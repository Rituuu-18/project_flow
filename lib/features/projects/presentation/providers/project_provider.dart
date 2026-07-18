import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_project_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/entities/project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return SupabaseProjectRepository(Supabase.instance.client);
});

final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProjects();
});

