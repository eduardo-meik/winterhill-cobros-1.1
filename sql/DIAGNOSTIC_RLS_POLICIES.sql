-- ============================================================================
-- DIAGNOSTIC: Check RLS Policies for Guardian Portal Access
-- ============================================================================
-- Run these queries to verify guardians can access their data

-- 1. Check student_guardian RLS policies
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
WHERE tablename = 'student_guardian'
ORDER BY policyname;

-- 2. Check students RLS policies
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
WHERE tablename = 'students'
ORDER BY policyname;

-- 3. Check cursos RLS policies (for curso lookup)
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
WHERE tablename = 'cursos'
ORDER BY policyname;

-- 4. Check guardians RLS policies
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
WHERE tablename = 'guardians'
ORDER BY policyname;

-- 5. Check fee RLS policies
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
WHERE tablename = 'fee'
ORDER BY policyname;

-- 6. Test if a specific guardian can see their students (replace guardian_id)
-- SELECT 
--   sg.student_id,
--   s.whole_name,
--   c.nom_curso
-- FROM student_guardian sg
-- JOIN students s ON s.id = sg.student_id
-- LEFT JOIN cursos c ON c.id = s.curso
-- WHERE sg.guardian_id = 'YOUR-GUARDIAN-UUID-HERE';

-- 7. Check if RLS is enabled on these tables
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename IN ('student_guardian', 'students', 'cursos', 'guardians', 'fee')
  AND schemaname = 'public'
ORDER BY tablename;
