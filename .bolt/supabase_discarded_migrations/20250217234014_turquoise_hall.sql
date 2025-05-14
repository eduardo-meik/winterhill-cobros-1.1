/*
  # Database Metadata View Creation

  1. Purpose
    - Create a view to easily query database structure
    - Include table definitions, columns, constraints, indexes, and policies
    - Provide a single source of truth for database documentation

  2. Components
    - Table information
    - Column details
    - Constraints
    - Indexes
    - RLS policies
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
    c.column_name,
    c.data_type,
    c.column_default,
    c.is_nullable,
    c.character_maximum_length,
    col_description((quote_ident(c.table_schema) || '.' || quote_ident(c.table_name))::regclass::oid, 
                    c.ordinal_position) as column_description
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
),
constraint_info AS (
  SELECT 
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    CASE 
      WHEN tc.constraint_type = 'FOREIGN KEY' THEN
        ccu.table_name || '(' || ccu.column_name || ')'
      ELSE
        cc.check_clause
    END as constraint_definition
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
),
index_info AS (
  SELECT 
    schemaname as table_schema,
    tablename as table_name,
    indexname as index_name,
    indexdef as index_definition
  FROM pg_indexes
  WHERE schemaname = 'public'
),
policy_info AS (
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
)
SELECT 
  json_build_object(
    'tables', (
      SELECT json_agg(json_build_object(
        'schema', ti.table_schema,
        'name', ti.table_name,
        'type', ti.table_type,
        'description', ti.table_description,
        'columns', (
          SELECT json_agg(json_build_object(
            'name', ci.column_name,
            'type', ci.data_type,
            'default', ci.column_default,
            'nullable', ci.is_nullable,
            'max_length', ci.character_maximum_length,
            'description', ci.column_description
          ))
          FROM column_info ci
          WHERE ci.table_schema = ti.table_schema
            AND ci.table_name = ti.table_name
        ),
        'constraints', (
          SELECT json_agg(json_build_object(
            'name', coi.constraint_name,
            'type', coi.constraint_type,
            'column', coi.column_name,
            'definition', coi.constraint_definition
          ))
          FROM constraint_info coi
          WHERE coi.table_schema = ti.table_schema
            AND coi.table_name = ti.table_name
        ),
        'indexes', (
          SELECT json_agg(json_build_object(
            'name', ii.index_name,
            'definition', ii.index_definition
          ))
          FROM index_info ii
          WHERE ii.table_schema = ti.table_schema
            AND ii.table_name = ti.table_name
        ),
        'policies', (
          SELECT json_agg(json_build_object(
            'name', pi.policyname,
            'permissive', pi.permissive,
            'roles', pi.roles,
            'command', pi.cmd,
            'using', pi.qual,
            'with_check', pi.with_check
          ))
          FROM policy_info pi
          WHERE pi.schemaname = ti.table_schema
            AND pi.tablename = ti.table_name
        )
      ))
      FROM table_info ti
    )
  ) as database_metadata;

-- Create a function to get table metadata
CREATE OR REPLACE FUNCTION get_table_metadata(p_table_name text)
RETURNS json AS $$
  SELECT (database_metadata->'tables')::json
  FROM database_metadata
  WHERE json_array_elements(database_metadata->'tables')::json->>'name' = p_table_name;
$$ LANGUAGE sql;