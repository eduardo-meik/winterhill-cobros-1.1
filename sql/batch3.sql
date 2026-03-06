-- BATCH 3 (migrations 21 to 30)
-- ######################################################################

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [21/49] MIGRATION: 20251103_alter_cheques_add_numero_cuota
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add numero_cuota to cheques to support one cheque per installment
-- Date: 2025-11-03

BEGIN;

ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS numero_cuota integer;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cheques_numero_cuota_check') THEN
    ALTER TABLE public.cheques
      ADD CONSTRAINT cheques_numero_cuota_check CHECK (numero_cuota IS NULL OR numero_cuota >= 1);
  END IF;
END$$;

-- Helpful composite index for lookups and ordering
CREATE INDEX IF NOT EXISTS idx_cheques_enrollment_cuota ON public.cheques(enrollment_id, numero_cuota);

-- Optional uniqueness (commented). Enable after data backfill if required
-- ALTER TABLE public.cheques
--   ADD CONSTRAINT cheques_unique_enrollment_cuota UNIQUE (enrollment_id, numero_cuota);

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [22/49] MIGRATION: 20251103_fix_cheques_policies
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Fix cheques RLS policies to use correct profiles columns
-- Date: 2025-11-03
-- Reason: ERROR 42703: column profiles.user_id does not exist. Schema uses profiles.id and profiles.role.

DO $$
BEGIN
  -- Ensure table exists before altering policies
  IF to_regclass('public.cheques') IS NULL THEN
    RAISE EXCEPTION 'Table public.cheques does not exist. Run 20251101_create_cheques_table.sql first.';
  END IF;

  -- Drop old policies that reference profiles.user_id and profiles.profile
  EXECUTE 'DROP POLICY IF EXISTS "ADMIN and ASIST can view all cheques" ON public.cheques';
  EXECUTE 'DROP POLICY IF EXISTS "ADMIN and ASIST can insert cheques" ON public.cheques';
  EXECUTE 'DROP POLICY IF EXISTS "ADMIN and ASIST can update cheques" ON public.cheques';

  -- Re-create policies using profiles.id and profiles.role
  EXECUTE 'CREATE POLICY "ADMIN and ASIST can view all cheques"
    ON public.cheques
    FOR SELECT
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.role IN (''ADMIN'', ''ASIST'')
      )
    )';

  EXECUTE 'CREATE POLICY "ADMIN and ASIST can insert cheques"
    ON public.cheques
    FOR INSERT
    TO authenticated
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.role IN (''ADMIN'', ''ASIST'')
      )
    )';

  EXECUTE 'CREATE POLICY "ADMIN and ASIST can update cheques"
    ON public.cheques
    FOR UPDATE
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.role IN (''ADMIN'', ''ASIST'')
      )
    )';

END $$ LANGUAGE plpgsql;

-- Verification (optional):
-- SELECT polname, cmd, roles, qual, with_check FROM pg_policies WHERE schemaname='public' AND tablename='cheques';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [23/49] MIGRATION: 20251108_add_audit_logs
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Add generic audit logging infrastructure
-- Date: 2025-11-08
-- Purpose: Capture critical UPDATE/DELETE operations (amount changes, deletions) across key financial tables.

-- 1. Audit table (idempotent create)
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  occurred_at timestamptz NOT NULL DEFAULT now(),
  actor_uid uuid NULL, -- auth.uid()
  action text NOT NULL, -- UPDATE | DELETE
  table_name text NOT NULL,
  record_pk text NOT NULL, -- serialized primary key value(s)
  changed_columns text[] NULL,
  old_values jsonb NULL,
  new_values jsonb NULL,
  reason text NULL, -- optional manual justification
  extra jsonb NULL -- future metadata
);

COMMENT ON TABLE public.audit_logs IS 'Generic immutable audit trail for critical data modifications.';

-- Minimal index to search recent changes by table and record
CREATE INDEX IF NOT EXISTS audit_logs_table_pk_idx ON public.audit_logs(table_name, record_pk);
CREATE INDEX IF NOT EXISTS audit_logs_actor_idx ON public.audit_logs(actor_uid, occurred_at);

