import 'package:uuid/uuid.dart';

import '../entities/stage.dart';
import '../entities/sub_step.dart';

const _uuid = Uuid();

const Map<String, List<String>> defaultStageChecklist = {
  'Requirements': [
    'Define the problem and scope',
    'Identify stakeholders and interfaces',
    'Capture user and business needs',
    'Derive functional requirements',
    'Define performance and quality targets',
    'Establish constraints and boundaries',
    'Non-functional requirements',
    'Validation and testability definition',
    'Requirements document and structure',
    'Review, negotiate, and freeze baseline',
  ],
  'Concept Review': [
    'Clarify review goals and scope',
    'Capture user and stakeholder needs',
    'Document solution concept options',
    'Compare concepts against key requirements',
    'Assess feasibility (technical & schedule)',
    'Identify and list major risks',
    'Estimate cost / benefit for each concept',
    'State key assumptions and constraints',
    'Capture early stakeholder feedback',
    'Select preferred concept and rationale',
    'Assign follow-up actions and owners',
  ],
  'Preliminary Design Review': [
    'Entry criteria met for PDR',
    'Preliminary system architecture complete',
    'Requirements allocated to subsystems',
    'Interfaces identified and documented',
    'Key calculations / simulations available',
    'Technical risks reviewed and updated',
    'Verification strategy drafted',
    'Manufacturability and serviceability considered',
    'Schedule and resources reviewed',
    'PDR actions defined and recorded',
  ],
  'Detailed Design Review': [
    'CAD models complete for all assemblies and parts',
    'Drawings and GD&T checked for critical features',
    'Interfaces and clearances verified in 3D and 2D',
    'Materials, coatings, and finishes specified',
    'Strength / stiffness / thermal analyses reviewed',
    'Fasteners, joints, and sealing strategy verified',
    'Assembly sequence and access reviewed',
    'Tolerance stack-ups and key fit conditions checked',
    'Manufacturability with target processes confirmed',
    'Detailed design documentation ready for release review',
  ],
  'Simulation Review': [
    'Simulation scope, objectives, and acceptance criteria defined',
    'Geometry prepared and simplified for analysis',
    'Mesh strategy and critical regions reviewed',
    'Material models and fluid properties verified',
    'Loads, boundary conditions, and operating cases validated',
    'Solver setup, models, and assumptions reviewed',
    'Convergence behavior and result stability checked',
    'Sensitivity study or mesh independence reviewed where needed',
    'Results compared with hand calculations, baseline, or test data',
    'Simulation conclusions, limitations, and recommendations documented',
  ],
  'Prototype Review': [
    'Prototype build scope and goals confirmed',
    'Prototype configuration and revision documented',
    'Form and ergonomics inspected against intent',
    'Fit to mating parts and interfaces checked',
    'Basic functional tests run under representative use',
    'Assembly process, tools, and time observed',
    'Key usability and safety issues captured',
    'Prototype deviations vs. design and drawing noted',
    'Manufacturing and supplier feedback collected',
    'Prototype learnings and next-iteration actions agreed',
  ],
  'Testing Validation': [
    'Test objectives and success criteria confirmed',
    'Verification and validation test plan approved',
    'Test procedures, setups, and instrumentation ready',
    'Test samples, configuration, and revision documented',
    'Test execution completed and anomalies recorded',
    'Results analyzed against requirements and limits',
    'Non-conformances and root causes identified',
    'Corrective actions defined and owners assigned',
    'Re-tests or additional evidence completed as needed',
    'Test report, traceability, and sign-off finalized',
  ],
  'Manufacturing Readiness': [
    'Production configuration and BOM frozen for build',
    'Critical drawings, specs, and routings released',
    'Tooling, jigs, and fixtures built and validated',
    'Work instructions and inspection plans approved',
    'Suppliers qualified and material lead times confirmed',
    'Process capability and first article results reviewed',
    'Production quality plan and control methods in place',
    'Packaging, labeling, and logistics validated',
    'Production staffing, training, and maintenance prepared',
    'Ramp-up risks, KPIs, and readiness sign-off agreed',
  ],
  'Final Release': [
    'Released configuration and change freeze agreed',
    'All required tests passed or waivers approved',
    'Final drawings, models, and specifications released to PLM',
    'BOM, part numbers, and revision status verified',
    'Regulatory, safety, and compliance approvals confirmed',
    'Service, spares, and documentation packages ready',
    'Customer communication and release notes prepared',
    'Cross-functional release review and sign-off completed',
    'Release data archived with traceability and access control',
    'Post-release monitoring and feedback plan established',
  ],
  'Continuous Improvement': [
    'Weight Optimization',
    'Cost Optimization',
    'Assembly Optimization',
  ],
};

List<Stage> getDefaultStages() {
  final now = DateTime.now();
  return defaultStageChecklist.entries
      .map(
        (entry) => Stage(
          id: _uuid.v4(),
          name: entry.key,
          lastUpdated: now,
          subSteps: entry.value.map(_newSubStep).toList(),
        ),
      )
      .toList();
}

/// Upgrades reviews created with the incomplete legacy Step 4-10 definition.
///
/// Existing stage progress and matching substep workspaces are retained. The
/// canonical checklist is only applied to the known ten-stage review lifecycle,
/// leaving any future custom lifecycle untouched.
List<Stage> upgradeLegacyDefaultStages(List<Stage> stages) {
  if (stages.length != defaultStageChecklist.length) return stages;

  final canonicalNames = defaultStageChecklist.keys.toList();
  final alreadyCurrent = stages.asMap().entries.every((entry) {
    final expectedItems = defaultStageChecklist[canonicalNames[entry.key]]!;
    return entry.value.name == canonicalNames[entry.key] &&
        entry.value.subSteps.map((item) => item.name).toList().join('|') ==
            expectedItems.join('|');
  });
  if (alreadyCurrent) return stages;

  final isLegacyLifecycle =
      stages.take(4).map((stage) => stage.name).toList().join('|') ==
          canonicalNames.take(4).join('|') &&
      stages.skip(4).every((stage) => stage.subSteps.isEmpty);
  if (!isLegacyLifecycle) return stages;

  return stages.asMap().entries.map((entry) {
    final existingStage = entry.value;
    final canonicalName = canonicalNames[entry.key];
    final existingItems = {
      for (final item in existingStage.subSteps) item.name: item,
    };
    final upgradedItems = defaultStageChecklist[canonicalName]!
        .map((name) => existingItems[name] ?? _newSubStep(name))
        .toList();

    return existingStage.copyWith(name: canonicalName, subSteps: upgradedItems);
  }).toList();
}

SubStep _newSubStep(String name) {
  return SubStep(id: _uuid.v4(), name: name, workspaceId: _uuid.v4());
}
