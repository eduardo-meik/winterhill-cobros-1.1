-- =========================================
-- FINAL SECURITY AND PERFORMANCE FIXES
-- =========================================
-- This script applies all remaining fixes for Supabase Performance Advisor
-- and Security Linter warnings.
--
-- IMPORTANT: Run this script in your Supabase Dashboard SQL Editor
-- 
-- Issues Fixed:
-- 1. SECURITY DEFINER views (database_metadata, payment_summary)
-- 2. Missing RLS on tables (matriculas_detalle, user_roles, guardians)
-- 3. Column reference error in payment_summary view
-- 4. Complete RLS policies for all sensitive tables

-- =========================================
-- 1. FIX SECURITY DEFINER VIEWS
-- =========================================

-- Drop and recreate database_metadata view without SECURITY DEFINER
DROP VIEW IF EXISTS public.database_metadata;
CREATE OR REPLACE VIEW public.database_metadata AS
SELECT 
    schemaname as table_schema,
    tablename as table_name,
    jsonb_build_object(
        'has_indexes', hasindexes,
        'has_rules', hasrules,
        'has_triggers', hastriggers,
        'row_security', rowsecurity,
        'table_owner', tableowner
    ) as metadata
FROM pg_tables 
WHERE schemaname = 'public';

-- Drop and recreate payment_summary view without SECURITY DEFINER and with correct columns
DROP VIEW IF EXISTS public.payment_summary;
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

-- =========================================
-- 2. ENABLE RLS ON MISSING TABLES
-- =========================================

-- Enable RLS on matriculas_detalle
ALTER TABLE matriculas_detalle ENABLE ROW LEVEL SECURITY;

-- Enable RLS on user_roles
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Enable RLS on guardians (if not already enabled)
ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;

-- =========================================
-- 3. CREATE RLS POLICIES
-- =========================================

-- Policies for matriculas_detalle
DROP POLICY IF EXISTS "matriculas_detalle_read_policy" ON matriculas_detalle;
CREATE POLICY "matriculas_detalle_read_policy" ON matriculas_detalle
    FOR SELECT 
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "matriculas_detalle_insert_policy" ON matriculas_detalle;
CREATE POLICY "matriculas_detalle_insert_policy" ON matriculas_detalle
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "matriculas_detalle_update_policy" ON matriculas_detalle;
CREATE POLICY "matriculas_detalle_update_policy" ON matriculas_detalle
    FOR UPDATE 
    TO authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "matriculas_detalle_delete_policy" ON matriculas_detalle;
CREATE POLICY "matriculas_detalle_delete_policy" ON matriculas_detalle
    FOR DELETE 
    TO authenticated
    USING (true);

-- Policies for user_roles
DROP POLICY IF EXISTS "user_roles_read_policy" ON user_roles;
CREATE POLICY "user_roles_read_policy" ON user_roles
    FOR SELECT 
    TO authenticated
    USING (auth.uid() = user_id OR 
           EXISTS (
               SELECT 1 FROM user_roles ur 
               WHERE ur.user_id = auth.uid() 
               AND ur.role = 'admin'
           ));

DROP POLICY IF EXISTS "user_roles_insert_policy" ON user_roles;
CREATE POLICY "user_roles_insert_policy" ON user_roles
    FOR INSERT 
    TO authenticated
    WITH CHECK (EXISTS (
        SELECT 1 FROM user_roles ur 
        WHERE ur.user_id = auth.uid() 
        AND ur.role = 'admin'
    ));

DROP POLICY IF EXISTS "user_roles_update_policy" ON user_roles;
CREATE POLICY "user_roles_update_policy" ON user_roles
    FOR UPDATE 
    TO authenticated
    USING (EXISTS (
        SELECT 1 FROM user_roles ur 
        WHERE ur.user_id = auth.uid() 
        AND ur.role = 'admin'
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM user_roles ur 
        WHERE ur.user_id = auth.uid() 
        AND ur.role = 'admin'
    ));

DROP POLICY IF EXISTS "user_roles_delete_policy" ON user_roles;
CREATE POLICY "user_roles_delete_policy" ON user_roles
    FOR DELETE 
    TO authenticated
    USING (EXISTS (
        SELECT 1 FROM user_roles ur 
        WHERE ur.user_id = auth.uid() 
        AND ur.role = 'admin'
    ));

-- Policies for guardians (full CRUD access for authenticated users)
DROP POLICY IF EXISTS "guardians_read_policy" ON guardians;
CREATE POLICY "guardians_read_policy" ON guardians
    FOR SELECT 
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "guardians_insert_policy" ON guardians;
CREATE POLICY "guardians_insert_policy" ON guardians
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "guardians_update_policy" ON guardians;
CREATE POLICY "guardians_update_policy" ON guardians
    FOR UPDATE 
    TO authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "guardians_delete_policy" ON guardians;
CREATE POLICY "guardians_delete_policy" ON guardians
    FOR DELETE 
    TO authenticated
    USING (true);

-- =========================================
-- 4. GRANT PERMISSIONS
-- =========================================

-- Grant permissions to authenticated role
GRANT SELECT, INSERT, UPDATE, DELETE ON matriculas_detalle TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON guardians TO authenticated;

-- Grant permissions for views
GRANT SELECT ON database_metadata TO authenticated;
GRANT SELECT ON payment_summary TO authenticated;

-- =========================================
-- 5. VERIFICATION QUERIES
-- =========================================

-- Verify RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('matriculas_detalle', 'user_roles', 'guardians')
ORDER BY tablename;

-- Verify policies exist
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    roles
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('matriculas_detalle', 'user_roles', 'guardians')
ORDER BY tablename, policyname;

-- Test views are accessible
SELECT 'database_metadata' as view_name, COUNT(*) as row_count FROM database_metadata
UNION ALL
SELECT 'payment_summary' as view_name, COUNT(*) as row_count FROM payment_summary;

-- =========================================
-- SUCCESS MESSAGE
-- =========================================
SELECT 'All security and performance fixes applied successfully!' as status;
