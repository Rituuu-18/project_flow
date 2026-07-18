-- 005_rls.sql

BEGIN;

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sub_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stakeholders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_comments ENABLE ROW LEVEL SECURITY;

-- Force RLS even for table owners (good practice)
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.projects FORCE ROW LEVEL SECURITY;
ALTER TABLE public.design_reviews FORCE ROW LEVEL SECURITY;
ALTER TABLE public.sub_steps FORCE ROW LEVEL SECURITY;
ALTER TABLE public.stakeholders FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workspaces FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_comments FORCE ROW LEVEL SECURITY;

-- ============================================================
-- Policies: Profiles
-- ============================================================
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- ============================================================
-- Policies: Projects
-- ============================================================
CREATE POLICY "Users can view their own projects"
  ON public.projects FOR SELECT USING (auth.uid() = created_by);

CREATE POLICY "Users can insert their own projects"
  ON public.projects FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own projects"
  ON public.projects FOR UPDATE USING (auth.uid() = created_by) WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete their own projects"
  ON public.projects FOR DELETE USING (auth.uid() = created_by);

-- ============================================================
-- Policies: Design Reviews
-- ============================================================
CREATE POLICY "Users can view their own design reviews"
  ON public.design_reviews FOR SELECT USING (auth.uid() = created_by);

CREATE POLICY "Users can insert their own design reviews"
  ON public.design_reviews FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own design reviews"
  ON public.design_reviews FOR UPDATE USING (auth.uid() = created_by) WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete their own design reviews"
  ON public.design_reviews FOR DELETE USING (auth.uid() = created_by);

-- ============================================================
-- Policies: Sub Steps
-- ============================================================
CREATE POLICY "Users can view sub steps of their design reviews"
  ON public.sub_steps FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.design_reviews d
      WHERE d.id = design_review_id 
        AND d.created_by = public.auth_user_id()
    )
  );

CREATE POLICY "Users can insert sub steps for their design reviews"
  ON public.sub_steps FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.design_reviews d
      WHERE d.id = design_review_id 
        AND d.created_by = public.auth_user_id()
    )
  );

CREATE POLICY "Users can update sub steps of their design reviews"
  ON public.sub_steps FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.design_reviews d
      WHERE d.id = design_review_id 
        AND d.created_by = public.auth_user_id()
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.design_reviews d
      WHERE d.id = design_review_id 
        AND d.created_by = public.auth_user_id()
    )
  );

CREATE POLICY "Users can delete sub steps of their design reviews"
  ON public.sub_steps FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.design_reviews d
      WHERE d.id = design_review_id 
        AND d.created_by = public.auth_user_id()
    )
  );

-- ============================================================
-- Policies: Stakeholders
-- ============================================================
CREATE POLICY "Users can view stakeholders of their reviews"
  ON public.stakeholders FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.design_reviews d 
      WHERE d.id = design_review_id AND d.created_by = public.auth_user_id()
    )
  );

CREATE POLICY "Users can insert stakeholders for their reviews"
  ON public.stakeholders FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.design_reviews d 
      WHERE d.id = design_review_id AND d.created_by = public.auth_user_id()
    )
  );

CREATE POLICY "Users can update stakeholders of their reviews"
  ON public.stakeholders FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.design_reviews d 
      WHERE d.id = design_review_id AND d.created_by = public.auth_user_id()
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.design_reviews d 
      WHERE d.id = design_review_id AND d.created_by = public.auth_user_id()
    )
  );

CREATE POLICY "Users can delete stakeholders of their reviews"
  ON public.stakeholders FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.design_reviews d 
      WHERE d.id = design_review_id AND d.created_by = public.auth_user_id()
    )
  );

-- ============================================================
-- Policies: Workspaces
-- ============================================================
CREATE POLICY "Users can view their own workspaces"
  ON public.workspaces FOR SELECT USING (auth.uid() = created_by);

CREATE POLICY "Users can insert their own workspaces"
  ON public.workspaces FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own workspaces"
  ON public.workspaces FOR UPDATE USING (auth.uid() = created_by) WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete their own workspaces"
  ON public.workspaces FOR DELETE USING (auth.uid() = created_by);

-- ============================================================
-- Policies: Workspace Comments
-- ============================================================
CREATE POLICY "Users can view comments in their workspaces"
  ON public.workspace_comments FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.workspaces w 
      WHERE w.id = workspace_id AND w.created_by = public.auth_user_id()
    )
  );

CREATE POLICY "Users can insert comments in their workspaces"
  ON public.workspace_comments FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workspaces w 
      WHERE w.id = workspace_id AND w.created_by = public.auth_user_id()
    )
  );

CREATE POLICY "Users can update comments in their workspaces"
  ON public.workspace_comments FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.workspaces w 
      WHERE w.id = workspace_id AND w.created_by = public.auth_user_id()
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workspaces w 
      WHERE w.id = workspace_id AND w.created_by = public.auth_user_id()
    )
  );

CREATE POLICY "Users can delete comments in their workspaces"
  ON public.workspace_comments FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.workspaces w 
      WHERE w.id = workspace_id AND w.created_by = public.auth_user_id()
    )
  );

COMMIT;
