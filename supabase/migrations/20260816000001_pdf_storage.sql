-- 20260816000001_pdf_storage.sql

BEGIN;

CREATE TABLE public.pdf_storage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE public.pdf_storage ENABLE ROW LEVEL SECURITY;

-- Create Policies
CREATE POLICY "Users can view their own PDFs"
  ON public.pdf_storage
  FOR SELECT
  USING (auth.uid() = created_by);

CREATE POLICY "Users can insert their own PDFs"
  ON public.pdf_storage
  FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own PDFs"
  ON public.pdf_storage
  FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete their own PDFs"
  ON public.pdf_storage
  FOR DELETE
  USING (auth.uid() = created_by);

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pdf_storage TO authenticated;
GRANT SELECT ON public.pdf_storage TO anon;

COMMIT;
