-- ============================================================================
-- FIX DEFINITIVO v2: SIN DEPENDER DE PROFILES
-- ============================================================================
-- SOLUCIÓN: Solo usar auth.users.email, nada más de profiles
-- ============================================================================

DROP POLICY IF EXISTS insert_own_intake ON public.guardian_intake_surveys;
CREATE POLICY insert_own_intake ON public.guardian_intake_surveys FOR INSERT WITH CHECK (guardian_id IN (SELECT g.id FROM public.guardians g WHERE g.owner_id = auth.uid()));

DROP FUNCTION IF EXISTS public.ensure_guardian_for_user();
CREATE OR REPLACE FUNCTION public.ensure_guardian_for_user() RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_guardian_id uuid;
  v_user_email text;
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT id INTO v_guardian_id FROM public.guardians WHERE owner_id = v_user_id LIMIT 1;
  IF v_guardian_id IS NOT NULL THEN RETURN v_guardian_id; END IF;
  SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;
  INSERT INTO public.guardians (owner_id, first_name, last_name, email, relationship_type)
  VALUES (v_user_id, 'Por completar', 'Por completar', COALESCE(v_user_email, ''), 'Tutor')
  RETURNING id INTO v_guardian_id;
  RETURN v_guardian_id;
END; $$;

-- Resto igual...
SELECT 'EJECUTA ESTO COMPLETO EN SUPABASE' as instruccion;
