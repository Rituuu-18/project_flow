import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engineering_werk/features/projects/presentation/pages/design_review_detail_screen.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/sub_step.dart';
import 'package:engineering_werk/features/reviews/presentation/providers/design_review_provider.dart';
import 'package:engineering_werk/features/reviews/domain/repositories/design_review_repository.dart';
import 'package:engineering_werk/core/utils/enums.dart';

class MockDesignReviewRepository extends Mock
    implements DesignReviewRepository {}

void main() {
  late MockDesignReviewRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      DesignReview(
        id: '',
        name: '',
        owner: '',
        discipline: '',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockDesignReviewRepository();
  });

  Widget createTestWidget(String reviewId) {
    return ProviderScope(
      overrides: [
        designReviewRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(home: DesignReviewDetailScreen(reviewId: reviewId)),
    );
  }

  testWidgets('DesignReviewDetailScreen shows stages and info', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final review = DesignReview(
      id: 'rev-1',
      name: 'Test Review',
      owner: 'Admin',
      discipline: 'Mechanical',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      stages: [
        Stage(
          id: 'stage-1',
          name: 'Requirements',
          lastUpdated: DateTime.now(),
          subSteps: [
            SubStep(id: 'ss-1', name: 'Define scope', workspaceId: 'ws-1'),
          ],
        ),
      ],
    );

    when(
      () => mockRepository.watchReviews(),
    ).thenAnswer((_) => Stream.value([review]));
    when(
      () => mockRepository.getAllReviews(),
    ).thenAnswer((_) => Future.value([review]));

    await tester.pumpWidget(createTestWidget('rev-1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Design review steps'), findsOneWidget);
    expect(find.text('Requirements'), findsOneWidget);
    expect(find.text('Define scope'), findsOneWidget);
  });

  testWidgets('mobile review layout keeps stage content readable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    final review = DesignReview(
      id: 'rev-1',
      name: 'Test Review',
      owner: 'Admin',
      discipline: 'Mechanical',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      stages: [
        Stage(
          id: 'stage-1',
          name: 'Detailed Design Review',
          lastUpdated: DateTime.now(),
          subSteps: [
            SubStep(
              id: 'ss-1',
              name: 'Detailed design documentation ready for release review',
              workspaceId: 'ws-1',
            ),
          ],
        ),
      ],
    );

    when(
      () => mockRepository.watchReviews(),
    ).thenAnswer((_) => Stream.value([review]));
    when(
      () => mockRepository.getAllReviews(),
    ).thenAnswer((_) => Future.value([review]));

    await tester.pumpWidget(createTestWidget('rev-1'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Detailed Design Review'), 300);

    expect(find.text('Detailed Design Review'), findsOneWidget);
    expect(
      find.text('Detailed design documentation ready for release review'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Adding a stakeholder calls repository', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    addTearDown(() => tester.view.resetPhysicalSize());

    final review = DesignReview(
      id: 'rev-1',
      name: 'Test Review',
      owner: 'Admin',
      discipline: 'Mechanical',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      stages: [],
    );

    when(
      () => mockRepository.watchReviews(),
    ).thenAnswer((_) => Stream.value([review]));
    when(
      () => mockRepository.getAllReviews(),
    ).thenAnswer((_) => Future.value([review]));
    when(
      () => mockRepository.saveReview(any()),
    ).thenAnswer((_) => Future.value());

    await tester.pumpWidget(createTestWidget('rev-1'));
    await tester.pump();

    // Scroll to see stakeholders if needed
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), 'Reviewer');
    await tester.tap(find.text('Add stakeholder'));
    await tester.pump();

    verify(() => mockRepository.saveReview(any())).called(1);
  });

  testWidgets('Updating substep status updates progress', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    addTearDown(() => tester.view.resetPhysicalSize());

    final review = DesignReview(
      id: 'rev-1',
      name: 'Test Review',
      owner: 'Admin',
      discipline: 'Mechanical',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      stages: [
        Stage(
          id: 'stage-1',
          name: 'Requirements',
          lastUpdated: DateTime.now(),
          subSteps: [
            SubStep(
              id: 'ss-1',
              name: 'Task 1',
              workspaceId: 'ws-1',
              status: StageStatus.notStarted,
            ),
          ],
        ),
      ],
    );

    when(
      () => mockRepository.watchReviews(),
    ).thenAnswer((_) => Stream.value([review]));
    when(
      () => mockRepository.getAllReviews(),
    ).thenAnswer((_) => Future.value([review]));
    when(
      () => mockRepository.saveReview(any()),
    ).thenAnswer((_) => Future.value());

    await tester.pumpWidget(createTestWidget('rev-1'));
    await tester.pump();

    // Scroll down to the table
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pump();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Select 'Completed' from dropdown
    await tester.tap(find.text('Completed').last);
    await tester.pumpAndSettle();

    verify(() => mockRepository.saveReview(any())).called(1);
  });
}
