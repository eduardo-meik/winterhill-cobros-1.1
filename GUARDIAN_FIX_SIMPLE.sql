-- ============================================================================
-- SOLUCIÓN SIMPLIFICADA: Guardian Auto-Create SIN profiles
-- ============================================================================
-- ✅ NO depende de profiles en absoluto
-- ✅ Solo usa auth.users.email
-- ✅ Todo lo demás viene del formulario de intake
-- ============================================================================

-- 1. Política RLS
DROP POLICY IF EXISTS insert_own_intake ON public.guardian_intake_surveys;
CREATE POLICY insert_own_intake ON public.guardian_intake_surveys 
FOR INSERT WITH CHECK (
  guardian_id IN (SELECT g.id FROM public.guardians g WHERE g.owner_id = auth.uid())
);

-- 2. Función simplificada
DROP FUNCTION IF EXISTS public.ensure_guardian_for_user();

CREATE OR REPLACE FUNCTION public.ensure_guardian_for_user()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_guardian_id uuid;
  v_email text;
  v_temp_run text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Buscar guardian existente
  SELECT id INTO v_guardian_id
  FROM public.guardians
  WHERE owner_id = v_user_id
  LIMIT 1;

  IF v_guardian_id IS NOT NULL THEN
    RETURN v_guardian_id;
  END IF;

  -- Obtener email de auth.users (única dependencia externa)
  SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;

  -- Generar RUN temporal único (formato K + dígitos) para cumplir constraints y permitir edición posterior
  v_temp_run := 'K'
    || to_char(floor(extract(epoch FROM clock_timestamp()) * 1000)::bigint, 'FM000000000000000')
    || lpad(trunc(random() * 1000)::int::text, 3, '0');

  -- Crear guardian mínimo
  INSERT INTO public.guardians (
    owner_id,
    first_name,
    last_name,
    run,
    email,
    relationship_type
  ) VALUES (
    v_user_id,
    'Por completar',
    'Por completar',
    v_temp_run,
    COALESCE(v_email, ''),
    'Tutor'
  )
  RETURNING id INTO v_guardian_id;

  RETURN v_guardian_id;
END;
$$;

COMMENT ON FUNCTION public.ensure_guardian_for_user() IS 
'Creates minimal guardian record. All real data comes from intake form.';

-- 3. Verificar
SELECT 'SUCCESS - Function created' as status;
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_name = 'ensure_guardian_for_user';
