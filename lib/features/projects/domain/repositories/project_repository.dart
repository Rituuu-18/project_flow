import '../../domain/entities/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> getAllProjects();
  Future<Project?> getProjectById(String id);
  Future<void> saveProject(Project project);
  Future<void> deleteProject(String id);
  Stream<List<Project>> watchProjects();
}
