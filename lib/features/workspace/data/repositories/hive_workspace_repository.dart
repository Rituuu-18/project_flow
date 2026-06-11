import 'package:hive/hive.dart';
import '../../../../core/database/hive_models.dart';
import '../../../../core/database/hive_service.dart';
import '../../domain/entities/workspace_data.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../models/workspace_mapper.dart';

class HiveWorkspaceRepository implements WorkspaceRepository {
  final Box<WorkspaceDataHiveModel> _box = HiveService.workspaceBox;

  @override
  Future<WorkspaceData?> getWorkspaceById(String id) async {
    final model = _box.values.where((m) => m.uuid == id).firstOrNull;
    return model?.toEntity();
  }

  @override
  Future<void> saveWorkspace(WorkspaceData workspace) async {
    final model = workspace.toHiveModel();
    await _box.put(workspace.id, model);
  }
}
