import 'package:uuid/uuid.dart';

import '../../../../core/utils/enums.dart';
import '../entities/design_review.dart';
import '../entities/stage.dart';
import '../entities/stakeholder.dart';
import '../entities/sub_step.dart';

const _uuid = Uuid();

/// Creates an independent copy of [source] with new review and child IDs.
///
/// Stakeholders and sub-steps keep names/roles/status but get fresh UUIDs so
/// [saveReview] upserts insert new rows instead of reassigning the original.
DesignReview cloneForCopy(DesignReview source, {DateTime? now}) {
  final timestamp = now ?? DateTime.now();
  return DesignReview(
    id: _uuid.v4(),
    name: 'Copy of ${source.name}',
    owner: source.owner,
    discipline: source.discipline,
    status: ProjectStatus.active,
    createdAt: timestamp,
    lastUpdated: timestamp,
    imageUrl: null,
    progress: 0.0,
    stages: source.stages.map(_cloneStage).toList(),
    stakeholders: source.stakeholders
        .map(
          (s) => Stakeholder(
            id: _uuid.v4(),
            name: s.name,
            role: s.role,
          ),
        )
        .toList(),
  );
}

Stage _cloneStage(Stage stage) {
  return Stage(
    id: _uuid.v4(),
    name: stage.name,
    status: StageStatus.notStarted,
    progress: 0.0,
    lastUpdated: DateTime.now(),
    subSteps: stage.subSteps.map(_cloneSubStep).toList(),
  );
}

SubStep _cloneSubStep(SubStep sub) {
  return SubStep(
    id: _uuid.v4(),
    name: sub.name,
    status: StageStatus.notStarted,
    workspaceId: _uuid.v4(),
  );
}
