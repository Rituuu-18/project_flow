import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/hive_workspace_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/entities/workspace_data.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return HiveWorkspaceRepository();
});

final workspaceDataProvider = FutureProvider.family<WorkspaceData?, String>((ref, id) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return repository.getWorkspaceById(id);
});
