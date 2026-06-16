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
    'Clarify goals and success criteria',
    'Prepare concept documentation',
    'Identify and invite stakeholders',
    'Present concepts side by side',
    'Assess feasibility (technical & schedule)',
    'Evaluate desirability, feasibility, viability',
    'Analyze risks and constraints',
    'Capture structured feedback',
    'Compare and prioritize concepts',
    'Decide and define next steps',
    'Document outcomes and update roadmap',
  ],
  'Preliminary Design Review': [
    'Define PDR objectives and criteria',
    'Prepare design baseline and documentation',
    'Verify requirements allocation and traceability',
    'Review system architecture and functional design',
    'Evaluate key technical aspects and analyses',
    'Check interfaces and compatibility',
    'Assess producibility, materials, and make-or-buy',
    'Review verification and test strategy',
    'Analyze project risks, schedule, and resources',
    'Conduct the review meeting',
    'Decide outcome and actions',
    'Document and baseline the preliminary design',
  ],
  'Detailed Design Review': [
    'Confirm review objectives and readiness',
    'Review complete design definition (CAD and drawings)',
    'Check requirements compliance',
    'Assess analyses and simulations',
    'Evaluate manufacturability and assembly (DFMA)',
    'Review materials, components, and standards',
    'Check interfaces and integration',
    'Validate safety, reliability, and compliance aspects',
    'Review documentation and configuration control',
    'Examine project impacts: cost, schedule, and risk',
    'Conduct the review meeting',
    'Decide outcome and approve for next phase',
    'Record lessons learned and improvements',
  ],
  'Simulation Review': [
    'Define objectives and success criteria',
    'Plan the simulation strategy',
    'Build or validate models',
    'Set up loads, boundary conditions, and steps',
    'Run simulations and ensure numerical quality',
    'Post-process and interpret results',
    'Correlate with physical data (when available)',
    'Review assumptions, limitations, and risks',
    'Conduct the Simulation Review meeting',
    'Decide design actions and maturity',
    'Document and archive simulation data',
  ],
  'Prototype Review': [
    'Define purpose and acceptance criteria',
    'Plan prototype build and configuration',
    'Inspect build quality and design conformity',
    'Evaluate assembly and manufacturability',
    'Perform basic functional tests',
    'Gather user and stakeholder feedback',
    'Compare results to requirements and simulations',
    'Identify issues, root causes, and design changes',
    'Conduct the Prototype Review meeting',
    'Decide on next steps and build iterations',
    'Document learnings and update baselines',
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
    'Define manufacturing readiness objectives',
    'Assess design for manufacturability',
    'Define and validate manufacturing processes',
    'Develop and qualify tooling, fixtures, and equipment',
    'Build and stabilize the supply chain',
    'Validate process capability and quality control',
    'Confirm cost, throughput, and scalability',
    'Prepare workforce, documentation, and training',
    'Run pilot builds and manufacturing readiness assessments',
    'Manage risks and continuous improvement before launch',
    'Formal manufacturing readiness review and sign-off',
  ],
  'Final Release': [
    'Confirm readiness across all domains',
    'Freeze product definition and configuration',
    'Verify documentation completeness',
    'Review test and validation evidence',
    'Confirm manufacturing and supply readiness',
    'Align commercial launch and support',
    'Run a formal Final Release Review',
    'Execute release and deployment',
    'Monitor early production and field performance',
    'Archive and baseline for future changes',
  ],
  'Continuous Improvement': [
    'Define improvement goals and metrics',
    'Collect feedback and performance data',
    'Analyze problems and opportunities',
    'Plan improvements (Plan phase of PDCA)',
    'Implement small changes (Do)',
    'Check results and learn (Check)',
    'Standardize successful practices (Act)',
    'Run regular retrospectives and Kaizen activities',
    'Maintain an improvement backlog and governance',
    'Feed improvements into next product iterations',
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
