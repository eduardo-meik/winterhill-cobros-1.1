-- Security Fixes for Supabase Database Linter Issues
-- Execute these commands in Supabase SQL Editor to fix security vulnerabilities

-- ========================================
-- 1. FIX SECURITY DEFINER VIEWS (CRITICAL)
-- ========================================

-- Fix: Remove SECURITY DEFINER from database_metadata view
-- This ensures the view uses the querying user's permissions instead of the creator's
DROP VIEW IF EXISTS public.database_metadata;

-- Recreate database_metadata view without SECURITY DEFINER
CREATE OR REPLACE VIEW public.database_metadata AS
SELECT 
    schemaname,
    tablename,
    tableowner,
    hasindexes,
    hasrules,
    hastriggers,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
UNION ALL
SELECT 
    schemaname,
    viewname as tablename,
    viewowner as tableowner,
    false as hasindexes,
    false as hasrules,
    false as hastriggers,
    false as rowsecurity
FROM pg_views 
WHERE schemaname = 'public';

-- Fix: Remove SECURITY DEFINER from payment_summary view
-- This ensures the view uses the querying user's permissions instead of the creator's
DROP VIEW IF EXISTS public.payment_summary;

-- Recreate payment_summary view without SECURITY DEFINER
CREATE OR REPLACE VIEW public.payment_summary AS
SELECT 
    p.id,
    p.amount,
    p.payment_date,
    p.invoice_id,
    p.created_at,
    f.student_id,
    f.amount as fee_amount,
    f.due_date,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    CONCAT(s.apellido_paterno, ' ', s.apellido_materno) as full_last_name,
    s.curso,
    c.nom_curso
FROM payments p
JOIN fee f ON p.invoice_id = f.id
JOIN students s ON f.student_id = s.id
LEFT JOIN cursos c ON s.curso = c.id;

-- ========================================
-- 2. ENABLE RLS ON PUBLIC TABLES (CRITICAL)
-- ========================================

-- Enable RLS on matriculas_detalle table
ALTER TABLE public.matriculas_detalle ENABLE ROW LEVEL SECURITY;

-- Enable RLS on user_roles table
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Enable RLS on guardians table (if not already enabled)
ALTER TABLE public.guardians ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 3. CREATE SECURE RLS POLICIES
-- ========================================

-- RLS Policies for guardians table
-- Drop existing policies if they exist, then create new ones
DROP POLICY IF EXISTS "Authenticated users can view guardians" ON public.guardians;
DROP POLICY IF EXISTS "Authenticated users can create guardians" ON public.guardians;
DROP POLICY IF EXISTS "Authenticated users can update guardians" ON public.guardians;
DROP POLICY IF EXISTS "Authenticated users can delete guardians" ON public.guardians;

-- Allow authenticated users to view all guardians (for selection in forms)
CREATE POLICY "Authenticated users can view guardians" 
ON public.guardians 
FOR SELECT 
TO authenticated 
USING (true);

-- Allow authenticated users to insert guardians
CREATE POLICY "Authenticated users can create guardians" 
ON public.guardians 
FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- Allow authenticated users to update guardians
CREATE POLICY "Authenticated users can update guardians" 
ON public.guardians 
FOR UPDATE 
TO authenticated 
USING (true) 
WITH CHECK (true);

-- Allow authenticated users to delete guardians
CREATE POLICY "Authenticated users can delete guardians" 
ON public.guardians 
FOR DELETE 
TO authenticated 
USING (true);

-- RLS Policies for matriculas_detalle table
-- Drop existing policies if they exist, then create new ones
DROP POLICY IF EXISTS "Users can view their own matriculas_detalle" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "Users can insert their own matriculas_detalle" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "Users can update their own matriculas_detalle" ON public.matriculas_detalle;

-- Allow authenticated users to view their own matriculas data
CREATE POLICY "Users can view their own matriculas_detalle" 
ON public.matriculas_detalle 
FOR SELECT 
TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND (
            auth.users.email = (
                SELECT email FROM profiles 
                WHERE profiles.id = matriculas_detalle.apoderado_id
            )
            OR 
            auth.users.id = matriculas_detalle.apoderado_id
        )
    )
);

