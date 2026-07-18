import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_workspace_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/entities/workspace_data.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return SupabaseWorkspaceRepository(Supabase.instance.client);
});

final workspaceDataProvider = FutureProvider.family<WorkspaceData?, String>((ref, id) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return repository.getWorkspaceById(id);
});

