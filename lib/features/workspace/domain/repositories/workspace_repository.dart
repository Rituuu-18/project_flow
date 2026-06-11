import '../../domain/entities/workspace_data.dart';

abstract class WorkspaceRepository {
  Future<WorkspaceData?> getWorkspaceById(String id);
  Future<void> saveWorkspace(WorkspaceData workspace);
}
