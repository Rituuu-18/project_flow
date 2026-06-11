import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/hive_project_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/entities/project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return HiveProjectRepository();
});

final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProjects();
});
