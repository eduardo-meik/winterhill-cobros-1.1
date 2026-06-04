-- ============================================================================
-- CONSOLIDATED MIGRATION FILE
-- Generated: 2026-03-06 00:19:11
-- Project: winterhill-cobros (yeotpplgerfpxviqazrn)
-- Contains: 49 pending local-only migrations
-- 
-- WARNING: This file is very large. For Supabase SQL Editor,
-- you may need to execute migrations in batches.
-- See the batch markers below.
-- ============================================================================


-- ######################################################################
-- BATCH 1 (migrations 1 to 10)
-- ######################################################################

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [1/49] MIGRATION: 20250515000001_add_guardian_student_functions
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

/*
  # Add helper functions for guardian-student relationships

  Add functions to help reliably query student-guardian relationships.
  This is especially important for the reporting page functionality.

  1. Functions
    - get_students_by_guardian_ids: Get all student_ids for given guardian_ids
*/

-- Function to get student IDs for a list of guardian IDs
DROP FUNCTION IF EXISTS get_students_by_guardian_ids(uuid[]);
CREATE OR REPLACE FUNCTION get_students_by_guardian_ids(guardian_ids uuid[])
RETURNS TABLE (student_id uuid)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT sg.student_id 
  FROM student_guardian sg 
  WHERE sg.guardian_id = ANY(guardian_ids);
$$;

-- Function to get guardian IDs for a list of student IDs
DROP FUNCTION IF EXISTS get_guardians_by_student_ids(uuid[]);
CREATE OR REPLACE FUNCTION get_guardians_by_student_ids(student_ids uuid[])
RETURNS TABLE (guardian_id uuid)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT sg.guardian_id 
  FROM student_guardian sg 
  WHERE sg.student_id = ANY(student_ids);
$$;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [2/49] MIGRATION: 20250529000000_add_role_to_student_guardian
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add guardian_role to student_guardian table
ALTER TABLE public.student_guardian
ADD COLUMN IF NOT EXISTS guardian_role TEXT;

COMMENT ON COLUMN public.student_guardian.guardian_role IS 'Specifies the role of the guardian in relation to the student (e.g., ECONOMICO, PEDAGOGICO, AMBOS, OTRO)';

-- Optional: You might want to add a check constraint if you have a fixed set of roles
-- and want to enforce them at the database level.
-- Example:
-- ALTER TABLE public.student_guardian
-- ADD CONSTRAINT check_guardian_role CHECK (guardian_role IN ('ECONOMICO', 'PEDAGOGICO', 'AMBOS', 'OTRO'));


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [3/49] MIGRATION: 20250529000001_add_unique_constraint_to_student_guardian
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add unique constraint to student_guardian table to ensure student_id and guardian_id pairs are unique.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'student_guardian_student_id_guardian_id_key'
  ) THEN
    ALTER TABLE public.student_guardian
    ADD CONSTRAINT student_guardian_student_id_guardian_id_key UNIQUE (student_id, guardian_id);
  END IF;
END$$;

COMMENT ON CONSTRAINT student_guardian_student_id_guardian_id_key ON public.student_guardian IS 'Ensures that each student-guardian pair is unique, allowing upsert operations to correctly update roles.';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [4/49] MIGRATION: 20250726202500_harden_security
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- 1. Create handle_new_user function and trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, created_at)
  VALUES (new.id, new.email, now());
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. Add RLS policies for cursos table
ALTER TABLE public.cursos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage cursos" ON public.cursos;
CREATE POLICY "Admins can manage cursos" ON public.cursos
  FOR ALL USING (get_current_user_role() = 'ADMIN'::text)
  WITH CHECK (get_current_user_role() = 'ADMIN'::text);

DROP POLICY IF EXISTS "All authenticated users can read cursos" ON public.cursos;
CREATE POLICY "All authenticated users can read cursos" ON public.cursos
  FOR SELECT USING (auth.role() = 'authenticated');

-- 3. Refactor existing policies to be more consistent
-- For example, refactor policies on the 'guardians' table
DROP POLICY IF EXISTS "Users can delete their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Users can insert their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Users can update their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Users can view their own guardians" ON public.guardians;

DROP POLICY IF EXISTS "Guardians can manage their own data" ON public.guardians;
CREATE POLICY "Guardians can manage their own data" ON public.guardians
  FOR ALL USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Apply similar refactoring to other tables as needed...
-- (I will add more refactoring for other tables in the new policies.json)


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [5/49] MIGRATION: 20250805000001_fix_security_definer_views
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Fix SECURITY DEFINER views security issue
-- This addresses Supabase Security Advisor alerts about views with SECURITY DEFINER

-- 1. Drop and recreate database_metadata view without SECURITY DEFINER
DROP VIEW IF EXISTS public.database_metadata;
CREATE OR REPLACE VIEW public.database_metadata AS
WITH table_info AS (
  SELECT 
    t.table_schema,
    t.table_name,
    t.table_type,
    obj_description((quote_ident(t.table_schema) || '.' || quote_ident(t.table_name))::regclass, 'pg_class') as table_description
  FROM information_schema.tables t
  WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
),
column_info AS (
  SELECT 
    c.table_schema,
    c.table_name,
    jsonb_agg(jsonb_build_object(
      'column_name', c.column_name,
      'data_type', c.data_type,
      'is_nullable', c.is_nullable,
      'column_default', c.column_default,
      'character_maximum_length', c.character_maximum_length,
      'ordinal_position', c.ordinal_position
    ) ORDER BY c.ordinal_position) as columns
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
  GROUP BY c.table_schema, c.table_name
),
constraint_info AS (
  SELECT 
    tc.table_schema,
    tc.table_name,
    jsonb_agg(jsonb_build_object(
      'constraint_name', tc.constraint_name,
      'constraint_type', tc.constraint_type,
      'column_names', kcu_agg.col_names
    )) as constraints
  FROM information_schema.table_constraints tc
  LEFT JOIN LATERAL (
    SELECT array_agg(kcu.column_name ORDER BY kcu.ordinal_position) AS col_names
    FROM information_schema.key_column_usage kcu
    WHERE kcu.constraint_name = tc.constraint_name
      AND kcu.table_schema = tc.table_schema
      AND kcu.table_name = tc.table_name
  ) kcu_agg ON true
  WHERE tc.table_schema = 'public'
  GROUP BY tc.table_schema, tc.table_name
),
index_info AS (
  SELECT 
    schemaname as table_schema,
    tablename as table_name,
    jsonb_agg(jsonb_build_object(
      'index_name', indexname,
      'index_definition', indexdef
    )) as indexes
  FROM pg_indexes
  WHERE schemaname = 'public'
  GROUP BY schemaname, tablename
),
policy_info AS (
  SELECT 
    schemaname as table_schema,
    tablename as table_name,
    jsonb_agg(jsonb_build_object(
      'policy_name', policyname,
      'permissive', permissive,
      'roles', roles,
      'cmd', cmd,
      'qual', qual,
      'with_check', with_check
    )) as policies
  FROM pg_policies
  WHERE schemaname = 'public'
  GROUP BY schemaname, tablename
)
SELECT 
  ti.table_schema,
  ti.table_name,
  ti.table_type,
  ti.table_description,
  COALESCE(ci.columns, '[]'::jsonb) as columns,
  COALESCE(ct.constraints, '[]'::jsonb) as constraints,
  COALESCE(ii.indexes, '[]'::jsonb) as indexes,
  COALESCE(pi.policies, '[]'::jsonb) as policies
