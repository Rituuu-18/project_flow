import '../../../../core/database/hive_models.dart';
import '../../../../core/utils/enums.dart';
import '../../domain/entities/design_review.dart';
import '../../domain/entities/stage.dart';
import '../../domain/entities/sub_step.dart';
import '../../domain/entities/stakeholder.dart';

extension DesignReviewHiveModelX on DesignReviewHiveModel {
  DesignReview toEntity() {
    return DesignReview(
      id: uuid,
      name: name,
      owner: owner,
      discipline: discipline,
      status: ProjectStatus.values[statusIndex.clamp(0, ProjectStatus.values.length - 1)],
      createdAt: createdAt,
      lastUpdated: lastUpdated,
      imageUrl: imageUrl,
      progress: progress ?? 0.0,
      stages: (stages ?? []).map((s) => s.toEntity()).toList(),
      stakeholders: (stakeholders ?? []).map((s) => s.toEntity()).toList(),
    );
  }
}

extension DesignReviewX on DesignReview {
  DesignReviewHiveModel toHiveModel() {
    return DesignReviewHiveModel()
      ..uuid = id
      ..name = name
      ..owner = owner
      ..discipline = discipline
      ..statusIndex = status.index
      ..createdAt = createdAt
      ..lastUpdated = lastUpdated
      ..imageUrl = imageUrl
      ..progress = progress
      ..stages = stages.map((s) => s.toHiveModel()).toList()
      ..stakeholders = stakeholders.map((s) => s.toHiveModel()).toList();
  }
}

extension StageHiveModelX on StageHiveModel {
  Stage toEntity() {
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

extension StageX on Stage {
  StageHiveModel toHiveModel() {
    return StageHiveModel()
      ..uuid = id
      ..name = name
      ..statusIndex = status.index
      ..progress = progress
      ..lastUpdated = lastUpdated
      ..subSteps = subSteps.map((s) => s.toHiveModel()).toList();
  }
}

extension SubStepHiveModelX on SubStepHiveModel {
  SubStep toEntity() {
    return SubStep(
      id: uuid,
      name: name,
      status: StageStatus.values[statusIndex.clamp(0, StageStatus.values.length - 1)],
      workspaceId: workspaceId,
    );
  }
}

extension SubStepX on SubStep {
  SubStepHiveModel toHiveModel() {
    return SubStepHiveModel()
      ..uuid = id
      ..name = name
      ..statusIndex = status.index
      ..workspaceId = workspaceId;
  }
}

extension StakeholderHiveModelX on StakeholderHiveModel {
  Stakeholder toEntity() {
    return Stakeholder(
      id: uuid,
      name: name,
      role: role,
    );
  }
}

extension StakeholderX on Stakeholder {
  StakeholderHiveModel toHiveModel() {
    return StakeholderHiveModel()
      ..uuid = id
      ..name = name
      ..role = role;
  }
}
