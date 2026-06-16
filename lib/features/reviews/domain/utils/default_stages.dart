import 'package:uuid/uuid.dart';

import '../../../../core/utils/enums.dart';
import '../entities/stage.dart';
import '../entities/sub_step.dart';

const _uuid = Uuid();

class StageDefaultContent {
  final String description;
  final Map<String, SubStepDefaultInfo> subSteps;

  const StageDefaultContent({
    required this.description,
    required this.subSteps,
  });
}

class SubStepDefaultInfo {
  final String description;
  final String discipline;

  const SubStepDefaultInfo({
    required this.description,
    required this.discipline,
  });
}

const defaultSubStepFallback = SubStepDefaultInfo(
  description:
      'Record the review context, engineering observations, decisions, evidence, and follow-up actions for this checklist item.',
  discipline: 'General Engineering',
);

const Map<String, StageDefaultContent> defaultStageContent = {
  'Requirements': StageDefaultContent(
    description:
        'Define the problem, project scope, stakeholders, requirements, constraints, and verification basis before design work starts.',
    subSteps: {
      'Define the problem and scope': SubStepDefaultInfo(
        description:
            'Clarify the core problem the product must solve, who it is for, and the operating context. Define what is included in the project and what is explicitly out of scope so the team can avoid uncontrolled scope growth.',
        discipline: 'Systems Engineering',
      ),
      'Identify stakeholders and interfaces': SubStepDefaultInfo(
        description:
            'List customers, internal teams, regulators, suppliers, service groups, and other decision makers. Identify product, infrastructure, software, standards, and external-system interfaces that the design must support.',
        discipline: 'Systems Engineering',
      ),
      'Capture user and business needs': SubStepDefaultInfo(
        description:
            'Gather needs from interviews, workshops, field observations, issue reports, competitor review, and business inputs. Convert those inputs into clear need statements such as reduced installation time, higher throughput, lower service effort, or compliance with a target standard.',
        discipline: 'Product Definition',
      ),
      'Derive functional requirements': SubStepDefaultInfo(
        description:
            'Translate needs into functions the system must perform, with measurable success criteria for each function. Include required ranges, loads, accuracy, response times, control behavior, and other values that can be verified later.',
        discipline: 'Requirements',
      ),
      'Define performance and quality targets': SubStepDefaultInfo(
        description:
            'Set performance targets such as capacity, speed, efficiency, noise, energy use, lifetime, reliability, and environmental robustness. Capture quality expectations including temperature, vibration, ingress protection, safety integrity, and allowed failure rates.',
        discipline: 'Requirements',
      ),
      'Establish constraints and boundaries': SubStepDefaultInfo(
        description:
            'Document regulatory norms, company standards, safety rules, available technologies, preferred materials, platform reuse, schedule milestones, target markets, budget, target cost, and selling-price boundaries.',
        discipline: 'Program Management',
      ),
      'Non-functional requirements': SubStepDefaultInfo(
        description:
            'Capture usability, ergonomics, accessibility, installation time, maintenance interval, service access, diagnostics, data logging, cybersecurity needs for connected products, documentation, and labeling expectations.',
        discipline: 'Lifecycle Engineering',
      ),
      'Validation and testability definition': SubStepDefaultInfo(
        description:
            'Define how each requirement will be verified: analysis, simulation, inspection, lab test, field test, certification, or acceptance test. Make requirements specific, measurable, achievable, relevant, time-bound, and traceable to a validation method.',
        discipline: 'Verification',
      ),
      'Requirements document and structure': SubStepDefaultInfo(
        description:
            'Compile the requirement set into a structured specification with scope, stakeholders, functional and non-functional requirements, constraints, and verification details. Use stable IDs so requirements can be traced through design, tests, and changes.',
        discipline: 'Documentation',
      ),
      'Review, negotiate, and freeze baseline': SubStepDefaultInfo(
        description:
            'Run a Requirements Review with key stakeholders to check completeness, consistency, conflicts, and feasibility. Resolve conflicts, adjust unrealistic requirements, approve the baseline, and move future changes into a controlled change process.',
        discipline: 'Review Board',
      ),
    },
  ),
  'Concept Review': StageDefaultContent(
    description:
        'Compare solution concepts against requirements, feasibility, risk, business fit, and the preferred path before deeper design investment.',
    subSteps: {
      'Clarify goals and success criteria': SubStepDefaultInfo(
        description:
            'Define the exact questions this Concept Review must answer, including technical feasibility, requirement coverage, business fit, risk level, budget, and schedule. Agree on go/no-go criteria up front so the team knows what passing the review means.',
        discipline: 'Product Strategy',
      ),
      'Prepare concept documentation': SubStepDefaultInfo(
        description:
            'Create concise concept packages for each option, including the problem statement, target users, high-level architecture or mechanism, key features, and sizing or capacity assumptions. Add customer pain points, market inputs, competitor comparison, and rough cost-benefit expectations.',
        discipline: 'Product Definition',
      ),
      'Identify and invite stakeholders': SubStepDefaultInfo(
        description:
            'Select reviewers from engineering, design, manufacturing, testing, quality, marketing, service, and management so all relevant perspectives are present. Make their role clear: challenge assumptions, assess risks, and decide which concepts move forward.',
        discipline: 'Review Board',
      ),
      'Present concepts side by side': SubStepDefaultInfo(
        description:
            'Present each concept at a comparable level of detail using the same template, function diagram, rough layout, main components, and user interaction view. Highlight differences in working principle, complexity, expected performance, manufacturability, and novelty.',
        discipline: 'Systems Engineering',
      ),
      'Evaluate desirability, feasibility, viability': SubStepDefaultInfo(
        description:
            'Rate each concept for desirability, feasibility, and viability. Cover user value and differentiation, technical risk and development effort, and business impact such as lifecycle cost, margin, revenue potential, and strategy fit.',
        discipline: 'Product Strategy',
      ),
      'Analyze risks and constraints': SubStepDefaultInfo(
        description:
            'Identify major technical, schedule, cost, regulatory, supplier, tooling, process, IP, or licensing risks for each concept. Capture dependencies and blockers early, including new materials, unproven processes, or special supplier needs.',
        discipline: 'Risk Management',
      ),
      'Capture structured feedback': SubStepDefaultInfo(
        description:
            'During the review, record strengths, weaknesses, open questions, requested investigations, and concerns per concept. Use scorecards, ranking sheets, or expert scoring so feedback can be compared instead of relying on the loudest voice.',
        discipline: 'Review Facilitation',
      ),
      'Compare and prioritize concepts': SubStepDefaultInfo(
        description:
            'Aggregate scores and qualitative assessments to rank concepts by promise, requirement coverage, and acceptable risk. Eliminate weak concepts and, where useful, select a primary concept plus a backup variant for limited exploration.',
        discipline: 'Decision Analysis',
      ),
      'Decide and define next steps': SubStepDefaultInfo(
        description:
            'Make a clear decision: proceed, refine and re-review, combine concepts, or stop the project. For the selected concept, define concrete Preliminary Design actions such as analyses, experiments, supplier discussions, and business-case updates.',
        discipline: 'Program Management',
      ),
      'Document outcomes and update roadmap': SubStepDefaultInfo(
        description:
            'Record the decision, rationale, selected concept, assumptions, and known risks, then link the record to the requirements baseline. Update the product roadmap and communicate the outcome to stakeholders who were not in the review.',
        discipline: 'Documentation',
      ),
    },
  ),
  'Preliminary Design Review': StageDefaultContent(
    description:
        'Confirm that the selected concept has a sound architecture, allocated requirements, clear interfaces, early evidence, and understood risks before detailed design.',
    subSteps: {
      'Define PDR objectives and criteria': SubStepDefaultInfo(
        description:
            'Clarify that the PDR must confirm requirement allocation, architecture soundness, major risks, and mitigation plans. Set entry and exit criteria such as required maturity, analyses available, and documents ready before the meeting.',
        discipline: 'Systems Engineering',
      ),
      'Prepare design baseline and documentation': SubStepDefaultInfo(
        description:
            'Compile the preliminary design package with system architecture, block diagrams, major assemblies, interfaces, performance budgets, calculations, and simulations. Include the product tree, work breakdown, technical specifications, verification plan, configuration plan, risk plan, and quality plan.',
        discipline: 'Design Engineering',
      ),
      'Verify requirements allocation and traceability': SubStepDefaultInfo(
        description:
            'Show how each top-level requirement is allocated to subsystems and components using a traceability matrix or equivalent method. Check that the design can in principle meet capacity, accuracy, interface, environment, safety, and reliability needs, and flag requirements at risk.',
        discipline: 'Requirements',
      ),
      'Review system architecture and functional design': SubStepDefaultInfo(
        description:
            'Present functional descriptions and diagrams showing major functions, data flows, energy flows, and control logic. Confirm the architecture is complete, avoids unnecessary complexity, and respects constraints such as redundancy, scalability, and single-point-failure rules.',
        discipline: 'Systems Architecture',
      ),
      'Evaluate key technical aspects and analyses': SubStepDefaultInfo(
        description:
            'Assess whether the expected maturity-level analyses are complete, including structural, thermal, electrical, sizing, performance, and critical simulations. Review early reliability, safety, hazard, environmental, thermal, and calibration inputs that will drive detailed design.',
        discipline: 'Analysis',
      ),
      'Check interfaces and compatibility': SubStepDefaultInfo(
        description:
            'Examine mechanical, electrical, software, data, and external-system interfaces such as mounting points, connectors, communication protocols, and envelopes. Verify loads, mass, power, memory, timing, data rates, and space claims are defined, feasible, and consistent.',
        discipline: 'Integration',
      ),
      'Assess producibility, materials, and make-or-buy': SubStepDefaultInfo(
        description:
            'Review major material choices, manufacturing processes, tolerancing approach, and whether the design appears producible with available capability. Decide preliminary make-or-buy direction and identify long-lead parts, special tooling, or facilities that need early action.',
        discipline: 'Manufacturing Engineering',
      ),
      'Review verification and test strategy': SubStepDefaultInfo(
        description:
            'Present the draft verification plan showing which requirements will be verified by analysis, simulation, inspection, qualification tests, and acceptance tests. Confirm testability is built into the design through sensor access, calibration features, diagnostics, and built-in checks.',
        discipline: 'Verification',
      ),
      'Analyze project risks, schedule, and resources': SubStepDefaultInfo(
        description:
            'Summarize technical and program risks with likelihood, impact, and mitigation plans. Confirm the schedule, budget, and resource estimates for detailed design, prototyping, and testing are realistic for the design complexity and risk profile.',
        discipline: 'Program Management',
      ),
      'Conduct the review meeting': SubStepDefaultInfo(
        description:
            'Ensure engineering, manufacturing, quality, testing, program management, suppliers, and other stakeholders receive the package in advance. Walk through the design against PDR objectives and capture requests for action, findings, and observations in a structured way.',
        discipline: 'Review Board',
      ),
      'Decide outcome and actions': SubStepDefaultInfo(
        description:
            'Decide whether to pass PDR and proceed, pass with actions, require re-review, redirect, or stop. Assign owners and due dates for all actions, analyses, design changes, and documentation updates before the next milestone.',
        discipline: 'Decision Board',
      ),
      'Document and baseline the preliminary design': SubStepDefaultInfo(
        description:
            'Record minutes, findings, decisions, updated risks, and the approved preliminary design package. Baseline the allocated design so later changes go through controlled change management and remain traceable to PDR decisions.',
        discipline: 'Configuration Management',
      ),
    },
  ),
  'Detailed Design Review': StageDefaultContent(
    description:
        'Verify that the detailed design is engineered, documented, producible, safe, reliable, and ready for simulation, prototype, or production release.',
    subSteps: {
      'Confirm review objectives and readiness': SubStepDefaultInfo(
        description:
            'Define what the DDR must confirm: the detailed design implements requirements, is producible, safe, reliable, and ready for the next release. Check entry criteria such as complete models, drawings, critical analyses, and PDR actions closed or under clear control.',
        discipline: 'Design Engineering',
      ),
      'Review complete design definition (CAD and drawings)': SubStepDefaultInfo(
        description:
            'Inspect 3D CAD models for geometry, constraints, clearances, interferences, motion, and assembly sequence feasibility. Review drawings for views, dimensions, tolerances, surface finishes, GD&T, material specifications, weld symbols, and standard notes.',
        discipline: 'Mechanical Design',
      ),
      'Check requirements compliance': SubStepDefaultInfo(
        description:
            'Trace each functional, performance, safety, regulatory, reliability, and environmental requirement to design features, calculations, or analyses. Identify requirements that are unmet, partly met, or deferred to later verification, and document risks or waivers.',
        discipline: 'Requirements',
      ),
      'Assess analyses and simulations': SubStepDefaultInfo(
        description:
            'Review strength, fatigue, thermal, vibration, fluid-flow, kinematic, tolerance-stack, and worst-case analyses. Confirm safety factors, margins, and performance reserves meet guidelines and that assumptions match real use cases.',
        discipline: 'Analysis',
      ),
      'Evaluate manufacturability and assembly (DFMA)': SubStepDefaultInfo(
        description:
            'Check that features, tolerances, and processes suit the selected manufacturing methods such as machining, casting, molding, or sheet metal. Evaluate part count, assembly access, standard components, fastener access, mistake-proofing, and the need for special tools or jigs.',
        discipline: 'Manufacturing Engineering',
      ),
      'Review materials, components, and standards': SubStepDefaultInfo(
        description:
            'Verify materials, treatments, and coatings against strength, corrosion, wear, weight, cost, and availability needs. Prefer standard hardware and approved parts where possible, and confirm long-lead or special components are identified and approved.',
        discipline: 'Materials Engineering',
      ),
      'Check interfaces and integration': SubStepDefaultInfo(
        description:
            'Confirm mechanical, electrical, fluid, and software interfaces match the corresponding subsystems and external systems. Validate interface control documents, reference models, and integration diagrams for clashes, overlaps, and inconsistent specifications.',
        discipline: 'Integration',
      ),
      'Validate safety, reliability, and compliance aspects': SubStepDefaultInfo(
        description:
            'Review guards, interlocks, fail-safe behavior, emergency stops, warning labels, and relevant norms or standards. Assess maintainability and reliability through service access, derating, redundancy, diagnostics, and FMEA or similar evidence.',
        discipline: 'Safety and Reliability',
      ),
      'Review documentation and configuration control': SubStepDefaultInfo(
        description:
            'Ensure BOMs, drawings, CAD, specifications, interface documents, calculations, and test or inspection requirements are current and consistent. Confirm unique IDs, revision control, change history, and future change rules are in place.',
        discipline: 'Configuration Management',
      ),
      'Examine project impacts: cost, schedule, and risk': SubStepDefaultInfo(
        description:
            'Review cost estimates for material, manufacturing, assembly, tooling, testing, and lifecycle impact. Update the risk register for tight tolerances, new processes, supplier dependencies, schedule pressure, and required contingencies.',
        discipline: 'Program Management',
      ),
      'Conduct the review meeting': SubStepDefaultInfo(
        description:
            'Invite design, analysis, manufacturing, quality, supply chain, service, and program stakeholders, and share the package in advance. Walk through the system and key subsystems, collect findings, and log actions with owners and due dates.',
        discipline: 'Review Board',
      ),
      'Decide outcome and approve for next phase': SubStepDefaultInfo(
        description:
            'Decide whether the design is approved, approved with minor actions, conditionally approved pending major actions, or rejected for redesign and re-review. If approved, release the design to simulation, prototype build, manufacturing, or the relevant next baseline.',
        discipline: 'Decision Board',
      ),
      'Record lessons learned and improvements': SubStepDefaultInfo(
        description:
            'Document key issues, root causes, good practices, and decisions from the DDR so future projects benefit from the review. Update review templates, checklists, and design standards based on what worked well or poorly.',
        discipline: 'Continuous Improvement',
      ),
    },
  ),
  'Simulation Review': StageDefaultContent(
    description:
        'Validate the design with virtual models, load cases, assumptions, numerical quality, and correlation evidence before or alongside prototypes.',
    subSteps: {
      'Define objectives and success criteria': SubStepDefaultInfo(
        description:
            'Clarify why simulations are being run: requirement compliance, design comparison, safety-factor sizing, performance optimization, or cost reduction. Define quantitative success criteria such as stress, deflection, pressure drop, temperature, factor of safety, stability margin, or requirement limits.',
        discipline: 'Simulation',
      ),
      'Plan the simulation strategy': SubStepDefaultInfo(
        description:
            'Decide which analyses are needed, such as structural, fatigue, thermal, CFD, vibration, modal, crash, kinematics, multi-body dynamics, or system-level simulation. Define load cases, operating conditions, worst-case scenarios, and transient events for each type.',
        discipline: 'CAE Planning',
      ),
      'Build or validate models': SubStepDefaultInfo(
        description:
            'Create or clean geometry, choose idealizations such as symmetry, shell versus solid, rigid versus flexible, and generate a suitable mesh. Select material models, nonlinear behavior, damping, contact definitions, and properties that are accurate enough for the decision.',
        discipline: 'CAE Modeling',
      ),
      'Set up loads, boundary conditions, and steps': SubStepDefaultInfo(
        description:
            'Apply realistic forces, pressures, flows, torques, contacts, thermal loads, constraints, and motion inputs based on use cases and test plans. For nonlinear or time-dependent problems, define load steps and substeps so loading is stable and critical events are captured.',
        discipline: 'CAE Setup',
      ),
      'Run simulations and ensure numerical quality': SubStepDefaultInfo(
        description:
            'Execute analyses with solver settings such as time step, convergence tolerance, contact setting, and substep control tuned for stability and performance. Check convergence, energy balance, contact penetration, mesh sensitivity, and time-step sensitivity, then refine as needed.',
        discipline: 'Simulation',
      ),
      'Post-process and interpret results': SubStepDefaultInfo(
        description:
            'Extract stress, strain, displacement, safety factor, flow, pressure, temperature, frequency, mode, and time-response results. Compare results with objectives and requirements, and identify hotspots, margins, unexpected behavior, and failure modes.',
        discipline: 'Analysis',
      ),
      'Correlate with physical data (when available)': SubStepDefaultInfo(
        description:
            'Compare simulation predictions with prototype, historical, or test measurements when data exists. Record whether correlation is good, acceptable with caveats, or poor, and explain how that affects confidence in design decisions.',
        discipline: 'Test Correlation',
      ),
      'Review assumptions, limitations, and risks': SubStepDefaultInfo(
        description:
            'List modeling assumptions such as simplified geometry, idealized materials, boundary conditions, ignored effects, and coverage gaps. Explain how they may bias results and define mitigations such as extra testing, refined models, or added safety factors.',
        discipline: 'Risk Management',
      ),
      'Conduct the Simulation Review meeting': SubStepDefaultInfo(
        description:
            'Share a structured report in advance with objectives, models, assumptions, load cases, plots, results-versus-requirements tables, conclusions, and recommendations. Walk stakeholders through major simulations, critical findings, questions, and required follow-up actions.',
        discipline: 'Review Board',
      ),
      'Decide design actions and maturity': SubStepDefaultInfo(
        description:
            'Use the evidence to decide whether the design is acceptable, needs local reinforcement or optimization, or requires deeper architectural changes. Prioritize design changes, additional simulations, and physical tests with owners and deadlines.',
        discipline: 'Decision Board',
      ),
      'Document and archive simulation data': SubStepDefaultInfo(
        description:
            'Store input files, result files, post-processing scripts, review minutes, and traceability links in a controlled location. Summarize validated models and learnings so future projects can reuse them and improve the simulation approach.',
        discipline: 'Documentation',
      ),
    },
  ),
  'Prototype Review': StageDefaultContent(
    description:
        'Evaluate the first physical builds for design conformity, function, manufacturability, usability, issues, and build-iteration decisions.',
    subSteps: {
      'Define purpose and acceptance criteria': SubStepDefaultInfo(
        description:
            'Clarify whether the prototype is for concept proof, functional validation, ergonomics, manufacturability, or demonstration. Set acceptance criteria for which functions must work, expected tolerances or performance, and what can remain rough at this stage.',
        discipline: 'Prototype Planning',
      ),
      'Plan prototype build and configuration': SubStepDefaultInfo(
        description:
            'Decide prototype type and fidelity, such as looks-like, works-like, full functional, partial subsystem, or demonstration unit. Plan build source, materials, processes, quantity, and documented configuration for review and testing.',
        discipline: 'Prototype Planning',
      ),
      'Inspect build quality and design conformity': SubStepDefaultInfo(
        description:
            'Inspect each prototype against drawings and CAD for dimensions, tolerances, mating-part fit, alignment, and finish where relevant. Record deviations, temporary concessions, rework, and missing features so design issues are separated from prototype-process issues.',
        discipline: 'Quality',
      ),
      'Evaluate assembly and manufacturability': SubStepDefaultInfo(
        description:
            'Observe the assembly process, number of steps, difficulty, required tools, risk of incorrect assembly, and actual versus planned assembly time. Identify DFMA issues such as excess part count, awkward fastener access, interference, or hard-to-produce features.',
        discipline: 'Manufacturing Engineering',
      ),
      'Perform basic functional tests': SubStepDefaultInfo(
        description:
            'Run core functional checks tied to the prototype goals, such as motion, load bearing, fluid paths, thermal behavior, safety features, controls, and basic performance. Note failures, noise, vibration, instability, or shortfalls and link them to likely design or build causes.',
        discipline: 'Testing',
      ),
      'Gather user and stakeholder feedback': SubStepDefaultInfo(
        description:
            'Let representative users, technicians, and internal stakeholders interact with the prototype. Capture structured qualitative comments and simple ratings for usability, ergonomics, accessibility, indicator clarity, and perceived quality.',
        discipline: 'User Research',
      ),
      'Compare results to requirements and simulations': SubStepDefaultInfo(
        description:
            'Compare prototype behavior with requirements and simulation predictions such as deflection, temperature, force, or performance. Use gaps between prediction and reality to update models, refine assumptions, and decide whether margins are adequate.',
        discipline: 'Verification',
      ),
      'Identify issues, root causes, and design changes': SubStepDefaultInfo(
        description:
            'Log findings in a defect list with category, severity, and suspected root cause across fit, function, safety, usability, and manufacturability. Propose design actions such as geometry changes, tolerance changes, material updates, added features, or process changes, and estimate their impact.',
        discipline: 'Problem Solving',
      ),
      'Conduct the Prototype Review meeting': SubStepDefaultInfo(
        description:
            'Prepare a review package with prototype configuration, photos, test results, user feedback, issue list, and proposed changes. Walk through fit and finish, function, usability, DFMA, and safety findings, and decide which changes are mandatory versus optional.',
        discipline: 'Review Board',
      ),
      'Decide on next steps and build iterations': SubStepDefaultInfo(
        description:
            'Decide whether to move toward validation testing, build an improved prototype generation, or reconsider fundamental design choices. Define the next build scope, timing, changes included, unit count, and new tests to perform.',
        discipline: 'Program Management',
      ),
      'Document learnings and update baselines': SubStepDefaultInfo(
        description:
            'Update design documents, CAD, drawings, and BOMs with approved changes while preserving traceability to prototype findings. Capture lessons about processes, suppliers, build methods, and test setups so later prototypes and projects avoid repeated issues.',
        discipline: 'Documentation',
      ),
    },
  ),
  'Testing Validation': StageDefaultContent(
    description:
        'Confirm that test planning, execution, evidence, non-conformances, corrective actions, traceability, and sign-off prove the product meets requirements.',
    subSteps: {
      'Test objectives and success criteria confirmed': SubStepDefaultInfo(
        description:
            'Define what the validation campaign must prove and which requirements, limits, standards, and customer conditions it covers. Confirm measurable pass/fail criteria before test execution starts.',
        discipline: 'Verification',
      ),
      'Verification and validation test plan approved': SubStepDefaultInfo(
        description:
            'Review the full test plan, including methods, sample counts, acceptance criteria, schedule, responsibilities, risks, and required approvals. Confirm the plan covers analysis, inspection, qualification, acceptance, and field or lab validation as needed.',
        discipline: 'Test Engineering',
      ),
      'Test procedures, setups, and instrumentation ready': SubStepDefaultInfo(
        description:
            'Confirm procedures, fixtures, rigs, data acquisition, sensors, calibration records, software versions, and safety controls are ready. Check that the setup can measure the required values with adequate accuracy and repeatability.',
        discipline: 'Test Engineering',
      ),
      'Test samples, configuration, and revision documented': SubStepDefaultInfo(
        description:
            'Record each test sample, serial number, build configuration, hardware revision, software or firmware version, concessions, and pre-test condition. Make sure every result can be traced to the exact configuration tested.',
        discipline: 'Configuration Management',
      ),
      'Test execution completed and anomalies recorded': SubStepDefaultInfo(
        description:
            'Execute tests according to approved procedures and capture raw data, observations, environmental conditions, and operator notes. Record anomalies, interruptions, deviations, and retests with enough context to evaluate validity.',
        discipline: 'Testing',
      ),
      'Results analyzed against requirements and limits': SubStepDefaultInfo(
        description:
            'Analyze measured data against requirement limits, acceptance criteria, standards, and expected trends. Identify pass/fail status, margins, uncertainty, and any results that need engineering judgment or further evidence.',
        discipline: 'Analysis',
      ),
      'Non-conformances and root causes identified': SubStepDefaultInfo(
        description:
            'Document failures, deviations, and non-conformances with severity, affected requirements, likely causes, and containment actions. Use root-cause methods before approving design or process changes.',
        discipline: 'Quality',
      ),
      'Corrective actions defined and owners assigned': SubStepDefaultInfo(
        description:
            'Define corrective and preventive actions for failed or weak results, including design changes, process updates, documentation changes, or additional tests. Assign owners, due dates, decision criteria, and approval needs.',
        discipline: 'Program Management',
      ),
      'Re-tests or additional evidence completed as needed': SubStepDefaultInfo(
        description:
            'Run retests, supplemental analyses, inspections, or simulations needed to close gaps or verify corrective actions. Link the added evidence back to the original issue and requirement.',
        discipline: 'Verification',
      ),
      'Test report, traceability, and sign-off finalized': SubStepDefaultInfo(
        description:
            'Finalize the test report with objectives, configuration, methods, results, anomalies, conclusions, requirement traceability, open risks, and approvals. Store the signed evidence package as the release or gate reference.',
        discipline: 'Documentation',
      ),
    },
  ),
  'Manufacturing Readiness': StageDefaultContent(
    description:
        'Prove the design can be built reliably at the required volume, cost, quality, and readiness level using capable processes and suppliers.',
    subSteps: {
      'Define manufacturing readiness objectives': SubStepDefaultInfo(
        description:
            'Clarify what ready means for the project, such as pilot build, low-rate production, or full series production. Choose a manufacturing readiness framework or target level and define the evidence required before launch.',
        discipline: 'Manufacturing Engineering',
      ),
      'Assess design for manufacturability': SubStepDefaultInfo(
        description:
            'Review part count, complexity, tolerances, special features, cycle-time drivers, scrap risks, and process suitability. Identify design changes or process solutions needed to reduce cost, special handling, and production risk.',
        discipline: 'DFM',
      ),
      'Define and validate manufacturing processes': SubStepDefaultInfo(
        description:
            'List the key processes required to build the product, including machining, molding, casting, welding, coating, assembly, testing, and packaging. Define work steps, parameters, controls, and trial builds that prove processes can meet specifications consistently.',
        discipline: 'Process Engineering',
      ),
      'Develop and qualify tooling, fixtures, and equipment': SubStepDefaultInfo(
        description:
            'Identify tools, fixtures, jigs, molds, dies, test rigs, and automation required for production. Confirm designs, lead times, ownership, debugging, and production-relevant qualification against cycle-time and quality targets.',
        discipline: 'Tooling',
      ),
      'Build and stabilize the supply chain': SubStepDefaultInfo(
        description:
            'Select and qualify suppliers for materials and components, checking capacity, quality systems, and delivery reliability. Establish contracts, dual sourcing where needed, logistics, packaging, and inventory plans for ramp-up and steady-state demand.',
        discipline: 'Supply Chain',
      ),
      'Validate process capability and quality control': SubStepDefaultInfo(
        description:
            'Use pilot or low-rate build data to calculate process capability, defect rates, and control of critical dimensions or characteristics. Define in-process checks, final inspections, sampling plans, and control charts for production quality.',
        discipline: 'Quality',
      ),
      'Confirm cost, throughput, and scalability': SubStepDefaultInfo(
        description:
            'Refine the cost model with real process times, scrap rates, labor assumptions, tooling cost, and supplier quotes. Demonstrate that lines, shifts, equipment, and staffing can hit required volume and scale if demand increases.',
        discipline: 'Operations',
      ),
      'Prepare workforce, documentation, and training': SubStepDefaultInfo(
        description:
            'Create work instructions, standard operating procedures, checklists, machine maintenance plans, and quality instructions. Train production, quality, and maintenance teams, then verify they can follow the process reliably during trial builds.',
        discipline: 'Operations Training',
      ),
      'Run pilot builds and manufacturing readiness assessments': SubStepDefaultInfo(
        description:
            'Conduct pilot or pre-series builds using the intended line, equipment, materials, and workforce to mimic real production. Perform a structured readiness assessment to identify remaining manufacturing risks, gaps, and actions.',
        discipline: 'Manufacturing Engineering',
      ),
      'Manage risks and continuous improvement before launch': SubStepDefaultInfo(
        description:
            'Maintain a manufacturing risk register covering technology, suppliers, processes, workforce, facilities, and deadlines. Apply lean, Six Sigma, Kaizen, or similar improvement methods to reduce cycle time, scrap, and variability before launch approval.',
        discipline: 'Risk Management',
      ),
      'Formal manufacturing readiness review and sign-off': SubStepDefaultInfo(
        description:
            'Hold a Manufacturing Readiness Review with engineering, production, quality, supply chain, and management. Document the readiness decision, remaining watch items, and authorization to transition to low-rate or full-rate production.',
        discipline: 'Review Board',
      ),
    },
  ),
  'Final Release': StageDefaultContent(
    description:
        'Approve the product for market or full production with configuration frozen, evidence complete, launch teams ready, and release controls in place.',
    subSteps: {
      'Confirm readiness across all domains': SubStepDefaultInfo(
        description:
            'Verify that engineering, testing, manufacturing, quality, service, and commercial teams declare readiness based on prior gates. Check release criteria such as critical tests passed, open issues below threshold, readiness targets met, and formal waivers approved.',
        discipline: 'Release Management',
      ),
      'Freeze product definition and configuration': SubStepDefaultInfo(
        description:
            'Lock the final BOM, CAD, drawings, software or firmware versions, materials, options, and configuration identifiers. Define part numbers, revisions, version tags, and change-control rules for any future updates.',
        discipline: 'Configuration Management',
      ),
      'Verify documentation completeness': SubStepDefaultInfo(
        description:
            'Confirm technical documentation is complete and consistent, including specifications, drawings, work instructions, test procedures, certifications, risk analyses, and user manuals. Check external documents such as installation guides, service manuals, labels, safety information, and regulatory markings.',
        discipline: 'Documentation',
      ),
      'Review test and validation evidence': SubStepDefaultInfo(
        description:
            'Summarize verification and validation evidence from lab tests, field trials, reliability testing, compliance reports, and certification records. Confirm critical issues are closed or have approved workarounds with residual risks documented.',
        discipline: 'Verification',
      ),
      'Confirm manufacturing and supply readiness': SubStepDefaultInfo(
        description:
            'Verify manufacturing lines, tooling, QA processes, trained staff, suppliers, logistics, and spare parts are ready for the released configuration. Confirm planned volume, quality levels, ramp-up support, and contingency plans for key components.',
        discipline: 'Manufacturing',
      ),
      'Align commercial launch and support': SubStepDefaultInfo(
        description:
            'Coordinate product management, marketing, and sales on launch timing, pricing, packaging, and claims that match final product capability. Confirm helpdesk, field service, spare parts lists, warranty terms, and support structures are ready for customers.',
        discipline: 'Commercial Readiness',
      ),
      'Run a formal Final Release Review': SubStepDefaultInfo(
        description:
            'Hold a go/no-go review with decision makers from all functions and present readiness, residual risks, and launch plan. Decide Go, Go with conditions such as limited volume or geography, or No-go with corrective actions and a new target date.',
        discipline: 'Decision Board',
      ),
      'Execute release and deployment': SubStepDefaultInfo(
        description:
            'After a Go decision, open manufacturing orders, enable ordering in ERP or PLM systems, update catalog data, and trigger logistics and distribution. For products with software, deploy approved images and ensure production and test systems use the released versions.',
        discipline: 'Release Management',
      ),
      'Monitor early production and field performance': SubStepDefaultInfo(
        description:
            'Track yield, defect rates, returns, customer complaints, and critical incidents during the early release period. Maintain a fast feedback loop so issues can be corrected through controlled fixes, minor design updates, or process adjustments.',
        discipline: 'Quality',
      ),
      'Archive and baseline for future changes': SubStepDefaultInfo(
        description:
            'Archive design data, documentation, test evidence, approval records, and the official released baseline. Define how minor updates, new revisions, and next-generation work will feed into change control and Continuous Improvement.',
        discipline: 'Configuration Management',
      ),
    },
  ),
  'Continuous Improvement': StageDefaultContent(
    description:
        'Use field, customer, production, and team feedback to improve the product and the development system after release.',
    subSteps: {
      'Define improvement goals and metrics': SubStepDefaultInfo(
        description:
            'Set clear improvement objectives such as reducing field failures, improving usability, cutting production cost, or shortening lead time. Establish measurable KPIs and baselines such as complaint rate, NPS, defect ppm, OEE, cycle time, or warranty cost.',
        discipline: 'Continuous Improvement',
      ),
      'Collect feedback and performance data': SubStepDefaultInfo(
        description:
            'Create regular feedback loops from customers, service, production, and sales through tickets, surveys, interviews, analytics, and warranty returns. Combine qualitative feedback with quantitative data so the product's real behavior is visible.',
        discipline: 'Customer Insights',
      ),
      'Analyze problems and opportunities': SubStepDefaultInfo(
        description:
            'Use collected data to find recurring issues, bottlenecks, waste, and underused or misunderstood features. Apply root-cause tools such as 5 Whys, fishbone diagrams, or Pareto analysis before jumping to solutions.',
        discipline: 'Problem Solving',
      ),
      'Plan improvements (Plan phase of PDCA)': SubStepDefaultInfo(
        description:
            'Select a small number of high-impact improvement themes and define the specific changes to try. For each change, document the hypothesis, expected metric effect, scope, and how results will be measured.',
        discipline: 'Continuous Improvement',
      ),
      'Implement small changes (Do)': SubStepDefaultInfo(
        description:
            'Apply improvements on a controlled scale first, such as one line, one team, one product variant, or one customer segment. Make sure operators, engineers, and support staff understand what is changing and how to execute it.',
        discipline: 'Operations',
      ),
      'Check results and learn (Check)': SubStepDefaultInfo(
        description:
            'After the trial period, compare new data against baseline KPIs to confirm whether the change delivered the expected benefit. Capture learnings even when an experiment fails, because negative results still improve future decisions.',
        discipline: 'Analysis',
      ),
      'Standardize successful practices (Act)': SubStepDefaultInfo(
        description:
            'When an improvement works, update design rules, work instructions, test procedures, coding guidelines, or checklists. Roll the new standard across the relevant products, teams, or sites and retire the old method to avoid regression.',
        discipline: 'Process Governance',
      ),
      'Run regular retrospectives and Kaizen activities': SubStepDefaultInfo(
        description:
            'Hold periodic retrospectives or Kaizen workshops where cross-functional teams review recent work and propose concrete improvements. Encourage contributions from operators, engineers, service teams, and stakeholders so improvement becomes normal work.',
        discipline: 'Team Facilitation',
      ),
      'Maintain an improvement backlog and governance': SubStepDefaultInfo(
        description:
            'Keep a prioritized backlog of improvement ideas with owners, expected impact, effort, status, and decisions. Use lightweight governance such as a CI board or steering meeting to resource and track valuable improvements through completion.',
        discipline: 'Program Management',
      ),
      'Feed improvements into next product iterations': SubStepDefaultInfo(
        description:
            'Use validated learnings to shape future requirements, architectures, design guidelines, tests, manufacturing processes, and support practices. Treat each product generation as the next loop of the improvement cycle.',
        discipline: 'Product Strategy',
      ),
    },
  ),
};

