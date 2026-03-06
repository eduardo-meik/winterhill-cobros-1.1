-- Quick fix for Guardians page not showing data
-- This addresses the immediate RLS issue for the guardians table

-- Enable RLS on guardians table if not already enabled
ALTER TABLE public.guardians ENABLE ROW LEVEL SECURITY;

-- Create basic policy to allow authenticated users to access guardians
-- Drop existing policy if it exists, then create new one
DROP POLICY IF EXISTS "Allow authenticated users full access to guardians" ON public.guardians;

CREATE POLICY "Allow authenticated users full access to guardians" 
ON public.guardians 
FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);

-- Grant table permissions to authenticated users
GRANT ALL ON public.guardians TO authenticated;

-- Verify RLS is enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'guardians';

-- Check if policies exist
SELECT 
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'guardians';

-- Test query (this should work after the fix)
-- SELECT COUNT(*) FROM public.guardians;
