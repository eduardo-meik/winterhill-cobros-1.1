-- CORRECTED SUPABASE PERFORMANCE FIXES
-- Execute these commands in Supabase SQL Editor to fix the identified performance issues

-- ========================================
-- 1. FIX UNINDEXED FOREIGN KEYS (CRITICAL)
-- ========================================

-- Fix: students table - curso foreign key (MOST IMPORTANT)
-- This is critical for the PaymentsPage students->cursos join
CREATE INDEX IF NOT EXISTS idx_students_curso_fkey ON public.students (curso);

-- Fix: fee table - student_id foreign key (may already exist)
-- This improves fee->students join performance
CREATE INDEX IF NOT EXISTS idx_fee_student_id_fkey ON public.fee (student_id);

-- Fix: matriculas_detalle table foreign keys
CREATE INDEX IF NOT EXISTS idx_matriculas_detalle_apoderado_id_fkey ON public.matriculas_detalle (apoderado_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_detalle_estudiante_id_fkey ON public.matriculas_detalle (estudiante_id);

-- Fix: payments table foreign key (if table exists)
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
            -- Add id column
            ALTER TABLE public.cursos ADD COLUMN id SERIAL;
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

-- Remove the duplicate students owner index (keep the more descriptive one)
DROP INDEX IF EXISTS public.idx_students_owner;

-- Remove unused indexes to improve write performance and reduce storage
-- Only dropping indexes that are confirmed safe to remove

-- Drop unused auth_logs indexes (if they exist)
DROP INDEX IF EXISTS public.idx_auth_logs_created_at;
DROP INDEX IF EXISTS public.idx_auth_logs_user_id;

-- Drop unused profiles role index (if it exists)
DROP INDEX IF EXISTS public.idx_profiles_role;

-- Drop unused fee guardian_id index (if it exists)
DROP INDEX IF EXISTS public.idx_fee_guardian_id;

-- ========================================
-- 4. UPDATE STATISTICS
-- ========================================

-- Update table statistics for better query planning
ANALYZE public.fee;
ANALYZE public.students;
ANALYZE public.cursos;

-- ========================================
-- 5. VERIFICATION QUERIES
-- ========================================

-- Check that the critical index for students->cursos exists
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'students' 
  AND indexdef LIKE '%curso%'
  AND schemaname = 'public';

-- Check cursos table has primary key
SELECT 
    table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE table_name = 'cursos' 
            AND constraint_type = 'PRIMARY KEY'
            AND table_schema = 'public'
        ) THEN '✅ HAS PRIMARY KEY'
        ELSE '❌ MISSING PRIMARY KEY'
    END as pk_status
FROM information_schema.tables 
WHERE table_name = 'cursos' AND table_schema = 'public';

-- ========================================
-- SUCCESS MESSAGE
-- ========================================

SELECT 'Database performance optimizations completed successfully!' as result;
