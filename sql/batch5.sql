-- BATCH 5 (migrations 41 to 49)
-- ######################################################################

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [41/49] MIGRATION: 20260222_security_hardening
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

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


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [42/49] MIGRATION: 20260302_annual_transition_academic_records
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- MIGRATION: Annual Transition & Academic Records Enhancement
-- Date: 2026-03-02
-- Purpose: 
--   1. Backfill student_academic_records from existing 2025 enrollment data
--   2. Enhance finalize_enrollment to populate student_academic_records
--   3. Create batch promotion helper
--   4. Create get_student_promotion_suggestion function (real implementation)
-- ============================================================================
BEGIN;

-- ============================================================================
-- PART 1: Backfill student_academic_records for existing 2025 data
-- ============================================================================
-- Populate academic records for students that already have a curso assigned
-- This covers both 2025 and 2026 students already in the system

INSERT INTO public.student_academic_records (
  student_id,
  curso_id,
  year_academico,
  fecha_inicio,
  estado,
  enrollment_id,
  created_by
)
SELECT DISTINCT
  s.id AS student_id,
  s.curso AS curso_id,
  c.year_academico,
  COALESCE(s.fecha_matricula, s.created_at::date) AS fecha_inicio,
  CASE
    WHEN s.fecha_retiro IS NOT NULL THEN 'retirado'
    ELSE 'activo'
  END AS estado,
  (
    SELECT es.enrollment_id
    FROM public.enrollment_students es
    JOIN public.enrollments e ON e.id = es.enrollment_id
    WHERE es.student_id = s.id
      AND e.year = c.year_academico
    ORDER BY e.created_at DESC
    LIMIT 1
  ) AS enrollment_id,
  NULL::uuid AS created_by
FROM public.students s
JOIN public.cursos c ON c.id = s.curso
WHERE s.curso IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.student_academic_records sar
    WHERE sar.student_id = s.id
      AND sar.year_academico = c.year_academico
  );

-- ============================================================================
-- PART 2: Enhanced finalize_enrollment RPC
-- Now also:
--   a) Updates students.curso to the enrollment's curso_id
--   b) Inserts a row into student_academic_records
-- ============================================================================
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

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id, es.curso_id
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

  FOR r_es IN SELECT es.student_id, es.curso_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
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

    -- ── NEW: Update student.curso + insert academic record ──
    FOR r_es IN
      SELECT es.student_id, es.curso_id
        FROM public.enrollment_students es
       WHERE es.enrollment_id = p_enrollment_id
         AND es.curso_id IS NOT NULL
    LOOP
      -- Update the student's current curso to the enrollment curso
      UPDATE public.students
         SET curso = r_es.curso_id,
             estado_std = 'MATRICULADO',
             updated_at = now()
       WHERE id = r_es.student_id;

      -- Insert academic record (one per student per year)
      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, enrollment_id, created_by
      ) VALUES (
        r_es.student_id, r_es.curso_id, v_year, CURRENT_DATE, 'activo', p_enrollment_id, v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            enrollment_id = EXCLUDED.enrollment_id,
            updated_at = now(),
            updated_by = v_uid;
    END LOOP;

    -- Also update students without curso_id in enrollment_students (legacy path)
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
          AND es.curso_id IS NULL
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

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 
'Finalize an enrollment: generates fees, updates student.curso, creates academic records, marks enrollment completed.';

REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;

-- ============================================================================
-- PART 3: get_student_promotion_suggestion — real implementation
-- Given a student, suggests the next curso for the following year
-- ============================================================================
DROP FUNCTION IF EXISTS public.get_student_promotion_suggestion(uuid);

CREATE OR REPLACE FUNCTION public.get_student_promotion_suggestion(p_student_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_curso RECORD;
  v_next_curso RECORD;
  v_current_year int;
  v_next_year int;
BEGIN
  v_current_year := EXTRACT(YEAR FROM CURRENT_DATE)::int;
  v_next_year := v_current_year + 1;

  -- Get the student's current curso
  SELECT c.id, c.nom_curso, c.nivel, c.year_academico
    INTO v_current_curso
    FROM public.students s
    JOIN public.cursos c ON c.id = s.curso
   WHERE s.id = p_student_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'suggestion', NULL,
      'reason', 'Student has no current curso assigned'
    );
  END IF;

  -- Try to find the next-level curso for the next academic year
  -- nivel ordering: PRE-KINDER < KINDER < 1B < 2B < 3B < 4B < 5B < 6B < 7B < 8B < I < II < III < IV
  SELECT c.id, c.nom_curso, c.nivel, c.year_academico
    INTO v_next_curso
    FROM public.cursos c
   WHERE c.year_academico = v_next_year
     AND c.nivel = (
       CASE v_current_curso.nivel
         WHEN 'PRE-KINDER' THEN 'KINDER'
         WHEN 'KINDER'     THEN '1B'
         WHEN '1B'         THEN '2B'
         WHEN '2B'         THEN '3B'
         WHEN '3B'         THEN '4B'
         WHEN '4B'         THEN '5B'
         WHEN '5B'         THEN '6B'
         WHEN '6B'         THEN '7B'
         WHEN '7B'         THEN '8B'
         WHEN '8B'         THEN 'I'
         WHEN 'I'          THEN 'II'
         WHEN 'II'         THEN 'III'
         WHEN 'III'        THEN 'IV'
         WHEN 'IV'         THEN NULL -- Graduated
         ELSE NULL
       END
     )
   LIMIT 1;

  IF v_current_curso.nivel = 'IV' THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'current_curso', jsonb_build_object(
        'id', v_current_curso.id,
        'nom_curso', v_current_curso.nom_curso,
        'nivel', v_current_curso.nivel,
        'year', v_current_curso.year_academico
      ),
      'suggestion', NULL,
      'reason', 'Student is in final year (IV medio) — graduating'
    );
  END IF;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'current_curso', jsonb_build_object(
        'id', v_current_curso.id,
        'nom_curso', v_current_curso.nom_curso,
        'nivel', v_current_curso.nivel,
        'year', v_current_curso.year_academico
      ),
      'suggestion', NULL,
      'reason', format('No curso found for nivel %s in year %s', 
        CASE v_current_curso.nivel
          WHEN 'PRE-KINDER' THEN 'KINDER'
          WHEN 'KINDER'     THEN '1B'
          WHEN '1B'         THEN '2B'
          WHEN '2B'         THEN '3B'
          WHEN '3B'         THEN '4B'
          WHEN '4B'         THEN '5B'
          WHEN '5B'         THEN '6B'
          WHEN '6B'         THEN '7B'
          WHEN '7B'         THEN '8B'
          WHEN '8B'         THEN 'I'
          WHEN 'I'          THEN 'II'
          WHEN 'II'         THEN 'III'
          WHEN 'III'        THEN 'IV'
          ELSE 'UNKNOWN'
        END,
        v_next_year
      )
    );
  END IF;

  RETURN jsonb_build_object(
    'student_id', p_student_id,
    'current_curso', jsonb_build_object(
      'id', v_current_curso.id,
      'nom_curso', v_current_curso.nom_curso,
      'nivel', v_current_curso.nivel,
      'year', v_current_curso.year_academico
    ),
    'suggestion', jsonb_build_object(
      'id', v_next_curso.id,
      'nom_curso', v_next_curso.nom_curso,
      'nivel', v_next_curso.nivel,
      'year', v_next_curso.year_academico
    ),
    'reason', 'Promotion suggested based on level sequence'
  );