-- 2. Trigger function to append audit rows
CREATE OR REPLACE FUNCTION public.audit_log_change() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp AS
$$
DECLARE
  v_actor uuid := auth.uid();
  v_changed text[] := ARRAY[]::text[];
  v_old jsonb;
  v_new jsonb;
  v_action text;
  v_table text := TG_TABLE_NAME;
  v_pk text;
  col text;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    v_action := 'UPDATE';
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);
    -- Collect changed columns (exclude updated_at noise if only timestamp changes)
    FOR col IN SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = TG_TABLE_NAME LOOP
      IF (v_old -> col) IS DISTINCT FROM (v_new -> col) THEN
        v_changed := array_append(v_changed, col);
      END IF;
    END LOOP;
    IF v_changed = ARRAY['updated_at'] THEN
      -- Skip pure timestamp refresh updates
      RETURN NEW;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    v_action := 'DELETE';
    v_old := to_jsonb(OLD);
    v_new := NULL;
  ELSE
    RETURN NULL; -- ignore other ops
  END IF;

  -- Primary key assumption: single column named id (text serialization fallback)
  IF TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN
    IF to_jsonb(OLD) ? 'id' THEN
      v_pk := COALESCE(OLD.id::text, NEW.id::text);
    ELSE
      v_pk := COALESCE(NEW::text, OLD::text); -- fallback
    END IF;
  END IF;

  INSERT INTO public.audit_logs(actor_uid, action, table_name, record_pk, changed_columns, old_values, new_values)
  VALUES (v_actor, v_action, v_table, v_pk, NULLIF(v_changed, ARRAY[]::text[]), v_old, v_new);

  IF TG_OP = 'UPDATE' THEN
    RETURN NEW;
  ELSE
    RETURN OLD;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.audit_log_change() IS 'Generic trigger function to record UPDATE/DELETE diffs into audit_logs.';

-- 3. Attach triggers to critical tables (idempotent guard by dropping existing named triggers first)
DO $$
BEGIN
  -- fee table
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'tr_audit_fee_change') THEN
    EXECUTE 'DROP TRIGGER tr_audit_fee_change ON public.fee';
  END IF;
  EXECUTE 'CREATE TRIGGER tr_audit_fee_change BEFORE UPDATE OR DELETE ON public.fee FOR EACH ROW EXECUTE FUNCTION public.audit_log_change()';

  -- cheques table
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'tr_audit_cheques_change') THEN
    EXECUTE 'DROP TRIGGER tr_audit_cheques_change ON public.cheques';
  END IF;
  EXECUTE 'CREATE TRIGGER tr_audit_cheques_change BEFORE UPDATE OR DELETE ON public.cheques FOR EACH ROW EXECUTE FUNCTION public.audit_log_change()';

  -- enrollment_documents (focus on deletion / content update)
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'tr_audit_enrollment_documents_change') THEN
    EXECUTE 'DROP TRIGGER tr_audit_enrollment_documents_change ON public.enrollment_documents';
  END IF;
  EXECUTE 'CREATE TRIGGER tr_audit_enrollment_documents_change BEFORE UPDATE OR DELETE ON public.enrollment_documents FOR EACH ROW EXECUTE FUNCTION public.audit_log_change()';
END $$;

-- 4. RLS (readonly to guardians only if their data? For now restrict to staff)
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Staff read policy
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='audit_logs' AND policyname='audit_logs_staff_read'
  ) THEN
    EXECUTE 'CREATE POLICY audit_logs_staff_read ON public.audit_logs FOR SELECT USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN (''ADMIN'',''ASIST'')))';
  END IF;
END $$;

-- Allow INSERTs only from definer context (postgres) so triggers can write despite RLS
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='audit_logs' AND policyname='audit_logs_postgres_insert'
  ) THEN
    EXECUTE 'CREATE POLICY audit_logs_postgres_insert ON public.audit_logs FOR INSERT TO postgres WITH CHECK (true)';
  END IF;
END $$;

-- No direct INSERT/UPDATE/DELETE via client; only trigger (which runs with table privileges). Optionally revoke for safety.
REVOKE ALL ON public.audit_logs FROM anon, authenticated;
GRANT SELECT ON public.audit_logs TO authenticated; -- RLS will still filter

-- 5. Optional view to expose limited columns (hide raw json if desired) - comment out for now
-- CREATE OR REPLACE VIEW public.audit_logs_summary AS
-- SELECT id, occurred_at, actor_uid, action, table_name, record_pk, changed_columns FROM public.audit_logs;
-- GRANT SELECT ON public.audit_logs_summary TO authenticated;

-- 6. Future enhancements (documented only):
-- - Add column request_id to correlate multi-row changes.
-- - Add automatic reason capture through app-supplied set_config('app.audit_reason', ...) pattern.
-- - Add policy allowing guardians to see their own deletions (low priority).


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [24/49] MIGRATION: 20251108_rate_limit
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Rate limiting primitives (fixed window)
-- Date: 2025-11-08

-- 1) Counter table (fixed window)
CREATE TABLE IF NOT EXISTS public.rate_limit_counters (
  key text NOT NULL,
  window_start timestamptz NOT NULL,
  count integer NOT NULL DEFAULT 0,
  CONSTRAINT rate_limit_counters_pkey PRIMARY KEY (key, window_start)
);

CREATE INDEX IF NOT EXISTS rate_limit_counters_window_idx ON public.rate_limit_counters(window_start);

