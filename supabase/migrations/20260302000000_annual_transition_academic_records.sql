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
  NULL AS created_by
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
