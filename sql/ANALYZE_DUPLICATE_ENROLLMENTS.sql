-- =====================================================
-- ANÁLISIS DETALLADO DE ESTUDIANTES CON MÚLTIPLES ENROLLMENTS
-- =====================================================
-- Detectar estudiantes matriculados más de una vez
-- Determinar si son duplicados reales o errores de sistema
-- =====================================================

-- =====================================================
-- 1. ESTUDIANTES CON MÚLTIPLES ENROLLMENTS
-- =====================================================

WITH estudiantes_duplicados AS (
    SELECT 
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre,
        s.run as estudiante_run,
        COUNT(DISTINCT es.enrollment_id) as veces_matriculado
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno, s.run
    HAVING COUNT(DISTINCT es.enrollment_id) > 1
)
SELECT 
    '===== ESTUDIANTES CON ENROLLMENTS DUPLICADOS =====' as tipo,
    ed.student_id,
    ed.estudiante_nombre,
    ed.estudiante_run,
    ed.veces_matriculado,
    -- Detalles de cada enrollment
    e.id as enrollment_id,
    e.created_at as fecha_enrollment,
    e.status as estado_enrollment,
    e.year as año_enrollment,
    -- Apoderado de cada enrollment
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1)) as apoderado,
    g.email as apoderado_email,
    g.run as apoderado_run,
    -- Análisis
    ROW_NUMBER() OVER (PARTITION BY ed.student_id ORDER BY e.created_at) as numero_matricula,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY ed.student_id ORDER BY e.created_at) = 1 
        THEN '✅ PRIMERA MATRÍCULA (CONSERVAR)'
        ELSE '⚠️ MATRÍCULA DUPLICADA (EVALUAR)'
    END as evaluacion
FROM estudiantes_duplicados ed
INNER JOIN enrollment_students es ON es.student_id = ed.student_id
INNER JOIN enrollments e ON e.id = es.enrollment_id
INNER JOIN guardians g ON g.id = e.guardian_id
ORDER BY ed.estudiante_nombre, e.created_at;

-- =====================================================
-- 2. RESUMEN POR ESTUDIANTE DUPLICADO
-- =====================================================

WITH estudiantes_duplicados AS (
    SELECT 
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre,
        s.run as estudiante_run,
        COUNT(DISTINCT es.enrollment_id) as veces_matriculado
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno, s.run
    HAVING COUNT(DISTINCT es.enrollment_id) > 1
)
SELECT 
    '===== RESUMEN POR ESTUDIANTE =====' as tipo,
    ed.student_id,
    ed.estudiante_nombre,
    ed.estudiante_run,
    ed.veces_matriculado,
    -- Fechas
    MIN(e.created_at) as primera_matricula,
    MAX(e.created_at) as ultima_matricula,
    -- Apoderados diferentes
    COUNT(DISTINCT e.guardian_id) as apoderados_diferentes,
    STRING_AGG(DISTINCT CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1), ' (', g.email, ')'), ' | ' ORDER BY CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1), ' (', g.email, ')')) as lista_apoderados,
    -- Estados
    STRING_AGG(DISTINCT e.status, ', ') as estados_enrollments,
    -- Años
    STRING_AGG(DISTINCT e.year::TEXT, ', ') as años_enrollment,
    -- Análisis de patrón
    CASE 
        WHEN COUNT(DISTINCT e.guardian_id) = 1 
        THEN '⚠️ MISMO APODERADO - Posible error de sistema'
        WHEN COUNT(DISTINCT e.guardian_id) > 1 
        THEN '⚠️ DIFERENTES APODERADOS - Revisar manualmente'
    END as patron_detectado,
    -- Recomendación
    CASE 
        WHEN COUNT(DISTINCT e.guardian_id) = 1 AND COUNT(DISTINCT DATE(e.created_at)) = 1
        THEN '🗑️ BORRAR DUPLICADOS - Mismo apoderado mismo día'
        WHEN COUNT(DISTINCT e.guardian_id) = 1 AND MIN(e.created_at) < MAX(e.created_at) - INTERVAL '1 day'
        THEN '⚠️ REVISAR - Mismo apoderado diferentes fechas'
        WHEN COUNT(DISTINCT e.guardian_id) > 1
        THEN '⚠️ REVISAR - Diferentes apoderados (cambio de tutor?)'
        ELSE '⚠️ REVISAR MANUALMENTE'
    END as recomendacion
FROM estudiantes_duplicados ed
INNER JOIN enrollment_students es ON es.student_id = ed.student_id
INNER JOIN enrollments e ON e.id = es.enrollment_id
INNER JOIN guardians g ON g.id = e.guardian_id
GROUP BY ed.student_id, ed.estudiante_nombre, ed.estudiante_run, ed.veces_matriculado
ORDER BY ed.veces_matriculado DESC, ed.estudiante_nombre;

-- =====================================================
-- 3. DUPLICADOS DEL MISMO DÍA (ERRORES DE SISTEMA)
-- =====================================================