-- 2) Function: check and increment atomically
-- Returns: allowed, remaining, reset_at, current_count
CREATE OR REPLACE FUNCTION public.check_and_increment_rate_limit(
  p_key text,
  p_limit integer,
  p_window_seconds integer,
  p_now timestamptz DEFAULT now()
) RETURNS TABLE (
  allowed boolean,
  remaining integer,
  reset_at timestamptz,
  current_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp AS
$$
DECLARE
  v_window_start timestamptz;
  v_count integer;
  v_reset_at timestamptz;
BEGIN
  -- Compute fixed window start aligned to p_window_seconds
  v_window_start := to_timestamp(floor(extract(epoch from p_now) / p_window_seconds) * p_window_seconds);

  -- Upsert increment
  INSERT INTO public.rate_limit_counters(key, window_start, count)
  VALUES (p_key, v_window_start, 1)
  ON CONFLICT (key, window_start)
  DO UPDATE SET count = public.rate_limit_counters.count + 1
  RETURNING count INTO v_count;

  v_reset_at := v_window_start + make_interval(secs => p_window_seconds);

  allowed := (v_count <= p_limit);
  remaining := GREATEST(p_limit - v_count, 0);
  reset_at := v_reset_at;
  current_count := v_count;
  RETURN;
END;
$$;

COMMENT ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) IS 'Fixed-window rate limit: increments counter and indicates if within limit.';

-- Permissions: callable by service role; block anon/authenticated if desired
REVOKE ALL ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) TO postgres;
GRANT EXECUTE ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) TO service_role;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [25/49] MIGRATION: 20251110_extend_enrollment_documents_types
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

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
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'enrollment_documents_type_check') THEN
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
  END IF;
END$$;

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [26/49] MIGRATION: 20251115_finalize_enrollment_rpc
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Finalize Enrollment: Generates fee charges from an enrollment in an idempotent, audited, and RLS-safe way
-- This migration is idempotent and safe to re-run.

-- 0) Helpers: is_staff()
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'is_staff' AND pg_function_is_visible(oid)
  ) THEN
    CREATE OR REPLACE FUNCTION public.is_staff()
    RETURNS boolean
    LANGUAGE sql
    STABLE
    SET search_path = public
    AS $is_staff$
      SELECT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
      );
    $is_staff$;
    COMMENT ON FUNCTION public.is_staff() IS 'Returns true if auth.uid() has role ADMIN or ASIST in public.profiles.';
  END IF;
END$$;

-- 1) Ensure fee has required columns/constraints for idempotency and traceability
DO $$
DECLARE
  v_exists boolean;
BEGIN
  -- Add year_academico if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='fee' AND column_name='year_academico'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN year_academico int;
  END IF;

  -- Add numero_cuota if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='fee' AND column_name='numero_cuota'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN numero_cuota int;
  END IF;

  -- Add enrollment_id (nullable) for traceability if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='fee' AND column_name='enrollment_id'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL;
  END IF;

  -- Add unique constraint for idempotent inserts per student/year/cuota
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='fee' AND indexname='ux_fee_student_year_cuota'
  ) THEN
    -- Clean up any legacy duplicates before enforcing the unique index
    WITH dup_fee AS (
      SELECT id,
             ROW_NUMBER() OVER (
               PARTITION BY student_id, year_academico, numero_cuota
               ORDER BY COALESCE(created_at, updated_at, now()) ASC, id ASC
             ) AS rn
        FROM public.fee
       WHERE student_id IS NOT NULL
         AND year_academico IS NOT NULL
         AND numero_cuota IS NOT NULL
    )
    DELETE FROM public.fee f
    USING dup_fee d
     WHERE f.id = d.id
       AND d.rn > 1;

    CREATE UNIQUE INDEX ux_fee_student_year_cuota
      ON public.fee(student_id, year_academico, numero_cuota)
      WHERE student_id IS NOT NULL AND year_academico IS NOT NULL AND numero_cuota IS NOT NULL;
  END IF;
END$$;

