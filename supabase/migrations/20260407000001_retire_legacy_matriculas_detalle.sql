-- Migration: retire legacy matriculas_detalle
-- Date: 2026-04-07
-- Purpose:
--   - Remove legacy matriculas_detalle table no longer used by runtime flows.
--   - Clean up residual RLS policies and grants tied to it.
-- Safety:
--   - Aborts if the table contains rows, to prevent accidental data loss.

DO $$
DECLARE
  v_row_count bigint := 0;
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'matriculas_detalle'
  ) THEN
    EXECUTE 'SELECT count(*) FROM public.matriculas_detalle' INTO v_row_count;
  END IF;

  IF v_row_count > 0 THEN
    RAISE EXCEPTION 'Abortado: public.matriculas_detalle contiene % registro(s). Revisar migracion antes de eliminar.', v_row_count;
  END IF;
END;
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'matriculas_detalle'
  ) THEN
    EXECUTE 'DROP POLICY IF EXISTS matriculas_detalle_read_policy ON public.matriculas_detalle';
    EXECUTE 'DROP POLICY IF EXISTS matriculas_detalle_staff_insert ON public.matriculas_detalle';
    EXECUTE 'DROP POLICY IF EXISTS matriculas_detalle_staff_update ON public.matriculas_detalle';
    EXECUTE 'DROP POLICY IF EXISTS matriculas_detalle_staff_delete ON public.matriculas_detalle';
    EXECUTE 'DROP POLICY IF EXISTS "matriculas_detalle_read_policy" ON public.matriculas_detalle';
    EXECUTE 'DROP POLICY IF EXISTS "matriculas_detalle_staff_insert" ON public.matriculas_detalle';
    EXECUTE 'DROP POLICY IF EXISTS "matriculas_detalle_staff_update" ON public.matriculas_detalle';
    EXECUTE 'DROP POLICY IF EXISTS "matriculas_detalle_staff_delete" ON public.matriculas_detalle';
    EXECUTE 'REVOKE ALL ON TABLE public.matriculas_detalle FROM anon, authenticated';
    EXECUTE 'DROP TABLE public.matriculas_detalle';
  END IF;
END;
$$;
