-- 007_fk_tweaks.sql

BEGIN;

-- ============================================================
-- Ensure Workspaces are safely managed when Sub Steps are deleted
-- Since SubStep holds the workspace_id (FK), we cannot use ON DELETE CASCADE
-- to delete the parent workspace. We must use a trigger to clean up 
-- orphaned workspaces if a sub_step is deleted.
-- ============================================================

CREATE OR REPLACE FUNCTION public.cleanup_orphaned_workspace()
RETURNS trigger AS $$
BEGIN
  -- Check if the workspace is referenced by any other sub_steps.
  -- If not, delete the workspace to prevent orphan data.
  IF NOT EXISTS (SELECT 1 FROM public.sub_steps WHERE workspace_id = OLD.workspace_id AND id != OLD.id) THEN
    DELETE FROM public.workspaces WHERE id = OLD.workspace_id;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_sub_step_deleted
  AFTER DELETE ON public.sub_steps
  FOR EACH ROW
  EXECUTE PROCEDURE public.cleanup_orphaned_workspace();

COMMIT;
