import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';
import 'comment.dart';

class WorkspaceData extends Equatable {
  final String id;
  final String problemStatement;
  final List<String> scopeIn;
  final List<String> scopeOut;
  final String notes;
  final List<String> attachments;
  final List<String> images;
  final List<String> documents;
  final List<Comment> comments;
  final ApprovalStatus approvalStatus;

  // New fields
  final String checklistItem;
  final String itemDescription;
  final String engineeringComments;
  final String actionDescription;
  final String priority;
  final String assignee;
  final String discipline;
  final DateTime? dueDate;
  final List<String> activityLogs;
  final List<String> stakeholders;

  const WorkspaceData({
    required this.id,
    this.problemStatement = '',
    this.scopeIn = const [],
    this.scopeOut = const [],
    this.notes = '',
    this.attachments = const [],
    this.images = const [],
    this.documents = const [],
    this.comments = const [],
    this.approvalStatus = ApprovalStatus.pending,
    this.checklistItem = '',
    this.itemDescription = '',
    this.engineeringComments = '',
    this.actionDescription = '',
    this.priority = 'Medium',
    this.assignee = '',
    this.discipline = '',
    this.dueDate,
    this.activityLogs = const [],
    this.stakeholders = const [],
  });

  @override
  List<Object?> get props => [
        id,
        problemStatement,
        scopeIn,
        scopeOut,
        notes,
        attachments,
        images,
        documents,
        comments,
        approvalStatus,
        checklistItem,
        itemDescription,
        engineeringComments,
        actionDescription,
        priority,
        assignee,
        discipline,
        dueDate,
        activityLogs,
        stakeholders,
      ];

  WorkspaceData copyWith({
    String? id,
    String? problemStatement,
    List<String>? scopeIn,
    List<String>? scopeOut,
    String? notes,
    List<String>? attachments,
    List<String>? images,
    List<String>? documents,
    List<Comment>? comments,
    ApprovalStatus? approvalStatus,
    String? checklistItem,
    String? itemDescription,
    String? engineeringComments,
    String? actionDescription,
    String? priority,
    String? assignee,
    String? discipline,
    DateTime? dueDate,
    List<String>? activityLogs,
    List<String>? stakeholders,
  }) {
    return WorkspaceData(
      id: id ?? this.id,
      problemStatement: problemStatement ?? this.problemStatement,
      scopeIn: scopeIn ?? this.scopeIn,
      scopeOut: scopeOut ?? this.scopeOut,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      images: images ?? this.images,
      documents: documents ?? this.documents,
      comments: comments ?? this.comments,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      checklistItem: checklistItem ?? this.checklistItem,
      itemDescription: itemDescription ?? this.itemDescription,
      engineeringComments: engineeringComments ?? this.engineeringComments,
      actionDescription: actionDescription ?? this.actionDescription,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      discipline: discipline ?? this.discipline,
      dueDate: dueDate ?? this.dueDate,
      activityLogs: activityLogs ?? this.activityLogs,
      stakeholders: stakeholders ?? this.stakeholders,
    );
  }
}

