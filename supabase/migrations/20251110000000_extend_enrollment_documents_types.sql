-- Migration: Extend allowed types for enrollment_documents.type
-- Date: 2025-11-10
-- Purpose: Support new auto-generated document types (PRESTACION, PRIORITARIO, PAGARE_DEUDA, PAGARE_REPACTACION)

BEGIN;

-- Drop any existing anonymous CHECK constraint(s) on enrollment_documents.type safely
DO $$
DECLARE
  cons RECORD;
BEGIN
  -- First, drop known named constraint if present to avoid duplicate-name error
  BEGIN
    ALTER TABLE public.enrollment_documents DROP CONSTRAINT IF EXISTS enrollment_documents_type_check;
  EXCEPTION WHEN others THEN
    -- ignore
  END;

  FOR cons IN
    SELECT conname
    FROM   pg_constraint c
    JOIN   pg_class t ON t.oid = c.conrelid
    JOIN   pg_namespace n ON n.oid = t.relnamespace
    WHERE  n.nspname = 'public'
    AND    t.relname = 'enrollment_documents'
    AND    c.contype = 'c'
    AND    pg_get_constraintdef(c.oid) ILIKE '%CHECK%type%IN%'
  LOOP
    EXECUTE format('ALTER TABLE public.enrollment_documents DROP CONSTRAINT IF EXISTS %I;', cons.conname);
  END LOOP;
END$$;

-- Add the new explicit CHECK constraint with the full set of allowed types
ALTER TABLE public.enrollment_documents
  ADD CONSTRAINT enrollment_documents_type_check
  CHECK (type IN (
    'PRESTACION',
    'PRIORITARIO',
    'PAGARE',
    'PAGARE_DEUDA',
    'PAGARE_REPACTACION',
    'DECLARACION',
    'OTRO'
  ));

COMMIT;
