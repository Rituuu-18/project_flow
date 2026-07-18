-- 006_storage.sql

BEGIN;

-- ============================================================
-- Create Storage Buckets
-- ============================================================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('attachments', 'attachments', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('images', 'images', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- Storage Helper Function
-- ============================================================
CREATE OR REPLACE FUNCTION public.can_access_storage_path(bucket_id text, object_name text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  path_parts text[];
  entity_type text;
  entity_id uuid;
BEGIN
  -- Split the path string by /
  path_parts := string_to_array(object_name, '/');
  
  -- Require at least entity_type/entity_id/filename
  IF array_length(path_parts, 1) < 2 THEN
    RETURN false;
  END IF;

  entity_type := path_parts[1];
  
  -- Try casting to UUID safely
  BEGIN
    entity_id := path_parts[2]::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RETURN false;
  END;

  -- Check access based on entity type
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
  END IF;

  RETURN false;
END;
$$;

-- ============================================================
-- Storage RLS Policies
-- ============================================================

-- Drop old policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Authenticated users can upload attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view attachments" ON storage.objects;
DROP POLICY IF EXISTS "Users can manage their own attachments" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own attachments" ON storage.objects;

DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view images" ON storage.objects;
DROP POLICY IF EXISTS "Users can manage their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own images" ON storage.objects;

DROP POLICY IF EXISTS "Authenticated users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can manage their own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own documents" ON storage.objects;


-- Attachments bucket
CREATE POLICY "Users can upload authorized attachments"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'attachments' AND public.can_access_storage_path(bucket_id, name));

CREATE POLICY "Users can view authorized attachments"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'attachments' AND public.can_access_storage_path(bucket_id, name));

CREATE POLICY "Users can update authorized attachments"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'attachments' AND public.can_access_storage_path(bucket_id, name));

CREATE POLICY "Users can delete authorized attachments"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'attachments' AND public.can_access_storage_path(bucket_id, name));

-- Images bucket
CREATE POLICY "Users can upload authorized images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'images' AND public.can_access_storage_path(bucket_id, name));

CREATE POLICY "Users can view authorized images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'images' AND public.can_access_storage_path(bucket_id, name));

CREATE POLICY "Users can update authorized images"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'images' AND public.can_access_storage_path(bucket_id, name));

CREATE POLICY "Users can delete authorized images"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'images' AND public.can_access_storage_path(bucket_id, name));

-- Documents bucket
CREATE POLICY "Users can upload authorized documents"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'documents' AND public.can_access_storage_path(bucket_id, name));

CREATE POLICY "Users can view authorized documents"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'documents' AND public.can_access_storage_path(bucket_id, name));

CREATE POLICY "Users can update authorized documents"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'documents' AND public.can_access_storage_path(bucket_id, name));

CREATE POLICY "Users can delete authorized documents"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'documents' AND public.can_access_storage_path(bucket_id, name));

COMMIT;
