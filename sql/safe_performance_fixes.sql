-- SAFE SUPABASE PERFORMANCE FIXES - STEP BY STEP
-- Execute these commands ONE AT A TIME in Supabase SQL Editor

-- ========================================
-- STEP 1: CREATE CRITICAL INDEXES (SAFE)
-- ========================================

-- This is the most important index for PaymentsPage performance
CREATE INDEX IF NOT EXISTS idx_students_curso_fkey ON public.students (curso);

-- Ensure fee->students join is optimized
CREATE INDEX IF NOT EXISTS idx_fee_student_id_fkey ON public.fee (student_id);

-- ========================================
-- STEP 2: FIX CURSOS TABLE PRIMARY KEY
-- ========================================

-- First, let's check the current state of cursos table
SELECT 
  COUNT(*) as total_rows,
  COUNT(id) as non_null_ids,
  MIN(id) as min_id,
  MAX(id) as max_id
FROM public.cursos;

-- Fix NULL values in id column
UPDATE public.cursos 
SET id = COALESCE(id, 
  (SELECT COALESCE(MAX(id), 0) FROM public.cursos WHERE id IS NOT NULL) + row_number() OVER ()
) 
WHERE id IS NULL;

-- Make id column NOT NULL
ALTER TABLE public.cursos ALTER COLUMN id SET NOT NULL;

-- Add primary key
ALTER TABLE public.cursos ADD PRIMARY KEY (id);

-- ========================================
-- STEP 3: REMOVE DUPLICATE INDEX (SAFE)
-- ========================================

-- Remove the duplicate index
DROP INDEX IF EXISTS public.idx_students_owner;

-- ========================================
-- STEP 4: UPDATE STATISTICS (SAFE)
-- ========================================

ANALYZE public.fee;
ANALYZE public.students;
ANALYZE public.cursos;

-- ========================================
-- VERIFICATION
-- ========================================

-- Check that primary key was added successfully
SELECT 
  table_name,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'cursos' 
  AND constraint_type = 'PRIMARY KEY';

-- Check that the critical index exists
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'students' 
  AND indexname = 'idx_students_curso_fkey';

SELECT 'Performance optimizations completed successfully!' as result;
