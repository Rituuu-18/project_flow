-- Fix handle_new_user to read snake_case metadata keys written by the Flutter app
-- (first_name / last_name), with camelCase fallback for older clients.

BEGIN;

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

COMMIT;
