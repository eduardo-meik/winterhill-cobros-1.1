-- Supabase Performance Advisor Fixes
-- Execute these commands in Supabase SQL Editor to fix the identified performance issues

-- ========================================
-- 1. FIX UNINDEXED FOREIGN KEYS (CRITICAL)
-- ========================================

-- Fix: students table - curso foreign key (MOST IMPORTANT)
-- This is critical for the PaymentsPage students->cursos join
CREATE INDEX IF NOT EXISTS idx_students_curso_fkey ON public.students (curso);

-- Fix: fee table - student_id foreign key (already exists but adding for completeness)
-- This improves fee->students join performance
CREATE INDEX IF NOT EXISTS idx_fee_student_id_fkey ON public.fee (student_id);

-- Fix: matriculas_detalle table foreign keys
CREATE INDEX IF NOT EXISTS idx_matriculas_detalle_apoderado_id_fkey ON public.matriculas_detalle (apoderado_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_detalle_estudiante_id_fkey ON public.matriculas_detalle (estudiante_id);

-- Fix: payments table foreign key
CREATE INDEX IF NOT EXISTS idx_payments_invoice_id_fkey ON public.payments (invoice_id);

-- ========================================
-- 2. FIX PRIMARY KEY ISSUE (CRITICAL)
-- ========================================

-- Add primary key to cursos table
-- This is essential for replication and performance
DO $$
BEGIN
    -- Check if primary key already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'cursos' 
          AND constraint_type = 'PRIMARY KEY' 
          AND table_schema = 'public'
    ) THEN
        -- Check if id column exists
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'cursos' 
              AND column_name = 'id' 
              AND table_schema = 'public'
        ) THEN
            -- Add id column as SERIAL (auto-incrementing)
            ALTER TABLE public.cursos ADD COLUMN id SERIAL;
        ELSE
            -- Column exists but may have NULL values, populate them
            -- First, create a sequence if it doesn't exist
            CREATE SEQUENCE IF NOT EXISTS cursos_id_seq;
            
            -- Update NULL values with sequential numbers
            UPDATE public.cursos 
            SET id = nextval('cursos_id_seq') 
            WHERE id IS NULL;
            
            -- Set the sequence to continue from the highest existing value
            SELECT setval('cursos_id_seq', COALESCE(MAX(id), 0) + 1, false) FROM public.cursos;
            
            -- Make the column NOT NULL and set default
            ALTER TABLE public.cursos ALTER COLUMN id SET NOT NULL;
            ALTER TABLE public.cursos ALTER COLUMN id SET DEFAULT nextval('cursos_id_seq');
        END IF;
        
        -- Add primary key constraint
        ALTER TABLE public.cursos ADD PRIMARY KEY (id);
        
        RAISE NOTICE 'Primary key added to cursos table';
    ELSE
        RAISE NOTICE 'Primary key already exists on cursos table';
    END IF;
END $$;

-- ========================================
-- 3. REMOVE UNUSED INDEXES (CLEANUP)
-- ========================================

-- Remove unused indexes to improve write performance and reduce storage
-- Only dropping indexes that are confirmed safe to remove

-- Drop unused auth_logs indexes
DROP INDEX IF EXISTS public.idx_auth_logs_created_at;
DROP INDEX IF EXISTS public.idx_auth_logs_user_id;

-- Drop unused profiles role index
DROP INDEX IF EXISTS public.idx_profiles_role;

-- Drop unused students owner index
DROP INDEX IF EXISTS public.idx_students_owner;

-- Drop unused fee guardian_id index
DROP INDEX IF EXISTS public.idx_fee_guardian_id;

-- NOTE: Keeping idx_cursos_nom_curso as it may be used by application queries
-- The performance advisor may not detect usage from Supabase client queries

-- ========================================
-- 4. UPDATE STATISTICS
-- ========================================

-- Update table statistics for better query planning
ANALYZE public.fee;
ANALYZE public.students;
ANALYZE public.cursos;
ANALYZE public.matriculas_detalle;
ANALYZE public.payments;

-- ========================================
-- 5. VERIFICATION QUERIES
-- ========================================

-- Run these queries after executing the above to verify the fixes:

-- Check all foreign keys now have covering indexes
SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE tablename = tc.table_name 
            AND indexdef LIKE '%' || kcu.column_name || '%'
        ) THEN '✅ HAS INDEX'
        ELSE '❌ MISSING INDEX'
    END as index_status
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('fee', 'students', 'matriculas_detalle', 'payments')
ORDER BY tc.table_name, tc.constraint_name;

-- Check primary keys exist on all tables
SELECT 
    t.table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE table_name = t.table_name 
            AND constraint_type = 'PRIMARY KEY'
            AND table_schema = 'public'
        ) THEN '✅ HAS PRIMARY KEY'
        ELSE '❌ MISSING PRIMARY KEY'
    END as pk_status
FROM information_schema.tables t
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
  AND t.table_name IN ('fee', 'students', 'cursos', 'matriculas_detalle', 'payments')
ORDER BY t.table_name;

-- Check index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as "times_used",
    pg_size_pretty(pg_relation_size(indexrelid)) as "size"
FROM pg_stat_user_indexes 
WHERE tablename IN ('fee', 'students', 'cursos', 'matriculas_detalle', 'payments')
ORDER BY tablename, idx_scan DESC;

-- ========================================
-- EXPECTED RESULTS AFTER EXECUTION:
-- ========================================

-- ✅ All foreign keys should have covering indexes
-- ✅ cursos table should have a primary key
-- ✅ Unused indexes should be removed
-- ✅ Query performance should improve for PaymentsPage
-- ✅ Database storage should be optimized

-- SUCCESS MESSAGE:
-- "Supabase Performance Advisor recommendations successfully implemented!"
