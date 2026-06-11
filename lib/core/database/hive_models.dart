import 'package:hive/hive.dart';

part 'hive_models.g.dart';

// ──────────────────────────────────────────────
// Design Review Hive Model  (typeId: 5)
// ──────────────────────────────────────────────
@HiveType(typeId: 5)
class DesignReviewHiveModel extends HiveObject {
  @HiveField(0)
  late String uuid;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String owner;

  @HiveField(3)
  late String discipline;

  @HiveField(4)
  late int statusIndex;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime lastUpdated;

  @HiveField(7)
  String? imageUrl;

  @HiveField(8)
  double? progress;

  @HiveField(9)
  List<StageHiveModel>? stages;

  @HiveField(10)
  List<StakeholderHiveModel>? stakeholders;
}

// ──────────────────────────────────────────────
// Stakeholder Hive Model  (typeId: 6)
// ──────────────────────────────────────────────
@HiveType(typeId: 6)
class StakeholderHiveModel extends HiveObject {
  @HiveField(0)
  late String uuid;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String role;
}

// ──────────────────────────────────────────────
// Project Hive Model  (typeId: 0)
// ──────────────────────────────────────────────
@HiveType(typeId: 0)
class ProjectHiveModel extends HiveObject {
  @HiveField(0)
  late String uuid;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String description;

  @HiveField(3)
  double? progress;

  @HiveField(4)
  late int statusIndex;

  @HiveField(5)
  late DateTime lastUpdated;

  @HiveField(6)
  List<StageHiveModel>? stages;

  @HiveField(7)
  late String owner;

  @HiveField(8)
  late String discipline;

  @HiveField(9)
  String? imageUrl;
}

// ──────────────────────────────────────────────
// Stage Hive Model  (typeId: 1)
// ──────────────────────────────────────────────
@HiveType(typeId: 1)
class StageHiveModel extends HiveObject {
  @HiveField(0)
  late String uuid;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int statusIndex;

  @HiveField(3)
  double? progress;

  @HiveField(4)
  late DateTime lastUpdated;

  @HiveField(5)
  List<SubStepHiveModel>? subSteps;
}

// ──────────────────────────────────────────────
// SubStep Hive Model  (typeId: 4)
// ──────────────────────────────────────────────
@HiveType(typeId: 4)
class SubStepHiveModel extends HiveObject {
  @HiveField(0)
  late String uuid;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int statusIndex;

  @HiveField(3)
  late String workspaceId;
}

// ──────────────────────────────────────────────
// Workspace Data Hive Model  (typeId: 2)
// ──────────────────────────────────────────────
@HiveType(typeId: 2)
class WorkspaceDataHiveModel extends HiveObject {
  @HiveField(0)
  late String uuid;

  @HiveField(1)
  late String problemStatement;

  @HiveField(2)
  late List<String> scopeIn;

  @HiveField(3)
  late List<String> scopeOut;

  @HiveField(4)
  late String notes;

  @HiveField(5)
  late List<String> attachments;

  @HiveField(6)
  late List<String> images;

  @HiveField(7)
  late List<String> documents;

  @HiveField(8)
  late int approvalStatusIndex;

  @HiveField(9)
  late List<CommentHiveModel> comments;

  @HiveField(10)
  late String checklistItem;

  @HiveField(11)
  late String itemDescription;

  @HiveField(12)
  late String engineeringComments;

  @HiveField(13)
  late String actionDescription;

  @HiveField(14)
  late String priority;

  @HiveField(15)
  late String assignee;

  @HiveField(16)
  late String discipline;

  @HiveField(17)
  DateTime? dueDate;

  @HiveField(18)
  late List<String> activityLogs;

  @HiveField(19)
  late List<String> stakeholders;
}

// ──────────────────────────────────────────────
// Comment Hive Model  (typeId: 3)
// ──────────────────────────────────────────────
@HiveType(typeId: 3)
class CommentHiveModel extends HiveObject {
  @HiveField(0)
  late String uuid;

  @HiveField(1)
  late String author;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime createdAt;
}
