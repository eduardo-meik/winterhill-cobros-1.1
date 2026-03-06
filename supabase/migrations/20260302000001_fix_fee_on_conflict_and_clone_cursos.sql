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
