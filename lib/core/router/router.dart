import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:engineering_werk/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:engineering_werk/features/projects/presentation/pages/design_review_detail_screen.dart';
import 'package:engineering_werk/features/workspace/presentation/pages/workspace_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/project/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            child: DesignReviewDetailScreen(reviewId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(
                  CurveTween(curve: Curves.easeOutCubic),
                ),
              ),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: '/workspace/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final projectName = state.uri.queryParameters['projectName'] ?? 'Project';
          final stageName = state.uri.queryParameters['stageName'] ?? 'Stage';
          final subStepName = state.uri.queryParameters['subStepName'] ?? 'Workspace';
          return CustomTransitionPage(
            child: WorkspaceScreen(workspaceId: id, projectName: projectName, stageName: stageName, subStepName: subStepName),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ],
  );
});
