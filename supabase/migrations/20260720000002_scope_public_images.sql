-- Narrow public read on the images bucket to design-review cover paths only.
-- Upload/update/delete remain ACL-protected via can_access_storage_path.

BEGIN;

DROP POLICY IF EXISTS "Public can view images" ON storage.objects;

CREATE POLICY "Public can view design review images"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'images'
    AND name LIKE 'design_review/%'
  );

COMMIT;
