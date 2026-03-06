-- ============================================================================
-- ANÁLISIS DE ENROLLMENTS CON MÚLTIPLES ESTUDIANTES
-- ============================================================================

-- 1. Distribución: ¿Cuántos enrollments tienen N estudiantes?
SELECT 
    students_per_enrollment as cantidad_estudiantes,
    COUNT(*) as cantidad_enrollments,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as porcentaje
FROM (
    SELECT 
        enrollment_id,
        COUNT(student_id) as students_per_enrollment
    FROM enrollment_students
    GROUP BY enrollment_id
) subquery
GROUP BY students_per_enrollment
ORDER BY students_per_enrollment;

-- 2. Top enrollments con más estudiantes
SELECT 
    e.id as enrollment_id,
    e.year,
    e.status,
    e.created_at,
    g.first_name || ' ' || g.last_name as apoderado,
    g.email as apoderado_email,
    COUNT(es.student_id) as cantidad_estudiantes,
    (
        SELECT STRING_AGG(nombre, ', ' ORDER BY nombre)
        FROM (
            SELECT DISTINCT s2.first_name || ' ' || s2.apellido_paterno as nombre
            FROM enrollment_students es2
            INNER JOIN students s2 ON s2.id = es2.student_id
            WHERE es2.enrollment_id = e.id
        ) nombres_unicos
    ) as lista_estudiantes
FROM enrollments e
INNER JOIN guardians g ON g.id = e.guardian_id
INNER JOIN enrollment_students es ON es.enrollment_id = e.id
INNER JOIN students s ON s.id = es.student_id
GROUP BY e.id, e.year, e.status, e.created_at, g.first_name, g.last_name, g.email
HAVING COUNT(es.student_id) > 1
ORDER BY cantidad_estudiantes DESC, e.created_at DESC
LIMIT 20;

-- 3. Identificar enrollments problemáticos (sin estudiantes)
SELECT 
    e.id as enrollment_id,
    e.year,
    e.status,
    e.created_at,
    g.first_name || ' ' || g.last_name as apoderado,
    'SIN ESTUDIANTES' as problema
FROM enrollments e
INNER JOIN guardians g ON g.id = e.guardian_id
LEFT JOIN enrollment_students es ON es.enrollment_id = e.id
WHERE es.enrollment_id IS NULL
ORDER BY e.created_at DESC;

-- 4. Estadísticas por año
SELECT 
    e.year,
    COUNT(DISTINCT e.id) as total_enrollments,
    COUNT(DISTINCT es.student_id) as total_estudiantes,
    ROUND(COUNT(DISTINCT es.student_id)::numeric / COUNT(DISTINCT e.id), 2) as promedio_estudiantes_por_enrollment,
    COUNT(*) FILTER (
        WHERE (
            SELECT COUNT(*) 
            FROM enrollment_students es2 
            WHERE es2.enrollment_id = e.id
        ) > 1
    ) as enrollments_multiples
FROM enrollments e
LEFT JOIN enrollment_students es ON es.enrollment_id = e.id
GROUP BY e.year
ORDER BY e.year DESC;

-- 5. Verificar integridad: enrollments con estudiantes duplicados (ERROR)
SELECT 
    enrollment_id,
    student_id,
    COUNT(*) as veces_duplicado
FROM enrollment_students
GROUP BY enrollment_id, student_id
HAVING COUNT(*) > 1;
-- Debería retornar 0 rows (PRIMARY KEY lo previene)

-- 6. Casos de uso real: Familias con múltiples hijos matriculados
SELECT 
    g.id as guardian_id,
    g.first_name || ' ' || g.last_name as apoderado,
    g.email,
    COUNT(DISTINCT e.id) as enrollments_totales,
    COUNT(DISTINCT s.id) as hijos_totales,
    STRING_AGG(DISTINCT e.year::text, ', ' ORDER BY e.year::text) as años_matriculados,
    (
        SELECT STRING_AGG(nombre, ', ' ORDER BY nombre)
        FROM (
            SELECT DISTINCT s2.first_name || ' ' || s2.apellido_paterno as nombre
            FROM enrollment_students es2
            INNER JOIN students s2 ON s2.id = es2.student_id
            INNER JOIN enrollments e2 ON e2.id = es2.enrollment_id
            WHERE e2.guardian_id = g.id
        ) nombres_unicos
    ) as hijos
FROM guardians g
INNER JOIN enrollments e ON e.guardian_id = g.id
INNER JOIN enrollment_students es ON es.enrollment_id = e.id
INNER JOIN students s ON s.id = es.student_id
GROUP BY g.id, g.first_name, g.last_name, g.email
HAVING COUNT(DISTINCT s.id) > 1
ORDER BY hijos_totales DESC
LIMIT 20;
