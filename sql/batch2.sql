-- BATCH 2 (migrations 11 to 20)
-- ######################################################################

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [11/49] MIGRATION: 20250925_guardian_intake_survey
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Guardian Intake Survey (Annual) Migration

-- 1. Table definition
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
  student_course_id uuid REFERENCES public.cursos(id),
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

-- 2. Updated_at trigger (create helper if missing)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'set_updated_at'
  ) THEN
    CREATE OR REPLACE FUNCTION public.set_updated_at()
    RETURNS trigger LANGUAGE plpgsql AS $fn$
    BEGIN
      NEW.updated_at = now();
      RETURN NEW;
    END;
    $fn$;
  END IF;
END;$$;

DROP TRIGGER IF EXISTS trg_guardian_intake_surveys_updated_at ON public.guardian_intake_surveys;
CREATE TRIGGER trg_guardian_intake_surveys_updated_at
BEFORE UPDATE ON public.guardian_intake_surveys
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3. Enable RLS
ALTER TABLE public.guardian_intake_surveys ENABLE ROW LEVEL SECURITY;

-- 4. Policies (idempotent creation pattern via DO block per policy)
DO $$
BEGIN
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

-- 5. Helper: get current academic year (simple)
CREATE OR REPLACE FUNCTION public.current_academic_year()
RETURNS int LANGUAGE sql IMMUTABLE AS $$
  SELECT date_part('year', now())::int;
$$;

-- 6. Upsert function (draft save)
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
    INSERT INTO public.guardian_intake_surveys (
      guardian_id, year,
      guardian_first_name, guardian_last_name_paterno, guardian_last_name_materno, guardian_relationship,
      guardian_rut, guardian_education_level, guardian_address, guardian_commune, guardian_email, guardian_phone,
      student_first_names, student_last_name_paterno, student_last_name_materno, student_run, student_course, student_course_id,
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
      NULLIF(payload->>'student_course_id','')::uuid,
      (payload->>'student_birth_date')::date, payload->>'student_nationality', payload->>'student_gender', payload->>'student_social_name', (payload->>'student_enrollment_date')::date,
      (payload->>'student_withdrawal_date')::date, payload->>'student_withdrawal_reason', (payload->>'student_repeat_current')::boolean, payload->>'student_previous_institution',
      payload->>'student_address', payload->>'student_commune', string_to_array(COALESCE(payload->>'student_lives_with',''), '|')::text[], payload->>'alt_contact_name', payload->>'alt_contact_phone',
      (payload->>'scholarship_percentage')::numeric, (payload->>'payment_form_prioritario')::boolean, (payload->>'payment_form_cheques')::boolean, (payload->>'payment_form_pagare')::boolean,
      (payload->>'payment_form_credit_card')::boolean, (payload->>'payment_form_transfer')::boolean, (payload->>'payment_form_planilla')::boolean, payload->>'financial_institution', COALESCE(payload->>'status','draft')
    ) RETURNING * INTO result_row;
  ELSE
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
      student_lives_with = string_to_array(COALESCE(payload->>'student_lives_with',''), '|')::text[],
      alt_contact_name = payload->>'alt_contact_name',
      alt_contact_phone = payload->>'alt_contact_phone',
      scholarship_percentage = (payload->>'scholarship_percentage')::numeric,
      payment_form_prioritario = (payload->>'payment_form_prioritario')::boolean,
      payment_form_cheques = (payload->>'payment_form_cheques')::boolean,
      payment_form_pagare = (payload->>'payment_form_pagare')::boolean,
      payment_form_credit_card = (payload->>'payment_form_credit_card')::boolean,
      payment_form_transfer = (payload->>'payment_form_transfer')::boolean,
      payment_form_planilla = (payload->>'payment_form_planilla')::boolean,
      financial_institution = payload->>'financial_institution',
      status = COALESCE(payload->>'status', status)
    WHERE id = existing_id
    RETURNING * INTO result_row;
  END IF;

  RETURN to_jsonb(result_row);
END;
$$;

COMMENT ON FUNCTION public.upsert_guardian_intake_survey(jsonb) IS 'Creates or updates guardian intake survey draft for current year.';

-- 7. Submit function (locks it)
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
  IF v_user IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT id INTO v_guardian_id FROM public.guardians WHERE owner_id = v_user LIMIT 1;
  IF v_guardian_id IS NULL THEN RAISE EXCEPTION 'Guardian record not found'; END IF;
  SELECT * INTO v_row FROM public.guardian_intake_surveys WHERE guardian_id = v_guardian_id AND year = v_year;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No draft survey found';
  END IF;
  IF v_row.status = 'submitted' THEN
    RETURN jsonb_build_object('status','already_submitted','id', v_row.id);
  END IF;
  -- Minimal validation example (extend as needed)
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


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [12/49] MIGRATION: 20251021_guardian_invite_and_claim
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Guardian Invite & Claim Flow
-- Date: 2025-10-21
-- Purpose: Allow sending a link to guardians so they can create an account, automatically
--          get the guardian role, and be linked to their existing guardian record (owner_id).
-- Safety: idempotent column adds; functions use SECURITY DEFINER and constrained search_path.

