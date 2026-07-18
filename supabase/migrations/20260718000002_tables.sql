-- 002_tables.sql

BEGIN;

-- ============================================================
-- Profiles Table
-- ============================================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  role public.user_role DEFAULT 'member'::public.user_role,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Projects Table
-- ============================================================
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  owner TEXT NOT NULL,
  discipline TEXT NOT NULL,
  image_url TEXT,
  progress NUMERIC NOT NULL DEFAULT 0.0 CHECK (progress >= 0 AND progress <= 100),
  status public.project_status NOT NULL DEFAULT 'active'::public.project_status,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- ============================================================
-- Design Reviews Table
-- ============================================================
CREATE TABLE public.design_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  owner TEXT NOT NULL,
  discipline TEXT NOT NULL,
  image_url TEXT,
  progress NUMERIC NOT NULL DEFAULT 0.0 CHECK (progress >= 0 AND progress <= 100),
  status public.project_status NOT NULL DEFAULT 'active'::public.project_status,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);


-- ============================================================
-- Workspaces Table
-- Contains TEXT[] arrays for simple list fields to satisfy
-- minimum 3NF and avoid unnecessary 1-column tables
-- ============================================================
CREATE TABLE public.workspaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  problem_statement TEXT,
  scope_in TEXT[] DEFAULT '{}',
  scope_out TEXT[] DEFAULT '{}',
  notes TEXT,
  attachments TEXT[] DEFAULT '{}',
  images TEXT[] DEFAULT '{}',
  documents TEXT[] DEFAULT '{}',
  approval_status public.approval_status NOT NULL DEFAULT 'pending'::public.approval_status,
  checklist_item TEXT,
  item_description TEXT,
  engineering_comments TEXT,
  action_description TEXT,
  priority TEXT,
  assignee TEXT,
  discipline TEXT,
  due_date TIMESTAMPTZ,
  activity_logs TEXT[] DEFAULT '{}',
  stakeholders TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- ============================================================
-- Sub Steps Table
-- ============================================================
CREATE TABLE public.sub_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  design_review_id UUID NOT NULL REFERENCES public.design_reviews(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  status public.stage_status NOT NULL DEFAULT 'notStarted'::public.stage_status,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Stakeholders Table (for Design Reviews)
-- ============================================================
CREATE TABLE public.stakeholders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  design_review_id UUID NOT NULL REFERENCES public.design_reviews(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Workspace Comments Table
-- ============================================================
CREATE TABLE public.workspace_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  author TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMIT;
