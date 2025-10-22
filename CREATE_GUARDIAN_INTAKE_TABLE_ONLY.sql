-- ============================================================================
-- CREAR SOLO LA TABLA guardian_intake_surveys
-- Las funciones upsert_guardian_intake_survey y submit_guardian_intake_survey 
-- ya existen en tu base de datos
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

-- 6. Función helper: current_academic_year (si no existe)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'current_academic_year'
  ) THEN
    CREATE OR REPLACE FUNCTION public.current_academic_year()
    RETURNS int LANGUAGE sql IMMUTABLE AS $func$
      SELECT date_part('year', now())::int;
    $func$;
  END IF;
END;$$;

-- ============================================================================
-- VERIFICACIÓN FINAL
-- ============================================================================
-- Ejecuta esto después para confirmar que la tabla fue creada:
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'guardian_intake_surveys';

-- Verificar columnas
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'guardian_intake_surveys'
ORDER BY ordinal_position;

-- Verificar políticas RLS
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'guardian_intake_surveys';
