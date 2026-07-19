import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/workspace_data.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../../../core/database/supabase_errors.dart';
import '../../../../core/utils/enums.dart';

class SupabaseWorkspaceRepository implements WorkspaceRepository {
  final SupabaseClient _supabaseClient;

  SupabaseWorkspaceRepository(this._supabaseClient);

  @override
  Future<WorkspaceData?> getWorkspaceById(String id) async {
    return supabaseCall(() async {
      final response = await _supabaseClient
          .from('workspaces')
          .select('*, workspace_comments(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return _fromJson(response);
    }, operation: 'getWorkspaceById');
  }

  @override
  Future<void> saveWorkspace(WorkspaceData workspace) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    await supabaseCall(() async {
      // 1. Upsert Workspace
      await _supabaseClient.from('workspaces').upsert({
        'id': workspace.id,
        'problem_statement': workspace.problemStatement,
        'scope_in': workspace.scopeIn,
        'scope_out': workspace.scopeOut,
        'notes': workspace.notes,
        'attachments': workspace.attachments,
        'images': workspace.images,
        'documents': workspace.documents,
        'approval_status': workspace.approvalStatus.name,
        'checklist_item': workspace.checklistItem,
        'item_description': workspace.itemDescription,
        'engineering_comments': workspace.engineeringComments,
        'action_description': workspace.actionDescription,
        'priority': workspace.priority,
        'assignee': workspace.assignee,
        'discipline': workspace.discipline,
        'due_date': workspace.dueDate?.toIso8601String(),
        'activity_logs': workspace.activityLogs,
        'stakeholders': workspace.stakeholders,
        'created_by': currentUser.id,
      });

      // 2. Upsert Comments
      // We only upsert comments if they exist. To handle deletions correctly,
      // a real production app might use a separate endpoint or sync mechanism.
      // Here we'll just upsert the ones provided.
      if (workspace.comments.isNotEmpty) {
        final commentsPayload = workspace.comments
            .map((c) => {
                  'id': c.id,
                  'workspace_id': workspace.id,
                  'author': c.author,
                  'content': c.content,
                  'created_at': c.createdAt.toIso8601String(),
                })
            .toList();

        await _supabaseClient.from('workspace_comments').upsert(commentsPayload);
      }
    }, operation: 'saveWorkspace');
  }

  WorkspaceData _fromJson(Map<String, dynamic> json) {
    final commentsList = (json['workspace_comments'] as List?)?.map((c) => Comment(
      id: c['id'] as String,
      author: c['author'] as String,
      content: c['content'] as String,
      createdAt: DateTime.parse(c['created_at'] as String),
    )).toList() ?? [];

    return WorkspaceData(
      id: json['id'] as String,
      problemStatement: json['problem_statement'] as String? ?? '',
      scopeIn: (json['scope_in'] as List?)?.cast<String>() ?? const [],
      scopeOut: (json['scope_out'] as List?)?.cast<String>() ?? const [],
      notes: json['notes'] as String? ?? '',
      attachments: (json['attachments'] as List?)?.cast<String>() ?? const [],
      images: (json['images'] as List?)?.cast<String>() ?? const [],
      documents: (json['documents'] as List?)?.cast<String>() ?? const [],
      comments: commentsList,
      approvalStatus: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['approval_status'],
        orElse: () => ApprovalStatus.pending,
      ),
      checklistItem: json['checklist_item'] as String? ?? '',
      itemDescription: json['item_description'] as String? ?? '',
      engineeringComments: json['engineering_comments'] as String? ?? '',
      actionDescription: json['action_description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Medium',
      assignee: json['assignee'] as String? ?? '',
      discipline: json['discipline'] as String? ?? '',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      activityLogs: (json['activity_logs'] as List?)?.cast<String>() ?? const [],
      stakeholders: (json['stakeholders'] as List?)?.cast<String>() ?? const [],
    );
  }
}
