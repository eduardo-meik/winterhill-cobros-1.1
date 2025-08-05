-- 1. Create handle_new_user function and trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, created_at)
  VALUES (new.id, new.email, now());
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. Add RLS policies for cursos table
ALTER TABLE public.cursos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage cursos" ON public.cursos
  FOR ALL USING (get_current_user_role() = 'ADMIN'::text)
  WITH CHECK (get_current_user_role() = 'ADMIN'::text);

CREATE POLICY "All authenticated users can read cursos" ON public.cursos
  FOR SELECT USING (auth.role() = 'authenticated');

-- 3. Refactor existing policies to be more consistent
-- For example, refactor policies on the 'guardians' table
DROP POLICY "Users can delete their own guardians" ON public.guardians;
DROP POLICY "Users can insert their own guardians" ON public.guardians;
DROP POLICY "Users can update their own guardians" ON public.guardians;
DROP POLICY "Users can view their own guardians" ON public.guardians;

CREATE POLICY "Guardians can manage their own data" ON public.guardians
  FOR ALL USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Apply similar refactoring to other tables as needed...
-- (I will add more refactoring for other tables in the new policies.json)
