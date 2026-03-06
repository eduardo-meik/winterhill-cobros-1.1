-- FIX: Three RLS helper functions that compare against UPPERCASE roles
-- but the profiles table stores roles in LOWERCASE ('admin', 'asist', 'guardian').
-- This causes them to ALWAYS return FALSE, blocking all data for admin/asist users.
--
-- Affected tables (via these functions):
--   get_current_user_role():  fee, cursos, student_guardian, profiles, auth_logs
--   is_admin_or_asist():      students, guardians
--   is_staff():               student_academic_records
--
-- Fix: Use upper(role) in all three functions so comparisons work regardless of case.

BEGIN;

-- 1. Fix get_current_user_role() → return UPPER(role)
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT upper(role)
  FROM public.profiles
  WHERE id = auth.uid()
  LIMIT 1;
$$;

-- 2. Fix is_admin_or_asist() → use upper(role) in comparison
CREATE OR REPLACE FUNCTION public.is_admin_or_asist()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND upper(role) IN ('ADMIN', 'ASIST')
  );
$$;

-- 3. Fix is_staff() → use upper(role) in comparison
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
    AND upper(p.role) IN ('ADMIN', 'ASIST')
  );
$$;

-- 4. Also fix cursos_admin_full_access and cursos_asist_full_access
--    These use inline queries comparing raw role against uppercase.
DROP POLICY IF EXISTS "cursos_admin_full_access" ON public.cursos;
CREATE POLICY "cursos_admin_full_access" ON public.cursos
  FOR ALL TO authenticated
  USING (
    (SELECT upper(profiles.role) FROM profiles WHERE profiles.id = auth.uid()) = 'ADMIN'
  )
  WITH CHECK (
    (SELECT upper(profiles.role) FROM profiles WHERE profiles.id = auth.uid()) = 'ADMIN'
  );

DROP POLICY IF EXISTS "cursos_asist_full_access" ON public.cursos;
CREATE POLICY "cursos_asist_full_access" ON public.cursos
  FOR ALL TO authenticated
  USING (
    (SELECT upper(profiles.role) FROM profiles WHERE profiles.id = auth.uid()) = 'ASIST'
  )
  WITH CHECK (
    (SELECT upper(profiles.role) FROM profiles WHERE profiles.id = auth.uid()) = 'ASIST'
  );

COMMIT;

-- Verify: Run this to confirm the fix works
-- SELECT get_current_user_role();
-- SELECT is_admin_or_asist();
-- SELECT is_staff();
