-- ══════════════════════════════════════════════════════════════════════
-- LIMPIEZA DE DATOS: Enrollments y Cursos con year vacío o inválido
-- Fecha: 2025-12-19
-- ══════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════
-- PASO 1: INSPECCIONAR datos problemáticos
-- ══════════════════════════════════════════════════════════════════════

-- Ver enrollments con year NULL, vacío o inválido
SELECT 
    'enrollments con year problemático' as tipo,
    e.id,
    e.year,
    e.status,
    e.created_at,
    COUNT(es.student_id) as cantidad_estudiantes
FROM public.enrollments e
LEFT JOIN public.enrollment_students es ON e.id = es.enrollment_id
WHERE e.year IS NULL 
   OR e.year::TEXT = ''
   OR e.year < 2000 
   OR e.year > 2050
GROUP BY e.id, e.year, e.status, e.created_at
ORDER BY e.created_at DESC;

-- Ver cursos con year_academico NULL, vacío o inválido
SELECT 
    'cursos con year_academico problemático' as tipo,
    c.id,
    c.nom_curso,
    c.nivel,
    c.year_academico,
    COUNT(s.id) as cantidad_estudiantes
FROM public.cursos c
LEFT JOIN public.students s ON s.curso = c.id
WHERE c.year_academico IS NULL 
   OR c.year_academico::TEXT = ''
   OR c.year_academico < 2000 
   OR c.year_academico > 2050
GROUP BY c.id, c.nom_curso, c.nivel, c.year_academico
ORDER BY c.nom_curso;

-- ══════════════════════════════════════════════════════════════════════
-- PASO 2: CORREGIR datos (asignar año desde created_at o fecha actual)
-- ══════════════════════════════════════════════════════════════════════

-- Opción A: CORREGIR enrollments (asignar año desde created_at)
UPDATE public.enrollments
SET year = EXTRACT(YEAR FROM created_at)::INTEGER
WHERE year IS NULL 
   OR year::TEXT = ''
   OR year < 2000 
   OR year > 2050;

-- Opción B: CORREGIR cursos (asignar año actual o 2026)
UPDATE public.cursos
SET year_academico = 2026
WHERE year_academico IS NULL 
   OR year_academico::TEXT = ''
   OR year_academico < 2000 
   OR year_academico > 2050;

-- ══════════════════════════════════════════════════════════════════════
-- PASO 3: ELIMINAR registros (SOLO SI NO TIENEN ESTUDIANTES)
-- ══════════════════════════════════════════════════════════════════════

-- Eliminar enrollments vacíos con year problemático
DELETE FROM public.enrollments
WHERE (year IS NULL OR year::TEXT = '' OR year < 2000 OR year > 2050)
  AND id NOT IN (
    SELECT DISTINCT enrollment_id 
    FROM public.enrollment_students
  );

-- Eliminar cursos vacíos con year_academico problemático
DELETE FROM public.cursos
WHERE (year_academico IS NULL OR year_academico::TEXT = '' OR year_academico < 2000 OR year_academico > 2050)
  AND id NOT IN (
    SELECT DISTINCT curso 
    FROM public.students 
    WHERE curso IS NOT NULL
  );

-- ══════════════════════════════════════════════════════════════════════
-- VERIFICACIÓN FINAL
-- ══════════════════════════════════════════════════════════════════════

SELECT 
    'Enrollments restantes' as tabla,
    COUNT(*) as total,
    COUNT(CASE WHEN year IS NULL OR year::TEXT = '' THEN 1 END) as problematicos
FROM public.enrollments

UNION ALL

SELECT 
    'Cursos restantes' as tabla,
    COUNT(*) as total,
    COUNT(CASE WHEN year_academico IS NULL OR year_academico::TEXT = '' THEN 1 END) as problematicos
FROM public.cursos;
