-- =====================================================
-- DETALLE COMPLETO DE CADA ENROLLMENT DUPLICADO
-- =====================================================
-- Muestra TODOS los detalles de cada enrollment duplicado
-- Para determinar cuál conservar y cuáles eliminar
-- =====================================================

-- =====================================================
-- 1. DETALLE COMPLETO POR ESTUDIANTE DUPLICADO
-- =====================================================

WITH estudiantes_duplicados AS (
    SELECT DISTINCT
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre,
        s.run as estudiante_run
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno, s.run
    HAVING COUNT(DISTINCT es.enrollment_id) > 1
    -- Excluir estudiantes de prueba
    AND s.id NOT IN (
        '99f9a557-fd89-4ced-8ffb-b4b800a17f26',
        '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'
    )
)
SELECT 
    '===== DETALLE COMPLETO DE ENROLLMENTS DUPLICADOS =====' as seccion,
    -- ESTUDIANTE
    ed.student_id,
    ed.estudiante_nombre,
    ed.estudiante_run,
    s.email as estudiante_email,
    s.date_of_birth as estudiante_fecha_nac,
    s.genero,
    s.estado_std,
    c.nom_curso,
    c.nivel,
    c.year_academico,
    '---' as separador1,
    -- ENROLLMENT
    e.id as enrollment_id,
    e.created_at as fecha_creacion_enrollment,
    TO_CHAR(e.created_at, 'YYYY-MM-DD') as fecha_enrollment,
    TO_CHAR(e.created_at, 'HH24:MI:SS') as hora_enrollment,
    e.updated_at as fecha_actualizacion,
    e.status as estado_enrollment,
    e.year as año_enrollment,
    ROW_NUMBER() OVER (PARTITION BY ed.student_id ORDER BY e.created_at) as numero_matricula,
    '---' as separador2,
    -- APODERADO
    g.id as guardian_id,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1), ' ', COALESCE(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), ''), '')) as apoderado_nombre_completo,
    g.run as apoderado_run,
    g.email as apoderado_email,
    g.phone as apoderado_telefono,
    g.profesion as apoderado_profesion,
    '---' as separador3,
    -- ANÁLISIS
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY ed.student_id ORDER BY e.created_at) = 1 
        THEN '✅ PRIMERA MATRÍCULA'
        ELSE '⚠️ DUPLICADO ' || (ROW_NUMBER() OVER (PARTITION BY ed.student_id ORDER BY e.created_at))::TEXT
    END as orden_cronologico,
    CASE 
        WHEN DATE(e.created_at) = DATE(LAG(e.created_at) OVER (PARTITION BY ed.student_id ORDER BY e.created_at))
             AND e.guardian_id = LAG(e.guardian_id) OVER (PARTITION BY ed.student_id ORDER BY e.created_at)
        THEN '🗑️ BORRAR - Mismo día y apoderado'
        WHEN e.guardian_id != LAG(e.guardian_id) OVER (PARTITION BY ed.student_id ORDER BY e.created_at)
        THEN '⚠️ REVISAR - Cambio de apoderado'
        WHEN DATE(e.created_at) != DATE(LAG(e.created_at) OVER (PARTITION BY ed.student_id ORDER BY e.created_at))
        THEN '⚠️ REVISAR - Diferente fecha'
        ELSE '✅ CONSERVAR - Primera matrícula'
    END as recomendacion_automatica,
    -- Diferencia de tiempo con el enrollment anterior
    CASE 
        WHEN LAG(e.created_at) OVER (PARTITION BY ed.student_id ORDER BY e.created_at) IS NOT NULL
        THEN EXTRACT(EPOCH FROM (e.created_at - LAG(e.created_at) OVER (PARTITION BY ed.student_id ORDER BY e.created_at)))::INTEGER || ' segundos'
        ELSE 'N/A - Primera matrícula'
    END as tiempo_desde_anterior
