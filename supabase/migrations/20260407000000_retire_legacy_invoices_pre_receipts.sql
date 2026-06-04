-- Migration: retire legacy invoices and pre_receipts
-- Date: 2026-04-07
-- Purpose:
--   - Remove legacy financial/document tables no longer used by runtime flows.
--   - Clean up SQL functions, RLS policies, triggers, and grants tied to them.
-- Safety:
--   - Aborts if either table contains rows, to prevent accidental data loss.

DO $$
DECLARE
  v_invoices_count bigint := 0;
  v_pre_receipts_count bigint := 0;
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'invoices'
  ) THEN
    EXECUTE 'SELECT count(*) FROM public.invoices' INTO v_invoices_count;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'pre_receipts'
  ) THEN
    EXECUTE 'SELECT count(*) FROM public.pre_receipts' INTO v_pre_receipts_count;
  END IF;

  IF v_invoices_count > 0 THEN
    RAISE EXCEPTION 'Abortado: public.invoices contiene % registro(s). Revisar migracion antes de eliminar.', v_invoices_count;
  END IF;

  IF v_pre_receipts_count > 0 THEN
    RAISE EXCEPTION 'Abortado: public.pre_receipts contiene % registro(s). Revisar migracion antes de eliminar.', v_pre_receipts_count;
  END IF;
END;
$$;

-- Drop legacy invoice functions first so the table can be removed cleanly.
DROP FUNCTION IF EXISTS public.generate_invoice(uuid, integer, integer, numeric);
DROP FUNCTION IF EXISTS public.generate_invoice(uuid, date, date, jsonb[]);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'invoices'
  ) THEN
    EXECUTE 'DROP POLICY IF EXISTS "All authenticated users can read invoices" ON public.invoices';
    EXECUTE 'DROP POLICY IF EXISTS invoices_staff_write ON public.invoices';
    EXECUTE 'DROP POLICY IF EXISTS invoices_staff_update ON public.invoices';
    EXECUTE 'DROP POLICY IF EXISTS invoices_staff_delete ON public.invoices';
    EXECUTE 'DROP POLICY IF EXISTS "invoices_staff_write" ON public.invoices';
    EXECUTE 'DROP POLICY IF EXISTS "invoices_staff_update" ON public.invoices';
    EXECUTE 'DROP POLICY IF EXISTS "invoices_staff_delete" ON public.invoices';
    EXECUTE 'REVOKE ALL ON TABLE public.invoices FROM anon, authenticated';
    EXECUTE 'DROP TABLE public.invoices';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'pre_receipts'
  ) THEN
    EXECUTE 'DROP POLICY IF EXISTS pre_receipts_guardian_read ON public.pre_receipts';
    EXECUTE 'DROP POLICY IF EXISTS pre_receipts_admin_all ON public.pre_receipts';
    EXECUTE 'DROP TRIGGER IF EXISTS trg_pre_receipts_updated_at ON public.pre_receipts';
    EXECUTE 'REVOKE ALL ON TABLE public.pre_receipts FROM anon, authenticated';
    EXECUTE 'DROP TABLE public.pre_receipts';
  END IF;
END;
$$;
