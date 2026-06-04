-- FIX: Robust RLS using Security Definer Function
-- This script creates a secure function to check roles, bypassing RLS on the profiles table.
-- This ensures that even if the user cannot "read" the profiles table directly due to RLS, the check still succeeds.

BEGIN;

-- 1. Create a Security Definer function to check roles
-- This function runs with the privileges of the database owner, bypassing RLS on 'profiles'.
CREATE OR REPLACE FUNCTION public.is_admin_or_asist()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('ADMIN', 'ASIST')
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin_or_asist TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_or_asist TO anon;

-- 2. Update Enrollments Policy
DROP POLICY IF EXISTS enrollments_admin_asist_access ON public.enrollments;
CREATE POLICY enrollments_admin_asist_access ON public.enrollments
  FOR ALL TO authenticated
  USING ( public.is_admin_or_asist() )
  WITH CHECK ( public.is_admin_or_asist() );

-- 3. Update Guardians Policy
DROP POLICY IF EXISTS guardians_staff_all ON public.guardians;
CREATE POLICY guardians_staff_all ON public.guardians
  FOR ALL TO authenticated
  USING ( public.is_admin_or_asist() )
  WITH CHECK ( public.is_admin_or_asist() );

-- 4. Update Students Policy
DROP POLICY IF EXISTS "students_admin_asist_full_access" ON public.students;
-- Also drop the old one if it exists
DROP POLICY IF EXISTS "students_admin_full_access" ON public.students;

CREATE POLICY "students_admin_asist_full_access" ON public.students
  FOR ALL TO authenticated
  USING ( public.is_admin_or_asist() )
  WITH CHECK ( public.is_admin_or_asist() );

-- 5. Update Enrollment Students Policy
DROP POLICY IF EXISTS enrollment_students_admin_asist_access ON public.enrollment_students;
CREATE POLICY enrollment_students_admin_asist_access ON public.enrollment_students
  FOR ALL TO authenticated
  USING ( public.is_admin_or_asist() )
  WITH CHECK ( public.is_admin_or_asist() );

-- 6. Ensure RLS is enabled (just in case)
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollment_students ENABLE ROW LEVEL SECURITY;

COMMIT;
