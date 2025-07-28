-- =============================================================================
-- RLS PERFORMANCE OPTIMIZATION SCRIPT
-- Fixes Supabase Performance Advisor warnings for RLS policies
-- =============================================================================

-- Begin transaction to ensure all changes are applied atomically
BEGIN;

-- =============================================================================
-- 1. FIX AUTH RLS INITIALIZATION PLAN ISSUES
-- Replace direct auth.<function>() calls with (select auth.<function>())
-- =============================================================================

-- PROFILES TABLE RLS POLICY FIXES
-- ================================

-- Drop existing problematic policies for profiles table
DROP POLICY IF EXISTS "Admin can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin to read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated user to read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Profiles read access" ON public.profiles;
DROP POLICY IF EXISTS "User can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Profiles – Users can update their own row" ON public.profiles;
DROP POLICY IF EXISTS "admin_full_access" ON public.profiles;
DROP POLICY IF EXISTS "users_insert_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "users_read_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "users_update_own_profile" ON public.profiles;

-- Create optimized consolidated policies for profiles
CREATE POLICY "profiles_admin_full_access" ON public.profiles
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  );

CREATE POLICY "profiles_users_own_access" ON public.profiles
  FOR ALL TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

-- GUARDIANS TABLE RLS POLICY FIXES
-- =================================

-- Drop existing problematic policies for guardians table
DROP POLICY IF EXISTS "Users can view their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Users can delete their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Users can insert their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Users can update their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Guardians - ADMIN Full Access" ON public.guardians;
DROP POLICY IF EXISTS "Guardians - FINANCE_MANAGER Read Access" ON public.guardians;

-- Create optimized consolidated policies for guardians
CREATE POLICY "guardians_admin_full_access" ON public.guardians
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  );

CREATE POLICY "guardians_finance_read_access" ON public.guardians
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  );

CREATE POLICY "guardians_own_access" ON public.guardians
  FOR ALL TO authenticated
  USING (owner_id = (SELECT auth.uid()))
  WITH CHECK (owner_id = (SELECT auth.uid()));

-- AUTH_LOGS TABLE RLS POLICY FIXES
-- =================================

-- Drop existing problematic policies for auth_logs table
DROP POLICY IF EXISTS "Auth logs read access" ON public.auth_logs;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.auth_logs;
DROP POLICY IF EXISTS "Auth logs insert access" ON public.auth_logs;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.auth_logs;

-- Create optimized consolidated policies for auth_logs
CREATE POLICY "auth_logs_read_access" ON public.auth_logs
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    ) OR user_id = (SELECT auth.uid())
  );

CREATE POLICY "auth_logs_insert_access" ON public.auth_logs
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

-- STUDENT_GUARDIAN TABLE RLS POLICY FIXES
-- ========================================

-- Drop existing problematic policies for student_guardian table
DROP POLICY IF EXISTS "Guardian can view own associations" ON public.student_guardian;
DROP POLICY IF EXISTS "Student guardian delete access" ON public.student_guardian;
DROP POLICY IF EXISTS "Student guardian insert access" ON public.student_guardian;
DROP POLICY IF EXISTS "Student guardian read access" ON public.student_guardian;
DROP POLICY IF EXISTS "Admin can manage student_guardian" ON public.student_guardian;
DROP POLICY IF EXISTS "Enable read for all authenticated users" ON public.student_guardian;

-- Create optimized consolidated policies for student_guardian
CREATE POLICY "student_guardian_admin_full_access" ON public.student_guardian
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  );

CREATE POLICY "student_guardian_own_access" ON public.student_guardian
  FOR ALL TO authenticated
  USING (
    guardian_id IN (
      SELECT id FROM public.guardians 
      WHERE owner_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    guardian_id IN (
      SELECT id FROM public.guardians 
      WHERE owner_id = (SELECT auth.uid())
    )
  );

-- FEE TABLE RLS POLICY FIXES
-- ===========================

-- Drop existing problematic policies for fee table
DROP POLICY IF EXISTS "Users can only view their own fees" ON public.fee;
DROP POLICY IF EXISTS "Fee - ADMIN Full Access" ON public.fee;
DROP POLICY IF EXISTS "Fee - FINANCE_MANAGER CRUD Access" ON public.fee;
DROP POLICY IF EXISTS "Fee - GUARDIAN Read Access to Own Students Fees" ON public.fee;

-- Create optimized consolidated policies for fee table
CREATE POLICY "fee_admin_full_access" ON public.fee
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  );

CREATE POLICY "fee_finance_crud_access" ON public.fee
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  );

CREATE POLICY "fee_guardian_read_access" ON public.fee
  FOR SELECT TO authenticated
  USING (
    student_id IN (
      SELECT s.id FROM public.students s
      INNER JOIN public.student_guardian sg ON s.id = sg.student_id
      INNER JOIN public.guardians g ON sg.guardian_id = g.id
      WHERE g.owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "fee_owner_access" ON public.fee
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.students s 
      WHERE s.id = fee.student_id 
      AND s.owner_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.students s 
      WHERE s.id = fee.student_id 
      AND s.owner_id = (SELECT auth.uid())
    )
  );