FROM table_info ti
LEFT JOIN column_info ci ON ti.table_schema = ci.table_schema AND ti.table_name = ci.table_name
LEFT JOIN constraint_info ct ON ti.table_schema = ct.table_schema AND ti.table_name = ct.table_name
LEFT JOIN index_info ii ON ti.table_schema = ii.table_schema AND ti.table_name = ii.table_name
LEFT JOIN policy_info pi ON ti.table_schema = pi.table_schema AND ti.table_name = pi.table_name
ORDER BY ti.table_name;

-- 2. Drop and recreate payment_summary view without SECURITY DEFINER
DROP VIEW IF EXISTS public.payment_summary;
CREATE OR REPLACE VIEW public.payment_summary AS
SELECT 
  p.id,
  p.student_id,
  s.whole_name as student_name,
  s.first_name,
  s.apellido_paterno,
  s.apellido_materno,
  c.nom_curso as course_name,
  p.amount,
  p.numero_cuota,
  p.due_date,
  p.payment_date,
  p.status,
  p.payment_method,
  p.num_boleta,
  p.mov_bancario,
  p.notes,
  p.created_at,
  p.updated_at,
  -- Calculate days overdue for overdue payments
  CASE 
    WHEN p.status = 'overdue' AND p.due_date IS NOT NULL 
    THEN (CURRENT_DATE - p.due_date)
    ELSE NULL 
  END as days_overdue,
  -- Payment status in Spanish
  CASE p.status
    WHEN 'paid' THEN 'Pagado'
    WHEN 'pending' THEN 'Pendiente'
    WHEN 'overdue' THEN 'Vencido'
    ELSE p.status
  END as status_display
FROM fee p
LEFT JOIN students s ON p.student_id = s.id
LEFT JOIN cursos c ON s.curso = c.id
ORDER BY p.due_date DESC, p.created_at DESC;

