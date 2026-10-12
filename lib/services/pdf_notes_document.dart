import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../features/workspace/domain/entities/notes_document.dart';

/// Uses the same saved Notes format as the workspace's formatted view.
class PdfNotesDocument {
  static List<pw.Widget> build(
    String text, {
    required List<pw.Widget> Function(String) paragraphBuilder,
  }) {
    final document = NotesDocument.parse(text);
    if (!document.hasTables &&
        !document.blocks.any((block) => block is NotesHeading)) {
      return paragraphBuilder(text);
    }
    return [
      for (var index = 0; index < document.blocks.length; index++) ...[
        if (index > 0) pw.SizedBox(height: 10),
        ...switch (document.blocks[index]) {
          NotesHeading(:final text, :final level) => [
            pw.NewPage(freeSpace: 100),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12),
              child: pw.Text(
                text,
                overflow: pw.TextOverflow.span,
                style: pw.TextStyle(
                  fontSize: level == 1 ? 12 : 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0F172A'),
                  height: 1.25,
                ),
              ),
            ),
          ],
          NotesParagraph(:final text) => paragraphBuilder(text),
          NotesTable table => [
            pw.NewPage(freeSpace: 100),
            _table(table),
          ],
        },
      ],
    ];
  }

  static pw.Widget _table(NotesTable table) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12),
    child: pw.LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = table.columns.length;
        final weights = switch (columnCount) {
          2 => [0.30, 0.70],
          3 => [0.24, 0.38, 0.38],
          _ => List.filled(columnCount, 1.0 / columnCount),
        };
        final width = constraints!.maxWidth;
        final rows = <pw.TableRow>[
          pw.TableRow(
            repeat: true,
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E9EEF5')),
            children: [
              for (final column in table.columns) _cell(column, header: true),
            ],
          ),
        ];
        for (var rowIndex = 0; rowIndex < table.rows.length; rowIndex++) {
          final row = table.rows[rowIndex];
          final parts = [
            for (var column = 0; column < columnCount; column++)
              _cellParts(
                context,
                row[column],
                width * weights[column] - 16,
                label: column == 0,
              ),
          ];
          final partCount = parts.map((parts) => parts.length).reduce(math.max);
          for (var part = 0; part < partCount; part++) {
            rows.add(
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex(
                    rowIndex.isEven ? '#FFFFFF' : '#F8FAFC',
                  ),
                ),
                children: [
                  for (var column = 0; column < columnCount; column++)
                    _cell(
                      part < parts[column].length
                          ? parts[column][part]
                          : column == 0 && parts[column].length == 1
                          ? '${row[column]} (continued)'
                          : '',
                      label: column == 0,
                    ),
                ],
              ),
            );
          }
        }
        // Keep the Table directly in the spanning chain. A Column around it
        // would require the entire table to fit on one page.
        return pw.Table(
          border: pw.TableBorder.all(
            color: PdfColor.fromHex('#CBD5E1'),
            width: 0.6,
          ),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
          columnWidths: {
            for (var column = 0; column < columnCount; column++)
              column: pw.FlexColumnWidth(weights[column]),
          },
          children: rows,
        );
      },
    ),
  );

  static pw.TextStyle _style({bool header = false, bool label = false}) =>
      pw.TextStyle(
        fontSize: 8.7,
        fontWeight: header || label ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: PdfColor.fromHex(header || label ? '#1E293B' : '#334155'),
        height: 1.3,
      );

  static pw.Widget _cell(
    String text, {
    bool header = false,
    bool label = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: pw.Text(
      text,
      style: _style(header: header, label: label),
    ),
  );

  /// PDF tables split between rows, so split unusually tall cells into aligned
  /// continuation rows using their actual font metrics and column width.
  static List<String> _cellParts(
    pw.Context context,
    String text,
    double width, {
    required bool label,
  }) {
    const maxHeight = 200.0;
    final style = _style(label: label);
    bool fits(String value) {
      final measured = pw.Text(value, style: style);
      measured.layout(context, pw.BoxConstraints(maxWidth: width));
      return measured.box!.height <= maxHeight;
    }

    final parts = <String>[];
    var remaining = text;
    while (remaining.isNotEmpty) {
      final limit = math.min(remaining.length, 3000);
      if (limit == remaining.length && fits(remaining)) {
        parts.add(remaining);
        break;
      }
      var low = 1;
      var high = limit;
      while (low < high) {
        final middle = (low + high + 1) ~/ 2;
        if (fits(remaining.substring(0, middle))) {
          low = middle;
        } else {
          high = middle - 1;
        }
      }
      var end = low;
      final boundary = remaining.lastIndexOf(RegExp(r'\s'), end - 1);
      if (boundary > 0) end = boundary + 1;
      // Do not split UTF-16 surrogate pairs when a cell has no spaces.
      final unit = remaining.codeUnitAt(end - 1);
      if (unit >= 0xD800 && unit <= 0xDBFF && end > 1) end--;
      parts.add(remaining.substring(0, end));
      remaining = remaining.substring(end);
    }
    return parts.isEmpty ? [''] : parts;
  }
}
