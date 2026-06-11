// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DesignReviewHiveModelAdapter extends TypeAdapter<DesignReviewHiveModel> {
  @override
  final int typeId = 5;

  @override
  DesignReviewHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DesignReviewHiveModel()
      ..uuid = fields[0] as String
      ..name = fields[1] as String
      ..owner = fields[2] as String
      ..discipline = fields[3] as String
      ..statusIndex = fields[4] as int
      ..createdAt = fields[5] as DateTime
      ..lastUpdated = fields[6] as DateTime
      ..imageUrl = fields[7] as String?
      ..progress = fields[8] as double?
      ..stages = (fields[9] as List?)?.cast<StageHiveModel>()
      ..stakeholders = (fields[10] as List?)?.cast<StakeholderHiveModel>();
  }

  @override
  void write(BinaryWriter writer, DesignReviewHiveModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.owner)
      ..writeByte(3)
      ..write(obj.discipline)
      ..writeByte(4)
      ..write(obj.statusIndex)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.progress)
      ..writeByte(9)
      ..write(obj.stages)
      ..writeByte(10)
      ..write(obj.stakeholders);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesignReviewHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StakeholderHiveModelAdapter extends TypeAdapter<StakeholderHiveModel> {
  @override
  final int typeId = 6;

  @override
  StakeholderHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StakeholderHiveModel()
      ..uuid = fields[0] as String
      ..name = fields[1] as String
      ..role = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, StakeholderHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.role);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StakeholderHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProjectHiveModelAdapter extends TypeAdapter<ProjectHiveModel> {
  @override
  final int typeId = 0;

  @override
  ProjectHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectHiveModel()
      ..uuid = fields[0] as String
      ..name = fields[1] as String
      ..description = fields[2] as String
      ..progress = fields[3] as double?
      ..statusIndex = fields[4] as int
      ..lastUpdated = fields[5] as DateTime
      ..stages = (fields[6] as List?)?.cast<StageHiveModel>()
      ..owner = fields[7] as String
      ..discipline = fields[8] as String
      ..imageUrl = fields[9] as String?;
  }

  @override
  void write(BinaryWriter writer, ProjectHiveModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.progress)
      ..writeByte(4)
      ..write(obj.statusIndex)
      ..writeByte(5)
      ..write(obj.lastUpdated)
      ..writeByte(6)
      ..write(obj.stages)
      ..writeByte(7)
      ..write(obj.owner)
      ..writeByte(8)
      ..write(obj.discipline)
      ..writeByte(9)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StageHiveModelAdapter extends TypeAdapter<StageHiveModel> {
  @override
  final int typeId = 1;

  @override
  StageHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StageHiveModel()
      ..uuid = fields[0] as String
      ..name = fields[1] as String
      ..statusIndex = fields[2] as int
      ..progress = fields[3] as double?
      ..lastUpdated = fields[4] as DateTime
      ..subSteps = (fields[5] as List?)?.cast<SubStepHiveModel>();
  }

  @override
  void write(BinaryWriter writer, StageHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.statusIndex)
      ..writeByte(3)
      ..write(obj.progress)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.subSteps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubStepHiveModelAdapter extends TypeAdapter<SubStepHiveModel> {
  @override
  final int typeId = 4;

  @override
  SubStepHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubStepHiveModel()
      ..uuid = fields[0] as String
      ..name = fields[1] as String
      ..statusIndex = fields[2] as int
      ..workspaceId = fields[3] as String;
  }

  @override
  void write(BinaryWriter writer, SubStepHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.statusIndex)
      ..writeByte(3)
      ..write(obj.workspaceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubStepHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkspaceDataHiveModelAdapter
    extends TypeAdapter<WorkspaceDataHiveModel> {
  @override
  final int typeId = 2;

  @override
  WorkspaceDataHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkspaceDataHiveModel()
      ..uuid = fields[0] as String
      ..problemStatement = fields[1] as String
      ..scopeIn = (fields[2] as List).cast<String>()
      ..scopeOut = (fields[3] as List).cast<String>()
      ..notes = fields[4] as String
      ..attachments = (fields[5] as List).cast<String>()
      ..images = (fields[6] as List).cast<String>()
      ..documents = (fields[7] as List).cast<String>()
      ..approvalStatusIndex = fields[8] as int
      ..comments = (fields[9] as List).cast<CommentHiveModel>()
      ..checklistItem = fields[10] as String
      ..itemDescription = fields[11] as String
      ..engineeringComments = fields[12] as String
      ..actionDescription = fields[13] as String
      ..priority = fields[14] as String
      ..assignee = fields[15] as String
      ..discipline = fields[16] as String
      ..dueDate = fields[17] as DateTime?
      ..activityLogs = (fields[18] as List).cast<String>()
      ..stakeholders = (fields[19] as List).cast<String>();
  }

  @override
  void write(BinaryWriter writer, WorkspaceDataHiveModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.problemStatement)
      ..writeByte(2)
      ..write(obj.scopeIn)
      ..writeByte(3)
      ..write(obj.scopeOut)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.attachments)
      ..writeByte(6)
      ..write(obj.images)
      ..writeByte(7)
      ..write(obj.documents)
      ..writeByte(8)
      ..write(obj.approvalStatusIndex)
      ..writeByte(9)
      ..write(obj.comments)
      ..writeByte(10)
      ..write(obj.checklistItem)
      ..writeByte(11)
      ..write(obj.itemDescription)
      ..writeByte(12)
      ..write(obj.engineeringComments)
      ..writeByte(13)
      ..write(obj.actionDescription)
      ..writeByte(14)
      ..write(obj.priority)
      ..writeByte(15)
      ..write(obj.assignee)
      ..writeByte(16)
      ..write(obj.discipline)
      ..writeByte(17)
      ..write(obj.dueDate)
      ..writeByte(18)
      ..write(obj.activityLogs)
      ..writeByte(19)
      ..write(obj.stakeholders);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceDataHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CommentHiveModelAdapter extends TypeAdapter<CommentHiveModel> {
  @override
  final int typeId = 3;

  @override
  CommentHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommentHiveModel()
      ..uuid = fields[0] as String
      ..author = fields[1] as String
      ..content = fields[2] as String
      ..createdAt = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, CommentHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.author)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