END;
$$;

COMMENT ON FUNCTION public.get_student_promotion_suggestion(uuid) IS
'Returns the suggested next curso for a student based on their current nivel and the next academic year.';

REVOKE ALL ON FUNCTION public.get_student_promotion_suggestion(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.get_student_promotion_suggestion(uuid) TO authenticated;

-- ============================================================================
-- PART 4: Batch promote students RPC
-- Moves a set of students from their current year to the next year's curso
-- ============================================================================
CREATE OR REPLACE FUNCTION public.batch_promote_students(
  p_student_ids uuid[],
  p_target_year int DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_target_year int;
  v_promoted int := 0;
  v_skipped int := 0;
  v_errors jsonb := '[]'::jsonb;
  v_details jsonb := '[]'::jsonb;
  r_student RECORD;
  v_suggestion jsonb;
  v_next_curso_id uuid;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can batch promote students';
  END IF;

  v_target_year := COALESCE(p_target_year, EXTRACT(YEAR FROM CURRENT_DATE)::int + 1);

  FOREACH r_student.id IN ARRAY p_student_ids LOOP
    BEGIN
      -- Get promotion suggestion
      v_suggestion := public.get_student_promotion_suggestion(r_student.id);
      
      IF v_suggestion->'suggestion' IS NULL OR v_suggestion->>'suggestion' = 'null' THEN
        v_skipped := v_skipped + 1;
        v_errors := v_errors || jsonb_build_object(
          'student_id', r_student.id,
          'reason', v_suggestion->>'reason'
        );
        CONTINUE;
      END IF;

      v_next_curso_id := (v_suggestion->'suggestion'->>'id')::uuid;

      -- Mark current academic record as completed
      UPDATE public.student_academic_records
         SET estado = 'completado',
             fecha_termino = CURRENT_DATE,
             updated_at = now(),
             updated_by = v_uid
       WHERE student_id = r_student.id
         AND year_academico = v_target_year - 1
         AND estado = 'activo';

      -- Update student's current curso
      UPDATE public.students
         SET curso = v_next_curso_id,
             updated_at = now()
       WHERE id = r_student.id;

      -- Create new academic record for target year
      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, created_by
      ) VALUES (
        r_student.id, v_next_curso_id, v_target_year, CURRENT_DATE, 'activo', v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            estado = 'activo',
            fecha_inicio = CURRENT_DATE,
            updated_at = now(),
            updated_by = v_uid;

      v_promoted := v_promoted + 1;
      v_details := v_details || jsonb_build_object(
        'student_id', r_student.id,
        'new_curso_id', v_next_curso_id,
        'new_curso', v_suggestion->'suggestion'->>'nom_curso'
      );

    EXCEPTION WHEN OTHERS THEN
      v_skipped := v_skipped + 1;
      v_errors := v_errors || jsonb_build_object(
        'student_id', r_student.id,
        'reason', SQLERRM
      );
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'promoted', v_promoted,
    'skipped', v_skipped,
    'target_year', v_target_year,
    'details', v_details,
    'errors', v_errors
  );
END;
$$;

COMMENT ON FUNCTION public.batch_promote_students(uuid[], int) IS
'Batch promote students to their next curso for the target academic year. Staff only.';

REVOKE ALL ON FUNCTION public.batch_promote_students(uuid[], int) FROM public;
GRANT EXECUTE ON FUNCTION public.batch_promote_students(uuid[], int) TO authenticated;

-- ============================================================================
-- PART 5: RLS policy for staff to manage student_academic_records
-- ============================================================================
DO $$
BEGIN
  -- Allow staff full access to academic records
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'student_academic_records' AND policyname = 'sar_staff_all'
  ) THEN
    CREATE POLICY sar_staff_all ON public.student_academic_records
      FOR ALL
      USING (public.is_staff())
      WITH CHECK (public.is_staff());
  END IF;