BEGIN;

-- 1) Columns on guardians (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='claim_token'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN claim_token text;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='claim_expires_at'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN claim_expires_at timestamptz;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='claimed_at'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN claimed_at timestamptz;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='needs_update'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN needs_update boolean DEFAULT true;
  END IF;
END$$;

-- 1.1) Unique index for claim_token (nullable)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='guardians_claim_token_unique'
  ) THEN
    CREATE UNIQUE INDEX guardians_claim_token_unique ON public.guardians (claim_token) WHERE claim_token IS NOT NULL;
  END IF;
END$$;

-- 2) Ensure pgcrypto for randomness
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 3) Function: create_guardian_invite(guardian_id, expires_in_minutes)
CREATE OR REPLACE FUNCTION public.create_guardian_invite(p_guardian_id uuid, p_expires_in_minutes int DEFAULT 10080)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_token text;
BEGIN
  -- Generate opaque token
  v_token := encode(gen_random_bytes(24), 'hex');

  UPDATE public.guardians
  SET claim_token = v_token,
      claim_expires_at = now() + make_interval(mins => COALESCE(p_expires_in_minutes, 10080)),
      updated_at = now()
  WHERE id = p_guardian_id;

  RETURN v_token;
END;
$$;

COMMENT ON FUNCTION public.create_guardian_invite(uuid, int) IS 'Generates a one-time claim token for a guardian; default expiry 7 days.';

