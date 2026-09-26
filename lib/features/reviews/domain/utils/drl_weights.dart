import '../../../../core/utils/enums.dart';
import '../entities/stage.dart';

/// Fixed DRL (Design Readiness Level) weights per substep.
///
/// Each key is a canonical stage name (must match the names in
/// [defaultStageChecklist]). The value is an ordered list of weights (in %)
/// for every substep within that stage, matched **by index**.
///
/// Only substeps whose [StageStatus] is [StageStatus.completed] contribute
/// their weight to the total DRL. All other statuses contribute 0%.
///
/// The weights across all stages sum to exactly 100.00%.
const Map<String, List<double>> drlSubStepWeights = {
  // Step 1 – Requirements (10 substeps)
  'Requirements': [
    1.67, // 1. Define the problem and scope
    1.67, // 2. Identify stakeholders and interfaces
    1.67, // 3. Capture user and business needs
    1.67, // 4. Derive functional requirements
    1.67, // 5. Define performance and quality targets
    1.67, // 6. Establish constraints and boundaries
    1.67, // 7. Non-functional requirements
    1.67, // 8. Validation and testability definition
    0.00, // 9. Requirements document and structure
    1.64, // 10. Review, negotiate, and freeze baseline
  ],

  // Step 2 – Concept (10 substeps)
  'Concept': [
    1.33, // 1. Clarify goals and success criteria
    0.00, // 2. Prepare concept documentation
    0.00, // 3. Identify and invite stakeholders
    0.00, // 4. Present concepts side by side
    1.33, // 5. Evaluate desirability, feasibility, viability
    1.33, // 6. Analyze risks and constraints
    1.33, // 7. Capture structured feedback
    1.33, // 8. Compare and prioritize concepts
    1.35, // 9. Decide and define next steps
    0.00, // 10. Document outcomes and update roadmap
  ],

  // Step 3 – Preliminary Design (12 substeps)
  'Preliminary Design': [
    1.71, // 1. Define PDR objectives and criteria
    0.00, // 2. Prepare design baseline and documentation
    1.71, // 3. Verify requirements allocation and traceability
    0.00, // 4. Review system architecture and functional design
    1.71, // 5. Evaluate key technical aspects and analyses
    1.71, // 6. Check interfaces and compatibility
    1.71, // 7. Assess producibility, materials, and make-or-buy
    0.00, // 8. Review verification and test strategy
    1.71, // 9. Analyze project risks, schedule, and resources
    0.00, // 10. Conduct the review meeting
    1.74, // 11. Decide outcome and actions
    0.00, // 12. Document and baseline the preliminary design
  ],

  // Step 4 – Detailed Design (13 substeps)
  'Detailed Design': [
    0.00, // 1. Confirm review objectives and readiness
    0.00, // 2. Review complete design definition (CAD and drawings)
    2.57, // 3. Check requirements compliance
    2.57, // 4. Assess analyses and simulations
    2.57, // 5. Evaluate manufacturability and assembly (DFMA)
    0.00, // 6. Review materials, components, and standards
    2.57, // 7. Check interfaces and integration
    2.57, // 8. Validate safety, reliability, and compliance aspects
    0.00, // 9. Review documentation and configuration control
    2.57, // 10. Examine project impacts: cost, schedule, and risk
    0.00, // 11. Conduct the review meeting
    2.58, // 12. Decide outcome and approve for next phase
    0.00, // 13. Record lessons learned and improvements
  ],

  // Step 5 – Simulation (FEA,CFD...) (11 substeps)
  'Simulation (FEA,CFD...)': [
    1.00, // 1. Define objectives and success criteria
    1.00, // 2. Plan the simulation strategy
    1.00, // 3. Build or validate models
    1.00, // 4. Set up loads, boundary conditions, and steps
    1.00, // 5. Run simulations and ensure numerical quality
    1.00, // 6. Post-process and interpret results
    1.00, // 7. Correlate with physical data (when available)
    0.00, // 8. Review assumptions, limitations, and risks
    0.00, // 9. Conduct the Simulation Review meeting
    1.00, // 10. Decide design actions and maturity
    0.00, // 11. Document and archive simulation data
  ],

  // Step 6 – Prototype (11 substeps)
  'Prototype': [
    1.11, // 1. Define purpose and acceptance criteria
    1.11, // 2. Plan prototype build and configuration
    1.11, // 3. Inspect build quality and design conformity
    1.11, // 4. Evaluate assembly and manufacturability
    1.11, // 5. Perform basic functional tests
    1.11, // 6. Gather user and stakeholder feedback
    1.11, // 7. Compare results to requirements and simulations
    1.11, // 8. Identify issues, root causes, and design changes
    0.00, // 9. Conduct the Prototype Review meeting
    1.12, // 10. Decide on next steps and build iterations
    0.00, // 11. Document learnings and update baselines
  ],

  // Step 7 – Testing Validation (6 substeps)
  'Testing Validation': [
    2.40, // 1. Test objectives and success criteria confirmed
    2.40, // 2. Verification and validation test plan approved
    2.40, // 3. Test procedures, setups, and instrumentation ready
    2.40, // 4. Test samples, configuration, and revision documented
    0.00, // 5. Test execution completed and anomalies recorded
    2.40, // 6. Results analyzed against requirements and limits
  ],

  // Step 8 – Manufacturing Readiness (11 substeps)
  'Manufacturing Readiness': [
    1.11, // 1. Define manufacturing readiness objectives
    1.11, // 2. Assess design for manufacturability
    1.11, // 3. Define and validate manufacturing processes
    1.11, // 4. Develop and qualify tooling, fixtures, and equipment
    1.11, // 5. Build and stabilize the supply chain
    1.11, // 6. Validate process capability and quality control
    1.11, // 7. Confirm cost, throughput, and scalability
    0.00, // 8. Prepare workforce, documentation, and training
    1.11, // 9. Run pilot builds and manufacturing readiness assessments
    1.12, // 10. Manage risks and continuous improvement before launch
    0.00, // 11. Formal manufacturing readiness review and sign-off
  ],

  // Step 9 – Final Release (10 substeps)
  'Final Release': [
    0.00, // 1. Confirm readiness across all domains
    1.40, // 2. Freeze product definition and configuration
    0.00, // 3. Verify documentation completeness
    0.00, // 4. Review test and validation evidence
    1.40, // 5. Confirm manufacturing and supply readiness
    1.40, // 6. Align commercial launch and support
    0.00, // 7. Run a formal Final Release Review
    1.40, // 8. Execute release and deployment
    1.40, // 9. Monitor early production and field performance
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

/// Calculates the Design Readiness Level from a list of [Stage]s.
///
/// Returns a value between 0.0 and 100.0 (percentage).
/// Only substeps with [StageStatus.completed] contribute their weight.
double calculateDrl(List<Stage> stages) {
  double drl = 0.0;

  for (final stage in stages) {
    final weights = drlSubStepWeights[stage.name];
    if (weights == null) continue;

    for (int i = 0; i < stage.subSteps.length; i++) {
      if (i >= weights.length) break;
      if (stage.subSteps[i].status == StageStatus.completed) {
        drl += weights[i];
      }
    }
  }

  return drl.clamp(0.0, 100.0);
}
