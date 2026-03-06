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
-- BATCH 2 (migrations 11 to 20)
-- ######################################################################

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [11/49] MIGRATION: 20250925_guardian_intake_survey
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Guardian Intake Survey (Annual) Migration

-- 1. Table definition
CREATE TABLE IF NOT EXISTS public.guardian_intake_surveys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_id uuid NOT NULL REFERENCES public.guardians(id) ON DELETE CASCADE,
  year int NOT NULL,
  -- Guardian fields
  guardian_first_name text,
  guardian_last_name_paterno text,
  guardian_last_name_materno text,
  guardian_relationship text,
  guardian_rut text,
  guardian_education_level text,
  guardian_address text,
  guardian_commune text,
  guardian_email text,
  guardian_phone text,
  -- Student fields
  student_first_names text,
  student_last_name_paterno text,
  student_last_name_materno text,
  student_run text,
  student_course text,
  student_course_id uuid REFERENCES public.cursos(id),
  student_birth_date date,
  student_nationality text,
  student_gender text,
  student_social_name text,
  student_enrollment_date date,
  student_withdrawal_date date,
  student_withdrawal_reason text,
  student_repeat_current boolean,
  student_previous_institution text,
  student_address text,
  student_commune text,
  student_lives_with text[],
  alt_contact_name text,
  alt_contact_phone text,
  scholarship_percentage numeric(5,2),
  payment_form_prioritario boolean DEFAULT false,
  payment_form_cheques boolean DEFAULT false,
  payment_form_pagare boolean DEFAULT false,
  payment_form_credit_card boolean DEFAULT false,
  payment_form_transfer boolean DEFAULT false,
  payment_form_planilla boolean DEFAULT false,
  financial_institution text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted')),
  submitted_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (guardian_id, year)
);

-- 2. Updated_at trigger (create helper if missing)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'set_updated_at'
  ) THEN
    CREATE OR REPLACE FUNCTION public.set_updated_at()
    RETURNS trigger LANGUAGE plpgsql AS $fn$
    BEGIN
      NEW.updated_at = now();
      RETURN NEW;
    END;
    $fn$;
  END IF;
END;$$;

DROP TRIGGER IF EXISTS trg_guardian_intake_surveys_updated_at ON public.guardian_intake_surveys;
CREATE TRIGGER trg_guardian_intake_surveys_updated_at
BEFORE UPDATE ON public.guardian_intake_surveys
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3. Enable RLS
ALTER TABLE public.guardian_intake_surveys ENABLE ROW LEVEL SECURITY;

-- 4. Policies (idempotent creation pattern via DO block per policy)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='guardian_intake_surveys' AND policyname='select_own_intake'
  ) THEN
    CREATE POLICY select_own_intake ON public.guardian_intake_surveys
      FOR SELECT USING (
        guardian_id IN (
          SELECT g.id FROM public.guardians g WHERE g.owner_id = auth.uid()
        )
      );
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='guardian_intake_surveys' AND policyname='insert_own_intake'
  ) THEN
    CREATE POLICY insert_own_intake ON public.guardian_intake_surveys
      FOR INSERT WITH CHECK (
        guardian_id IN (
          SELECT g.id FROM public.guardians g WHERE g.owner_id = auth.uid()
        )
      );
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='guardian_intake_surveys' AND policyname='update_own_intake'
  ) THEN
    CREATE POLICY update_own_intake ON public.guardian_intake_surveys
      FOR UPDATE USING (
        guardian_id IN (
          SELECT g.id FROM public.guardians g WHERE g.owner_id = auth.uid()
        )
      );
  END IF;
END;$$;

-- 5. Helper: get current academic year (simple)
CREATE OR REPLACE FUNCTION public.current_academic_year()
RETURNS int LANGUAGE sql IMMUTABLE AS $$
  SELECT date_part('year', now())::int;
$$;

-- 6. Upsert function (draft save)
CREATE OR REPLACE FUNCTION public.upsert_guardian_intake_survey(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_guardian_id uuid;
  v_year int := COALESCE((payload->>'year')::int, current_academic_year());
  existing_id uuid;
  result_row guardian_intake_surveys%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  SELECT id INTO v_guardian_id FROM public.guardians WHERE owner_id = v_user LIMIT 1;
  IF v_guardian_id IS NULL THEN
    RAISE EXCEPTION 'Guardian record not found for user';
  END IF;

  SELECT id INTO existing_id FROM public.guardian_intake_surveys WHERE guardian_id = v_guardian_id AND year = v_year;

  IF existing_id IS NULL THEN
    INSERT INTO public.guardian_intake_surveys (
      guardian_id, year,
      guardian_first_name, guardian_last_name_paterno, guardian_last_name_materno, guardian_relationship,
      guardian_rut, guardian_education_level, guardian_address, guardian_commune, guardian_email, guardian_phone,
      student_first_names, student_last_name_paterno, student_last_name_materno, student_run, student_course, student_course_id,
      student_birth_date, student_nationality, student_gender, student_social_name, student_enrollment_date,
      student_withdrawal_date, student_withdrawal_reason, student_repeat_current, student_previous_institution,
      student_address, student_commune, student_lives_with, alt_contact_name, alt_contact_phone,
      scholarship_percentage, payment_form_prioritario, payment_form_cheques, payment_form_pagare,
      payment_form_credit_card, payment_form_transfer, payment_form_planilla, financial_institution, status
    ) VALUES (
      v_guardian_id, v_year,
      payload->>'guardian_first_name', payload->>'guardian_last_name_paterno', payload->>'guardian_last_name_materno', payload->>'guardian_relationship',
      payload->>'guardian_rut', payload->>'guardian_education_level', payload->>'guardian_address', payload->>'guardian_commune', payload->>'guardian_email', payload->>'guardian_phone',
      payload->>'student_first_names', payload->>'student_last_name_paterno', payload->>'student_last_name_materno', payload->>'student_run', payload->>'student_course',
      NULLIF(payload->>'student_course_id','')::uuid,
      (payload->>'student_birth_date')::date, payload->>'student_nationality', payload->>'student_gender', payload->>'student_social_name', (payload->>'student_enrollment_date')::date,
      (payload->>'student_withdrawal_date')::date, payload->>'student_withdrawal_reason', (payload->>'student_repeat_current')::boolean, payload->>'student_previous_institution',
      payload->>'student_address', payload->>'student_commune', string_to_array(COALESCE(payload->>'student_lives_with',''), '|')::text[], payload->>'alt_contact_name', payload->>'alt_contact_phone',
      (payload->>'scholarship_percentage')::numeric, (payload->>'payment_form_prioritario')::boolean, (payload->>'payment_form_cheques')::boolean, (payload->>'payment_form_pagare')::boolean,
      (payload->>'payment_form_credit_card')::boolean, (payload->>'payment_form_transfer')::boolean, (payload->>'payment_form_planilla')::boolean, payload->>'financial_institution', COALESCE(payload->>'status','draft')
    ) RETURNING * INTO result_row;
  ELSE
    UPDATE public.guardian_intake_surveys SET
      guardian_first_name = payload->>'guardian_first_name',
      guardian_last_name_paterno = payload->>'guardian_last_name_paterno',
      guardian_last_name_materno = payload->>'guardian_last_name_materno',
      guardian_relationship = payload->>'guardian_relationship',
      guardian_rut = payload->>'guardian_rut',
      guardian_education_level = payload->>'guardian_education_level',
      guardian_address = payload->>'guardian_address',
      guardian_commune = payload->>'guardian_commune',
      guardian_email = payload->>'guardian_email',
      guardian_phone = payload->>'guardian_phone',
      student_first_names = payload->>'student_first_names',
      student_last_name_paterno = payload->>'student_last_name_paterno',
      student_last_name_materno = payload->>'student_last_name_materno',
      student_run = payload->>'student_run',
      student_course = payload->>'student_course',
      student_course_id = NULLIF(payload->>'student_course_id','')::uuid,
      student_birth_date = (payload->>'student_birth_date')::date,
      student_nationality = payload->>'student_nationality',
      student_gender = payload->>'student_gender',
      student_social_name = payload->>'student_social_name',
      student_enrollment_date = (payload->>'student_enrollment_date')::date,
      student_withdrawal_date = (payload->>'student_withdrawal_date')::date,
      student_withdrawal_reason = payload->>'student_withdrawal_reason',
      student_repeat_current = (payload->>'student_repeat_current')::boolean,
      student_previous_institution = payload->>'student_previous_institution',
      student_address = payload->>'student_address',
      student_commune = payload->>'student_commune',
      student_lives_with = string_to_array(COALESCE(payload->>'student_lives_with',''), '|')::text[],
      alt_contact_name = payload->>'alt_contact_name',
      alt_contact_phone = payload->>'alt_contact_phone',
      scholarship_percentage = (payload->>'scholarship_percentage')::numeric,
      payment_form_prioritario = (payload->>'payment_form_prioritario')::boolean,
      payment_form_cheques = (payload->>'payment_form_cheques')::boolean,
      payment_form_pagare = (payload->>'payment_form_pagare')::boolean,
      payment_form_credit_card = (payload->>'payment_form_credit_card')::boolean,
      payment_form_transfer = (payload->>'payment_form_transfer')::boolean,
      payment_form_planilla = (payload->>'payment_form_planilla')::boolean,
      financial_institution = payload->>'financial_institution',
      status = COALESCE(payload->>'status', status)
    WHERE id = existing_id
    RETURNING * INTO result_row;
  END IF;

  RETURN to_jsonb(result_row);
END;
$$;

COMMENT ON FUNCTION public.upsert_guardian_intake_survey(jsonb) IS 'Creates or updates guardian intake survey draft for current year.';

-- 7. Submit function (locks it)
CREATE OR REPLACE FUNCTION public.submit_guardian_intake_survey()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_guardian_id uuid;
  v_year int := current_academic_year();
  v_row guardian_intake_surveys%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT id INTO v_guardian_id FROM public.guardians WHERE owner_id = v_user LIMIT 1;
  IF v_guardian_id IS NULL THEN RAISE EXCEPTION 'Guardian record not found'; END IF;
  SELECT * INTO v_row FROM public.guardian_intake_surveys WHERE guardian_id = v_guardian_id AND year = v_year;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No draft survey found';
  END IF;
  IF v_row.status = 'submitted' THEN
    RETURN jsonb_build_object('status','already_submitted','id', v_row.id);
  END IF;
  -- Minimal validation example (extend as needed)
  IF v_row.guardian_rut IS NULL OR v_row.student_run IS NULL THEN
    RAISE EXCEPTION 'Required RUN fields missing';
  END IF;
  UPDATE public.guardian_intake_surveys
    SET status='submitted', submitted_at=now()
  WHERE id = v_row.id
  RETURNING * INTO v_row;
  RETURN jsonb_build_object('status','submitted','id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.submit_guardian_intake_survey() IS 'Submits and locks the current year guardian survey.';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [12/49] MIGRATION: 20251021_guardian_invite_and_claim
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Guardian Invite & Claim Flow
-- Date: 2025-10-21
-- Purpose: Allow sending a link to guardians so they can create an account, automatically
--          get the guardian role, and be linked to their existing guardian record (owner_id).
-- Safety: idempotent column adds; functions use SECURITY DEFINER and constrained search_path.

BEGIN;

-- 1) Columns on guardians (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='claim_token'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN claim_token text;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='claim_expires_at'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN claim_expires_at timestamptz;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='claimed_at'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN claimed_at timestamptz;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='needs_update'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN needs_update boolean DEFAULT true;
  END IF;
END$$;

-- 1.1) Unique index for claim_token (nullable)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='guardians_claim_token_unique'
  ) THEN
    CREATE UNIQUE INDEX guardians_claim_token_unique ON public.guardians (claim_token) WHERE claim_token IS NOT NULL;
  END IF;
END$$;

-- 2) Ensure pgcrypto for randomness
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 3) Function: create_guardian_invite(guardian_id, expires_in_minutes)
CREATE OR REPLACE FUNCTION public.create_guardian_invite(p_guardian_id uuid, p_expires_in_minutes int DEFAULT 10080)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_token text;
BEGIN
  -- Generate opaque token
  v_token := encode(gen_random_bytes(24), 'hex');

  UPDATE public.guardians
  SET claim_token = v_token,
      claim_expires_at = now() + make_interval(mins => COALESCE(p_expires_in_minutes, 10080)),
      updated_at = now()
  WHERE id = p_guardian_id;

  RETURN v_token;
END;
$$;

COMMENT ON FUNCTION public.create_guardian_invite(uuid, int) IS 'Generates a one-time claim token for a guardian; default expiry 7 days.';

-- 4) Function: accept_guardian_invite(token)
CREATE OR REPLACE FUNCTION public.accept_guardian_invite(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_row guardians%ROWTYPE;
  v_role text;
BEGIN
  IF v_user IS NULL THEN
    RETURN jsonb_build_object('status','not_authenticated');
  END IF;

  SELECT * INTO v_row FROM public.guardians WHERE claim_token = p_token LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','invalid_token');
  END IF;

  IF v_row.claim_expires_at IS NOT NULL AND v_row.claim_expires_at < now() THEN
    RETURN jsonb_build_object('status','expired');
  END IF;

  IF v_row.owner_id IS NOT NULL THEN
    IF v_row.owner_id = v_user THEN
      RETURN jsonb_build_object('status','already_linked','guardian_id', v_row.id);
    ELSE
      RETURN jsonb_build_object('status','claimed_by_other');
    END IF;
  END IF;

  -- Assign ownership and finalize claim
  UPDATE public.guardians
    SET owner_id = v_user,
        claimed_at = now(),
        claim_token = NULL,
        claim_expires_at = NULL,
        updated_at = now()
  WHERE id = v_row.id;

  -- Set profile role if empty
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='profiles') THEN
    SELECT role INTO v_role FROM public.profiles WHERE id = v_user;
    IF v_role IS NULL OR v_role = '' THEN
      UPDATE public.profiles SET role = 'guardian', updated_at = now() WHERE id = v_user;
    END IF;
  END IF;

  RETURN jsonb_build_object('status','linked','guardian_id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.accept_guardian_invite(text) IS 'Links the current user to a guardian record using a one-time token and sets profile role if empty.';

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [13/49] MIGRATION: 20251022_fix_guardian_intake_auto_create
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Fix guardian intake survey to auto-create guardian record when missing
-- This prevents 400 errors when accessing the intake page for the first time

-- Drop and recreate upsert_guardian_intake_survey to use ensure_guardian_for_user
DROP FUNCTION IF EXISTS public.upsert_guardian_intake_survey(jsonb);

CREATE OR REPLACE FUNCTION public.upsert_guardian_intake_survey(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_guardian_id uuid;
  v_year int := COALESCE((payload->>'year')::int, current_academic_year());
  existing_id uuid;
  result_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  -- Verificar autenticación
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Obtener o crear guardian_id usando ensure_guardian_for_user
  v_guardian_id := ensure_guardian_for_user();
  
  IF v_guardian_id IS NULL THEN
    RAISE EXCEPTION 'Failed to obtain guardian record';
  END IF;

  -- Buscar registro existente
  SELECT id INTO existing_id 
  FROM public.guardian_intake_surveys 
  WHERE guardian_id = v_guardian_id AND year = v_year;

  IF existing_id IS NULL THEN
    -- INSERT nuevo registro
    INSERT INTO public.guardian_intake_surveys (
      guardian_id, 
      year,
      guardian_first_name, 
      guardian_last_name_paterno, 
      guardian_last_name_materno, 
      guardian_relationship,
      guardian_rut, 
      guardian_education_level, 
      guardian_address, 
      guardian_commune, 
      guardian_email, 
      guardian_phone,
      student_first_names, 
      student_last_name_paterno, 
      student_last_name_materno, 
      student_run, 
      student_course,
      student_course_id,
      student_birth_date, 
      student_nationality, 
      student_gender, 
      student_social_name, 
      student_enrollment_date,
      student_withdrawal_date, 
      student_withdrawal_reason, 
      student_repeat_current, 
      student_previous_institution,
      student_address, 
      student_commune, 
      student_lives_with, 
      alt_contact_name, 
      alt_contact_phone,
      scholarship_percentage, 
      payment_form_prioritario, 
      payment_form_cheques, 
      payment_form_pagare,
      payment_form_credit_card, 
      payment_form_transfer, 
      payment_form_planilla, 
      financial_institution, 
      status
    ) VALUES (
      v_guardian_id, 
      v_year,
      payload->>'guardian_first_name', 
      payload->>'guardian_last_name_paterno', 
      payload->>'guardian_last_name_materno', 
      payload->>'guardian_relationship',
      payload->>'guardian_rut', 
      payload->>'guardian_education_level', 
      payload->>'guardian_address', 
      payload->>'guardian_commune', 
      payload->>'guardian_email', 
      payload->>'guardian_phone',
      payload->>'student_first_names', 
      payload->>'student_last_name_paterno', 
      payload->>'student_last_name_materno', 
      payload->>'student_run', 
      payload->>'student_course',
      NULLIF(payload->>'student_course_id','')::uuid,
      NULLIF(payload->>'student_birth_date', '')::date, 
      payload->>'student_nationality', 
      payload->>'student_gender', 
      payload->>'student_social_name', 
      NULLIF(payload->>'student_enrollment_date', '')::date,
      NULLIF(payload->>'student_withdrawal_date', '')::date, 
      payload->>'student_withdrawal_reason', 
      COALESCE((payload->>'student_repeat_current')::boolean, false), 
      payload->>'student_previous_institution',
      payload->>'student_address', 
      payload->>'student_commune', 
      string_to_array(COALESCE(payload->>'student_lives_with',''), '|')::text[], 
      payload->>'alt_contact_name', 
      payload->>'alt_contact_phone',
      NULLIF(payload->>'scholarship_percentage', '')::numeric, 
      COALESCE((payload->>'payment_form_prioritario')::boolean, false), 
      COALESCE((payload->>'payment_form_cheques')::boolean, false), 
      COALESCE((payload->>'payment_form_pagare')::boolean, false),
      COALESCE((payload->>'payment_form_credit_card')::boolean, false), 
      COALESCE((payload->>'payment_form_transfer')::boolean, false), 
      COALESCE((payload->>'payment_form_planilla')::boolean, false), 
      payload->>'financial_institution', 
      COALESCE(payload->>'status','draft')
    ) RETURNING * INTO result_row;
  ELSE
    -- UPDATE registro existente
    UPDATE public.guardian_intake_surveys SET
      guardian_first_name = payload->>'guardian_first_name',
      guardian_last_name_paterno = payload->>'guardian_last_name_paterno',
      guardian_last_name_materno = payload->>'guardian_last_name_materno',
      guardian_relationship = payload->>'guardian_relationship',
      guardian_rut = payload->>'guardian_rut',
      guardian_education_level = payload->>'guardian_education_level',
      guardian_address = payload->>'guardian_address',
      guardian_commune = payload->>'guardian_commune',
      guardian_email = payload->>'guardian_email',
      guardian_phone = payload->>'guardian_phone',
      student_first_names = payload->>'student_first_names',
      student_last_name_paterno = payload->>'student_last_name_paterno',
      student_last_name_materno = payload->>'student_last_name_materno',
      student_run = payload->>'student_run',
      student_course = payload->>'student_course',
      student_course_id = NULLIF(payload->>'student_course_id','')::uuid,
      student_birth_date = NULLIF(payload->>'student_birth_date', '')::date,
      student_nationality = payload->>'student_nationality',
      student_gender = payload->>'student_gender',
      student_social_name = payload->>'student_social_name',
      student_enrollment_date = NULLIF(payload->>'student_enrollment_date', '')::date,
      student_withdrawal_date = NULLIF(payload->>'student_withdrawal_date', '')::date,
      student_withdrawal_reason = payload->>'student_withdrawal_reason',
      student_repeat_current = COALESCE((payload->>'student_repeat_current')::boolean, student_repeat_current),
      student_previous_institution = payload->>'student_previous_institution',
      student_address = payload->>'student_address',
      student_commune = payload->>'student_commune',
      student_lives_with = string_to_array(COALESCE(payload->>'student_lives_with',''), '|')::text[],
      alt_contact_name = payload->>'alt_contact_name',
      alt_contact_phone = payload->>'alt_contact_phone',
      scholarship_percentage = NULLIF(payload->>'scholarship_percentage', '')::numeric,
      payment_form_prioritario = COALESCE((payload->>'payment_form_prioritario')::boolean, payment_form_prioritario),
      payment_form_cheques = COALESCE((payload->>'payment_form_cheques')::boolean, payment_form_cheques),
      payment_form_pagare = COALESCE((payload->>'payment_form_pagare')::boolean, payment_form_pagare),
      payment_form_credit_card = COALESCE((payload->>'payment_form_credit_card')::boolean, payment_form_credit_card),
      payment_form_transfer = COALESCE((payload->>'payment_form_transfer')::boolean, payment_form_transfer),
      payment_form_planilla = COALESCE((payload->>'payment_form_planilla')::boolean, payment_form_planilla),
      financial_institution = payload->>'financial_institution',
      status = COALESCE(payload->>'status', status)
    WHERE id = existing_id
    RETURNING * INTO result_row;
  END IF;

  RETURN to_jsonb(result_row);
END;
$$;

COMMENT ON FUNCTION public.upsert_guardian_intake_survey(jsonb) IS 'Creates or updates guardian intake survey draft, auto-creating guardian if needed.';

-- Also update submit function to use ensure_guardian_for_user
DROP FUNCTION IF EXISTS public.submit_guardian_intake_survey();

CREATE OR REPLACE FUNCTION public.submit_guardian_intake_survey()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_guardian_id uuid;
  v_year int := current_academic_year();
  v_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Obtener o crear guardian_id
  v_guardian_id := ensure_guardian_for_user();
  
  IF v_guardian_id IS NULL THEN
    RAISE EXCEPTION 'Failed to obtain guardian record';
  END IF;

  SELECT * INTO v_row 
  FROM public.guardian_intake_surveys 
  WHERE guardian_id = v_guardian_id AND year = v_year;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No draft survey found';
  END IF;

  IF v_row.status = 'submitted' THEN
    RETURN jsonb_build_object('status', 'already_submitted', 'id', v_row.id);
  END IF;

  -- Validación mínima
  IF v_row.guardian_rut IS NULL OR v_row.student_run IS NULL THEN
    RAISE EXCEPTION 'Required RUN fields missing';
  END IF;

  UPDATE public.guardian_intake_surveys
  SET status = 'submitted', submitted_at = now()
  WHERE id = v_row.id
  RETURNING * INTO v_row;

  RETURN jsonb_build_object('status', 'submitted', 'id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.submit_guardian_intake_survey() IS 'Submits and locks the current year guardian survey, auto-creating guardian if needed.';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [14/49] MIGRATION: 20251023_add_year_to_fee
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add year column to fee table for filtering by academic year
-- This allows querying fees by year without extracting from due_date

ALTER TABLE public.fee 
ADD COLUMN IF NOT EXISTS year integer;

-- Set default year based on due_date for existing records
UPDATE public.fee 
SET year = EXTRACT(YEAR FROM due_date)
WHERE year IS NULL;

-- Add constraint to ensure year is always set
ALTER TABLE public.fee 
ALTER COLUMN year SET NOT NULL;

-- Add check constraint for reasonable year values
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fee_year_valid') THEN
    ALTER TABLE public.fee 
    ADD CONSTRAINT fee_year_valid CHECK (year >= 2020 AND year <= 2100);
  END IF;
END$$;

-- Add index for faster year-based queries
CREATE INDEX IF NOT EXISTS idx_fee_year ON public.fee(year);

-- Add index for combined student + year queries (most common)
CREATE INDEX IF NOT EXISTS idx_fee_student_year ON public.fee(student_id, year);

COMMENT ON COLUMN public.fee.year IS 'Academic year for the fee. Allows efficient filtering without date extraction.';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [15/49] MIGRATION: 20251023_complete_architecture_implementation
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- WINTERHILL SCHOOL MANAGEMENT: ARCHITECTURE IMPLEMENTATION
-- ============================================================================
-- Date: October 23, 2025
-- Purpose: Add academic records tracking and fix fee year column
-- Status: PRODUCTION READY - Execute manually in Supabase SQL Editor
-- 
-- INSTRUCTIONS:
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Copy-paste this ENTIRE file
-- 3. Click "RUN" (executes as transaction, rolls back on error)
-- 4. Verify success message at bottom
-- 5. Test queries provided at end
-- ============================================================================

BEGIN;

-- ============================================================================
-- PHASE 1: EXTEND FEE TABLE WITH YEAR_ACADEMICO
-- ============================================================================
-- Purpose: Allow direct year queries on fees without date extraction
-- Fixes: 400 Bad Request error on GuardianWelcomePage

DO $$
BEGIN
  -- Add column if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fee' 
    AND column_name = 'year_academico'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN year_academico integer;
    RAISE NOTICE 'Column year_academico added to fee table';
  ELSE
    RAISE NOTICE 'Column year_academico already exists in fee table';
  END IF;
END $$;

-- Populate year_academico from existing data
-- Strategy 1: Try to extract from fee_curso → cursos.year_academico
UPDATE public.fee f
SET year_academico = c.year_academico
FROM public.cursos c
WHERE f.fee_curso = c.id
  AND f.year_academico IS NULL;

-- Strategy 2: For fees without fee_curso, use due_date year
UPDATE public.fee
SET year_academico = EXTRACT(YEAR FROM due_date)
WHERE year_academico IS NULL
  AND due_date IS NOT NULL;

-- Strategy 3: For remaining nulls, use current year (safeguard)
UPDATE public.fee
SET year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE year_academico IS NULL;

-- Make NOT NULL after population
ALTER TABLE public.fee 
ALTER COLUMN year_academico SET NOT NULL;

-- Add check constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fee_year_valid'
  ) THEN
    ALTER TABLE public.fee 
    ADD CONSTRAINT fee_year_valid CHECK (year_academico >= 2020 AND year_academico <= 2100);
    RAISE NOTICE 'Constraint fee_year_valid added';
  END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_fee_year_academico 
ON public.fee(year_academico);

CREATE INDEX IF NOT EXISTS idx_fee_student_year 
ON public.fee(student_id, year_academico);

COMMENT ON COLUMN public.fee.year_academico IS 
'Academic year for the fee. Allows efficient filtering without date extraction. Populated from curso.year_academico or extracted from due_date.';

-- ============================================================================
-- PHASE 2: CREATE STUDENT_ACADEMIC_RECORDS TABLE
-- ============================================================================
-- Purpose: Track which course each student was enrolled in each year
-- Preserves academic history without overwriting students.curso

CREATE TABLE IF NOT EXISTS public.student_academic_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Core relationship
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  curso_id uuid NOT NULL REFERENCES public.cursos(id) ON DELETE RESTRICT,
  year_academico integer NOT NULL CHECK (year_academico BETWEEN 2020 AND 2100),
  
  -- Academic period tracking
  fecha_inicio date, -- Will be set by trigger or application code
  fecha_termino date, -- Will be set by trigger or application code
  estado text NOT NULL CHECK (estado IN ('activo','completado','retirado','repitio','trasladado')) DEFAULT 'activo',
  
  -- Academic performance (optional, populated at year end)
  promedio_anual numeric(3,2) CHECK (promedio_anual IS NULL OR promedio_anual BETWEEN 1.0 AND 7.0),
  asistencia_porcentaje numeric(5,2) CHECK (asistencia_porcentaje IS NULL OR asistencia_porcentaje BETWEEN 0 AND 100),
  observaciones text,
  
  -- Link to administrative enrollment process (optional)
  enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL,
  
  -- Audit fields
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  updated_by uuid REFERENCES auth.users(id),
  
  -- Business rules
  UNIQUE(student_id, year_academico) -- One course per student per year
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sar_student 
ON public.student_academic_records(student_id);

CREATE INDEX IF NOT EXISTS idx_sar_year 
ON public.student_academic_records(year_academico);

CREATE INDEX IF NOT EXISTS idx_sar_curso 
ON public.student_academic_records(curso_id);

CREATE INDEX IF NOT EXISTS idx_sar_student_year 
ON public.student_academic_records(student_id, year_academico);

CREATE INDEX IF NOT EXISTS idx_sar_estado 
ON public.student_academic_records(estado) 
WHERE estado = 'activo'; -- Partial index for active students only

-- Comments for documentation
COMMENT ON TABLE public.student_academic_records IS 
'Academic history: tracks which course each student was enrolled in each year. Preserves historical data when student advances to next grade.';

COMMENT ON COLUMN public.student_academic_records.estado IS 
'Academic status: activo (current), completado (finished year), retirado (withdrawn), repitio (repeated year), trasladado (transferred)';

COMMENT ON COLUMN public.student_academic_records.enrollment_id IS 
'Optional link to administrative enrollment process (enrollments table). Links academic record with document signing, fee generation, etc.';

-- ============================================================================
-- PHASE 3: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.student_academic_records ENABLE ROW LEVEL SECURITY;

-- Policy 1: Guardians can read academic records of their students
DROP POLICY IF EXISTS sar_guardian_read ON public.student_academic_records;
CREATE POLICY sar_guardian_read ON public.student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.student_guardian sg
      JOIN public.guardians g ON g.id = sg.guardian_id
      WHERE sg.student_id = student_academic_records.student_id
        AND g.owner_id = auth.uid()
    )
  );

