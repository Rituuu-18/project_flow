import 'dart:convert';

import 'package:engineering_werk/features/workspace/domain/entities/engineering_report.dart';
import 'package:engineering_werk/features/workspace/domain/entities/notes_document.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/engineering_report_fixture.dart';

void main() {
  test('AI report notes render every column, row, heading, and summary', () {
    final report = EngineeringReport.fromResponse(
      jsonEncode(engineeringReportFixture),
    );
    final document = NotesDocument.parse(report.toNotesText());
    final tables = document.blocks.whereType<NotesTable>().toList();
    expect(tables, hasLength(3));
    for (var index = 0; index < tables.length; index++) {
      expect(tables[index].columns, report.sections[index].columns);
      expect(tables[index].rows, report.sections[index].rows);
    }
    expect(
      document.blocks.whereType<NotesHeading>().map((block) => block.text),
      contains('Engineering-focused version'),
    );
    expect(
      document.blocks.whereType<NotesParagraph>().first.text,
      report.summary,
    );
  });

  test('escaped pipes and backslashes survive table serialization', () {
    const report = EngineeringReport(
      title: 'Report',
      summary: 'Summary',
      sections: [
        EngineeringReportSection(
          heading: 'Inputs',
          columns: ['Item', 'Value'],
          rows: [
            ['Seal', r'Water | dust; C:\drawings\seal'],
            ['Path', r'Escaped \| symbol'],
          ],
        ),
      ],
    );
    final table = NotesDocument.parse(
      report.toNotesText(),
    ).blocks.whereType<NotesTable>().single;
    expect(table.rows, report.sections.single.rows);
  });

  test('team notes and multiple appended reports retain their order', () {
    final report = EngineeringReport.fromResponse(
      jsonEncode(engineeringReportFixture),
    );
    final document = NotesDocument.parse(
      'Team observation\n\n${report.toNotesText()}\n\nFollow-up\n\n${report.toNotesText()}',
    );
    expect((document.blocks.first as NotesParagraph).text, 'Team observation');
    expect(document.blocks.whereType<NotesTable>(), hasLength(6));
    expect(
      document.blocks.whereType<NotesParagraph>().map((block) => block.text),
      contains('Follow-up'),
    );
  });

  test('incomplete or mismatched table text is preserved', () {
    const text = '| Item | Value |\n| --- | --- |\n| Only one cell |';
    final document = NotesDocument.parse(text);
    expect(document.hasTables, isFalse);
    expect((document.blocks.single as NotesParagraph).text, text);
    expect(NotesDocument.parse('').blocks, isEmpty);
    expect(
      NotesDocument.parse('Regular notes with | a pipe').hasTables,
      isFalse,
    );
  });
}