-- 4) Function: accept_guardian_invite(token)
CREATE OR REPLACE FUNCTION public.accept_guardian_invite(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_row guardians%ROWTYPE;
  v_role text;
BEGIN
  IF v_user IS NULL THEN
    RETURN jsonb_build_object('status','not_authenticated');
  END IF;

  SELECT * INTO v_row FROM public.guardians WHERE claim_token = p_token LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','invalid_token');
  END IF;

  IF v_row.claim_expires_at IS NOT NULL AND v_row.claim_expires_at < now() THEN
    RETURN jsonb_build_object('status','expired');
  END IF;

  IF v_row.owner_id IS NOT NULL THEN
    IF v_row.owner_id = v_user THEN
      RETURN jsonb_build_object('status','already_linked','guardian_id', v_row.id);
    ELSE
      RETURN jsonb_build_object('status','claimed_by_other');
    END IF;
  END IF;

  -- Assign ownership and finalize claim
  UPDATE public.guardians
    SET owner_id = v_user,
        claimed_at = now(),
        claim_token = NULL,
        claim_expires_at = NULL,
        updated_at = now()
  WHERE id = v_row.id;

  -- Set profile role if empty
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='profiles') THEN
    SELECT role INTO v_role FROM public.profiles WHERE id = v_user;
    IF v_role IS NULL OR v_role = '' THEN
      UPDATE public.profiles SET role = 'guardian', updated_at = now() WHERE id = v_user;
    END IF;
  END IF;

  RETURN jsonb_build_object('status','linked','guardian_id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.accept_guardian_invite(text) IS 'Links the current user to a guardian record using a one-time token and sets profile role if empty.';

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [13/49] MIGRATION: 20251022_fix_guardian_intake_auto_create
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Fix guardian intake survey to auto-create guardian record when missing
-- This prevents 400 errors when accessing the intake page for the first time

-- Drop and recreate upsert_guardian_intake_survey to use ensure_guardian_for_user
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
  
  -- Obtener o crear guardian_id usando ensure_guardian_for_user
  v_guardian_id := ensure_guardian_for_user();
  
  IF v_guardian_id IS NULL THEN
    RAISE EXCEPTION 'Failed to obtain guardian record';
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
      string_to_array(COALESCE(payload->>'student_lives_with',''), '|')::text[], 
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
      student_lives_with = string_to_array(COALESCE(payload->>'student_lives_with',''), '|')::text[],
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

COMMENT ON FUNCTION public.upsert_guardian_intake_survey(jsonb) IS 'Creates or updates guardian intake survey draft, auto-creating guardian if needed.';

-- Also update submit function to use ensure_guardian_for_user
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
  
  -- Obtener o crear guardian_id
  v_guardian_id := ensure_guardian_for_user();
  
  IF v_guardian_id IS NULL THEN
    RAISE EXCEPTION 'Failed to obtain guardian record';
  END IF;

  SELECT * INTO v_row 
  FROM public.guardian_intake_surveys 
  WHERE guardian_id = v_guardian_id AND year = v_year;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No draft survey found';
  END IF;

  IF v_row.status = 'submitted' THEN
    RETURN jsonb_build_object('status', 'already_submitted', 'id', v_row.id);
  END IF;

  -- Validación mínima
  IF v_row.guardian_rut IS NULL OR v_row.student_run IS NULL THEN
    RAISE EXCEPTION 'Required RUN fields missing';
  END IF;

  UPDATE public.guardian_intake_surveys
  SET status = 'submitted', submitted_at = now()
  WHERE id = v_row.id
  RETURNING * INTO v_row;

  RETURN jsonb_build_object('status', 'submitted', 'id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.submit_guardian_intake_survey() IS 'Submits and locks the current year guardian survey, auto-creating guardian if needed.';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [14/49] MIGRATION: 20251023_add_year_to_fee
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add year column to fee table for filtering by academic year
-- This allows querying fees by year without extracting from due_date

ALTER TABLE public.fee 
ADD COLUMN IF NOT EXISTS year integer;

-- Set default year based on due_date for existing records
UPDATE public.fee 
SET year = EXTRACT(YEAR FROM due_date)
WHERE year IS NULL;

-- Add constraint to ensure year is always set
ALTER TABLE public.fee 
ALTER COLUMN year SET NOT NULL;

-- Add check constraint for reasonable year values
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fee_year_valid') THEN
    ALTER TABLE public.fee 
    ADD CONSTRAINT fee_year_valid CHECK (year >= 2020 AND year <= 2100);
  END IF;
END$$;

-- Add index for faster year-based queries
CREATE INDEX IF NOT EXISTS idx_fee_year ON public.fee(year);

-- Add index for combined student + year queries (most common)
CREATE INDEX IF NOT EXISTS idx_fee_student_year ON public.fee(student_id, year);

COMMENT ON COLUMN public.fee.year IS 'Academic year for the fee. Allows efficient filtering without date extraction.';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [15/49] MIGRATION: 20251023_complete_architecture_implementation
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- WINTERHILL SCHOOL MANAGEMENT: ARCHITECTURE IMPLEMENTATION
-- ============================================================================
-- Date: October 23, 2025
-- Purpose: Add academic records tracking and fix fee year column
-- Status: PRODUCTION READY - Execute manually in Supabase SQL Editor
-- 
-- INSTRUCTIONS:
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Copy-paste this ENTIRE file
-- 3. Click "RUN" (executes as transaction, rolls back on error)
-- 4. Verify success message at bottom
-- 5. Test queries provided at end
-- ============================================================================

BEGIN;

-- ============================================================================
-- PHASE 1: EXTEND FEE TABLE WITH YEAR_ACADEMICO
-- ============================================================================
-- Purpose: Allow direct year queries on fees without date extraction
-- Fixes: 400 Bad Request error on GuardianWelcomePage

DO $$
BEGIN
  -- Add column if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fee' 
    AND column_name = 'year_academico'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN year_academico integer;
    RAISE NOTICE 'Column year_academico added to fee table';
  ELSE
    RAISE NOTICE 'Column year_academico already exists in fee table';
  END IF;
END $$;

-- Populate year_academico from existing data
-- Strategy 1: Try to extract from fee_curso → cursos.year_academico
UPDATE public.fee f
SET year_academico = c.year_academico
FROM public.cursos c
WHERE f.fee_curso = c.id
  AND f.year_academico IS NULL;

-- Strategy 2: For fees without fee_curso, use due_date year
UPDATE public.fee
SET year_academico = EXTRACT(YEAR FROM due_date)
WHERE year_academico IS NULL
  AND due_date IS NOT NULL;

-- Strategy 3: For remaining nulls, use current year (safeguard)
UPDATE public.fee
SET year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE year_academico IS NULL;

-- Make NOT NULL after population
ALTER TABLE public.fee 
ALTER COLUMN year_academico SET NOT NULL;

-- Add check constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fee_year_valid'
  ) THEN
    ALTER TABLE public.fee 
    ADD CONSTRAINT fee_year_valid CHECK (year_academico >= 2020 AND year_academico <= 2100);
    RAISE NOTICE 'Constraint fee_year_valid added';
  END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_fee_year_academico 
ON public.fee(year_academico);

CREATE INDEX IF NOT EXISTS idx_fee_student_year 
ON public.fee(student_id, year_academico);

COMMENT ON COLUMN public.fee.year_academico IS 
'Academic year for the fee. Allows efficient filtering without date extraction. Populated from curso.year_academico or extracted from due_date.';

-- ============================================================================
-- PHASE 2: CREATE STUDENT_ACADEMIC_RECORDS TABLE
-- ============================================================================
-- Purpose: Track which course each student was enrolled in each year
-- Preserves academic history without overwriting students.curso

CREATE TABLE IF NOT EXISTS public.student_academic_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Core relationship
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  curso_id uuid NOT NULL REFERENCES public.cursos(id) ON DELETE RESTRICT,
  year_academico integer NOT NULL CHECK (year_academico BETWEEN 2020 AND 2100),
  
  -- Academic period tracking
  fecha_inicio date, -- Will be set by trigger or application code
  fecha_termino date, -- Will be set by trigger or application code
  estado text NOT NULL CHECK (estado IN ('activo','completado','retirado','repitio','trasladado')) DEFAULT 'activo',
  
  -- Academic performance (optional, populated at year end)
  promedio_anual numeric(3,2) CHECK (promedio_anual IS NULL OR promedio_anual BETWEEN 1.0 AND 7.0),
  asistencia_porcentaje numeric(5,2) CHECK (asistencia_porcentaje IS NULL OR asistencia_porcentaje BETWEEN 0 AND 100),
  observaciones text,
  
  -- Link to administrative enrollment process (optional)
  enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL,
  
  -- Audit fields
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  updated_by uuid REFERENCES auth.users(id),
  
  -- Business rules
  UNIQUE(student_id, year_academico) -- One course per student per year
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sar_student 
ON public.student_academic_records(student_id);

CREATE INDEX IF NOT EXISTS idx_sar_year 
ON public.student_academic_records(year_academico);

CREATE INDEX IF NOT EXISTS idx_sar_curso 
ON public.student_academic_records(curso_id);

CREATE INDEX IF NOT EXISTS idx_sar_student_year 
ON public.student_academic_records(student_id, year_academico);

CREATE INDEX IF NOT EXISTS idx_sar_estado 
ON public.student_academic_records(estado) 
WHERE estado = 'activo'; -- Partial index for active students only

-- Comments for documentation
COMMENT ON TABLE public.student_academic_records IS 
'Academic history: tracks which course each student was enrolled in each year. Preserves historical data when student advances to next grade.';

COMMENT ON COLUMN public.student_academic_records.estado IS 
'Academic status: activo (current), completado (finished year), retirado (withdrawn), repitio (repeated year), trasladado (transferred)';

COMMENT ON COLUMN public.student_academic_records.enrollment_id IS 
'Optional link to administrative enrollment process (enrollments table). Links academic record with document signing, fee generation, etc.';

-- ============================================================================
-- PHASE 3: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.student_academic_records ENABLE ROW LEVEL SECURITY;

-- Policy 1: Guardians can read academic records of their students
DROP POLICY IF EXISTS sar_guardian_read ON public.student_academic_records;
CREATE POLICY sar_guardian_read ON public.student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.student_guardian sg
      JOIN public.guardians g ON g.id = sg.guardian_id
      WHERE sg.student_id = student_academic_records.student_id
        AND g.owner_id = auth.uid()
    )
  );

