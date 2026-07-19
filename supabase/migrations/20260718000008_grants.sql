-- 007_grants.sql

BEGIN;

-- Grant permissions to authenticated, anon, and service_role 
-- so the Supabase API can access the tables (RLS will restrict rows)
GRANT ALL ON TABLE public.profiles TO authenticated, anon, service_role;
GRANT ALL ON TABLE public.projects TO authenticated, anon, service_role;
GRANT ALL ON TABLE public.design_reviews TO authenticated, anon, service_role;
GRANT ALL ON TABLE public.sub_steps TO authenticated, anon, service_role;
GRANT ALL ON TABLE public.stakeholders TO authenticated, anon, service_role;
GRANT ALL ON TABLE public.workspaces TO authenticated, anon, service_role;
GRANT ALL ON TABLE public.workspace_comments TO authenticated, anon, service_role;

-- Grant usage on schemas and sequences if necessary
-- For standard setup, public schema usage is usually granted, but just in case:
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

COMMIT;
