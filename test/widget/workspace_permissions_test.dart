import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/presentation/providers/design_review_provider.dart';
import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:engineering_werk/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:engineering_werk/features/workspace/presentation/pages/workspace_screen.dart';
import 'package:engineering_werk/features/workspace/presentation/providers/workspace_provider.dart';
import 'package:engineering_werk/features/workspace/presentation/widgets/ai_analysis_sheet.dart';
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
      overrides: [
        workspaceRepositoryProvider.overrideWithValue(repository),
        designReviewsStreamProvider.overrideWith(
          (ref) => Stream.value(const <DesignReview>[]),
        ),
      ],
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
    'workspace hides stakeholders section and locks admin-owned item details',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Stakeholders'), findsNothing);
      expect(
        find.textContaining('No stakeholders yet'),
        findsOneWidget,
      );
      expect(find.text('Managed by admin'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
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

  testWidgets(
    'tapping AI Analyze expands inline AI panel directly in the page without modal popup',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially, AI panel is closed and no AIAnalysisSheet is in the tree
      expect(find.byType(AIAnalysisSheet), findsNothing);
      // AI Analyze button is only in the Notes section, not in Item Details
      expect(find.text('AI Analyze'), findsOneWidget);

      // Tap the AI Analyze button in the Notes section
      final aiButton = find.widgetWithText(InkWell, 'AI Analyze');
      await tester.tap(aiButton);
      await tester.pumpAndSettle();

      // Inline AIAnalysisSheet is now rendered directly in the page with isInline: true
      expect(find.byType(AIAnalysisSheet), findsOneWidget);
      final inlineSheet =
          tester.widget<AIAnalysisSheet>(find.byType(AIAnalysisSheet));
      expect(inlineSheet.isInline, isTrue);

      // Verify no modal bottom sheet route was pushed (ModalBarrier count stays at 1 for root route)
      expect(find.byType(ModalBarrier), findsOneWidget);

      // Verify toggle button updated to close label
      expect(find.text('Close AI Assistant'), findsWidgets);

      // Tap "Close AI Assistant" to smoothly collapse the inline panel
      final closeButton = find.text('Close AI Assistant').last;
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Inline AIAnalysisSheet is now closed/collapsed
      expect(find.byType(AIAnalysisSheet), findsNothing);
    },
  );

  testWidgets(
    'Item Details has no AI Analyze button and only Notes provides AI analysis',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Only one AI Analyze button exists in the entire workspace (in Notes)
      expect(find.widgetWithText(InkWell, 'AI Analyze'), findsOneWidget);

      // Verify that Item Details has Managed by admin without any AI button
      expect(find.text('Managed by admin'), findsOneWidget);

      // Open from Notes and verify inline sheet expands
      await tester.tap(find.widgetWithText(InkWell, 'AI Analyze'));
      await tester.pumpAndSettle();

      expect(find.byType(AIAnalysisSheet), findsOneWidget);

      // Tapping the close icon on the AI panel collapses it
      final closeIcon = find.byTooltip('Close AI Assistant');
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(find.byType(AIAnalysisSheet), findsNothing);
    },
  );
}
