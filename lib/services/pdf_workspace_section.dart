import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/database/supabase_storage.dart';
import '../core/utils/enums.dart';
import '../features/reviews/domain/entities/stakeholder.dart';
import '../features/reviews/domain/utils/default_stages.dart';
import '../features/workspace/domain/entities/workspace_data.dart';
import 'pdf_notes_document.dart';

/// Returns page-level blocks so a workspace never has to fit on one page.
class PdfWorkspaceSection {
  static List<pw.Widget> build({
    required int subStepNumber,
    required String subStepName,
    required WorkspaceData wsData,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
    required List<Stakeholder> projectStakeholders,
  }) {
    return [
      pw.NewPage(freeSpace: 90),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F1F5F9'),
          border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
        ),
        child: pw.Text(
          '$subStepNumber. $subStepName',
          overflow: pw.TextOverflow.span,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0F172A'),
          ),
        ),
      ),
      ..._description(subStepName, wsData),
      ..._notes(wsData),
      ..._evidence(wsData, workspaceImages, workspaceAttachmentUrls),
      ..._action(wsData),
      ..._responsiblePerson(subStepName, wsData, projectStakeholders),
      pw.SizedBox(height: 8),
      pw.Divider(color: PdfColor.fromHex('#E2E8F0')),
    ];
  }

  static List<pw.Widget> _heading(String title) => [
    pw.NewPage(freeSpace: 40),
    pw.SizedBox(height: 7),
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#005CFF'),
        ),
      ),
    ),
    pw.SizedBox(height: 4),
  ];

  static List<pw.Widget> _text(
    String text, {
    bool muted = false,
    bool bold = false,
    double fontSize = 9.5,
  }) => [
    // Bound each spanning block without imposing a document page limit. Prefer
    // paragraph/word boundaries; even a single very long field can progress.
    for (final chunk in _textChunks(text))
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12),
        child: pw.Text(
          chunk,
          overflow: pw.TextOverflow.span,
          style: pw.TextStyle(
            fontSize: fontSize,
            color: PdfColor.fromHex(muted ? '#64748B' : '#334155'),
            fontStyle: muted ? pw.FontStyle.italic : pw.FontStyle.normal,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            height: 1.3,
          ),
        ),
      ),
  ];

  static Iterable<String> _textChunks(String text) sync* {
    const maxLength = 3000;
    const maxLines = 80;
    var remaining = text.trim();
    while (remaining.isNotEmpty) {
      var limit = math.min(maxLength, remaining.length);
      var newline = -1;
      for (var line = 0; line < maxLines; line++) {
        newline = remaining.indexOf('\n', newline + 1);
        if (newline < 0 || newline >= limit) break;
        if (line == maxLines - 1) limit = newline;
      }
      if (limit == remaining.length) {
        yield remaining;
        break;
      }
      var end = remaining.lastIndexOf('\n', limit);
      if (end < limit ~/ 2) end = remaining.lastIndexOf(' ', limit);
      if (end <= 0) {
        end = limit;
        // Keep a UTF-16 surrogate pair together when there is no whitespace.
        final codeUnit = remaining.codeUnitAt(end - 1);
        if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) end--;
      }
      yield remaining.substring(0, end);
      final delimiter = remaining[end];
      remaining = remaining.substring(
        end + (delimiter == '\n' || delimiter == ' ' ? 1 : 0),
      );
    }
  }

  static List<pw.Widget> _description(String name, WorkspaceData ws) {
    var description = ws.itemDescription.trim();
    if (description.isEmpty) {
      for (final stage in defaultStageContent.values) {
        final info = stage.subSteps[name];
        if (info != null) {
          description = info.description.trim();
          break;
        }
      }
    }
    return [
      ..._heading('a. Description'),
      ..._text(
        description.isEmpty ? 'No description provided.' : description,
        muted: description.isEmpty,
      ),
    ];
  }

  static List<pw.Widget> _notes(WorkspaceData ws) {
    final items = <pw.Widget>[];
    if (ws.notes.trim().isNotEmpty) items.addAll(_formattedNotes(ws.notes));
    if (ws.engineeringComments.trim().isNotEmpty) {
      if (items.isNotEmpty) items.add(pw.SizedBox(height: 4));
      items.addAll(_text('Engineering Comments', bold: true));
      items.add(pw.SizedBox(height: 4));
      items.addAll(_formattedNotes(ws.engineeringComments));
    }
    for (final comment in ws.comments) {
      if (items.isNotEmpty) items.add(pw.SizedBox(height: 4));
      final author = comment.author.trim().isEmpty
          ? 'Author'
          : comment.author.trim();
      final date = DateFormat('dd MMM yyyy HH:mm').format(comment.createdAt);
      items.addAll(_formattedNotes(comment.content));
      items.add(pw.SizedBox(height: 2));
      items.addAll(_text('- $author on $date', muted: true, fontSize: 8.5));
    }
    return [
      ..._heading('b. Notes'),
      if (items.isEmpty)
        ..._text('No notes available.', muted: true)
      else
        ...items,
    ];
  }

  static List<pw.Widget> _formattedNotes(String text) =>
      PdfNotesDocument.build(text, paragraphBuilder: (text) => _text(text));

  static List<pw.Widget> _evidence(
    WorkspaceData ws,
    Map<String, Uint8List> images,
    Map<String, String> urls,
  ) {
    final refs = {...ws.attachments, ...ws.images, ...ws.documents};
    return [
      ..._heading('c. Evidence'),
      if (refs.isEmpty) ..._text('No evidence uploaded.', muted: true),
      // Keep one image/file and its link together, not the entire evidence list.
      for (final ref in refs) _evidenceItem(ref, images[ref], urls[ref]),
    ];
  }

  static pw.Widget _evidenceItem(String ref, Uint8List? bytes, String? rawUrl) {
    final name = SupabaseStorage.attachmentDisplayName(ref);
    final extension = name.split('.').last.toLowerCase();
    final isImage = {'png', 'jpg', 'jpeg', 'webp', 'gif'}.contains(extension);
    final url =
        rawUrl != null &&
            (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))
        ? rawUrl
        : null;
    final linkStyle = pw.TextStyle(
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex(url != null ? '#2563EB' : '#475569'),
      decoration: url != null
          ? pw.TextDecoration.underline
          : pw.TextDecoration.none,
    );
    final item = pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: bytes != null && bytes.isNotEmpty && isImage
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(bytes),
                    height: 95,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Image: $name', style: linkStyle),
              ],
            )
          : pw.Row(
              children: [
                pw.Expanded(child: pw.Text(name, style: linkStyle)),
                pw.SizedBox(width: 8),
                pw.Text(
                  url != null ? _fileType(name) : 'File unavailable',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColor.fromHex(
                      url != null ? '#005CFF' : '#EF4444',
                    ),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
    // Evidence cards have a bounded height and must move as a whole to keep the
    // annotation on the same page as the image/caption it links.
    return pw.Inseparable(
      child: url != null ? pw.UrlLink(destination: url, child: item) : item,
    );
  }

  static String _fileType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'PDF Document',
      'dwg' ||
      'dxf' ||
      'step' ||
      'stp' ||
      'iges' ||
      'igs' ||
      'sldprt' => 'CAD File (.${ext.toUpperCase()})',
      'doc' || 'docx' => 'Word Document',
      'xls' || 'xlsx' || 'csv' => 'Excel Spreadsheet',
      'ppt' || 'pptx' => 'Presentation',
      'png' ||
      'jpg' ||
      'jpeg' ||
      'webp' ||
      'gif' => 'Image (${ext.toUpperCase()})',
      _ => 'Document (.$ext)',
    };
  }

  static List<pw.Widget> _action(WorkspaceData ws) {
    final action = ws.actionDescription.trim();
    final details = <String>[
      if (ws.priority.trim().isNotEmpty) 'Priority: ${ws.priority.trim()}',
      if (ws.assignee.trim().isNotEmpty) 'Assigned: ${ws.assignee.trim()}',
      if (ws.dueDate != null)
        'Due: ${DateFormat('dd MMM yyyy').format(ws.dueDate!)}',
      if (ws.approvalStatus != ApprovalStatus.pending)
        'Status: ${ws.approvalStatus.name}',
    ];
    return [
      ..._heading('d. Action Description'),
      ..._text(
        action.isEmpty ? 'No actions recorded.' : action,
        muted: action.isEmpty,
      ),
      if (action.isNotEmpty && details.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        ..._text(details.join(' | '), fontSize: 8.5, bold: true),
      ],
    ];
  }

  static List<pw.Widget> _responsiblePerson(
    String name,
    WorkspaceData ws,
    List<Stakeholder> stakeholders,
  ) {
    var person = ws.assignee.trim();
    var discipline = ws.discipline.trim();
    if (person.isEmpty) {
      final defaultInfo = defaultStageContent['Requirements']?.subSteps[name];
      final target = discipline.isNotEmpty
          ? discipline
          : (defaultInfo?.discipline ?? '');
      final matched = stakeholders.firstWhere(
        (s) =>
            s.role.trim().toLowerCase() == target.toLowerCase() &&
            s.name.trim().isNotEmpty,
        orElse: () => const Stakeholder(id: '', name: '', role: ''),
      );
      if (matched.name.trim().isNotEmpty) {
        person = matched.name.trim();
        discipline = matched.role.trim();
      }
    }
    return [
      ..._heading('e. Responsible Person'),
      if (person.isEmpty)
        ..._text('No responsible person assigned.', muted: true)
      else ...[
        ..._text('Responsible Person: $person', bold: true),
        pw.SizedBox(height: 1),
        ..._text(
          'Discipline: ${discipline.isEmpty ? 'General Engineering' : discipline}',
        ),
      ],
    ];
  }
}
