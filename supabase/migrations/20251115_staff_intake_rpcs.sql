-- Staff RPCs to manage guardian intake surveys (admin upsert/submit)
-- Variant 1: prefer RPCs over widening RLS on guardian_intake_surveys.

-- Helper: is_staff() already created in finalize_enrollment migration; redefine safely
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
  );
$$;

-- Admin upsert: create/update intake for any guardian and year
DROP FUNCTION IF EXISTS public.admin_upsert_guardian_intake(uuid, jsonb, int) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_upsert_guardian_intake(p_guardian_id uuid, p_payload jsonb, p_year int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year int := COALESCE(p_year, (SELECT date_part('year', now())::int));
  v_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'RLS_DENIED: only staff can use this function';
  END IF;

  -- Ensure guardian exists
  PERFORM 1 FROM public.guardians g WHERE g.id = p_guardian_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Guardian % not found', p_guardian_id;
  END IF;

  -- Upsert by (guardian_id, year)
  INSERT INTO public.guardian_intake_surveys (
    guardian_id, year,
    guardian_first_name, guardian_last_name_paterno, guardian_last_name_materno, guardian_relationship,
    guardian_rut, guardian_education_level, guardian_address, guardian_commune, guardian_email, guardian_phone,
    student_first_names, student_last_name_paterno, student_last_name_materno, student_run, student_course,
    student_birth_date, student_nationality, student_gender, student_social_name, student_enrollment_date,
    student_withdrawal_date, student_withdrawal_reason, student_repeat_current, student_previous_institution,
    student_address, student_commune, student_lives_with, alt_contact_name, alt_contact_phone,
    scholarship_percentage, payment_form_prioritario, payment_form_cheques, payment_form_pagare,
    payment_form_credit_card, payment_form_transfer, payment_form_planilla, financial_institution, status
  ) VALUES (
    p_guardian_id, v_year,
    p_payload->>'guardian_first_name', p_payload->>'guardian_last_name_paterno', p_payload->>'guardian_last_name_materno', p_payload->>'guardian_relationship',
    p_payload->>'guardian_rut', p_payload->>'guardian_education_level', p_payload->>'guardian_address', p_payload->>'guardian_commune', p_payload->>'guardian_email', p_payload->>'guardian_phone',
    p_payload->>'student_first_names', p_payload->>'student_last_name_paterno', p_payload->>'student_last_name_materno', p_payload->>'student_run', p_payload->>'student_course',
    (p_payload->>'student_birth_date')::date, p_payload->>'student_nationality', p_payload->>'student_gender', p_payload->>'student_social_name', (p_payload->>'student_enrollment_date')::date,
    (p_payload->>'student_withdrawal_date')::date, p_payload->>'student_withdrawal_reason', (p_payload->>'student_repeat_current')::boolean, p_payload->>'student_previous_institution',
    p_payload->>'student_address', p_payload->>'student_commune', string_to_array(COALESCE(p_payload->>'student_lives_with',''), '|')::text[], p_payload->>'alt_contact_name', p_payload->>'alt_contact_phone',
    (p_payload->>'scholarship_percentage')::numeric, (p_payload->>'payment_form_prioritario')::boolean, (p_payload->>'payment_form_cheques')::boolean, (p_payload->>'payment_form_pagare')::boolean,
    (p_payload->>'payment_form_credit_card')::boolean, (p_payload->>'payment_form_transfer')::boolean, (p_payload->>'payment_form_planilla')::boolean, p_payload->>'financial_institution', COALESCE(p_payload->>'status','draft')
  )
  ON CONFLICT (guardian_id, year) DO UPDATE SET
    guardian_first_name = EXCLUDED.guardian_first_name,
    guardian_last_name_paterno = EXCLUDED.guardian_last_name_paterno,
    guardian_last_name_materno = EXCLUDED.guardian_last_name_materno,
    guardian_relationship = EXCLUDED.guardian_relationship,
    guardian_rut = EXCLUDED.guardian_rut,
    guardian_education_level = EXCLUDED.guardian_education_level,
    guardian_address = EXCLUDED.guardian_address,
    guardian_commune = EXCLUDED.guardian_commune,
    guardian_email = EXCLUDED.guardian_email,
    guardian_phone = EXCLUDED.guardian_phone,
    student_first_names = EXCLUDED.student_first_names,
    student_last_name_paterno = EXCLUDED.student_last_name_paterno,
    student_last_name_materno = EXCLUDED.student_last_name_materno,
    student_run = EXCLUDED.student_run,
    student_course = EXCLUDED.student_course,
    student_birth_date = EXCLUDED.student_birth_date,
    student_nationality = EXCLUDED.student_nationality,
    student_gender = EXCLUDED.student_gender,
    student_social_name = EXCLUDED.student_social_name,
    student_enrollment_date = EXCLUDED.student_enrollment_date,
    student_withdrawal_date = EXCLUDED.student_withdrawal_date,
    student_withdrawal_reason = EXCLUDED.student_withdrawal_reason,
    student_repeat_current = EXCLUDED.student_repeat_current,
    student_previous_institution = EXCLUDED.student_previous_institution,
    student_address = EXCLUDED.student_address,
    student_commune = EXCLUDED.student_commune,
    student_lives_with = EXCLUDED.student_lives_with,
    alt_contact_name = EXCLUDED.alt_contact_name,
    alt_contact_phone = EXCLUDED.alt_contact_phone,
    scholarship_percentage = EXCLUDED.scholarship_percentage,
    payment_form_prioritario = EXCLUDED.payment_form_prioritario,
    payment_form_cheques = EXCLUDED.payment_form_cheques,
    payment_form_pagare = EXCLUDED.payment_form_pagare,
    payment_form_credit_card = EXCLUDED.payment_form_credit_card,
    payment_form_transfer = EXCLUDED.payment_form_transfer,
    payment_form_planilla = EXCLUDED.payment_form_planilla,
    financial_institution = EXCLUDED.financial_institution,
    status = EXCLUDED.status
  RETURNING * INTO v_row;

  RETURN to_jsonb(v_row);
END;
$$;

COMMENT ON FUNCTION public.admin_upsert_guardian_intake(uuid, jsonb, int) IS 'STAFF: upsert guardian intake survey for a specific guardian and year.';

REVOKE ALL ON FUNCTION public.admin_upsert_guardian_intake(uuid, jsonb, int) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_upsert_guardian_intake(uuid, jsonb, int) TO authenticated;

-- Admin submit: lock the survey
DROP FUNCTION IF EXISTS public.admin_submit_guardian_intake(uuid, int) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_submit_guardian_intake(p_guardian_id uuid, p_year int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year int := COALESCE(p_year, (SELECT date_part('year', now())::int));
  v_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'RLS_DENIED: only staff can use this function';
  END IF;

  SELECT * INTO v_row FROM public.guardian_intake_surveys
   WHERE guardian_id = p_guardian_id AND year = v_year;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No draft survey found for guardian % and year %', p_guardian_id, v_year;
  END IF;
  IF v_row.status = 'submitted' THEN
    RETURN jsonb_build_object('status','already_submitted','id', v_row.id);
  END IF;
  -- Minimal validations (extend as needed)
  IF v_row.guardian_rut IS NULL OR v_row.student_run IS NULL THEN
    RAISE EXCEPTION 'Required RUN fields missing in intake survey';
  END IF;
  UPDATE public.guardian_intake_surveys
     SET status='submitted', submitted_at=now()
   WHERE id = v_row.id
  RETURNING * INTO v_row;
  RETURN jsonb_build_object('status','submitted','id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.admin_submit_guardian_intake(uuid, int) IS 'STAFF: submit (lock) guardian intake survey for a specific guardian and year.';

REVOKE ALL ON FUNCTION public.admin_submit_guardian_intake(uuid, int) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_submit_guardian_intake(uuid, int) TO authenticated;
