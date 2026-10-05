import 'dart:convert';

import 'package:engineering_werk/features/workspace/domain/entities/engineering_report.dart';
import 'package:engineering_werk/features/workspace/presentation/widgets/workspace_notes_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/engineering_report_fixture.dart';

void main() {
  final reportText = EngineeringReport.fromResponse(
    jsonEncode(engineeringReportFixture),
  ).toNotesText();

  Future<void> pumpEditor(
    WidgetTester tester,
    TextEditingController controller, {
    double width = 1100,
    ThemeMode themeMode = ThemeMode.light,
    int revision = 0,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
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
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: WorkspaceNotesEditor(
                  controller: controller,
                  formattedRevision: revision,
                  decoration: const InputDecoration(hintText: 'Notes'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'pasted report becomes tables and can be edited and viewed again',
    (tester) async {
      final controller = TextEditingController(text: 'Existing team note');
      addTearDown(controller.dispose);
      await pumpEditor(tester, controller);
      expect(find.byType(TextField), findsOneWidget);
      controller.text = 'Existing team note\n\n$reportText';
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsNWidgets(3));
      expect(find.text('Existing team note'), findsOneWidget);
      expect(find.text('Engineering-focused version'), findsOneWidget);
      await tester.tap(find.text('Edit text'));
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsNothing);
      expect(controller.text, contains('Existing team note'));
      await tester.enterText(
        find.byType(TextField),
        controller.text.replaceFirst('Cutting duty', 'Updated cutting duty'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text('Formatted view'));
      await tester.pumpAndSettle();
      expect(find.text('Updated cutting duty'), findsOneWidget);
      expect(find.byType(Table), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('saved tables reopen and scroll in a narrow $mode layout', (
      tester,
    ) async {
      final controller = TextEditingController(text: reportText);
      addTearDown(controller.dispose);
      await pumpEditor(tester, controller, width: 390, themeMode: mode);
      expect(find.byType(Table), findsNWidgets(3));
      expect(
        find.text('Scroll sideways to view all columns'),
        findsNWidgets(3),
      );
      expect(find.byType(TextField), findsNothing);
      expect(controller.text, reportText);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'new AI paste selects formatted view even after editing an existing report',
    (tester) async {
      final controller = TextEditingController(text: reportText);
      addTearDown(controller.dispose);
      await pumpEditor(tester, controller);
      await tester.tap(find.text('Edit text'));
      await tester.pumpAndSettle();
      controller.text = reportText.replaceFirst(
        'Cutting duty',
        'Replacement duty',
      );
      await pumpEditor(tester, controller, revision: 1);
      expect(find.byType(Table), findsNWidgets(3));
      expect(find.text('Replacement duty'), findsOneWidget);
    },
  );
}