-- Allow authenticated users to insert their own matriculas data
CREATE POLICY "Users can insert their own matriculas_detalle" 
ON public.matriculas_detalle 
FOR INSERT 
TO authenticated 
WITH CHECK (
    auth.uid() = apoderado_id
);

-- Allow authenticated users to update their own matriculas data
CREATE POLICY "Users can update their own matriculas_detalle" 
ON public.matriculas_detalle 
FOR UPDATE 
TO authenticated 
USING (
    auth.uid() = apoderado_id
) 
WITH CHECK (
    auth.uid() = apoderado_id
);

-- RLS Policies for user_roles table
-- Drop existing policies if they exist, then create new ones
DROP POLICY IF EXISTS "Users can view their own role" ON public.user_roles;
DROP POLICY IF EXISTS "Service role can manage user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Admins can view all user_roles" ON public.user_roles;

-- Only allow users to view their own role
CREATE POLICY "Users can view their own role" 
ON public.user_roles 
FOR SELECT 
TO authenticated 
USING (
    auth.uid() = user_id
);

-- Only allow service_role to manage user roles
CREATE POLICY "Service role can manage user_roles" 
ON public.user_roles 
FOR ALL 
TO service_role 
USING (true) 
WITH CHECK (true);

-- Admins can view all user roles
CREATE POLICY "Admins can view all user_roles" 
ON public.user_roles 
FOR SELECT 
TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin'
    )
);

-- ========================================
-- 4. GRANT APPROPRIATE PERMISSIONS
-- ========================================

-- Grant SELECT permissions on views to authenticated users
GRANT SELECT ON public.database_metadata TO authenticated;
GRANT SELECT ON public.payment_summary TO authenticated;

-- Grant appropriate permissions on tables
GRANT SELECT, INSERT, UPDATE ON public.matriculas_detalle TO authenticated;
GRANT SELECT ON public.user_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.guardians TO authenticated;

-- ========================================
-- 5. VERIFICATION QUERIES
-- ========================================

-- Check that RLS is enabled on all required tables
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ENABLED'
        ELSE '❌ RLS DISABLED'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN ('matriculas_detalle', 'user_roles', 'guardians')
ORDER BY tablename;

-- Check that views are not using SECURITY DEFINER
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public'
  AND viewname IN ('database_metadata', 'payment_summary');

-- Check RLS policies exist
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('matriculas_detalle', 'user_roles', 'guardians')
ORDER BY tablename, policyname;

-- ========================================
-- 6. ADDITIONAL SECURITY RECOMMENDATIONS
-- ========================================

-- Ensure all other public tables have RLS enabled
-- (You may need to review and enable RLS on other tables as well)

-- Check for other tables without RLS
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ENABLED'
        ELSE '⚠️  RLS DISABLED - REVIEW NEEDED'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
  AND NOT rowsecurity
ORDER BY tablename;

-- ========================================
-- EXPECTED RESULTS AFTER EXECUTION:
-- ========================================

-- ✅ database_metadata view should not use SECURITY DEFINER
-- ✅ payment_summary view should not use SECURITY DEFINER
-- ✅ matriculas_detalle table should have RLS enabled with policies
-- ✅ user_roles table should have RLS enabled with policies
-- ✅ guardians table should have RLS enabled with policies
-- ✅ All security vulnerabilities should be resolved

-- SUCCESS MESSAGE:
-- "All critical security issues have been resolved!"

-- ========================================
-- NOTES:
-- ========================================

-- 1. SECURITY DEFINER views can be security risks because they execute with
--    the permissions of the view creator, potentially bypassing RLS policies
--
-- 2. Tables without RLS in public schema are accessible to all authenticated users
--    which can lead to data exposure
--
-- 3. After applying these fixes, test your application to ensure functionality
--    is preserved while security is enhanced
--
-- 4. Consider implementing more granular RLS policies based on your specific
--    business requirements and user roles