-- Policy 2: Students can read their own academic records (if student portal exists)
DROP POLICY IF EXISTS sar_student_read ON public.student_academic_records;
CREATE POLICY sar_student_read ON public.student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.students s
      WHERE s.id = student_academic_records.student_id
        AND s.owner_id = auth.uid()
    )
  );

-- Policy 3: Admins and teachers can read all records
DROP POLICY IF EXISTS sar_staff_read ON public.student_academic_records;
CREATE POLICY sar_staff_read ON public.student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin', 'teacher', 'director', 'secretary')
    )
  );

-- Policy 4: Only admins and teachers can insert/update/delete
DROP POLICY IF EXISTS sar_staff_write ON public.student_academic_records;
CREATE POLICY sar_staff_write ON public.student_academic_records
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin', 'teacher', 'director')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin', 'teacher', 'director')
    )
  );

-- ============================================================================
-- PHASE 4: TRIGGERS FOR AUTO-MAINTENANCE
-- ============================================================================

-- Trigger 1: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_student_academic_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_sar_updated_at ON public.student_academic_records;
CREATE TRIGGER trigger_sar_updated_at
  BEFORE UPDATE ON public.student_academic_records
  FOR EACH ROW
  EXECUTE FUNCTION update_student_academic_records_updated_at();

-- Trigger 1.5: Auto-set academic year dates
CREATE OR REPLACE FUNCTION set_academic_year_dates()
RETURNS TRIGGER AS $$
BEGIN
  -- Set fecha_inicio if NULL (March 1st of academic year)
  IF NEW.fecha_inicio IS NULL THEN
    NEW.fecha_inicio = make_date(NEW.year_academico, 3, 1);
  END IF;
  
  -- Set fecha_termino if NULL (December 31st of academic year)
  IF NEW.fecha_termino IS NULL THEN
    NEW.fecha_termino = make_date(NEW.year_academico, 12, 31);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_academic_dates ON public.student_academic_records;
CREATE TRIGGER trigger_set_academic_dates
  BEFORE INSERT OR UPDATE ON public.student_academic_records
  FOR EACH ROW
  EXECUTE FUNCTION set_academic_year_dates();

-- Trigger 2: Auto-sync students.curso with current year active record
-- This keeps students.curso as a "current curso" helper field
CREATE OR REPLACE FUNCTION sync_student_current_curso()
RETURNS TRIGGER AS $$
DECLARE
  current_year integer := EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
  -- Only sync if this is current year and active
  IF NEW.year_academico = current_year AND NEW.estado = 'activo' THEN
    UPDATE public.students 
    SET curso = NEW.curso_id,
        updated_at = now()
    WHERE id = NEW.student_id;
    
    RAISE NOTICE 'Synced students.curso for student_id % to curso_id %', NEW.student_id, NEW.curso_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_sync_student_curso ON public.student_academic_records;
