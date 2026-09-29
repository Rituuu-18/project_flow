import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';

import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/utils/default_stages.dart';
import 'package:engineering_werk/features/reviews/domain/utils/drl_weights.dart';
import 'package:engineering_werk/core/utils/enums.dart';

void main() {
  group('DesignReview Entity', () {
    final now = DateTime.now();
    final review = DesignReview(
      id: '1',
      name: 'Test Review',
      owner: 'John Doe',
      discipline: 'Mechanical',
      createdAt: now,
      lastUpdated: now,
    );

    test('should create DesignReview with correct values', () {
      expect(review.id, '1');
      expect(review.name, 'Test Review');
      expect(review.owner, 'John Doe');
      expect(review.discipline, 'Mechanical');
      expect(review.status, ProjectStatus.active);
      expect(review.createdAt, now);
      expect(review.lastUpdated, now);
    });

    test('copyWith should return a new instance with updated values', () {
      final updated = review.copyWith(
        name: 'Updated Name',
        status: ProjectStatus.completed,
      );
      expect(updated.name, 'Updated Name');
      expect(updated.status, ProjectStatus.completed);
      expect(updated.id, '1'); // remains unchanged
    });

    test('Equality works correctly', () {
      final review2 = DesignReview(
        id: '1',
        name: 'Test Review',
        owner: 'John Doe',
        discipline: 'Mechanical',
        createdAt: now,
        lastUpdated: now,
      );
      expect(review, equals(review2));
    });
  });

  group('Default review lifecycle', () {
    test('contains the complete PDF-backed canonical checklist', () {
      final stages = getDefaultStages();

      expect(stages, hasLength(10));
      expect(stages[1].name, 'Concept');
      expect(stages[1].subSteps, hasLength(10));
      expect(
        stages[1].subSteps.map((item) => item.name),
        isNot(contains('Assess feasibility (technical & schedule)')),
      );
      expect(stages[2].name, 'Preliminary Design');
      expect(stages[2].subSteps, hasLength(15));
      expect(stages[2].subSteps.skip(1).take(3).map((item) => item.name), [
        'Define systems, subsystems, and interfaces',
        'Perform engineering calculations from allocated requirements',
        'Select and justify candidate standard components',
      ]);
      expect(stages[3].name, 'Detailed Design');
      expect(stages[3].subSteps, hasLength(13));
      expect(stages[4].name, 'Simulation (FEA,CFD...)');
      expect(stages[4].subSteps, hasLength(11));
      expect(stages[5].name, 'Prototype');
      expect(stages[5].subSteps, hasLength(11));
      expect(stages[6].name, 'Testing Validation');
      expect(stages[6].subSteps, hasLength(10));
      expect(stages[7].name, 'Manufacturing Readiness');
      expect(stages[7].subSteps, hasLength(11));
      expect(stages[8].name, 'Final Release');
      expect(stages[8].subSteps, hasLength(10));
      expect(stages[9].name, 'Continuous Improvement');
      expect(stages[9].subSteps, hasLength(10));
      expect(
        getDefaultSubStepInfo(
          stageName: 'Concept',
          subStepName: 'Clarify goals and success criteria',
        ).description,
        contains('go/no-go criteria'),
      );
    });

    test('upgrades the incomplete saved lifecycle', () {
      final now = DateTime.now();
      final current = getDefaultStages();
      final legacy = [
        ...current.take(4),
        for (final name in [
          'Critical Design Review',
          'Integration & Test Review',
          'Verification & Validation',
          'Pre-Production Review',
          'Production Readiness Review',
          'Final Release',
        ])
          Stage(id: name, name: name, lastUpdated: now),
      ];

      final upgraded = upgradeLegacyDefaultStages(legacy);

      expect(upgraded[4].name, 'Simulation (FEA,CFD...)');
      expect(upgraded[4].subSteps, hasLength(11));
      expect(upgraded[9].name, 'Continuous Improvement');
      expect(upgraded[9].subSteps, hasLength(10));
    });

    test(
      'adds scoreable PDR items to saved reviews without losing existing work',
      () {
        final current = getDefaultStages();
        final pdr = current[2];
        final existingItem = pdr.subSteps[5].copyWith(
          status: StageStatus.completed,
        );
        final oldPdr = pdr.copyWith(
          subSteps: [
            pdr.subSteps.first,
            pdr.subSteps[4],
            existingItem,
            ...pdr.subSteps.skip(6),
          ],
        );
        final saved = [...current]..[2] = oldPdr;

        final upgraded = upgradeLegacyDefaultStages(
          saved,
          reviewId: 'review-1',
        );
        final items = upgraded[2].subSteps;

        expect(items, hasLength(15));
        expect(
          items
              .skip(1)
              .take(3)
              .every(
                (item) =>
                    item.status == StageStatus.notStarted &&
                    item.workspaceId.isNotEmpty,
              ),
          isTrue,
        );
        expect(items[5], existingItem);
        expect(upgraded[2].progress, 1 / 15);
        expect(upgradeLegacyDefaultStages(upgraded), same(upgraded));
        final reloaded = upgradeLegacyDefaultStages(
          saved,
          reviewId: 'review-1',
        );
        expect(
          reloaded[2].subSteps.skip(1).take(3).map((item) => item.id),
          items.skip(1).take(3).map((item) => item.id),
        );
        expect(
          reloaded[2].subSteps.skip(1).take(3).map((item) => item.workspaceId),
          items.skip(1).take(3).map((item) => item.workspaceId),
        );

        final weights = drlSubStepWeights['Preliminary Design']!;
        expect(weights, hasLength(items.length));
        expect(weights.skip(1).take(3).every((weight) => weight > 0), isTrue);
        expect(weights.reduce((a, b) => a + b), closeTo(12.0, 0.0001));
        expect(calculateDrl(upgraded), closeTo(weights[5], 0.0001));

        final completedNewItem = upgraded[2].copyWith(
          subSteps: [
            items.first,
            items[1].copyWith(status: StageStatus.completed),
            ...items.skip(2),
          ],
        );
        final scored = [...upgraded]..[2] = completedNewItem;
        expect(calculateDrl(scored), closeTo(weights[1] + weights[5], 0.0001));
      },
    );
  });
}
