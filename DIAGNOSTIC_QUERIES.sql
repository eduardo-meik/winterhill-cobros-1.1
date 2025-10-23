-- ============================================================================
-- DIAGNOSTIC QUERIES - Find why Query 3 returned no rows
-- ============================================================================

-- Diagnostic 1: Check what values exist in students.estado_std
SELECT 
  estado_std,
  COUNT(*) as student_count
FROM public.students
GROUP BY estado_std
ORDER BY student_count DESC;

-- Diagnostic 2: Check students WITHOUT estado_std (NULL values)
SELECT 
  COUNT(*) as students_with_null_estado
FROM public.students
WHERE estado_std IS NULL;

-- Diagnostic 3: Check students with curso assigned
SELECT 
  COUNT(*) as students_with_curso,
  COUNT(*) FILTER (WHERE curso IS NULL) as students_without_curso
FROM public.students;

-- Diagnostic 4: Simple query - ALL students (no filters)
SELECT 
  s.id,
  s.whole_name,
  s.estado_std,
  c.nom_curso as curso_actual,
  sar.year_academico,
  sar.estado as academic_estado
FROM public.students s
LEFT JOIN public.cursos c ON c.id = s.curso
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = 2025
LIMIT 10;

-- Diagnostic 5: Check if academic records are linked to existing students
SELECT 
  sar.student_id,
  sar.year_academico,
  sar.estado,
  s.whole_name,
  s.estado_std,
  c.nom_curso
FROM public.student_academic_records sar
LEFT JOIN public.students s ON s.id = sar.student_id
LEFT JOIN public.cursos c ON c.id = sar.curso_id
WHERE sar.year_academico = 2025
LIMIT 10;

-- Diagnostic 6: Count students by estado_std vs academic records
SELECT 
  'Total students' as category,
  COUNT(*) as count
FROM public.students
UNION ALL
SELECT 
  'Students with curso' as category,
  COUNT(*) as count
FROM public.students
WHERE curso IS NOT NULL
UNION ALL
SELECT 
  'Students with estado_std = activo' as category,
  COUNT(*) as count
FROM public.students
WHERE estado_std = 'activo'
UNION ALL
SELECT 
  'Academic records created' as category,
  COUNT(*) as count
FROM public.student_academic_records;
