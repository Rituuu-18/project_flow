import 'package:engineering_werk/core/router/router.dart';
import 'package:engineering_werk/core/theme/app_theme.dart';
import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:engineering_werk/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:engineering_werk/features/workspace/presentation/providers/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWorkspaceRepository implements WorkspaceRepository {
  @override
  Future<WorkspaceData?> getWorkspaceById(String id) async {
    return WorkspaceData(id: id, checklistItem: 'Review sealing interface');
  }

  @override
  Future<void> saveWorkspace(WorkspaceData workspace) async {}
}

void main() {
  testWidgets('workspace transition keeps an opaque background', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        workspaceRepositoryProvider.overrideWithValue(
          _FakeWorkspaceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    router.go(
      '/workspace/workspace-1'
      '?reviewId=review-1'
      '&projectName=Pump'
      '&stageName=Requirements'
      '&subStepName=Review',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    final background = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('app-route-background')),
    );
    expect(background.color, AppTheme.backgroundLight);
  });
}