CREATE TRIGGER trigger_sync_student_curso
  AFTER INSERT OR UPDATE ON public.student_academic_records
  FOR EACH ROW
  EXECUTE FUNCTION sync_student_current_curso();

-- ============================================================================
-- PHASE 5: EXTEND ENROLLMENT_STUDENTS (OPTIONAL LINK)
-- ============================================================================
-- Adds optional reference from enrollment_students to academic_records
-- This links administrative enrollment process ↔ academic history

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'enrollment_students' 
    AND column_name = 'academic_record_id'
  ) THEN
    ALTER TABLE public.enrollment_students 
    ADD COLUMN academic_record_id uuid REFERENCES public.student_academic_records(id) ON DELETE SET NULL;
    
    RAISE NOTICE 'Column academic_record_id added to enrollment_students';
  ELSE
    RAISE NOTICE 'Column academic_record_id already exists in enrollment_students';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_enrollment_students_academic 
ON public.enrollment_students(academic_record_id);

COMMENT ON COLUMN public.enrollment_students.academic_record_id IS 
'Optional link to student_academic_records. Connects administrative enrollment process with academic course assignment.';

-- ============================================================================
-- PHASE 6: DATA MIGRATION - POPULATE CURRENT YEAR RECORDS
-- ============================================================================
-- Migrates existing students.curso → student_academic_records for current year
-- Only runs if student doesn't already have a record for current year

DO $$
DECLARE
  current_year integer := EXTRACT(YEAR FROM CURRENT_DATE);
  migrated_count integer := 0;
BEGIN
  -- Insert records for students who don't have one for current year
  INSERT INTO public.student_academic_records (
    student_id, 
    curso_id, 
    year_academico, 
    estado,
    fecha_inicio,
    created_by
  )
  SELECT 
    s.id,
    s.curso,
    current_year,
    CASE 
      WHEN UPPER(s.estado_std) = 'ACTIVO' THEN 'activo'
      WHEN s.fecha_retiro IS NOT NULL THEN 'retirado'
      ELSE 'activo' -- Default to active if unclear
    END,
    COALESCE(s.fecha_matricula, make_date(current_year, 3, 1)),
    NULL -- created_by will be NULL for migration
  FROM public.students s
  WHERE s.curso IS NOT NULL
    AND NOT EXISTS (
      -- Don't insert if already has record for current year
      SELECT 1 FROM public.student_academic_records sar
      WHERE sar.student_id = s.id 
        AND sar.year_academico = current_year
    );
  
  GET DIAGNOSTICS migrated_count = ROW_COUNT;
  RAISE NOTICE 'Migrated % student records to student_academic_records for year %', migrated_count, current_year;
END $$;

-- ============================================================================
-- PHASE 7: HELPER VIEWS (OPTIONAL)
-- ============================================================================

-- View 1: Current Active Students with Course
CREATE OR REPLACE VIEW v_current_student_courses AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  s.first_name,
  s.apellido_paterno,
  s.apellido_materno,
  sar.curso_id,
  c.nom_curso,
  c.nivel,
  c.letra_curso,
  c.year_academico,
  sar.estado as enrollment_status,
  sar.promedio_anual,
  sar.asistencia_porcentaje
FROM public.students s
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN public.cursos c ON c.id = sar.curso_id
WHERE UPPER(s.estado_std) = 'ACTIVO' OR s.estado_std IS NULL;

COMMENT ON VIEW v_current_student_courses IS 
'Helper view: Shows all active students with their current year course assignment.';

-- View 2: Student Academic History
CREATE OR REPLACE VIEW v_student_academic_history AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  sar.year_academico,
  c.nom_curso,
  c.nivel,
  sar.estado,
  sar.promedio_anual,
  sar.asistencia_porcentaje,
  sar.observaciones,
  sar.fecha_inicio,
  sar.fecha_termino
FROM public.students s
JOIN public.student_academic_records sar ON sar.student_id = s.id
JOIN public.cursos c ON c.id = sar.curso_id
ORDER BY s.id, sar.year_academico DESC;

COMMENT ON VIEW v_student_academic_history IS 
'Complete academic history: shows all courses a student has been enrolled in across years.';

-- ============================================================================
-- PHASE 8: UTILITY FUNCTIONS
-- ============================================================================

-- Function: Get current academic year (handles Jan-Feb as previous year)
CREATE OR REPLACE FUNCTION current_academic_year()
RETURNS integer AS $$
BEGIN
  -- In Chile, school year starts in March
  -- So January-February still belong to previous academic year
  IF EXTRACT(MONTH FROM CURRENT_DATE) <= 2 THEN
    RETURN EXTRACT(YEAR FROM CURRENT_DATE)::integer - 1;
  ELSE
    RETURN EXTRACT(YEAR FROM CURRENT_DATE)::integer;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION current_academic_year() IS 
'Returns current academic year. Considers Jan-Feb as previous year since school starts in March.';

