-- ============================================================
-- MIGRACIÓN: Añadir columnas faltantes a tabla cheques
-- Fecha: 2025-12-17
-- Descripción: Consolida las columnas numero_cuota, document_id 
--              y folio_number necesarias para el flujo de cheques
-- ============================================================

BEGIN;

-- 1) Añadir numero_cuota (correlación cheque -> cuota)
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS numero_cuota integer;

-- Constraint: numero_cuota debe ser >= 1 si tiene valor
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'cheques_numero_cuota_check'
  ) THEN
    ALTER TABLE public.cheques
      ADD CONSTRAINT cheques_numero_cuota_check 
      CHECK (numero_cuota IS NULL OR numero_cuota >= 1);
  END IF;
END $$;

-- Índice compuesto para búsquedas por enrollment + cuota
CREATE INDEX IF NOT EXISTS idx_cheques_enrollment_cuota 
  ON public.cheques(enrollment_id, numero_cuota);

-- 2) Añadir document_id (FK al pagaré en enrollment_documents)
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS document_id uuid;

-- Añadir FK si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'cheques_document_id_fkey'
  ) THEN
    ALTER TABLE public.cheques
      ADD CONSTRAINT cheques_document_id_fkey 
      FOREIGN KEY (document_id) 
      REFERENCES public.enrollment_documents(id) 
      ON DELETE SET NULL;
  END IF;
END $$;

-- Índice para búsquedas por document_id
CREATE INDEX IF NOT EXISTS idx_cheques_document_id 
  ON public.cheques(document_id);

-- 3) Añadir folio_number (desnormalización del folio del pagaré)
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS folio_number text;

-- Índice para búsquedas por folio
CREATE INDEX IF NOT EXISTS idx_cheques_folio_number 
  ON public.cheques(folio_number);

-- 4) Comentarios descriptivos
COMMENT ON COLUMN public.cheques.numero_cuota IS 'Número de cuota que este cheque cubre (1-N)';
COMMENT ON COLUMN public.cheques.document_id IS 'FK al documento pagaré asociado en enrollment_documents';
COMMENT ON COLUMN public.cheques.folio_number IS 'Número de folio del pagaré (desnormalizado para consultas rápidas)';

COMMIT;

-- ============================================================
-- VERIFICACIÓN (ejecutar después del COMMIT)
-- ============================================================
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'cheques' 
--   AND column_name IN ('numero_cuota', 'document_id', 'folio_number');