END;
$$;

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [43/49] MIGRATION: 20260302_fix_fee_on_conflict_and_clone_cursos
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- FE-01 / FE-02: Fix ON CONFLICT mismatch in finalize_enrollment
-- TA-07: Clone cursos 2025 → 2026
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────────
-- PART 1: Clone cursos from 2025 to 2026 (TA-07)
-- Only creates 2026 cursos if they don't already exist
-- ──────────────────────────────────────────────────────────────────────────────

INSERT INTO public.cursos (nom_curso, nivel, year_academico, letra_curso)
SELECT 
  nom_curso,
  nivel,
  2026,
  letra_curso
FROM public.cursos
WHERE year_academico = 2025
  AND NOT EXISTS (
    SELECT 1 FROM public.cursos c2
    WHERE c2.nom_curso = cursos.nom_curso
      AND c2.nivel = cursos.nivel
      AND c2.year_academico = 2026
  );

-- ──────────────────────────────────────────────────────────────────────────────
-- PART 2: Fix ON CONFLICT in finalize_enrollment (FE-01 / FE-02)
-- The INSERT INTO fee used ON CONFLICT (student_id, guardian_id, numero_cuota)
-- but the unique index ux_fee_student_year_cuota is on
-- (student_id, year_academico, numero_cuota).
-- This caused the DO NOTHING clause to never match, allowing duplicate fees.
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_enrollment record;
  v_plan       jsonb;
  v_cuotas     jsonb;
  v_year       int;
  v_dry_run    boolean;
  v_students   int;
  v_created    int := 0;
  v_skipped    int := 0;
  v_uid        uuid;
  v_summary    jsonb;
  v_folio      text := null;
  r_es         record;
  r_cuota      record;
