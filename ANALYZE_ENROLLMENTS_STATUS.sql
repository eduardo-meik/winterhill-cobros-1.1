-- ══════════════════════════════════════════════════════════════════════
-- ANÁLISIS DE ENROLLMENTS POR ESTADO
-- Fecha: 2025-12-19
-- ══════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════
-- ENROLLMENTS POR STATUS (draft, submitted, finalized, etc.)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Enrollments por STATUS' as analisis,
    COALESCE(e.status, 'NULL') as status,
    COUNT(*) as total,
    COUNT(DISTINCT e.guardian_id) as apoderados_unicos,
    MIN(TO_CHAR(e.created_at, 'DD/MM/YYYY')) as primera_fecha,
    MAX(TO_CHAR(e.created_at, 'DD/MM/YYYY')) as ultima_fecha
FROM public.enrollments e
GROUP BY e.status
ORDER BY total DESC;

-- ══════════════════════════════════════════════════════════════════════
-- ESTUDIANTES EN ENROLLMENT_STUDENTS POR ESTADO_STD
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Estudiantes por ESTADO_STD' as analisis,
    COALESCE(s.estado_std, 'NULL') as estado,
    COUNT(DISTINCT s.id) as total_estudiantes,
    COUNT(DISTINCT es.enrollment_id) as enrollments_asociados
FROM public.students s
INNER JOIN public.enrollment_students es ON s.id = es.student_id
GROUP BY s.estado_std
ORDER BY total_estudiantes DESC;

-- ══════════════════════════════════════════════════════════════════════
-- CRUCE: ENROLLMENT STATUS vs STUDENT ESTADO_STD
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    COALESCE(e.status, 'NULL') as enrollment_status,
    COALESCE(s.estado_std, 'NULL') as student_estado,
    COUNT(DISTINCT es.student_id) as total_estudiantes,
    COUNT(DISTINCT e.id) as total_enrollments
FROM public.enrollments e
LEFT JOIN public.enrollment_students es ON e.id = es.enrollment_id
LEFT JOIN public.students s ON es.student_id = s.id
GROUP BY e.status, s.estado_std
ORDER BY total_estudiantes DESC;

-- ══════════════════════════════════════════════════════════════════════
-- ENROLLMENTS VACÍOS (sin estudiantes en enrollment_students)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Enrollments VACÍOS (sin estudiantes)' as categoria,
    e.status,
    COUNT(*) as total,
    MIN(TO_CHAR(e.created_at, 'DD/MM/YYYY HH24:MI')) as primera_fecha,
    MAX(TO_CHAR(e.created_at, 'DD/MM/YYYY HH24:MI')) as ultima_fecha
FROM public.enrollments e
WHERE e.id NOT IN (
    SELECT DISTINCT enrollment_id 
    FROM public.enrollment_students
)
GROUP BY e.status
ORDER BY total DESC;

-- ══════════════════════════════════════════════════════════════════════
-- ENROLLMENTS DESDE DICIEMBRE 8 POR STATUS
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Desde 08/12/2025' as periodo,
    COALESCE(e.status, 'NULL') as status,
    COUNT(*) as total_enrollments,
    (SELECT COUNT(DISTINCT es2.student_id) 
     FROM enrollment_students es2 
     WHERE es2.enrollment_id IN (
         SELECT e3.id FROM enrollments e3 
         WHERE e3.created_at >= '2025-12-08'::date 
         AND e3.status = e.status
     )) as estudiantes_matriculados
FROM public.enrollments e
WHERE e.created_at >= '2025-12-08'::date
GROUP BY e.status
ORDER BY total_enrollments DESC;

-- ══════════════════════════════════════════════════════════════════════
-- RESUMEN COMPLETO
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Total enrollments' as metrica,
    COUNT(*) as valor
FROM public.enrollments

UNION ALL

SELECT 
    'Enrollments con estudiantes' as metrica,
    COUNT(DISTINCT e.id) as valor
FROM public.enrollments e
WHERE EXISTS (
    SELECT 1 FROM enrollment_students es WHERE es.enrollment_id = e.id
)

UNION ALL

SELECT 
    'Enrollments vacíos' as metrica,
    COUNT(*) as valor
FROM public.enrollments e
WHERE NOT EXISTS (
    SELECT 1 FROM enrollment_students es WHERE es.enrollment_id = e.id
)

UNION ALL

SELECT 
    'Total estudiantes únicos en enrollment_students' as metrica,
    COUNT(DISTINCT student_id) as valor
FROM public.enrollment_students

UNION ALL

SELECT 
    'Enrollments desde 08/12/2025' as metrica,
    COUNT(*) as valor
FROM public.enrollments
WHERE created_at >= '2025-12-08'::date

UNION ALL

SELECT 
    'Estudiantes desde 08/12/2025' as metrica,
    COUNT(DISTINCT es.student_id) as valor
FROM public.enrollment_students es
JOIN public.enrollments e ON es.enrollment_id = e.id
WHERE e.created_at >= '2025-12-08'::date;