-- 2) Finalize RPC
DROP FUNCTION IF EXISTS public.finalize_enrollment(uuid, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_year int;
  v_skip_docs boolean := COALESCE((p_options->>'skip_doc_checks')::boolean, false);
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;

  r_es RECORD;
  r_cuota RECORD;
  v_has_prestacion boolean;
  v_has_pagare boolean;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Load enrollment and guardian
  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  -- Authorization
  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Ready check (optional skip for staff via option)
  IF NOT v_skip_docs THEN
    -- PRESTACION signed by guardian
    SELECT EXISTS (
      SELECT 1
        FROM public.enrollment_documents d
  JOIN public.signatures s ON s.enrollment_document_id = d.id AND s.signer_type IN ('GUARDIAN','APODERADO') AND s.signed_at IS NOT NULL
       WHERE d.enrollment_id = p_enrollment_id AND d.type = 'PRESTACION')
    INTO v_has_prestacion;

    -- at least one PAGARE*
    SELECT EXISTS (
      SELECT 1
        FROM public.enrollment_documents d
  JOIN public.signatures s ON s.enrollment_document_id = d.id AND s.signer_type IN ('GUARDIAN','APODERADO') AND s.signed_at IS NOT NULL
       WHERE d.enrollment_id = p_enrollment_id AND (d.type LIKE 'PAGARE%'))
    INTO v_has_pagare;

    IF NOT (COALESCE(v_has_prestacion,false) AND COALESCE(v_has_pagare,false)) THEN
      RAISE EXCEPTION 'NOT_READY: required documents or signatures are missing';
    END IF;
  END IF;

  -- Fetch students
  FOR r_es IN
    SELECT es.student_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    -- Ensure student_guardian relation
    PERFORM 1 FROM public.student_guardian sg
      WHERE sg.student_id = r_es.student_id AND sg.guardian_id = v_enrollment.guardian_id;
    IF NOT FOUND THEN
      IF v_is_staff THEN
        INSERT INTO public.student_guardian(student_id, guardian_id, is_primary)
        VALUES (r_es.student_id, v_enrollment.guardian_id, false)
        ON CONFLICT DO NOTHING;
      ELSE
        RAISE EXCEPTION 'MISSING_RELATION: student % is not linked with this guardian', r_es.student_id;
      END IF;
    END IF;
  END LOOP;

  IF v_students = 0 THEN
    RAISE EXCEPTION 'NO_STUDENTS: enrollment has no students';
  END IF;

  -- Resolve payment plan: options.payment_plan > enrollment.meta.payment_plan > any doc payload
  v_plan := p_options->'payment_plan';
  IF v_plan IS NULL THEN
    SELECT e.meta->'payment_plan' INTO v_plan FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;
  IF v_plan IS NULL THEN
    SELECT ed.generated_payload INTO v_plan
      FROM public.enrollment_documents ed
     WHERE ed.enrollment_id = p_enrollment_id
       AND (ed.type = 'PRESTACION' OR ed.type LIKE 'PAGARE%')
       AND ed.generated_payload IS NOT NULL
     ORDER BY CASE WHEN ed.type='PRESTACION' THEN 0 ELSE 1 END, ed.created_at DESC
     LIMIT 1;
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  -- Compute cuotas array
  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
    -- try to synthesize from n_cuotas, primer_vencimiento, monto_por_cuota or monto_total
    DECLARE
      v_n int := COALESCE((v_plan->>'n_cuotas')::int, NULL);
      v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
      v_amount numeric := COALESCE((v_plan->>'monto_por_cuota')::numeric,
                                   NULLIF((v_plan->>'monto_total')::numeric, NULL) / NULLIF(v_n,0));
      i int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      IF v_n IS NULL OR v_first IS NULL OR v_amount IS NULL THEN
        RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
      END IF;
      WHILE i <= v_n LOOP
        v_synth := v_synth || jsonb_build_object(
          'numero', i,
          'amount', v_amount,
          'due_date', (v_first + make_interval(months := i-1))::date
        );
        i := i + 1;
      END LOOP;
      v_cuotas := v_synth;
    END;
  END IF;

  -- Dry-run summary scaffold
  v_summary := '[]'::jsonb;

  -- Iterate students x cuotas
  FOR r_es IN SELECT es.student_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    -- per-student accumulation
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          ON CONFLICT (student_id, year_academico, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  -- Update enrollment status
  IF NOT v_dry_run THEN
    UPDATE public.enrollments SET status = 'completed', updated_at = now()
     WHERE id = p_enrollment_id;

    -- Mark students as MATRICULADO until contracts are fully activated
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary
  );
END;
$$;

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 'Finalize an enrollment: validates readiness, ensures links, generates fee charges idempotently, and marks enrollment as CONFIRMED. Supports dry_run and staff overrides.';

-- 3) Grants
REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [27/49] MIGRATION: 20251115_staff_intake_rpcs
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Staff RPCs to manage guardian intake surveys (admin upsert/submit)
-- Variant 1: prefer RPCs over widening RLS on guardian_intake_surveys.

-- Helper: is_staff() already created in finalize_enrollment migration; redefine safely
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
  );
$$;

