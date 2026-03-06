-- Fix Security Definer Views
-- This script removes SECURITY DEFINER from views flagged by Supabase Security Advisor
-- Date: 2025-08-05

-- First, let's see what views exist and their definitions
-- You should run this query first to see the current view definitions:
-- SELECT schemaname, viewname, definition FROM pg_views WHERE schemaname = 'public' AND viewname IN ('database_metadata', 'payment_summary');

-- Fix database_metadata view - remove SECURITY DEFINER
DROP VIEW IF EXISTS public.database_metadata CASCADE;

CREATE VIEW public.database_metadata AS
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

-- Fix payment_summary view - remove SECURITY DEFINER  
DROP VIEW IF EXISTS public.payment_summary CASCADE;

CREATE VIEW public.payment_summary AS
SELECT 
    p.id,
    p.amount,
    p.payment_date,
    p.invoice_id,
    p.created_at,
    i.student_id,
    f.amount as fee_amount,
    f.due_date,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    CONCAT(s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as full_last_name,
    s.curso,
    c.nom_curso
FROM payments p
LEFT JOIN invoices i ON p.invoice_id = i.id
LEFT JOIN fee f ON f.student_id = i.student_id
LEFT JOIN students s ON i.student_id = s.id
LEFT JOIN cursos c ON s.curso = c.id;

-- Grant appropriate permissions
GRANT SELECT ON public.database_metadata TO authenticated;
GRANT SELECT ON public.payment_summary TO authenticated;

-- Enable RLS on the views if needed
ALTER VIEW public.database_metadata OWNER TO postgres;
ALTER VIEW public.payment_summary OWNER TO postgres;

-- Note: Views don't support RLS directly, but the underlying tables should have RLS enabled
-- Ensure RLS is enabled on underlying tables:
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies if they don't exist
-- These policies assume owner_id field exists for ownership-based access
DO $$
BEGIN
    -- Students table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'students' AND policyname = 'students_owner_policy') THEN
        CREATE POLICY students_owner_policy ON students
            FOR ALL
            USING (owner_id = auth.uid())
            WITH CHECK (owner_id = auth.uid());
    END IF;

    -- Guardians table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'guardians' AND policyname = 'guardians_owner_policy') THEN
        CREATE POLICY guardians_owner_policy ON guardians
            FOR ALL
            USING (owner_id = auth.uid())
            WITH CHECK (owner_id = auth.uid());
    END IF;

    -- Fee table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fee' AND policyname = 'fee_owner_policy') THEN
        CREATE POLICY fee_owner_policy ON fee
            FOR ALL
            USING (owner_id = auth.uid())
            WITH CHECK (owner_id = auth.uid());
    END IF;

    -- Profiles table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'profiles_owner_policy') THEN
        CREATE POLICY profiles_owner_policy ON profiles
            FOR ALL
            USING (id = auth.uid());
    END IF;
END $$;

-- Verification queries
-- Run these to verify the views have been recreated without SECURITY DEFINER:
-- SELECT schemaname, viewname, definition FROM pg_views WHERE schemaname = 'public' AND viewname IN ('database_metadata', 'payment_summary');
