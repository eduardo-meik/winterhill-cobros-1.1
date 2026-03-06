-- FIX: Ensure ADMIN and ASIST roles have full visibility of all enrollment-related data
-- This script updates RLS policies for enrollments, guardians, students, and enrollment_students
-- to explicitly allow 'ADMIN' and 'ASIST' roles to view ALL records.

BEGIN;

-- 1. Enrollments
-- Ensure ADMIN/ASIST can see ALL enrollments
DROP POLICY IF EXISTS enrollments_admin_asist_access ON public.enrollments;
CREATE POLICY enrollments_admin_asist_access ON public.enrollments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  );

-- 2. Guardians
-- Ensure ADMIN/ASIST can see ALL guardians
DROP POLICY IF EXISTS guardians_staff_all ON public.guardians;
CREATE POLICY guardians_staff_all ON public.guardians
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  );

-- 3. Students
-- Update "students_admin_full_access" to include ASIST
DROP POLICY IF EXISTS "students_admin_full_access" ON public.students;
DROP POLICY IF EXISTS "students_admin_asist_full_access" ON public.students;

CREATE POLICY "students_admin_asist_full_access" ON public.students
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = auth.uid() 
      AND p.role IN ('ADMIN', 'ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = auth.uid() 
      AND p.role IN ('ADMIN', 'ASIST')
    )
  );

-- 4. Enrollment Students
-- Ensure ADMIN/ASIST can see ALL enrollment_students
DROP POLICY IF EXISTS enrollment_students_admin_asist_access ON public.enrollment_students;
CREATE POLICY enrollment_students_admin_asist_access ON public.enrollment_students
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  );

COMMIT;
