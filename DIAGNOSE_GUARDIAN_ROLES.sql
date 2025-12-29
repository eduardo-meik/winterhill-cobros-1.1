-- ============================================================================
-- DIAGNÓSTICO: Distribución de apoderados por estudiante
-- ============================================================================

-- 1) Ver distribución de is_primary y guardian_role
SELECT 
  is_primary,
  guardian_role,
  COUNT(*) as total
FROM student_guardian
GROUP BY is_primary, guardian_role
ORDER BY total DESC;

-- 2) Estudiantes con MÚLTIPLES apoderados
SELECT 
  student_id,
  COUNT(*) as num_guardians,
  STRING_AGG(
    CONCAT(
      'is_primary=', COALESCE(is_primary::text, 'NULL'), 
      ', role=', COALESCE(guardian_role, 'NULL')
    ), 
    ' | ' 
    ORDER BY created_at
  ) as guardian_config
FROM student_guardian
GROUP BY student_id
HAVING COUNT(*) > 1
ORDER BY num_guardians DESC
LIMIT 20;

-- 3) Casos problemáticos: Apoderados marcados como secundarios pero con role='titular'
SELECT 
  sg.student_id,
  s.first_name || ' ' || s.apellido_paterno as estudiante,
  g.first_name || ' ' || g.last_name as apoderado,
  sg.is_primary,
  sg.guardian_role,
  sg.created_at
FROM student_guardian sg
JOIN students s ON sg.student_id = s.id
JOIN guardians g ON sg.guardian_id = g.id
WHERE sg.is_primary = false AND sg.guardian_role = 'titular'
ORDER BY sg.created_at DESC
LIMIT 10;

-- 4) Casos problemáticos: Apoderados SIN is_primary definido
SELECT 
  sg.student_id,
  s.first_name || ' ' || s.apellido_paterno as estudiante,
  g.first_name || ' ' || g.last_name as apoderado,
  sg.is_primary,
  sg.guardian_role,
  sg.created_at
FROM student_guardian sg
JOIN students s ON sg.student_id = s.id
JOIN guardians g ON sg.guardian_id = g.id
WHERE sg.is_primary IS NULL
ORDER BY sg.created_at DESC
LIMIT 10;

-- 5) Estudiantes que aparecen con APODERADO SECUNDARIO pero NO PRINCIPAL
WITH guardian_classification AS (
  SELECT 
    student_id,
    MAX(CASE 
      WHEN is_primary = true OR guardian_role = 'titular' THEN 1 
      ELSE 0 
    END) as has_primary,
    MAX(CASE 
      WHEN is_primary = false AND (guardian_role = 'suplente' OR guardian_role IS NULL) THEN 1 
      ELSE 0 
    END) as has_secondary
  FROM student_guardian
  GROUP BY student_id
)
SELECT 
  gc.student_id,
  s.first_name || ' ' || s.apellido_paterno as estudiante,
  gc.has_primary,
  gc.has_secondary
FROM guardian_classification gc
JOIN students s ON gc.student_id = s.id
WHERE gc.has_secondary = 1 AND gc.has_primary = 0
LIMIT 10;