final Map<String, List<String>> defaultStageChecklist = Map.unmodifiable(
  defaultStageContent.map(
    (stageName, content) => MapEntry(
      stageName,
      content.subSteps.keys.toList(growable: false),
    ),
  ),
);

String getDefaultStageDescription(String stageName) {
  return defaultStageContent[stageName]?.description ??
      'Engineering review and validation for this development phase.';
}

SubStepDefaultInfo getDefaultSubStepInfo({
  required String stageName,
  required String subStepName,
}) {
  return defaultStageContent[stageName]?.subSteps[subStepName] ??
      defaultSubStepFallback;
}

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

/// Upgrades reviews created from older default lifecycle definitions.
///
/// Existing stage progress and matching substep workspaces are retained where
/// the canonical PDF-backed checklist still contains the same substep name.
/// Custom lifecycle definitions are left untouched.
List<Stage> upgradeLegacyDefaultStages(List<Stage> stages) {
  if (stages.length != defaultStageChecklist.length) return stages;

  final canonicalNames = defaultStageChecklist.keys.toList(growable: false);
  final isCanonicalLifecycle = stages.asMap().entries.every(
        (entry) => entry.value.name == canonicalNames[entry.key],
      );
  final isIncompleteLegacyLifecycle =
      stages.take(4).map((stage) => stage.name).toList().join('|') ==
          canonicalNames.take(4).join('|') &&
      stages.skip(4).every((stage) => stage.subSteps.isEmpty);

  if (!isCanonicalLifecycle && !isIncompleteLegacyLifecycle) return stages;

  var changed = false;
  final upgradedStages = stages.asMap().entries.map((entry) {
    final existingStage = entry.value;
    final canonicalName = canonicalNames[entry.key];
    final existingItems = {
      for (final item in existingStage.subSteps) item.name: item,
    };
    final upgradedItems = defaultStageChecklist[canonicalName]!
        .map((name) => existingItems[name] ?? _newSubStep(name))
        .toList();
    final progress = _calculateProgress(upgradedItems);
    final status = _statusForProgress(progress, upgradedItems);

    final subStepsChanged =
        existingStage.subSteps.length != upgradedItems.length ||
            existingStage.subSteps.asMap().entries.any((subStepEntry) {
              final index = subStepEntry.key;
              return index >= upgradedItems.length ||
                  subStepEntry.value.name != upgradedItems[index].name;
            });
    final stageChanged = existingStage.name != canonicalName ||
        subStepsChanged ||
        existingStage.progress != progress ||
        existingStage.status != status;
    changed = changed || stageChanged;

    return stageChanged
        ? existingStage.copyWith(
            name: canonicalName,
            subSteps: upgradedItems,
            progress: progress,
            status: status,
          )
        : existingStage;
  }).toList();

  return changed ? upgradedStages : stages;
}

SubStep _newSubStep(String name) {
  return SubStep(id: _uuid.v4(), name: name, workspaceId: _uuid.v4());
}

double _calculateProgress(List<SubStep> subSteps) {
  if (subSteps.isEmpty) return 0;
  final completed = subSteps
      .where((subStep) => subStep.status == StageStatus.completed)
      .length;
  return completed / subSteps.length;
}

StageStatus _statusForProgress(double progress, List<SubStep> subSteps) {
  if (subSteps.isEmpty || progress == 0) return StageStatus.notStarted;
  return progress == 1 ? StageStatus.completed : StageStatus.inProgress;
}