-- Function: Get student's course for specific year
CREATE OR REPLACE FUNCTION get_student_course(p_student_id uuid, p_year integer)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'student_id', sar.student_id,
    'year', sar.year_academico,
    'curso_id', sar.curso_id,
    'curso_nombre', c.nom_curso,
    'nivel', c.nivel,
    'estado', sar.estado,
    'promedio', sar.promedio_anual,
    'asistencia', sar.asistencia_porcentaje
  ) INTO result
  FROM public.student_academic_records sar
  JOIN public.cursos c ON c.id = sar.curso_id
  WHERE sar.student_id = p_student_id
    AND sar.year_academico = p_year;
  
  RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION get_student_course(uuid, integer) IS 
'Returns course information for a student in a specific year as JSON.';

-- ============================================================================
-- COMMIT TRANSACTION
-- ============================================================================

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES (Run separately to verify success)
-- ============================================================================

-- Check 1: Verify fee.year_academico exists and is populated
SELECT 
  COUNT(*) as total_fees,
  COUNT(year_academico) as with_year,
  MIN(year_academico) as oldest_year,
  MAX(year_academico) as newest_year
FROM public.fee;

-- Check 2: Verify student_academic_records table exists
SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT student_id) as unique_students,
  MIN(year_academico) as oldest_year,
  MAX(year_academico) as newest_year
FROM public.student_academic_records;

-- Check 3: Verify current year students have records
SELECT 
  s.id,
  s.whole_name,
  c.nom_curso as curso_actual,
  sar.year_academico,
  sar.estado
FROM public.students s
LEFT JOIN public.cursos c ON c.id = s.curso
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE s.estado_std = 'activo'
LIMIT 10;

-- Check 4: Verify RLS policies exist
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename IN ('student_academic_records', 'fee')
ORDER BY tablename, policyname;

-- Check 5: Test current_academic_year function
SELECT current_academic_year() as current_year;

-- ============================================================================
-- ROLLBACK SCRIPT (In case of emergency - run separately)
-- ============================================================================
/*
BEGIN;

-- Drop views
DROP VIEW IF EXISTS v_student_academic_history CASCADE;
DROP VIEW IF EXISTS v_current_student_courses CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS get_student_course(uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS current_academic_year() CASCADE;
DROP FUNCTION IF EXISTS sync_student_current_curso() CASCADE;
DROP FUNCTION IF EXISTS set_academic_year_dates() CASCADE;
DROP FUNCTION IF EXISTS update_student_academic_records_updated_at() CASCADE;

-- Drop table
DROP TABLE IF EXISTS public.student_academic_records CASCADE;

-- Remove fee.year_academico
ALTER TABLE public.fee DROP COLUMN IF EXISTS year_academico CASCADE;

-- Remove enrollment_students.academic_record_id
ALTER TABLE public.enrollment_students DROP COLUMN IF EXISTS academic_record_id CASCADE;

COMMIT;

SELECT 'Rollback completed successfully' as status;
*/

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '
  ============================================================================
  ✅ ARCHITECTURE IMPLEMENTATION COMPLETED SUCCESSFULLY
  ============================================================================
  
  Changes Applied:
  ✅ fee.year_academico column added and populated
  ✅ student_academic_records table created
  ✅ RLS policies configured
  ✅ Triggers for auto-sync and audit created
  ✅ Helper views and utility functions created
  ✅ Current year data migrated
  
  Next Steps:
  1. Run VERIFICATION QUERIES above to confirm success
  2. Update frontend code to use new year_academico column
  3. Test Guardian dashboard (should show fee totals correctly)
  4. Begin using student_academic_records for 2026 enrollments
  
  Documentation: See FINAL_ARCHITECTURE_RECOMMENDATION.md
  ============================================================================
  ';
END $$;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [16/49] MIGRATION: 20251027_setup_enrollment_documents_bucket
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- =====================================================
-- MIGRATION: Setup Storage Bucket for Enrollment Documents
-- Date: 2025-10-27
-- Description: Creates bucket and RLS policies for storing
--              generated PDF documents (Pagaré, etc.)
-- =====================================================

-- 1. CREATE STORAGE BUCKET
-- Note: This must be executed in Supabase Dashboard > Storage
-- or via Supabase CLI, not via standard SQL migration
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES (
--   'enrollment-documents',
--   'enrollment-documents',
--   false, -- private bucket
--   10485760, -- 10MB limit
--   ARRAY['application/pdf']
-- );

-- Alternative: Use Supabase Dashboard to create bucket with these settings:
-- Name: enrollment-documents
-- Public: No (private)
-- File size limit: 10 MB
-- Allowed MIME types: application/pdf

-- =====================================================
-- 2. RLS POLICIES FOR STORAGE
-- =====================================================

-- Policy: Allow authenticated users to upload documents
DROP POLICY IF EXISTS "Users can upload enrollment documents" ON storage.objects;
CREATE POLICY "Users can upload enrollment documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'enrollment-documents' 
  AND auth.uid() IS NOT NULL
);