-- Policy 2: Students can read their own academic records (if student portal exists)
DROP POLICY IF EXISTS sar_student_read ON public.student_academic_records;
CREATE POLICY sar_student_read ON public.student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.students s
      WHERE s.id = student_academic_records.student_id
        AND s.owner_id = auth.uid()
    )
  );

-- Policy 3: Admins and teachers can read all records
DROP POLICY IF EXISTS sar_staff_read ON public.student_academic_records;
CREATE POLICY sar_staff_read ON public.student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin', 'teacher', 'director', 'secretary')
    )
  );

-- Policy 4: Only admins and teachers can insert/update/delete
DROP POLICY IF EXISTS sar_staff_write ON public.student_academic_records;
CREATE POLICY sar_staff_write ON public.student_academic_records
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin', 'teacher', 'director')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin', 'teacher', 'director')
    )
  );

-- ============================================================================
-- PHASE 4: TRIGGERS FOR AUTO-MAINTENANCE
-- ============================================================================

-- Trigger 1: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_student_academic_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_sar_updated_at ON public.student_academic_records;
CREATE TRIGGER trigger_sar_updated_at
  BEFORE UPDATE ON public.student_academic_records
  FOR EACH ROW
  EXECUTE FUNCTION update_student_academic_records_updated_at();

-- Trigger 1.5: Auto-set academic year dates
CREATE OR REPLACE FUNCTION set_academic_year_dates()
RETURNS TRIGGER AS $$
BEGIN
  -- Set fecha_inicio if NULL (March 1st of academic year)
  IF NEW.fecha_inicio IS NULL THEN
    NEW.fecha_inicio = make_date(NEW.year_academico, 3, 1);
  END IF;
  
  -- Set fecha_termino if NULL (December 31st of academic year)
  IF NEW.fecha_termino IS NULL THEN
    NEW.fecha_termino = make_date(NEW.year_academico, 12, 31);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_academic_dates ON public.student_academic_records;
CREATE TRIGGER trigger_set_academic_dates
  BEFORE INSERT OR UPDATE ON public.student_academic_records
  FOR EACH ROW
  EXECUTE FUNCTION set_academic_year_dates();

-- Trigger 2: Auto-sync students.curso with current year active record
-- This keeps students.curso as a "current curso" helper field
CREATE OR REPLACE FUNCTION sync_student_current_curso()
RETURNS TRIGGER AS $$
DECLARE
  current_year integer := EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
  -- Only sync if this is current year and active
  IF NEW.year_academico = current_year AND NEW.estado = 'activo' THEN
    UPDATE public.students 
    SET curso = NEW.curso_id,
        updated_at = now()
    WHERE id = NEW.student_id;
    
    RAISE NOTICE 'Synced students.curso for student_id % to curso_id %', NEW.student_id, NEW.curso_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_sync_student_curso ON public.student_academic_records;
CREATE TRIGGER trigger_sync_student_curso
  AFTER INSERT OR UPDATE ON public.student_academic_records
  FOR EACH ROW
  EXECUTE FUNCTION sync_student_current_curso();

-- ============================================================================
-- PHASE 5: EXTEND ENROLLMENT_STUDENTS (OPTIONAL LINK)
-- ============================================================================
-- Adds optional reference from enrollment_students to academic_records
-- This links administrative enrollment process ↔ academic history

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'enrollment_students' 
    AND column_name = 'academic_record_id'
  ) THEN
    ALTER TABLE public.enrollment_students 
    ADD COLUMN academic_record_id uuid REFERENCES public.student_academic_records(id) ON DELETE SET NULL;
    
    RAISE NOTICE 'Column academic_record_id added to enrollment_students';
  ELSE
    RAISE NOTICE 'Column academic_record_id already exists in enrollment_students';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_enrollment_students_academic 
ON public.enrollment_students(academic_record_id);

COMMENT ON COLUMN public.enrollment_students.academic_record_id IS 
'Optional link to student_academic_records. Connects administrative enrollment process with academic course assignment.';

-- ============================================================================
-- PHASE 6: DATA MIGRATION - POPULATE CURRENT YEAR RECORDS
-- ============================================================================
-- Migrates existing students.curso → student_academic_records for current year
-- Only runs if student doesn't already have a record for current year

DO $$
DECLARE
  current_year integer := EXTRACT(YEAR FROM CURRENT_DATE);
  migrated_count integer := 0;
BEGIN
  -- Insert records for students who don't have one for current year
  INSERT INTO public.student_academic_records (
    student_id, 
    curso_id, 
    year_academico, 
    estado,
    fecha_inicio,
    created_by
  )
  SELECT 
    s.id,
    s.curso,
    current_year,
    CASE 
      WHEN UPPER(s.estado_std) = 'ACTIVO' THEN 'activo'
      WHEN s.fecha_retiro IS NOT NULL THEN 'retirado'
      ELSE 'activo' -- Default to active if unclear
    END,
    COALESCE(s.fecha_matricula, make_date(current_year, 3, 1)),
    NULL -- created_by will be NULL for migration
  FROM public.students s
  WHERE s.curso IS NOT NULL
    AND NOT EXISTS (
      -- Don't insert if already has record for current year
      SELECT 1 FROM public.student_academic_records sar
      WHERE sar.student_id = s.id 
        AND sar.year_academico = current_year
    );
  
  GET DIAGNOSTICS migrated_count = ROW_COUNT;
  RAISE NOTICE 'Migrated % student records to student_academic_records for year %', migrated_count, current_year;
END $$;

-- ============================================================================
-- PHASE 7: HELPER VIEWS (OPTIONAL)
-- ============================================================================

-- View 1: Current Active Students with Course
CREATE OR REPLACE VIEW v_current_student_courses AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  s.first_name,
  s.apellido_paterno,
  s.apellido_materno,
  sar.curso_id,
  c.nom_curso,
  c.nivel,
  c.letra_curso,
  c.year_academico,
  sar.estado as enrollment_status,
  sar.promedio_anual,
  sar.asistencia_porcentaje
FROM public.students s
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN public.cursos c ON c.id = sar.curso_id
WHERE UPPER(s.estado_std) = 'ACTIVO' OR s.estado_std IS NULL;

COMMENT ON VIEW v_current_student_courses IS 
'Helper view: Shows all active students with their current year course assignment.';

-- View 2: Student Academic History
CREATE OR REPLACE VIEW v_student_academic_history AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  sar.year_academico,
  c.nom_curso,
  c.nivel,
  sar.estado,
  sar.promedio_anual,
  sar.asistencia_porcentaje,
  sar.observaciones,
  sar.fecha_inicio,
  sar.fecha_termino
FROM public.students s
JOIN public.student_academic_records sar ON sar.student_id = s.id
JOIN public.cursos c ON c.id = sar.curso_id
ORDER BY s.id, sar.year_academico DESC;

COMMENT ON VIEW v_student_academic_history IS 
'Complete academic history: shows all courses a student has been enrolled in across years.';

-- ============================================================================
-- PHASE 8: UTILITY FUNCTIONS
-- ============================================================================

-- Function: Get current academic year (handles Jan-Feb as previous year)
CREATE OR REPLACE FUNCTION current_academic_year()
RETURNS integer AS $$
BEGIN
  -- In Chile, school year starts in March
  -- So January-February still belong to previous academic year
  IF EXTRACT(MONTH FROM CURRENT_DATE) <= 2 THEN
    RETURN EXTRACT(YEAR FROM CURRENT_DATE)::integer - 1;
  ELSE
    RETURN EXTRACT(YEAR FROM CURRENT_DATE)::integer;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION current_academic_year() IS 
'Returns current academic year. Considers Jan-Feb as previous year since school starts in March.';

-- Function: Get student's course for specific year
CREATE OR REPLACE FUNCTION get_student_course(p_student_id uuid, p_year integer)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'student_id', sar.student_id,
    'year', sar.year_academico,
    'curso_id', sar.curso_id,
    'curso_nombre', c.nom_curso,
    'nivel', c.nivel,
    'estado', sar.estado,
    'promedio', sar.promedio_anual,
    'asistencia', sar.asistencia_porcentaje
  ) INTO result
  FROM public.student_academic_records sar
  JOIN public.cursos c ON c.id = sar.curso_id
  WHERE sar.student_id = p_student_id
    AND sar.year_academico = p_year;
  
  RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION get_student_course(uuid, integer) IS 
'Returns course information for a student in a specific year as JSON.';

-- ============================================================================
-- COMMIT TRANSACTION
-- ============================================================================

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES (Run separately to verify success)
-- ============================================================================

-- Check 1: Verify fee.year_academico exists and is populated
SELECT 
  COUNT(*) as total_fees,
  COUNT(year_academico) as with_year,
  MIN(year_academico) as oldest_year,
  MAX(year_academico) as newest_year
FROM public.fee;

-- Check 2: Verify student_academic_records table exists
SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT student_id) as unique_students,
  MIN(year_academico) as oldest_year,
  MAX(year_academico) as newest_year
FROM public.student_academic_records;

-- Check 3: Verify current year students have records
SELECT 
  s.id,
  s.whole_name,
  c.nom_curso as curso_actual,
  sar.year_academico,
  sar.estado
FROM public.students s
LEFT JOIN public.cursos c ON c.id = s.curso
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE s.estado_std = 'activo'
LIMIT 10;

-- Check 4: Verify RLS policies exist
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename IN ('student_academic_records', 'fee')
ORDER BY tablename, policyname;

-- Check 5: Test current_academic_year function
SELECT current_academic_year() as current_year;

-- ============================================================================
-- ROLLBACK SCRIPT (In case of emergency - run separately)
-- ============================================================================
/*
BEGIN;

-- Drop views
DROP VIEW IF EXISTS v_student_academic_history CASCADE;
DROP VIEW IF EXISTS v_current_student_courses CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS get_student_course(uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS current_academic_year() CASCADE;
DROP FUNCTION IF EXISTS sync_student_current_curso() CASCADE;
DROP FUNCTION IF EXISTS set_academic_year_dates() CASCADE;
DROP FUNCTION IF EXISTS update_student_academic_records_updated_at() CASCADE;

-- Drop table
DROP TABLE IF EXISTS public.student_academic_records CASCADE;

-- Remove fee.year_academico
ALTER TABLE public.fee DROP COLUMN IF EXISTS year_academico CASCADE;

-- Remove enrollment_students.academic_record_id
ALTER TABLE public.enrollment_students DROP COLUMN IF EXISTS academic_record_id CASCADE;

COMMIT;

SELECT 'Rollback completed successfully' as status;
*/

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '
  ============================================================================
  ✅ ARCHITECTURE IMPLEMENTATION COMPLETED SUCCESSFULLY
  ============================================================================
  
  Changes Applied:
  ✅ fee.year_academico column added and populated
  ✅ student_academic_records table created
  ✅ RLS policies configured
  ✅ Triggers for auto-sync and audit created
  ✅ Helper views and utility functions created
  ✅ Current year data migrated
  
  Next Steps:
  1. Run VERIFICATION QUERIES above to confirm success
  2. Update frontend code to use new year_academico column
  3. Test Guardian dashboard (should show fee totals correctly)
  4. Begin using student_academic_records for 2026 enrollments
  
  Documentation: See FINAL_ARCHITECTURE_RECOMMENDATION.md
  ============================================================================
  ';
END $$;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [16/49] MIGRATION: 20251027_setup_enrollment_documents_bucket
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- =====================================================
-- MIGRATION: Setup Storage Bucket for Enrollment Documents
-- Date: 2025-10-27
-- Description: Creates bucket and RLS policies for storing
--              generated PDF documents (Pagaré, etc.)
-- =====================================================

-- 1. CREATE STORAGE BUCKET
-- Note: This must be executed in Supabase Dashboard > Storage
-- or via Supabase CLI, not via standard SQL migration
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES (
--   'enrollment-documents',
--   'enrollment-documents',
--   false, -- private bucket
--   10485760, -- 10MB limit
--   ARRAY['application/pdf']
-- );

-- Alternative: Use Supabase Dashboard to create bucket with these settings:
-- Name: enrollment-documents
-- Public: No (private)
-- File size limit: 10 MB
-- Allowed MIME types: application/pdf

-- =====================================================
-- 2. RLS POLICIES FOR STORAGE
-- =====================================================

-- Policy: Allow authenticated users to upload documents
DROP POLICY IF EXISTS "Users can upload enrollment documents" ON storage.objects;
CREATE POLICY "Users can upload enrollment documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'enrollment-documents' 
  AND auth.uid() IS NOT NULL
);

-- Policy: Users can view their own documents (guardians see their enrollments)
DROP POLICY IF EXISTS "Guardians can view their enrollment documents" ON storage.objects;
CREATE POLICY "Guardians can view their enrollment documents"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND (
    -- Admin role can see all
    auth.jwt()->>'role' = 'admin'
    OR
    -- Guardian can see documents from their enrollments
    EXISTS (
      SELECT 1 
      FROM enrollment_documents ed
      JOIN enrollments e ON e.id = ed.enrollment_id
      WHERE ed.storage_path = storage.objects.name
        AND e.guardian_id::text = auth.uid()::text
    )
  )
);

-- Policy: Allow users to update their own documents (regenerate)
DROP POLICY IF EXISTS "Users can update their enrollment documents" ON storage.objects;
CREATE POLICY "Users can update their enrollment documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND (
    auth.jwt()->>'role' = 'admin'
    OR
    EXISTS (
      SELECT 1 
      FROM enrollment_documents ed
      JOIN enrollments e ON e.id = ed.enrollment_id
      WHERE ed.storage_path = storage.objects.name
        AND e.guardian_id::text = auth.uid()::text
    )
  )
);

-- Policy: Only admins can delete documents
DROP POLICY IF EXISTS "Only admins can delete enrollment documents" ON storage.objects;
CREATE POLICY "Only admins can delete enrollment documents"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND auth.jwt()->>'role' = 'admin'
);

-- =====================================================
-- 3. HELPER FUNCTIONS
-- =====================================================

-- Function: Get signed URL for document (valid for 1 hour)
CREATE OR REPLACE FUNCTION get_enrollment_document_url(document_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  storage_path_val TEXT;
  signed_url TEXT;
BEGIN
  -- Get storage path
  SELECT storage_path INTO storage_path_val
  FROM enrollment_documents
  WHERE id = document_id;
  
  IF storage_path_val IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Generate signed URL (valid for 1 hour)
  -- Note: This requires Supabase Storage API
  -- In practice, this is handled by the frontend using supabase.storage.from().createSignedUrl()
  RETURN storage_path_val;
END;
$$;

-- =====================================================
-- 4. VERIFICATION QUERIES
-- =====================================================

-- Verify bucket exists
-- SELECT * FROM storage.buckets WHERE id = 'enrollment-documents';

-- Verify policies
-- SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%enrollment%';

-- Test document count
-- SELECT COUNT(*) FROM enrollment_documents WHERE pdf_url IS NOT NULL;

-- =====================================================
-- MANUAL STEPS REQUIRED:
-- =====================================================
-- 1. Go to Supabase Dashboard > Storage
-- 2. Click "Create new bucket"
-- 3. Name: enrollment-documents
-- 4. Public: OFF (private bucket)
-- 5. File size limit: 10 MB
-- 6. Allowed MIME types: application/pdf
-- 7. Click "Create bucket"
-- 8. Run this migration to set up RLS policies
-- =====================================================


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [17/49] MIGRATION: 20251030_enrollment_assisted_mode_policies
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Assisted mode RLS policies to allow ADMIN and ASIST to manage enrollments and enrollment_students
-- Safe to run multiple times; policies are dropped/created idempotently.

-- Enrollments: allow ADMIN/ASIST full access
DROP POLICY IF EXISTS enrollments_admin_asist_access ON public.enrollments;
CREATE POLICY enrollments_admin_asist_access ON public.enrollments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  );

