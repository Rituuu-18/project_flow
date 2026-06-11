import 'package:uuid/uuid.dart';
import '../entities/stage.dart';
import '../entities/sub_step.dart';

List<Stage> getDefaultStages() {
  const uuid = Uuid();
  final now = DateTime.now();

  return [
    Stage(
      id: uuid.v4(),
      name: 'Requirements',
      lastUpdated: now,
      subSteps: [
        SubStep(id: uuid.v4(), name: 'Define the problem and scope', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Identify stakeholders and interfaces', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Capture user and business needs', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Derive functional requirements', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Define performance and quality targets', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Establish constraints and boundaries', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Non-functional requirements', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Validation and testability definition', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Requirements document and structure', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Review, negotiate, and freeze baseline', workspaceId: uuid.v4()),
      ],
    ),
    Stage(
      id: uuid.v4(),
      name: 'Concept Review',
      lastUpdated: now,
      subSteps: [
        SubStep(id: uuid.v4(), name: 'Clarify review goals and scope', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Capture user and stakeholder needs', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Document solution concept options', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Compare concepts against key requirements', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Assess feasibility (technical & schedule)', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Identify and list major risks', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Estimate cost / benefit for each concept', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'State key assumptions and constraints', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Capture early stakeholder feedback', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Select preferred concept and rationale', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Assign follow-up actions and owners', workspaceId: uuid.v4()),
      ],
    ),
    Stage(
      id: uuid.v4(),
      name: 'Preliminary Design Review',
      lastUpdated: now,
      subSteps: [
        SubStep(id: uuid.v4(), name: 'Entry criteria met for PDR', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Preliminary system architecture complete', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Requirements allocated to subsystems', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Interfaces identified and documented', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Key calculations / simulations available', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Technical risks reviewed and updated', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Verification strategy drafted', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Manufacturability and serviceability considered', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Schedule and resources reviewed', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'PDR actions defined and recorded', workspaceId: uuid.v4()),
      ],
    ),
    Stage(
      id: uuid.v4(),
      name: 'Detailed Design Review',
      lastUpdated: now,
      subSteps: [
        SubStep(id: uuid.v4(), name: 'CAD models complete for all assemblies', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Detailed drawings and specifications', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'BOM (Bill of Materials) finalized', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Material selection and analysis', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Tolerance stack-up analysis', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'FEA / CFD thermal/structural results', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'PCB layout and circuit design complete', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Firmware / Software architecture ready', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'Compliance / Regulatory review', workspaceId: uuid.v4()),
        SubStep(id: uuid.v4(), name: 'DFM/DFA (Design for Mfg/Assembly)', workspaceId: uuid.v4()),
      ],
    ),
    Stage(id: uuid.v4(), name: 'Critical Design Review', lastUpdated: now, subSteps: []),
    Stage(id: uuid.v4(), name: 'Integration & Test Review', lastUpdated: now, subSteps: []),
    Stage(id: uuid.v4(), name: 'Verification & Validation', lastUpdated: now, subSteps: []),
    Stage(id: uuid.v4(), name: 'Pre-Production Review', lastUpdated: now, subSteps: []),
    Stage(id: uuid.v4(), name: 'Production Readiness Review', lastUpdated: now, subSteps: []),
    Stage(id: uuid.v4(), name: 'Final Release', lastUpdated: now, subSteps: []),
  ];
}
