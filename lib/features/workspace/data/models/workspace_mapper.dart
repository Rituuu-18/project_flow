import '../../../../core/database/hive_models.dart';
import '../../domain/entities/workspace_data.dart';
import '../../domain/entities/comment.dart';
import '../../../../core/utils/enums.dart';

extension WorkspaceDataHiveModelX on WorkspaceDataHiveModel {
  WorkspaceData toEntity() {
    return WorkspaceData(
      id: uuid,
      problemStatement: problemStatement,
      scopeIn: scopeIn.toList(),
      scopeOut: scopeOut.toList(),
      notes: notes,
      attachments: attachments.toList(),
      images: images.toList(),
      documents: documents.toList(),
      comments: comments.map((c) => c.toEntity()).toList(),
      approvalStatus: ApprovalStatus.values[approvalStatusIndex],
      checklistItem: checklistItem,
      itemDescription: itemDescription,
      engineeringComments: engineeringComments,
      actionDescription: actionDescription,
      priority: priority,
      assignee: assignee,
      discipline: discipline,
      dueDate: dueDate,
      activityLogs: activityLogs.toList(),
      stakeholders: stakeholders.toList(),
    );
  }
}

extension WorkspaceDataX on WorkspaceData {
  WorkspaceDataHiveModel toHiveModel() {
    return WorkspaceDataHiveModel()
      ..uuid = id
      ..problemStatement = problemStatement
      ..scopeIn = scopeIn
      ..scopeOut = scopeOut
      ..notes = notes
      ..attachments = attachments
      ..images = images
      ..documents = documents
      ..approvalStatusIndex = approvalStatus.index
      ..comments = comments.map((c) => c.toHiveModel()).toList()
      ..checklistItem = checklistItem
      ..itemDescription = itemDescription
      ..engineeringComments = engineeringComments
      ..actionDescription = actionDescription
      ..priority = priority
      ..assignee = assignee
      ..discipline = discipline
      ..dueDate = dueDate
      ..activityLogs = activityLogs
      ..stakeholders = stakeholders;
  }
}

extension CommentHiveModelX on CommentHiveModel {
  Comment toEntity() {
    return Comment(
      id: uuid,
      author: author,
      content: content,
      createdAt: createdAt,
    );
  }
}

extension CommentX on Comment {
  CommentHiveModel toHiveModel() {
    return CommentHiveModel()
      ..uuid = id
      ..author = author
      ..content = content
      ..createdAt = createdAt;
  }
}