-- Policy: Users can view their own documents (guardians see their enrollments)
DROP POLICY IF EXISTS "Guardians can view their enrollment documents" ON storage.objects;
CREATE POLICY "Guardians can view their enrollment documents"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND (
    -- Admin role can see all
    auth.jwt()->>'role' = 'admin'
    OR
    -- Guardian can see documents from their enrollments
    EXISTS (
      SELECT 1 
      FROM enrollment_documents ed
      JOIN enrollments e ON e.id = ed.enrollment_id
      WHERE ed.storage_path = storage.objects.name
        AND e.guardian_id::text = auth.uid()::text
    )
  )
);

-- Policy: Allow users to update their own documents (regenerate)
DROP POLICY IF EXISTS "Users can update their enrollment documents" ON storage.objects;
CREATE POLICY "Users can update their enrollment documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND (
    auth.jwt()->>'role' = 'admin'
    OR
    EXISTS (
      SELECT 1 
      FROM enrollment_documents ed
      JOIN enrollments e ON e.id = ed.enrollment_id
      WHERE ed.storage_path = storage.objects.name
        AND e.guardian_id::text = auth.uid()::text
    )
  )
);

-- Policy: Only admins can delete documents
DROP POLICY IF EXISTS "Only admins can delete enrollment documents" ON storage.objects;
CREATE POLICY "Only admins can delete enrollment documents"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND auth.jwt()->>'role' = 'admin'
);

-- =====================================================
-- 3. HELPER FUNCTIONS
-- =====================================================

-- Function: Get signed URL for document (valid for 1 hour)
CREATE OR REPLACE FUNCTION get_enrollment_document_url(document_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  storage_path_val TEXT;
  signed_url TEXT;
BEGIN
  -- Get storage path
  SELECT storage_path INTO storage_path_val
  FROM enrollment_documents
  WHERE id = document_id;
  
  IF storage_path_val IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Generate signed URL (valid for 1 hour)
  -- Note: This requires Supabase Storage API
  -- In practice, this is handled by the frontend using supabase.storage.from().createSignedUrl()
  RETURN storage_path_val;
END;
$$;

-- =====================================================
-- 4. VERIFICATION QUERIES
-- =====================================================

-- Verify bucket exists
-- SELECT * FROM storage.buckets WHERE id = 'enrollment-documents';

-- Verify policies
-- SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%enrollment%';

-- Test document count
-- SELECT COUNT(*) FROM enrollment_documents WHERE pdf_url IS NOT NULL;

-- =====================================================
-- MANUAL STEPS REQUIRED:
-- =====================================================
-- 1. Go to Supabase Dashboard > Storage
-- 2. Click "Create new bucket"
-- 3. Name: enrollment-documents
-- 4. Public: OFF (private bucket)
-- 5. File size limit: 10 MB
-- 6. Allowed MIME types: application/pdf
-- 7. Click "Create bucket"
-- 8. Run this migration to set up RLS policies
-- =====================================================


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [17/49] MIGRATION: 20251030_enrollment_assisted_mode_policies
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Assisted mode RLS policies to allow ADMIN and ASIST to manage enrollments and enrollment_students
-- Safe to run multiple times; policies are dropped/created idempotently.

-- Enrollments: allow ADMIN/ASIST full access
DROP POLICY IF EXISTS enrollments_admin_asist_access ON public.enrollments;
CREATE POLICY enrollments_admin_asist_access ON public.enrollments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  );

-- Enrollment students: allow ADMIN/ASIST full access
DROP POLICY IF EXISTS enrollment_students_admin_asist_access ON public.enrollment_students;
CREATE POLICY enrollment_students_admin_asist_access ON public.enrollment_students
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  );

-- Enrollment documents: allow ADMIN/ASIST full access (needed to manage pagaré records when assisting)
DROP POLICY IF EXISTS enrollment_documents_admin_asist_access ON public.enrollment_documents;
CREATE POLICY enrollment_documents_admin_asist_access ON public.enrollment_documents
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  );


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [18/49] MIGRATION: 20251031_email_logs
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Create table to audit outbound emails (receipts, pagarés, etc.)
-- Simplicity-first: minimal fields, robust constraints, and RLS for read access.

-- Ensure pgcrypto for gen_random_uuid
create extension if not exists pgcrypto with schema public;

