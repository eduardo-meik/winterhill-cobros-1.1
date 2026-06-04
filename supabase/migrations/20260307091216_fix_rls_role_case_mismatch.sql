-- Fix critical RLS case mismatch: functions returned UPPER(role) while
-- all policies compare with lowercase role values ('admin', 'asist', 'guardian').
-- This broke data access for ALL staff users.

-- 1. get_current_user_role() - UPPER → LOWER  (used by 10 RLS policies)
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT LOWER(role) FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

-- 2. es_admin_o_equipo(uuid) - uppercase + wrong role names → lowercase correct roles
CREATE OR REPLACE FUNCTION public.es_admin_o_equipo(user_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role text;
BEGIN
    SELECT role INTO user_role
    FROM profiles
    WHERE id = user_uuid;

    RETURN user_role IN ('admin', 'asist');
END;
$$;

-- 3. es_admin_o_equipo() (no params) - uppercase + wrong role names → lowercase correct roles
CREATE OR REPLACE FUNCTION public.es_admin_o_equipo()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = ANY (ARRAY['admin', 'asist'])
  );
END;
$$;

-- 4. ensure_profile_for_current_user - was writing UPPER roles, now writes lowercase
CREATE OR REPLACE FUNCTION public.ensure_profile_for_current_user(p_role text DEFAULT 'guardian')
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_role text := lower(coalesce(p_role, 'guardian'));
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No auth.uid() in context';
  END IF;
  IF v_role NOT IN ('admin', 'guardian', 'asist') THEN
    v_role := 'guardian';
  END IF;

  INSERT INTO profiles(id, role)
  VALUES (v_uid, v_role)
  ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role
  WHERE profiles.role IS DISTINCT FROM EXCLUDED.role;
END;
$$;
