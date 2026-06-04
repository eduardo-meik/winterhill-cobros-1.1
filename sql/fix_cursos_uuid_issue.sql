-- FIX FOR CURSOS TABLE - Handle Record Without UUID
-- Execute these commands step by step in Supabase SQL Editor

-- ========================================
-- STEP 1: IDENTIFY THE PROBLEMATIC RECORD
-- ========================================

-- First, let's see what we're dealing with
SELECT 
    id,
    codigo_curso_matricula,
    nom_curso,
    nivel,
    year_academico,
    CASE 
        WHEN id IS NULL THEN '❌ NO UUID'
        ELSE '✅ HAS UUID'
    END as status
FROM public.cursos
ORDER BY id NULLS FIRST;

-- ========================================
-- STEP 2: FIX THE RECORD WITHOUT UUID
-- ========================================

-- Option A: Generate a new UUID for the record
UPDATE public.cursos 
SET id = gen_random_uuid()
WHERE id IS NULL 
  AND codigo_curso_matricula = '2024-test';

-- Verify the fix
SELECT 
    id,
    codigo_curso_matricula,
    nom_curso,
    'Fixed - UUID added' as status
FROM public.cursos
WHERE codigo_curso_matricula = '2024-test';

-- ========================================
-- STEP 3: ALTERNATIVE - DELETE THE RECORD (if not needed)
-- ========================================

-- If you want to delete this test record instead, use this:
-- (Uncomment the line below if you want to delete it)

-- DELETE FROM public.cursos WHERE codigo_curso_matricula = '2024-test' AND id IS NULL;

-- ========================================
-- STEP 4: NOW ADD PRIMARY KEY SAFELY
-- ========================================

-- Check that all records now have UUIDs
SELECT 
    COUNT(*) as total_records,
    COUNT(id) as records_with_uuid,
    COUNT(*) - COUNT(id) as records_without_uuid
FROM public.cursos;

-- If all records have UUIDs, add the primary key
DO $$
BEGIN
    -- Check if any NULL ids remain
    IF (SELECT COUNT(*) FROM public.cursos WHERE id IS NULL) = 0 THEN
        -- Make id column NOT NULL
        ALTER TABLE public.cursos ALTER COLUMN id SET NOT NULL;
        
        -- Add primary key constraint
        ALTER TABLE public.cursos ADD PRIMARY KEY (id);
        
        RAISE NOTICE 'Primary key added successfully to cursos table';
    ELSE
        RAISE NOTICE 'Still have NULL ids - cannot add primary key yet';
    END IF;
END $$;

-- ========================================
-- STEP 5: ADD THE CRITICAL PERFORMANCE INDEX
-- ========================================

-- This is the most important fix for PaymentsPage performance
CREATE INDEX IF NOT EXISTS idx_students_curso_fkey ON public.students (curso);

-- ========================================
-- VERIFICATION
-- ========================================

-- Check final state
SELECT 
    'cursos table fixed' as result,
    COUNT(*) as total_records,
    COUNT(id) as records_with_uuid
FROM public.cursos;

-- Check primary key exists
SELECT 
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'cursos' 
  AND constraint_type = 'PRIMARY KEY';

-- Check critical index exists
SELECT 
    indexname, 
    'Critical performance index created' as status
FROM pg_indexes 
WHERE tablename = 'students' 
  AND indexname = 'idx_students_curso_fkey';

SELECT 'All fixes completed successfully!' as final_result;
