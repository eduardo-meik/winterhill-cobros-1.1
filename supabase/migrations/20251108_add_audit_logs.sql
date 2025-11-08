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
