-- Fix cheques RLS policies to use correct profiles columns
-- Date: 2025-11-03
-- Reason: ERROR 42703: column profiles.user_id does not exist. Schema uses profiles.id and profiles.role.

DO $$
BEGIN
  -- Ensure table exists before altering policies
  IF to_regclass('public.cheques') IS NULL THEN
    RAISE EXCEPTION 'Table public.cheques does not exist. Run 20251101_create_cheques_table.sql first.';
  END IF;

  -- Drop old policies that reference profiles.user_id and profiles.profile
  EXECUTE 'DROP POLICY IF EXISTS "ADMIN and ASIST can view all cheques" ON public.cheques';
  EXECUTE 'DROP POLICY IF EXISTS "ADMIN and ASIST can insert cheques" ON public.cheques';
  EXECUTE 'DROP POLICY IF EXISTS "ADMIN and ASIST can update cheques" ON public.cheques';

  -- Re-create policies using profiles.id and profiles.role
  EXECUTE 'CREATE POLICY "ADMIN and ASIST can view all cheques"
    ON public.cheques
    FOR SELECT
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.role IN (''ADMIN'', ''ASIST'')
      )
    )';

  EXECUTE 'CREATE POLICY "ADMIN and ASIST can insert cheques"
    ON public.cheques
    FOR INSERT
    TO authenticated
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.role IN (''ADMIN'', ''ASIST'')
      )
    )';

  EXECUTE 'CREATE POLICY "ADMIN and ASIST can update cheques"
    ON public.cheques
    FOR UPDATE
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.role IN (''ADMIN'', ''ASIST'')
      )
    )';

END $$ LANGUAGE plpgsql;

-- Verification (optional):
-- SELECT polname, cmd, roles, qual, with_check FROM pg_policies WHERE schemaname='public' AND tablename='cheques';
