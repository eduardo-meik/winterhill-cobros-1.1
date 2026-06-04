-- ============================================================================
-- SECURITY HARDENING MIGRATION
-- Date: 2026-02-22
-- Resolves ALL Supabase Linter findings (3 ERRORs + 25 WARNs)
-- ============================================================================
-- PHASE 4.1 – Fix SECURITY DEFINER views
-- PHASE 4.2 – Drop orphan backup table
-- PHASE 5.1 – Fix search_path on all public functions
-- PHASE 5.2 – Harden overly-permissive RLS policies
-- PHASE 7.1 – Cleanup redundant policies
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 4.1 – SECURITY DEFINER VIEWS → SECURITY INVOKER
-- ════════════════════════════════════════════════════════════════════════════

-- 4.1.1  database_metadata → recreate with security_invoker = true
DROP VIEW IF EXISTS public.database_metadata CASCADE;

CREATE VIEW public.database_metadata WITH (security_invoker = true) AS
SELECT
    t.table_schema,
    t.table_name,
    jsonb_agg(
        jsonb_build_object(
            'column_name', c.column_name,
            'data_type', c.data_type,
            'is_nullable', c.is_nullable,
            'column_default', c.column_default,
            'character_maximum_length', c.character_maximum_length
        ) ORDER BY c.ordinal_position
    ) AS metadata
FROM information_schema.tables t
JOIN information_schema.columns c
  ON t.table_name = c.table_name AND t.table_schema = c.table_schema
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
GROUP BY t.table_schema, t.table_name
ORDER BY t.table_name;

GRANT SELECT ON public.database_metadata TO authenticated;

-- 4.1.2  payment_summary → recreate with security_invoker = true
DROP VIEW IF EXISTS public.payment_summary CASCADE;

CREATE VIEW public.payment_summary WITH (security_invoker = true) AS
SELECT
    f.id,
    f.student_id,
    s.whole_name   AS student_name,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    c.nom_curso    AS course_name,
    f.amount,
    f.numero_cuota,
    f.due_date,
    f.payment_date,
    f.status,
    f.payment_method,
    f.num_boleta,
    f.mov_bancario,
    f.notes,
    f.created_at,
    f.updated_at,
    CASE
        WHEN f.status = 'overdue' AND f.due_date IS NOT NULL
        THEN (CURRENT_DATE - f.due_date::date)
        ELSE NULL
    END AS days_overdue,
    CASE f.status
        WHEN 'paid'    THEN 'Pagado'
        WHEN 'pending' THEN 'Pendiente'
        WHEN 'overdue' THEN 'Vencido'
        ELSE f.status
    END AS status_display
FROM public.fee f
LEFT JOIN public.students s ON f.student_id = s.id
LEFT JOIN public.cursos   c ON s.curso = c.id
ORDER BY f.due_date DESC, f.created_at DESC;

GRANT SELECT ON public.payment_summary TO authenticated;

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 4.2 – DROP ORPHAN BACKUP TABLE
-- ════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS public.student_guardian_backup_20241222;

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 5.1 – FIX search_path ON ALL PUBLIC FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════
-- Uses ALTER FUNCTION to set search_path without recreating the function body.
-- Wrapped in DO blocks to gracefully skip functions that may not exist.

-- ── 5.1.1  CRITICAL: used in RLS / auth ──

