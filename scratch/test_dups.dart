import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'lib/features/reviews/domain/utils/default_stages.dart';
import 'lib/features/reviews/domain/entities/stage.dart';
import 'lib/features/reviews/domain/entities/sub_step.dart';
import 'lib/core/utils/enums.dart';

void main() {
  // Simulate JSON response from Supabase
  final List<Map<String, dynamic>> subStepsJson = [];
  
  // Create mock DB data
  for (final stageName in defaultStageContent.keys) {
    final stageDef = defaultStageContent[stageName]!;
    for (final name in stageDef.subSteps.keys) {
      subStepsJson.add({
        'id': Uuid().v4(),
        'name': name,
        'status': 'notStarted',
        'workspace_id': Uuid().v4(),
      });
    }
  }

  // Run the logic from _fromJson
  final flatSubSteps = subStepsJson.map((s) {
    return SubStep(
      id: s['id'] as String,
      name: s['name'] as String,
      status: StageStatus.values.firstWhere(
        (e) => e.name == s['status'],
        orElse: () => StageStatus.notStarted,
      ),
      workspaceId: s['workspace_id'] as String,
    );
  }).toList();

  final reconstructedStages = <Stage>[];
  for (final stageName in defaultStageContent.keys) {
    final stageDef = defaultStageContent[stageName]!;
    
    final expectedSubStepNames = stageDef.subSteps.keys.toList();
    final stageSubSteps = <SubStep>[];
    for (final expectedName in expectedSubStepNames) {
      final matchIndex = flatSubSteps.indexWhere((sub) => sub.name == expectedName);
      if (matchIndex != -1) {
        stageSubSteps.add(flatSubSteps.removeAt(matchIndex));
      }
    }
    
    reconstructedStages.add(Stage(
      id: Uuid().v4(),
      name: stageName,
      status: StageStatus.notStarted,
      progress: 0.0,
      lastUpdated: DateTime.now(),
      subSteps: stageSubSteps,
    ));
  }

  // Check for duplicates in subStepsPayload
  final seenIds = <String>{};
  bool hasDuplicate = false;
  for (final stage in reconstructedStages) {
    for (final sub in stage.subSteps) {
      if (seenIds.contains(sub.id)) {
        print('DUPLICATE ID FOUND: \${sub.id} (Name: \${sub.name})');
        hasDuplicate = true;
      }
      seenIds.add(sub.id);
    }
  }

  if (!hasDuplicate) {
    print('No duplicates found! The logic works.');
  }
}