-- 3. Grant appropriate permissions (using invoker's permissions, not SECURITY DEFINER)
GRANT SELECT ON public.database_metadata TO authenticated;
GRANT SELECT ON public.payment_summary TO authenticated;

-- 4. Create RLS policies for the views if needed
-- Note: Views inherit RLS from underlying tables, so this is usually not needed
-- but we can add explicit policies if required

-- 5. Verify the views are not using SECURITY DEFINER
-- This query should return empty results for secure views
SELECT 
  schemaname,
  viewname,
  definition
FROM pg_views 
WHERE schemaname = 'public' 
  AND viewname IN ('database_metadata', 'payment_summary')
  AND definition ILIKE '%SECURITY DEFINER%';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [6/49] MIGRATION: 20250805000002_fix_function_search_path
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Fix function search_path security issues
-- Date: 2025-08-05
-- Description: Add SET search_path = public to all functions flagged by Supabase Security Advisor

-- Drop existing functions first to avoid return type conflicts
-- Use CASCADE for trigger functions to drop dependent triggers
DROP FUNCTION IF EXISTS public.actualizar_estado_std(uuid, text);
DROP FUNCTION IF EXISTS public.es_admin_o_equipo(uuid);
DROP FUNCTION IF EXISTS public.generate_invoice(uuid, integer, integer, numeric);
DROP FUNCTION IF EXISTS public.get_fees_with_students();
DROP FUNCTION IF EXISTS public.get_guardians_by_student_ids(uuid[]);
DROP FUNCTION IF EXISTS public.get_student_balance(uuid);
DROP FUNCTION IF EXISTS public.get_students_by_guardian_ids(uuid[]);
DROP FUNCTION IF EXISTS public.get_table_metadata(text);
DROP FUNCTION IF EXISTS public.get_user_profile(uuid);
DROP FUNCTION IF EXISTS public.update_fee_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.update_profile_full_name() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;

-- Function: actualizar_estado_std
CREATE OR REPLACE FUNCTION public.actualizar_estado_std(
    p_student_id uuid,
    p_new_status text
)
RETURNS void
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    UPDATE students 
    SET status = p_new_status, 
        updated_at = now()
    WHERE id = p_student_id;
END;
$$;

-- Function: es_admin_o_equipo
CREATE OR REPLACE FUNCTION public.es_admin_o_equipo(user_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
DECLARE
    user_role text;
BEGIN
    SELECT role INTO user_role
    FROM profiles
    WHERE id = user_uuid;
    
    RETURN user_role IN ('ADMIN', 'EQUIPO');
END;
$$;

-- Function: generate_invoice
CREATE OR REPLACE FUNCTION public.generate_invoice(
    p_student_id uuid,
    p_month integer,
    p_year integer,
    p_amount numeric
)
RETURNS uuid
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
DECLARE
    invoice_id uuid;
BEGIN
    INSERT INTO invoices (student_id, month, year, amount, status, created_at)
    VALUES (p_student_id, p_month, p_year, p_amount, 'PENDING', now())
    RETURNING id INTO invoice_id;
    
    RETURN invoice_id;
END;
$$;

-- Function: get_fees_with_students
CREATE OR REPLACE FUNCTION public.get_fees_with_students()
RETURNS TABLE (
    fee_id uuid,
    student_id uuid,
    student_name text,
    amount numeric,
    due_date date,
    status text
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id as fee_id,
        s.id as student_id,
        COALESCE(s.whole_name, CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', s.apellido_materno)) as student_name,
        f.amount,
        f.due_date,
        f.status
    FROM fee f  -- FIXED: Changed from 'fees' to 'fee' to match schema
    JOIN students s ON f.student_id = s.id
    ORDER BY f.due_date DESC;
END;
$$;

-- Function: get_guardians_by_student_ids
CREATE OR REPLACE FUNCTION public.get_guardians_by_student_ids(student_ids uuid[])
RETURNS TABLE (
    guardian_id uuid,
    student_id uuid,
    first_name text,
    last_name text,
    email text,
    phone text,
    relationship_type text,
    tipo_apoderado text
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.id as guardian_id,
        sg.student_id,
        g.first_name,
        g.last_name,
        g.email,
        g.phone,
        g.relationship_type,
        g.tipo_apoderado
    FROM guardians g
    JOIN student_guardian sg ON g.id = sg.guardian_id
    WHERE sg.student_id = ANY(student_ids);
END;
$$;

-- Function: get_student_balance
CREATE OR REPLACE FUNCTION public.get_student_balance(p_student_id uuid)
RETURNS numeric
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
DECLARE
    total_fees numeric := 0;
    total_payments numeric := 0;
    balance numeric := 0;
BEGIN
    -- Calculate total fees (FIXED: table name)
    SELECT COALESCE(SUM(amount), 0) INTO total_fees
    FROM fee  -- FIXED: Changed from 'fees' to 'fee'
    WHERE student_id = p_student_id;
    
    -- Calculate total payments
    SELECT COALESCE(SUM(amount), 0) INTO total_payments
    FROM fee
    WHERE student_id = p_student_id
      AND status = 'paid';
    
    balance := total_fees - total_payments;
    
    RETURN balance;
END;
$$;

-- Function: get_students_by_guardian_ids
CREATE OR REPLACE FUNCTION public.get_students_by_guardian_ids(guardian_ids uuid[])
RETURNS TABLE (
    student_id uuid,
    guardian_id uuid,
    first_name text,
    apellido_paterno text,
    apellido_materno text,
    whole_name text,
    curso_id uuid,
    curso_name text
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id as student_id,
        sg.guardian_id,
        s.first_name,
        s.apellido_paterno,
        s.apellido_materno,
        COALESCE(s.whole_name, CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', s.apellido_materno)) as whole_name,
        s.curso as curso_id,
        c.nom_curso as curso_name
    FROM students s
    JOIN student_guardian sg ON s.id = sg.student_id
    LEFT JOIN cursos c ON s.curso = c.id
    WHERE sg.guardian_id = ANY(guardian_ids);
END;
$$;

-- Function: get_table_metadata
CREATE OR REPLACE FUNCTION public.get_table_metadata(table_name text)
RETURNS TABLE (
    column_name text,
    data_type text,
    is_nullable text,
    column_default text
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.column_name::text,
        c.data_type::text,
        c.is_nullable::text,
        c.column_default::text
    FROM information_schema.columns c
    WHERE c.table_name = get_table_metadata.table_name
    AND c.table_schema = 'public'
    ORDER BY c.ordinal_position;
END;
$$;

-- Function: get_user_profile
CREATE OR REPLACE FUNCTION public.get_user_profile(user_id uuid)
RETURNS TABLE (
    id uuid,
    email text,
    full_name text,
    role text,
    created_at timestamptz,
    updated_at timestamptz
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.email,
        p.full_name,
        p.role,
        p.created_at,
        p.updated_at
    FROM profiles p
    WHERE p.id = user_id;
END;
$$;

-- Function: update_fee_updated_at
CREATE OR REPLACE FUNCTION public.update_fee_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Function: update_profile_full_name
CREATE OR REPLACE FUNCTION public.update_profile_full_name()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    -- Update full_name based on first_name and last_name if they exist
    IF NEW.first_name IS NOT NULL OR NEW.last_name IS NOT NULL THEN
        NEW.full_name = CONCAT(COALESCE(NEW.first_name, ''), ' ', COALESCE(NEW.last_name, ''));
        NEW.full_name = TRIM(NEW.full_name);
    END IF;
    
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Function: update_updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.actualizar_estado_std(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.es_admin_o_equipo(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_invoice(uuid, integer, integer, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_fees_with_students() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_guardians_by_student_ids(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_student_balance(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_students_by_guardian_ids(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_table_metadata(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_profile(uuid) TO authenticated;

-- Recreate triggers that were dropped with CASCADE
-- Trigger for fee table
DROP TRIGGER IF EXISTS update_fee_updated_at_trigger ON fee;
CREATE TRIGGER update_fee_updated_at_trigger
    BEFORE UPDATE ON fee
    FOR EACH ROW
    EXECUTE FUNCTION update_fee_updated_at();

-- Trigger for profiles table (if it exists)
DROP TRIGGER IF EXISTS update_profile_full_name_trigger ON profiles;
CREATE TRIGGER update_profile_full_name_trigger
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_full_name();

-- Generic updated_at triggers (common pattern)
-- Add these for tables that need updated_at timestamp updates
DO $$
DECLARE
    tbl text;
    table_names text[] := ARRAY['students', 'guardians', 'cursos', 'fee'];
BEGIN
    FOREACH tbl IN ARRAY table_names
    LOOP
        -- Check if table exists before creating trigger
        IF EXISTS (SELECT 1 FROM information_schema.tables t WHERE t.table_schema = 'public' AND t.table_name = tbl) THEN
            EXECUTE format('DROP TRIGGER IF EXISTS update_%I_updated_at_trigger ON %I', tbl, tbl);
            EXECUTE format('CREATE TRIGGER update_%I_updated_at_trigger 
                           BEFORE UPDATE ON %I 
                           FOR EACH ROW 
                           EXECUTE FUNCTION update_updated_at()', tbl, tbl);
        END IF;
    END LOOP;
END $$;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [7/49] MIGRATION: 20250924_matricula_base
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Matrícula Base Schema Migration
-- Date: 2025-09-24
-- Purpose: Create enrollment (matrícula) core tables, strict RLS, triggers, and seed Pagaré template

-- Safety: wrap in transaction
BEGIN;

-- 1) Helper: enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid

-- 2) Tables
-- 2.1 enrollments (one per guardian per academic year, may include multiple students)
CREATE TABLE IF NOT EXISTS public.enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_id uuid NOT NULL REFERENCES public.guardians(id) ON DELETE RESTRICT,
  year integer NOT NULL CHECK (year BETWEEN 2000 AND 2100),
  status text NOT NULL CHECK (status IN ('draft','pending','completed','rejected')) DEFAULT 'draft',
  meta jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (guardian_id, year)
);

-- 2.2 enrollment_students (N students per enrollment)
CREATE TABLE IF NOT EXISTS public.enrollment_students (
  enrollment_id uuid NOT NULL REFERENCES public.enrollments(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (enrollment_id, student_id)
);

-- 2.3 document_templates (admin-editable legal templates)
CREATE TABLE IF NOT EXISTS public.document_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type IN ('PAGARE','DECLARACION','OTRO')),
  version int NOT NULL,
  title text,
  content text NOT NULL, -- raw template with {{placeholders}}
  placeholders jsonb DEFAULT '[]'::jsonb,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (type, version)
);

-- 2.4 enrollment_documents (generated per enrollment: pagaré, declaraciones, etc.)
CREATE TABLE IF NOT EXISTS public.enrollment_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id uuid NOT NULL REFERENCES public.enrollments(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('PAGARE','DECLARACION','OTRO')),
  template_version int NOT NULL,
  status text NOT NULL CHECK (status IN ('draft','generated','signed')) DEFAULT 'draft',
  pdf_url text, -- storage public URL or signed path
  storage_path text, -- storage object path
  generated_payload jsonb DEFAULT '{}'::jsonb, -- rendered variables snapshot
  signed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.5 signatures (audit of acceptances / signatures)
CREATE TABLE IF NOT EXISTS public.signatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_document_id uuid NOT NULL REFERENCES public.enrollment_documents(id) ON DELETE CASCADE,
  signer_type text NOT NULL CHECK (signer_type IN ('GUARDIAN','ADMIN')),
  signer_user_id uuid, -- auth.users.id when applicable
  method text NOT NULL CHECK (method IN ('checkbox','drawn','upload')),
  ip inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2.6 Optional: pre_receipts (pre-invoice/receipt before SII)
CREATE TABLE IF NOT EXISTS public.pre_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL,
  student_id uuid REFERENCES public.students(id) ON DELETE SET NULL,
  amount numeric(12,2) NOT NULL CHECK (amount >= 0),
  status text NOT NULL CHECK (status IN ('draft','issued','void')) DEFAULT 'draft',
  issued_at timestamptz,
  meta jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 3) Indexes
CREATE INDEX IF NOT EXISTS idx_enrollments_guardian_year ON public.enrollments (guardian_id, year);
CREATE INDEX IF NOT EXISTS idx_enrollment_students_enrollment ON public.enrollment_students (enrollment_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_students_student ON public.enrollment_students (student_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_documents_enrollment ON public.enrollment_documents (enrollment_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_documents_type ON public.enrollment_documents (type);
CREATE INDEX IF NOT EXISTS idx_pre_receipts_student ON public.pre_receipts (student_id);

-- 4) RLS enablement
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollment_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollment_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signatures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pre_receipts ENABLE ROW LEVEL SECURITY;

-- 5) RLS Policies
-- Helper policy approach: link access to guardians.owner_id = auth.uid()

-- enrollments: guardian who owns guardian_id can read/write their own enrollments
DROP POLICY IF EXISTS enrollments_guardian_access ON public.enrollments;
CREATE POLICY enrollments_guardian_access ON public.enrollments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = enrollments.guardian_id
      AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = enrollments.guardian_id
      AND g.owner_id = auth.uid()
    )
  );

-- enrollment_students: access via parent enrollment
DROP POLICY IF EXISTS enrollment_students_guardian_access ON public.enrollment_students;
CREATE POLICY enrollment_students_guardian_access ON public.enrollment_students
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE e.id = enrollment_students.enrollment_id
      AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE e.id = enrollment_students.enrollment_id
      AND g.owner_id = auth.uid()
    )
  );

-- document_templates: readable by all authenticated; write restricted later to ADMIN
DROP POLICY IF EXISTS document_templates_read ON public.document_templates;
CREATE POLICY document_templates_read ON public.document_templates
  FOR SELECT TO authenticated
  USING (true);

-- Admin write access (align with profiles.role = 'ADMIN')
DROP POLICY IF EXISTS document_templates_admin_write ON public.document_templates;
CREATE POLICY document_templates_admin_write ON public.document_templates
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'ADMIN'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'ADMIN'
    )
  );

-- enrollment_documents: access via parent enrollment
DROP POLICY IF EXISTS enrollment_documents_guardian_access ON public.enrollment_documents;
CREATE POLICY enrollment_documents_guardian_access ON public.enrollment_documents
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE e.id = enrollment_documents.enrollment_id
      AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE e.id = enrollment_documents.enrollment_id
      AND g.owner_id = auth.uid()
    )
  );

-- signatures: access via parent enrollment_document
DROP POLICY IF EXISTS signatures_guardian_access ON public.signatures;
CREATE POLICY signatures_guardian_access ON public.signatures
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.enrollment_documents d
      JOIN public.enrollments e ON e.id = d.enrollment_id
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE d.id = signatures.enrollment_document_id
      AND g.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS signatures_insert_guardian ON public.signatures;
CREATE POLICY signatures_insert_guardian ON public.signatures
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.enrollment_documents d
      JOIN public.enrollments e ON e.id = d.enrollment_id
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE d.id = signatures.enrollment_document_id
      AND g.owner_id = auth.uid()
    )
  );

-- pre_receipts: guardian can read their own; admin can manage
DROP POLICY IF EXISTS pre_receipts_guardian_read ON public.pre_receipts;
CREATE POLICY pre_receipts_guardian_read ON public.pre_receipts
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.owner_id = auth.uid()
      AND (
        (pre_receipts.enrollment_id IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.enrollments e WHERE e.id = pre_receipts.enrollment_id AND e.guardian_id = g.id
        ))
        OR
        (pre_receipts.student_id IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.student_guardian sg WHERE sg.student_id = pre_receipts.student_id AND sg.guardian_id = g.id
        ))
      )
    )
  );

