/*
  # Database Metadata View and Function
  
  1. Creates a view that provides metadata about:
    - Tables
    - Columns
    - Constraints
    - Indexes
    - Policies
  
  2. Creates a function to get metadata for a specific table
*/

-- Create a view for database metadata
CREATE OR REPLACE VIEW database_metadata AS
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
      'name', c.column_name,
      'type', c.data_type,
      'default', c.column_default,
      'nullable', c.is_nullable,
      'max_length', c.character_maximum_length,
      'description', col_description((quote_ident(c.table_schema) || '.' || quote_ident(c.table_name))::regclass::oid, c.ordinal_position)
    )) as columns
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
  GROUP BY c.table_schema, c.table_name
),
constraint_info AS (
  SELECT 
    tc.table_schema,
    tc.table_name,
    jsonb_agg(jsonb_build_object(
      'name', tc.constraint_name,
      'type', tc.constraint_type,
      'column', kcu.column_name,
      'definition', CASE 
        WHEN tc.constraint_type = 'FOREIGN KEY' THEN
          ccu.table_name || '(' || ccu.column_name || ')'
        ELSE
          cc.check_clause
      END
    )) as constraints
  FROM information_schema.table_constraints tc
  LEFT JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  LEFT JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.table_schema = ccu.table_schema
  LEFT JOIN information_schema.check_constraints cc
    ON tc.constraint_name = cc.constraint_name
    AND tc.table_schema = cc.constraint_schema
  WHERE tc.table_schema = 'public'
  GROUP BY tc.table_schema, tc.table_name
),
index_info AS (
  SELECT 
    schemaname as table_schema,
    tablename as table_name,
    jsonb_agg(jsonb_build_object(
      'name', indexname,
      'definition', indexdef
    )) as indexes
  FROM pg_indexes
  WHERE schemaname = 'public'
  GROUP BY schemaname, tablename
),
policy_info AS (
  SELECT 
    schemaname,
    tablename,
    jsonb_agg(jsonb_build_object(
      'name', policyname,
      'permissive', permissive,
      'roles', roles,
      'command', cmd,
      'using', qual,
      'with_check', with_check
    )) as policies
  FROM pg_policies
  WHERE schemaname = 'public'
  GROUP BY schemaname, tablename
)
SELECT 
  ti.table_schema,
  ti.table_name,
  jsonb_build_object(
    'schema', ti.table_schema,
    'name', ti.table_name,
    'type', ti.table_type,
    'description', ti.table_description,
    'columns', COALESCE(ci.columns, '[]'::jsonb),
    'constraints', COALESCE(coi.constraints, '[]'::jsonb),
    'indexes', COALESCE(ii.indexes, '[]'::jsonb),
    'policies', COALESCE(pi.policies, '[]'::jsonb)
  ) as metadata
FROM table_info ti
LEFT JOIN column_info ci ON ti.table_schema = ci.table_schema AND ti.table_name = ci.table_name
LEFT JOIN constraint_info coi ON ti.table_schema = coi.table_schema AND ti.table_name = coi.table_name
LEFT JOIN index_info ii ON ti.table_schema = ii.table_schema AND ti.table_name = ii.table_name
LEFT JOIN policy_info pi ON ti.table_schema = pi.schemaname AND ti.table_name = pi.tablename;

-- Create a function to get table metadata
CREATE OR REPLACE FUNCTION get_table_metadata(p_table_name text)
RETURNS jsonb AS $$
  SELECT metadata
  FROM database_metadata
  WHERE table_name = p_table_name;
$$ LANGUAGE sql;