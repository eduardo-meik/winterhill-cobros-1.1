-- Migration: ensure_profile_for_current_user RPC
-- Description: Adds a SECURITY DEFINER function to upsert the caller's profile with a given role (default GUARDIAN) without causing RLS recursion.
-- NOTE: Adjust role validation if you later add more roles.

begin;

-- Optional: create enum for roles if not exists (safe guard)
-- DO NOT fail if enum already exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
    CREATE TYPE app_role AS ENUM ('ADMIN','GUARDIAN');
  END IF;
END;$$;

-- Ensure profiles.role is compatible (if column exists but not enum you can ALTER later manually)
-- This block is safe if already correct.
-- ALTER TABLE profiles ALTER COLUMN role TYPE app_role USING role::app_role; -- Uncomment if you adopt enum fully.

create or replace function ensure_profile_for_current_user(p_role text default 'GUARDIAN')
returns void
language plpgsql
security definer
set search_path = public
as $$
DECLARE
  v_uid uuid := auth.uid();
  v_role text := upper(coalesce(p_role,'GUARDIAN'));
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No auth.uid() in context';
  END IF;
  -- Basic validation of role
  IF v_role NOT IN ('ADMIN','GUARDIAN') THEN
    v_role := 'GUARDIAN';
  END IF;

  -- Upsert without reading profiles first (avoids recursion)
  INSERT INTO profiles(id, role)
  VALUES (v_uid, v_role)
  ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role
  WHERE profiles.role IS DISTINCT FROM EXCLUDED.role; -- update only if changed
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION ensure_profile_for_current_user(text) TO authenticated; 

commit;