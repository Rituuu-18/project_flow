import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engineering_werk/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/repositories/design_review_repository.dart';
import 'package:engineering_werk/features/reviews/presentation/providers/design_review_provider.dart';

class MockDesignReviewRepository extends Mock
    implements DesignReviewRepository {}

void main() {
  late MockDesignReviewRepository mockRepo;

  setUp(() {
    mockRepo = MockDesignReviewRepository();
    // Register fallback for DesignReview for mocktail 'any' matcher
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

    // Default fallback for watchReviews
    when(() => mockRepo.watchReviews()).thenAnswer((_) => Stream.value([]));
    when(() => mockRepo.getAllReviews()).thenAnswer((_) => Future.value([]));
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [designReviewRepositoryProvider.overrideWithValue(mockRepo)],
      child: const MaterialApp(home: DashboardScreen()),
    );
  }

  testWidgets('Dashboard shows empty state when no reviews', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump(); // Handle loading state

    expect(find.text('No Design Reviews yet.'), findsOneWidget);
    expect(find.text('Click the button above to start one.'), findsOneWidget);
  });

  testWidgets('Dashboard displays active reviews', (tester) async {
    final reviews = [
      DesignReview(
        id: '1',
        name: 'Pump Housing Rev C',
        owner: 'Sunil',
        discipline: 'Mechanical',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    ];

    when(
      () => mockRepo.watchReviews(),
    ).thenAnswer((_) => Stream.value(reviews));

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.text('Active Design Reviews'), findsOneWidget);
    expect(find.text('Pump Housing Rev C'), findsOneWidget);
    expect(find.textContaining('Owner: Sunil'), findsOneWidget);
  });

  testWidgets('Dialog should appear and allow creating a review', (
    tester,
  ) async {
    when(() => mockRepo.saveReview(any())).thenAnswer((_) => Future.value());

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    // Click New Design Review button
    await tester.tap(find.text('New Design Review'));
    await tester.pumpAndSettle();

    // Verify Dialog titles
    expect(find.text('CREATE DESIGN REVIEW'), findsOneWidget);
    expect(find.text('New Design Review'), findsOneWidget);

    // Enter data
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Gearbox Cover Rev A'),
      'Test Gearbox',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Owner'),
      'Alice',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Discipline'),
      'Electronics',
    );

    // Click Create
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify repository was called
    verify(() => mockRepo.saveReview(any())).called(1);

    // Dialog should be closed
    expect(find.text('CREATE DESIGN REVIEW'), findsNothing);
  });
}