DROP POLICY IF EXISTS pre_receipts_admin_all ON public.pre_receipts;
CREATE POLICY pre_receipts_admin_all ON public.pre_receipts
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('ADMIN','FINANCE_MANAGER')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('ADMIN','FINANCE_MANAGER')
    )
  );

-- 6) Triggers for updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enrollments_updated_at ON public.enrollments;
CREATE TRIGGER trg_enrollments_updated_at BEFORE UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_document_templates_updated_at ON public.document_templates;
CREATE TRIGGER trg_document_templates_updated_at BEFORE UPDATE ON public.document_templates FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_enrollment_documents_updated_at ON public.enrollment_documents;
CREATE TRIGGER trg_enrollment_documents_updated_at BEFORE UPDATE ON public.enrollment_documents FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_pre_receipts_updated_at ON public.pre_receipts;
CREATE TRIGGER trg_pre_receipts_updated_at BEFORE UPDATE ON public.pre_receipts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 7) Grants (keep least privilege; RLS will gate data)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT ON public.document_templates TO authenticated;

-- 8) Seed initial Pagaré template (v1) from contratos/pagare.txt
-- Note: placeholders will be progressively integrated in rendering layer
INSERT INTO public.document_templates (type, version, title, content, placeholders, active)
VALUES (
  'PAGARE',
  1,
  'Pagaré Winterhill v1',
  $$CONTRATO DE PRESTACIÓN DE SERVICIOS EDUCACIONALES 

En Viña del Mar, a _____ de _____ del 202__ entre la CORPORACIÓN EDUCACIONAL WINTERHILL. RUT 65.152.884-4, representada legalmente por doña Orlando Borquéz Domingo, cédula de Identidad N° 7.269.437-6 ambos domiciliadas en Pasaje Anwandter N° 31. Viña del Mar, en adelante, "LA CORPORACIÓN" y Don(a), _____ (nacionalidad) _____ (profesión u oficio). fano _____ (estado civil) _____ cédula de identidad N° _____ domiciliado/a en: _____ 




En adelante "EL/LA APODERADO/A", se ha celebrado el sigulente Contrato de Prestación de Servicios Educacionales: 


Primero: La Corporación Educacional Winterhill se encuentra reconocida oficialmente como tal y es sostenedora del Establecimiento Educacional denominado "Colegio Winterhill", en adelante "EL ESTABLECIMIENTO", ubicado en Pasaje Andwanter N° 31, Comuna de Viña del Mar, 


Segundo: Para todos los efectos de este contrato, se entiende por APODERADO/A la persona que, como responsable dellos) hijo(s) suscribe el presente instrumento, quien asume la totalidad de las obligaciones, deberes y compromisos que en este instrumento se consignan. 

