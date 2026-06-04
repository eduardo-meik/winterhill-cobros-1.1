-- ============================================================================
-- CREAR TABLA guardian_intake_surveys Y FUNCIONES
-- Ejecuta este script completo en Supabase SQL Editor
-- ============================================================================

-- 1. Crear tabla guardian_intake_surveys
CREATE TABLE IF NOT EXISTS public.guardian_intake_surveys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_id uuid NOT NULL REFERENCES public.guardians(id) ON DELETE CASCADE,
  year int NOT NULL,
  -- Guardian fields
  guardian_first_name text,
  guardian_last_name_paterno text,
  guardian_last_name_materno text,
  guardian_relationship text,
  guardian_rut text,
  guardian_education_level text,
  guardian_address text,
  guardian_commune text,
  guardian_email text,
  guardian_phone text,
  -- Student fields
  student_first_names text,
  student_last_name_paterno text,
  student_last_name_materno text,
  student_run text,
  student_course text,
  student_birth_date date,
  student_nationality text,
  student_gender text,
  student_social_name text,
  student_enrollment_date date,
  student_withdrawal_date date,
  student_withdrawal_reason text,
  student_repeat_current boolean,
  student_previous_institution text,
  student_address text,
  student_commune text,
  student_lives_with text[],
  alt_contact_name text,
  alt_contact_phone text,
  scholarship_percentage numeric(5,2),
  payment_form_prioritario boolean DEFAULT false,
  payment_form_cheques boolean DEFAULT false,
  payment_form_pagare boolean DEFAULT false,
  payment_form_credit_card boolean DEFAULT false,
  payment_form_transfer boolean DEFAULT false,
  payment_form_planilla boolean DEFAULT false,
  financial_institution text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted')),
  submitted_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (guardian_id, year)
);

-- 2. Crear función set_updated_at si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'set_updated_at'
  ) THEN
    CREATE OR REPLACE FUNCTION public.set_updated_at()
    RETURNS trigger LANGUAGE plpgsql AS $func$
    BEGIN
      NEW.updated_at = now();
      RETURN NEW;
    END; $func$;
  END IF;
END;$$;

-- 3. Crear trigger para updated_at
DROP TRIGGER IF EXISTS trg_guardian_intake_surveys_updated_at ON public.guardian_intake_surveys;
CREATE TRIGGER trg_guardian_intake_surveys_updated_at
BEFORE UPDATE ON public.guardian_intake_surveys
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 4. Habilitar RLS
ALTER TABLE public.guardian_intake_surveys ENABLE ROW LEVEL SECURITY;

-- 5. Crear políticas RLS
DO $$
BEGIN
  -- Política SELECT
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='guardian_intake_surveys' AND policyname='select_own_intake'
  ) THEN
    CREATE POLICY select_own_intake ON public.guardian_intake_surveys
      FOR SELECT USING (
        guardian_id IN (
          SELECT g.id FROM public.guardians g WHERE g.owner_id = auth.uid()
        )
      );
  END IF;
  
  -- Política INSERT
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='guardian_intake_surveys' AND policyname='insert_own_intake'
  ) THEN
    CREATE POLICY insert_own_intake ON public.guardian_intake_surveys
      FOR INSERT WITH CHECK (
        guardian_id IN (
          SELECT g.id FROM public.guardians g WHERE g.owner_id = auth.uid()
        )
      );
  END IF;
  
  -- Política UPDATE
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='guardian_intake_surveys' AND policyname='update_own_intake'
  ) THEN
    CREATE POLICY update_own_intake ON public.guardian_intake_surveys
      FOR UPDATE USING (
        guardian_id IN (
          SELECT g.id FROM public.guardians g WHERE g.owner_id = auth.uid()
        )
      );
  END IF;
END;$$;

-- 6. Función helper: current_academic_year
CREATE OR REPLACE FUNCTION public.current_academic_year()
RETURNS int LANGUAGE sql IMMUTABLE AS $$
  SELECT date_part('year', now())::int;
$$;

