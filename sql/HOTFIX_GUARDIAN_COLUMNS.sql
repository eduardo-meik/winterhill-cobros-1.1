-- ============================================================================
-- CORRECCIÓN RÁPIDA: Actualizar ensure_guardian_for_user con columnas correctas
-- ============================================================================
-- La tabla guardians usa first_name, last_name, phone, NO nombres, apellidos, telefono
-- La tabla profiles puede no tener "rut", solo usar lo que exista
-- ============================================================================

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
  v_profile record;
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

  -- No existe, crear uno nuevo con datos del perfil si están disponibles
  SELECT * INTO v_profile
  FROM public.profiles
  WHERE id = v_user_id
  LIMIT 1;

  -- Insertar con valores seguros (sin asumir que profiles.rut existe)
  INSERT INTO public.guardians (
    owner_id,
    first_name,
    last_name,
    email,
    phone,
    address,
    relationship_type
  ) VALUES (
    v_user_id,
    COALESCE(v_profile.first_name, 'Sin nombre'),
    COALESCE(v_profile.last_name, 'Sin apellido'),
    v_profile.email,
    v_profile.phone,
    v_profile.address,
    'Tutor'
  )
  RETURNING id INTO v_guardian_id;

  RETURN v_guardian_id;
END;
$$;

COMMENT ON FUNCTION public.ensure_guardian_for_user() IS 'Auto-creates guardian record for authenticated user if not exists - CORRECTED COLUMNS';

-- Verificar que se creó correctamente
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'ensure_guardian_for_user';