-- =============================================================================
-- 2. FIX MULTIPLE PERMISSIVE POLICIES FOR OTHER TABLES
-- =============================================================================

-- FEES TABLE (different from fee)
-- ================================
DROP POLICY IF EXISTS "Admins and Finance Managers can manage fees" ON public.fees;
DROP POLICY IF EXISTS "All authenticated users can read fees" ON public.fees;

-- Create single consolidated policy for fees table
CREATE POLICY "fees_consolidated_access" ON public.fees
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  );

-- INVOICES TABLE
-- ==============
DROP POLICY IF EXISTS "All authenticated users can read invoices" ON public.invoices;
DROP POLICY IF EXISTS "Invoices – Admin/Finance full access" ON public.invoices;

-- Create consolidated policy for invoices table
CREATE POLICY "invoices_consolidated_access" ON public.invoices
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  );

-- PAYMENTS TABLE
-- ==============
DROP POLICY IF EXISTS "All authenticated users can read payments" ON public.payments;
DROP POLICY IF EXISTS "Payments – Admin/Finance full access" ON public.payments;

-- Create consolidated policy for payments table
CREATE POLICY "payments_consolidated_access" ON public.payments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  );

-- STUDENTS TABLE
-- ==============
DROP POLICY IF EXISTS "Students - ACADEMICO CRUD Access" ON public.students;
DROP POLICY IF EXISTS "Students - ADMIN Full Access" ON public.students;
DROP POLICY IF EXISTS "Students - FINANCE_MANAGER Read Access" ON public.students;
DROP POLICY IF EXISTS "Students - GUARDIAN Read Access" ON public.students;
DROP POLICY IF EXISTS "Students - GUARDIAN Update Access" ON public.students;

-- Create consolidated policies for students table
CREATE POLICY "students_admin_full_access" ON public.students
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role = 'ADMIN'
    )
  );

CREATE POLICY "students_academico_crud_access" ON public.students
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'ACADEMICO')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'ACADEMICO')
    )
  );

CREATE POLICY "students_finance_read_access" ON public.students
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = (SELECT auth.uid()) 
      AND p.role IN ('ADMIN', 'FINANCE_MANAGER')
    )
  );

CREATE POLICY "students_guardian_access" ON public.students
  FOR SELECT TO authenticated
  USING (
    id IN (
      SELECT sg.student_id FROM public.student_guardian sg
      INNER JOIN public.guardians g ON sg.guardian_id = g.id
      WHERE g.owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "students_guardian_update_access" ON public.students
  FOR UPDATE TO authenticated
  USING (
    id IN (
      SELECT sg.student_id FROM public.student_guardian sg
      INNER JOIN public.guardians g ON sg.guardian_id = g.id
      WHERE g.owner_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    id IN (
      SELECT sg.student_id FROM public.student_guardian sg
      INNER JOIN public.guardians g ON sg.guardian_id = g.id
      WHERE g.owner_id = (SELECT auth.uid())
    )
  );

-- =============================================================================
-- 3. FIX DUPLICATE INDEX ISSUE
-- =============================================================================

-- Drop duplicate index (keep the more descriptive one)
DROP INDEX IF EXISTS public.idx_students_owner;

-- =============================================================================
-- 4. ADD PERFORMANCE MONITORING VIEWS
-- =============================================================================

-- Create a view to monitor RLS policy performance
CREATE OR REPLACE VIEW public.rls_policy_monitor AS
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
ORDER BY tablename, policyname;

-- Create a view to monitor index usage
CREATE OR REPLACE VIEW public.index_usage_monitor AS
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_tup_read,
  idx_tup_fetch,
  idx_scan
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- =============================================================================
-- 5. VERIFICATION QUERIES
-- =============================================================================

-- Function to verify RLS optimization
CREATE OR REPLACE FUNCTION public.verify_rls_optimization() 
RETURNS TABLE(
  table_name text,
  policy_count bigint,
  optimized boolean
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.tablename::text,
    COUNT(p.policyname)::bigint as policy_count,
    CASE 
      WHEN COUNT(p.policyname) <= 4 THEN true 
      ELSE false 
    END as optimized
  FROM information_schema.tables t
  LEFT JOIN pg_policies p ON t.table_name = p.tablename
  WHERE t.table_schema = 'public' 
    AND t.table_type = 'BASE TABLE'
    AND EXISTS (SELECT 1 FROM pg_policies WHERE tablename = t.table_name)
  GROUP BY t.tablename
  ORDER BY policy_count DESC;
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- =============================================================================
-- VERIFICATION REPORT
-- =============================================================================

-- Display optimization results
SELECT 'RLS Policy Optimization Complete' as status;

-- Show policy counts per table
SELECT * FROM public.verify_rls_optimization();

-- Show remaining policies that might need attention
SELECT 
  tablename,
  COUNT(*) as policy_count,
  array_agg(policyname) as policies
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
HAVING COUNT(*) > 4
ORDER BY policy_count DESC;

-- Show index status
SELECT 
  schemaname,
  tablename,
  COUNT(*) as index_count
FROM pg_indexes 
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;