WITH estudiantes_duplicados AS (
    SELECT 
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre,
        s.run as estudiante_run
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno, s.run
    HAVING COUNT(DISTINCT es.enrollment_id) > 1
)
SELECT 
    '===== DUPLICADOS MISMO DÍA Y APODERADO =====' as tipo,
    ed.student_id,
    ed.estudiante_nombre,
    ed.estudiante_run,
    DATE(e.created_at) as fecha,
    g.id as guardian_id,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1)) as apoderado,
    g.email as apoderado_email,
    COUNT(*) as enrollments_mismo_dia,
    STRING_AGG(e.id::TEXT, ' | ' ORDER BY e.created_at) as enrollment_ids,
    STRING_AGG(TO_CHAR(e.created_at, 'HH24:MI:SS'), ' | ' ORDER BY e.created_at) as horas,
    '🗑️ BORRAR TODOS MENOS EL PRIMERO' as accion_recomendada,
    (ARRAY_AGG(e.id ORDER BY e.created_at))[1]::TEXT as enrollment_a_conservar,
    ARRAY_TO_STRING(
        (ARRAY_AGG(e.id ORDER BY e.created_at))[2:],
        ', '
    ) as enrollments_a_borrar
FROM estudiantes_duplicados ed
INNER JOIN enrollment_students es ON es.student_id = ed.student_id
INNER JOIN enrollments e ON e.id = es.enrollment_id
INNER JOIN guardians g ON g.id = e.guardian_id
GROUP BY ed.student_id, ed.estudiante_nombre, ed.estudiante_run, DATE(e.created_at), g.id, g.first_name, split_part(COALESCE(g.last_name, ''), ' ', 1), g.email
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, ed.estudiante_nombre, fecha;

-- =====================================================
-- 4. ESTUDIANTES CON MISMO RUN (DUPLICADOS FÍSICOS)
-- =====================================================

WITH run_duplicados AS (
    SELECT 
        run,
        COUNT(DISTINCT id) as veces_registrado
    FROM students
    WHERE run IS NOT NULL AND run != ''
    GROUP BY run
    HAVING COUNT(DISTINCT id) > 1
)
SELECT 
    '===== ESTUDIANTES CON RUN DUPLICADO =====' as tipo,
    rd.run as run_duplicado,
    rd.veces_registrado,
    s.id as student_id,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    s.email as estudiante_email,
    s.date_of_birth,
    s.estado_std,
    c.nom_curso,
    c.nivel,
    -- Enrollments asociados
    (SELECT COUNT(*) FROM enrollment_students WHERE student_id = s.id) as enrollments_count,
    (SELECT STRING_AGG(e.created_at::TEXT, ' | ')
     FROM enrollment_students es
     INNER JOIN enrollments e ON e.id = es.enrollment_id
     WHERE es.student_id = s.id
    ) as fechas_enrollments,
    -- Decisión
    CASE 
        WHEN (SELECT COUNT(*) FROM enrollment_students WHERE student_id = s.id) = 0
        THEN '🗑️ SIN ENROLLMENTS - Candidato a borrar'
        WHEN (SELECT COUNT(*) FROM enrollment_students WHERE student_id = s.id) > 0
        THEN '⚠️ CON ENROLLMENTS - Fusionar o revisar'
        ELSE '❓ REVISAR'
    END as recomendacion
FROM run_duplicados rd
INNER JOIN students s ON s.run = rd.run
LEFT JOIN cursos c ON c.id = s.curso
ORDER BY rd.run, (SELECT COUNT(*) FROM enrollment_students WHERE student_id = s.id) DESC;

-- =====================================================
-- 5. ESTADÍSTICAS GENERALES
-- =====================================================

SELECT 
    '===== ESTADÍSTICAS DE DUPLICACIÓN =====' as tipo,
    (SELECT COUNT(*) FROM students) as total_estudiantes,
    (SELECT COUNT(DISTINCT student_id) 
     FROM enrollment_students) as estudiantes_con_enrollment,
    (SELECT COUNT(*) 
     FROM (
         SELECT student_id 
         FROM enrollment_students 
         GROUP BY student_id 
         HAVING COUNT(DISTINCT enrollment_id) > 1
     ) sub
    ) as estudiantes_con_enrollments_duplicados,
    (SELECT COUNT(*) 
     FROM (
         SELECT run 
         FROM students 
         WHERE run IS NOT NULL AND run != ''
         GROUP BY run 
         HAVING COUNT(DISTINCT id) > 1
     ) sub
    ) as runs_duplicados,
    (SELECT COUNT(*) 
     FROM (
         SELECT s.id, DATE(e.created_at), e.guardian_id
         FROM students s
         INNER JOIN enrollment_students es ON es.student_id = s.id
         INNER JOIN enrollments e ON e.id = es.enrollment_id
         GROUP BY s.id, DATE(e.created_at), e.guardian_id
         HAVING COUNT(*) > 1
     ) sub
    ) as estudiantes_duplicados_mismo_dia;

-- =====================================================
-- 6. TOP 10 ESTUDIANTES MÁS DUPLICADOS
-- =====================================================

SELECT 
    '===== TOP 10 ESTUDIANTES MÁS DUPLICADOS =====' as tipo,
    s.id as student_id,
    CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre,
    s.run as estudiante_run,
    s.email as estudiante_email,
    COUNT(DISTINCT es.enrollment_id) as total_enrollments,
    MIN(e.created_at) as primera_matricula,
    MAX(e.created_at) as ultima_matricula,
    COUNT(DISTINCT e.guardian_id) as apoderados_diferentes,
    STRING_AGG(DISTINCT CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1)), ' | ') as lista_apoderados
FROM students s
INNER JOIN enrollment_students es ON es.student_id = s.id
INNER JOIN enrollments e ON e.id = es.enrollment_id
INNER JOIN guardians g ON g.id = e.guardian_id
GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno, s.run, s.email
HAVING COUNT(DISTINCT es.enrollment_id) > 1
ORDER BY total_enrollments DESC, estudiante_nombre
LIMIT 10;
