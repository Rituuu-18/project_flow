-- Allow design-review cover images in the private->public images bucket.
-- Path convention: design_review/{review_id}/{filename}

BEGIN;

-- Extend path ACL for design reviews
CREATE OR REPLACE FUNCTION public.can_access_storage_path(bucket_id text, object_name text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, storage
AS $$
DECLARE
  path_parts text[];
  entity_type text;
  entity_id uuid;
BEGIN
  path_parts := string_to_array(object_name, '/');

  IF array_length(path_parts, 1) < 2 THEN
    RETURN false;
  END IF;

  entity_type := path_parts[1];

  BEGIN
    entity_id := path_parts[2]::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RETURN false;
  END;

  IF entity_type = 'workspace' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.workspaces w
      WHERE w.id = entity_id AND w.created_by = auth.uid()
    );
  ELSIF entity_type = 'project' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.projects p
      WHERE p.id = entity_id AND p.created_by = auth.uid()
    );
  ELSIF entity_type = 'design_review' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.design_reviews d
      WHERE d.id = entity_id AND d.created_by = auth.uid()
    );
  END IF;

  RETURN false;
END;
$$;

-- Cover images are safe to read via public URL (upload still ACL-protected).
UPDATE storage.buckets
SET public = true
WHERE id = 'images';

DROP POLICY IF EXISTS "Public can view images" ON storage.objects;
CREATE POLICY "Public can view images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'images');

COMMIT;
