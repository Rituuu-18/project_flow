import 'package:engineering_werk/core/utils/enums.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stakeholder.dart';
import 'package:engineering_werk/features/reviews/domain/entities/sub_step.dart';
import 'package:engineering_werk/features/reviews/domain/utils/clone_for_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cloneForCopy', () {
    test('creates independent ids for review, stages, substeps, stakeholders',
        () {
      final now = DateTime(2026, 1, 1);
      final source = DesignReview(
        id: 'review-1',
        name: 'Pump Housing',
        owner: 'Ada',
        discipline: 'Mechanical',
        createdAt: now,
        lastUpdated: now,
        imageUrl: 'https://example.com/cover.png',
        progress: 0.4,
        stakeholders: const [
          Stakeholder(id: 'sh-1', name: 'Alice', role: 'Structures'),
        ],
        stages: [
          Stage(
            id: 'stage-1',
            name: 'Requirements',
            status: StageStatus.inProgress,
            progress: 0.5,
            lastUpdated: now,
            subSteps: const [
              SubStep(
                id: 'sub-1',
                name: 'Define the problem and scope',
                status: StageStatus.completed,
                workspaceId: 'ws-1',
              ),
            ],
          ),
        ],
      );

      final copy = cloneForCopy(source, now: DateTime(2026, 2, 1));

      expect(copy.id, isNot(source.id));
      expect(copy.name, 'Copy of Pump Housing');
      expect(copy.status, ProjectStatus.active);
      expect(copy.progress, 0);
      expect(copy.imageUrl, isNull);
      expect(copy.stakeholders, hasLength(1));
      expect(copy.stakeholders.single.id, isNot('sh-1'));
      expect(copy.stakeholders.single.name, 'Alice');
      expect(copy.stakeholders.single.role, 'Structures');

      expect(copy.stages, hasLength(1));
      expect(copy.stages.single.id, isNot('stage-1'));
      expect(copy.stages.single.name, 'Requirements');
      expect(copy.stages.single.status, StageStatus.notStarted);
      expect(copy.stages.single.subSteps, hasLength(1));
      expect(copy.stages.single.subSteps.single.id, isNot('sub-1'));
      expect(copy.stages.single.subSteps.single.workspaceId, isNot('ws-1'));
      expect(
        copy.stages.single.subSteps.single.name,
        'Define the problem and scope',
      );
      expect(
        copy.stages.single.subSteps.single.status,
        StageStatus.notStarted,
      );
    });
  });
}
