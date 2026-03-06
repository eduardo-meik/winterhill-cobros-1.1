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

COMMENT ON FUNCTION public.promote_and_enroll_batch IS
  'Promotes students to next curso for target year, creates formal enrollments grouped by guardian, and optionally generates fees from the supplied payment plan.';
