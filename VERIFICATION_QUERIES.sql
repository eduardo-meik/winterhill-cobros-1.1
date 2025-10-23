-- ============================================================================
-- VERIFICATION QUERIES - Run these in Supabase SQL Editor
-- ============================================================================
-- Execute AFTER running the main migration
-- These queries verify that all changes were applied successfully

-- Query 1: Verify fee.year_academico exists and is populated
-- Expected: Should show total fees, all with year_academico populated
SELECT 
  COUNT(*) as total_fees,
  COUNT(year_academico) as with_year,
  MIN(year_academico) as oldest_year,
  MAX(year_academico) as newest_year
FROM public.fee;

-- Query 2: Verify student_academic_records table exists and has data
-- Expected: Should show migrated records for current year students
SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT student_id) as unique_students,
  MIN(year_academico) as oldest_year,
  MAX(year_academico) as newest_year
FROM public.student_academic_records;

-- Query 3: Verify current year students have academic records
-- Expected: Should show active students with their courses for 2025
SELECT 
  s.id,
  s.whole_name,
  c.nom_curso as curso_actual,
  sar.year_academico,
  sar.estado,
  sar.fecha_inicio,
  sar.fecha_termino
FROM public.students s
LEFT JOIN public.cursos c ON c.id = s.curso
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE UPPER(s.estado_std) = 'ACTIVO'  -- Case-insensitive comparison
ORDER BY s.whole_name
LIMIT 10;

-- Query 4: Verify RLS policies exist
-- Expected: Should show 4 policies for student_academic_records
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

-- Query 5: Test current_academic_year function
-- Expected: Should return 2025 (or 2024 if in Jan-Feb)
SELECT current_academic_year() as current_year;

-- Query 6: Test get_student_course function (replace with real student_id)
-- Expected: Should return JSON with student course info
-- SELECT get_student_course('YOUR-STUDENT-UUID-HERE', 2025);

-- Query 7: Verify triggers exist
-- Expected: Should show 3 triggers on student_academic_records
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'student_academic_records'
ORDER BY trigger_name;

-- Query 8: Verify views exist
-- Expected: Should show 2 views
SELECT 
  table_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN ('v_current_student_courses', 'v_student_academic_history');

-- Query 9: Test v_current_student_courses view
-- Expected: Should show active students with their current courses
SELECT * FROM v_current_student_courses
LIMIT 5;

-- Query 10: Verify enrollment_students.academic_record_id column exists
-- Expected: Should show the new column
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'enrollment_students'
  AND column_name = 'academic_record_id';

-- ============================================================================
-- SUCCESS CHECKLIST
-- ============================================================================
-- ✅ Query 1: All fees should have year_academico populated
-- ✅ Query 2: Should show records migrated for current year
-- ✅ Query 3: Active students should appear with 2025 academic records
-- ✅ Query 4: Should show 4 RLS policies for student_academic_records
-- ✅ Query 5: Should return 2025
-- ✅ Query 7: Should show 3 triggers
-- ✅ Query 8: Should show 2 views
-- ✅ Query 9: Should display current students with courses
-- ✅ Query 10: Should show academic_record_id column exists
