import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';

import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/utils/default_stages.dart';
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
      expect(
        stages[2].subSteps.take(5).map((item) => item.name).toList(),
        [
          'Define PDR objectives and criteria',
          'Perform engineering calculations from allocated requirements',
          'Define systems, subsystems, and interfaces',
          'Select and justify candidate standard components',
          'Prepare design baseline and documentation',
        ],
      );
      expect(
        stages[2].subSteps.map((item) => item.workspaceId).toSet(),
        hasLength(15),
      );
      expect(
        stages[2].subSteps.every((item) => item.status == StageStatus.notStarted),
        isTrue,
      );
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

    test('new PDR workspaces use the requested admin-owned descriptions', () {
      const expected = {
        'Perform engineering calculations from allocated requirements':
            'Calculate loads, stresses, deflection, torque, power, thermal behavior, fatigue life, safety factors, flow, pressure, and other relevant engineering parameters for the selected concept. Trace all calculations back to the applicable project and subsystem requirements.',
        'Define systems, subsystems, and interfaces':
            'Decompose the product into systems and subsystems; allocate functions and requirements; define key physical, electrical, fluid, software, and user interfaces; and establish preliminary performance targets. This aligns directly with the purpose of the PDR and the allocated baseline.',
        'Select and justify candidate standard components':
            'Select preliminary standard components—such as bearings, bolts, fasteners, seals, springs, motors, sensors, gears, couplings, valves, and similar items—using engineering calculations, interface requirements, applicable standards, environmental conditions, supply risk, cost, and manufacturability as selection criteria. Record the alternatives considered and provide the rationale for the final selection.',
      };

      for (final entry in expected.entries) {
        expect(
          getDefaultSubStepInfo(
            stageName: 'Preliminary Design',
            subStepName: entry.key,
          ).description,
          entry.value,
        );
      }
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
  });
}