EI/LA APODERADO/A ha solicitado a LA CORPORACIÓN -quien lo ha aceptado-matricular y prestar servicios educacionales en el Establecimiento Educacional Colegio Winterhill, ubicado en Pasaje Andwanter N 31. Comuna de Viña del Mar, par el año académico 2025, en calidad de alumnos(s) a su(s) pupilo a) que se individualizan a continuación, en adelante, Indistinta y anónimamente "EL/LA ESTUDIANTE": 

Númer	Nombre	RUT	Curso año 2025
O			
2			
3			
A			
5			



Export to Sheets
Tercero: LA CORPORACIÓN, en su calidad de sostenedora del ESTABLECIMIENTO, como entidad educacional y formativa, se compromete a lo siguiente:

Entregar, durante la vigencia del presente contrato, la atención necesaria para que EL/LA ESTUDIANTE desarrolle el proceso educativo dentro del nivel académico establecido por el colegio, comprometiendo un énfasis en su formación integral. 

Desarrollar el proceso de enseñanza-aprendizaje de conformidad con el Proyecto Educativo Institucional y los planes y programas de estudio del respectivo nivel, aprobados por el Ministerio de Educación de Chile, implementado por los docentes del colegio. 

Velar por el proceso formativo acorde a las normas reglamentarias del ESTABLECIMIENTO, basado en exigencias legales oficiales, vigentes en materias de evaluación y promoción. 

Difundir el contenido del Proyecto Educativo Institucional del Colegio, Manual de Convivencia Escolar y Reglamento de Evaluación y Promoción. 

Proporcionar al ESTUDIANTE. de acuerdo a las condiciones internas, la infraestructura del ESTABLECIMIENTO que se requiera para el desarrollo del programa curricular y extracurricular. 

Cuarto: EL/LA APODERADO/A se compromete a:
1 Aceptar y respetar los principios y objetivos del ESTABLECIMIENTO descritos en el Proyecto Educativo Institucional. Manual de Convivencia Escolar y Reglamento de Evaluación y Promoción. 


2 Favorecer las tareas educativas y formativas que, en beneficio del ESTUDIANTE, conciba y desarrolle EL ESTABLECIMIENTO. 


3. Pagar oportunamente, dentro de los plazos establecidos, la colegiatura y cumplir con el compromiso mensual correspondiente al Financiamiento Compartido. 


4. Asistir a las reuniones convocadas por el subcentro de madres, padres y apoderados. 


5. Asistir a las entrevistas personales citadas por los profesionales que se desempeñan en el Colegio. 

6 Mantener una actitud de respeta hacia cualquier miembro de la comunidad educativa. 


7. Informar por escrito el retiro de un estudiante. 

Quinto: EI/LA ESTUDIANTE, en virtud del presente contrato, adquiere los siguientes derechos:

A participar del proceso de enseñanza-aprendizaje acorde al Proyecto Educativo del Colegio y programas oficiales del Ministerio de Educación. 

A participar en todas las actividades académicas curriculares propias y demás de carácter extra programáticas que el Colegio promueva y ejecute. 

Utilizar la infraestructura del Colegio según las normas internas, para el normal desarrollo de su formación y del régimen curricular. 

Sexto: Serán obligaciones de EL/LA ALUMNO/A, en tanto beneficiario/a del presente contrato, las siguientes:

Cumplir con lo establecido en el Manual de Convivencia Escolar del Colegio. 

Asistir puntual y regularmente a las clases y actividades planificadas por el establecimiento. 

Respetar las normas de evaluación descritas en el Reglamento de Evaluación y Promoción vigente. 


Séptimo: EL APODERADO/A se obliga a pagar a LA CORPORACIÓN, por la prestación de los servicios educacionales encomendados, los siguientes valores, por los/as estudiantes individualizados en la Cláusula Segunda: 

Por concepto de matricula, al contado, la suma de $ _____ 