-- Admin upsert: create/update intake for any guardian and year
DROP FUNCTION IF EXISTS public.admin_upsert_guardian_intake(uuid, jsonb, int) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_upsert_guardian_intake(p_guardian_id uuid, p_payload jsonb, p_year int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year int := COALESCE(p_year, (SELECT date_part('year', now())::int));
  v_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'RLS_DENIED: only staff can use this function';
  END IF;

  -- Ensure guardian exists
  PERFORM 1 FROM public.guardians g WHERE g.id = p_guardian_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Guardian % not found', p_guardian_id;
  END IF;

  -- Upsert by (guardian_id, year)
  INSERT INTO public.guardian_intake_surveys (
    guardian_id, year,
    guardian_first_name, guardian_last_name_paterno, guardian_last_name_materno, guardian_relationship,
    guardian_rut, guardian_education_level, guardian_address, guardian_commune, guardian_email, guardian_phone,
    student_first_names, student_last_name_paterno, student_last_name_materno, student_run, student_course, student_course_id,
    student_birth_date, student_nationality, student_gender, student_social_name, student_enrollment_date,
    student_withdrawal_date, student_withdrawal_reason, student_repeat_current, student_previous_institution,
    student_address, student_commune, student_lives_with, alt_contact_name, alt_contact_phone,
    scholarship_percentage, payment_form_prioritario, payment_form_cheques, payment_form_pagare,
    payment_form_credit_card, payment_form_transfer, payment_form_planilla, financial_institution, status
  ) VALUES (
    p_guardian_id, v_year,
    p_payload->>'guardian_first_name', p_payload->>'guardian_last_name_paterno', p_payload->>'guardian_last_name_materno', p_payload->>'guardian_relationship',
    p_payload->>'guardian_rut', p_payload->>'guardian_education_level', p_payload->>'guardian_address', p_payload->>'guardian_commune', p_payload->>'guardian_email', p_payload->>'guardian_phone',
    p_payload->>'student_first_names', p_payload->>'student_last_name_paterno', p_payload->>'student_last_name_materno', p_payload->>'student_run', p_payload->>'student_course', NULLIF(p_payload->>'student_course_id','')::uuid,
    (p_payload->>'student_birth_date')::date, p_payload->>'student_nationality', p_payload->>'student_gender', p_payload->>'student_social_name', (p_payload->>'student_enrollment_date')::date,
    (p_payload->>'student_withdrawal_date')::date, p_payload->>'student_withdrawal_reason', (p_payload->>'student_repeat_current')::boolean, p_payload->>'student_previous_institution',
    p_payload->>'student_address', p_payload->>'student_commune', string_to_array(COALESCE(p_payload->>'student_lives_with',''), '|')::text[], p_payload->>'alt_contact_name', p_payload->>'alt_contact_phone',
    (p_payload->>'scholarship_percentage')::numeric, (p_payload->>'payment_form_prioritario')::boolean, (p_payload->>'payment_form_cheques')::boolean, (p_payload->>'payment_form_pagare')::boolean,
    (p_payload->>'payment_form_credit_card')::boolean, (p_payload->>'payment_form_transfer')::boolean, (p_payload->>'payment_form_planilla')::boolean, p_payload->>'financial_institution', COALESCE(p_payload->>'status','draft')
  )
  ON CONFLICT (guardian_id, year) DO UPDATE SET
    guardian_first_name = EXCLUDED.guardian_first_name,
    guardian_last_name_paterno = EXCLUDED.guardian_last_name_paterno,
    guardian_last_name_materno = EXCLUDED.guardian_last_name_materno,
    guardian_relationship = EXCLUDED.guardian_relationship,
    guardian_rut = EXCLUDED.guardian_rut,
    guardian_education_level = EXCLUDED.guardian_education_level,
    guardian_address = EXCLUDED.guardian_address,
    guardian_commune = EXCLUDED.guardian_commune,
    guardian_email = EXCLUDED.guardian_email,
    guardian_phone = EXCLUDED.guardian_phone,
    student_first_names = EXCLUDED.student_first_names,
    student_last_name_paterno = EXCLUDED.student_last_name_paterno,
    student_last_name_materno = EXCLUDED.student_last_name_materno,
    student_run = EXCLUDED.student_run,
    student_course = EXCLUDED.student_course,
    student_course_id = EXCLUDED.student_course_id,
    student_birth_date = EXCLUDED.student_birth_date,
    student_nationality = EXCLUDED.student_nationality,
    student_gender = EXCLUDED.student_gender,
    student_social_name = EXCLUDED.student_social_name,
    student_enrollment_date = EXCLUDED.student_enrollment_date,
    student_withdrawal_date = EXCLUDED.student_withdrawal_date,
    student_withdrawal_reason = EXCLUDED.student_withdrawal_reason,
    student_repeat_current = EXCLUDED.student_repeat_current,
    student_previous_institution = EXCLUDED.student_previous_institution,
    student_address = EXCLUDED.student_address,
    student_commune = EXCLUDED.student_commune,
    student_lives_with = EXCLUDED.student_lives_with,
    alt_contact_name = EXCLUDED.alt_contact_name,
    alt_contact_phone = EXCLUDED.alt_contact_phone,
    scholarship_percentage = EXCLUDED.scholarship_percentage,
    payment_form_prioritario = EXCLUDED.payment_form_prioritario,
    payment_form_cheques = EXCLUDED.payment_form_cheques,
    payment_form_pagare = EXCLUDED.payment_form_pagare,
    payment_form_credit_card = EXCLUDED.payment_form_credit_card,
    payment_form_transfer = EXCLUDED.payment_form_transfer,
    payment_form_planilla = EXCLUDED.payment_form_planilla,
    financial_institution = EXCLUDED.financial_institution,
    status = EXCLUDED.status
  RETURNING * INTO v_row;

  RETURN to_jsonb(v_row);
END;
$$;

COMMENT ON FUNCTION public.admin_upsert_guardian_intake(uuid, jsonb, int) IS 'STAFF: upsert guardian intake survey for a specific guardian and year.';

REVOKE ALL ON FUNCTION public.admin_upsert_guardian_intake(uuid, jsonb, int) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_upsert_guardian_intake(uuid, jsonb, int) TO authenticated;

-- Admin submit: lock the survey
DROP FUNCTION IF EXISTS public.admin_submit_guardian_intake(uuid, int) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_submit_guardian_intake(p_guardian_id uuid, p_year int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year int := COALESCE(p_year, (SELECT date_part('year', now())::int));
  v_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'RLS_DENIED: only staff can use this function';
  END IF;

  SELECT * INTO v_row FROM public.guardian_intake_surveys
   WHERE guardian_id = p_guardian_id AND year = v_year;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No draft survey found for guardian % and year %', p_guardian_id, v_year;
  END IF;
  IF v_row.status = 'submitted' THEN
    RETURN jsonb_build_object('status','already_submitted','id', v_row.id);
  END IF;
  -- Minimal validations (extend as needed)
  IF v_row.guardian_rut IS NULL OR v_row.student_run IS NULL THEN
    RAISE EXCEPTION 'Required RUN fields missing in intake survey';
  END IF;
  UPDATE public.guardian_intake_surveys
     SET status='submitted', submitted_at=now()
   WHERE id = v_row.id
  RETURNING * INTO v_row;
  RETURN jsonb_build_object('status','submitted','id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.admin_submit_guardian_intake(uuid, int) IS 'STAFF: submit (lock) guardian intake survey for a specific guardian and year.';

REVOKE ALL ON FUNCTION public.admin_submit_guardian_intake(uuid, int) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_submit_guardian_intake(uuid, int) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [28/49] MIGRATION: 20251116_add_matriculado_estado
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add MATRICULADO status for students
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'students' AND column_name = 'estado_std'
  ) THEN
    ALTER TABLE public.students
      ADD COLUMN estado_std text DEFAULT 'ACTIVO';
  END IF;
END$$;

ALTER TABLE public.students
  DROP CONSTRAINT IF EXISTS students_estado_std_check;

ALTER TABLE public.students
  ADD CONSTRAINT students_estado_std_check
  CHECK (estado_std IN ('ACTIVO','RETIRADO','MATRICULADO'));

CREATE INDEX IF NOT EXISTS idx_students_estado_std ON public.students(estado_std);


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [29/49] MIGRATION: 20251118_enrollment_document_receipts
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Enrollment document receipts + signed_at plumbing + finalized RPC refresh
-- Safe to run multiple times.

-- 1) Ensure signatures.signed_at exists and is indexed
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'signatures' AND column_name = 'signed_at'
  ) THEN
    ALTER TABLE public.signatures
      ADD COLUMN signed_at timestamptz NOT NULL DEFAULT timezone('utc', now());
    UPDATE public.signatures
       SET signed_at = COALESCE(signed_at, created_at, timezone('utc', now()));
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_signatures_document_signed_at
  ON public.signatures(enrollment_document_id, signer_type, signed_at);

