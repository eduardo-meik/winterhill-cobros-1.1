-- Assisted mode RLS policies to allow ADMIN and ASIST to manage enrollments and enrollment_students
-- Safe to run multiple times; policies are dropped/created idempotently.

-- Enrollments: allow ADMIN/ASIST full access
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

-- Enrollment students: allow ADMIN/ASIST full access
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

-- Enrollment documents: allow ADMIN/ASIST full access (needed to manage pagaré records when assisting)
DROP POLICY IF EXISTS enrollment_documents_admin_asist_access ON public.enrollment_documents;
CREATE POLICY enrollment_documents_admin_asist_access ON public.enrollment_documents
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
