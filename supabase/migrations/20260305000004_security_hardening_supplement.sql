-- ============================================================================
-- SECURITY HARDENING – SUPPLEMENT
-- Date: 2026-03-05
-- Covers items NOT in 20260222_security_hardening.sql:
--   SC-07: auth_logs INSERT policy (always-true → staff + owner)
--   SC-10: guardian_claim_logs – add RLS policies
--   SC-11: rate_limit_counters – add RLS policies
-- ============================================================================
-- PREREQUISITE: Run 20260222_security_hardening.sql FIRST.
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- SC-07 – auth_logs: restrict INSERT to staff or own user
-- ════════════════════════════════════════════════════════════════════════════
-- Current policy "Users can insert logs" uses WITH CHECK (true).
-- Replace with: user can only insert logs for themselves.

DROP POLICY IF EXISTS "Users can insert logs" ON public.auth_logs;
DROP POLICY IF EXISTS auth_logs_insert_own ON public.auth_logs;

CREATE POLICY auth_logs_insert_own ON public.auth_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id IS NULL OR user_id = auth.uid()::text
  );

-- ════════════════════════════════════════════════════════════════════════════
-- SC-10 – guardian_claim_logs: enable RLS + add policies
-- ════════════════════════════════════════════════════════════════════════════
-- Table is written only by claim_guardian_by_run() (SECURITY DEFINER).
-- Admin/staff need read access for auditing.

ALTER TABLE IF EXISTS public.guardian_claim_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS guardian_claim_logs_staff_read ON public.guardian_claim_logs;

CREATE POLICY guardian_claim_logs_staff_read ON public.guardian_claim_logs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

-- No INSERT/UPDATE/DELETE policies for authenticated users;
-- writes happen exclusively via SECURITY DEFINER function.

-- ════════════════════════════════════════════════════════════════════════════
-- SC-11 – rate_limit_counters: enable RLS + add policies
-- ════════════════════════════════════════════════════════════════════════════
-- Table is used only by check_and_increment_rate_limit() (SECURITY DEFINER).
-- No authenticated user needs direct access. Add service_role-only policy.

ALTER TABLE IF EXISTS public.rate_limit_counters ENABLE ROW LEVEL SECURITY;

-- service_role bypasses RLS by default, but adding explicit policy
-- satisfies the linter and documents intent.
DROP POLICY IF EXISTS rate_limit_service_role_only ON public.rate_limit_counters;

CREATE POLICY rate_limit_service_role_only ON public.rate_limit_counters
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ════════════════════════════════════════════════════════════════════════════
-- VERIFICATION
-- ════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_count integer;
BEGIN
  -- auth_logs: should no longer have always-true INSERT
  SELECT count(*) INTO v_count
  FROM pg_policies
  WHERE tablename = 'auth_logs'
    AND policyname = 'Users can insert logs';
  IF v_count = 0 THEN
    RAISE NOTICE '✅ SC-07: auth_logs always-true INSERT policy removed';
  ELSE
    RAISE WARNING '⚠ SC-07: Old auth_logs INSERT policy still exists';
  END IF;

  -- guardian_claim_logs: should have at least 1 policy
  SELECT count(*) INTO v_count
  FROM pg_policies
  WHERE tablename = 'guardian_claim_logs';
  IF v_count > 0 THEN
    RAISE NOTICE '✅ SC-10: guardian_claim_logs has % policy(ies)', v_count;
  ELSE
    RAISE WARNING '⚠ SC-10: guardian_claim_logs has no policies';
  END IF;

  -- rate_limit_counters: should have at least 1 policy
  SELECT count(*) INTO v_count
  FROM pg_policies
  WHERE tablename = 'rate_limit_counters';
  IF v_count > 0 THEN
    RAISE NOTICE '✅ SC-11: rate_limit_counters has % policy(ies)', v_count;
  ELSE
    RAISE WARNING '⚠ SC-11: rate_limit_counters has no policies';
  END IF;
END $$;

COMMIT;
