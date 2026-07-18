import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../../../core/utils/enums.dart';

class SupabaseProjectRepository implements ProjectRepository {
  final SupabaseClient _supabaseClient;

  SupabaseProjectRepository(this._supabaseClient);

  final _controller = StreamController<List<Project>>.broadcast();
  List<Project> _cache = [];

  @override
  Future<List<Project>> getAllProjects() async {
    final response = await _supabaseClient
        .from('projects')
        .select()
        .order('created_at', ascending: false);
    
    _cache = (response as List).map((row) => _fromJson(row)).toList();
    _controller.add(_cache);
    return _cache;
  }

  @override
  Future<Project?> getProjectById(String id) async {
    final response = await _supabaseClient
        .from('projects')
        .select()
        .eq('id', id)
        .maybeSingle();
        
    if (response == null) return null;
    return _fromJson(response);
  }

  @override
  Future<void> saveProject(Project project) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    await _supabaseClient.from('projects').upsert({
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'owner': project.owner,
      'discipline': project.discipline,
      'image_url': project.imageUrl,
      'progress': project.progress,
      'status': project.status.name,
      'created_by': currentUser.id,
    });

    final index = _cache.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _cache[index] = project;
    } else {
      _cache.insert(0, project);
    }
    _controller.add(_cache);
  }

  @override
  Future<void> deleteProject(String id) async {
    await _supabaseClient.from('projects').delete().eq('id', id);
    _cache.removeWhere((p) => p.id == id);
    _controller.add(_cache);
  }

  @override
  Stream<List<Project>> watchProjects() async* {
    yield await getAllProjects();
    yield* _controller.stream;
  }

  Project _fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      discipline: json['discipline'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectStatus.active,
      ),
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'] as String) 
          : DateTime.now(),
      stages: const [], // Not fetching nested stages directly to avoid over-fetching
    );
  }
}