FROM estudiantes_duplicados ed
INNER JOIN students s ON s.id = ed.student_id
INNER JOIN enrollment_students es ON es.student_id = ed.student_id
INNER JOIN enrollments e ON e.id = es.enrollment_id
INNER JOIN guardians g ON g.id = e.guardian_id
LEFT JOIN cursos c ON c.id = s.curso
ORDER BY ed.estudiante_nombre, e.created_at;

-- =====================================================
-- 2. RESUMEN AGRUPADO POR ESTUDIANTE
-- =====================================================

WITH estudiantes_duplicados AS (
    SELECT DISTINCT
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre,
        s.run as estudiante_run
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno, s.run
    HAVING COUNT(DISTINCT es.enrollment_id) > 1
    AND s.id NOT IN (
        '99f9a557-fd89-4ced-8ffb-b4b800a17f26',
        '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'
    )
)
SELECT 
    '===== RESUMEN POR ESTUDIANTE =====' as tipo,
    ed.student_id,
    ed.estudiante_nombre,
    ed.estudiante_run,
    COUNT(*) as total_enrollments,
    MIN(e.created_at) as primera_matricula,
    MAX(e.created_at) as ultima_matricula,
    -- Fechas únicas
    COUNT(DISTINCT DATE(e.created_at)) as dias_diferentes,
    STRING_AGG(DISTINCT DATE(e.created_at)::TEXT, ', ' ORDER BY DATE(e.created_at)::TEXT) as fechas_unicas,
    -- Apoderados
    COUNT(DISTINCT e.guardian_id) as apoderados_diferentes,
    STRING_AGG(
        DISTINCT CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1), ' (', g.email, ')'), 
        ' | ' 
        ORDER BY CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1), ' (', g.email, ')')
    ) as lista_apoderados,
    -- Estados
    STRING_AGG(DISTINCT e.status, ', ') as estados,
    -- IDs de enrollments
    STRING_AGG(e.id::TEXT, ' | ' ORDER BY e.created_at) as enrollment_ids,
    -- Primer enrollment (conservar)
    (ARRAY_AGG(e.id ORDER BY e.created_at))[1]::TEXT as enrollment_a_conservar,
    -- Enrollments a borrar
    ARRAY_TO_STRING(
        (ARRAY_AGG(e.id ORDER BY e.created_at))[2:],
        ', '
    ) as enrollments_a_borrar,
    -- Recomendación
    CASE 
        WHEN COUNT(DISTINCT DATE(e.created_at)) = 1 AND COUNT(DISTINCT e.guardian_id) = 1
        THEN '🗑️ BORRAR DUPLICADOS - Mismo día y apoderado'
        WHEN COUNT(DISTINCT e.guardian_id) > 1
        THEN '⚠️ REVISAR MANUALMENTE - Diferentes apoderados'
        WHEN COUNT(DISTINCT DATE(e.created_at)) > 1
        THEN '⚠️ REVISAR MANUALMENTE - Diferentes fechas'
        ELSE '❓ REVISAR'
    END as recomendacion
FROM estudiantes_duplicados ed
INNER JOIN enrollment_students es ON es.student_id = ed.student_id
INNER JOIN enrollments e ON e.id = es.enrollment_id
INNER JOIN guardians g ON g.id = e.guardian_id
GROUP BY ed.student_id, ed.estudiante_nombre, ed.estudiante_run
ORDER BY total_enrollments DESC, ed.estudiante_nombre;

-- =====================================================
-- 3. CASOS PARA BORRAR AUTOMÁTICAMENTE
-- =====================================================

