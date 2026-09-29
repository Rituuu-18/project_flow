import 'dart:convert';

import 'package:engineering_werk/features/workspace/domain/entities/engineering_report.dart';
import 'package:engineering_werk/features/workspace/presentation/widgets/ai_analysis_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/engineering_report_fixture.dart';

Future<void> pumpReport(
  WidgetTester tester, {
  double width = 1100,
  ThemeMode themeMode = ThemeMode.light,
  String? raw,
  void Function(String, bool)? onApply,
}) async {
  tester.view.physicalSize = Size(width, 950);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: Scaffold(
          body: AIAnalysisSheet(
            projectName: 'Woodchipper rotor',
            stageName: 'Preliminary Design',
            checklistItem: 'Perform engineering calculations',
            itemDescription: 'Calculate loads from allocated requirements.',
            existingNotes: 'Existing notes',
            initialRawAnalysis: raw ?? jsonEncode(engineeringReportFixture),
            onApplyNotes: onApply ?? (_, _) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'report renders real table headings and untruncated engineering cells',
    (tester) async {
      await pumpReport(tester);
      expect(find.text('Woodchipper rotor calculations'), findsOneWidget);
      expect(find.text('Engineering-focused version'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Engineering-focused version')).dy,
        lessThan(
          tester.getTopLeft(find.text('Woodchipper rotor calculations')).dy,
        ),
      );
      expect(find.text('Required inputs'), findsOneWidget);
      expect(find.text('Calculation sequence'), findsOneWidget);
      expect(find.text('Traceability and acceptance'), findsOneWidget);
      expect(find.text('Values to allocate or confirm'), findsOneWidget);
      expect(find.text('Result or design decision'), findsOneWidget);
      expect(find.byType(Table), findsNWidgets(3));
      final equation = find.textContaining('T = F_t × r');
      expect(equation, findsOneWidget);
      expect(tester.widget<Text>(equation).maxLines, isNull);
      expect(find.text('General problem statement'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('report tables fit a narrow panel in $mode', (tester) async {
      await pumpReport(tester, width: 390, themeMode: mode);
      expect(
        find.text('Scroll sideways to view all columns'),
        findsNWidgets(3),
      );
      await tester.ensureVisible(find.text('Calculation sequence'));
      await tester.pumpAndSettle();
      final tableScroll = find
          .ancestor(
            of: find.byType(Table).at(1),
            matching: find.byType(SingleChildScrollView),
          )
          .first;
      final scrollWidget = tester.widget<SingleChildScrollView>(tableScroll);
      expect(scrollWidget.scrollDirection, Axis.horizontal);
      scrollWidget.controller!.jumpTo(100);
      await tester.pumpAndSettle();
      expect(scrollWidget.controller!.offset, 100);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('copy and notes preserve every report section and table column', (
    tester,
  ) async {
    String? appliedText;
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpReport(tester, onApply: (text, _) => appliedText = text);
    await tester.tap(find.byTooltip('Copy full report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(
      find.text('Preview of engineering report ready for insertion:'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Paste full report'));
    await tester.pumpAndSettle();
    final expected = EngineeringReport.fromResponse(
      jsonEncode(engineeringReportFixture),
    ).toNotesText();
    expect(copiedText, expected);
    expect(appliedText, expected);
    expect(appliedText, contains('## Calculation sequence'));
    expect(
      appliedText,
      contains(
        '| Check | Preliminary calculation | Result or design decision |',
      ),
    );
  });

  testWidgets('top copy action copies only the engineering-focused summary', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpReport(tester, width: 390);
    await tester.tap(find.widgetWithText(TextButton, 'Copy summary'));
    await tester.pumpAndSettle();
    expect(copiedText, engineeringReportFixture['summary']);
    expect(copiedText, isNot(contains('|')));
  });

  for (final append in [false, true]) {
    testWidgets('top summary action preserves the append flag: $append', (
      tester,
    ) async {
      String? appliedText;
      bool? appliedAppend;
      await pumpReport(
        tester,
        width: 390,
        onApply: (text, shouldAppend) {
          appliedText = text;
          appliedAppend = shouldAppend;
        },
      );
      await tester.ensureVisible(
        find.text(append ? 'Append summary' : 'Paste summary'),
      );
      await tester.tap(find.text(append ? 'Append summary' : 'Paste summary'));
      await tester.pumpAndSettle();
      expect(appliedText, engineeringReportFixture['summary']);
      expect(appliedAppend, append);
      expect(appliedText, isNot(contains('Required inputs')));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'malformed cached report shows a recovery action without raw JSON',
    (tester) async {
      await pumpReport(tester, raw: '{"title":"Truncated');
      expect(
        find.text(
          'The AI report is incomplete or could not be read. Regenerate the analysis.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(Table), findsNothing);
      expect(find.byTooltip('Copy'), findsNothing);
      expect(find.textContaining('Truncated'), findsNothing);
    },
  );
}
