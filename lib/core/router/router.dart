import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:engineering_werk/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:engineering_werk/features/projects/presentation/pages/design_review_detail_screen.dart';
import 'package:engineering_werk/features/workspace/presentation/pages/workspace_screen.dart';

const _routeTransitionDuration = Duration(milliseconds: 260);
const _routeReverseTransitionDuration = Duration(milliseconds: 200);
const _routeCurve = Cubic(0.2, 0.8, 0.2, 1);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const DashboardScreen()),
      ),
      GoRoute(
        path: '/project/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPage(
            state: state,
            child: DesignReviewDetailScreen(reviewId: id),
          );
        },
      ),
      GoRoute(
        path: '/workspace/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final reviewId = state.uri.queryParameters['reviewId'] ?? '';
          final projectName =
              state.uri.queryParameters['projectName'] ?? 'Project';
          final stageName = state.uri.queryParameters['stageName'] ?? 'Stage';
          final subStepName =
              state.uri.queryParameters['subStepName'] ?? 'Workspace';
          return _buildPage(
            state: state,
            child: WorkspaceScreen(
              workspaceId: id,
              reviewId: reviewId,
              projectName: projectName,
              stageName: stageName,
              subStepName: subStepName,
            ),
          );
        },
      ),
    ],
  );
});

CustomTransitionPage<void> _buildPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: _routeTransitionDuration,
    reverseTransitionDuration: _routeReverseTransitionDuration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: _routeCurve,
        reverseCurve: _routeCurve,
      );

      return ColoredBox(
        key: const ValueKey('app-route-background'),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.012),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        ),
      );
    },
  );
}
