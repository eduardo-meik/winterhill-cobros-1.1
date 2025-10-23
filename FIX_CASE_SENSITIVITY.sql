-- ============================================================================
-- FIX CASE SENSITIVITY - Update view to handle UPPER CASE estado_std
-- ============================================================================
-- Execute this in Supabase SQL Editor to fix the v_current_student_courses view

-- Drop and recreate the view with case-insensitive comparison
DROP VIEW IF EXISTS v_current_student_courses CASCADE;

CREATE VIEW v_current_student_courses AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  s.first_name,
  s.apellido_paterno,
  s.apellido_materno,
  sar.curso_id,
  c.nom_curso,
  c.nivel,
  c.letra_curso,
  c.year_academico,
  sar.estado as enrollment_status,
  sar.promedio_anual,
  sar.asistencia_porcentaje
FROM public.students s
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN public.cursos c ON c.id = sar.curso_id
WHERE UPPER(s.estado_std) = 'ACTIVO' OR s.estado_std IS NULL;

COMMENT ON VIEW v_current_student_courses IS 
'Helper view: Shows all active students with their current year course assignment. Uses case-insensitive comparison for estado_std.';

-- Verify the fix worked
SELECT COUNT(*) as active_students_count 
FROM v_current_student_courses;
