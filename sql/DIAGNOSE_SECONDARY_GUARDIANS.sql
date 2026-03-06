-- ============================================================================
-- DIAGNÓSTICO: ¿De dónde vienen los apoderados con is_primary = FALSE?
-- ============================================================================

-- 1) DISTRIBUCIÓN DE is_primary
SELECT 
  is_primary,
  guardian_role,
  COUNT(*) as total
FROM student_guardian
GROUP BY is_primary, guardian_role
ORDER BY total DESC;

-- 2) ESTUDIANTES CON is_primary = FALSE
SELECT 
  sg.student_id,
  s.first_name || ' ' || s.apellido_paterno as estudiante,
  g.first_name || ' ' || g.last_name as apoderado,
  sg.is_primary,
  sg.guardian_role,
  sg.created_at,
  s.created_at as student_created_at
FROM student_guardian sg
JOIN students s ON sg.student_id = s.id
JOIN guardians g ON sg.guardian_id = g.id
WHERE sg.is_primary = false
ORDER BY sg.created_at DESC
LIMIT 50;

-- 3) ESTUDIANTES CON MÚLTIPLES APODERADOS
WITH student_counts AS (
  SELECT 
    student_id,
    COUNT(*) as num_guardians
  FROM student_guardian
  GROUP BY student_id
)
SELECT 
  sc.student_id,
  s.first_name || ' ' || s.apellido_paterno as estudiante,
  sc.num_guardians,
  STRING_AGG(
    g.first_name || ' ' || g.last_name || 
    ' (primary=' || COALESCE(sg.is_primary::text, 'NULL') || 
    ', role=' || COALESCE(sg.guardian_role, 'NULL') || ')',
    ' | '
    ORDER BY sg.is_primary DESC NULLS LAST, sg.created_at
  ) as apoderados
FROM student_counts sc
JOIN student_guardian sg ON sg.student_id = sc.student_id
JOIN students s ON s.id = sc.student_id
JOIN guardians g ON g.id = sg.guardian_id
WHERE sc.num_guardians > 1
GROUP BY sc.student_id, s.first_name, s.apellido_paterno, sc.num_guardians
ORDER BY sc.num_guardians DESC
LIMIT 30;

-- 4) ¿TODOS los apoderados tienen is_primary = TRUE?
SELECT 
  COUNT(*) as total_relaciones,
  COUNT(CASE WHEN is_primary = true THEN 1 END) as con_primary_true,
  COUNT(CASE WHEN is_primary = false THEN 1 END) as con_primary_false,
  COUNT(CASE WHEN is_primary IS NULL THEN 1 END) as con_primary_null
FROM student_guardian;

-- 5) VERIFICAR si existen registros creados manualmente vs automáticamente
-- (Comparar fechas de creación de student_guardian vs students)
SELECT 
  sg.student_id,
  s.first_name || ' ' || s.apellido_paterno as estudiante,
  g.first_name || ' ' || g.last_name as apoderado,
  sg.is_primary,
  sg.guardian_role,
  sg.created_at as relacion_creada,
  s.created_at as estudiante_creado,
  EXTRACT(EPOCH FROM (sg.created_at - s.created_at)) / 3600 as horas_diferencia
FROM student_guardian sg
JOIN students s ON sg.student_id = s.id
JOIN guardians g ON sg.guardian_id = g.id
WHERE sg.is_primary = false
ORDER BY sg.created_at DESC
LIMIT 20;