Por concepto de colegiatura anual, el monto correspondiente a 

_____−divididoen_____cuotasmensualesde _____ cada una para el dia _____ de cada mes. 

EL/LA APODERADO/A pagará la escolaridad anual del/los estudiantes señalados en este instrumento. en la siguiente forma (seleccionar): Cheques: _____ Transferencia Electrónica: _____ Pago en efectivo: _____ ☐ Tarjeta de Crédito: _____ 


Atendido que, LA CORPORACIÓN, se encuentra sujeta a la necesidad de financiar el funcionamiento del ESTABLECIMIENTO, por el periodo que corresponda a la totalidad del respectivo año académico, será obligatorio para el padre y/o apoderado/a efectuar el pago de la colegiatura anual, en la forma y fechas que se han establecido en esta cláusula. 

En el caso de el/la estudiante requiera, previo informe médico y/o psicológico, dar cierre anticipado del año escolar, la CORPORACIÓN exigirá el pago del año completo de conformidad con lo establecido en la cláusula séptima de este instrumento. 

Las partes contratantes convienen que, tanto el pago de la matrícula como la colegiatura anual antes referidas, constituyen obligaciones esenciales del presente contrato y su incumplimiento, por parte del APODERADO/A, habilitará a LA CORPORACIÓN para poner término a este contrato y perseguir las responsabilidades legales que de ello deriven. 

Igualmente, la CORPORACIÓN se reserva el derecho a renovar matricula en favor del/la estudiantes individualizados en la cláusula segunda para el evento que el/la apoderado/a incurra en incumplimiento de las obligaciones financieras que ha asumido en virtud de la presente cláusula. toda vez que -los ingresos que ellas deben reportar- resultan esenciales para el financiamiento y debido funcionamiento del Colegio Winterhill. 


Sin perjuicio de ello, las partes se comprometen a estudiar, en particular, la situación que pueda explicar dicho incumplimiento y, en el evento de ser ello plausible, establecer los mecanismos necesarios a fin de lograr, en definitiva, el pago de las referidas obligaciones y no afectar la situación educacional del alumno/a. 


Octavo: En el caso que el/la estudiante(s) tenga la calidad de "alumno prioritario" durante el presente año (2025). su apoderado/a. igualmente, deberá suscribir este contrato comprometiéndose a documentar el arancel en caso de que, eventualmente, pierda esta calidad para el año lectivo 2025. 


Noveno: En caso que el/la estudiante tenga que interrumpir el curso del respectivo año académico. cualquiera sea la causal de ello y habiendo dado aviso oportuno a la Dirección del ESTABLECIMIENTO Y al Departamento de Administración, se procederá a entregar al APODERADO/A la documentación académica que corresponda. 



Décimo: El presente contrato comenzará a regir desde la fecha de su suscripción y durará hasta el término del año lectivo correspondiente. Podrá ser renovado por el mutuo y expreso acuerdo de las partes que se manifestará en la suscripción de un nuevo contrato. 


Undécimo: El cumplimiento de las obligaciones financieras contraídas por el/la APODERADO/A, en el marco del presente contrato, será garantizado de la siguiente forma (seleccionar):
a) Cheques: nominativos a nombre de Corporación Educacional Winterhill, con vencimiento dentro de los primeros diez días de cada mes, por el periodo de marzo de 2025 a diciembre de 2025, 

b) Tarjeta de Crédito: a través del número de cuotas que le permita el banco. 

c) Pago efectivo: por el total de la colegiatura del año. 

d) Pago con transferencia bancaria comprometida a través de pagare notarial. 


Duodécimo: La CORPORACIÓN queda facultada para endosar o transferir, a cualquier título, los créditos constituidos por los cheques a fecha extendidos y/o aceptadas por el/la apoderado/a para garantizar las obligaciones financieras indicadas en la cláusula séptima, así como endosarios en cobranza o en garantía y disponer su protesto en caso de falta de pago oportuno. 

Por tanto, el/la apoderado/a autoriza expresamente al representante legal de la CORPORACIÓN para que, en caso de simple retardo, mora o incumplimiento de las obligaciones contraídas en documentos tales como contrato, facturas, órdenes de compra, solicitudes de compra, letras de cambio u otros, sus datos y las demás derivados de dichos documentos puedan ser ingresados, procesados, tratados y comunicados a terceros sin restricciones, en el registro o banco de datos SICOM (sistema de morosidades y Protestos DICOM). Esta autorización tiene el carácter de permanente, pudiendo ser revocada, sin efecto retroactivo y con fecha no anterior al último documento de pago emitido 



Décimo Tercero: La vigencia del presente Contrato de Prestación de Servicios Educacionales es exclusivamente por el período académico definido en la cláusula segunda de este instrumento. Su renovación por parte del Establecimiento Educacional estará sujeta al estricto cumplimiento por parte del alumno/a de lo establecido en los reglamentos institucionales y, especialmente, en lo relativo al cumplimiento de las obligaciones pecuniarias por parte del padre, madre o apoderado para con el Establecimiento Educacional. Para que el/la alumno/a pueda conservar su calidad de alumno regular del Colegio Winterhill, su padre y/o apoderado/a tendrá la obligación de suscribir, dentro de los plazos fijados por la CORPORACIÓN, el nuevo Contrato de Prestación de Servicios Educacionales. correspondiente al periodo académico siguiente. 




Décimo Cuarto: Tanto el/la estudiante como el apoderado/a declaran conocer y aceptar los principios que inspiran la misión y objetivos del Colegio Winterhill como, asimismo, las disposiciones reglamentarias del Reglamento General del Alumno y del Reglamento Interno del establecimiento. 


Décimo Quinto: En caso que el/la estudiante cause daños materiales al patrimonio de la CORPORACIÓN o del Colegio Winterhill, su padre y/o apoderado/a deberá pagar la reparación o reposición de los daños causados, sin perjuicio de las sanciones que puedan corresponder al alumno en conformidad a la reglamentación interna del Colegio. Será responsabilidad exclusiva del estudiante el cuidado de sus útiles y efectos personales que introduzca al recinto del Colegio, entendiéndose que éste, sus docentes y/o trabajadores, no asumen responsabilidad alguna por su eventual hurto, extravia o deterioro por cualquier causa. 



