import '../../../../core/database/hive_models.dart';
import '../../domain/entities/project.dart';
import '../../../reviews/domain/entities/stage.dart';
import '../../../reviews/domain/entities/sub_step.dart';
import '../../../../core/utils/enums.dart';

extension ProjectHiveModelX on ProjectHiveModel {
  Project toEntity() {
    return Project(
      id: uuid,
      name: name,
      description: description,
      owner: owner,
      discipline: discipline,
      imageUrl: imageUrl,
      progress: progress ?? 0.0,
      status: ProjectStatus.values[statusIndex.clamp(0, ProjectStatus.values.length - 1)],
      lastUpdated: lastUpdated,
      stages: (stages ?? []).map((s) => s.toProjectEntity()).toList(),
    );
  }
}

extension ProjectX on Project {
  ProjectHiveModel toHiveModel() {
    return ProjectHiveModel()
      ..uuid = id
      ..name = name
      ..description = description
      ..owner = owner
      ..discipline = discipline
      ..imageUrl = imageUrl
      ..progress = progress
      ..statusIndex = status.index
      ..lastUpdated = lastUpdated
      ..stages = stages.map((s) => s.toProjectHiveModel()).toList();
  }
}

// Named differently to avoid clash with the extension in design_review_mapper.dart
extension StageHiveModelProjectX on StageHiveModel {
  Stage toProjectEntity() {
    return Stage(
      id: uuid,
      name: name,
      status: StageStatus.values[statusIndex.clamp(0, StageStatus.values.length - 1)],
      progress: progress ?? 0.0,
      lastUpdated: lastUpdated,
      subSteps: (subSteps ?? []).map((s) => s.toEntity()).toList(),
    );
  }
}

extension StageProjectX on Stage {
  StageHiveModel toProjectHiveModel() {
    return StageHiveModel()
      ..uuid = id
      ..name = name
      ..statusIndex = status.index
      ..progress = progress
      ..lastUpdated = lastUpdated
      ..subSteps = subSteps.map((s) => s.toHiveModel()).toList();
  }
}

extension SubStepHiveModelProjectX on SubStepHiveModel {
  SubStep toEntity() {
    return SubStep(
      id: uuid,
      name: name,
      status: StageStatus.values[statusIndex.clamp(0, StageStatus.values.length - 1)],
      workspaceId: workspaceId,
    );
  }
}

extension SubStepProjectX on SubStep {
  SubStepHiveModel toHiveModel() {
    return SubStepHiveModel()
      ..uuid = id
      ..name = name
      ..statusIndex = status.index
      ..workspaceId = workspaceId;
  }
}
