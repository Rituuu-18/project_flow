import '../../../../core/utils/enums.dart';
import 'default_stages.dart';
import '../entities/stage.dart';

/// Fixed DRL (Design Readiness Level) weights per substep.
///
/// Each key is a canonical stage name (must match the names in
/// [defaultStageChecklist]). The value is an ordered list of weights (in %)
/// for every canonical substep within that stage. Lookup resolves by name so a
/// partially migrated review cannot assign a neighbour's weight to an item.
///
/// Only substeps whose [StageStatus] is [StageStatus.completed] contribute
/// their weight to the total DRL. All other statuses contribute 0%.
///
/// Existing Preliminary Design weights are unchanged and its three new items
/// add 1.71% each. Other positive weights were scaled from 88.00% to 82.87%,
/// rounded down to cents, then remaining cents assigned by largest remainder
/// in canonical stage/substep order. Zero-weight items remain at zero.
///
/// The weights across all stages sum to exactly 100.00%.
const Map<String, List<double>> drlSubStepWeights = {
  // Step 1 – Requirements (10 substeps)
  'Requirements': [
    1.57, // 1. Define the problem and scope
    1.57, // 2. Identify stakeholders and interfaces
    1.57, // 3. Capture user and business needs
    1.57, // 4. Derive functional requirements
    1.57, // 5. Define performance and quality targets
    1.57, // 6. Establish constraints and boundaries
    1.57, // 7. Non-functional requirements
    1.57, // 8. Validation and testability definition
    0.00, // 9. Requirements document and structure
    1.54, // 10. Review, negotiate, and freeze baseline
  ],

  // Step 2 – Concept (10 substeps)
  'Concept': [
    1.25, // 1. Clarify goals and success criteria
    0.00, // 2. Prepare concept documentation
    0.00, // 3. Identify and invite stakeholders
    0.00, // 4. Present concepts side by side
    1.25, // 5. Evaluate desirability, feasibility, viability
    1.25, // 6. Analyze risks and constraints
    1.25, // 7. Capture structured feedback
    1.25, // 8. Compare and prioritize concepts
    1.27, // 9. Decide and define next steps
    0.00, // 10. Document outcomes and update roadmap
  ],

  // Step 3 – Preliminary Design (15 substeps)
  'Preliminary Design': [
    1.71, // 1. Define PDR objectives and criteria
    1.71, // 2. Perform engineering calculations from allocated requirements
    1.71, // 3. Define systems, subsystems, and interfaces
    1.71, // 4. Select and justify candidate standard components
    0.00, // 5. Prepare design baseline and documentation
    1.71, // 6. Verify requirements allocation and traceability
    0.00, // 7. Review system architecture and functional design
    1.71, // 8. Evaluate key technical aspects and analyses
    1.71, // 9. Check interfaces and compatibility
    1.71, // 10. Assess producibility, materials, and make-or-buy
    0.00, // 11. Review verification and test strategy
    1.71, // 12. Analyze project risks, schedule, and resources
    0.00, // 13. Conduct the review meeting
    1.74, // 14. Decide outcome and actions
    0.00, // 15. Document and baseline the preliminary design
  ],

  // Step 4 – Detailed Design (13 substeps)
  'Detailed Design': [
    0.00, // 1. Confirm review objectives and readiness
    0.00, // 2. Review complete design definition (CAD and drawings)
    2.42, // 3. Check requirements compliance
    2.42, // 4. Assess analyses and simulations
    2.42, // 5. Evaluate manufacturability and assembly (DFMA)
    0.00, // 6. Review materials, components, and standards
    2.42, // 7. Check interfaces and integration
    2.42, // 8. Validate safety, reliability, and compliance aspects
    0.00, // 9. Review documentation and configuration control
    2.42, // 10. Examine project impacts: cost, schedule, and risk
    0.00, // 11. Conduct the review meeting
    2.43, // 12. Decide outcome and approve for next phase
    0.00, // 13. Record lessons learned and improvements
  ],

  // Step 5 – Simulation (FEA,CFD...) (11 substeps)
  'Simulation (FEA,CFD...)': [
    0.94, // 1. Define objectives and success criteria
    0.94, // 2. Plan the simulation strategy
    0.94, // 3. Build or validate models
    0.94, // 4. Set up loads, boundary conditions, and steps
    0.94, // 5. Run simulations and ensure numerical quality
    0.94, // 6. Post-process and interpret results
    0.94, // 7. Correlate with physical data (when available)
    0.00, // 8. Review assumptions, limitations, and risks
    0.00, // 9. Conduct the Simulation Review meeting
    0.94, // 10. Decide design actions and maturity
    0.00, // 11. Document and archive simulation data
  ],

  // Step 6 – Prototype (11 substeps)
  'Prototype': [
    1.05, // 1. Define purpose and acceptance criteria
    1.05, // 2. Plan prototype build and configuration
    1.05, // 3. Inspect build quality and design conformity
    1.05, // 4. Evaluate assembly and manufacturability
    1.05, // 5. Perform basic functional tests
    1.05, // 6. Gather user and stakeholder feedback
    1.05, // 7. Compare results to requirements and simulations
    1.05, // 8. Identify issues, root causes, and design changes
    0.00, // 9. Conduct the Prototype Review meeting
    1.05, // 10. Decide on next steps and build iterations
    0.00, // 11. Document learnings and update baselines
  ],

  // Step 7 – Testing Validation (10 substeps)
  'Testing Validation': [
    2.26, // 1. Test objectives and success criteria confirmed
    2.26, // 2. Verification and validation test plan approved
    2.26, // 3. Test procedures, setups, and instrumentation ready
    2.26, // 4. Test samples, configuration, and revision documented
    0.00, // 5. Test execution completed and anomalies recorded
    2.26, // 6. Results analyzed against requirements and limits
    0.00, // 7. Non-conformances and root causes identified
    0.00, // 8. Corrective actions defined and owners assigned
    0.00, // 9. Re-tests or additional evidence completed as needed
    0.00, // 10. Test report, traceability, and sign-off finalized
  ],

  // Step 8 – Manufacturing Readiness (11 substeps)
  'Manufacturing Readiness': [
    1.05, // 1. Define manufacturing readiness objectives
    1.05, // 2. Assess design for manufacturability
    1.05, // 3. Define and validate manufacturing processes
    1.05, // 4. Develop and qualify tooling, fixtures, and equipment
    1.05, // 5. Build and stabilize the supply chain
    1.05, // 6. Validate process capability and quality control
    1.04, // 7. Confirm cost, throughput, and scalability
    0.00, // 8. Prepare workforce, documentation, and training
    1.04, // 9. Run pilot builds and manufacturing readiness assessments
    1.05, // 10. Manage risks and continuous improvement before launch
    0.00, // 11. Formal manufacturing readiness review and sign-off
  ],

  // Step 9 – Final Release (10 substeps)
  'Final Release': [
    0.00, // 1. Confirm readiness across all domains
    1.32, // 2. Freeze product definition and configuration
    0.00, // 3. Verify documentation completeness
    0.00, // 4. Review test and validation evidence
    1.32, // 5. Confirm manufacturing and supply readiness
    1.32, // 6. Align commercial launch and support
    0.00, // 7. Run a formal Final Release Review
    1.32, // 8. Execute release and deployment
    1.32, // 9. Monitor early production and field performance
    0.00, // 10. Archive and baseline for future changes
  ],

  // Step 10 – Continuous Improvement (10 substeps, all 0%)
  'Continuous Improvement': [
    0.00, // 1. Define improvement goals and metrics
    0.00, // 2. Collect feedback and performance data
    0.00, // 3. Analyze problems and opportunities
    0.00, // 4. Plan improvements (Plan phase of PDCA)
    0.00, // 5. Implement small changes (Do)
    0.00, // 6. Check results and learn (Check)
    0.00, // 7. Standardize successful practices (Act)
    0.00, // 8. Run regular retrospectives and Kaizen activities
    0.00, // 9. Maintain an improvement backlog and governance
    0.00, // 10. Feed improvements into next product iterations
  ],
};

/// Returns the canonical DRL contribution for a substep, regardless of the
/// order or completeness of a persisted stage.
double drlWeightForSubStep(String stageName, String subStepName) {
  final names = defaultStageChecklist[stageName];
  final weights = drlSubStepWeights[stageName];
  if (names == null || weights == null) return 0.0;
  final index = names.indexOf(subStepName);
  return index >= 0 && index < weights.length ? weights[index] : 0.0;
}

/// Calculates the Design Readiness Level from a list of [Stage]s.
///
/// Returns a value between 0.0 and 100.0 (percentage).
/// Only substeps with [StageStatus.completed] contribute their weight.
double calculateDrl(List<Stage> stages) {
  double drl = 0.0;

  for (final stage in stages) {
    for (final subStep in stage.subSteps) {
      if (subStep.status == StageStatus.completed) {
        drl += drlWeightForSubStep(stage.name, subStep.name);
      }
    }
  }

  return drl.clamp(0.0, 100.0);
}