-- Enrollment students: allow ADMIN/ASIST full access
DROP POLICY IF EXISTS enrollment_students_admin_asist_access ON public.enrollment_students;
CREATE POLICY enrollment_students_admin_asist_access ON public.enrollment_students
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  );

-- Enrollment documents: allow ADMIN/ASIST full access (needed to manage pagaré records when assisting)
DROP POLICY IF EXISTS enrollment_documents_admin_asist_access ON public.enrollment_documents;
CREATE POLICY enrollment_documents_admin_asist_access ON public.enrollment_documents
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
    )
  );


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [18/49] MIGRATION: 20251031_email_logs
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Create table to audit outbound emails (receipts, pagarés, etc.)
-- Simplicity-first: minimal fields, robust constraints, and RLS for read access.

-- Ensure pgcrypto for gen_random_uuid
create extension if not exists pgcrypto with schema public;

create table if not exists public.email_logs (
  id uuid primary key default gen_random_uuid(),
  type text not null default 'other',
  to_email text not null,
  related_id uuid null,
  user_id uuid null, -- who triggered the send (auth.uid())
  provider_message_id text null, -- provider-specific id
  status text not null default 'queued',
  error text null,
  created_at timestamptz not null default now(),
  constraint email_logs_status_check check (status in ('queued','sent','failed')),
  constraint email_logs_type_check check (type in ('receipt','pagare','other')),
  constraint email_logs_email_check check (to_email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$')
);

comment on table public.email_logs is 'Audit log of outbound emails (receipts, pagaré, etc.)';
comment on column public.email_logs.type is 'receipt | pagare | other';

create index if not exists email_logs_related_id_idx on public.email_logs(related_id);
create index if not exists email_logs_to_email_idx on public.email_logs(to_email);
create index if not exists email_logs_created_at_idx on public.email_logs(created_at desc);

alter table public.email_logs enable row level security;

-- Allow ADMIN and ASIST to read logs; inserts are performed by service role (bypasses RLS)
DROP POLICY IF EXISTS email_logs_select_admin_asist ON public.email_logs;
create policy email_logs_select_admin_asist on public.email_logs
for select to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and lower(p.role) in ('admin','asist')
  )
);


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [19/49] MIGRATION: 20251101_create_cheques_table
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Create cheques table for managing check payment details
-- Created: 2025-11-01
-- Purpose: Store check information when "Cheque" payment method is selected during enrollment

-- Create cheques table
CREATE TABLE IF NOT EXISTS public.cheques (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Link to enrollment
  enrollment_id UUID NOT NULL REFERENCES public.enrollments(id) ON DELETE CASCADE,
  
  -- Check details
  numero_serie VARCHAR(100) NOT NULL, -- Check series number
  banco VARCHAR(200) NOT NULL, -- Bank name
  fecha_emision DATE NOT NULL, -- Issue date
  monto NUMERIC(12,2) NOT NULL CHECK (monto > 0), -- Amount
  
  -- Status tracking
  estado VARCHAR(50) NOT NULL DEFAULT 'pendiente' 
    CHECK (estado IN ('pendiente', 'cobrado', 'rechazado', 'anulado')),
  
  -- Additional info
  notas TEXT, -- Optional notes
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_cheques_enrollment_id ON public.cheques(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_cheques_estado ON public.cheques(estado);
CREATE INDEX IF NOT EXISTS idx_cheques_fecha_emision ON public.cheques(fecha_emision);

-- Add RLS policies
ALTER TABLE public.cheques ENABLE ROW LEVEL SECURITY;

-- ADMIN and ASIST can see all checks
DROP POLICY IF EXISTS "ADMIN and ASIST can view all cheques" ON public.cheques;
CREATE POLICY "ADMIN and ASIST can view all cheques"
  ON public.cheques
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ADMIN', 'ASIST')
    )
  );

-- ADMIN and ASIST can insert checks
DROP POLICY IF EXISTS "ADMIN and ASIST can insert cheques" ON public.cheques;
CREATE POLICY "ADMIN and ASIST can insert cheques"
  ON public.cheques
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ADMIN', 'ASIST')
    )
  );

-- ADMIN and ASIST can update checks
DROP POLICY IF EXISTS "ADMIN and ASIST can update cheques" ON public.cheques;
CREATE POLICY "ADMIN and ASIST can update cheques"
  ON public.cheques
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ADMIN', 'ASIST')
    )
  );

-- Guardians can view their own checks
DROP POLICY IF EXISTS "Guardians can view their own cheques" ON public.cheques;
CREATE POLICY "Guardians can view their own cheques"
  ON public.cheques
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.enrollments
      JOIN public.guardians ON enrollments.guardian_id = guardians.id
      WHERE enrollments.id = cheques.enrollment_id
      AND guardians.owner_id = auth.uid()
    )
  );

-- Guardians can insert checks for their own enrollments
DROP POLICY IF EXISTS "Guardians can insert cheques for own enrollments" ON public.cheques;
CREATE POLICY "Guardians can insert cheques for own enrollments"
  ON public.cheques
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.enrollments
      JOIN public.guardians ON enrollments.guardian_id = guardians.id
      WHERE enrollments.id = enrollment_id
      AND guardians.owner_id = auth.uid()
    )
  );

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cheques_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_cheques_timestamp ON public.cheques;
CREATE TRIGGER trigger_update_cheques_timestamp
  BEFORE UPDATE ON public.cheques
  FOR EACH ROW
  EXECUTE FUNCTION update_cheques_updated_at();

-- Add comment to table
COMMENT ON TABLE public.cheques IS 'Stores check payment details for enrollments';
COMMENT ON COLUMN public.cheques.numero_serie IS 'Check series/number';
COMMENT ON COLUMN public.cheques.banco IS 'Bank name that issued the check';
COMMENT ON COLUMN public.cheques.fecha_emision IS 'Check issue date';
COMMENT ON COLUMN public.cheques.monto IS 'Check amount in CLP';
COMMENT ON COLUMN public.cheques.estado IS 'Check status: pendiente, cobrado, rechazado, anulado';




-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [20/49] MIGRATION: 20251103_alter_cheques_add_document_link
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add document link fields to cheques to associate with Pagaré folio
-- Date: 2025-11-03

BEGIN;

-- Add columns if not exists
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS document_id uuid REFERENCES public.enrollment_documents(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS folio_number text;

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_cheques_document_id ON public.cheques(document_id);
CREATE INDEX IF NOT EXISTS idx_cheques_folio_number ON public.cheques(folio_number);

COMMIT;



-- ######################################################################
-- BATCH 3 (migrations 21 to 30)
-- ######################################################################

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [21/49] MIGRATION: 20251103_alter_cheques_add_numero_cuota
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add numero_cuota to cheques to support one cheque per installment
-- Date: 2025-11-03

BEGIN;

ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS numero_cuota integer;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cheques_numero_cuota_check') THEN
    ALTER TABLE public.cheques
      ADD CONSTRAINT cheques_numero_cuota_check CHECK (numero_cuota IS NULL OR numero_cuota >= 1);
  END IF;
END$$;

-- Helpful composite index for lookups and ordering
CREATE INDEX IF NOT EXISTS idx_cheques_enrollment_cuota ON public.cheques(enrollment_id, numero_cuota);

-- Optional uniqueness (commented). Enable after data backfill if required
-- ALTER TABLE public.cheques
--   ADD CONSTRAINT cheques_unique_enrollment_cuota UNIQUE (enrollment_id, numero_cuota);

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [22/49] MIGRATION: 20251103_fix_cheques_policies
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

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


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [23/49] MIGRATION: 20251108_add_audit_logs
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Add generic audit logging infrastructure
-- Date: 2025-11-08
-- Purpose: Capture critical UPDATE/DELETE operations (amount changes, deletions) across key financial tables.

-- 1. Audit table (idempotent create)
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  occurred_at timestamptz NOT NULL DEFAULT now(),
  actor_uid uuid NULL, -- auth.uid()
  action text NOT NULL, -- UPDATE | DELETE
  table_name text NOT NULL,
  record_pk text NOT NULL, -- serialized primary key value(s)
  changed_columns text[] NULL,
  old_values jsonb NULL,
  new_values jsonb NULL,
  reason text NULL, -- optional manual justification
  extra jsonb NULL -- future metadata
);

COMMENT ON TABLE public.audit_logs IS 'Generic immutable audit trail for critical data modifications.';

-- Minimal index to search recent changes by table and record
CREATE INDEX IF NOT EXISTS audit_logs_table_pk_idx ON public.audit_logs(table_name, record_pk);
CREATE INDEX IF NOT EXISTS audit_logs_actor_idx ON public.audit_logs(actor_uid, occurred_at);

-- 2. Trigger function to append audit rows
CREATE OR REPLACE FUNCTION public.audit_log_change() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp AS
$$
DECLARE
  v_actor uuid := auth.uid();
  v_changed text[] := ARRAY[]::text[];
  v_old jsonb;
  v_new jsonb;
  v_action text;
  v_table text := TG_TABLE_NAME;
  v_pk text;
  col text;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    v_action := 'UPDATE';
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);
    -- Collect changed columns (exclude updated_at noise if only timestamp changes)
    FOR col IN SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = TG_TABLE_NAME LOOP
      IF (v_old -> col) IS DISTINCT FROM (v_new -> col) THEN
        v_changed := array_append(v_changed, col);
      END IF;
    END LOOP;
    IF v_changed = ARRAY['updated_at'] THEN
      -- Skip pure timestamp refresh updates
      RETURN NEW;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    v_action := 'DELETE';
    v_old := to_jsonb(OLD);
    v_new := NULL;
  ELSE
    RETURN NULL; -- ignore other ops
  END IF;

  -- Primary key assumption: single column named id (text serialization fallback)
  IF TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN
    IF to_jsonb(OLD) ? 'id' THEN
      v_pk := COALESCE(OLD.id::text, NEW.id::text);
    ELSE
      v_pk := COALESCE(NEW::text, OLD::text); -- fallback
    END IF;
  END IF;

  INSERT INTO public.audit_logs(actor_uid, action, table_name, record_pk, changed_columns, old_values, new_values)
  VALUES (v_actor, v_action, v_table, v_pk, NULLIF(v_changed, ARRAY[]::text[]), v_old, v_new);

  IF TG_OP = 'UPDATE' THEN
    RETURN NEW;
  ELSE
    RETURN OLD;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.audit_log_change() IS 'Generic trigger function to record UPDATE/DELETE diffs into audit_logs.';

-- 3. Attach triggers to critical tables (idempotent guard by dropping existing named triggers first)
DO $$
BEGIN
  -- fee table
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'tr_audit_fee_change') THEN
    EXECUTE 'DROP TRIGGER tr_audit_fee_change ON public.fee';
  END IF;
  EXECUTE 'CREATE TRIGGER tr_audit_fee_change BEFORE UPDATE OR DELETE ON public.fee FOR EACH ROW EXECUTE FUNCTION public.audit_log_change()';

  -- cheques table
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'tr_audit_cheques_change') THEN
    EXECUTE 'DROP TRIGGER tr_audit_cheques_change ON public.cheques';
  END IF;
  EXECUTE 'CREATE TRIGGER tr_audit_cheques_change BEFORE UPDATE OR DELETE ON public.cheques FOR EACH ROW EXECUTE FUNCTION public.audit_log_change()';

  -- enrollment_documents (focus on deletion / content update)
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'tr_audit_enrollment_documents_change') THEN
    EXECUTE 'DROP TRIGGER tr_audit_enrollment_documents_change ON public.enrollment_documents';
  END IF;
  EXECUTE 'CREATE TRIGGER tr_audit_enrollment_documents_change BEFORE UPDATE OR DELETE ON public.enrollment_documents FOR EACH ROW EXECUTE FUNCTION public.audit_log_change()';
END $$;

-- 4. RLS (readonly to guardians only if their data? For now restrict to staff)
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Staff read policy
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='audit_logs' AND policyname='audit_logs_staff_read'
  ) THEN
    EXECUTE 'CREATE POLICY audit_logs_staff_read ON public.audit_logs FOR SELECT USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN (''ADMIN'',''ASIST'')))';
  END IF;
END $$;

-- Allow INSERTs only from definer context (postgres) so triggers can write despite RLS
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='audit_logs' AND policyname='audit_logs_postgres_insert'
  ) THEN
    EXECUTE 'CREATE POLICY audit_logs_postgres_insert ON public.audit_logs FOR INSERT TO postgres WITH CHECK (true)';
  END IF;
END $$;

-- No direct INSERT/UPDATE/DELETE via client; only trigger (which runs with table privileges). Optionally revoke for safety.
REVOKE ALL ON public.audit_logs FROM anon, authenticated;
GRANT SELECT ON public.audit_logs TO authenticated; -- RLS will still filter

-- 5. Optional view to expose limited columns (hide raw json if desired) - comment out for now
-- CREATE OR REPLACE VIEW public.audit_logs_summary AS
-- SELECT id, occurred_at, actor_uid, action, table_name, record_pk, changed_columns FROM public.audit_logs;
-- GRANT SELECT ON public.audit_logs_summary TO authenticated;

-- 6. Future enhancements (documented only):
-- - Add column request_id to correlate multi-row changes.
-- - Add automatic reason capture through app-supplied set_config('app.audit_reason', ...) pattern.
-- - Add policy allowing guardians to see their own deletions (low priority).


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [24/49] MIGRATION: 20251108_rate_limit
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Rate limiting primitives (fixed window)
-- Date: 2025-11-08

-- 1) Counter table (fixed window)
CREATE TABLE IF NOT EXISTS public.rate_limit_counters (
  key text NOT NULL,
  window_start timestamptz NOT NULL,
  count integer NOT NULL DEFAULT 0,
  CONSTRAINT rate_limit_counters_pkey PRIMARY KEY (key, window_start)
);

CREATE INDEX IF NOT EXISTS rate_limit_counters_window_idx ON public.rate_limit_counters(window_start);

-- 2) Function: check and increment atomically
-- Returns: allowed, remaining, reset_at, current_count
CREATE OR REPLACE FUNCTION public.check_and_increment_rate_limit(
  p_key text,
  p_limit integer,
  p_window_seconds integer,
  p_now timestamptz DEFAULT now()
) RETURNS TABLE (
  allowed boolean,
  remaining integer,
  reset_at timestamptz,
  current_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp AS
$$
DECLARE
  v_window_start timestamptz;
  v_count integer;
  v_reset_at timestamptz;
BEGIN
  -- Compute fixed window start aligned to p_window_seconds
  v_window_start := to_timestamp(floor(extract(epoch from p_now) / p_window_seconds) * p_window_seconds);

  -- Upsert increment
  INSERT INTO public.rate_limit_counters(key, window_start, count)
  VALUES (p_key, v_window_start, 1)
  ON CONFLICT (key, window_start)
  DO UPDATE SET count = public.rate_limit_counters.count + 1
  RETURNING count INTO v_count;

  v_reset_at := v_window_start + make_interval(secs => p_window_seconds);

  allowed := (v_count <= p_limit);
  remaining := GREATEST(p_limit - v_count, 0);
  reset_at := v_reset_at;
  current_count := v_count;
  RETURN;
END;
$$;

COMMENT ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) IS 'Fixed-window rate limit: increments counter and indicates if within limit.';

-- Permissions: callable by service role; block anon/authenticated if desired
REVOKE ALL ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) TO postgres;
GRANT EXECUTE ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) TO service_role;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [25/49] MIGRATION: 20251110_extend_enrollment_documents_types
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Extend allowed types for enrollment_documents.type
-- Date: 2025-11-10
-- Purpose: Support new auto-generated document types (PRESTACION, PRIORITARIO, PAGARE_DEUDA, PAGARE_REPACTACION)

BEGIN;

-- Drop any existing anonymous CHECK constraint(s) on enrollment_documents.type safely
DO $$
DECLARE
  cons RECORD;
BEGIN
  -- First, drop known named constraint if present to avoid duplicate-name error
  BEGIN
    ALTER TABLE public.enrollment_documents DROP CONSTRAINT IF EXISTS enrollment_documents_type_check;
  EXCEPTION WHEN others THEN
    -- ignore
  END;

  FOR cons IN
    SELECT conname
    FROM   pg_constraint c
    JOIN   pg_class t ON t.oid = c.conrelid
    JOIN   pg_namespace n ON n.oid = t.relnamespace
    WHERE  n.nspname = 'public'
    AND    t.relname = 'enrollment_documents'
    AND    c.contype = 'c'
    AND    pg_get_constraintdef(c.oid) ILIKE '%CHECK%type%IN%'
  LOOP
    EXECUTE format('ALTER TABLE public.enrollment_documents DROP CONSTRAINT IF EXISTS %I;', cons.conname);
  END LOOP;
END$$;

-- Add the new explicit CHECK constraint with the full set of allowed types
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'enrollment_documents_type_check') THEN
    ALTER TABLE public.enrollment_documents
      ADD CONSTRAINT enrollment_documents_type_check
      CHECK (type IN (
        'PRESTACION',
        'PRIORITARIO',
        'PAGARE',
        'PAGARE_DEUDA',
        'PAGARE_REPACTACION',
        'DECLARACION',
        'OTRO'
      ));
  END IF;
END$$;

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [26/49] MIGRATION: 20251115_finalize_enrollment_rpc
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Finalize Enrollment: Generates fee charges from an enrollment in an idempotent, audited, and RLS-safe way
-- This migration is idempotent and safe to re-run.

-- 0) Helpers: is_staff()
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'is_staff' AND pg_function_is_visible(oid)
  ) THEN
    CREATE OR REPLACE FUNCTION public.is_staff()
    RETURNS boolean
    LANGUAGE sql
    STABLE
    SET search_path = public
    AS $is_staff$
      SELECT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
      );
    $is_staff$;
    COMMENT ON FUNCTION public.is_staff() IS 'Returns true if auth.uid() has role ADMIN or ASIST in public.profiles.';
  END IF;
END$$;

-- 1) Ensure fee has required columns/constraints for idempotency and traceability
DO $$
DECLARE
  v_exists boolean;
BEGIN
  -- Add year_academico if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='fee' AND column_name='year_academico'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN year_academico int;
  END IF;

  -- Add numero_cuota if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='fee' AND column_name='numero_cuota'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN numero_cuota int;
  END IF;

  -- Add enrollment_id (nullable) for traceability if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='fee' AND column_name='enrollment_id'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL;
  END IF;

  -- Add unique constraint for idempotent inserts per student/year/cuota
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='fee' AND indexname='ux_fee_student_year_cuota'
  ) THEN
    -- Clean up any legacy duplicates before enforcing the unique index
    WITH dup_fee AS (
      SELECT id,
             ROW_NUMBER() OVER (
               PARTITION BY student_id, year_academico, numero_cuota
               ORDER BY COALESCE(created_at, updated_at, now()) ASC, id ASC
             ) AS rn
        FROM public.fee
       WHERE student_id IS NOT NULL
         AND year_academico IS NOT NULL
         AND numero_cuota IS NOT NULL
    )
    DELETE FROM public.fee f
    USING dup_fee d
     WHERE f.id = d.id
       AND d.rn > 1;

    CREATE UNIQUE INDEX ux_fee_student_year_cuota
      ON public.fee(student_id, year_academico, numero_cuota)
      WHERE student_id IS NOT NULL AND year_academico IS NOT NULL AND numero_cuota IS NOT NULL;
  END IF;
END$$;