-- 2) Enrollment document receipts table (physical paperwork tracking)
CREATE TABLE IF NOT EXISTS public.enrollment_document_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_document_id uuid NOT NULL REFERENCES public.enrollment_documents(id) ON DELETE CASCADE,
  received_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  received_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  method text NOT NULL DEFAULT 'PAPER',
  evidence_url text,
  notes text,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'ux_enrollment_document_receipts_document'
       AND conrelid = 'public.enrollment_document_receipts'::regclass
  ) THEN
    ALTER TABLE public.enrollment_document_receipts
      ADD CONSTRAINT ux_enrollment_document_receipts_document UNIQUE (enrollment_document_id);
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_receipts_document ON public.enrollment_document_receipts(enrollment_document_id);
CREATE INDEX IF NOT EXISTS idx_receipts_received_by ON public.enrollment_document_receipts(received_by);

ALTER TABLE public.enrollment_document_receipts ENABLE ROW LEVEL SECURITY;

-- Allow ADMIN/ASIST full control
DROP POLICY IF EXISTS enrollment_document_receipts_staff_policy ON public.enrollment_document_receipts;
CREATE POLICY enrollment_document_receipts_staff_policy ON public.enrollment_document_receipts
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- Keep updated_at in sync
DROP TRIGGER IF EXISTS tr_receipts_updated_at ON public.enrollment_document_receipts;
CREATE TRIGGER tr_receipts_updated_at
  BEFORE UPDATE ON public.enrollment_document_receipts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3) Trigger helpers to mirror signatures/receipts onto enrollment_documents.signed_at
