import 'package:hive/hive.dart';
import '../../../../core/database/hive_models.dart';
import '../../../../core/database/hive_service.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_mapper.dart';

class HiveProjectRepository implements ProjectRepository {
  final Box<ProjectHiveModel> _box = HiveService.projectsBox;

  @override
  Future<List<Project>> getAllProjects() async {
    return _box.values.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Project?> getProjectById(String id) async {
    final model = _box.values.where((m) => m.uuid == id).firstOrNull;
    return model?.toEntity();
  }

  @override
  Future<void> saveProject(Project project) async {
    final model = project.toHiveModel();
    // Use uuid as key for easier lookups if unique
    await _box.put(project.id, model);
  }

  @override
  Future<void> deleteProject(String id) async {
    await _box.delete(id);
  }

  @override
  Stream<List<Project>> watchProjects() async* {
    yield _box.values.map((m) => m.toEntity()).toList();
    await for (final _ in _box.watch()) {
      yield _box.values.map((m) => m.toEntity()).toList();
    }
  }
}
