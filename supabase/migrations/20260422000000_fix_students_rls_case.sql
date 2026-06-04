-- ============================================================================
-- Fix: students RLS policies use uppercase roles that never match profiles.role
-- Date: 2026-04-22
--
-- Root cause: Migration 20250507161158_wooden_union.sql created policies on
-- `students` with role = 'ADMIN' / 'FINANCE_MANAGER' / 'REGISTRAR', but
-- profiles.role stores only lowercase: 'admin', 'asist', 'guardian'.
--
-- Additionally, is_staff() helper still used 'ADMIN','ASIST' (uppercase).
-- The 2026-03-07 fix corrected other functions but not is_staff().
--
-- Result: staff users could not read student rows → PostgREST returned
-- student: null in fee+students joins → search in PaymentsPage found nothing.
--
-- This migration:
--   1. Fixes is_staff() to use lowercase role values
--   2. Drops the 4 broken uppercase policies on students
--   3. Creates 3 correct policies: staff full-access, owner full-access, guardian select
--   4. Fixes guardian_claim_logs_staff_read policy (also used uppercase)
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- 1. Fix is_staff() — was using 'ADMIN','ASIST' (uppercase, never matched)
-- ════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin', 'asist')
  );
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. Drop the 4 broken policies on students (all used uppercase roles)
-- ════════════════════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "Admin access"       ON public.students;
DROP POLICY IF EXISTS "Team member access" ON public.students;
DROP POLICY IF EXISTS "Guardian access"    ON public.students;
DROP POLICY IF EXISTS "Owner access"       ON public.students;

-- Also drop named variants that security_hardening referenced but never created
DROP POLICY IF EXISTS students_admin_asist_full_access ON public.students;
DROP POLICY IF EXISTS students_owner_access            ON public.students;
DROP POLICY IF EXISTS students_guardian_select         ON public.students;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. Create correct policies on students
-- ════════════════════════════════════════════════════════════════════════════

-- Staff (admin + asist) have full access via is_staff() SECURITY DEFINER helper.
-- Using the helper avoids inline subquery recursion and keeps policy logic DRY.
CREATE POLICY students_admin_asist_full_access ON public.students
  FOR ALL
  TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- Original owners retain full access to their own records.
CREATE POLICY students_owner_access ON public.students
  FOR ALL
  TO authenticated
  USING (students.owner_id = auth.uid())
  WITH CHECK (students.owner_id = auth.uid());

-- Guardians can read students they are linked to (read-only).
CREATE POLICY students_guardian_select ON public.students
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.student_guardian sg
      WHERE sg.student_id = students.id
        AND sg.guardian_id = auth.uid()
    )
  );

-- ════════════════════════════════════════════════════════════════════════════
-- 4. Fix guardian_claim_logs_staff_read — also used uppercase 'ADMIN','ASIST'
--    (created in 20260305000004_security_hardening_supplement.sql)
-- ════════════════════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS guardian_claim_logs_staff_read ON public.guardian_claim_logs;

CREATE POLICY guardian_claim_logs_staff_read ON public.guardian_claim_logs
  FOR SELECT
  TO authenticated
  USING (public.is_staff());

-- ════════════════════════════════════════════════════════════════════════════
-- 5. Verification
-- ════════════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  v_count integer;
  v_bad   integer;
BEGIN
  -- Verify students now has exactly 3 policies
  SELECT count(*) INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'students';

  IF v_count <> 3 THEN
    RAISE WARNING '⚠ students has % policies (expected 3)', v_count;
  ELSE
    RAISE NOTICE '✅ students has 3 RLS policies';
  END IF;

  -- Verify none of the old uppercase-named policies remain
  SELECT count(*) INTO v_bad
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'students'
    AND policyname IN ('Admin access', 'Team member access', 'Guardian access', 'Owner access');

  IF v_bad > 0 THEN
    RAISE WARNING '⚠ % legacy uppercase policy(ies) still present on students', v_bad;
  ELSE
    RAISE NOTICE '✅ No legacy uppercase policies on students';
  END IF;
END $$;

COMMIT;
