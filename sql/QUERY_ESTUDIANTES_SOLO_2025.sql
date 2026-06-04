-- ============================================================================
-- LISTAR ESTUDIANTES QUE SOLO TIENEN MATRÍCULA 2025 (SIN 2026)
-- ============================================================================

SELECT 
    s.id as student_id,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as nombre_completo,
    s.run as run_estudiante,
    -- Enrollment info
    e.id as enrollment_id,
    e.created_at as fecha_matricula,
    e.status as estado,
    e.year as año,
    -- Guardian info
    g.id as guardian_id,
    g.first_name as apoderado_nombre,
    split_part(COALESCE(g.last_name, ''), ' ', 1) as apoderado_apellido_paterno,
    NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '') as apoderado_apellido_materno,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1), ' ', COALESCE(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), ''), '')) as apoderado_nombre_completo,
    g.run as apoderado_run,
    g.email as apoderado_email,
    g.telefono as apoderado_telefono
FROM students s
INNER JOIN enrollment_students es ON es.student_id = s.id
INNER JOIN enrollments e ON e.id = es.enrollment_id
INNER JOIN guardians g ON g.id = e.guardian_id
WHERE e.year = 2025
  AND NOT EXISTS (
    SELECT 1 
    FROM enrollment_students es2
    INNER JOIN enrollments e2 ON e2.id = es2.enrollment_id
    WHERE es2.student_id = s.id 
      AND e2.year = 2026
  )
ORDER BY s.apellido_paterno, s.apellido_materno, s.first_name;
