import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/design_review.dart';
import '../../domain/repositories/design_review_repository.dart';
import '../../../../core/database/supabase_errors.dart';
import '../../../../core/utils/enums.dart';
import '../../domain/entities/stage.dart';
import '../../domain/entities/sub_step.dart';
import '../../domain/entities/stakeholder.dart';
import '../../domain/utils/default_stages.dart';

/// Supabase-backed implementation of [DesignReviewRepository].
class SupabaseDesignReviewRepository implements DesignReviewRepository {
  final SupabaseClient _supabaseClient;
  
  SupabaseDesignReviewRepository(this._supabaseClient);

  final _controller = StreamController<List<DesignReview>>.broadcast();
  List<DesignReview> _cache = [];

  // Helper to ensure a default project exists because design_reviews requires project_id
  Future<String> _getDefaultProjectId() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    return supabaseCall(() async {
      final response = await _supabaseClient
          .from('projects')
          .select('id')
          .eq('created_by', currentUser.id)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return response['id'] as String;
      }

      final newProjectId = const Uuid().v4();
      await _supabaseClient.from('projects').insert({
        'id': newProjectId,
        'name': 'Default Project',
        'owner': currentUser.id, // TEXT owner
        'discipline': 'General',
        'created_by': currentUser.id,
      });
      return newProjectId;
    }, operation: 'ensureDefaultProject');
  }

  // ── Read ────────────────────────────────────────────────────────────────

  @override
  Future<List<DesignReview>> getAllReviews() async {
    return supabaseCall(() async {
      final response = await _supabaseClient
          .from('design_reviews')
          .select('*, sub_steps(*), stakeholders(*)')
          .order('created_at', ascending: false);

      _cache = (response as List).map((row) => _fromJson(row)).toList();
      _controller.add(_cache);
      return _cache;
    }, operation: 'getAllReviews');
  }

  @override
  Future<DesignReview?> getReviewById(String id) async {
    return supabaseCall(() async {
      final response = await _supabaseClient
          .from('design_reviews')
          .select('*, sub_steps(*), stakeholders(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return _fromJson(response);
    }, operation: 'getReviewById');
  }

  // ── Write ───────────────────────────────────────────────────────────────

  @override
  Future<void> saveReview(DesignReview review) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    await supabaseCall(() async {
      final projectId = await _getDefaultProjectId();

      // 1. Upsert Design Review
      await _supabaseClient.from('design_reviews').upsert({
        'id': review.id,
        'project_id': projectId,
        'name': review.name,
        'owner': review.owner,
        'discipline': review.discipline,
        'image_url': review.imageUrl,
        'progress': review.progress,
        'status': review.status.name,
        'created_by': currentUser.id,
      });

      // 2. Upsert Sub Steps & Workspaces
      final workspacesPayload = <Map<String, dynamic>>[];
      final subStepsPayload = <Map<String, dynamic>>[];
      for (final stage in review.stages) {
        for (final sub in stage.subSteps) {
          workspacesPayload.add({
            'id': sub.workspaceId,
            'created_by': currentUser.id,
          });

          subStepsPayload.add({
            'id': sub.id,
            'design_review_id': review.id,
            'name': sub.name,
            'status': sub.status.name,
            'workspace_id': sub.workspaceId,
          });
        }
      }

      if (workspacesPayload.isNotEmpty) {
        await _supabaseClient.from('workspaces').upsert(
          workspacesPayload,
          onConflict: 'id',
          ignoreDuplicates: true, // Only creates empty workspace if it doesn't exist
        );
      }

      if (subStepsPayload.isNotEmpty) {
        await _supabaseClient.from('sub_steps').upsert(subStepsPayload);
      }

      // 3. Upsert Stakeholders
      if (review.stakeholders.isNotEmpty) {
        final shPayload = review.stakeholders
            .map((sh) => {
                  'id': sh.id,
                  'design_review_id': review.id,
                  'name': sh.name,
                  'role': sh.role,
                })
            .toList();
        await _supabaseClient.from('stakeholders').upsert(shPayload);
      }

      // Update Cache
      final index = _cache.indexWhere((r) => r.id == review.id);
      if (index >= 0) {
        _cache[index] = review;
      } else {
        _cache.insert(0, review);
      }
      _controller.add(_cache);
    }, operation: 'saveReview');
  }

  @override
  Future<void> addStakeholder(String reviewId, Stakeholder stakeholder) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final role = stakeholder.role.trim();

    await supabaseCall(() async {
      await _supabaseClient.from('stakeholders').upsert({
        'id': stakeholder.id,
        'design_review_id': reviewId,
        'name': stakeholder.name.trim(),
        'role': role,
      });

      final index = _cache.indexWhere((r) => r.id == reviewId);
      if (index >= 0) {
        final existing = _cache[index];
        final next = [
          ...existing.stakeholders.where((s) => s.id != stakeholder.id),
          stakeholder.copyWith(role: role),
        ];
        _cache[index] = existing.copyWith(stakeholders: next);
        _controller.add(List<DesignReview>.from(_cache));
      } else {
        // Ensure listeners refresh from network on next watch cycle.
        await getAllReviews();
      }
    }, operation: 'addStakeholder');
  }

  @override
  Future<void> updateImageUrl(String reviewId, String? imageUrl) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    await supabaseCall(() async {
      await _supabaseClient.from('design_reviews').update({
        'image_url': imageUrl,
      }).eq('id', reviewId);

      final index = _cache.indexWhere((r) => r.id == reviewId);
      if (index >= 0) {
        _cache[index] = _cache[index].copyWith(imageUrl: imageUrl);
        _controller.add(List<DesignReview>.from(_cache));
      } else {
        await getAllReviews();
      }
    }, operation: 'updateImageUrl');
  }

  // ── Delete ──────────────────────────────────────────────────────────────

  @override
  Future<void> deleteReview(String id) async {
    await supabaseCall(() async {
      await _supabaseClient.from('design_reviews').delete().eq('id', id);
      _cache.removeWhere((r) => r.id == id);
      _controller.add(_cache);
    }, operation: 'deleteReview');
  }

  // ── Stream ──────────────────────────────────────────────────────────────

  @override
  Stream<List<DesignReview>> watchReviews() async* {
    yield await getAllReviews();
    yield* _controller.stream;
  }

  // ── Serialization ───────────────────────────────────────────────────────

  DesignReview _fromJson(Map<String, dynamic> json) {
    // Reconstruct stages from flat sub_steps
    final flatSubSteps = (json['sub_steps'] as List?)?.map((s) {
      return SubStep(
        id: s['id'] as String,
        name: s['name'] as String,
        status: StageStatus.values.firstWhere(
          (e) => e.name == s['status'],
          orElse: () => StageStatus.notStarted,
        ),
        workspaceId: s['workspace_id'] as String,
      );
    }).toList() ?? [];

    // Group sub-steps back into the 10 stages
    final reconstructedStages = <Stage>[];
    for (final stageName in defaultStageContent.keys) {
      final stageDef = defaultStageContent[stageName]!;
      
      // Find sub-steps that belong to this stage based on name
      final expectedSubStepNames = stageDef.subSteps.keys.toSet();
      final stageSubSteps = flatSubSteps.where((sub) => expectedSubStepNames.contains(sub.name)).toList();
      
      if (stageSubSteps.isNotEmpty) {
        // Calculate progress
        final completed = stageSubSteps.where((s) => s.status == StageStatus.completed).length;
        final notRequired = stageSubSteps.where((s) => s.status == StageStatus.notRequired).length;
        final applicable = stageSubSteps.length - notRequired;
        final progress = applicable > 0 ? completed / applicable : 1.0;

        // Determine stage status
        StageStatus status = StageStatus.notStarted;
        if (applicable == 0) {
          status = StageStatus.notRequired;
        } else if (completed == applicable) {
          status = StageStatus.completed;
        } else if (completed > 0 || stageSubSteps.any((s) => s.status == StageStatus.inProgress)) {
          status = StageStatus.inProgress;
        }

        reconstructedStages.add(Stage(
          id: const Uuid().v4(), // Stage ID is ephemeral now
          name: stageName,
          status: status,
          progress: progress,
          lastUpdated: DateTime.now(), // Ephemeral
          subSteps: stageSubSteps,
        ));
      }
    }

    final stakeholders = (json['stakeholders'] as List?)?.map((sh) => Stakeholder(
      id: sh['id'] as String,
      name: sh['name'] as String,
      role: sh['role'] as String,
    )).toList() ?? [];

    return DesignReview(
      id: json['id'] as String,
      name: json['name'] as String,
      owner: json['owner'] as String? ?? '',
      discipline: json['discipline'] as String? ?? '',
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectStatus.active,
      ),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      lastUpdated: json['last_updated'] != null ? DateTime.parse(json['last_updated'] as String) : DateTime.now(),
      imageUrl: json['image_url'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      stages: reconstructedStages,
      stakeholders: stakeholders,
    );
  }
}