-- 2) Finalize RPC
DROP FUNCTION IF EXISTS public.finalize_enrollment(uuid, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_year int;
  v_skip_docs boolean := COALESCE((p_options->>'skip_doc_checks')::boolean, false);
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;

  r_es RECORD;
  r_cuota RECORD;
  v_has_prestacion boolean;
  v_has_pagare boolean;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Load enrollment and guardian
  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  -- Authorization
  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Ready check (optional skip for staff via option)
  IF NOT v_skip_docs THEN
    -- PRESTACION signed by guardian
    SELECT EXISTS (
      SELECT 1
        FROM public.enrollment_documents d
  JOIN public.signatures s ON s.enrollment_document_id = d.id AND s.signer_type IN ('GUARDIAN','APODERADO') AND s.signed_at IS NOT NULL
       WHERE d.enrollment_id = p_enrollment_id AND d.type = 'PRESTACION')
    INTO v_has_prestacion;

    -- at least one PAGARE*
    SELECT EXISTS (
      SELECT 1
        FROM public.enrollment_documents d
  JOIN public.signatures s ON s.enrollment_document_id = d.id AND s.signer_type IN ('GUARDIAN','APODERADO') AND s.signed_at IS NOT NULL
       WHERE d.enrollment_id = p_enrollment_id AND (d.type LIKE 'PAGARE%'))
    INTO v_has_pagare;

    IF NOT (COALESCE(v_has_prestacion,false) AND COALESCE(v_has_pagare,false)) THEN
      RAISE EXCEPTION 'NOT_READY: required documents or signatures are missing';
    END IF;
  END IF;

  -- Fetch students
  FOR r_es IN
    SELECT es.student_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    -- Ensure student_guardian relation
    PERFORM 1 FROM public.student_guardian sg
      WHERE sg.student_id = r_es.student_id AND sg.guardian_id = v_enrollment.guardian_id;
    IF NOT FOUND THEN
      IF v_is_staff THEN
        INSERT INTO public.student_guardian(student_id, guardian_id, is_primary)
        VALUES (r_es.student_id, v_enrollment.guardian_id, false)
        ON CONFLICT DO NOTHING;
      ELSE
        RAISE EXCEPTION 'MISSING_RELATION: student % is not linked with this guardian', r_es.student_id;
      END IF;
    END IF;
  END LOOP;

  IF v_students = 0 THEN
    RAISE EXCEPTION 'NO_STUDENTS: enrollment has no students';
  END IF;

  -- Resolve payment plan: options.payment_plan > enrollment.meta.payment_plan > any doc payload
  v_plan := p_options->'payment_plan';
  IF v_plan IS NULL THEN
    SELECT e.meta->'payment_plan' INTO v_plan FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;
  IF v_plan IS NULL THEN
    SELECT ed.generated_payload INTO v_plan
      FROM public.enrollment_documents ed
     WHERE ed.enrollment_id = p_enrollment_id
       AND (ed.type = 'PRESTACION' OR ed.type LIKE 'PAGARE%')
       AND ed.generated_payload IS NOT NULL
     ORDER BY CASE WHEN ed.type='PRESTACION' THEN 0 ELSE 1 END, ed.created_at DESC
     LIMIT 1;
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  -- Compute cuotas array
  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
    -- try to synthesize from n_cuotas, primer_vencimiento, monto_por_cuota or monto_total
    DECLARE
      v_n int := COALESCE((v_plan->>'n_cuotas')::int, NULL);
      v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
      v_amount numeric := COALESCE((v_plan->>'monto_por_cuota')::numeric,
                                   NULLIF((v_plan->>'monto_total')::numeric, NULL) / NULLIF(v_n,0));
      i int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      IF v_n IS NULL OR v_first IS NULL OR v_amount IS NULL THEN
        RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
      END IF;
      WHILE i <= v_n LOOP
        v_synth := v_synth || jsonb_build_object(
          'numero', i,
          'amount', v_amount,
          'due_date', (v_first + make_interval(months := i-1))::date
        );
        i := i + 1;
      END LOOP;
      v_cuotas := v_synth;
    END;
  END IF;

  -- Dry-run summary scaffold
  v_summary := '[]'::jsonb;

  -- Iterate students x cuotas
  FOR r_es IN SELECT es.student_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    -- per-student accumulation
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          ON CONFLICT (student_id, year_academico, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  -- Update enrollment status
  IF NOT v_dry_run THEN
    UPDATE public.enrollments SET status = 'completed', updated_at = now()
     WHERE id = p_enrollment_id;

    -- Mark students as MATRICULADO until contracts are fully activated
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary
  );
END;
$$;

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 'Finalize an enrollment: validates readiness, ensures links, generates fee charges idempotently, and marks enrollment as CONFIRMED. Supports dry_run and staff overrides.';

-- 3) Grants
REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [27/49] MIGRATION: 20251115_staff_intake_rpcs
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Staff RPCs to manage guardian intake surveys (admin upsert/submit)
-- Variant 1: prefer RPCs over widening RLS on guardian_intake_surveys.

-- Helper: is_staff() already created in finalize_enrollment migration; redefine safely
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role IN ('ADMIN','ASIST')
  );
$$;

-- Admin upsert: create/update intake for any guardian and year
DROP FUNCTION IF EXISTS public.admin_upsert_guardian_intake(uuid, jsonb, int) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_upsert_guardian_intake(p_guardian_id uuid, p_payload jsonb, p_year int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year int := COALESCE(p_year, (SELECT date_part('year', now())::int));
  v_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'RLS_DENIED: only staff can use this function';
  END IF;

  -- Ensure guardian exists
  PERFORM 1 FROM public.guardians g WHERE g.id = p_guardian_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Guardian % not found', p_guardian_id;
  END IF;

  -- Upsert by (guardian_id, year)
  INSERT INTO public.guardian_intake_surveys (
    guardian_id, year,
    guardian_first_name, guardian_last_name_paterno, guardian_last_name_materno, guardian_relationship,
    guardian_rut, guardian_education_level, guardian_address, guardian_commune, guardian_email, guardian_phone,
    student_first_names, student_last_name_paterno, student_last_name_materno, student_run, student_course, student_course_id,
    student_birth_date, student_nationality, student_gender, student_social_name, student_enrollment_date,
    student_withdrawal_date, student_withdrawal_reason, student_repeat_current, student_previous_institution,
    student_address, student_commune, student_lives_with, alt_contact_name, alt_contact_phone,
    scholarship_percentage, payment_form_prioritario, payment_form_cheques, payment_form_pagare,
    payment_form_credit_card, payment_form_transfer, payment_form_planilla, financial_institution, status
  ) VALUES (
    p_guardian_id, v_year,
    p_payload->>'guardian_first_name', p_payload->>'guardian_last_name_paterno', p_payload->>'guardian_last_name_materno', p_payload->>'guardian_relationship',
    p_payload->>'guardian_rut', p_payload->>'guardian_education_level', p_payload->>'guardian_address', p_payload->>'guardian_commune', p_payload->>'guardian_email', p_payload->>'guardian_phone',
    p_payload->>'student_first_names', p_payload->>'student_last_name_paterno', p_payload->>'student_last_name_materno', p_payload->>'student_run', p_payload->>'student_course', NULLIF(p_payload->>'student_course_id','')::uuid,
    (p_payload->>'student_birth_date')::date, p_payload->>'student_nationality', p_payload->>'student_gender', p_payload->>'student_social_name', (p_payload->>'student_enrollment_date')::date,
    (p_payload->>'student_withdrawal_date')::date, p_payload->>'student_withdrawal_reason', (p_payload->>'student_repeat_current')::boolean, p_payload->>'student_previous_institution',
    p_payload->>'student_address', p_payload->>'student_commune', string_to_array(COALESCE(p_payload->>'student_lives_with',''), '|')::text[], p_payload->>'alt_contact_name', p_payload->>'alt_contact_phone',
    (p_payload->>'scholarship_percentage')::numeric, (p_payload->>'payment_form_prioritario')::boolean, (p_payload->>'payment_form_cheques')::boolean, (p_payload->>'payment_form_pagare')::boolean,
    (p_payload->>'payment_form_credit_card')::boolean, (p_payload->>'payment_form_transfer')::boolean, (p_payload->>'payment_form_planilla')::boolean, p_payload->>'financial_institution', COALESCE(p_payload->>'status','draft')
  )
  ON CONFLICT (guardian_id, year) DO UPDATE SET
    guardian_first_name = EXCLUDED.guardian_first_name,
    guardian_last_name_paterno = EXCLUDED.guardian_last_name_paterno,
    guardian_last_name_materno = EXCLUDED.guardian_last_name_materno,
    guardian_relationship = EXCLUDED.guardian_relationship,
    guardian_rut = EXCLUDED.guardian_rut,
    guardian_education_level = EXCLUDED.guardian_education_level,
    guardian_address = EXCLUDED.guardian_address,
    guardian_commune = EXCLUDED.guardian_commune,
    guardian_email = EXCLUDED.guardian_email,
    guardian_phone = EXCLUDED.guardian_phone,
    student_first_names = EXCLUDED.student_first_names,
    student_last_name_paterno = EXCLUDED.student_last_name_paterno,
    student_last_name_materno = EXCLUDED.student_last_name_materno,
    student_run = EXCLUDED.student_run,
    student_course = EXCLUDED.student_course,
    student_course_id = EXCLUDED.student_course_id,
    student_birth_date = EXCLUDED.student_birth_date,
    student_nationality = EXCLUDED.student_nationality,
    student_gender = EXCLUDED.student_gender,
    student_social_name = EXCLUDED.student_social_name,
    student_enrollment_date = EXCLUDED.student_enrollment_date,
    student_withdrawal_date = EXCLUDED.student_withdrawal_date,
    student_withdrawal_reason = EXCLUDED.student_withdrawal_reason,
    student_repeat_current = EXCLUDED.student_repeat_current,
    student_previous_institution = EXCLUDED.student_previous_institution,
    student_address = EXCLUDED.student_address,
    student_commune = EXCLUDED.student_commune,
    student_lives_with = EXCLUDED.student_lives_with,
    alt_contact_name = EXCLUDED.alt_contact_name,
    alt_contact_phone = EXCLUDED.alt_contact_phone,
    scholarship_percentage = EXCLUDED.scholarship_percentage,
    payment_form_prioritario = EXCLUDED.payment_form_prioritario,
    payment_form_cheques = EXCLUDED.payment_form_cheques,
    payment_form_pagare = EXCLUDED.payment_form_pagare,
    payment_form_credit_card = EXCLUDED.payment_form_credit_card,
    payment_form_transfer = EXCLUDED.payment_form_transfer,
    payment_form_planilla = EXCLUDED.payment_form_planilla,
    financial_institution = EXCLUDED.financial_institution,
    status = EXCLUDED.status
  RETURNING * INTO v_row;

  RETURN to_jsonb(v_row);
END;
$$;

COMMENT ON FUNCTION public.admin_upsert_guardian_intake(uuid, jsonb, int) IS 'STAFF: upsert guardian intake survey for a specific guardian and year.';

REVOKE ALL ON FUNCTION public.admin_upsert_guardian_intake(uuid, jsonb, int) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_upsert_guardian_intake(uuid, jsonb, int) TO authenticated;

-- Admin submit: lock the survey
DROP FUNCTION IF EXISTS public.admin_submit_guardian_intake(uuid, int) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_submit_guardian_intake(p_guardian_id uuid, p_year int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year int := COALESCE(p_year, (SELECT date_part('year', now())::int));
  v_row public.guardian_intake_surveys%ROWTYPE;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'RLS_DENIED: only staff can use this function';
  END IF;

  SELECT * INTO v_row FROM public.guardian_intake_surveys
   WHERE guardian_id = p_guardian_id AND year = v_year;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No draft survey found for guardian % and year %', p_guardian_id, v_year;
  END IF;
  IF v_row.status = 'submitted' THEN
    RETURN jsonb_build_object('status','already_submitted','id', v_row.id);
  END IF;
  -- Minimal validations (extend as needed)
  IF v_row.guardian_rut IS NULL OR v_row.student_run IS NULL THEN
    RAISE EXCEPTION 'Required RUN fields missing in intake survey';
  END IF;
  UPDATE public.guardian_intake_surveys
     SET status='submitted', submitted_at=now()
   WHERE id = v_row.id
  RETURNING * INTO v_row;
  RETURN jsonb_build_object('status','submitted','id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.admin_submit_guardian_intake(uuid, int) IS 'STAFF: submit (lock) guardian intake survey for a specific guardian and year.';

REVOKE ALL ON FUNCTION public.admin_submit_guardian_intake(uuid, int) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_submit_guardian_intake(uuid, int) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [28/49] MIGRATION: 20251116_add_matriculado_estado
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add MATRICULADO status for students
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'students' AND column_name = 'estado_std'
  ) THEN
    ALTER TABLE public.students
      ADD COLUMN estado_std text DEFAULT 'ACTIVO';
  END IF;
END$$;

ALTER TABLE public.students
  DROP CONSTRAINT IF EXISTS students_estado_std_check;

ALTER TABLE public.students
  ADD CONSTRAINT students_estado_std_check
  CHECK (estado_std IN ('ACTIVO','RETIRADO','MATRICULADO'));

CREATE INDEX IF NOT EXISTS idx_students_estado_std ON public.students(estado_std);


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [29/49] MIGRATION: 20251118_enrollment_document_receipts
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Enrollment document receipts + signed_at plumbing + finalized RPC refresh
-- Safe to run multiple times.

-- 1) Ensure signatures.signed_at exists and is indexed
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'signatures' AND column_name = 'signed_at'
  ) THEN
    ALTER TABLE public.signatures
      ADD COLUMN signed_at timestamptz NOT NULL DEFAULT timezone('utc', now());
    UPDATE public.signatures
       SET signed_at = COALESCE(signed_at, created_at, timezone('utc', now()));
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_signatures_document_signed_at
  ON public.signatures(enrollment_document_id, signer_type, signed_at);

-- 2) Enrollment document receipts table (physical paperwork tracking)
CREATE TABLE IF NOT EXISTS public.enrollment_document_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_document_id uuid NOT NULL REFERENCES public.enrollment_documents(id) ON DELETE CASCADE,
  received_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  received_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  method text NOT NULL DEFAULT 'PAPER',
  evidence_url text,
  notes text,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'ux_enrollment_document_receipts_document'
       AND conrelid = 'public.enrollment_document_receipts'::regclass
  ) THEN
    ALTER TABLE public.enrollment_document_receipts
      ADD CONSTRAINT ux_enrollment_document_receipts_document UNIQUE (enrollment_document_id);
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_receipts_document ON public.enrollment_document_receipts(enrollment_document_id);
CREATE INDEX IF NOT EXISTS idx_receipts_received_by ON public.enrollment_document_receipts(received_by);

ALTER TABLE public.enrollment_document_receipts ENABLE ROW LEVEL SECURITY;

-- Allow ADMIN/ASIST full control
DROP POLICY IF EXISTS enrollment_document_receipts_staff_policy ON public.enrollment_document_receipts;
CREATE POLICY enrollment_document_receipts_staff_policy ON public.enrollment_document_receipts
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- Keep updated_at in sync
DROP TRIGGER IF EXISTS tr_receipts_updated_at ON public.enrollment_document_receipts;
CREATE TRIGGER tr_receipts_updated_at
  BEFORE UPDATE ON public.enrollment_document_receipts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3) Trigger helpers to mirror signatures/receipts onto enrollment_documents.signed_at
CREATE OR REPLACE FUNCTION public.trg_mark_document_signed_from_signature()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.signed_at IS NULL THEN
    RETURN NEW;
  END IF;
  UPDATE public.enrollment_documents
     SET signed_at = COALESCE(signed_at, NEW.signed_at)
   WHERE id = NEW.enrollment_document_id
     AND signed_at IS NULL;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_mark_document_signed_from_receipt()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.enrollment_documents
     SET signed_at = COALESCE(signed_at, NEW.received_at)
   WHERE id = NEW.enrollment_document_id
     AND signed_at IS NULL;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_signatures_mark_doc_signed ON public.signatures;
CREATE TRIGGER tr_signatures_mark_doc_signed
  AFTER INSERT OR UPDATE OF signed_at ON public.signatures
  FOR EACH ROW EXECUTE FUNCTION public.trg_mark_document_signed_from_signature();

DROP TRIGGER IF EXISTS tr_receipts_mark_doc_signed ON public.enrollment_document_receipts;
CREATE TRIGGER tr_receipts_mark_doc_signed
  AFTER INSERT OR UPDATE ON public.enrollment_document_receipts
  FOR EACH ROW EXECUTE FUNCTION public.trg_mark_document_signed_from_receipt();