BEGIN
  -- ── Auth ──
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- ── Fetch enrollment ──
  SELECT * INTO v_enrollment FROM public.enrollments WHERE id = p_enrollment_id;
  IF v_enrollment IS NULL THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;

  v_dry_run := COALESCE((p_options->>'dry_run')::boolean, true);
  v_year    := v_enrollment.year;

  SELECT count(*) INTO v_students
    FROM public.enrollment_students
   WHERE enrollment_id = p_enrollment_id;

  -- ── Payment plan ──
  v_plan := v_enrollment.payment_plan;
  IF v_plan IS NULL AND p_options ? 'payment_plan' THEN
    v_plan := p_options->'payment_plan';
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'No payment plan found for enrollment %', p_enrollment_id;
  END IF;

  -- ── Cuotas from plan ──
  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_array_length(v_cuotas) = 0 THEN
    DECLARE
      v_num   int := COALESCE((v_plan->>'numero_cuotas')::int, 10);
      v_amt   numeric := COALESCE((v_plan->>'monto_cuota')::numeric, 0);
      v_first date := COALESCE((v_plan->>'primera_cuota')::date, make_date(v_year, 3, 1));
      i       int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      WHILE i <= v_num LOOP
        v_synth := v_synth || jsonb_build_object(
          'numero', i,
          'amount', v_amt,
          'due_date', (v_first + make_interval(months := i-1))::date
        );
        i := i + 1;
      END LOOP;
      v_cuotas := v_synth;
    END;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id, es.curso_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
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
          -- FIX: Match the actual unique index ux_fee_student_year_cuota
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

  IF NOT v_dry_run THEN
    -- Generate folio
    v_folio := 'ENR-' || v_year || '-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || substring(p_enrollment_id::text, 1, 8);
    
    -- Update enrollment with folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    -- ── Update student.curso + insert academic record ──
    FOR r_es IN
      SELECT es.student_id, es.curso_id
        FROM public.enrollment_students es
       WHERE es.enrollment_id = p_enrollment_id
         AND es.curso_id IS NOT NULL
    LOOP
      -- Update the student's current curso to the enrollment curso
      UPDATE public.students
         SET curso = r_es.curso_id,
             estado_std = 'MATRICULADO',
             updated_at = now()
       WHERE id = r_es.student_id;

      -- Insert academic record (one per student per year)
      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, enrollment_id, created_by
      ) VALUES (
        r_es.student_id, r_es.curso_id, v_year, CURRENT_DATE, 'activo', p_enrollment_id, v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            enrollment_id = EXCLUDED.enrollment_id,
            updated_at = now(),
            updated_by = v_uid;
    END LOOP;

    -- Also update students without curso_id in enrollment_students (legacy path)
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
          AND es.curso_id IS NULL
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


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [44/49] MIGRATION: 20260302_promote_and_enroll_batch
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- RPC: promote_and_enroll_batch
-- Purpose: Promote selected students to next curso AND create formal
--          enrollment (matrícula) with fee generation per guardian.
-- Flow:
--   1. For each student → get_student_promotion_suggestion → update curso +
--      academic records (same as batch_promote_students).
--   2. Group promoted students by their primary guardian.
--   3. For each guardian group → create enrollment → insert enrollment_students
--      → finalize_enrollment (generates fees from the supplied payment plan).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.promote_and_enroll_batch(
  p_student_ids uuid[],
  p_target_year int DEFAULT NULL,
  p_payment_plan jsonb DEFAULT NULL,
  p_dry_run boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_target_year int;
  v_promoted int := 0;
  v_skipped int := 0;
  v_errors jsonb := '[]'::jsonb;
  v_details jsonb := '[]'::jsonb;
  v_enrollments_created int := 0;
  v_fees_created int := 0;
  r_student record;
  v_suggestion jsonb;
  v_next_curso_id uuid;
  -- enrollment grouping
  r_group record;
  v_enrollment_id uuid;
  v_finalize_result jsonb;
BEGIN
  -- ── Auth ──
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can batch promote students';
  END IF;

  v_target_year := COALESCE(p_target_year, EXTRACT(YEAR FROM CURRENT_DATE)::int + 1);

  -- ═══════════════════════════════════════════════════════════════════════════
  -- PHASE 1: Promote each student (curso + academic records)
  -- ═══════════════════════════════════════════════════════════════════════════
  FOREACH r_student.id IN ARRAY p_student_ids LOOP
    BEGIN
      v_suggestion := public.get_student_promotion_suggestion(r_student.id);

      IF v_suggestion->'suggestion' IS NULL OR v_suggestion->>'suggestion' = 'null' THEN
        v_skipped := v_skipped + 1;
        v_errors := v_errors || jsonb_build_object(
          'student_id', r_student.id,
          'reason', COALESCE(v_suggestion->>'reason', 'No promotion suggestion')
        );
        CONTINUE;
      END IF;

      v_next_curso_id := (v_suggestion->'suggestion'->>'id')::uuid;

      IF NOT p_dry_run THEN
        -- Mark current academic record as completed
        UPDATE public.student_academic_records
           SET estado = 'completado',
               fecha_termino = CURRENT_DATE,
               updated_at = now(),
               updated_by = v_uid
         WHERE student_id = r_student.id
           AND year_academico = v_target_year - 1
           AND estado = 'activo';

        -- Update student's current curso
        UPDATE public.students
           SET curso = v_next_curso_id,
               estado_std = 'MATRICULADO',
               updated_at = now()
         WHERE id = r_student.id;

        -- Create new academic record for target year
        INSERT INTO public.student_academic_records (
          student_id, curso_id, year_academico, fecha_inicio, estado, created_by
        ) VALUES (
          r_student.id, v_next_curso_id, v_target_year, CURRENT_DATE, 'activo', v_uid
        )
        ON CONFLICT (student_id, year_academico) DO UPDATE
          SET curso_id = EXCLUDED.curso_id,
              estado = 'activo',
              fecha_inicio = CURRENT_DATE,
              updated_at = now(),
              updated_by = v_uid;
      END IF;

      v_promoted := v_promoted + 1;
      v_details := v_details || jsonb_build_object(
        'student_id', r_student.id,
        'new_curso_id', v_next_curso_id,
        'new_curso', v_suggestion->'suggestion'->>'nom_curso',
        'current_curso', v_suggestion->'current_curso'->>'nom_curso'
      );

    EXCEPTION WHEN OTHERS THEN
      v_skipped := v_skipped + 1;
      v_errors := v_errors || jsonb_build_object(
        'student_id', r_student.id,
        'reason', SQLERRM
      );
    END;
  END LOOP;

  -- ═══════════════════════════════════════════════════════════════════════════
  -- PHASE 2: Create formal enrollments grouped by guardian (only if NOT dry run)
  -- ═══════════════════════════════════════════════════════════════════════════
  IF NOT p_dry_run AND v_promoted > 0 THEN
    FOR r_group IN
      SELECT sg.guardian_id, array_agg(d.student_id) AS student_ids
        FROM jsonb_to_recordset(v_details) AS d(student_id uuid, new_curso_id uuid)
        JOIN public.student_guardian sg ON sg.student_id = d.student_id AND sg.is_primary = true
       GROUP BY sg.guardian_id
    LOOP
      BEGIN
        -- Upsert enrollment for this guardian + target year
        INSERT INTO public.enrollments (guardian_id, year, status, meta)
        VALUES (
          r_group.guardian_id,
          v_target_year,
          'draft',
          jsonb_build_object('source', 'promotion_batch', 'promoted_at', now()::text)
        )
        ON CONFLICT (guardian_id, year) DO UPDATE
          SET meta = public.enrollments.meta || jsonb_build_object('promotion_batch_updated', now()::text),
              updated_at = now()
        RETURNING id INTO v_enrollment_id;

        -- Insert enrollment_students for each promoted student of this guardian
        DECLARE
          v_sid uuid;
        BEGIN
          FOREACH v_sid IN ARRAY r_group.student_ids LOOP
            INSERT INTO public.enrollment_students (enrollment_id, student_id)
            VALUES (v_enrollment_id, v_sid)
            ON CONFLICT DO NOTHING;
          END LOOP;
        END;

        -- Store payment plan in enrollment meta if provided
        IF p_payment_plan IS NOT NULL THEN
          UPDATE public.enrollments
             SET meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('payment_plan', p_payment_plan),
                 updated_at = now()
           WHERE id = v_enrollment_id;

          -- Finalize enrollment (generates fees)
          v_finalize_result := public.finalize_enrollment(
            v_enrollment_id,
            jsonb_build_object('dry_run', false, 'payment_plan', p_payment_plan)
          );

          v_fees_created := v_fees_created + COALESCE((v_finalize_result->>'created_charges')::int, 0);
        END IF;

        v_enrollments_created := v_enrollments_created + 1;

      EXCEPTION WHEN OTHERS THEN
        v_errors := v_errors || jsonb_build_object(
          'guardian_id', r_group.guardian_id,
          'reason', 'Enrollment creation failed: ' || SQLERRM
        );
      END;
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'dry_run', p_dry_run,
    'target_year', v_target_year,
    'promoted', v_promoted,
    'skipped', v_skipped,
    'enrollments_created', v_enrollments_created,
    'fees_created', v_fees_created,
    'details', v_details,
    'errors', v_errors
  );
END;
$$;

-- Grant access
GRANT EXECUTE ON FUNCTION public.promote_and_enroll_batch(uuid[], int, jsonb, boolean) TO authenticated;

COMMENT ON FUNCTION public.promote_and_enroll_batch(uuid[], int, jsonb, boolean) IS
  'Promotes students to next curso for target year, creates formal enrollments grouped by guardian, and optionally generates fees from the supplied payment plan.';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [45/49] MIGRATION: 20260305_backfill_academic_records
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- BACKFILL student_academic_records FROM enrollment data
-- MP-01: Poblar tabla student_academic_records desde enrollments existentes
-- ============================================================================
-- This script populates student_academic_records from finalized enrollments
-- that were processed before the trigger was added to finalize_enrollment().
--
-- Safe to run multiple times (uses ON CONFLICT DO UPDATE).
-- ============================================================================

BEGIN;

-- Backfill from enrollment_students joined with enrollments
INSERT INTO public.student_academic_records (
  student_id,
  curso_id,
  year_academico,
  fecha_inicio,
  estado,
  enrollment_id,
  created_at
)
SELECT
  es.student_id,
  s.curso AS curso_id,
  e.year AS year_academico,
  e.created_at::date AS fecha_inicio,
  'activo' AS estado,
  e.id AS enrollment_id,
  e.created_at
FROM public.enrollment_students es
JOIN public.enrollments e ON e.id = es.enrollment_id
JOIN public.students s ON s.id = es.student_id
WHERE e.status = 'completed'
  AND s.curso IS NOT NULL
  AND e.year IS NOT NULL
ON CONFLICT (student_id, year_academico) DO UPDATE
  SET curso_id = EXCLUDED.curso_id,
      enrollment_id = EXCLUDED.enrollment_id,
      fecha_inicio = COALESCE(student_academic_records.fecha_inicio, EXCLUDED.fecha_inicio),
      updated_at = now();

-- Report results
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.student_academic_records;
  RAISE NOTICE 'student_academic_records now has % rows', v_count;
END $$;

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [46/49] MIGRATION: 20260305_finalize_enrollment_per_student_plans
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Support per-student payment plans in finalize_enrollment
-- Problem: When a family has multiple siblings with different tuition amounts
--          (e.g., different grade levels or scholarships), the system was using
--          a single averaged cuota amount for ALL students.
-- Fix:     Accept optional per_student_plans in p_options. When present, each
--          student gets their own cuotas with individually calculated amounts.
-- ============================================================================

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
  v_per_student_plans jsonb;
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

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id, es.curso_id
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

  -- Load per-student plans (new: individual cuotas per student)
  v_per_student_plans := p_options->'per_student_plans';
  -- Also check enrollment.meta for per_student_plans
  IF v_per_student_plans IS NULL THEN
    SELECT e.meta->'per_student_plans' INTO v_per_student_plans
      FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;

  -- Load global/fallback payment plan
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
  IF v_plan IS NULL AND v_per_student_plans IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  -- Build global cuotas as fallback (only if v_plan exists)
  IF v_plan IS NOT NULL THEN
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
        IF v_n IS NOT NULL AND v_first IS NOT NULL AND v_amount IS NOT NULL THEN
          WHILE i <= v_n LOOP
            v_synth := v_synth || jsonb_build_object(
              'numero', i,
              'amount', v_amount,
              'due_date', (v_first + make_interval(months := i-1))::date
            );
            i := i + 1;
          END LOOP;
          v_cuotas := v_synth;
        ELSIF v_per_student_plans IS NULL THEN
          RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
        END IF;
      END;
    END IF;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id, es.curso_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
      v_student_cuotas jsonb;
      v_student_plan jsonb;
    BEGIN
      -- Try to get per-student cuotas first, fall back to global cuotas
      v_student_cuotas := NULL;
      IF v_per_student_plans IS NOT NULL AND v_per_student_plans ? r_es.student_id::text THEN
        v_student_plan := v_per_student_plans->r_es.student_id::text;
        v_student_cuotas := v_student_plan->'cuotas';
        -- If student plan has payment_method, use it
        IF v_student_plan->>'payment_method' IS NOT NULL THEN
          v_method := v_student_plan->>'payment_method';
        END IF;
      END IF;
      -- Fall back to global cuotas if per-student not available
      IF v_student_cuotas IS NULL OR jsonb_typeof(v_student_cuotas) <> 'array' THEN
        v_student_cuotas := v_cuotas;
      END IF;

      IF v_student_cuotas IS NULL THEN
        RAISE EXCEPTION 'PLAN_MISSING: no cuotas found for student %', r_es.student_id;
      END IF;

      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_student_cuotas) AS c
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
          -- FIX: Match the actual unique index ux_fee_student_year_cuota
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

  IF NOT v_dry_run THEN
    -- Generate folio
    v_folio := 'ENR-' || v_year || '-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || substring(p_enrollment_id::text, 1, 8);
    
    -- Update enrollment with folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    -- Update student.curso + insert academic record
    FOR r_es IN
      SELECT es.student_id, es.curso_id
        FROM public.enrollment_students es
       WHERE es.enrollment_id = p_enrollment_id
         AND es.curso_id IS NOT NULL
    LOOP
      UPDATE public.students
         SET curso = r_es.curso_id,
             estado_std = 'MATRICULADO',
             updated_at = now()
       WHERE id = r_es.student_id;

      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, enrollment_id, created_by
      ) VALUES (
        r_es.student_id, r_es.curso_id, v_year, CURRENT_DATE, 'activo', p_enrollment_id, v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            enrollment_id = EXCLUDED.enrollment_id,
            updated_at = now(),
            updated_by = v_uid;
    END LOOP;

    -- Also update students without curso_id in enrollment_students (legacy path)
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
          AND es.curso_id IS NULL
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

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 
'Finalize an enrollment: generates fees (with per-student amounts when available), updates student.curso, creates academic records, marks enrollment completed.';

REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [47/49] MIGRATION: 20260305_folio_unification
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- Migration: Folio Matrícula Unification
-- 
-- Problem: Pagaré and cheques use a UUID substring as folio_number, while the
--          real enrollment folio (ENR-YYYY-NNNNNN) is only generated at
--          finalization time. The school archives physical expedientes by
--          folio number, so all documents must share the same folio.
--
-- Changes:
--   1. New RPC  assign_enrollment_folio(uuid)  — pre-assigns a sequential
--      folio to an enrollment so the pagaré can show it before finalization.
--   2. Fix  finalize_enrollment  — reuses existing folio (instead of
--      overwriting with a timestamp-based one), restores sequential format,
--      and updates cheques.folio_number after finalization.
--
-- Existing signed pagarés are NOT affected. Only new enrollments will
-- receive the pre-assigned folio in their pagaré.
-- ============================================================================

-- 1. Create the assign_enrollment_folio RPC
-- -------------------------------------------
CREATE OR REPLACE FUNCTION public.assign_enrollment_folio(p_enrollment_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_existing_folio text;
  v_folio_seq bigint;
  v_folio text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Fetch enrollment
  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;

  -- Authorization check
  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to access this enrollment';
  END IF;

  -- Check if folio already exists
  v_existing_folio := v_enrollment.meta->>'folio';
  IF v_existing_folio IS NOT NULL AND v_existing_folio <> '' THEN
    RETURN v_existing_folio;
  END IF;

  -- Assign new sequential folio
  v_folio_seq := nextval('public.enrollment_folio_seq');
  v_folio := 'ENR-' || v_enrollment.year || '-' || to_char(v_folio_seq, 'FM000000');

  -- Store in enrollment meta
  UPDATE public.enrollments
     SET meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio),
         updated_at = now()
   WHERE id = p_enrollment_id;

  RETURN v_folio;
END;
$$;

COMMENT ON FUNCTION public.assign_enrollment_folio(uuid) IS
  'Assigns a sequential folio (ENR-YYYY-NNNNNN) to an enrollment. Returns existing folio if already assigned. Idempotent.';

REVOKE ALL ON FUNCTION public.assign_enrollment_folio(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.assign_enrollment_folio(uuid) TO authenticated;


-- 2. Fix finalize_enrollment: reuse existing folio + sequential format + update cheques
-- --------------------------------------------------------------------------------------
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
  v_per_student_plans jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;
  v_folio text;
  v_folio_seq bigint;
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

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id, es.curso_id
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

  -- Load per-student plans (individual cuotas per student)
  v_per_student_plans := p_options->'per_student_plans';
  IF v_per_student_plans IS NULL THEN
    SELECT e.meta->'per_student_plans' INTO v_per_student_plans
      FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;

  -- Load global/fallback payment plan
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
  IF v_plan IS NULL AND v_per_student_plans IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  -- Build global cuotas as fallback (only if v_plan exists)
  IF v_plan IS NOT NULL THEN
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
        IF v_n IS NOT NULL AND v_first IS NOT NULL AND v_amount IS NOT NULL THEN
          WHILE i <= v_n LOOP
            v_synth := v_synth || jsonb_build_object(
              'numero', i,
              'amount', v_amount,
              'due_date', (v_first + make_interval(months := i-1))::date
            );
            i := i + 1;
          END LOOP;
          v_cuotas := v_synth;
        ELSIF v_per_student_plans IS NULL THEN
          RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
        END IF;
      END;
    END IF;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id, es.curso_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
      v_student_cuotas jsonb;
      v_student_plan jsonb;
    BEGIN
      v_student_cuotas := NULL;
      IF v_per_student_plans IS NOT NULL AND v_per_student_plans ? r_es.student_id::text THEN
        v_student_plan := v_per_student_plans->r_es.student_id::text;
        v_student_cuotas := v_student_plan->'cuotas';
        IF v_student_plan->>'payment_method' IS NOT NULL THEN
          v_method := v_student_plan->>'payment_method';
        END IF;
      END IF;
      IF v_student_cuotas IS NULL OR jsonb_typeof(v_student_cuotas) <> 'array' THEN
        v_student_cuotas := v_cuotas;
      END IF;

      IF v_student_cuotas IS NULL THEN
        RAISE EXCEPTION 'PLAN_MISSING: no cuotas found for student %', r_es.student_id;
      END IF;

      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_student_cuotas) AS c
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
          -- FIX: Match the actual unique index ux_fee_student_year_cuota
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

  IF NOT v_dry_run THEN
    -- Reuse existing folio if pre-assigned, otherwise generate sequential one
    v_folio := v_enrollment.meta->>'folio';
    IF v_folio IS NULL OR v_folio = '' THEN
      v_folio_seq := nextval('public.enrollment_folio_seq');
      v_folio := 'ENR-' || v_year || '-' || to_char(v_folio_seq, 'FM000000');
    END IF;

    -- Update enrollment status + folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    -- Update cheques.folio_number to match the real enrollment folio
    UPDATE public.cheques
       SET folio_number = v_folio
     WHERE enrollment_id = p_enrollment_id;

    -- Update student.curso + insert academic record
    FOR r_es IN
      SELECT es.student_id, es.curso_id
        FROM public.enrollment_students es
       WHERE es.enrollment_id = p_enrollment_id
         AND es.curso_id IS NOT NULL
    LOOP
      UPDATE public.students
         SET curso = r_es.curso_id,
             estado_std = 'MATRICULADO',
             updated_at = now()
       WHERE id = r_es.student_id;

      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, enrollment_id, created_by
      ) VALUES (
        r_es.student_id, r_es.curso_id, v_year, CURRENT_DATE, 'activo', p_enrollment_id, v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            enrollment_id = EXCLUDED.enrollment_id,
            updated_at = now(),
            updated_by = v_uid;
    END LOOP;

    -- Update students without curso_id (legacy path)
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
          AND es.curso_id IS NULL
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

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 
'Finalize an enrollment: generates fees (with per-student amounts when available), updates student.curso, creates academic records, marks enrollment completed. Reuses pre-assigned folio if available, otherwise generates sequential one. Updates cheques.folio_number to match.';

REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [48/49] MIGRATION: 20260305_performance_indexes
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- Migration: Performance Indexes (QP-03, QP-04, QP-05)
-- Source: pg_stat_statements analysis — March 5, 2026
-- ============================================================================

-- QP-05: Fee queries with triple join (student+cursos) — 44 calls, avg 518ms
CREATE INDEX IF NOT EXISTS idx_fee_year_academico ON public.fee(year_academico);
CREATE INDEX IF NOT EXISTS idx_fee_student_year ON public.fee(student_id, year_academico);

-- QP-03: Enrollment queries with lateral joins — 532 calls, avg 186ms, 20.4% total
CREATE INDEX IF NOT EXISTS idx_enrollments_created_at ON public.enrollments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_enrollment_students_enrollment ON public.enrollment_students(enrollment_id);

-- QP-04: ILIKE search on students — 168 calls, avg 190ms
-- Trigram indexes for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_guardians_name_trgm ON public.guardians USING gin (first_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_guardians_lastname_trgm ON public.guardians USING gin (last_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_students_wholename_trgm ON public.students USING gin (whole_name gin_trgm_ops);


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [49/49] MIGRATION: 20260305_security_hardening_supplement
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

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



-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- REGISTER MIGRATIONS IN HISTORY TABLE
-- Run this AFTER all migrations above succeed.
-- This keeps supabase_migrations.schema_migrations in sync with CLI.
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250515000001', '20250515000001_add_guardian_student_functions', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250529000000', '20250529000000_add_role_to_student_guardian', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250529000001', '20250529000001_add_unique_constraint_to_student_guardian', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250726202500', '20250726202500_harden_security', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250805000001', '20250805000001_fix_security_definer_views', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250805000002', '20250805000002_fix_function_search_path', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250924', '20250924_matricula_base', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925', '20250925_ensure_profile_for_current_user', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925', '20250925_guardian_auto_onboarding', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925', '20250925_guardian_claim_flow', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925', '20250925_guardian_intake_survey', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251021', '20251021_guardian_invite_and_claim', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251022', '20251022_fix_guardian_intake_auto_create', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251023', '20251023_add_year_to_fee', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251023', '20251023_complete_architecture_implementation', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251027', '20251027_setup_enrollment_documents_bucket', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251030', '20251030_enrollment_assisted_mode_policies', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251031', '20251031_email_logs', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251101', '20251101_create_cheques_table', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251103', '20251103_alter_cheques_add_document_link', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251103', '20251103_alter_cheques_add_numero_cuota', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251103', '20251103_fix_cheques_policies', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251108', '20251108_add_audit_logs', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251108', '20251108_rate_limit', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251110', '20251110_extend_enrollment_documents_types', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251115', '20251115_finalize_enrollment_rpc', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251115', '20251115_staff_intake_rpcs', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251116', '20251116_add_matriculado_estado', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251118', '20251118_enrollment_document_receipts', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251119', '20251119_guardian_identity_fields', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251120120000', '20251120120000_guardian_intake_course_id', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251202', '20251202_fix_security_issues', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251203', '20251203_matricula_p1_p2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251203', '20251203_matricula_p3_p4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251217', '20251217_add_cheques_missing_columns', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_add_guardian_fields_libro_matricula', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_add_pre_matriculado_estado', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_add_student_apellidos_separated', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_create_libro_matricula_rpc', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_fix_libro_matricula_report', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260222', '20260222_security_hardening', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260302', '20260302_annual_transition_academic_records', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260302', '20260302_fix_fee_on_conflict_and_clone_cursos', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260302', '20260302_promote_and_enroll_batch', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_backfill_academic_records', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_finalize_enrollment_per_student_plans', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_folio_unification', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_performance_indexes', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_security_hardening_supplement', '{}') ON CONFLICT DO NOTHING;
