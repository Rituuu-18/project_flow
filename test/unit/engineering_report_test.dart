import 'dart:convert';

import 'package:engineering_werk/features/workspace/domain/entities/engineering_report.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/engineering_report_fixture.dart';

void main() {
  test('structured report preserves sections, columns, and technical text', () {
    final report = EngineeringReport.fromResponse(
      '```json\n${jsonEncode(engineeringReportFixture)}\n```',
      requireTables: true,
    );
    expect(report.sections, hasLength(3));
    expect(report.sections[1].columns, hasLength(3));
    expect(report.sections[1].rows[1][1], contains('T = F_t × r'));
    expect(report.toJson(), engineeringReportFixture);
    final notes = report.toNotesText();
    expect(notes, startsWith('# Woodchipper rotor calculations'));
    expect(notes, contains('## Required inputs'));
    expect(notes, contains('## Engineering-focused version'));
    expect(report.toFocusedText(), engineeringReportFixture['summary']);
    expect(report.toFocusedText(), isNot(contains('## Required inputs')));
    expect(notes, contains('## Calculation sequence'));
    expect(notes, contains('## Traceability and acceptance'));
    expect(
      notes,
      contains(
        '| Check | Preliminary calculation | Result or design decision |',
      ),
    );
  });

  test('table serialization escapes pipes and flattens cell line breaks', () {
    const report = EngineeringReport(
      title: 'Engineering review',
      summary: 'Review allocated requirements.',
      sections: [
        EngineeringReportSection(
          heading: 'Inputs',
          columns: ['Item', 'Criteria'],
          rows: [
            ['Seal', 'Water | dust\nTo confirm'],
          ],
        ),
      ],
    );
    expect(
      report.toNotesText(),
      contains(r'| Seal | Water \| dust To confirm |'),
    );
  });

  test(
    'invalid or truncated AI reports are rejected rather than displayed',
    () {
      for (final response in [
        '{"title":',
        '[]',
        'A general product summary.',
      ]) {
        expect(
          () => EngineeringReport.fromResponse(response, requireTables: true),
          throwsFormatException,
        );
      }
      final malformed =
          jsonDecode(jsonEncode(engineeringReportFixture))
              as Map<String, dynamic>;
      (malformed['sections'] as List)[0]['rows'] = [
        ['Only one cell'],
      ];
      expect(
        () => EngineeringReport.fromResponse(jsonEncode(malformed)),
        throwsFormatException,
      );
    },
  );

  test('general sections and non-string cells cannot enter the report', () {
    final invalid =
        jsonDecode(jsonEncode(engineeringReportFixture))
            as Map<String, dynamic>;
    (invalid['sections'] as List)[0]['heading'] = '**General description**';
    expect(
      () => EngineeringReport.fromResponse(jsonEncode(invalid)),
      throwsFormatException,
    );
    (invalid['sections'] as List)[0]['heading'] = 'Required inputs';
    (invalid['sections'] as List)[0]['rows'][0][1] = 12;
    expect(
      () => EngineeringReport.fromResponse(jsonEncode(invalid)),
      throwsFormatException,
    );
  });
}