WITH estudiantes_duplicados AS (
    SELECT DISTINCT
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno
    HAVING COUNT(DISTINCT es.enrollment_id) > 1
    AND s.id NOT IN (
        '99f9a557-fd89-4ced-8ffb-b4b800a17f26',
        '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'
    )
),
enrollments_duplicados AS (
    SELECT 
        ed.student_id,
        ed.estudiante_nombre,
        DATE(e.created_at) as fecha,
        e.guardian_id,
        COUNT(*) as enrollments_mismo_dia
    FROM estudiantes_duplicados ed
    INNER JOIN enrollment_students es ON es.student_id = ed.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    GROUP BY ed.student_id, ed.estudiante_nombre, DATE(e.created_at), e.guardian_id
    HAVING COUNT(*) > 1
)
SELECT 
    '===== DUPLICADOS MISMO DÍA - BORRAR AUTOMÁTICAMENTE =====' as tipo,
    ed.student_id,
    ed.estudiante_nombre,
    ed.fecha,
    ed.enrollments_mismo_dia,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1)) as apoderado,
    g.email as apoderado_email,
    -- Enrollments
    STRING_AGG(e.id::TEXT, ' | ' ORDER BY e.created_at) as enrollment_ids,
    STRING_AGG(TO_CHAR(e.created_at, 'HH24:MI:SS'), ' | ' ORDER BY e.created_at) as horas,
    -- Acción
    (ARRAY_AGG(e.id ORDER BY e.created_at))[1]::TEXT as enrollment_conservar,
    ARRAY_TO_STRING(
        (ARRAY_AGG(e.id ORDER BY e.created_at))[2:],
        ''', '''
    ) as enrollments_borrar,
    -- SQL para borrar
    CONCAT(
        'DELETE FROM enrollment_students WHERE enrollment_id IN (''',
        ARRAY_TO_STRING((ARRAY_AGG(e.id ORDER BY e.created_at))[2:], ''', '''),
        '''); DELETE FROM enrollments WHERE id IN (''',
        ARRAY_TO_STRING((ARRAY_AGG(e.id ORDER BY e.created_at))[2:], ''', '''),
        ''');'
    ) as sql_para_ejecutar
FROM enrollments_duplicados ed
INNER JOIN enrollment_students es ON es.student_id = ed.student_id
INNER JOIN enrollments e ON e.id = es.enrollment_id AND DATE(e.created_at) = ed.fecha AND e.guardian_id = ed.guardian_id
INNER JOIN guardians g ON g.id = ed.guardian_id
GROUP BY ed.student_id, ed.estudiante_nombre, ed.fecha, ed.enrollments_mismo_dia, g.first_name, split_part(COALESCE(g.last_name, ''), ' ', 1), g.email
ORDER BY ed.enrollments_mismo_dia DESC, ed.estudiante_nombre;

-- =====================================================
-- 4. CASOS PARA REVISAR MANUALMENTE
-- =====================================================

WITH estudiantes_duplicados AS (
    SELECT DISTINCT
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno
    HAVING COUNT(DISTINCT es.enrollment_id) > 1
    AND s.id NOT IN (
        '99f9a557-fd89-4ced-8ffb-b4b800a17f26',
        '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'
    )
)
SELECT 
    '===== CASOS PARA REVISAR MANUALMENTE =====' as tipo,
    ed.student_id,
    ed.estudiante_nombre,
    COUNT(DISTINCT e.guardian_id) as apoderados_diferentes,
    COUNT(DISTINCT DATE(e.created_at)) as fechas_diferentes,
    COUNT(*) as total_enrollments,
    STRING_AGG(
        CONCAT(
            TO_CHAR(e.created_at, 'YYYY-MM-DD HH24:MI'), 
            ' - ',
            g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1),
            ' (', e.id, ')'
        ),
        ' | '
        ORDER BY e.created_at
    ) as detalle_cronologico
FROM estudiantes_duplicados ed
INNER JOIN enrollment_students es ON es.student_id = ed.student_id
INNER JOIN enrollments e ON e.id = es.enrollment_id
INNER JOIN guardians g ON g.id = e.guardian_id
GROUP BY ed.student_id, ed.estudiante_nombre
HAVING COUNT(DISTINCT e.guardian_id) > 1 OR COUNT(DISTINCT DATE(e.created_at)) > 1
ORDER BY total_enrollments DESC, ed.estudiante_nombre;