-- 7. Función upsert_guardian_intake_survey (guardar borrador)
CREATE OR REPLACE FUNCTION public.upsert_guardian_intake_survey(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_guardian_id uuid;
  v_year int := COALESCE((payload->>'year')::int, current_academic_year());
  existing_id uuid;
  result_row guardian_intake_surveys%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  SELECT id INTO v_guardian_id FROM public.guardians WHERE owner_id = v_user LIMIT 1;
  IF v_guardian_id IS NULL THEN
    RAISE EXCEPTION 'Guardian record not found for user';
  END IF;

  SELECT id INTO existing_id FROM public.guardian_intake_surveys WHERE guardian_id = v_guardian_id AND year = v_year;

  IF existing_id IS NULL THEN
    -- INSERT nuevo registro
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
      v_guardian_id, v_year,
      payload->>'guardian_first_name', payload->>'guardian_last_name_paterno', payload->>'guardian_last_name_materno', payload->>'guardian_relationship',
      payload->>'guardian_rut', payload->>'guardian_education_level', payload->>'guardian_address', payload->>'guardian_commune', payload->>'guardian_email', payload->>'guardian_phone',
      payload->>'student_first_names', payload->>'student_last_name_paterno', payload->>'student_last_name_materno', payload->>'student_run', payload->>'student_course',
      (payload->>'student_birth_date')::date, payload->>'student_nationality', payload->>'student_gender', payload->>'student_social_name', (payload->>'student_enrollment_date')::date,
      (payload->>'student_withdrawal_date')::date, payload->>'student_withdrawal_reason', (payload->>'student_repeat_current')::boolean, payload->>'student_previous_institution',
      payload->>'student_address', payload->>'student_commune', 
      CASE WHEN payload->>'student_lives_with' IS NOT NULL THEN string_to_array(payload->>'student_lives_with', '|')::text[] ELSE ARRAY[]::text[] END,
      payload->>'alt_contact_name', payload->>'alt_contact_phone',
      (payload->>'scholarship_percentage')::numeric, 
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
      student_birth_date = (payload->>'student_birth_date')::date,
      student_nationality = payload->>'student_nationality',
      student_gender = payload->>'student_gender',
      student_social_name = payload->>'student_social_name',
      student_enrollment_date = (payload->>'student_enrollment_date')::date,
      student_withdrawal_date = (payload->>'student_withdrawal_date')::date,
      student_withdrawal_reason = payload->>'student_withdrawal_reason',
      student_repeat_current = (payload->>'student_repeat_current')::boolean,
      student_previous_institution = payload->>'student_previous_institution',
      student_address = payload->>'student_address',
      student_commune = payload->>'student_commune',
      student_lives_with = CASE WHEN payload->>'student_lives_with' IS NOT NULL THEN string_to_array(payload->>'student_lives_with', '|')::text[] ELSE student_lives_with END,
      alt_contact_name = payload->>'alt_contact_name',
      alt_contact_phone = payload->>'alt_contact_phone',
      scholarship_percentage = (payload->>'scholarship_percentage')::numeric,
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

-- 8. Función submit_guardian_intake_survey (enviar y bloquear)
CREATE OR REPLACE FUNCTION public.submit_guardian_intake_survey()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_guardian_id uuid;
  v_year int := current_academic_year();
  v_row guardian_intake_surveys%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN 
    RAISE EXCEPTION 'Not authenticated'; 
  END IF;
  
  SELECT id INTO v_guardian_id FROM public.guardians WHERE owner_id = v_user LIMIT 1;
  IF v_guardian_id IS NULL THEN 
    RAISE EXCEPTION 'Guardian record not found'; 
  END IF;
  
  SELECT * INTO v_row FROM public.guardian_intake_surveys WHERE guardian_id = v_guardian_id AND year = v_year;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No draft survey found';
  END IF;
  
  IF v_row.status = 'submitted' THEN
    RETURN jsonb_build_object('status','already_submitted','id', v_row.id);
  END IF;
  
  -- Validación mínima (puedes agregar más)
  IF v_row.guardian_rut IS NULL OR v_row.student_run IS NULL THEN
    RAISE EXCEPTION 'Required RUN fields missing';
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
-- VERIFICACIÓN FINAL
-- ============================================================================
-- Ejecuta esto después para confirmar que la tabla fue creada:
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'guardian_intake_surveys';

-- Deberías ver: guardian_intake_surveys
