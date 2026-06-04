-- FIX_FINALIZE_ENROLLMENT_PLAN_INVALID.sql
-- Fixes "PLAN_INVALID: unable to compute cuotas from plan" error
-- This occurs when n_cuotas is 0 or missing, but total amount > 0.
-- Also handles missing first due date by defaulting to current date.

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
    SELECT es.student_id
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

  -- VALIDATION: If cuotas exist but seem invalid (all zeros), force regeneration
  -- This handles cases where the stored document payload has malformed amounts (e.g. 0)
  IF v_cuotas IS NOT NULL AND jsonb_typeof(v_cuotas) = 'array' THEN
    DECLARE
      v_has_nonzero boolean := false;
      v_chk_amount numeric;
      v_chk_item jsonb;
    BEGIN
      FOR v_chk_item IN SELECT * FROM jsonb_array_elements(v_cuotas) LOOP
        BEGIN
          -- Try simple cast first
          v_chk_amount := (v_chk_item->>'amount')::numeric;
        EXCEPTION WHEN OTHERS THEN
          v_chk_amount := 0;
        END;
        
        IF v_chk_amount > 0 THEN
          v_has_nonzero := true;
          EXIT;
        END IF;
      END LOOP;
      
      IF NOT v_has_nonzero THEN
        v_cuotas := NULL; -- Force regeneration
      END IF;
    END;
  END IF;

  IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
    DECLARE
      v_n_raw text := COALESCE(v_plan->>'n_cuotas', v_plan->>'cantidad_cuotas');
      v_n int;
      v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
      
      v_total_raw text;
      v_total numeric;
      v_amount_raw text;
      v_amount numeric;
      
      i int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      -- Safe cast for n_cuotas to avoid "invalid input syntax" from placeholders like "__________"
      IF v_n_raw ~ '^[0-9]+$' THEN
        v_n := v_n_raw::int;
      ELSE
        v_n := 0;
      END IF;

      -- Safe cast for total amount (handle "1.028.700" format)
      v_total_raw := TRIM(COALESCE(v_plan->>'monto_total', v_plan->>'colegiatura_anual'));
      
      IF v_total_raw IS NULL OR v_total_raw = '' THEN
        v_total := 0;
      ELSIF v_total_raw ~ '^[0-9]+(\.[0-9]+)?$' THEN
         v_total := v_total_raw::numeric;
      ELSIF v_total_raw ~ '^[0-9]{1,3}(\.[0-9]{3})*(,[0-9]+)?$' THEN
         v_total := REPLACE(REPLACE(v_total_raw, '.', ''), ',', '.')::numeric;
      ELSE
         -- Fallback: try to strip non-numeric chars (except comma/dot)
         -- This handles cases like "$ 1.000.000" or "1 000 000"
         BEGIN
           v_total := REPLACE(REPLACE(REGEXP_REPLACE(v_total_raw, '[^0-9,.]', '', 'g'), '.', ''), ',', '.')::numeric;
         EXCEPTION WHEN OTHERS THEN
           v_total := 0;
         END;
      END IF;

      -- Handle zero cost case
      IF v_total = 0 THEN
         v_cuotas := '[]'::jsonb;
      ELSE
         v_amount_raw := COALESCE(v_plan->>'monto_por_cuota', v_plan->>'monto_cuota');
         
         IF v_amount_raw IS NULL THEN
            v_amount := NULL;
         ELSIF v_amount_raw ~ '^[0-9]+(\.[0-9]+)?$' THEN
            v_amount := v_amount_raw::numeric;
         ELSIF v_amount_raw ~ '^[0-9]{1,3}(\.[0-9]{3})*(,[0-9]+)?$' THEN
            v_amount := REPLACE(REPLACE(v_amount_raw, '.', ''), ',', '.')::numeric;
         ELSE
            v_amount := NULL;
         END IF;
         
         v_amount := COALESCE(v_amount, v_total / NULLIF(v_n,0));

         -- FIX: If n_cuotas is 0/missing but total > 0, assume 1 installment
         IF v_n <= 0 THEN
            v_n := 1;
            v_amount := v_total; -- Ensure amount matches total if we forced n=1
         END IF;

         -- FIX: If first due date is missing, default to today
         IF v_first IS NULL THEN
            v_first := CURRENT_DATE;
         END IF;

         IF v_n IS NULL OR v_amount IS NULL THEN
            RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan (n=% total=% amount=%)', v_n, v_total, v_amount;
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
      END IF;
    END;
  END IF;

  v_summary := '[]'::jsonb;
  
  -- Track total amount for summary
  DECLARE
    v_total_generated_amount numeric := 0;
    v_total_items_count int := 0;
  BEGIN

  FOR r_es IN SELECT es.student_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
      v_final_amount numeric;
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        -- DIVIDE AMOUNT BY NUMBER OF STUDENTS to avoid duplication
        -- The plan amount is the Total for the Guardian. We must split it among students.
        v_final_amount := r_cuota.amount / GREATEST(v_students, 1);
        
        -- Round to integer if needed (optional, but good for CLP)
        v_final_amount := ROUND(v_final_amount);

        v_total_generated_amount := v_total_generated_amount + v_final_amount;
        v_total_items_count := v_total_items_count + 1;

        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', v_final_amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, v_final_amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          ON CONFLICT (student_id, guardian_id, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', v_final_amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', v_final_amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    -- Generate sequential folio
    v_folio_seq := nextval('public.enrollment_folio_seq');
    v_folio := 'ENR-' || v_year || '-' || to_char(v_folio_seq, 'FM000000');
    
    -- Update enrollment with folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    -- Update student status to PRE_MATRICULADO
    UPDATE public.students
       SET estado_std = 'PRE_MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
     );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'created', v_created,
    'skipped', v_skipped,
    'students', v_students,
    'folio', v_folio,
    'items', v_summary,
    'summary', jsonb_build_object(
      'students_count', v_students,
      'total_cuotas', v_total_items_count, -- Use the counter that works in dry_run too
      'total_amount', v_total_generated_amount,
      'year', v_year
    ),
    'dry_run', v_dry_run
  );
  END; -- End block for summary vars
END;
$$;