Décimo Sexto: EI/LA APODERADO/A declara que el estudiante individualizado en este contrato tiene salud compatible con el régimen de estudios del ESTABLECIMIENTO Colegio Winterhill. En caso de sufrir el/la estudiante algún accidente o problema de salud durante su permanencia en el Colegio, éste proporcionará todos los medios a su alcance para superar la emergencia y asegurar el pronto traslado del estudiante al establecimiento asistencial que corresponda, sin que ello implique asumir responsabilidad institucional ni económica por los hechos que motivaren la atención de emergencia. EI ESTABLECIMIENTO facilitará todos los trámites correspondientes al Seguro de Accidente Escolar al que tiene derecho todo alumno regular de instituciones reconocidas por el Ministerio de Educación. 




Décimo Séptimo: EL/LA APODERADO/A declara conocer el manual de convivencia escolar y los protocolos internos del Colegio Winterhill; asimismo, LA CORPORACIÓN da cuenta que éstos se encuentran disponibles en la página web 

http://colegiowinterhill.cl/Website/index.php/protocolos. Igualmente, las partes acuerdan que dichos documentos serán enviados por LA CORPORACIÓN al siguiente: correo electrónico que indica EL/LA APODERADO/ 



Décimo Octavo: Queda un ejemplar del presente contrato en poder de la CORPORACIÓN y otro en poder del apoderad/a quienes, por el hecho de suscribirlo, expresan su plena conformidad con el contenido del mismo. 

APODERADO/A
RUT: 

CORPORACIÓN EDUCACIONAL WINTERHILL
RUT: 65.152.884-4 $$,
  jsonb_build_array(
    'guardian_full_name','guardian_run','guardian_address','guardian_email','guardian_phone',
    'year','students_table','colegiatura_anual','cantidad_cuotas','monto_cuota','dia_vencimiento'
  ),
  true
)
ON CONFLICT (type, version) DO NOTHING;

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [8/49] MIGRATION: 20250925_ensure_profile_for_current_user
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

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

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [9/49] MIGRATION: 20250925_guardian_auto_onboarding
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Guardian Auto-Onboarding & Student Self-Service Helpers
-- Date: 2025-09-25
-- Purpose: Automatizar la creación del registro en guardians al crear perfil (usuario) y
-- proveer funciones para garantizar existencia de apoderado y creación segura de estudiantes.

BEGIN;

-- 1. Function: ensure_guardian_for_user
-- Crea un registro en guardians si no existe para el usuario actual (auth.uid())
-- Retorna el id del guardian.
-- Drop ALL existing overloads to avoid ambiguity
DO $$
BEGIN
    -- Drop no-arg version if exists
    DROP FUNCTION IF EXISTS public.ensure_guardian_for_user();
    -- Drop uuid-arg version if exists
    DROP FUNCTION IF EXISTS public.ensure_guardian_for_user(uuid);
END $$;

CREATE OR REPLACE FUNCTION public.ensure_guardian_for_user(p_user_id uuid DEFAULT auth.uid())
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_guardian_id uuid;
    v_email text;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'ensure_guardian_for_user: p_user_id no puede ser NULL';
    END IF;

    -- Buscar si ya existe guardian
    SELECT id INTO v_guardian_id FROM public.guardians WHERE owner_id = p_user_id LIMIT 1;
    IF v_guardian_id IS NOT NULL THEN
        RETURN v_guardian_id; -- Ya existe
    END IF;

    -- Intentar tomar email desde profiles (si existe)
    SELECT email INTO v_email FROM public.profiles WHERE id = p_user_id;

    -- Crear guardian mínimo
    INSERT INTO public.guardians (owner_id, email)
    VALUES (p_user_id, v_email)
    RETURNING id INTO v_guardian_id;

    RETURN v_guardian_id;
END;
$$;

COMMENT ON FUNCTION public.ensure_guardian_for_user(uuid) IS 'Garantiza la existencia de un guardian para el usuario dado y retorna su id.';

-- 2. Trigger: auto crear guardian al insertar profile (si no existe)
CREATE OR REPLACE FUNCTION public.trg_auto_create_guardian()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    -- Evitar doble creación: sólo si no existe ya
    PERFORM 1 FROM public.guardians WHERE owner_id = NEW.id;
    IF NOT FOUND THEN
        -- Reutiliza la lógica existente
        PERFORM public.ensure_guardian_for_user(NEW.id);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_auto_guardian ON public.profiles;
CREATE TRIGGER trg_profiles_auto_guardian
AFTER INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.trg_auto_create_guardian();

COMMENT ON TRIGGER trg_profiles_auto_guardian ON public.profiles IS 'Crea automáticamente un guardian asociado al nuevo usuario/perfil.';

