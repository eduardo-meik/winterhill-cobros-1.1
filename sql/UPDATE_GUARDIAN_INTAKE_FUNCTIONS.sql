-- ============================================================================
-- ACTUALIZAR FUNCIONES guardian_intake_surveys
-- Ejecuta este script para corregir el error 400 en upsert_guardian_intake_survey
-- ============================================================================

-- 1. Función helper: current_academic_year (recrear por si no existe)
CREATE OR REPLACE FUNCTION public.current_academic_year()
RETURNS int LANGUAGE sql IMMUTABLE AS $$
  SELECT date_part('year', now())::int;
$$;

-- 2. DROP y recrear upsert_guardian_intake_survey con la estructura correcta
DROP FUNCTION IF EXISTS public.upsert_guardian_intake_survey(jsonb);

CREATE OR REPLACE FUNCTION public.upsert_guardian_intake_survey(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_guardian_id uuid;
  v_year int := COALESCE((payload->>'year')::int, current_academic_year());
  existing_id uuid;
  result_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  -- Verificar autenticación
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Obtener guardian_id del usuario actual
  SELECT id INTO v_guardian_id 
  FROM public.guardians 
  WHERE owner_id = v_user 
  LIMIT 1;
  
  IF v_guardian_id IS NULL THEN
    RAISE EXCEPTION 'Guardian record not found for user';
  END IF;

  -- Buscar registro existente
  SELECT id INTO existing_id 
  FROM public.guardian_intake_surveys 
  WHERE guardian_id = v_guardian_id AND year = v_year;

  IF existing_id IS NULL THEN
    -- INSERT nuevo registro
    INSERT INTO public.guardian_intake_surveys (
      guardian_id, 
      year,
      guardian_first_name, 
      guardian_last_name_paterno, 
      guardian_last_name_materno, 
      guardian_relationship,
      guardian_rut, 
      guardian_education_level, 
      guardian_address, 
      guardian_commune, 
      guardian_email, 
      guardian_phone,
      student_first_names, 
      student_last_name_paterno, 
      student_last_name_materno, 
      student_run, 
      student_course,
      student_course_id,
      student_birth_date, 
      student_nationality, 
      student_gender, 
      student_social_name, 
      student_enrollment_date,
      student_withdrawal_date, 
      student_withdrawal_reason, 
      student_repeat_current, 
      student_previous_institution,
      student_address, 
      student_commune, 
      student_lives_with, 
      alt_contact_name, 
      alt_contact_phone,
      scholarship_percentage, 
      payment_form_prioritario, 
      payment_form_cheques, 
      payment_form_pagare,
      payment_form_credit_card, 
      payment_form_transfer, 
      payment_form_planilla, 
      financial_institution, 
      status
    ) VALUES (
      v_guardian_id, 
      v_year,
      payload->>'guardian_first_name', 
      payload->>'guardian_last_name_paterno', 
      payload->>'guardian_last_name_materno', 
      payload->>'guardian_relationship',
      payload->>'guardian_rut', 
      payload->>'guardian_education_level', 
      payload->>'guardian_address', 
      payload->>'guardian_commune', 
      payload->>'guardian_email', 
      payload->>'guardian_phone',
      payload->>'student_first_names', 
      payload->>'student_last_name_paterno', 
      payload->>'student_last_name_materno', 
      payload->>'student_run', 
      payload->>'student_course',
      NULLIF(payload->>'student_course_id','')::uuid,
      NULLIF(payload->>'student_birth_date', '')::date, 
      payload->>'student_nationality', 
      payload->>'student_gender', 
      payload->>'student_social_name', 
      NULLIF(payload->>'student_enrollment_date', '')::date,
      NULLIF(payload->>'student_withdrawal_date', '')::date, 
      payload->>'student_withdrawal_reason', 
      COALESCE((payload->>'student_repeat_current')::boolean, false), 
      payload->>'student_previous_institution',
      payload->>'student_address', 
      payload->>'student_commune', 
      COALESCE((payload->'student_lives_with')::jsonb, '[]'::jsonb)::text[], 
      payload->>'alt_contact_name', 
      payload->>'alt_contact_phone',
      NULLIF(payload->>'scholarship_percentage', '')::numeric, 
      COALESCE((payload->>'payment_form_prioritario')::boolean, false), 
      COALESCE((payload->>'payment_form_cheques')::boolean, false), 
      COALESCE((payload->>'payment_form_pagare')::boolean, false),
      COALESCE((payload->>'payment_form_credit_card')::boolean, false), 
      COALESCE((payload->>'payment_form_transfer')::boolean, false), 
      COALESCE((payload->>'payment_form_planilla')::boolean, false), 
      payload->>'financial_institution', 
      COALESCE(payload->>'status','draft')
    ) RETURNING * INTO result_row;
  ELSE
    -- UPDATE registro existente
    UPDATE public.guardian_intake_surveys SET
      guardian_first_name = payload->>'guardian_first_name',
      guardian_last_name_paterno = payload->>'guardian_last_name_paterno',
      guardian_last_name_materno = payload->>'guardian_last_name_materno',
      guardian_relationship = payload->>'guardian_relationship',
      guardian_rut = payload->>'guardian_rut',
      guardian_education_level = payload->>'guardian_education_level',
      guardian_address = payload->>'guardian_address',
      guardian_commune = payload->>'guardian_commune',
      guardian_email = payload->>'guardian_email',
      guardian_phone = payload->>'guardian_phone',
      student_first_names = payload->>'student_first_names',
      student_last_name_paterno = payload->>'student_last_name_paterno',
      student_last_name_materno = payload->>'student_last_name_materno',
      student_run = payload->>'student_run',
      student_course = payload->>'student_course',
      student_course_id = NULLIF(payload->>'student_course_id','')::uuid,
      student_birth_date = NULLIF(payload->>'student_birth_date', '')::date,
      student_nationality = payload->>'student_nationality',
      student_gender = payload->>'student_gender',
      student_social_name = payload->>'student_social_name',
      student_enrollment_date = NULLIF(payload->>'student_enrollment_date', '')::date,
      student_withdrawal_date = NULLIF(payload->>'student_withdrawal_date', '')::date,
      student_withdrawal_reason = payload->>'student_withdrawal_reason',
      student_repeat_current = COALESCE((payload->>'student_repeat_current')::boolean, student_repeat_current),
      student_previous_institution = payload->>'student_previous_institution',
      student_address = payload->>'student_address',
      student_commune = payload->>'student_commune',
      student_lives_with = COALESCE((payload->'student_lives_with')::jsonb, to_jsonb(student_lives_with))::text[],
      alt_contact_name = payload->>'alt_contact_name',
      alt_contact_phone = payload->>'alt_contact_phone',
      scholarship_percentage = NULLIF(payload->>'scholarship_percentage', '')::numeric,
      payment_form_prioritario = COALESCE((payload->>'payment_form_prioritario')::boolean, payment_form_prioritario),
      payment_form_cheques = COALESCE((payload->>'payment_form_cheques')::boolean, payment_form_cheques),
      payment_form_pagare = COALESCE((payload->>'payment_form_pagare')::boolean, payment_form_pagare),
      payment_form_credit_card = COALESCE((payload->>'payment_form_credit_card')::boolean, payment_form_credit_card),
      payment_form_transfer = COALESCE((payload->>'payment_form_transfer')::boolean, payment_form_transfer),
      payment_form_planilla = COALESCE((payload->>'payment_form_planilla')::boolean, payment_form_planilla),
      financial_institution = payload->>'financial_institution',
      status = COALESCE(payload->>'status', status)
    WHERE id = existing_id
    RETURNING * INTO result_row;
  END IF;

  RETURN to_jsonb(result_row);
END;
$$;

COMMENT ON FUNCTION public.upsert_guardian_intake_survey(jsonb) IS 'Creates or updates guardian intake survey draft for current year.';

-- 3. DROP y recrear submit_guardian_intake_survey
DROP FUNCTION IF EXISTS public.submit_guardian_intake_survey();

CREATE OR REPLACE FUNCTION public.submit_guardian_intake_survey()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_guardian_id uuid;
  v_year int := current_academic_year();
  v_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN 
    RAISE EXCEPTION 'Not authenticated'; 
  END IF;
  
  SELECT id INTO v_guardian_id 
  FROM public.guardians 
  WHERE owner_id = v_user 
  LIMIT 1;
  
  IF v_guardian_id IS NULL THEN 
    RAISE EXCEPTION 'Guardian record not found'; 
  END IF;
  
  SELECT * INTO v_row 
  FROM public.guardian_intake_surveys 
  WHERE guardian_id = v_guardian_id AND year = v_year;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No draft survey found';
  END IF;
  
  IF v_row.status = 'submitted' THEN
    RETURN jsonb_build_object('status','already_submitted','id', v_row.id);
  END IF;
  
  -- Validación mínima
  IF v_row.guardian_rut IS NULL OR v_row.guardian_rut = '' THEN
    RAISE EXCEPTION 'Guardian RUT is required';
  END IF;
  
  IF v_row.student_run IS NULL OR v_row.student_run = '' THEN
    RAISE EXCEPTION 'Student RUN is required';
  END IF;
  
  UPDATE public.guardian_intake_surveys
    SET status='submitted', submitted_at=now()
  WHERE id = v_row.id
  RETURNING * INTO v_row;
  
  RETURN jsonb_build_object('status','submitted','id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.submit_guardian_intake_survey() IS 'Submits and locks the current year guardian survey.';

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================
-- Verifica que las funciones se recrearon correctamente
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('upsert_guardian_intake_survey', 'submit_guardian_intake_survey', 'current_academic_year');

-- Deberías ver las 3 funciones listadas
