-- Add document link fields to cheques to associate with Pagaré folio
-- Date: 2025-11-03

BEGIN;

-- Add columns if not exists
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS document_id uuid REFERENCES public.enrollment_documents(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS folio_number text;

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_cheques_document_id ON public.cheques(document_id);
CREATE INDEX IF NOT EXISTS idx_cheques_folio_number ON public.cheques(folio_number);

COMMIT;