-- 3. Function: guardian_add_student
-- Permite que el usuario autenticado cree un nuevo estudiante y lo asocie consigo mismo.
-- Valida que el usuario tenga guardian. Retorna el id del estudiante creado.
CREATE OR REPLACE FUNCTION public.guardian_add_student(
    p_whole_name text,
    p_run text,
    p_extra jsonb DEFAULT '{}'::jsonb
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_guardian_id uuid;
    v_student_id uuid;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'guardian_add_student: usuario no autenticado';
    END IF;

    -- Asegurar guardian
    v_guardian_id := public.ensure_guardian_for_user(auth.uid());

    -- Evitar duplicado por RUN (suave): si ya existe alumno con ese run y relación, retornar existente
    IF p_run IS NOT NULL THEN
        SELECT s.id INTO v_student_id
        FROM public.students s
        JOIN public.student_guardian sg ON sg.student_id = s.id
        WHERE s.run = p_run AND sg.guardian_id = v_guardian_id
        LIMIT 1;
    END IF;
    IF v_student_id IS NOT NULL THEN
        RETURN v_student_id; -- ya existe asociado
    END IF;

    -- Crear estudiante (ajusta columnas reales según tu tabla students)
    INSERT INTO public.students (whole_name, run, meta)
    VALUES (p_whole_name, p_run, COALESCE(p_extra, '{}'::jsonb))
    RETURNING id INTO v_student_id;

    -- Asociar
    INSERT INTO public.student_guardian (student_id, guardian_id)
    VALUES (v_student_id, v_guardian_id)
    ON CONFLICT DO NOTHING;

    RETURN v_student_id;
END;
$$;

COMMENT ON FUNCTION public.guardian_add_student(text, text, jsonb) IS 'Crea un estudiante y lo vincula al guardian del usuario autenticado.';

-- Nota: Ajustar si la tabla students NO tiene columna meta. Quitar meta del insert en tal caso.

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [10/49] MIGRATION: 20250925_guardian_claim_flow
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Guardian Claim Flow Migration (Option E)
-- Creates utilities to sanitize and validate RUN, logging table, and claim_guardian_by_run function.

-- 1. Helper function: sanitize_run
CREATE OR REPLACE FUNCTION public.sanitize_run(input text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  cleaned text;
BEGIN
  IF input IS NULL THEN RETURN NULL; END IF;
  cleaned := upper(regexp_replace(input, '[^0-9kK]', '', 'g'));
  RETURN cleaned;
END;
$$;

-- 2. Helper function: validate_run (Chile RUT DV algorithm)
CREATE OR REPLACE FUNCTION public.validate_run(input text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  run text := sanitize_run(input);
  body text;
  dv_input text;
  sum_val int := 0;
  multiplier int := 2;
  digit char;
  computed_dv text;
  remainder int;
BEGIN
  IF run IS NULL OR length(run) < 2 THEN RETURN FALSE; END IF;
  body := substring(run from 1 for length(run)-1);
  dv_input := substring(run from length(run));
  -- Compute DV
  FOR digit IN SELECT reverse_chars FROM regexp_split_to_table(reverse(body), '') AS reverse_chars LOOP
    IF digit ~ '[0-9]' THEN
      sum_val := sum_val + (cast(digit as int) * multiplier);
      multiplier := multiplier + 1;
      IF multiplier > 7 THEN multiplier := 2; END IF;
    END IF;
  END LOOP;
  remainder := 11 - (sum_val % 11);
  IF remainder = 11 THEN
    computed_dv := '0';
  ELSIF remainder = 10 THEN
    computed_dv := 'K';
  ELSE
    computed_dv := remainder::text;
  END IF;
  RETURN upper(dv_input) = upper(computed_dv);
END;
$$;

-- 3. Logging table
CREATE TABLE IF NOT EXISTS public.guardian_claim_logs (
  id bigserial PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  input_run text,
  normalized_run text,
  status text NOT NULL,
  message text,
  guardian_id uuid REFERENCES public.guardians(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- 4. Functional unique index for normalized RUN on guardians (if not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='guardians_normalized_run_unique'
  ) THEN
    CREATE UNIQUE INDEX guardians_normalized_run_unique ON public.guardians ( upper(regexp_replace(coalesce(run,''),'[^0-9kK]','','g')) );
  END IF;
END;
$$;

-- 5. Claim function
CREATE OR REPLACE FUNCTION public.claim_guardian_by_run(input_run text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  normalized text := sanitize_run(input_run);
  current_user_id uuid := auth.uid();
  existing_guardian record;
  claim_status text;
  result jsonb;
  role_current text;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Validate RUN format & DV
  IF NOT validate_run(normalized) THEN
    claim_status := 'INVALID_RUN';
    INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message)
    VALUES (current_user_id, input_run, normalized, claim_status, 'Invalid RUN / DV');
    RETURN jsonb_build_object('status', claim_status, 'message', 'RUN inválido');
  END IF;

  -- Check if a guardian with this RUN already exists
  SELECT g.* INTO existing_guardian
  FROM public.guardians g
  WHERE upper(regexp_replace(coalesce(g.run,''),'[^0-9K]','','g')) = upper(normalized)
  LIMIT 1;

  -- Get current profile role
  SELECT role INTO role_current FROM public.profiles WHERE id = current_user_id;

  IF existing_guardian IS NOT NULL THEN
    IF existing_guardian.owner_id = current_user_id THEN
      claim_status := 'ALREADY_LINKED';
      INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message, guardian_id)
      VALUES (current_user_id, input_run, normalized, claim_status, 'Already linked to this guardian', existing_guardian.id);
      RETURN jsonb_build_object('status', claim_status, 'guardian_id', existing_guardian.id, 'message', 'Ya estabas vinculado.');
    ELSIF existing_guardian.owner_id IS NOT NULL AND existing_guardian.owner_id <> current_user_id THEN
      claim_status := 'ALREADY_CLAIMED';
      INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message, guardian_id)
      VALUES (current_user_id, input_run, normalized, claim_status, 'RUN already claimed by another user', existing_guardian.id);
      RETURN jsonb_build_object('status', claim_status, 'message', 'RUN ya reclamado por otro usuario');
    ELSE
      -- Guardian exists but unowned -> claim it
      UPDATE public.guardians
        SET owner_id = current_user_id, updated_at = now()
      WHERE id = existing_guardian.id;
      claim_status := 'CLAIMED_EXISTING';
      -- Assign guardian role if profile has no role or different (basic rule: prefer admin if already admin)
      IF role_current IS NULL OR role_current = '' THEN
        UPDATE public.profiles SET role = 'guardian', updated_at = now() WHERE id = current_user_id;
      END IF;
      INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message, guardian_id)
      VALUES (current_user_id, input_run, normalized, claim_status, 'Claimed existing unowned guardian', existing_guardian.id);
      RETURN jsonb_build_object('status', claim_status, 'guardian_id', existing_guardian.id, 'message', 'Reclamado con éxito');
    END IF;
  ELSE
    -- Create new guardian record
    INSERT INTO public.guardians (id, owner_id, run, needs_update, created_at, updated_at)
    VALUES (gen_random_uuid(), current_user_id, normalized, true, now(), now())
    RETURNING * INTO existing_guardian;
    claim_status := 'CREATED_NEW';
    IF role_current IS NULL OR role_current = '' THEN
      UPDATE public.profiles SET role = 'guardian', updated_at = now() WHERE id = current_user_id;
    END IF;
    INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message, guardian_id)
    VALUES (current_user_id, input_run, normalized, claim_status, 'Created new guardian');
    RETURN jsonb_build_object('status', claim_status, 'guardian_id', existing_guardian.id, 'created', true, 'message', 'Nuevo apoderado creado');
  END IF;
END;
$$;

-- 6. RLS considerations (assuming guardians table already protected by RLS). Ensure function runs with SECURITY DEFINER and limited search_path.

COMMENT ON FUNCTION public.claim_guardian_by_run(text) IS 'Claims or creates a guardian record by RUN, validates DV, logs the attempt, and assigns guardian role.';



-- ######################################################################