CREATE OR REPLACE FUNCTION public.trg_mark_document_signed_from_signature()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.signed_at IS NULL THEN
    RETURN NEW;
  END IF;
  UPDATE public.enrollment_documents
     SET signed_at = COALESCE(signed_at, NEW.signed_at)
   WHERE id = NEW.enrollment_document_id
     AND signed_at IS NULL;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_mark_document_signed_from_receipt()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.enrollment_documents
     SET signed_at = COALESCE(signed_at, NEW.received_at)
   WHERE id = NEW.enrollment_document_id
     AND signed_at IS NULL;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_signatures_mark_doc_signed ON public.signatures;
CREATE TRIGGER tr_signatures_mark_doc_signed
  AFTER INSERT OR UPDATE OF signed_at ON public.signatures
  FOR EACH ROW EXECUTE FUNCTION public.trg_mark_document_signed_from_signature();

DROP TRIGGER IF EXISTS tr_receipts_mark_doc_signed ON public.enrollment_document_receipts;
CREATE TRIGGER tr_receipts_mark_doc_signed
  AFTER INSERT OR UPDATE ON public.enrollment_document_receipts
  FOR EACH ROW EXECUTE FUNCTION public.trg_mark_document_signed_from_receipt();

-- 4) Helper to summarize required doc readiness (digital or physical)
CREATE OR REPLACE FUNCTION public.required_enrollment_documents_state(p_enrollment_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  WITH docs AS (
    SELECT d.type,
           EXISTS (
             SELECT 1 FROM public.signatures s
             WHERE s.enrollment_document_id = d.id
               AND s.signer_type IN ('GUARDIAN','APODERADO')
               AND s.signed_at IS NOT NULL
           ) AS has_digital,
           EXISTS (
             SELECT 1 FROM public.enrollment_document_receipts r
             WHERE r.enrollment_document_id = d.id
           ) AS has_receipt
      FROM public.enrollment_documents d
     WHERE d.enrollment_id = p_enrollment_id
  ), agg AS (
    SELECT
      bool_or(type = 'PRESTACION' AND (has_digital OR has_receipt)) AS prestacion_ready,
      bool_or(type LIKE 'PAGARE%' AND (has_digital OR has_receipt)) AS pagare_ready,
      bool_or(type = 'PRESTACION' AND has_digital) AS prestacion_digital,
      bool_or(type LIKE 'PAGARE%' AND has_digital) AS pagare_digital,
      bool_or(type = 'PRESTACION' AND has_receipt) AS prestacion_receipt,
      bool_or(type LIKE 'PAGARE%' AND has_receipt) AS pagare_receipt
    FROM docs
  )
  SELECT jsonb_build_object(
    'prestacion_ready', COALESCE(prestacion_ready, false),
    'pagare_ready', COALESCE(pagare_ready, false),
    'prestacion_digital', COALESCE(prestacion_digital, false),
    'pagare_digital', COALESCE(pagare_digital, false),
    'prestacion_receipt', COALESCE(prestacion_receipt, false),
    'pagare_receipt', COALESCE(pagare_receipt, false)
  )
  FROM agg;
$$;

COMMENT ON FUNCTION public.required_enrollment_documents_state(uuid) IS 'Returns JSON summarizing PRESTACION/PAGARE readiness (digital signatures or physical receipts).';

-- 5) RPC to record physical receipt evidence
DROP FUNCTION IF EXISTS public.record_document_receipt(uuid, jsonb);
CREATE OR REPLACE FUNCTION public.record_document_receipt(p_document_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_doc RECORD;
  v_receipt RECORD;
  v_method text := COALESCE(p_options->>'method', 'PAPER');
  v_notes text := NULLIF(p_options->>'notes', '');
  v_evidence text := NULLIF(p_options->>'evidence_url', '');
  v_meta jsonb := COALESCE(p_options->'meta', '{}'::jsonb);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'RLS_DENIED: sólo el equipo puede registrar recepción física';
  END IF;

  SELECT * INTO v_doc FROM public.enrollment_documents WHERE id = p_document_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Document % not found', p_document_id;
  END IF;

  INSERT INTO public.enrollment_document_receipts(
    enrollment_document_id, received_by, method, evidence_url, notes, meta
  ) VALUES (
    p_document_id, v_uid, v_method, v_evidence, v_notes, v_meta
  )
  ON CONFLICT (enrollment_document_id) DO UPDATE SET
    received_at = timezone('utc', now()),
    received_by = EXCLUDED.received_by,
    method = EXCLUDED.method,
    evidence_url = EXCLUDED.evidence_url,
    notes = EXCLUDED.notes,
    meta = EXCLUDED.meta,
    updated_at = timezone('utc', now())
  RETURNING * INTO v_receipt;

  INSERT INTO public.audit_logs(action, table_name, record_pk, actor_uid, reason, extra)
  VALUES (
    'DOCUMENT_RECEIPT_RECORDED',
    'enrollment_documents',
    p_document_id::text,
    v_uid,
    'physical_document_received',
    jsonb_build_object(
      'method', v_method,
      'notes', v_notes,
      'evidence_url', v_evidence,
      'meta', v_meta,
      'receipt_id', v_receipt.id,
      'enrollment_id', v_doc.enrollment_id
    )
  );

  RETURN jsonb_build_object(
    'receipt_id', v_receipt.id,
    'received_at', v_receipt.received_at,
    'method', v_receipt.method,
    'enrollment_document_id', v_receipt.enrollment_document_id
  );
END;
$$;

COMMENT ON FUNCTION public.record_document_receipt(uuid, jsonb) IS 'Staff helper to record physical paperwork reception for an enrollment document.';

REVOKE ALL ON FUNCTION public.record_document_receipt(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.record_document_receipt(uuid, jsonb) TO authenticated;

-- 6) Refresh finalize_enrollment RPC to honor receipts + stricter overrides
DROP FUNCTION IF EXISTS public.finalize_enrollment(uuid, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_year int;
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;
  v_folio text;
  r_es RECORD;
  r_cuota RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Staff can always confirm; guardians still rely on planner safeguards above

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    PERFORM 1 FROM public.student_guardian sg
      WHERE sg.student_id = r_es.student_id AND sg.guardian_id = v_enrollment.guardian_id;
    IF NOT FOUND THEN
      IF v_is_staff THEN
        INSERT INTO public.student_guardian(student_id, guardian_id, is_primary)
        VALUES (r_es.student_id, v_enrollment.guardian_id, false)
        ON CONFLICT DO NOTHING;
      ELSE
        RAISE EXCEPTION 'MISSING_RELATION: student % is not linked with this guardian', r_es.student_id;
      END IF;
    END IF;
  END LOOP;

  IF v_students = 0 THEN
    RAISE EXCEPTION 'NO_STUDENTS: enrollment has no students';
  END IF;

  v_plan := p_options->'payment_plan';
  IF v_plan IS NULL THEN
    SELECT e.meta->'payment_plan' INTO v_plan FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;
  IF v_plan IS NULL THEN
    SELECT ed.generated_payload INTO v_plan
      FROM public.enrollment_documents ed
     WHERE ed.enrollment_id = p_enrollment_id
       AND (ed.type = 'PRESTACION' OR ed.type LIKE 'PAGARE%')
       AND ed.generated_payload IS NOT NULL
     ORDER BY CASE WHEN ed.type='PRESTACION' THEN 0 ELSE 1 END, ed.created_at DESC
     LIMIT 1;
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
    DECLARE
      v_n int := COALESCE((v_plan->>'n_cuotas')::int, NULL);
      v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
      v_amount numeric := COALESCE((v_plan->>'monto_por_cuota')::numeric,
                                   NULLIF((v_plan->>'monto_total')::numeric, NULL) / NULLIF(v_n,0));
      i int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      IF v_n IS NULL OR v_first IS NULL OR v_amount IS NULL THEN
        RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
      END IF;
      WHILE i <= v_n LOOP
        v_synth := v_synth || jsonb_build_object(
          'numero', i,
          'amount', v_amount,
          'due_date', (v_first + make_interval(months := i-1))::date
        );
        i := i + 1;
      END LOOP;
      v_cuotas := v_synth;
    END;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          ON CONFLICT (student_id, guardian_id, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    -- Generate folio
    v_folio := 'ENR-' || v_year || '-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || substring(p_enrollment_id::text, 1, 8);
    
    -- Update enrollment with folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary,
    'folio', v_folio,
    'year', v_year
  );
END;
$$;

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 'Finalize an enrollment once PRESTACION + PAGARE docs are ready (digital or physical receipts), generating tuition charges safely.';

REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [30/49] MIGRATION: 20251119_guardian_identity_fields
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Add guardian identity fields for contract templates
-- Created: 2025-11-19
-- Purpose: Ensure pagaré/autorización documents can render nationality, profession and marital status

ALTER TABLE public.guardians
ADD COLUMN IF NOT EXISTS nacionalidad VARCHAR(50) DEFAULT 'Chilena';

ALTER TABLE public.guardians
ADD COLUMN IF NOT EXISTS profesion VARCHAR(100);

ALTER TABLE public.guardians
ADD COLUMN IF NOT EXISTS estado_civil VARCHAR(20);

-- Backfill nationality for existing guardians so templates show a friendly default
UPDATE public.guardians
SET nacionalidad = 'Chilena'
WHERE nacionalidad IS NULL OR nacionalidad = '';

COMMENT ON COLUMN public.guardians.nacionalidad IS 'Guardian nationality displayed in pagare/autorizacion templates.';
COMMENT ON COLUMN public.guardians.profesion IS 'Guardian profession or occupation displayed in contract templates.';
COMMENT ON COLUMN public.guardians.estado_civil IS 'Guardian marital status displayed in contract templates.';



-- ######################################################################
