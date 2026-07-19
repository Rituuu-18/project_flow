-- 004_triggers_functions.sql

BEGIN;

-- ============================================================
-- Extension for automatic updated_at timestamp
-- ============================================================
CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;

-- Apply to relevant tables
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (last_updated);

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.design_reviews
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (last_updated);


CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.workspaces
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

-- ============================================================
-- Auto-create profile on Auth Signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name)
  VALUES (
    new.id,
    COALESCE(
      new.raw_user_meta_data->>'first_name',
      new.raw_user_meta_data->>'firstName'
    ),
    COALESCE(
      new.raw_user_meta_data->>'last_name',
      new.raw_user_meta_data->>'lastName'
    )
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ============================================================
-- RLS Helper Functions (Optimized, Stable)
-- ============================================================
CREATE OR REPLACE FUNCTION public.auth_user_id()
RETURNS UUID
LANGUAGE sql STABLE SECURITY INVOKER
AS $$
  SELECT auth.uid();
$$;

COMMIT;