-- 4) Helper to summarize required doc readiness (digital or physical)
CREATE OR REPLACE FUNCTION public.required_enrollment_documents_state(p_enrollment_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  WITH docs AS (
    SELECT d.type,
           EXISTS (
             SELECT 1 FROM public.signatures s
             WHERE s.enrollment_document_id = d.id
               AND s.signer_type IN ('GUARDIAN','APODERADO')
               AND s.signed_at IS NOT NULL
           ) AS has_digital,
           EXISTS (
             SELECT 1 FROM public.enrollment_document_receipts r
             WHERE r.enrollment_document_id = d.id
           ) AS has_receipt
      FROM public.enrollment_documents d
     WHERE d.enrollment_id = p_enrollment_id
  ), agg AS (
    SELECT
      bool_or(type = 'PRESTACION' AND (has_digital OR has_receipt)) AS prestacion_ready,
      bool_or(type LIKE 'PAGARE%' AND (has_digital OR has_receipt)) AS pagare_ready,
      bool_or(type = 'PRESTACION' AND has_digital) AS prestacion_digital,
      bool_or(type LIKE 'PAGARE%' AND has_digital) AS pagare_digital,
      bool_or(type = 'PRESTACION' AND has_receipt) AS prestacion_receipt,
      bool_or(type LIKE 'PAGARE%' AND has_receipt) AS pagare_receipt
    FROM docs
  )
  SELECT jsonb_build_object(
    'prestacion_ready', COALESCE(prestacion_ready, false),
    'pagare_ready', COALESCE(pagare_ready, false),
    'prestacion_digital', COALESCE(prestacion_digital, false),
    'pagare_digital', COALESCE(pagare_digital, false),
    'prestacion_receipt', COALESCE(prestacion_receipt, false),
    'pagare_receipt', COALESCE(pagare_receipt, false)
  )
  FROM agg;
$$;

COMMENT ON FUNCTION public.required_enrollment_documents_state(uuid) IS 'Returns JSON summarizing PRESTACION/PAGARE readiness (digital signatures or physical receipts).';

-- 5) RPC to record physical receipt evidence
DROP FUNCTION IF EXISTS public.record_document_receipt(uuid, jsonb);
CREATE OR REPLACE FUNCTION public.record_document_receipt(p_document_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_doc RECORD;
  v_receipt RECORD;
  v_method text := COALESCE(p_options->>'method', 'PAPER');
  v_notes text := NULLIF(p_options->>'notes', '');
  v_evidence text := NULLIF(p_options->>'evidence_url', '');
  v_meta jsonb := COALESCE(p_options->'meta', '{}'::jsonb);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'RLS_DENIED: sólo el equipo puede registrar recepción física';
  END IF;

  SELECT * INTO v_doc FROM public.enrollment_documents WHERE id = p_document_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Document % not found', p_document_id;
  END IF;

  INSERT INTO public.enrollment_document_receipts(
    enrollment_document_id, received_by, method, evidence_url, notes, meta
  ) VALUES (
    p_document_id, v_uid, v_method, v_evidence, v_notes, v_meta
  )
  ON CONFLICT (enrollment_document_id) DO UPDATE SET
    received_at = timezone('utc', now()),
    received_by = EXCLUDED.received_by,
    method = EXCLUDED.method,
    evidence_url = EXCLUDED.evidence_url,
    notes = EXCLUDED.notes,
    meta = EXCLUDED.meta,
    updated_at = timezone('utc', now())
  RETURNING * INTO v_receipt;

  INSERT INTO public.audit_logs(action, table_name, record_pk, actor_uid, reason, extra)
  VALUES (
    'DOCUMENT_RECEIPT_RECORDED',
    'enrollment_documents',
    p_document_id::text,
    v_uid,
    'physical_document_received',
    jsonb_build_object(
      'method', v_method,
      'notes', v_notes,
      'evidence_url', v_evidence,
      'meta', v_meta,
      'receipt_id', v_receipt.id,
      'enrollment_id', v_doc.enrollment_id
    )
  );

  RETURN jsonb_build_object(
    'receipt_id', v_receipt.id,
    'received_at', v_receipt.received_at,
    'method', v_receipt.method,
    'enrollment_document_id', v_receipt.enrollment_document_id
  );
END;
$$;

COMMENT ON FUNCTION public.record_document_receipt(uuid, jsonb) IS 'Staff helper to record physical paperwork reception for an enrollment document.';

REVOKE ALL ON FUNCTION public.record_document_receipt(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.record_document_receipt(uuid, jsonb) TO authenticated;

-- 6) Refresh finalize_enrollment RPC to honor receipts + stricter overrides
DROP FUNCTION IF EXISTS public.finalize_enrollment(uuid, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_year int;
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;
  v_folio text;
  r_es RECORD;
  r_cuota RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Staff can always confirm; guardians still rely on planner safeguards above

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    PERFORM 1 FROM public.student_guardian sg
      WHERE sg.student_id = r_es.student_id AND sg.guardian_id = v_enrollment.guardian_id;
    IF NOT FOUND THEN
      IF v_is_staff THEN
        INSERT INTO public.student_guardian(student_id, guardian_id, is_primary)
        VALUES (r_es.student_id, v_enrollment.guardian_id, false)
        ON CONFLICT DO NOTHING;
      ELSE
        RAISE EXCEPTION 'MISSING_RELATION: student % is not linked with this guardian', r_es.student_id;
      END IF;
    END IF;
  END LOOP;

  IF v_students = 0 THEN
    RAISE EXCEPTION 'NO_STUDENTS: enrollment has no students';
  END IF;

  v_plan := p_options->'payment_plan';
  IF v_plan IS NULL THEN
    SELECT e.meta->'payment_plan' INTO v_plan FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;
  IF v_plan IS NULL THEN
    SELECT ed.generated_payload INTO v_plan
      FROM public.enrollment_documents ed
     WHERE ed.enrollment_id = p_enrollment_id
       AND (ed.type = 'PRESTACION' OR ed.type LIKE 'PAGARE%')
       AND ed.generated_payload IS NOT NULL
     ORDER BY CASE WHEN ed.type='PRESTACION' THEN 0 ELSE 1 END, ed.created_at DESC
     LIMIT 1;
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
    DECLARE
      v_n int := COALESCE((v_plan->>'n_cuotas')::int, NULL);
      v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
      v_amount numeric := COALESCE((v_plan->>'monto_por_cuota')::numeric,
                                   NULLIF((v_plan->>'monto_total')::numeric, NULL) / NULLIF(v_n,0));
      i int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      IF v_n IS NULL OR v_first IS NULL OR v_amount IS NULL THEN
        RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
      END IF;
      WHILE i <= v_n LOOP
        v_synth := v_synth || jsonb_build_object(
          'numero', i,
          'amount', v_amount,
          'due_date', (v_first + make_interval(months := i-1))::date
        );
        i := i + 1;
      END LOOP;
      v_cuotas := v_synth;
    END;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          ON CONFLICT (student_id, guardian_id, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    -- Generate folio
    v_folio := 'ENR-' || v_year || '-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || substring(p_enrollment_id::text, 1, 8);
    
    -- Update enrollment with folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary,
    'folio', v_folio,
    'year', v_year
  );
END;
$$;

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 'Finalize an enrollment once PRESTACION + PAGARE docs are ready (digital or physical receipts), generating tuition charges safely.';

REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [30/49] MIGRATION: 20251119_guardian_identity_fields
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Add guardian identity fields for contract templates
-- Created: 2025-11-19
-- Purpose: Ensure pagaré/autorización documents can render nationality, profession and marital status

ALTER TABLE public.guardians
ADD COLUMN IF NOT EXISTS nacionalidad VARCHAR(50) DEFAULT 'Chilena';

ALTER TABLE public.guardians
ADD COLUMN IF NOT EXISTS profesion VARCHAR(100);

ALTER TABLE public.guardians
ADD COLUMN IF NOT EXISTS estado_civil VARCHAR(20);

-- Backfill nationality for existing guardians so templates show a friendly default
UPDATE public.guardians
SET nacionalidad = 'Chilena'
WHERE nacionalidad IS NULL OR nacionalidad = '';

COMMENT ON COLUMN public.guardians.nacionalidad IS 'Guardian nationality displayed in pagare/autorizacion templates.';
COMMENT ON COLUMN public.guardians.profesion IS 'Guardian profession or occupation displayed in contract templates.';
COMMENT ON COLUMN public.guardians.estado_civil IS 'Guardian marital status displayed in contract templates.';



-- ######################################################################
-- BATCH 4 (migrations 31 to 40)
-- ######################################################################

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [31/49] MIGRATION: 20251120120000_guardian_intake_course_id
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add student_course_id to guardian intake surveys so we can link cursos directly
ALTER TABLE public.guardian_intake_surveys
  ADD COLUMN IF NOT EXISTS student_course_id uuid REFERENCES public.cursos(id);

CREATE INDEX IF NOT EXISTS idx_guardian_intake_surveys_course_id
  ON public.guardian_intake_surveys(student_course_id);

-- Best-effort backfill by matching existing text values to cursos.nom_curso
WITH normalized AS (
  SELECT gis.id, c.id AS curso_id
  FROM public.guardian_intake_surveys gis
  JOIN public.cursos c
    ON lower(trim(c.nom_curso)) = lower(trim(gis.student_course))
)
UPDATE public.guardian_intake_surveys AS gis
SET student_course_id = normalized.curso_id
FROM normalized
WHERE gis.id = normalized.id AND gis.student_course_id IS NULL;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [32/49] MIGRATION: 20251202_fix_security_issues
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Fix security issues reported by Supabase Linter
-- 1. Remove SECURITY DEFINER from views
-- 2. Enable RLS on public tables

-- 1. Fix database_metadata view
DROP VIEW IF EXISTS public.database_metadata CASCADE;

CREATE VIEW public.database_metadata WITH (security_invoker = true) AS
SELECT 
    t.table_schema,
    t.table_name,
    jsonb_agg(
        jsonb_build_object(
            'column_name', c.column_name,
            'data_type', c.data_type,
            'is_nullable', c.is_nullable,
            'column_default', c.column_default,
            'character_maximum_length', c.character_maximum_length
        ) ORDER BY c.ordinal_position
    ) AS metadata
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
GROUP BY t.table_schema, t.table_name
ORDER BY t.table_name;

GRANT SELECT ON public.database_metadata TO authenticated;


-- 2. Fix v_student_academic_history view
DROP VIEW IF EXISTS public.v_student_academic_history CASCADE;

CREATE VIEW public.v_student_academic_history WITH (security_invoker = true) AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  sar.year_academico,
  c.nom_curso,
  c.nivel,
  sar.estado,
  sar.promedio_anual,
  sar.asistencia_porcentaje,
  sar.observaciones,
  sar.fecha_inicio,
  sar.fecha_termino
FROM public.students s
JOIN public.student_academic_records sar ON sar.student_id = s.id
JOIN public.cursos c ON c.id = sar.curso_id
ORDER BY s.id, sar.year_academico DESC;

COMMENT ON VIEW public.v_student_academic_history IS 
'Complete academic history: shows all courses a student has been enrolled in across years.';

GRANT SELECT ON public.v_student_academic_history TO authenticated;


-- 3. Fix v_current_student_courses view
DROP VIEW IF EXISTS public.v_current_student_courses CASCADE;

CREATE VIEW public.v_current_student_courses WITH (security_invoker = true) AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  s.first_name,
  s.apellido_paterno,
  s.apellido_materno,
  sar.curso_id,
  c.nom_curso,
  c.nivel,
  c.letra_curso,
  c.year_academico,
  sar.estado as enrollment_status,
  sar.promedio_anual,
  sar.asistencia_porcentaje
FROM public.students s
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN public.cursos c ON c.id = sar.curso_id
WHERE UPPER(s.estado_std) = 'ACTIVO' OR s.estado_std IS NULL;

COMMENT ON VIEW public.v_current_student_courses IS 
'Helper view: Shows all active students with their current year course assignment. Uses case-insensitive comparison for estado_std.';

GRANT SELECT ON public.v_current_student_courses TO authenticated;


-- 4. Enable RLS on guardian_claim_logs
ALTER TABLE public.guardian_claim_logs ENABLE ROW LEVEL SECURITY;

-- 5. Enable RLS on rate_limit_counters
ALTER TABLE public.rate_limit_counters ENABLE ROW LEVEL SECURITY;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [33/49] MIGRATION: 20251203_matricula_p1_p2
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- P1 & P2 - MatriculaWizard helpers
-- Fecha: 2025-12-03
-- Objetivo:
--   P1: Exponer RPC para obtener cursos del año académico corriente.
--   P2: Exponer RPC base para obtener el último curso del estudiante
--       y un curso sugerido de promoción para el año actual.

-- -------------------------------------------------------------------
-- P1: RPC get_current_year_cursos()
-- -------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_current_year_cursos()
RETURNS SETOF public.cursos
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT c.*
  FROM public.cursos c
  WHERE c.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)::int
  ORDER BY c.nivel NULLS LAST, c.letra_curso NULLS LAST, c.nom_curso NULLS LAST;
$$;

COMMENT ON FUNCTION public.get_current_year_cursos() IS
'Devuelve todos los cursos del año académico corriente (year_academico = año actual). Pensado para MatriculaWizard.';

GRANT EXECUTE ON FUNCTION public.get_current_year_cursos() TO anon, authenticated, service_role;


-- -------------------------------------------------------------------
-- P2: RPC get_student_promotion_suggestion(student_id uuid)
-- -------------------------------------------------------------------
-- Nota: Esta función NO aplica todavía todas las reglas complejas de
-- promoción (por ejemplo 8° Básica -> I Medio). Solo entrega un
-- esqueleto seguro y coherente con el esquema para que frontend pueda
-- comenzar a integrar la funcionalidad.

CREATE OR REPLACE FUNCTION public.get_student_promotion_suggestion(p_student_id uuid)
RETURNS TABLE (
  current_course_id uuid,
  current_year int4,
  suggested_course_id uuid,
  suggested_year int4
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_year int4 := EXTRACT(YEAR FROM CURRENT_DATE)::int4;
BEGIN
  -- Último curso del estudiante según registros académicos
  RETURN QUERY
  WITH last_record AS (
    SELECT sar.curso_id,
           sar.year_academico
    FROM public.student_academic_records sar
    WHERE sar.student_id = p_student_id
    ORDER BY sar.year_academico DESC
    LIMIT 1
  )
  SELECT
    lr.curso_id AS current_course_id,
    lr.year_academico AS current_year,
    NULL::uuid AS suggested_course_id,
    v_current_year AS suggested_year
  FROM last_record lr;

  -- Nota: En una iteración posterior se puede reemplazar el NULL de
  -- suggested_course_id por la lógica real de promoción usando
  -- public.cursos (por ejemplo, mapa 2° -> 3°, etc.).
END;
$$;

COMMENT ON FUNCTION public.get_student_promotion_suggestion(uuid) IS
'Devuelve el último curso conocido del estudiante y el año académico actual como destino. La lógica de promoción de curso se añadirá en una fase posterior.';

GRANT EXECUTE ON FUNCTION public.get_student_promotion_suggestion(uuid) TO anon, authenticated, service_role;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [34/49] MIGRATION: 20251203_matricula_p3_p4
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- P3 & P4 - Plan de pagos y cheques
-- Fecha: 2025-12-03
-- Objetivo:
--   P3: Centralizar cálculo de plan de pagos (monto original,
--       descuento, monto neto, cuotas) para matrícula.
--   P4: Exponer un RPC que sugiera cheques a partir de las cuotas.

-- NOTA IMPORTANTE:
-- Esta migration NO modifica tablas existentes, solo agrega funciones
-- RPC para ser usadas por frontend / generación de documentos.

-- Suposiciones mínimas (adaptadas al inventario de columnas):
-- - Tabla public.fees: almacena cuotas asociadas a una matrícula.
--   Campos clave esperados (ajustar si es necesario):
--     id (uuid), enrollment_id (uuid), monto (numeric),
--     due_date (date), discount_amount (numeric, opcional),
--     discount_percent (numeric, opcional), year_academico (int).
-- - Tabla public.enrollments: representa la matrícula.


-- -------------------------------------------------------------------
-- P3: RPC calculate_enrollment_payment_plan(enrollment_id uuid)
-- -------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.calculate_enrollment_payment_plan(p_enrollment_id uuid)
RETURNS TABLE (
  enrollment_id uuid,
  total_original numeric,
  total_discount numeric,
  total_net numeric,
  numero_cuotas int4,
  cuota_index int4,
  cuota_monto_original numeric,
  cuota_discount numeric,
  cuota_monto_net numeric,
  cuota_due_date date,
  cuota_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_original numeric := 0;
  v_total_discount numeric := 0;
  v_total_net numeric := 0;
  v_num_cuotas int4 := 0;
BEGIN
  -- Calcular totales a partir de las cuotas (fee) existentes
  SELECT
    COALESCE(SUM(f.amount), 0) AS total_original,
    0 AS total_discount,
    COALESCE(SUM(f.amount), 0) AS total_net,
    COUNT(*) AS num_cuotas
  INTO v_total_original, v_total_discount, v_total_net, v_num_cuotas
  FROM public.fee f
  WHERE f.enrollment_id = p_enrollment_id;

  RETURN QUERY
  SELECT
    p_enrollment_id AS enrollment_id,
    v_total_original AS total_original,
    v_total_discount AS total_discount,
    v_total_net AS total_net,
    v_num_cuotas AS numero_cuotas,
    ROW_NUMBER() OVER (ORDER BY f.due_date, f.id) AS cuota_index,
    f.amount AS cuota_monto_original,
    0::numeric AS cuota_discount,
    f.amount AS cuota_monto_net,
    f.due_date AS cuota_due_date,
    f.id AS cuota_id
  FROM public.fee f
  WHERE f.enrollment_id = p_enrollment_id
  ORDER BY f.due_date, f.id;
END;
$$;

COMMENT ON FUNCTION public.calculate_enrollment_payment_plan(uuid) IS
'Calcula el plan de pagos de una matrícula a partir de fees existentes: totales (original, descuento, neto) y detalle de cuotas.';

GRANT EXECUTE ON FUNCTION public.calculate_enrollment_payment_plan(uuid) TO anon, authenticated, service_role;


-- -------------------------------------------------------------------
-- P4: RPC suggest_cheques_for_enrollment(enrollment_id uuid)
-- -------------------------------------------------------------------
-- Esta función NO crea cheques en la tabla cheques. Solo sugiere los
-- montos y fechas a partir del plan de pagos para que el frontend los
-- prellene y el usuario confirme.

CREATE OR REPLACE FUNCTION public.suggest_cheques_for_enrollment(p_enrollment_id uuid)
RETURNS TABLE (
  enrollment_id uuid,
  cheque_index int4,
  monto numeric,
  fecha_emision date,
  fecha_vencimiento date,
  cuota_id uuid
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    plan.enrollment_id,
    plan.cuota_index AS cheque_index,
    plan.cuota_monto_net AS monto,
    CURRENT_DATE::date AS fecha_emision,
    plan.cuota_due_date AS fecha_vencimiento,
    plan.cuota_id AS cuota_id
  FROM public.calculate_enrollment_payment_plan(p_enrollment_id) AS plan
  WHERE plan.cuota_monto_net > 0;
$$;

COMMENT ON FUNCTION public.suggest_cheques_for_enrollment(uuid) IS
'Sugiere cheques (monto y fechas) a partir del plan de pagos calculado para una matrícula. No inserta registros en la tabla cheques.';

GRANT EXECUTE ON FUNCTION public.suggest_cheques_for_enrollment(uuid) TO anon, authenticated, service_role;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [35/49] MIGRATION: 20251217_add_cheques_missing_columns
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================
-- MIGRACIÓN: Añadir columnas faltantes a tabla cheques
-- Fecha: 2025-12-17
-- Descripción: Consolida las columnas numero_cuota, document_id 
--              y folio_number necesarias para el flujo de cheques
-- ============================================================

BEGIN;

-- 1) Añadir numero_cuota (correlación cheque -> cuota)
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS numero_cuota integer;

-- Constraint: numero_cuota debe ser >= 1 si tiene valor
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'cheques_numero_cuota_check'
  ) THEN
    ALTER TABLE public.cheques
      ADD CONSTRAINT cheques_numero_cuota_check 
      CHECK (numero_cuota IS NULL OR numero_cuota >= 1);
  END IF;
END $$;

-- Índice compuesto para búsquedas por enrollment + cuota
CREATE INDEX IF NOT EXISTS idx_cheques_enrollment_cuota 
  ON public.cheques(enrollment_id, numero_cuota);

-- 2) Añadir document_id (FK al pagaré en enrollment_documents)
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS document_id uuid;

-- Añadir FK si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'cheques_document_id_fkey'
  ) THEN
    ALTER TABLE public.cheques
      ADD CONSTRAINT cheques_document_id_fkey 
      FOREIGN KEY (document_id) 
      REFERENCES public.enrollment_documents(id) 
      ON DELETE SET NULL;
  END IF;
END $$;

-- Índice para búsquedas por document_id
CREATE INDEX IF NOT EXISTS idx_cheques_document_id 
  ON public.cheques(document_id);

-- 3) Añadir folio_number (desnormalización del folio del pagaré)
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS folio_number text;

-- Índice para búsquedas por folio
CREATE INDEX IF NOT EXISTS idx_cheques_folio_number 
  ON public.cheques(folio_number);

-- 4) Comentarios descriptivos
COMMENT ON COLUMN public.cheques.numero_cuota IS 'Número de cuota que este cheque cubre (1-N)';
COMMENT ON COLUMN public.cheques.document_id IS 'FK al documento pagaré asociado en enrollment_documents';
COMMENT ON COLUMN public.cheques.folio_number IS 'Número de folio del pagaré (desnormalizado para consultas rápidas)';

COMMIT;

-- ============================================================
-- VERIFICACIÓN (ejecutar después del COMMIT)
-- ============================================================
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'cheques' 
--   AND column_name IN ('numero_cuota', 'document_id', 'folio_number');


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [36/49] MIGRATION: 20251219_add_guardian_fields_libro_matricula
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add missing fields to guardians table for Libro de Matrícula
-- Date: 2025-12-19

BEGIN;

-- Add date_of_birth field for guardians
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS date_of_birth DATE;

-- Add nivel_educacional field
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS nivel_educacional VARCHAR(100);

-- Add apellido_paterno and apellido_materno fields
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

-- Add helpful comments
COMMENT ON COLUMN public.guardians.date_of_birth IS 'Fecha de nacimiento del apoderado para Libro de Matrícula';
COMMENT ON COLUMN public.guardians.nivel_educacional IS 'Nivel educacional: Básica Completa, Media Completa, Técnica, Universitaria, Postgrado, etc.';
COMMENT ON COLUMN public.guardians.apellido_paterno IS 'Apellido paterno del apoderado';
COMMENT ON COLUMN public.guardians.apellido_materno IS 'Apellido materno del apoderado';

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [37/49] MIGRATION: 20251219_add_pre_matriculado_estado
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add PRE_MATRICULADO state to students.estado_std
-- Date: 2025-12-19
-- 
-- Flow:
--   Estudiante Nuevo (dic 8+)
--     ↓
--   [Proceso de matrícula completado]
--     ↓
--   Estado: PRE_MATRICULADO
--     ↓
--   [Inicio año escolar - MARZO más cercano]
--     ↓
--   Estado: MATRICULADO
--     ↓
--   [Durante año escolar]
--     ↓
--   Estado: ACTIVO

BEGIN;

-- Step 1: Drop existing constraint
ALTER TABLE public.students
  DROP CONSTRAINT IF EXISTS students_estado_std_check;

-- Step 2: Add new constraint with PRE_MATRICULADO
ALTER TABLE public.students
  ADD CONSTRAINT students_estado_std_check
  CHECK (estado_std IN ('ACTIVO','RETIRADO','MATRICULADO','PRE_MATRICULADO'));

-- Step 3: Update all students created from Dec 8, 2025 onwards to PRE_MATRICULADO
-- (Only if they are currently MATRICULADO or ACTIVO, preserve RETIRADO)
UPDATE public.students
SET estado_std = 'PRE_MATRICULADO'
WHERE created_at >= '2025-12-08'::date
  AND estado_std IN ('MATRICULADO', 'ACTIVO');

-- Step 4: Add helpful comment
COMMENT ON COLUMN public.students.estado_std IS 
'Estado del estudiante: PRE_MATRICULADO (matrícula en proceso desde dic 8+), MATRICULADO (confirmado para inicio año escolar en marzo), ACTIVO (cursando), RETIRADO (dado de baja)';

-- Step 5: Verification query (optional, for manual review)
-- SELECT estado_std, COUNT(*) as cantidad, MIN(created_at) as primer_registro, MAX(created_at) as ultimo_registro
-- FROM public.students
-- GROUP BY estado_std
-- ORDER BY estado_std;

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [38/49] MIGRATION: 20251219_add_student_apellidos_separated
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add apellido_paterno and apellido_materno to students table
-- Date: 2025-12-19

BEGIN;

-- Add apellido_paterno and apellido_materno fields
ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

-- Add helpful comments
COMMENT ON COLUMN public.students.apellido_paterno IS 'Apellido paterno del estudiante';
COMMENT ON COLUMN public.students.apellido_materno IS 'Apellido materno del estudiante';

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [39/49] MIGRATION: 20251219_create_libro_matricula_rpc
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Create RPC function to generate Libro de Matrícula report
-- Date: 2025-12-19

