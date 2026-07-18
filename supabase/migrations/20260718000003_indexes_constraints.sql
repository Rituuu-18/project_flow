-- 003_indexes_constraints.sql

BEGIN;

-- ============================================================
-- Indexes for Foreign Keys and Common Lookups
-- ============================================================
CREATE INDEX idx_projects_created_by ON public.projects(created_by);
CREATE INDEX idx_design_reviews_created_by ON public.design_reviews(created_by);

CREATE INDEX idx_design_reviews_project_id ON public.design_reviews(project_id);

CREATE INDEX idx_sub_steps_design_review_id ON public.sub_steps(design_review_id);
CREATE INDEX idx_sub_steps_workspace_id ON public.sub_steps(workspace_id);

CREATE INDEX idx_stakeholders_design_review_id ON public.stakeholders(design_review_id);

CREATE INDEX idx_workspaces_created_by ON public.workspaces(created_by);
CREATE INDEX idx_workspace_comments_workspace_id ON public.workspace_comments(workspace_id);



COMMIT;
