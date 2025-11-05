-- Add numero_cuota to cheques to support one cheque per installment
-- Date: 2025-11-03

BEGIN;

ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS numero_cuota integer,
  ADD CONSTRAINT cheques_numero_cuota_check CHECK (numero_cuota IS NULL OR numero_cuota >= 1);

-- Helpful composite index for lookups and ordering
CREATE INDEX IF NOT EXISTS idx_cheques_enrollment_cuota ON public.cheques(enrollment_id, numero_cuota);

-- Optional uniqueness (commented). Enable after data backfill if required
-- ALTER TABLE public.cheques
--   ADD CONSTRAINT cheques_unique_enrollment_cuota UNIQUE (enrollment_id, numero_cuota);

COMMIT;
