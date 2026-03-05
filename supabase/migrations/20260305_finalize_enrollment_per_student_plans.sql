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
