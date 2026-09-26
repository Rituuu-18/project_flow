import 'package:engineering_werk/core/utils/enums.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/sub_step.dart';
import 'package:engineering_werk/features/reviews/domain/utils/default_stages.dart';
import 'package:engineering_werk/features/reviews/domain/utils/drl_weights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database enum values round-trip without changing completion', () {
    expect(StageStatusExtension.fromJson('notStarted'), StageStatus.notStarted);
    expect(StageStatusExtension.fromJson('completed'), StageStatus.completed);
    expect(StageStatusExtension.fromJson('notRequired'), StageStatus.notRequired);
    expect(StageStatusExtension.fromJson('Completed'), StageStatus.completed);
  });

  test('weights cover the canonical checklist and total exactly 100%', () {
    var totalCents = 0;
    for (final entry in defaultStageChecklist.entries) {
      final weights = drlSubStepWeights[entry.key];
      expect(weights, isNotNull);
      expect(weights, hasLength(entry.value.length));
      totalCents += weights!.fold<int>(
        0,
        (sum, weight) => sum + (weight * 100).round(),
      );
    }
    expect(totalCents, 10000);
    expect(
      drlSubStepWeights['Preliminary Design']!.reduce((a, b) => a + b),
      closeTo(17.13, 0.0001),
    );
    for (final name
        in defaultStageChecklist['Preliminary Design']!.skip(1).take(3)) {
      expect(drlWeightForSubStep('Preliminary Design', name), 1.71);
    }
    const existingWeights = {
      'Define PDR objectives and criteria': 1.71,
      'Verify requirements allocation and traceability': 1.71,
      'Evaluate key technical aspects and analyses': 1.71,
      'Check interfaces and compatibility': 1.71,
      'Assess producibility, materials, and make-or-buy': 1.71,
      'Analyze project risks, schedule, and resources': 1.71,
      'Decide outcome and actions': 1.74,
    };
    for (final entry in existingWeights.entries) {
      expect(drlWeightForSubStep('Preliminary Design', entry.key), entry.value);
    }
  });

  test('missing saved items never shift another item’s score weight', () {
    final stage = Stage(
      id: 'stage',
      name: 'Preliminary Design',
      lastUpdated: DateTime.now(),
      subSteps: const [
        SubStep(
          id: 'last',
          name: 'Decide outcome and actions',
          workspaceId: 'workspace-last',
          status: StageStatus.completed,
        ),
        SubStep(
          id: 'new',
          name: 'Perform engineering calculations from allocated requirements',
          workspaceId: 'workspace-new',
          status: StageStatus.completed,
        ),
      ],
    );

    expect(calculateDrl([stage]), closeTo(3.45, 0.0001));
    expect(drlWeightForSubStep('Preliminary Design', 'Unknown item'), 0);
  });
}