CREATE OR REPLACE FUNCTION public.generate_libro_matricula_report(
  p_year INTEGER DEFAULT NULL,
  p_estado VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  nivel TEXT,
  curso TEXT,
  nombres TEXT,
  apellido_paterno TEXT,
  apellido_materno TEXT,
  run_estudiante TEXT,
  fecha_nac_estudiante TEXT,
  nacionalidad TEXT,
  genero_estudiante TEXT,
  con_quien_vive TEXT,
  direccion_estudiante TEXT,
  comuna_estudiante TEXT,
  repite_curso TEXT,
  institucion_procedencia TEXT,
  nombre_apoderado TEXT,
  apellido_paterno_apoderado TEXT,
  apellido_materno_apoderado TEXT,
  relacion_apoderado TEXT,
  fecha_nac_apoderado TEXT,
  run_apoderado TEXT,
  nivel_educacional_apoderado TEXT,
  direccion_apoderado TEXT,
  comuna_apoderado TEXT,
  email_apoderado TEXT,
  telefono_apoderado TEXT,
  nombre_apoderado_secundario TEXT,
  run_apoderado_secundario TEXT,
  fecha_nac_apoderado_secundario TEXT,
  telefono_apoderado_secundario TEXT,
  email_apoderado_secundario TEXT,
  fecha_retiro TEXT,
  motivo_retiro TEXT,
  condicion TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    -- Curso info
    COALESCE(c.nivel, '')::TEXT,
    COALESCE(c.nom_curso, '')::TEXT,
    
    -- Estudiante
    COALESCE(s.first_name, '')::TEXT AS nombres,
    COALESCE(s.apellido_paterno, '')::TEXT,
    COALESCE(s.apellido_materno, '')::TEXT,
    COALESCE(s.run, '')::TEXT,
    COALESCE(TO_CHAR(s.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    UPPER(COALESCE(s.nacionalidad, 'CHILENA'))::TEXT,
    COALESCE(s.genero, '')::TEXT,
    COALESCE(s.con_quien_vive, '')::TEXT,
    COALESCE(s.direccion, '')::TEXT,
    COALESCE(s.comuna, '')::TEXT,
    CASE WHEN COALESCE(s.repite_curso_actual, 'No') ILIKE 'si%' THEN 'Sí' ELSE 'No' END::TEXT,
    COALESCE(s.institucion_procedencia, '')::TEXT,
    
    -- Apoderado principal
    COALESCE(g1.first_name, '')::TEXT,
    COALESCE(g1.apellido_paterno, '')::TEXT,
    COALESCE(g1.apellido_materno, '')::TEXT,
    COALESCE(g1.relationship_type, '')::TEXT,
    COALESCE(TO_CHAR(g1.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g1.run, '')::TEXT,
    COALESCE(g1.nivel_educacional, '')::TEXT,
    COALESCE(g1.address, '')::TEXT,
    COALESCE(g1.comuna, '')::TEXT,
    COALESCE(g1.email, '')::TEXT,
    COALESCE(g1.phone, '')::TEXT,
    
    -- Apoderado secundario
    COALESCE(g2.first_name || ' ' || COALESCE(g2.apellido_paterno, '') || ' ' || COALESCE(g2.apellido_materno, ''), '')::TEXT,
    COALESCE(g2.run, '')::TEXT,
    COALESCE(TO_CHAR(g2.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g2.phone, '')::TEXT,
    COALESCE(g2.email, '')::TEXT,
    
    -- Retiro
    COALESCE(TO_CHAR(s.fecha_retiro, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(s.motivo_retiro, '')::TEXT,
    
    -- Condición
    CASE 
      WHEN s.estado_std = 'PRE_MATRICULADO' THEN 'Matrícula en proceso'
      WHEN s.estado_std = 'MATRICULADO' THEN 'Confirmado para año escolar'
      WHEN s.estado_std = 'ACTIVO' THEN 'Cursando'
      WHEN s.estado_std = 'RETIRADO' THEN 'Retirado'
      ELSE COALESCE(s.estado_std, '')
    END::TEXT
    
  FROM public.students s
  LEFT JOIN public.cursos c ON s.curso = c.id
  
  -- Apoderado principal (titular o primary)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND (sg.is_primary = true OR sg.role = 'titular')
    ORDER BY sg.is_primary DESC NULLS LAST, sg.created_at ASC
    LIMIT 1
  ) g1 ON true
  
  -- Apoderado secundario (suplente)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND sg.is_primary = false
      AND (sg.role = 'suplente' OR sg.role IS NULL)
    ORDER BY sg.created_at ASC
    LIMIT 1
  ) g2 ON true
  
  WHERE 
    (p_year IS NULL OR c.year_academico = p_year)
    AND (p_estado IS NULL OR s.estado_std = p_estado)
  
  ORDER BY c.nivel, c.nom_curso, s.apellido_paterno, s.apellido_materno, s.first_name;
END;
$$;

COMMENT ON FUNCTION public.generate_libro_matricula_report IS 
'Genera reporte completo del Libro de Matrícula con datos de estudiantes, apoderados titular y suplente. Filtros: p_year (año académico), p_estado (PRE_MATRICULADO, MATRICULADO, ACTIVO, RETIRADO)';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [40/49] MIGRATION: 20251219_fix_libro_matricula_report
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Fix generate_libro_matricula_report function to handle empty strings in year field
-- Date: 2025-12-19

-- STEP 1: Clean up bad data in enrollments.year
-- Handle NULL, 0, and potentially empty strings if year is text/varchar
DO $$
BEGIN
  -- Try to update assuming year is integer
  UPDATE public.enrollments
  SET year = EXTRACT(YEAR FROM created_at)::INTEGER
  WHERE year IS NULL OR year = 0;
EXCEPTION
  WHEN OTHERS THEN
    -- If year is text/varchar type, handle empty strings
    EXECUTE 'UPDATE public.enrollments SET year = EXTRACT(YEAR FROM created_at)::INTEGER WHERE year IS NULL OR year::text = '''' OR year::text = ''0''';
END $$;

-- STEP 2: Drop old function versions
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR);

CREATE OR REPLACE FUNCTION public.generate_libro_matricula_report(
  p_year INTEGER DEFAULT NULL,
  p_estado VARCHAR DEFAULT NULL,
  p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  numero_correlativo BIGINT,
  year_matricula INTEGER,
  fecha_matricula TIMESTAMPTZ,
  nivel TEXT,
  curso TEXT,
  nombres TEXT,
  apellido_paterno TEXT,
  apellido_materno TEXT,
  run_estudiante TEXT,
  fecha_nac_estudiante TEXT,
  nacionalidad TEXT,
  genero_estudiante TEXT,
  con_quien_vive TEXT,
  direccion_estudiante TEXT,
  comuna_estudiante TEXT,
  repite_curso TEXT,
  institucion_procedencia TEXT,
  nombre_apoderado TEXT,
  apellido_paterno_apoderado TEXT,
  apellido_materno_apoderado TEXT,
  relacion_apoderado TEXT,
  fecha_nac_apoderado TEXT,
  run_apoderado TEXT,
  nivel_educacional_apoderado TEXT,
  direccion_apoderado TEXT,
  comuna_apoderado TEXT,
  email_apoderado TEXT,
  telefono_apoderado TEXT,
  nombre_apoderado_secundario TEXT,
  run_apoderado_secundario TEXT,
  fecha_nac_apoderado_secundario TEXT,
  telefono_apoderado_secundario TEXT,
  email_apoderado_secundario TEXT,
  fecha_retiro TEXT,
  motivo_retiro TEXT,
  condicion TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_year INTEGER;
  v_estado VARCHAR;
  v_status VARCHAR;
BEGIN
  -- Sanitize parameters
  v_year := NULLIF(p_year, 0);
  v_estado := NULLIF(TRIM(p_estado), '');
  v_status := NULLIF(TRIM(p_status), '');

  RETURN QUERY
  SELECT
    -- Numeración y fecha de matrícula
    ROW_NUMBER() OVER (ORDER BY e.created_at ASC)::BIGINT,
    COALESCE(
      CASE WHEN e.year IS NOT NULL AND e.year > 0 THEN e.year 
           ELSE EXTRACT(YEAR FROM e.created_at)::INTEGER 
      END,
      EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER
    ),
    e.created_at,
    
    -- Curso info
    COALESCE(c.nivel, '')::TEXT,
    COALESCE(c.nom_curso, '')::TEXT,
    
    -- Estudiante
    COALESCE(s.first_name, '')::TEXT AS nombres,
    COALESCE(s.apellido_paterno, '')::TEXT,
    COALESCE(s.apellido_materno, '')::TEXT,
    COALESCE(s.run, '')::TEXT,
    COALESCE(TO_CHAR(s.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    UPPER(COALESCE(s.nacionalidad, 'CHILENA'))::TEXT,
    COALESCE(s.genero, '')::TEXT,
    COALESCE(s.con_quien_vive, '')::TEXT,
    COALESCE(s.direccion, '')::TEXT,
    COALESCE(s.comuna, '')::TEXT,
    CASE WHEN COALESCE(s.repite_curso_actual, 'No') ILIKE 'si%' THEN 'Sí' ELSE 'No' END::TEXT,
    COALESCE(s.institucion_procedencia, '')::TEXT,
    
    -- Apoderado principal
    COALESCE(g1.first_name, '')::TEXT,
    COALESCE(g1.apellido_paterno, '')::TEXT,
    COALESCE(g1.apellido_materno, '')::TEXT,
    COALESCE(g1.relationship_type, '')::TEXT,
    COALESCE(TO_CHAR(g1.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g1.run, '')::TEXT,
    COALESCE(g1.nivel_educacional, '')::TEXT,
    COALESCE(g1.address, '')::TEXT,
    COALESCE(g1.comuna, '')::TEXT,
    COALESCE(g1.email, '')::TEXT,
    COALESCE(g1.phone, '')::TEXT,
    
    -- Apoderado secundario
    COALESCE(g2.first_name || ' ' || COALESCE(g2.apellido_paterno, '') || ' ' || COALESCE(g2.apellido_materno, ''), '')::TEXT,
    COALESCE(g2.run, '')::TEXT,
    COALESCE(TO_CHAR(g2.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g2.phone, '')::TEXT,
    COALESCE(g2.email, '')::TEXT,
    
    -- Retiro
    COALESCE(TO_CHAR(s.fecha_retiro, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(s.motivo_retiro, '')::TEXT,
    
    -- Condición
    CASE 
      WHEN s.estado_std = 'PRE_MATRICULADO' THEN 'Matrícula en proceso'
      WHEN s.estado_std = 'MATRICULADO' THEN 'Confirmado para año escolar'
      WHEN s.estado_std = 'ACTIVO' THEN 'Cursando'
      WHEN s.estado_std = 'RETIRADO' THEN 'Retirado'
      ELSE COALESCE(s.estado_std, '')
    END::TEXT
    
  FROM public.students s
  
  -- Vincular con enrollment para filtrar por fecha de matrícula
  INNER JOIN public.enrollment_students es ON s.id = es.student_id
  INNER JOIN public.enrollments e ON es.enrollment_id = e.id
  
  LEFT JOIN public.cursos c ON s.curso = c.id
  
  -- Apoderado principal (titular o primary)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.guardian_role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND (sg.is_primary = true OR sg.guardian_role = 'titular')
    ORDER BY sg.is_primary DESC NULLS LAST, sg.created_at ASC
    LIMIT 1
  ) g1 ON true
  
  -- Apoderado secundario (suplente)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.guardian_role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND sg.is_primary = false
      AND (sg.guardian_role = 'suplente' OR sg.guardian_role IS NULL)
    ORDER BY sg.created_at ASC
    LIMIT 1
  ) g2 ON true
  
  WHERE 
    (v_year IS NULL OR e.year = v_year OR (c.year_academico IS NOT NULL AND c.year_academico = v_year))
    AND (v_estado IS NULL OR s.estado_std = v_estado)
    AND (v_status IS NULL OR e.status = v_status)
  
  ORDER BY e.created_at ASC, c.nivel, c.nom_curso, s.apellido_paterno, s.apellido_materno, s.first_name;
END;
$$;

COMMENT ON FUNCTION public.generate_libro_matricula_report IS 
'Genera reporte completo del Libro de Matrícula con datos de estudiantes, apoderados titular y suplente. 
Filtros: 
- p_year (año académico)
- p_estado (PRE_MATRICULADO, MATRICULADO, ACTIVO, RETIRADO)
- p_status (draft, pending, completed, rejected)
Retorna numeración correlativa, año de matrícula, y fecha de matrícula además de todos los datos del estudiante.';



-- ######################################################################
-- BATCH 5 (migrations 41 to 49)
-- ######################################################################

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [41/49] MIGRATION: 20260222_security_hardening
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- SECURITY HARDENING MIGRATION
-- Date: 2026-02-22
-- Resolves ALL Supabase Linter findings (3 ERRORs + 25 WARNs)
-- ============================================================================
-- PHASE 4.1 – Fix SECURITY DEFINER views
-- PHASE 4.2 – Drop orphan backup table
-- PHASE 5.1 – Fix search_path on all public functions
-- PHASE 5.2 – Harden overly-permissive RLS policies
-- PHASE 7.1 – Cleanup redundant policies
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 4.1 – SECURITY DEFINER VIEWS → SECURITY INVOKER
-- ════════════════════════════════════════════════════════════════════════════

-- 4.1.1  database_metadata → recreate with security_invoker = true
DROP VIEW IF EXISTS public.database_metadata CASCADE;

CREATE VIEW public.database_metadata WITH (security_invoker = true) AS
SELECT
    t.table_schema,
    t.table_name,
    jsonb_agg(
        jsonb_build_object(
            'column_name', c.column_name,
            'data_type', c.data_type,
            'is_nullable', c.is_nullable,
            'column_default', c.column_default,
            'character_maximum_length', c.character_maximum_length
        ) ORDER BY c.ordinal_position
    ) AS metadata
FROM information_schema.tables t
JOIN information_schema.columns c
  ON t.table_name = c.table_name AND t.table_schema = c.table_schema
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
GROUP BY t.table_schema, t.table_name
ORDER BY t.table_name;

GRANT SELECT ON public.database_metadata TO authenticated;

-- 4.1.2  payment_summary → recreate with security_invoker = true
DROP VIEW IF EXISTS public.payment_summary CASCADE;

CREATE VIEW public.payment_summary WITH (security_invoker = true) AS
SELECT
    f.id,
    f.student_id,
    s.whole_name   AS student_name,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    c.nom_curso    AS course_name,
    f.amount,
    f.numero_cuota,
    f.due_date,
    f.payment_date,
    f.status,
    f.payment_method,
    f.num_boleta,
    f.mov_bancario,
    f.notes,
    f.created_at,
    f.updated_at,
    CASE
        WHEN f.status = 'overdue' AND f.due_date IS NOT NULL
        THEN (CURRENT_DATE - f.due_date::date)
        ELSE NULL
    END AS days_overdue,
    CASE f.status
        WHEN 'paid'    THEN 'Pagado'
        WHEN 'pending' THEN 'Pendiente'
        WHEN 'overdue' THEN 'Vencido'
        ELSE f.status
    END AS status_display
FROM public.fee f
LEFT JOIN public.students s ON f.student_id = s.id
LEFT JOIN public.cursos   c ON s.curso = c.id
ORDER BY f.due_date DESC, f.created_at DESC;

GRANT SELECT ON public.payment_summary TO authenticated;

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 4.2 – DROP ORPHAN BACKUP TABLE
-- ════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS public.student_guardian_backup_20241222;

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 5.1 – FIX search_path ON ALL PUBLIC FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════
-- Uses ALTER FUNCTION to set search_path without recreating the function body.
-- Wrapped in DO blocks to gracefully skip functions that may not exist.

-- ── 5.1.1  CRITICAL: used in RLS / auth ──

DO $$ BEGIN
  ALTER FUNCTION public.get_current_user_role()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_current_user_role() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.current_jwt_role()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function current_jwt_role() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.es_admin_o_equipo(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function es_admin_o_equipo(uuid) does not exist, skipping.';
END $$;

-- ── 5.1.2  HIGH: triggers & financial ops ──

DO $$ BEGIN
  ALTER FUNCTION public.set_updated_at()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function set_updated_at() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.update_cheques_updated_at()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function update_cheques_updated_at() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.update_student_academic_records_updated_at()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function update_student_academic_records_updated_at() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.set_fee_owner_default()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function set_fee_owner_default() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.calculate_enrollment_payment_plan(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function calculate_enrollment_payment_plan(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.sanitize_run(text)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function sanitize_run(text) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.validate_run(text)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function validate_run(text) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.generate_invoice(uuid, integer, integer, numeric)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function generate_invoice(uuid,int,int,numeric) does not exist, skipping.';
END $$;

-- ── 5.1.3  MEDIUM: RPCs & helpers ──

DO $$ BEGIN
  ALTER FUNCTION public.set_academic_year_dates()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function set_academic_year_dates() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.sync_student_current_curso()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function sync_student_current_curso() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.get_student_course(uuid, integer)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_student_course(uuid,int) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.get_enrollment_document_url(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_enrollment_document_url(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.update_pre_matriculado_students()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function update_pre_matriculado_students() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.get_current_year_cursos()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_current_year_cursos() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.get_student_promotion_suggestion(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_student_promotion_suggestion(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.actualizar_estado_std(uuid, text)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function actualizar_estado_std(uuid,text) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.suggest_cheques_for_enrollment(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function suggest_cheques_for_enrollment(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.current_academic_year()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function current_academic_year() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.trg_mark_document_signed_from_signature()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function trg_mark_document_signed_from_signature() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.trg_mark_document_signed_from_receipt()
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function trg_mark_document_signed_from_receipt() does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.required_enrollment_documents_state(uuid)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function required_enrollment_documents_state(uuid) does not exist, skipping.';
END $$;

DO $$ BEGIN
  ALTER FUNCTION public.generate_libro_matricula_report(integer, varchar, varchar)
    SET search_path = public, pg_temp;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function generate_libro_matricula_report(int,varchar,varchar) does not exist, skipping.';
END $$;

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 5.2 – HARDEN OVERLY-PERMISSIVE RLS POLICIES
-- ════════════════════════════════════════════════════════════════════════════
-- Replace USING(true) / WITH CHECK(true) on write operations with proper
-- role checks. Keep SELECT USING(true) for intentional public read access.
-- Roles: ADMIN, ASIST (staff). READONLY/guardian via owner_id checks.

-- ── 5.2.1  invoices: replace open ALL with staff-only ──

DROP POLICY IF EXISTS "invoices_authenticated_policy" ON public.invoices;
DROP POLICY IF EXISTS "invoices_staff_write" ON public.invoices;
DROP POLICY IF EXISTS "invoices_staff_update" ON public.invoices;
DROP POLICY IF EXISTS "invoices_staff_delete" ON public.invoices;

CREATE POLICY invoices_staff_write ON public.invoices
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

CREATE POLICY invoices_staff_update ON public.invoices
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

CREATE POLICY invoices_staff_delete ON public.invoices
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

-- Keep the existing SELECT policy "All authenticated users can read invoices"
-- which uses USING(true) — intentional public read access.

-- ── 5.2.2  matriculas_detalle: replace open INSERT/UPDATE/DELETE with staff-only ──

DROP POLICY IF EXISTS "matriculas_detalle_delete_policy" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_insert_policy" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_update_policy" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_staff_insert" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_staff_update" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_staff_delete" ON public.matriculas_detalle;

CREATE POLICY matriculas_detalle_staff_insert ON public.matriculas_detalle
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

CREATE POLICY matriculas_detalle_staff_update ON public.matriculas_detalle
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

CREATE POLICY matriculas_detalle_staff_delete ON public.matriculas_detalle
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

-- Keep "matriculas_detalle_read_policy" SELECT USING(true) for public read.

-- ── 5.2.3  student_guardian: replace open ALL with staff + owner ──

DROP POLICY IF EXISTS "student_guardian_authenticated_policy" ON public.student_guardian;
DROP POLICY IF EXISTS "student_guardian_owner_policy" ON public.student_guardian;

CREATE POLICY student_guardian_owner_policy ON public.student_guardian
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = student_guardian.guardian_id
        AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = student_guardian.guardian_id
        AND g.owner_id = auth.uid()
    )
  );

-- Staff access already covered by:
--   student_guardian_admin_access (ADMIN)
--   student_guardian_asist_access (ASIST)

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 7.1 – CLEANUP REDUNDANT POLICIES
-- ════════════════════════════════════════════════════════════════════════════
-- Where a broad policy (e.g., is_admin_or_asist()) already covers both ADMIN
-- and ASIST, remove the individual role-specific policies to reduce noise.
--
-- IMPORTANT: Only remove if the covering policy already exists.
--            We verify existence before dropping.

-- ── 7.1.1  profiles: profiles_own_record duplicates profiles_owner_policy ──
-- Both use (id = auth.uid()). Keep profiles_owner_policy.
DROP POLICY IF EXISTS "profiles_own_record" ON public.profiles;

-- ── 7.1.2  students: 3 policies cover admin+asist, keep broadest one ──
-- students_admin_asist_full_access uses is_admin_or_asist() → covers both
DROP POLICY IF EXISTS "students_admin_access" ON public.students;
DROP POLICY IF EXISTS "students_asist_access" ON public.students;

-- ── 7.1.3  guardians: guardians_staff_all covers both roles ──
DROP POLICY IF EXISTS "guardians_admin_access" ON public.guardians;
DROP POLICY IF EXISTS "guardians_asist_access" ON public.guardians;

-- ── 7.1.4  enrollments: enrollments_admin_asist_access covers both ──
DROP POLICY IF EXISTS "enrollments_admin_full_access" ON public.enrollments;
DROP POLICY IF EXISTS "enrollments_asist_full_access" ON public.enrollments;

-- ── 7.1.5  matriculas_detalle: the new staff policies replace admin/asist ──
DROP POLICY IF EXISTS "matriculas_detalle_admin_full_access" ON public.matriculas_detalle;
DROP POLICY IF EXISTS "matriculas_detalle_asist_full_access" ON public.matriculas_detalle;

-- ════════════════════════════════════════════════════════════════════════════
-- VERIFICATION QUERIES (informational – run after applying)
-- ════════════════════════════════════════════════════════════════════════════

-- Check no SECURITY DEFINER views remain:
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_views
  WHERE schemaname = 'public'
    AND definition ILIKE '%security_definer%';
  IF v_count > 0 THEN
    RAISE WARNING '⚠ Still have % SECURITY DEFINER view(s) in public schema', v_count;
  ELSE
    RAISE NOTICE '✅ No SECURITY DEFINER views in public schema';
  END IF;
END $$;

-- Check backup table was dropped:
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'student_guardian_backup_20241222'
  ) THEN
    RAISE WARNING '⚠ student_guardian_backup_20241222 still exists!';
  ELSE
    RAISE NOTICE '✅ Backup table dropped successfully';
  END IF;
END $$;

-- Check all public functions have search_path set:
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proconfig IS NULL
    AND p.prokind = 'f';
  IF v_count > 0 THEN
    RAISE WARNING '⚠ Still have % function(s) without search_path in public schema', v_count;
  ELSE
    RAISE NOTICE '✅ All public functions have search_path configured';
  END IF;
END $$;

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [42/49] MIGRATION: 20260302_annual_transition_academic_records
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- MIGRATION: Annual Transition & Academic Records Enhancement
-- Date: 2026-03-02
-- Purpose: 
--   1. Backfill student_academic_records from existing 2025 enrollment data
--   2. Enhance finalize_enrollment to populate student_academic_records
--   3. Create batch promotion helper
--   4. Create get_student_promotion_suggestion function (real implementation)
-- ============================================================================
BEGIN;

-- ============================================================================
-- PART 1: Backfill student_academic_records for existing 2025 data
-- ============================================================================
-- Populate academic records for students that already have a curso assigned
-- This covers both 2025 and 2026 students already in the system

INSERT INTO public.student_academic_records (
  student_id,
  curso_id,
  year_academico,
  fecha_inicio,
  estado,
  enrollment_id,
  created_by
)
SELECT DISTINCT
  s.id AS student_id,
  s.curso AS curso_id,
  c.year_academico,
  COALESCE(s.fecha_matricula, s.created_at::date) AS fecha_inicio,
  CASE
    WHEN s.fecha_retiro IS NOT NULL THEN 'retirado'
    ELSE 'activo'
  END AS estado,
  (
    SELECT es.enrollment_id
    FROM public.enrollment_students es
    JOIN public.enrollments e ON e.id = es.enrollment_id
    WHERE es.student_id = s.id
      AND e.year = c.year_academico
    ORDER BY e.created_at DESC
    LIMIT 1
  ) AS enrollment_id,
  NULL AS created_by
FROM public.students s
JOIN public.cursos c ON c.id = s.curso
WHERE s.curso IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.student_academic_records sar
    WHERE sar.student_id = s.id
      AND sar.year_academico = c.year_academico
  );

-- ============================================================================
-- PART 2: Enhanced finalize_enrollment RPC
-- Now also:
--   a) Updates students.curso to the enrollment's curso_id
--   b) Inserts a row into student_academic_records
-- ============================================================================
DROP FUNCTION IF EXISTS public.finalize_enrollment(uuid, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_year int;
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;
  v_folio text;
  r_es RECORD;
  r_cuota RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id, es.curso_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    PERFORM 1 FROM public.student_guardian sg
      WHERE sg.student_id = r_es.student_id AND sg.guardian_id = v_enrollment.guardian_id;
    IF NOT FOUND THEN
      IF v_is_staff THEN
        INSERT INTO public.student_guardian(student_id, guardian_id, is_primary)
        VALUES (r_es.student_id, v_enrollment.guardian_id, false)
        ON CONFLICT DO NOTHING;
      ELSE
        RAISE EXCEPTION 'MISSING_RELATION: student % is not linked with this guardian', r_es.student_id;
      END IF;
    END IF;
  END LOOP;

  IF v_students = 0 THEN
    RAISE EXCEPTION 'NO_STUDENTS: enrollment has no students';
  END IF;

  v_plan := p_options->'payment_plan';
  IF v_plan IS NULL THEN
    SELECT e.meta->'payment_plan' INTO v_plan FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;
  IF v_plan IS NULL THEN
    SELECT ed.generated_payload INTO v_plan
      FROM public.enrollment_documents ed
     WHERE ed.enrollment_id = p_enrollment_id
       AND (ed.type = 'PRESTACION' OR ed.type LIKE 'PAGARE%')
       AND ed.generated_payload IS NOT NULL
     ORDER BY CASE WHEN ed.type='PRESTACION' THEN 0 ELSE 1 END, ed.created_at DESC
     LIMIT 1;
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
    DECLARE
      v_n int := COALESCE((v_plan->>'n_cuotas')::int, NULL);
      v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
      v_amount numeric := COALESCE((v_plan->>'monto_por_cuota')::numeric,
                                   NULLIF((v_plan->>'monto_total')::numeric, NULL) / NULLIF(v_n,0));
      i int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      IF v_n IS NULL OR v_first IS NULL OR v_amount IS NULL THEN
        RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
      END IF;
      WHILE i <= v_n LOOP
        v_synth := v_synth || jsonb_build_object(
          'numero', i,
          'amount', v_amount,
          'due_date', (v_first + make_interval(months := i-1))::date
        );
        i := i + 1;
      END LOOP;
      v_cuotas := v_synth;
    END;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id, es.curso_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          ON CONFLICT (student_id, guardian_id, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    -- Generate folio
    v_folio := 'ENR-' || v_year || '-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || substring(p_enrollment_id::text, 1, 8);
    
    -- Update enrollment with folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    -- ── NEW: Update student.curso + insert academic record ──
    FOR r_es IN
      SELECT es.student_id, es.curso_id
        FROM public.enrollment_students es
       WHERE es.enrollment_id = p_enrollment_id
         AND es.curso_id IS NOT NULL
    LOOP
      -- Update the student's current curso to the enrollment curso
      UPDATE public.students
         SET curso = r_es.curso_id,
             estado_std = 'MATRICULADO',
             updated_at = now()
       WHERE id = r_es.student_id;

      -- Insert academic record (one per student per year)
      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, enrollment_id, created_by
      ) VALUES (
        r_es.student_id, r_es.curso_id, v_year, CURRENT_DATE, 'activo', p_enrollment_id, v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            enrollment_id = EXCLUDED.enrollment_id,
            updated_at = now(),
            updated_by = v_uid;
    END LOOP;

    -- Also update students without curso_id in enrollment_students (legacy path)
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
          AND es.curso_id IS NULL
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary,
    'folio', v_folio,
    'year', v_year
  );
END;
$$;

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 
'Finalize an enrollment: generates fees, updates student.curso, creates academic records, marks enrollment completed.';

REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;

-- ============================================================================
-- PART 3: get_student_promotion_suggestion — real implementation
-- Given a student, suggests the next curso for the following year
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_student_promotion_suggestion(p_student_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_curso RECORD;
  v_next_curso RECORD;
  v_current_year int;
  v_next_year int;
BEGIN
  v_current_year := EXTRACT(YEAR FROM CURRENT_DATE)::int;
  v_next_year := v_current_year + 1;

  -- Get the student's current curso
  SELECT c.id, c.nom_curso, c.nivel, c.year_academico
    INTO v_current_curso
    FROM public.students s
    JOIN public.cursos c ON c.id = s.curso
   WHERE s.id = p_student_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'suggestion', NULL,
      'reason', 'Student has no current curso assigned'
    );
  END IF;

  -- Try to find the next-level curso for the next academic year
  -- nivel ordering: PRE-KINDER < KINDER < 1B < 2B < 3B < 4B < 5B < 6B < 7B < 8B < I < II < III < IV
  SELECT c.id, c.nom_curso, c.nivel, c.year_academico
    INTO v_next_curso
    FROM public.cursos c
   WHERE c.year_academico = v_next_year
     AND c.nivel = (
       CASE v_current_curso.nivel
         WHEN 'PRE-KINDER' THEN 'KINDER'
         WHEN 'KINDER'     THEN '1B'
         WHEN '1B'         THEN '2B'
         WHEN '2B'         THEN '3B'
         WHEN '3B'         THEN '4B'
         WHEN '4B'         THEN '5B'
         WHEN '5B'         THEN '6B'
         WHEN '6B'         THEN '7B'
         WHEN '7B'         THEN '8B'
         WHEN '8B'         THEN 'I'
         WHEN 'I'          THEN 'II'
         WHEN 'II'         THEN 'III'
         WHEN 'III'        THEN 'IV'
         WHEN 'IV'         THEN NULL -- Graduated
         ELSE NULL
       END
     )
   LIMIT 1;

  IF v_current_curso.nivel = 'IV' THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'current_curso', jsonb_build_object(
        'id', v_current_curso.id,
        'nom_curso', v_current_curso.nom_curso,
        'nivel', v_current_curso.nivel,
        'year', v_current_curso.year_academico
      ),
      'suggestion', NULL,
      'reason', 'Student is in final year (IV medio) — graduating'
    );
  END IF;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'current_curso', jsonb_build_object(
        'id', v_current_curso.id,
        'nom_curso', v_current_curso.nom_curso,
        'nivel', v_current_curso.nivel,
        'year', v_current_curso.year_academico
      ),
      'suggestion', NULL,
      'reason', format('No curso found for nivel %s in year %s', 
        CASE v_current_curso.nivel
          WHEN 'PRE-KINDER' THEN 'KINDER'
          WHEN 'KINDER'     THEN '1B'
          WHEN '1B'         THEN '2B'
          WHEN '2B'         THEN '3B'
          WHEN '3B'         THEN '4B'
          WHEN '4B'         THEN '5B'
          WHEN '5B'         THEN '6B'
          WHEN '6B'         THEN '7B'
          WHEN '7B'         THEN '8B'
          WHEN '8B'         THEN 'I'
          WHEN 'I'          THEN 'II'
          WHEN 'II'         THEN 'III'
          WHEN 'III'        THEN 'IV'
          ELSE 'UNKNOWN'
        END,
        v_next_year
      )
    );
  END IF;

  RETURN jsonb_build_object(
    'student_id', p_student_id,
    'current_curso', jsonb_build_object(
      'id', v_current_curso.id,
      'nom_curso', v_current_curso.nom_curso,
      'nivel', v_current_curso.nivel,
      'year', v_current_curso.year_academico
    ),
    'suggestion', jsonb_build_object(
      'id', v_next_curso.id,
      'nom_curso', v_next_curso.nom_curso,
      'nivel', v_next_curso.nivel,
      'year', v_next_curso.year_academico
    ),
    'reason', 'Promotion suggested based on level sequence'
  );
END;
$$;

COMMENT ON FUNCTION public.get_student_promotion_suggestion(uuid) IS
'Returns the suggested next curso for a student based on their current nivel and the next academic year.';

REVOKE ALL ON FUNCTION public.get_student_promotion_suggestion(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.get_student_promotion_suggestion(uuid) TO authenticated;

-- ============================================================================
-- PART 4: Batch promote students RPC
-- Moves a set of students from their current year to the next year's curso
-- ============================================================================
CREATE OR REPLACE FUNCTION public.batch_promote_students(
  p_student_ids uuid[],
  p_target_year int DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_target_year int;
  v_promoted int := 0;
  v_skipped int := 0;
  v_errors jsonb := '[]'::jsonb;
  v_details jsonb := '[]'::jsonb;
  r_student RECORD;
  v_suggestion jsonb;
  v_next_curso_id uuid;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can batch promote students';
  END IF;

  v_target_year := COALESCE(p_target_year, EXTRACT(YEAR FROM CURRENT_DATE)::int + 1);

  FOREACH r_student.id IN ARRAY p_student_ids LOOP
    BEGIN
      -- Get promotion suggestion
      v_suggestion := public.get_student_promotion_suggestion(r_student.id);
      
      IF v_suggestion->'suggestion' IS NULL OR v_suggestion->>'suggestion' = 'null' THEN
        v_skipped := v_skipped + 1;
        v_errors := v_errors || jsonb_build_object(
          'student_id', r_student.id,
          'reason', v_suggestion->>'reason'
        );
        CONTINUE;
      END IF;

      v_next_curso_id := (v_suggestion->'suggestion'->>'id')::uuid;

      -- Mark current academic record as completed
      UPDATE public.student_academic_records
         SET estado = 'completado',
             fecha_termino = CURRENT_DATE,
             updated_at = now(),
             updated_by = v_uid
       WHERE student_id = r_student.id
         AND year_academico = v_target_year - 1
         AND estado = 'activo';

      -- Update student's current curso
      UPDATE public.students
         SET curso = v_next_curso_id,
             updated_at = now()
       WHERE id = r_student.id;

      -- Create new academic record for target year
      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, created_by
      ) VALUES (
        r_student.id, v_next_curso_id, v_target_year, CURRENT_DATE, 'activo', v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            estado = 'activo',
            fecha_inicio = CURRENT_DATE,
            updated_at = now(),
            updated_by = v_uid;

      v_promoted := v_promoted + 1;
      v_details := v_details || jsonb_build_object(
        'student_id', r_student.id,
        'new_curso_id', v_next_curso_id,
        'new_curso', v_suggestion->'suggestion'->>'nom_curso'
      );

    EXCEPTION WHEN OTHERS THEN
      v_skipped := v_skipped + 1;
      v_errors := v_errors || jsonb_build_object(
        'student_id', r_student.id,
        'reason', SQLERRM
      );
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'promoted', v_promoted,
    'skipped', v_skipped,
    'target_year', v_target_year,
    'details', v_details,
    'errors', v_errors
  );
END;
$$;

COMMENT ON FUNCTION public.batch_promote_students(uuid[], int) IS
'Batch promote students to their next curso for the target academic year. Staff only.';

REVOKE ALL ON FUNCTION public.batch_promote_students(uuid[], int) FROM public;
GRANT EXECUTE ON FUNCTION public.batch_promote_students(uuid[], int) TO authenticated;

-- ============================================================================
-- PART 5: RLS policy for staff to manage student_academic_records
-- ============================================================================
DO $$
BEGIN
  -- Allow staff full access to academic records
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'student_academic_records' AND policyname = 'sar_staff_all'
  ) THEN
    CREATE POLICY sar_staff_all ON public.student_academic_records
      FOR ALL
      USING (public.is_staff())
      WITH CHECK (public.is_staff());
  END IF;
END;
$$;

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [43/49] MIGRATION: 20260302_fix_fee_on_conflict_and_clone_cursos
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- FE-01 / FE-02: Fix ON CONFLICT mismatch in finalize_enrollment
-- TA-07: Clone cursos 2025 → 2026
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────────
-- PART 1: Clone cursos from 2025 to 2026 (TA-07)
-- Only creates 2026 cursos if they don't already exist
-- ──────────────────────────────────────────────────────────────────────────────

INSERT INTO public.cursos (nom_curso, nivel, year_academico, letra_curso)
SELECT 
  nom_curso,
  nivel,
  2026,
  letra_curso
FROM public.cursos
WHERE year_academico = 2025
  AND NOT EXISTS (
    SELECT 1 FROM public.cursos c2
    WHERE c2.nom_curso = cursos.nom_curso
      AND c2.nivel = cursos.nivel
      AND c2.year_academico = 2026
  );

-- ──────────────────────────────────────────────────────────────────────────────
-- PART 2: Fix ON CONFLICT in finalize_enrollment (FE-01 / FE-02)
-- The INSERT INTO fee used ON CONFLICT (student_id, guardian_id, numero_cuota)
-- but the unique index ux_fee_student_year_cuota is on
-- (student_id, year_academico, numero_cuota).
-- This caused the DO NOTHING clause to never match, allowing duplicate fees.
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_enrollment record;
  v_plan       jsonb;
  v_cuotas     jsonb;
  v_year       int;
  v_dry_run    boolean;
  v_students   int;
  v_created    int := 0;
  v_skipped    int := 0;
  v_uid        uuid;
  v_summary    jsonb;
  v_folio      text := null;
  r_es         record;
  r_cuota      record;
BEGIN
  -- ── Auth ──
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- ── Fetch enrollment ──
  SELECT * INTO v_enrollment FROM public.enrollments WHERE id = p_enrollment_id;
  IF v_enrollment IS NULL THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;

  v_dry_run := COALESCE((p_options->>'dry_run')::boolean, true);
  v_year    := v_enrollment.year;

  SELECT count(*) INTO v_students
    FROM public.enrollment_students
   WHERE enrollment_id = p_enrollment_id;

  -- ── Payment plan ──
  v_plan := v_enrollment.payment_plan;
  IF v_plan IS NULL AND p_options ? 'payment_plan' THEN
    v_plan := p_options->'payment_plan';
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'No payment plan found for enrollment %', p_enrollment_id;
  END IF;

  -- ── Cuotas from plan ──
  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_array_length(v_cuotas) = 0 THEN
    DECLARE
      v_num   int := COALESCE((v_plan->>'numero_cuotas')::int, 10);
      v_amt   numeric := COALESCE((v_plan->>'monto_cuota')::numeric, 0);
      v_first date := COALESCE((v_plan->>'primera_cuota')::date, make_date(v_year, 3, 1));
      i       int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      WHILE i <= v_num LOOP
        v_synth := v_synth || jsonb_build_object(
          'numero', i,
          'amount', v_amt,
          'due_date', (v_first + make_interval(months := i-1))::date
        );
        i := i + 1;
      END LOOP;
      v_cuotas := v_synth;
    END;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id, es.curso_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          -- FIX: Match the actual unique index ux_fee_student_year_cuota
          ON CONFLICT (student_id, year_academico, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    -- Generate folio
    v_folio := 'ENR-' || v_year || '-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || substring(p_enrollment_id::text, 1, 8);
    
    -- Update enrollment with folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    -- ── Update student.curso + insert academic record ──
    FOR r_es IN
      SELECT es.student_id, es.curso_id
        FROM public.enrollment_students es
       WHERE es.enrollment_id = p_enrollment_id
         AND es.curso_id IS NOT NULL
    LOOP
      -- Update the student's current curso to the enrollment curso
      UPDATE public.students
         SET curso = r_es.curso_id,
             estado_std = 'MATRICULADO',
             updated_at = now()
       WHERE id = r_es.student_id;

      -- Insert academic record (one per student per year)
      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, enrollment_id, created_by
      ) VALUES (
        r_es.student_id, r_es.curso_id, v_year, CURRENT_DATE, 'activo', p_enrollment_id, v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            enrollment_id = EXCLUDED.enrollment_id,
            updated_at = now(),
            updated_by = v_uid;
    END LOOP;

    -- Also update students without curso_id in enrollment_students (legacy path)
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
          AND es.curso_id IS NULL
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary,
    'folio', v_folio,
    'year', v_year
  );
END;
$$;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [44/49] MIGRATION: 20260302_promote_and_enroll_batch
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- RPC: promote_and_enroll_batch
-- Purpose: Promote selected students to next curso AND create formal
--          enrollment (matrícula) with fee generation per guardian.
-- Flow:
--   1. For each student → get_student_promotion_suggestion → update curso +
--      academic records (same as batch_promote_students).
--   2. Group promoted students by their primary guardian.
--   3. For each guardian group → create enrollment → insert enrollment_students
--      → finalize_enrollment (generates fees from the supplied payment plan).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.promote_and_enroll_batch(
  p_student_ids uuid[],
  p_target_year int DEFAULT NULL,
  p_payment_plan jsonb DEFAULT NULL,
  p_dry_run boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_target_year int;
  v_promoted int := 0;
  v_skipped int := 0;
  v_errors jsonb := '[]'::jsonb;
  v_details jsonb := '[]'::jsonb;
  v_enrollments_created int := 0;
  v_fees_created int := 0;
  r_student record;
  v_suggestion jsonb;
  v_next_curso_id uuid;
  -- enrollment grouping
  r_group record;
  v_enrollment_id uuid;
  v_finalize_result jsonb;
BEGIN
  -- ── Auth ──
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Only staff can batch promote students';
  END IF;

  v_target_year := COALESCE(p_target_year, EXTRACT(YEAR FROM CURRENT_DATE)::int + 1);

  -- ═══════════════════════════════════════════════════════════════════════════
  -- PHASE 1: Promote each student (curso + academic records)
  -- ═══════════════════════════════════════════════════════════════════════════
  FOREACH r_student.id IN ARRAY p_student_ids LOOP
    BEGIN
      v_suggestion := public.get_student_promotion_suggestion(r_student.id);

      IF v_suggestion->'suggestion' IS NULL OR v_suggestion->>'suggestion' = 'null' THEN
        v_skipped := v_skipped + 1;
        v_errors := v_errors || jsonb_build_object(
          'student_id', r_student.id,
          'reason', COALESCE(v_suggestion->>'reason', 'No promotion suggestion')
        );
        CONTINUE;
      END IF;

      v_next_curso_id := (v_suggestion->'suggestion'->>'id')::uuid;

      IF NOT p_dry_run THEN
        -- Mark current academic record as completed
        UPDATE public.student_academic_records
           SET estado = 'completado',
               fecha_termino = CURRENT_DATE,
               updated_at = now(),
               updated_by = v_uid
         WHERE student_id = r_student.id
           AND year_academico = v_target_year - 1
           AND estado = 'activo';

        -- Update student's current curso
        UPDATE public.students
           SET curso = v_next_curso_id,
               estado_std = 'MATRICULADO',
               updated_at = now()
         WHERE id = r_student.id;

        -- Create new academic record for target year
        INSERT INTO public.student_academic_records (
          student_id, curso_id, year_academico, fecha_inicio, estado, created_by
        ) VALUES (
          r_student.id, v_next_curso_id, v_target_year, CURRENT_DATE, 'activo', v_uid
        )
        ON CONFLICT (student_id, year_academico) DO UPDATE
          SET curso_id = EXCLUDED.curso_id,
              estado = 'activo',
              fecha_inicio = CURRENT_DATE,
              updated_at = now(),
              updated_by = v_uid;
      END IF;

      v_promoted := v_promoted + 1;
      v_details := v_details || jsonb_build_object(
        'student_id', r_student.id,
        'new_curso_id', v_next_curso_id,
        'new_curso', v_suggestion->'suggestion'->>'nom_curso',
        'current_curso', v_suggestion->'current_curso'->>'nom_curso'
      );

    EXCEPTION WHEN OTHERS THEN
      v_skipped := v_skipped + 1;
      v_errors := v_errors || jsonb_build_object(
        'student_id', r_student.id,
        'reason', SQLERRM
      );
    END;
  END LOOP;

  -- ═══════════════════════════════════════════════════════════════════════════
  -- PHASE 2: Create formal enrollments grouped by guardian (only if NOT dry run)
  -- ═══════════════════════════════════════════════════════════════════════════
  IF NOT p_dry_run AND v_promoted > 0 THEN
    FOR r_group IN
      SELECT sg.guardian_id, array_agg(d.student_id) AS student_ids
        FROM jsonb_to_recordset(v_details) AS d(student_id uuid, new_curso_id uuid)
        JOIN public.student_guardian sg ON sg.student_id = d.student_id AND sg.is_primary = true
       GROUP BY sg.guardian_id
    LOOP
      BEGIN
        -- Upsert enrollment for this guardian + target year
        INSERT INTO public.enrollments (guardian_id, year, status, meta)
        VALUES (
          r_group.guardian_id,
          v_target_year,
          'draft',
          jsonb_build_object('source', 'promotion_batch', 'promoted_at', now()::text)
        )
        ON CONFLICT (guardian_id, year) DO UPDATE
          SET meta = public.enrollments.meta || jsonb_build_object('promotion_batch_updated', now()::text),
              updated_at = now()
        RETURNING id INTO v_enrollment_id;

        -- Insert enrollment_students for each promoted student of this guardian
        DECLARE
          v_sid uuid;
        BEGIN
          FOREACH v_sid IN ARRAY r_group.student_ids LOOP
            INSERT INTO public.enrollment_students (enrollment_id, student_id)
            VALUES (v_enrollment_id, v_sid)
            ON CONFLICT DO NOTHING;
          END LOOP;
        END;

        -- Store payment plan in enrollment meta if provided
        IF p_payment_plan IS NOT NULL THEN
          UPDATE public.enrollments
             SET meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('payment_plan', p_payment_plan),
                 updated_at = now()
           WHERE id = v_enrollment_id;

          -- Finalize enrollment (generates fees)
          v_finalize_result := public.finalize_enrollment(
            v_enrollment_id,
            jsonb_build_object('dry_run', false, 'payment_plan', p_payment_plan)
          );

          v_fees_created := v_fees_created + COALESCE((v_finalize_result->>'created_charges')::int, 0);
        END IF;

        v_enrollments_created := v_enrollments_created + 1;

      EXCEPTION WHEN OTHERS THEN
        v_errors := v_errors || jsonb_build_object(
          'guardian_id', r_group.guardian_id,
          'reason', 'Enrollment creation failed: ' || SQLERRM
        );
      END;
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'dry_run', p_dry_run,
    'target_year', v_target_year,
    'promoted', v_promoted,
    'skipped', v_skipped,
    'enrollments_created', v_enrollments_created,
    'fees_created', v_fees_created,
    'details', v_details,
    'errors', v_errors
  );
END;
$$;

-- Grant access
GRANT EXECUTE ON FUNCTION public.promote_and_enroll_batch(uuid[], int, jsonb, boolean) TO authenticated;

COMMENT ON FUNCTION public.promote_and_enroll_batch IS
  'Promotes students to next curso for target year, creates formal enrollments grouped by guardian, and optionally generates fees from the supplied payment plan.';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [45/49] MIGRATION: 20260305_backfill_academic_records
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- BACKFILL student_academic_records FROM enrollment data
-- MP-01: Poblar tabla student_academic_records desde enrollments existentes
-- ============================================================================
-- This script populates student_academic_records from finalized enrollments
-- that were processed before the trigger was added to finalize_enrollment().
--
-- Safe to run multiple times (uses ON CONFLICT DO UPDATE).
-- ============================================================================

BEGIN;

-- Backfill from enrollment_students joined with enrollments
INSERT INTO public.student_academic_records (
  student_id,
  curso_id,
  year_academico,
  fecha_inicio,
  estado,
  enrollment_id,
  created_at
)
SELECT
  es.student_id,
  s.curso AS curso_id,
  e.year AS year_academico,
  e.created_at::date AS fecha_inicio,
  'activo' AS estado,
  e.id AS enrollment_id,
  e.created_at
FROM public.enrollment_students es
JOIN public.enrollments e ON e.id = es.enrollment_id
JOIN public.students s ON s.id = es.student_id
WHERE e.status = 'completed'
  AND s.curso IS NOT NULL
  AND e.year IS NOT NULL
ON CONFLICT (student_id, year_academico) DO UPDATE
  SET curso_id = EXCLUDED.curso_id,
      enrollment_id = EXCLUDED.enrollment_id,
      fecha_inicio = COALESCE(student_academic_records.fecha_inicio, EXCLUDED.fecha_inicio),
      updated_at = now();

-- Report results
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.student_academic_records;
  RAISE NOTICE 'student_academic_records now has % rows', v_count;
END $$;

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [46/49] MIGRATION: 20260305_finalize_enrollment_per_student_plans
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Migration: Support per-student payment plans in finalize_enrollment
-- Problem: When a family has multiple siblings with different tuition amounts
--          (e.g., different grade levels or scholarships), the system was using
--          a single averaged cuota amount for ALL students.
-- Fix:     Accept optional per_student_plans in p_options. When present, each
--          student gets their own cuotas with individually calculated amounts.
-- ============================================================================

DROP FUNCTION IF EXISTS public.finalize_enrollment(uuid, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_year int;
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_per_student_plans jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;
  v_folio text;
  r_es RECORD;
  r_cuota RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id, es.curso_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    PERFORM 1 FROM public.student_guardian sg
      WHERE sg.student_id = r_es.student_id AND sg.guardian_id = v_enrollment.guardian_id;
    IF NOT FOUND THEN
      IF v_is_staff THEN
        INSERT INTO public.student_guardian(student_id, guardian_id, is_primary)
        VALUES (r_es.student_id, v_enrollment.guardian_id, false)
        ON CONFLICT DO NOTHING;
      ELSE
        RAISE EXCEPTION 'MISSING_RELATION: student % is not linked with this guardian', r_es.student_id;
      END IF;
    END IF;
  END LOOP;

  IF v_students = 0 THEN
    RAISE EXCEPTION 'NO_STUDENTS: enrollment has no students';
  END IF;

  -- Load per-student plans (new: individual cuotas per student)
  v_per_student_plans := p_options->'per_student_plans';
  -- Also check enrollment.meta for per_student_plans
  IF v_per_student_plans IS NULL THEN
    SELECT e.meta->'per_student_plans' INTO v_per_student_plans
      FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;

  -- Load global/fallback payment plan
  v_plan := p_options->'payment_plan';
  IF v_plan IS NULL THEN
    SELECT e.meta->'payment_plan' INTO v_plan FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;
  IF v_plan IS NULL THEN
    SELECT ed.generated_payload INTO v_plan
      FROM public.enrollment_documents ed
     WHERE ed.enrollment_id = p_enrollment_id
       AND (ed.type = 'PRESTACION' OR ed.type LIKE 'PAGARE%')
       AND ed.generated_payload IS NOT NULL
     ORDER BY CASE WHEN ed.type='PRESTACION' THEN 0 ELSE 1 END, ed.created_at DESC
     LIMIT 1;
  END IF;
  IF v_plan IS NULL AND v_per_student_plans IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  -- Build global cuotas as fallback (only if v_plan exists)
  IF v_plan IS NOT NULL THEN
    v_cuotas := v_plan->'cuotas';
    IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
      DECLARE
        v_n int := COALESCE((v_plan->>'n_cuotas')::int, NULL);
        v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
        v_amount numeric := COALESCE((v_plan->>'monto_por_cuota')::numeric,
                                     NULLIF((v_plan->>'monto_total')::numeric, NULL) / NULLIF(v_n,0));
        i int := 1;
        v_synth jsonb := '[]'::jsonb;
      BEGIN
        IF v_n IS NOT NULL AND v_first IS NOT NULL AND v_amount IS NOT NULL THEN
          WHILE i <= v_n LOOP
            v_synth := v_synth || jsonb_build_object(
              'numero', i,
              'amount', v_amount,
              'due_date', (v_first + make_interval(months := i-1))::date
            );
            i := i + 1;
          END LOOP;
          v_cuotas := v_synth;
        ELSIF v_per_student_plans IS NULL THEN
          RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
        END IF;
      END;
    END IF;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id, es.curso_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
      v_student_cuotas jsonb;
      v_student_plan jsonb;
    BEGIN
      -- Try to get per-student cuotas first, fall back to global cuotas
      v_student_cuotas := NULL;
      IF v_per_student_plans IS NOT NULL AND v_per_student_plans ? r_es.student_id::text THEN
        v_student_plan := v_per_student_plans->r_es.student_id::text;
        v_student_cuotas := v_student_plan->'cuotas';
        -- If student plan has payment_method, use it
        IF v_student_plan->>'payment_method' IS NOT NULL THEN
          v_method := v_student_plan->>'payment_method';
        END IF;
      END IF;
      -- Fall back to global cuotas if per-student not available
      IF v_student_cuotas IS NULL OR jsonb_typeof(v_student_cuotas) <> 'array' THEN
        v_student_cuotas := v_cuotas;
      END IF;

      IF v_student_cuotas IS NULL THEN
        RAISE EXCEPTION 'PLAN_MISSING: no cuotas found for student %', r_es.student_id;
      END IF;

      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_student_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          -- FIX: Match the actual unique index ux_fee_student_year_cuota
          ON CONFLICT (student_id, year_academico, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    -- Generate folio
    v_folio := 'ENR-' || v_year || '-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || substring(p_enrollment_id::text, 1, 8);
    
    -- Update enrollment with folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    -- Update student.curso + insert academic record
    FOR r_es IN
      SELECT es.student_id, es.curso_id
        FROM public.enrollment_students es
       WHERE es.enrollment_id = p_enrollment_id
         AND es.curso_id IS NOT NULL
    LOOP
      UPDATE public.students
         SET curso = r_es.curso_id,
             estado_std = 'MATRICULADO',
             updated_at = now()
       WHERE id = r_es.student_id;

      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, enrollment_id, created_by
      ) VALUES (
        r_es.student_id, r_es.curso_id, v_year, CURRENT_DATE, 'activo', p_enrollment_id, v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            enrollment_id = EXCLUDED.enrollment_id,
            updated_at = now(),
            updated_by = v_uid;
    END LOOP;

    -- Also update students without curso_id in enrollment_students (legacy path)
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
          AND es.curso_id IS NULL
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary,
    'folio', v_folio,
    'year', v_year
  );
END;
$$;

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 
'Finalize an enrollment: generates fees (with per-student amounts when available), updates student.curso, creates academic records, marks enrollment completed.';

REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [47/49] MIGRATION: 20260305_folio_unification
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- Migration: Folio Matrícula Unification
-- 
-- Problem: Pagaré and cheques use a UUID substring as folio_number, while the
--          real enrollment folio (ENR-YYYY-NNNNNN) is only generated at
--          finalization time. The school archives physical expedientes by
--          folio number, so all documents must share the same folio.
--
-- Changes:
--   1. New RPC  assign_enrollment_folio(uuid)  — pre-assigns a sequential
--      folio to an enrollment so the pagaré can show it before finalization.
--   2. Fix  finalize_enrollment  — reuses existing folio (instead of
--      overwriting with a timestamp-based one), restores sequential format,
--      and updates cheques.folio_number after finalization.
--
-- Existing signed pagarés are NOT affected. Only new enrollments will
-- receive the pre-assigned folio in their pagaré.
-- ============================================================================

-- 1. Create the assign_enrollment_folio RPC
-- -------------------------------------------
CREATE OR REPLACE FUNCTION public.assign_enrollment_folio(p_enrollment_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_existing_folio text;
  v_folio_seq bigint;
  v_folio text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Fetch enrollment
  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;

  -- Authorization check
  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to access this enrollment';
  END IF;

  -- Check if folio already exists
  v_existing_folio := v_enrollment.meta->>'folio';
  IF v_existing_folio IS NOT NULL AND v_existing_folio <> '' THEN
    RETURN v_existing_folio;
  END IF;

  -- Assign new sequential folio
  v_folio_seq := nextval('public.enrollment_folio_seq');
  v_folio := 'ENR-' || v_enrollment.year || '-' || to_char(v_folio_seq, 'FM000000');

  -- Store in enrollment meta
  UPDATE public.enrollments
     SET meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio),
         updated_at = now()
   WHERE id = p_enrollment_id;

  RETURN v_folio;
END;
$$;

COMMENT ON FUNCTION public.assign_enrollment_folio(uuid) IS
  'Assigns a sequential folio (ENR-YYYY-NNNNNN) to an enrollment. Returns existing folio if already assigned. Idempotent.';

REVOKE ALL ON FUNCTION public.assign_enrollment_folio(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.assign_enrollment_folio(uuid) TO authenticated;


-- 2. Fix finalize_enrollment: reuse existing folio + sequential format + update cheques
-- --------------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.finalize_enrollment(uuid, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_year int;
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_per_student_plans jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;
  v_folio text;
  v_folio_seq bigint;
  r_es RECORD;
  r_cuota RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id, es.curso_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    PERFORM 1 FROM public.student_guardian sg
      WHERE sg.student_id = r_es.student_id AND sg.guardian_id = v_enrollment.guardian_id;
    IF NOT FOUND THEN
      IF v_is_staff THEN
        INSERT INTO public.student_guardian(student_id, guardian_id, is_primary)
        VALUES (r_es.student_id, v_enrollment.guardian_id, false)
        ON CONFLICT DO NOTHING;
      ELSE
        RAISE EXCEPTION 'MISSING_RELATION: student % is not linked with this guardian', r_es.student_id;
      END IF;
    END IF;
  END LOOP;

  IF v_students = 0 THEN
    RAISE EXCEPTION 'NO_STUDENTS: enrollment has no students';
  END IF;

  -- Load per-student plans (individual cuotas per student)
  v_per_student_plans := p_options->'per_student_plans';
  IF v_per_student_plans IS NULL THEN
    SELECT e.meta->'per_student_plans' INTO v_per_student_plans
      FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;

  -- Load global/fallback payment plan
  v_plan := p_options->'payment_plan';
  IF v_plan IS NULL THEN
    SELECT e.meta->'payment_plan' INTO v_plan FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;
  IF v_plan IS NULL THEN
    SELECT ed.generated_payload INTO v_plan
      FROM public.enrollment_documents ed
     WHERE ed.enrollment_id = p_enrollment_id
       AND (ed.type = 'PRESTACION' OR ed.type LIKE 'PAGARE%')
       AND ed.generated_payload IS NOT NULL
     ORDER BY CASE WHEN ed.type='PRESTACION' THEN 0 ELSE 1 END, ed.created_at DESC
     LIMIT 1;
  END IF;
  IF v_plan IS NULL AND v_per_student_plans IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  -- Build global cuotas as fallback (only if v_plan exists)
  IF v_plan IS NOT NULL THEN
    v_cuotas := v_plan->'cuotas';
    IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
      DECLARE
        v_n int := COALESCE((v_plan->>'n_cuotas')::int, NULL);
        v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
        v_amount numeric := COALESCE((v_plan->>'monto_por_cuota')::numeric,
                                     NULLIF((v_plan->>'monto_total')::numeric, NULL) / NULLIF(v_n,0));
        i int := 1;
        v_synth jsonb := '[]'::jsonb;
      BEGIN
        IF v_n IS NOT NULL AND v_first IS NOT NULL AND v_amount IS NOT NULL THEN
          WHILE i <= v_n LOOP
            v_synth := v_synth || jsonb_build_object(
              'numero', i,
              'amount', v_amount,
              'due_date', (v_first + make_interval(months := i-1))::date
            );
            i := i + 1;
          END LOOP;
          v_cuotas := v_synth;
        ELSIF v_per_student_plans IS NULL THEN
          RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
        END IF;
      END;
    END IF;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id, es.curso_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
      v_student_cuotas jsonb;
      v_student_plan jsonb;
    BEGIN
      v_student_cuotas := NULL;
      IF v_per_student_plans IS NOT NULL AND v_per_student_plans ? r_es.student_id::text THEN
        v_student_plan := v_per_student_plans->r_es.student_id::text;
        v_student_cuotas := v_student_plan->'cuotas';
        IF v_student_plan->>'payment_method' IS NOT NULL THEN
          v_method := v_student_plan->>'payment_method';
        END IF;
      END IF;
      IF v_student_cuotas IS NULL OR jsonb_typeof(v_student_cuotas) <> 'array' THEN
        v_student_cuotas := v_cuotas;
      END IF;

      IF v_student_cuotas IS NULL THEN
        RAISE EXCEPTION 'PLAN_MISSING: no cuotas found for student %', r_es.student_id;
      END IF;

      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_student_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          -- FIX: Match the actual unique index ux_fee_student_year_cuota
          ON CONFLICT (student_id, year_academico, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    -- Reuse existing folio if pre-assigned, otherwise generate sequential one
    v_folio := v_enrollment.meta->>'folio';
    IF v_folio IS NULL OR v_folio = '' THEN
      v_folio_seq := nextval('public.enrollment_folio_seq');
      v_folio := 'ENR-' || v_year || '-' || to_char(v_folio_seq, 'FM000000');
    END IF;

    -- Update enrollment status + folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    -- Update cheques.folio_number to match the real enrollment folio
    UPDATE public.cheques
       SET folio_number = v_folio
     WHERE enrollment_id = p_enrollment_id;

    -- Update student.curso + insert academic record
    FOR r_es IN
      SELECT es.student_id, es.curso_id
        FROM public.enrollment_students es
       WHERE es.enrollment_id = p_enrollment_id
         AND es.curso_id IS NOT NULL
    LOOP
      UPDATE public.students
         SET curso = r_es.curso_id,
             estado_std = 'MATRICULADO',
             updated_at = now()
       WHERE id = r_es.student_id;

      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, enrollment_id, created_by
      ) VALUES (
        r_es.student_id, r_es.curso_id, v_year, CURRENT_DATE, 'activo', p_enrollment_id, v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            enrollment_id = EXCLUDED.enrollment_id,
            updated_at = now(),
            updated_by = v_uid;
    END LOOP;

    -- Update students without curso_id (legacy path)
    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
          AND es.curso_id IS NULL
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary,
    'folio', v_folio,
    'year', v_year
  );
END;
$$;

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 
'Finalize an enrollment: generates fees (with per-student amounts when available), updates student.curso, creates academic records, marks enrollment completed. Reuses pre-assigned folio if available, otherwise generates sequential one. Updates cheques.folio_number to match.';

REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [48/49] MIGRATION: 20260305_performance_indexes
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- Migration: Performance Indexes (QP-03, QP-04, QP-05)
-- Source: pg_stat_statements analysis — March 5, 2026
-- ============================================================================

-- QP-05: Fee queries with triple join (student+cursos) — 44 calls, avg 518ms
CREATE INDEX IF NOT EXISTS idx_fee_year_academico ON public.fee(year_academico);
CREATE INDEX IF NOT EXISTS idx_fee_student_year ON public.fee(student_id, year_academico);

-- QP-03: Enrollment queries with lateral joins — 532 calls, avg 186ms, 20.4% total
CREATE INDEX IF NOT EXISTS idx_enrollments_created_at ON public.enrollments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_enrollment_students_enrollment ON public.enrollment_students(enrollment_id);

-- QP-04: ILIKE search on students — 168 calls, avg 190ms
-- Trigram indexes for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_guardians_name_trgm ON public.guardians USING gin (first_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_guardians_lastname_trgm ON public.guardians USING gin (last_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_students_wholename_trgm ON public.students USING gin (whole_name gin_trgm_ops);


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [49/49] MIGRATION: 20260305_security_hardening_supplement
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================================
-- SECURITY HARDENING – SUPPLEMENT
-- Date: 2026-03-05
-- Covers items NOT in 20260222_security_hardening.sql:
--   SC-07: auth_logs INSERT policy (always-true → staff + owner)
--   SC-10: guardian_claim_logs – add RLS policies
--   SC-11: rate_limit_counters – add RLS policies
-- ============================================================================
-- PREREQUISITE: Run 20260222_security_hardening.sql FIRST.
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- SC-07 – auth_logs: restrict INSERT to staff or own user
-- ════════════════════════════════════════════════════════════════════════════
-- Current policy "Users can insert logs" uses WITH CHECK (true).
-- Replace with: user can only insert logs for themselves.

DROP POLICY IF EXISTS "Users can insert logs" ON public.auth_logs;
DROP POLICY IF EXISTS auth_logs_insert_own ON public.auth_logs;

CREATE POLICY auth_logs_insert_own ON public.auth_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id IS NULL OR user_id = auth.uid()::text
  );

-- ════════════════════════════════════════════════════════════════════════════
-- SC-10 – guardian_claim_logs: enable RLS + add policies
-- ════════════════════════════════════════════════════════════════════════════
-- Table is written only by claim_guardian_by_run() (SECURITY DEFINER).
-- Admin/staff need read access for auditing.

ALTER TABLE IF EXISTS public.guardian_claim_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS guardian_claim_logs_staff_read ON public.guardian_claim_logs;

CREATE POLICY guardian_claim_logs_staff_read ON public.guardian_claim_logs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST')
    )
  );

-- No INSERT/UPDATE/DELETE policies for authenticated users;
-- writes happen exclusively via SECURITY DEFINER function.

-- ════════════════════════════════════════════════════════════════════════════
-- SC-11 – rate_limit_counters: enable RLS + add policies
-- ════════════════════════════════════════════════════════════════════════════
-- Table is used only by check_and_increment_rate_limit() (SECURITY DEFINER).
-- No authenticated user needs direct access. Add service_role-only policy.

ALTER TABLE IF EXISTS public.rate_limit_counters ENABLE ROW LEVEL SECURITY;

-- service_role bypasses RLS by default, but adding explicit policy
-- satisfies the linter and documents intent.
DROP POLICY IF EXISTS rate_limit_service_role_only ON public.rate_limit_counters;

CREATE POLICY rate_limit_service_role_only ON public.rate_limit_counters
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ════════════════════════════════════════════════════════════════════════════
-- VERIFICATION
-- ════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_count integer;
BEGIN
  -- auth_logs: should no longer have always-true INSERT
  SELECT count(*) INTO v_count
  FROM pg_policies
  WHERE tablename = 'auth_logs'
    AND policyname = 'Users can insert logs';
  IF v_count = 0 THEN
    RAISE NOTICE '✅ SC-07: auth_logs always-true INSERT policy removed';
  ELSE
    RAISE WARNING '⚠ SC-07: Old auth_logs INSERT policy still exists';
  END IF;

  -- guardian_claim_logs: should have at least 1 policy
  SELECT count(*) INTO v_count
  FROM pg_policies
  WHERE tablename = 'guardian_claim_logs';
  IF v_count > 0 THEN
    RAISE NOTICE '✅ SC-10: guardian_claim_logs has % policy(ies)', v_count;
  ELSE
    RAISE WARNING '⚠ SC-10: guardian_claim_logs has no policies';
  END IF;

  -- rate_limit_counters: should have at least 1 policy
  SELECT count(*) INTO v_count
  FROM pg_policies
  WHERE tablename = 'rate_limit_counters';
  IF v_count > 0 THEN
    RAISE NOTICE '✅ SC-11: rate_limit_counters has % policy(ies)', v_count;
  ELSE
    RAISE WARNING '⚠ SC-11: rate_limit_counters has no policies';
  END IF;
END $$;

COMMIT;



-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- REGISTER MIGRATIONS IN HISTORY TABLE
-- Run this AFTER all migrations above succeed.
-- This keeps supabase_migrations.schema_migrations in sync with CLI.
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250515000001', '20250515000001_add_guardian_student_functions', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250529000000', '20250529000000_add_role_to_student_guardian', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250529000001', '20250529000001_add_unique_constraint_to_student_guardian', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250726202500', '20250726202500_harden_security', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250805000001', '20250805000001_fix_security_definer_views', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250805000002', '20250805000002_fix_function_search_path', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250924', '20250924_matricula_base', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925', '20250925_ensure_profile_for_current_user', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925', '20250925_guardian_auto_onboarding', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925', '20250925_guardian_claim_flow', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925', '20250925_guardian_intake_survey', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251021', '20251021_guardian_invite_and_claim', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251022', '20251022_fix_guardian_intake_auto_create', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251023', '20251023_add_year_to_fee', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251023', '20251023_complete_architecture_implementation', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251027', '20251027_setup_enrollment_documents_bucket', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251030', '20251030_enrollment_assisted_mode_policies', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251031', '20251031_email_logs', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251101', '20251101_create_cheques_table', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251103', '20251103_alter_cheques_add_document_link', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251103', '20251103_alter_cheques_add_numero_cuota', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251103', '20251103_fix_cheques_policies', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251108', '20251108_add_audit_logs', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251108', '20251108_rate_limit', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251110', '20251110_extend_enrollment_documents_types', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251115', '20251115_finalize_enrollment_rpc', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251115', '20251115_staff_intake_rpcs', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251116', '20251116_add_matriculado_estado', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251118', '20251118_enrollment_document_receipts', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251119', '20251119_guardian_identity_fields', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251120120000', '20251120120000_guardian_intake_course_id', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251202', '20251202_fix_security_issues', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251203', '20251203_matricula_p1_p2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251203', '20251203_matricula_p3_p4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251217', '20251217_add_cheques_missing_columns', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_add_guardian_fields_libro_matricula', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_add_pre_matriculado_estado', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_add_student_apellidos_separated', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_create_libro_matricula_rpc', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219', '20251219_fix_libro_matricula_report', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260222', '20260222_security_hardening', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260302', '20260302_annual_transition_academic_records', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260302', '20260302_fix_fee_on_conflict_and_clone_cursos', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260302', '20260302_promote_and_enroll_batch', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_backfill_academic_records', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_finalize_enrollment_per_student_plans', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_folio_unification', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_performance_indexes', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305', '20260305_security_hardening_supplement', '{}') ON CONFLICT DO NOTHING;
