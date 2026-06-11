import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:engineering_werk/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:engineering_werk/features/workspace/presentation/pages/workspace_screen.dart';
import 'package:engineering_werk/features/workspace/presentation/providers/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

void main() {
  late MockWorkspaceRepository repository;
  late WorkspaceData workspace;

  setUpAll(() {
    registerFallbackValue(const WorkspaceData(id: 'fallback'));
  });

  setUp(() {
    repository = MockWorkspaceRepository();
    workspace = const WorkspaceData(
      id: 'workspace-1',
      checklistItem: 'Admin checklist item',
      itemDescription: 'Admin-owned description',
      discipline: 'Mechanical',
    );

    when(
      () => repository.getWorkspaceById('workspace-1'),
    ).thenAnswer((_) async => workspace);
    when(() => repository.saveWorkspace(any())).thenAnswer((_) async {});
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: [workspaceRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
        home: WorkspaceScreen(
          workspaceId: 'workspace-1',
          reviewId: 'review-1',
          projectName: 'Pump Housing',
          stageName: 'Requirements',
          subStepName: 'Admin checklist item',
        ),
      ),
    );
  }

  testWidgets(
    'workspace hides stakeholders and locks admin-owned item details',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Stakeholders'), findsNothing);
      expect(find.text('Managed by admin'), findsOneWidget);
      expect(find.text('Admin checklist item'), findsOneWidget);
      expect(find.text('Admin-owned description'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Admin-owned description'),
        findsNothing,
      );

      await tester.tap(find.text('Save Progress'));
      await tester.pump();

      final saved =
          verify(() => repository.saveWorkspace(captureAny())).captured.single
              as WorkspaceData;
      expect(saved.checklistItem, 'Admin checklist item');
      expect(saved.itemDescription, 'Admin-owned description');
    },
  );
}
