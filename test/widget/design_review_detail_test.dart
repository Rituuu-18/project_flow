import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
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

  Widget createRoutedTestWidget(String reviewId) {
    final router = GoRouter(
      initialLocation: '/project/$reviewId',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard route')),
        ),
        GoRoute(
          path: '/project/:id',
          builder: (context, state) =>
              DesignReviewDetailScreen(reviewId: state.pathParameters['id']!),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        designReviewRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp.router(routerConfig: router),
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
    expect(find.text('REQUIREMENTS'), findsOneWidget);
    expect(find.text('Define scope'), findsOneWidget);
  });

  testWidgets('all stages show their substeps by default', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
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
          name: 'Requirements',
          lastUpdated: DateTime.now(),
          subSteps: [
            SubStep(
              id: 'ss-1',
              name: 'Requirements child item',
              workspaceId: 'ws-1',
            ),
          ],
        ),
        Stage(
          id: 'stage-2',
          name: 'Concept',
          lastUpdated: DateTime.now(),
          subSteps: [
            SubStep(
              id: 'ss-2',
              name: 'Concept child item',
              workspaceId: 'ws-2',
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

    expect(find.text('Requirements child item'), findsOneWidget);
    expect(find.text('Concept child item'), findsOneWidget);
  });

  testWidgets('Back to Dashboard works from a directly loaded project route', (
    WidgetTester tester,
  ) async {
    final review = DesignReview(
      id: 'rev-1',
      name: 'Test Review',
      owner: 'Admin',
      discipline: 'Mechanical',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    when(
      () => mockRepository.watchReviews(),
    ).thenAnswer((_) => Stream.value([review]));
    when(
      () => mockRepository.getAllReviews(),
    ).thenAnswer((_) => Future.value([review]));

    await tester.pumpWidget(createRoutedTestWidget('rev-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard route'), findsOneWidget);
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
    final subStepFinder = find.text(
      'Detailed design documentation ready for release review',
    );
    await tester.scrollUntilVisible(
      subStepFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('DETAILED DESIGN REVIEW'), findsOneWidget);
    expect(subStepFinder, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Adding a stakeholder calls repository', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
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
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
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

    final statusButton = find.byType(PopupMenuButton<StageStatus>);
    expect(statusButton, findsOneWidget);
    await tester.ensureVisible(statusButton);
    await tester.pump();
    await tester.tap(statusButton);
    await tester.pumpAndSettle();

    // Select 'Completed' from popup menu
    await tester.tap(find.text('Completed').last);
    await tester.pumpAndSettle();

    verify(() => mockRepository.saveReview(any())).called(1);
  });

  testWidgets('long review lifecycles build stages lazily', (tester) async {
    tester.view.physicalSize = const Size(412, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    final stages = List.generate(
      30,
      (index) => Stage(
        id: 'stage-$index',
        name: 'Lifecycle stage $index',
        lastUpdated: DateTime.now(),
        subSteps: [
          SubStep(
            id: 'substep-$index',
            name: 'Substep $index',
            workspaceId: 'workspace-$index',
          ),
        ],
      ),
    );
    final review = DesignReview(
      id: 'rev-1',
      name: 'Large Review',
      owner: 'Admin',
      discipline: 'Mechanical',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      stages: stages,
    );

    when(
      () => mockRepository.watchReviews(),
    ).thenAnswer((_) => Stream.value([review]));
    when(
      () => mockRepository.getAllReviews(),
    ).thenAnswer((_) => Future.value([review]));

    await tester.pumpWidget(createTestWidget('rev-1'));
    await tester.pumpAndSettle();

    expect(find.text('LIFECYCLE STAGE 29'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('LIFECYCLE STAGE 29'),
      700,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('LIFECYCLE STAGE 29'), findsOneWidget);
  });
}
