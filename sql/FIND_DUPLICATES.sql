-- ══════════════════════════════════════════════════════════════════════
-- DETECCIÓN DE ESTUDIANTES DUPLICADOS
-- Fecha: 2025-12-19
-- ══════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════
-- ESTUDIANTES QUE APARECEN EN MÚLTIPLES ENROLLMENTS
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    s.id as student_id,
    s.first_name || ' ' || COALESCE(s.apellido_paterno, '') || ' ' || COALESCE(s.apellido_materno, '') as nombre_completo,
    s.run,
    s.email,
    c.nom_curso as curso,
    COUNT(DISTINCT es.enrollment_id) as veces_matriculado,
    STRING_AGG(DISTINCT TO_CHAR(e.created_at, 'DD/MM/YYYY HH24:MI'), ' | ' ORDER BY TO_CHAR(e.created_at, 'DD/MM/YYYY HH24:MI')) as fechas_matriculas,
    STRING_AGG(DISTINCT g.first_name || ' ' || COALESCE(split_part(COALESCE(g.last_name, ''), ' ', 1), ''), ' | ') as apoderados
FROM public.students s
INNER JOIN public.enrollment_students es ON s.id = es.student_id
INNER JOIN public.enrollments e ON es.enrollment_id = e.id
LEFT JOIN public.cursos c ON s.curso = c.id
LEFT JOIN public.guardians g ON e.guardian_id = g.id
GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno, s.run, s.email, c.nom_curso
HAVING COUNT(DISTINCT es.enrollment_id) > 1
ORDER BY veces_matriculado DESC, s.apellido_paterno, s.first_name;

-- ══════════════════════════════════════════════════════════════════════
-- DETALLE DE ENROLLMENTS POR ESTUDIANTE DUPLICADO
-- ══════════════════════════════════════════════════════════════════════
WITH duplicados AS (
    SELECT student_id
    FROM public.enrollment_students
    GROUP BY student_id
    HAVING COUNT(DISTINCT enrollment_id) > 1
)
SELECT 
    s.id as student_id,
    s.first_name || ' ' || COALESCE(s.apellido_paterno, '') as estudiante,
    s.run,
    e.id as enrollment_id,
    TO_CHAR(e.created_at, 'DD/MM/YYYY HH24:MI') as fecha_matricula,
    e.status as enrollment_status,
    e.year as año_enrollment,
    g.first_name || ' ' || COALESCE(split_part(COALESCE(g.last_name, ''), ' ', 1), '') as apoderado,
    g.email as apoderado_email,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY e.created_at DESC) as orden
FROM duplicados d
JOIN public.students s ON d.student_id = s.id
JOIN public.enrollment_students es ON s.id = es.student_id
JOIN public.enrollments e ON es.enrollment_id = e.id
LEFT JOIN public.guardians g ON e.guardian_id = g.id
ORDER BY s.apellido_paterno, s.first_name, e.created_at DESC;

-- ══════════════════════════════════════════════════════════════════════
-- ESTUDIANTES CON MISMO RUN (posibles duplicados físicos)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    s.run,
    COUNT(DISTINCT s.id) as veces_registrado,
    STRING_AGG(DISTINCT s.first_name || ' ' || COALESCE(s.apellido_paterno, '') || ' ' || COALESCE(s.apellido_materno, ''), ' | ') as nombres_diferentes,
    STRING_AGG(DISTINCT s.id::TEXT, ' | ') as student_ids,
    STRING_AGG(DISTINCT c.nom_curso, ' | ') as cursos
FROM public.students s
LEFT JOIN public.cursos c ON s.curso = c.id
WHERE s.run IS NOT NULL AND s.run != ''
GROUP BY s.run
HAVING COUNT(DISTINCT s.id) > 1
ORDER BY veces_registrado DESC;

-- ══════════════════════════════════════════════════════════════════════
-- RESUMEN DE DUPLICACIÓN
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Total estudiantes únicos (ID)' as metrica,
    COUNT(DISTINCT id) as valor
FROM public.students

UNION ALL

SELECT 
    'Estudiantes en enrollment_students' as metrica,
    COUNT(DISTINCT student_id) as valor
FROM public.enrollment_students

UNION ALL

SELECT 
    'Estudiantes con múltiples enrollments' as metrica,
    COUNT(DISTINCT student_id) as valor
FROM (
    SELECT student_id
    FROM public.enrollment_students
    GROUP BY student_id
    HAVING COUNT(DISTINCT enrollment_id) > 1
) duplicados

UNION ALL

SELECT 
    'Total registros en enrollment_students' as metrica,
    COUNT(*) as valor
FROM public.enrollment_students

UNION ALL

SELECT 
    'RUNs duplicados (mismo estudiante registrado 2+ veces)' as metrica,
    COUNT(*) as valor
FROM (
    SELECT run
    FROM public.students
    WHERE run IS NOT NULL AND run != ''
    GROUP BY run
    HAVING COUNT(DISTINCT id) > 1
) runs_duplicados;

-- ══════════════════════════════════════════════════════════════════════
-- ENROLLMENTS CON MISMO APODERADO Y MISMA FECHA (posibles duplicados)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    g.first_name || ' ' || COALESCE(split_part(COALESCE(g.last_name, ''), ' ', 1), '') as apoderado,
    g.email,
    DATE(e.created_at) as fecha,
    COUNT(*) as enrollments_mismo_dia,
    STRING_AGG(e.id::TEXT, ' | ') as enrollment_ids
FROM public.enrollments e
JOIN public.guardians g ON e.guardian_id = g.id
GROUP BY g.id, g.first_name, split_part(COALESCE(g.last_name, ''), ' ', 1), g.email, DATE(e.created_at)
HAVING COUNT(*) > 1
ORDER BY enrollments_mismo_dia DESC, fecha DESC;