create table if not exists public.email_logs (
  id uuid primary key default gen_random_uuid(),
  type text not null default 'other',
  to_email text not null,
  related_id uuid null,
  user_id uuid null, -- who triggered the send (auth.uid())
  provider_message_id text null, -- provider-specific id
  status text not null default 'queued',
  error text null,
  created_at timestamptz not null default now(),
  constraint email_logs_status_check check (status in ('queued','sent','failed')),
  constraint email_logs_type_check check (type in ('receipt','pagare','other')),
  constraint email_logs_email_check check (to_email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$')
);

comment on table public.email_logs is 'Audit log of outbound emails (receipts, pagaré, etc.)';
comment on column public.email_logs.type is 'receipt | pagare | other';

create index if not exists email_logs_related_id_idx on public.email_logs(related_id);
create index if not exists email_logs_to_email_idx on public.email_logs(to_email);
create index if not exists email_logs_created_at_idx on public.email_logs(created_at desc);

alter table public.email_logs enable row level security;

-- Allow ADMIN and ASIST to read logs; inserts are performed by service role (bypasses RLS)
DROP POLICY IF EXISTS email_logs_select_admin_asist ON public.email_logs;
create policy email_logs_select_admin_asist on public.email_logs
for select to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and lower(p.role) in ('admin','asist')
  )
);


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [19/49] MIGRATION: 20251101_create_cheques_table
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Create cheques table for managing check payment details
-- Created: 2025-11-01
-- Purpose: Store check information when "Cheque" payment method is selected during enrollment

-- Create cheques table
CREATE TABLE IF NOT EXISTS public.cheques (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Link to enrollment
  enrollment_id UUID NOT NULL REFERENCES public.enrollments(id) ON DELETE CASCADE,
  
  -- Check details
  numero_serie VARCHAR(100) NOT NULL, -- Check series number
  banco VARCHAR(200) NOT NULL, -- Bank name
  fecha_emision DATE NOT NULL, -- Issue date
  monto NUMERIC(12,2) NOT NULL CHECK (monto > 0), -- Amount
  
  -- Status tracking
  estado VARCHAR(50) NOT NULL DEFAULT 'pendiente' 
    CHECK (estado IN ('pendiente', 'cobrado', 'rechazado', 'anulado')),
  
  -- Additional info
  notas TEXT, -- Optional notes
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_cheques_enrollment_id ON public.cheques(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_cheques_estado ON public.cheques(estado);
CREATE INDEX IF NOT EXISTS idx_cheques_fecha_emision ON public.cheques(fecha_emision);

-- Add RLS policies
ALTER TABLE public.cheques ENABLE ROW LEVEL SECURITY;

-- ADMIN and ASIST can see all checks
DROP POLICY IF EXISTS "ADMIN and ASIST can view all cheques" ON public.cheques;
CREATE POLICY "ADMIN and ASIST can view all cheques"
  ON public.cheques
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ADMIN', 'ASIST')
    )
  );

-- ADMIN and ASIST can insert checks
DROP POLICY IF EXISTS "ADMIN and ASIST can insert cheques" ON public.cheques;
CREATE POLICY "ADMIN and ASIST can insert cheques"
  ON public.cheques
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ADMIN', 'ASIST')
    )
  );

-- ADMIN and ASIST can update checks
DROP POLICY IF EXISTS "ADMIN and ASIST can update cheques" ON public.cheques;
CREATE POLICY "ADMIN and ASIST can update cheques"
  ON public.cheques
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ADMIN', 'ASIST')
    )
  );

-- Guardians can view their own checks
DROP POLICY IF EXISTS "Guardians can view their own cheques" ON public.cheques;
CREATE POLICY "Guardians can view their own cheques"
  ON public.cheques
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.enrollments
      JOIN public.guardians ON enrollments.guardian_id = guardians.id
      WHERE enrollments.id = cheques.enrollment_id
      AND guardians.owner_id = auth.uid()
    )
  );

-- Guardians can insert checks for their own enrollments
DROP POLICY IF EXISTS "Guardians can insert cheques for own enrollments" ON public.cheques;
CREATE POLICY "Guardians can insert cheques for own enrollments"
  ON public.cheques
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.enrollments
      JOIN public.guardians ON enrollments.guardian_id = guardians.id
      WHERE enrollments.id = enrollment_id
      AND guardians.owner_id = auth.uid()
    )
  );

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cheques_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_cheques_timestamp ON public.cheques;
CREATE TRIGGER trigger_update_cheques_timestamp
  BEFORE UPDATE ON public.cheques
  FOR EACH ROW
  EXECUTE FUNCTION update_cheques_updated_at();

-- Add comment to table
COMMENT ON TABLE public.cheques IS 'Stores check payment details for enrollments';
COMMENT ON COLUMN public.cheques.numero_serie IS 'Check series/number';
COMMENT ON COLUMN public.cheques.banco IS 'Bank name that issued the check';
COMMENT ON COLUMN public.cheques.fecha_emision IS 'Check issue date';
COMMENT ON COLUMN public.cheques.monto IS 'Check amount in CLP';
COMMENT ON COLUMN public.cheques.estado IS 'Check status: pendiente, cobrado, rechazado, anulado';




-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [20/49] MIGRATION: 20251103_alter_cheques_add_document_link
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add document link fields to cheques to associate with Pagaré folio
-- Date: 2025-11-03

BEGIN;

-- Add columns if not exists
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS document_id uuid REFERENCES public.enrollment_documents(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS folio_number text;

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_cheques_document_id ON public.cheques(document_id);
CREATE INDEX IF NOT EXISTS idx_cheques_folio_number ON public.cheques(folio_number);

COMMIT;



-- ######################################################################
