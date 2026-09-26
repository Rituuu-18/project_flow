-- Backfill the three new Preliminary Design items in existing canonical reviews.
-- Run before deploying the client that uses the 15-item checklist.
BEGIN;

WITH requested_items(name, description, discipline) AS (
  VALUES
    (
      'Perform engineering calculations from allocated requirements',
      'Calculate loads, stresses, deflection, torque, power, thermal behavior, fatigue life, safety factors, flow, pressure, and other relevant engineering parameters for the selected concept. Trace all calculations back to the applicable project and subsystem requirements.',
      'Design Engineering'
    ),
    (
      'Define systems, subsystems, and interfaces',
      'Decompose the product into systems and subsystems; allocate functions and requirements; define key physical, electrical, fluid, software, and user interfaces; and establish preliminary performance targets. This aligns directly with the purpose of the PDR and the allocated baseline.',
      'Systems Engineering'
    ),
    (
      'Select and justify candidate standard components',
      'Select preliminary standard components—such as bearings, bolts, fasteners, seals, springs, motors, sensors, gears, couplings, valves, and similar items—using engineering calculations, interface requirements, applicable standards, environmental conditions, supply risk, cost, and manufacturability as selection criteria. Record the alternatives considered and provide the rationale for the final selection.',
      'Design Engineering'
    )
),
missing AS MATERIALIZED (
  SELECT
    d.id AS review_id,
    d.created_by,
    item.name,
    item.description,
    item.discipline,
    gen_random_uuid() AS sub_step_id,
    gen_random_uuid() AS workspace_id
  FROM public.design_reviews AS d
  CROSS JOIN requested_items AS item
  WHERE EXISTS (
    SELECT 1 FROM public.sub_steps AS existing
    WHERE existing.design_review_id = d.id
      AND existing.name = 'Define PDR objectives and criteria'
  )
    AND NOT EXISTS (
      SELECT 1 FROM public.sub_steps AS existing
      WHERE existing.design_review_id = d.id
        AND existing.name = item.name
    )
),
created_workspaces AS (
  INSERT INTO public.workspaces (
    id, created_by, checklist_item, item_description, discipline
  )
  SELECT workspace_id, created_by, name, description, discipline
  FROM missing
  RETURNING id
)
INSERT INTO public.sub_steps (id, design_review_id, name, workspace_id)
SELECT missing.sub_step_id, missing.review_id, missing.name, missing.workspace_id
FROM missing
JOIN created_workspaces ON created_workspaces.id = missing.workspace_id;

