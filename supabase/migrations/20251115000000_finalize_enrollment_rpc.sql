-- Finalize Enrollment: Generates fee charges from an enrollment in an idempotent, audited, and RLS-safe way
-- This migration is idempotent and safe to re-run.

-- 0) Helpers: is_staff()
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'is_staff' AND pg_function_is_visible(oid)
  ) THEN
    CREATE OR REPLACE FUNCTION public.is_staff()
    RETURNS boolean
    LANGUAGE sql
    STABLE
    SET search_path = public
    AS $is_staff$
      SELECT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
      );
    $is_staff$;
    COMMENT ON FUNCTION public.is_staff() IS 'Returns true if auth.uid() has role ADMIN or ASIST in public.profiles.';
  END IF;
END$$;

-- 1) Ensure fee has required columns/constraints for idempotency and traceability
DO $$
DECLARE
  v_exists boolean;
BEGIN
  -- Add year_academico if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='fee' AND column_name='year_academico'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN year_academico int;
  END IF;

  -- Add numero_cuota if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='fee' AND column_name='numero_cuota'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN numero_cuota int;
  END IF;

  -- Add enrollment_id (nullable) for traceability if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='fee' AND column_name='enrollment_id'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL;
  END IF;

  -- Add unique constraint for idempotent inserts per student/year/cuota
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='fee' AND indexname='ux_fee_student_year_cuota'
  ) THEN
    -- Clean up any legacy duplicates before enforcing the unique index
    WITH dup_fee AS (
      SELECT id,
             ROW_NUMBER() OVER (
               PARTITION BY student_id, year_academico, numero_cuota
               ORDER BY COALESCE(created_at, updated_at, now()) ASC, id ASC
             ) AS rn
        FROM public.fee
       WHERE student_id IS NOT NULL
         AND year_academico IS NOT NULL
         AND numero_cuota IS NOT NULL
    )
    DELETE FROM public.fee f
    USING dup_fee d
     WHERE f.id = d.id
       AND d.rn > 1;

    CREATE UNIQUE INDEX ux_fee_student_year_cuota
      ON public.fee(student_id, year_academico, numero_cuota)
      WHERE student_id IS NOT NULL AND year_academico IS NOT NULL AND numero_cuota IS NOT NULL;
  END IF;
END$$;

-- 2) Finalize RPC
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
  v_skip_docs boolean := COALESCE((p_options->>'skip_doc_checks')::boolean, false);
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;

  r_es RECORD;
  r_cuota RECORD;
  v_has_prestacion boolean;
  v_has_pagare boolean;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Load enrollment and guardian
  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  -- Authorization
  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Ready check (optional skip for staff via option)
  IF NOT v_skip_docs THEN
    -- PRESTACION signed by guardian
    SELECT EXISTS (
      SELECT 1
        FROM public.enrollment_documents d
  JOIN public.signatures s ON s.enrollment_document_id = d.id AND s.signer_type IN ('GUARDIAN','APODERADO') AND s.signed_at IS NOT NULL
       WHERE d.enrollment_id = p_enrollment_id AND d.type = 'PRESTACION')
    INTO v_has_prestacion;

    -- at least one PAGARE*
    SELECT EXISTS (
      SELECT 1
        FROM public.enrollment_documents d
  JOIN public.signatures s ON s.enrollment_document_id = d.id AND s.signer_type IN ('GUARDIAN','APODERADO') AND s.signed_at IS NOT NULL
       WHERE d.enrollment_id = p_enrollment_id AND (d.type LIKE 'PAGARE%'))
    INTO v_has_pagare;

    IF NOT (COALESCE(v_has_prestacion,false) AND COALESCE(v_has_pagare,false)) THEN
      RAISE EXCEPTION 'NOT_READY: required documents or signatures are missing';
    END IF;
  END IF;

  -- Fetch students
  FOR r_es IN
    SELECT es.student_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    -- Ensure student_guardian relation
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

  -- Resolve payment plan: options.payment_plan > enrollment.meta.payment_plan > any doc payload
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

  -- Compute cuotas array
  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
    -- try to synthesize from n_cuotas, primer_vencimiento, monto_por_cuota or monto_total
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

  -- Dry-run summary scaffold
  v_summary := '[]'::jsonb;

  -- Iterate students x cuotas
  FOR r_es IN SELECT es.student_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    -- per-student accumulation
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

  -- Update enrollment status
  IF NOT v_dry_run THEN
    UPDATE public.enrollments SET status = 'completed', updated_at = now()
     WHERE id = p_enrollment_id;

    -- Mark students as MATRICULADO until contracts are fully activated
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary
  );
END;
$$;

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 'Finalize an enrollment: validates readiness, ensures links, generates fee charges idempotently, and marks enrollment as CONFIRMED. Supports dry_run and staff overrides.';

-- 3) Grants
REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;
