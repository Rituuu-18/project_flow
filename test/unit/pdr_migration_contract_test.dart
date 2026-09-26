import 'dart:io';

import 'package:engineering_werk/features/reviews/domain/utils/default_stages.dart';
import 'package:engineering_werk/features/reviews/domain/utils/drl_weights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backfill uses the canonical PDR descriptions and score weights', () {
    final sql = File(
      'supabase/migrations/20260927000001_preliminary_design_substeps.sql',
    ).readAsStringSync();

    for (final name in defaultStageChecklist['Preliminary Design']!
        .skip(1)
        .take(3)) {
      final description = getDefaultSubStepInfo(
        stageName: 'Preliminary Design',
        subStepName: name,
      ).description;
      expect(sql, contains("'$name'"));
      expect(sql, contains("'$description'"));
    }

    final scoreSection = sql.split('WITH weights(name, points) AS (').last;
    final rows = RegExp(
      r"^\s*\('([^']+)',\s*(\d+\.\d+)\),?$",
      multiLine: true,
    ).allMatches(scoreSection);
    final migrationWeights = {
      for (final match in rows)
        match.group(1)!: double.parse(match.group(2)!),
    };

    expect(migrationWeights.length, rows.length);
    for (final entry in defaultStageChecklist.entries) {
      final weights = drlSubStepWeights[entry.key]!;
      for (var index = 0; index < entry.value.length; index++) {
        final name = entry.value[index];
        final weight = weights[index];
        if (weight > 0) {
          expect(migrationWeights[name], weight, reason: name);
        } else {
          expect(migrationWeights.containsKey(name), isFalse, reason: name);
        }
      }
    }
    expect(
      migrationWeights.values.fold<double>(0, (sum, weight) => sum + weight),
      closeTo(100, 0.0001),
    );
  });
}
