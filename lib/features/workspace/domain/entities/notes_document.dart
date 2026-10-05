/// Parses the heading and table format written by EngineeringReport.toNotesText.
/// Unrecognised or incomplete tables remain plain text so edits are never lost.
class NotesDocument {
  final List<NotesBlock> blocks;

  const NotesDocument(this.blocks);

  bool get hasTables => blocks.any((block) => block is NotesTable);

  factory NotesDocument.parse(String text) {
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final blocks = <NotesBlock>[];
    final paragraph = <String>[];
    void flushParagraph() {
      if (paragraph.isNotEmpty) {
        blocks.add(NotesParagraph(paragraph.join('\n')));
        paragraph.clear();
      }
    }

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.trim().isEmpty) {
        flushParagraph();
        continue;
      }
      final heading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (heading != null) {
        flushParagraph();
        blocks.add(NotesHeading(heading.group(2)!, heading.group(1)!.length));
        continue;
      }
      final columns = _tableCells(line);
      final separator = index + 1 < lines.length
          ? _tableCells(lines[index + 1])
          : null;
      if (columns != null &&
          columns.length >= 2 &&
          columns.length <= 6 &&
          separator != null &&
          separator.length == columns.length &&
          separator.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell))) {
        final rows = <List<String>>[];
        var end = index + 2;
        while (end < lines.length) {
          final row = _tableCells(lines[end]);
          if (row == null || row.length != columns.length) break;
          rows.add(row);
          end++;
        }
        if (rows.isNotEmpty) {
          flushParagraph();
          blocks.add(NotesTable(columns, rows));
          index = end - 1;
          continue;
        }
      }
      paragraph.add(line);
    }
    flushParagraph();
    return NotesDocument(blocks);
  }
}

sealed class NotesBlock {
  const NotesBlock();
}

class NotesHeading extends NotesBlock {
  final String text;
  final int level;
  const NotesHeading(this.text, this.level);
}

class NotesParagraph extends NotesBlock {
  final String text;
  const NotesParagraph(this.text);
}

class NotesTable extends NotesBlock {
  final List<String> columns;
  final List<List<String>> rows;
  const NotesTable(this.columns, this.rows);
}

List<String>? _tableCells(String line) {
  final text = line.trim();
  if (!text.startsWith('|') || !text.endsWith('|')) return null;
  final cells = <String>[];
  final cell = StringBuffer();
  for (var index = 1; index < text.length - 1; index++) {
    final character = text[index];
    if (character == '\\' &&
        index + 1 < text.length - 1 &&
        (text[index + 1] == '|' || text[index + 1] == '\\')) {
      cell.write(text[++index]);
    } else if (character == '|') {
      cells.add(cell.toString().trim());
      cell.clear();
    } else {
      cell.write(character);
    }
  }
  cells.add(cell.toString().trim());
  return cells;
}