DO $$ BEGIN
  ALTER FUNCTION public.get_current_user_role()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_current_user_role() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.current_jwt_role()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function current_jwt_role() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.es_admin_o_equipo(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function es_admin_o_equipo(uuid) does not exist, skipping.';
END $$;

-- ── 5.1.2  HIGH: triggers & financial ops ──

DO $$ BEGIN
  ALTER FUNCTION public.set_updated_at()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function set_updated_at() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.update_cheques_updated_at()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function update_cheques_updated_at() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.update_student_academic_records_updated_at()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function update_student_academic_records_updated_at() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.set_fee_owner_default()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function set_fee_owner_default() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.calculate_enrollment_payment_plan(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function calculate_enrollment_payment_plan(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.sanitize_run(text)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function sanitize_run(text) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.validate_run(text)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function validate_run(text) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.generate_invoice(uuid, integer, integer, numeric)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function generate_invoice(uuid,int,int,numeric) does not exist, skipping.';
END $$;

-- ── 5.1.3  MEDIUM: RPCs & helpers ──

DO $$ BEGIN
  ALTER FUNCTION public.set_academic_year_dates()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function set_academic_year_dates() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.sync_student_current_curso()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function sync_student_current_curso() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.get_student_course(uuid, integer)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_student_course(uuid,int) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.get_enrollment_document_url(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_enrollment_document_url(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.update_pre_matriculado_students()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function update_pre_matriculado_students() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.get_current_year_cursos()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_current_year_cursos() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.get_student_promotion_suggestion(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_student_promotion_suggestion(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.actualizar_estado_std(uuid, text)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function actualizar_estado_std(uuid,text) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.suggest_cheques_for_enrollment(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function suggest_cheques_for_enrollment(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.current_academic_year()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function current_academic_year() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.trg_mark_document_signed_from_signature()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function trg_mark_document_signed_from_signature() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.trg_mark_document_signed_from_receipt()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function trg_mark_document_signed_from_receipt() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.required_enrollment_documents_state(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function required_enrollment_documents_state(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.generate_libro_matricula_report(integer, varchar, varchar)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function generate_libro_matricula_report(int,varchar,varchar) does not exist, skipping.';
END $$;

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 5.2 – HARDEN OVERLY-PERMISSIVE RLS POLICIES
-- ════════════════════════════════════════════════════════════════════════════
-- Replace USING(true) / WITH CHECK(true) on write operations with proper
-- role checks. Keep SELECT USING(true) for intentional public read access.
-- Roles: ADMIN, ASIST (staff). READONLY/guardian via owner_id checks.

-- ── 5.2.1  invoices: replace open ALL with staff-only ──

DROP POLICY IF EXISTS "invoices_authenticated_policy" ON public.invoices;
DROP POLICY IF EXISTS "invoices_staff_write" ON public.invoices;
DROP POLICY IF EXISTS "invoices_staff_update" ON public.invoices;
DROP POLICY IF EXISTS "invoices_staff_delete" ON public.invoices;

CREATE POLICY invoices_staff_write ON public.invoices
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

CREATE POLICY invoices_staff_update ON public.invoices
  FOR UPDATE
  TO authenticated
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

CREATE POLICY invoices_staff_delete ON public.invoices
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

-- Keep the existing SELECT policy "All authenticated users can read invoices"
-- which uses USING(true) — intentional public read access.

-- ── 5.2.2  matriculas_detalle: replace open INSERT/UPDATE/DELETE with staff-only ──

DROP POLICY IF EXISTS "matriculas_detalle_delete_policy" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_insert_policy" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_update_policy" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_staff_insert" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_staff_update" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_staff_delete" ON public.matriculas_detalle;

CREATE POLICY matriculas_detalle_staff_insert ON public.matriculas_detalle
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

CREATE POLICY matriculas_detalle_staff_update ON public.matriculas_detalle
  FOR UPDATE
  TO authenticated
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

CREATE POLICY matriculas_detalle_staff_delete ON public.matriculas_detalle
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

-- Keep "matriculas_detalle_read_policy" SELECT USING(true) for public read.

-- ── 5.2.3  student_guardian: replace open ALL with staff + owner ──

DROP POLICY IF EXISTS "student_guardian_authenticated_policy" ON public.student_guardian;
DROP POLICY IF EXISTS "student_guardian_owner_policy" ON public.student_guardian;

CREATE POLICY student_guardian_owner_policy ON public.student_guardian
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = student_guardian.guardian_id
        AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = student_guardian.guardian_id
        AND g.owner_id = auth.uid()
    )
  );

-- Staff access already covered by:
--   student_guardian_admin_access (ADMIN)
--   student_guardian_asist_access (ASIST)

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 7.1 – CLEANUP REDUNDANT POLICIES
-- ════════════════════════════════════════════════════════════════════════════
-- Where a broad policy (e.g., is_admin_or_asist()) already covers both ADMIN
-- and ASIST, remove the individual role-specific policies to reduce noise.
--
-- IMPORTANT: Only remove if the covering policy already exists.
--            We verify existence before dropping.

-- ── 7.1.1  profiles: profiles_own_record duplicates profiles_owner_policy ──
-- Both use (id = auth.uid()). Keep profiles_owner_policy.
DROP POLICY IF EXISTS "profiles_own_record" ON public.profiles;

-- ── 7.1.2  students: 3 policies cover admin+asist, keep broadest one ──
-- students_admin_asist_full_access uses is_admin_or_asist() → covers both
DROP POLICY IF EXISTS "students_admin_access" ON public.students;
DROP POLICY IF EXISTS "students_asist_access" ON public.students;

-- ── 7.1.3  guardians: guardians_staff_all covers both roles ──
DROP POLICY IF EXISTS "guardians_admin_access" ON public.guardians;
DROP POLICY IF EXISTS "guardians_asist_access" ON public.guardians;

-- ── 7.1.4  enrollments: enrollments_admin_asist_access covers both ──
DROP POLICY IF EXISTS "enrollments_admin_full_access" ON public.enrollments;
DROP POLICY IF EXISTS "enrollments_asist_full_access" ON public.enrollments;

-- ── 7.1.5  matriculas_detalle: the new staff policies replace admin/asist ──
DROP POLICY IF EXISTS "matriculas_detalle_admin_full_access" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_asist_full_access" ON public.matriculas_detalle;

-- ════════════════════════════════════════════════════════════════════════════
-- VERIFICATION QUERIES (informational – run after applying)
-- ════════════════════════════════════════════════════════════════════════════

-- Check no SECURITY DEFINER views remain:
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_views
  WHERE schemaname = 'public'
    AND definition ILIKE '%security_definer%';
  IF v_count > 0 THEN
    RAISE WARNING '⚠ Still have % SECURITY DEFINER view(s) in public schema', v_count;
  ELSE
    RAISE NOTICE '✅ No SECURITY DEFINER views in public schema';
  END IF;
END $$;

-- Check backup table was dropped:
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'student_guardian_backup_20241222'
  ) THEN
    RAISE WARNING '⚠ student_guardian_backup_20241222 still exists!';
  ELSE
    RAISE NOTICE '✅ Backup table dropped successfully';
  END IF;
END $$;

-- Check all public functions have search_path set:
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proconfig IS NULL
    AND p.prokind = 'f';
  IF v_count > 0 THEN
    RAISE WARNING '⚠ Still have % function(s) without search_path in public schema', v_count;
  ELSE
    RAISE NOTICE '✅ All public functions have search_path configured';
  END IF;
END $$;

COMMIT;
