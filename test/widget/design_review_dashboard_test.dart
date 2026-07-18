import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engineering_werk/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/repositories/design_review_repository.dart';
import 'package:engineering_werk/features/reviews/presentation/providers/design_review_provider.dart';
import 'package:engineering_werk/features/auth/domain/repositories/auth_repository.dart';
import 'package:engineering_werk/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockUser extends Mock implements User {}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => MockUser();

  @override
  Future<AuthResponse> signIn({required String email, required String password}) => throw UnimplementedError();

  @override
  Future<AuthResponse> signUp({required String email, required String password, String? firstName, String? lastName}) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPasswordForEmail(String email) => throw UnimplementedError();

  @override
  Future<UserResponse> updatePassword(String newPassword) => throw UnimplementedError();
}

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
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/project/:id',
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        designReviewRepositoryProvider.overrideWithValue(mockRepo),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('Dashboard shows empty state when no reviews', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Active Design Reviews'), findsOneWidget);
    expect(find.text('Pump Housing Rev C'), findsOneWidget);
    expect(find.textContaining('Owner: Sunil'), findsOneWidget);
  });

  testWidgets('Review menu can prepare a slide', (tester) async {
    final review = DesignReview(
      id: '1',
      name: 'Pump Housing Rev C',
      owner: 'Sunil',
      discipline: 'Mechanical',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    when(
      () => mockRepo.watchReviews(),
    ).thenAnswer((_) => Stream.value([review]));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More actions for Pump Housing Rev C'));
    await tester.pumpAndSettle();

    expect(find.text('Prepare slide'), findsOneWidget);

    await tester.tap(find.text('Prepare slide'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Pump Housing Rev C is ready for the presentation export flow.',
      ),
      findsOneWidget,
    );
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
    expect(find.text('New Design Review'), findsWidgets);

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
    final createButton = find.text('Create');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    // Verify repository was called
    verify(() => mockRepo.saveReview(any())).called(1);

    // Dialog should be closed
    expect(find.text('CREATE DESIGN REVIEW'), findsNothing);
  });
}