-- Snapshot of the canonical scoreable names and revised percentage weights.
-- This matches drlSubStepWeights; non-scoreable names contribute zero.
WITH weights(name, points) AS (
  VALUES
    ('Define the problem and scope', 1.57),
    ('Identify stakeholders and interfaces', 1.57),
    ('Capture user and business needs', 1.57),
    ('Derive functional requirements', 1.57),
    ('Define performance and quality targets', 1.57),
    ('Establish constraints and boundaries', 1.57),
    ('Non-functional requirements', 1.57),
    ('Validation and testability definition', 1.57),
    ('Review, negotiate, and freeze baseline', 1.54),
    ('Clarify goals and success criteria', 1.25),
    ('Evaluate desirability, feasibility, viability', 1.25),
    ('Analyze risks and constraints', 1.25),
    ('Capture structured feedback', 1.25),
    ('Compare and prioritize concepts', 1.25),
    ('Decide and define next steps', 1.27),
    ('Define PDR objectives and criteria', 1.71),
    ('Perform engineering calculations from allocated requirements', 1.71),
    ('Define systems, subsystems, and interfaces', 1.71),
    ('Select and justify candidate standard components', 1.71),
    ('Verify requirements allocation and traceability', 1.71),
    ('Evaluate key technical aspects and analyses', 1.71),
    ('Check interfaces and compatibility', 1.71),
    ('Assess producibility, materials, and make-or-buy', 1.71),
    ('Analyze project risks, schedule, and resources', 1.71),
    ('Decide outcome and actions', 1.74),
    ('Check requirements compliance', 2.42),
    ('Assess analyses and simulations', 2.42),
    ('Evaluate manufacturability and assembly (DFMA)', 2.42),
    ('Check interfaces and integration', 2.42),
    ('Validate safety, reliability, and compliance aspects', 2.42),
    ('Examine project impacts: cost, schedule, and risk', 2.42),
    ('Decide outcome and approve for next phase', 2.43),
    ('Define objectives and success criteria', 0.94),
    ('Plan the simulation strategy', 0.94),
    ('Build or validate models', 0.94),
    ('Set up loads, boundary conditions, and steps', 0.94),
    ('Run simulations and ensure numerical quality', 0.94),
    ('Post-process and interpret results', 0.94),
    ('Correlate with physical data (when available)', 0.94),
    ('Decide design actions and maturity', 0.94),
    ('Define purpose and acceptance criteria', 1.05),
    ('Plan prototype build and configuration', 1.05),
    ('Inspect build quality and design conformity', 1.05),
    ('Evaluate assembly and manufacturability', 1.05),
    ('Perform basic functional tests', 1.05),
    ('Gather user and stakeholder feedback', 1.05),
    ('Compare results to requirements and simulations', 1.05),
    ('Identify issues, root causes, and design changes', 1.05),
    ('Decide on next steps and build iterations', 1.05),
    ('Test objectives and success criteria confirmed', 2.26),
    ('Verification and validation test plan approved', 2.26),
    ('Test procedures, setups, and instrumentation ready', 2.26),
    ('Test samples, configuration, and revision documented', 2.26),
    ('Results analyzed against requirements and limits', 2.26),
    ('Define manufacturing readiness objectives', 1.05),
    ('Assess design for manufacturability', 1.05),
    ('Define and validate manufacturing processes', 1.05),
    ('Develop and qualify tooling, fixtures, and equipment', 1.05),
    ('Build and stabilize the supply chain', 1.05),
    ('Validate process capability and quality control', 1.05),
    ('Confirm cost, throughput, and scalability', 1.04),
    ('Run pilot builds and manufacturing readiness assessments', 1.04),
    ('Manage risks and continuous improvement before launch', 1.05),
    ('Freeze product definition and configuration', 1.32),
    ('Confirm manufacturing and supply readiness', 1.32),
    ('Align commercial launch and support', 1.32),
    ('Execute release and deployment', 1.32),
    ('Monitor early production and field performance', 1.32)
),
completed_names AS (
  SELECT DISTINCT design_review_id, name
  FROM public.sub_steps
  WHERE status = 'completed'::public.stage_status
),
scores AS (
  SELECT
    d.id AS review_id,
    COALESCE(SUM(weights.points), 0)::numeric AS score
  FROM public.design_reviews AS d
  LEFT JOIN completed_names AS items ON items.design_review_id = d.id
  LEFT JOIN weights ON weights.name = items.name
  WHERE EXISTS (
    SELECT 1 FROM public.sub_steps AS existing
    WHERE existing.design_review_id = d.id
      AND existing.name = 'Define PDR objectives and criteria'
  )
  GROUP BY d.id
)
UPDATE public.design_reviews AS d
SET
  progress = LEAST(scores.score, 100) / 100,
  status = CASE
    WHEN scores.score >= 100 THEN 'completed'::public.project_status
    WHEN d.status = 'completed'::public.project_status
      THEN 'active'::public.project_status
    ELSE d.status
  END
FROM scores
WHERE d.id = scores.review_id
  AND (
    d.progress IS DISTINCT FROM LEAST(scores.score, 100) / 100
    OR d.status = 'completed'::public.project_status AND scores.score < 100
    OR d.status <> 'completed'::public.project_status AND scores.score >= 100
  );

COMMIT;
