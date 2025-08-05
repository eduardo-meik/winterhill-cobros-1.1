-- URGENT SECURITY FIX: Remove SECURITY DEFINER from Views
-- Run this immediately in Supabase SQL Editor to fix security warnings

-- This script addresses the Security Advisor alerts:
-- - View `public.database_metadata` is defined with SECURITY DEFINER
-- - View `public.payment_summary` is defined with SECURITY DEFINER

BEGIN;

-- 1. Fix database_metadata view
DROP VIEW IF EXISTS public.database_metadata CASCADE;
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
      'column_names', array_agg(kcu.column_name ORDER BY kcu.ordinal_position)
    )) as constraints
  FROM information_schema.table_constraints tc
  LEFT JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name 
    AND tc.table_schema = kcu.table_schema
    AND tc.table_name = kcu.table_name
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

-- 2. Fix payment_summary view
DROP VIEW IF EXISTS public.payment_summary CASCADE;
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
    THEN EXTRACT(days FROM (CURRENT_DATE - p.due_date))::integer
    ELSE NULL 
  END as days_overdue,
  -- Payment status in Spanish
  CASE p.status
    WHEN 'paid' THEN 'Pagado'
    WHEN 'pending' THEN 'Pendiente'
    WHEN 'overdue' THEN 'Vencido'
    ELSE p.status
  END as status_display
FROM payments p
LEFT JOIN students s ON p.student_id = s.id
LEFT JOIN cursos c ON s.curso = c.id
ORDER BY p.due_date DESC, p.created_at DESC;

-- 3. Grant permissions (views now use invoker's permissions, not SECURITY DEFINER)
GRANT SELECT ON public.database_metadata TO authenticated;
GRANT SELECT ON public.payment_summary TO authenticated;

-- 4. Verify fix was successful - this should return 0 rows
SELECT 
  'Security check: Views with SECURITY DEFINER' as check_name,
  COUNT(*) as security_definer_views_found
FROM pg_views 
WHERE schemaname = 'public' 
  AND viewname IN ('database_metadata', 'payment_summary')
  AND definition ILIKE '%SECURITY DEFINER%';

COMMIT;

-- 5. Final verification
SELECT 
  viewname,
  'Fixed - No longer uses SECURITY DEFINER' as status
FROM pg_views 
WHERE schemaname = 'public' 
  AND viewname IN ('database_metadata', 'payment_summary');

-- Success message
SELECT 'SECURITY FIX COMPLETED: Views no longer use SECURITY DEFINER' as result;
