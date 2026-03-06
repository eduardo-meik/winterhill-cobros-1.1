-- ============================================================================
-- ANALIZAR Y BORRAR MATRÍCULAS 2025 DUPLICADAS
-- Created: 2025-12-22
-- Objetivo: Identificar estudiantes con matrículas en 2025 Y 2026
--           Borrar las de 2025 si tienen ambas
--           Reportar las que solo tienen 2025
-- ============================================================================

BEGIN;

-- ============================================================================
-- PASO 1: IDENTIFICAR ESTUDIANTES CON MATRÍCULAS 2025 Y 2026
-- ============================================================================
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as nombre_completo,
        s.run,
        e.year,
        e.id as enrollment_id,
        e.created_at as fecha_creacion,
        e.status
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_agrupados AS (
    SELECT 
        student_id,
        nombre_completo,
        run,
        COUNT(DISTINCT year) as años_diferentes,
        COUNT(CASE WHEN year = 2025 THEN 1 END) as matriculas_2025,
        COUNT(CASE WHEN year = 2026 THEN 1 END) as matriculas_2026,
        STRING_AGG(DISTINCT year::TEXT, ', ' ORDER BY year::TEXT) as años,
        (ARRAY_AGG(enrollment_id ORDER BY year) FILTER (WHERE year = 2025))[1] as enrollment_id_2025,
        (ARRAY_AGG(enrollment_id ORDER BY year) FILTER (WHERE year = 2026))[1] as enrollment_id_2026,
        MIN(fecha_creacion) FILTER (WHERE year = 2025) as fecha_2025,
        MIN(fecha_creacion) FILTER (WHERE year = 2026) as fecha_2026
    FROM estudiantes_por_año
    GROUP BY student_id, nombre_completo, run
)
SELECT 
    '===== ESTUDIANTES CON MATRÍCULAS EN 2025 Y 2026 =====' as reporte,
    COUNT(*) FILTER (WHERE años_diferentes = 2) as estudiantes_con_ambas_matriculas,
    COUNT(*) FILTER (WHERE años_diferentes = 1 AND matriculas_2025 > 0) as estudiantes_solo_2025,
    COUNT(*) FILTER (WHERE años_diferentes = 1 AND matriculas_2026 > 0) as estudiantes_solo_2026
FROM estudiantes_agrupados;

-- ============================================================================
-- PASO 2: LISTADO DE ESTUDIANTES CON AMBAS MATRÍCULAS (2025 Y 2026)
-- ============================================================================
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as nombre_completo,
        s.run,
        e.year,
        e.id as enrollment_id,
        e.created_at as fecha_creacion,
        e.status
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_agrupados AS (
    SELECT 
        student_id,
        nombre_completo,
        run,
        COUNT(DISTINCT year) as años_diferentes,
        COUNT(CASE WHEN year = 2025 THEN 1 END) as matriculas_2025,
        COUNT(CASE WHEN year = 2026 THEN 1 END) as matriculas_2026,
        (ARRAY_AGG(enrollment_id ORDER BY year) FILTER (WHERE year = 2025))[1] as enrollment_id_2025,
        (ARRAY_AGG(enrollment_id ORDER BY year) FILTER (WHERE year = 2026))[1] as enrollment_id_2026,
        MIN(fecha_creacion) FILTER (WHERE year = 2025) as fecha_2025,
        MIN(fecha_creacion) FILTER (WHERE year = 2026) as fecha_2026
    FROM estudiantes_por_año
    GROUP BY student_id, nombre_completo, run
)
SELECT 
    '===== ESTUDIANTES CON DUPLICADOS (2025 + 2026) - SE BORRARÁ 2025 =====' as accion,
    student_id,
    nombre_completo,
    run,
    enrollment_id_2025,
    fecha_2025,
    enrollment_id_2026,
    fecha_2026,
    CASE 
        WHEN DATE(fecha_2025) = DATE(fecha_2026) THEN '⚠️ MISMO DÍA'
        ELSE CONCAT((fecha_2026 - fecha_2025)::TEXT, ' diferencia')
    END as patron
FROM estudiantes_agrupados
WHERE años_diferentes = 2
ORDER BY nombre_completo;

-- ============================================================================
-- PASO 3: LISTADO DE ESTUDIANTES SOLO CON MATRÍCULA 2025 (EVALUAR)
-- ============================================================================
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as nombre_completo,
        s.run,
        e.year,
        e.id as enrollment_id,
        e.created_at as fecha_creacion,
        e.status
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_agrupados AS (
    SELECT 
        student_id,
        nombre_completo,
        run,
        COUNT(DISTINCT year) as años_diferentes,
        COUNT(CASE WHEN year = 2025 THEN 1 END) as matriculas_2025,
        (ARRAY_AGG(enrollment_id ORDER BY year) FILTER (WHERE year = 2025))[1] as enrollment_id_2025,
        MIN(fecha_creacion) FILTER (WHERE year = 2025) as fecha_2025,
        MIN(status) FILTER (WHERE year = 2025) as status_2025
    FROM estudiantes_por_año
    GROUP BY student_id, nombre_completo, run
)
SELECT 
    '===== ESTUDIANTES SOLO CON MATRÍCULA 2025 (SIN 2026) - REVISAR =====' as accion,
    student_id,
    nombre_completo,
    run,
    enrollment_id_2025,
    fecha_2025,
    status_2025,
    '⚠️ NO TIENE MATRÍCULA 2026' as advertencia
FROM estudiantes_agrupados
WHERE años_diferentes = 1 AND matriculas_2025 > 0
ORDER BY nombre_completo;

-- ============================================================================
-- PASO 4: ELIMINAR MATRÍCULAS 2025 DE ESTUDIANTES QUE TIENEN AMBAS
-- ============================================================================

-- 4.1 Identificar enrollments 2025 a eliminar
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_con_ambas AS (
    SELECT 
        student_id,
        COUNT(DISTINCT year) as años_diferentes
    FROM estudiantes_por_año
    GROUP BY student_id
    HAVING COUNT(DISTINCT year) = 2
),
enrollments_2025_a_borrar AS (
    SELECT DISTINCT e.id as enrollment_id
    FROM estudiantes_con_ambas eca
    INNER JOIN enrollment_students es ON es.student_id = eca.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year = 2025
)
SELECT 
    '===== RESUMEN DE ENROLLMENTS 2025 A ELIMINAR =====' as paso,
    COUNT(*) as total_enrollments_2025_a_borrar
FROM enrollments_2025_a_borrar;

-- 4.2 Eliminar enrollment_documents de enrollments 2025
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_con_ambas AS (
    SELECT 
        student_id,
        COUNT(DISTINCT year) as años_diferentes
    FROM estudiantes_por_año
    GROUP BY student_id
    HAVING COUNT(DISTINCT year) = 2
),
enrollments_2025_a_borrar AS (
    SELECT DISTINCT e.id as enrollment_id
    FROM estudiantes_con_ambas eca
    INNER JOIN enrollment_students es ON es.student_id = eca.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year = 2025
)
DELETE FROM enrollment_documents
WHERE enrollment_id IN (SELECT enrollment_id FROM enrollments_2025_a_borrar);

-- 4.3 Eliminar enrollment_document_receipts
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_con_ambas AS (
    SELECT 
        student_id,
        COUNT(DISTINCT year) as años_diferentes
    FROM estudiantes_por_año
    GROUP BY student_id
    HAVING COUNT(DISTINCT year) = 2
),
enrollments_2025_a_borrar AS (
    SELECT DISTINCT e.id as enrollment_id
    FROM estudiantes_con_ambas eca
    INNER JOIN enrollment_students es ON es.student_id = eca.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year = 2025
)
DELETE FROM enrollment_document_receipts
WHERE enrollment_document_id IN (
    SELECT ed.id 
    FROM enrollment_documents ed
    WHERE ed.enrollment_id IN (SELECT enrollment_id FROM enrollments_2025_a_borrar)
);

-- 4.4 Eliminar cuotas (fee)
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_con_ambas AS (
    SELECT 
        student_id,
        COUNT(DISTINCT year) as años_diferentes
    FROM estudiantes_por_año
    GROUP BY student_id
    HAVING COUNT(DISTINCT year) = 2
),
enrollments_2025_a_borrar AS (
    SELECT DISTINCT e.id as enrollment_id
    FROM estudiantes_con_ambas eca
    INNER JOIN enrollment_students es ON es.student_id = eca.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year = 2025
)
DELETE FROM fee
WHERE enrollment_id IN (SELECT enrollment_id FROM enrollments_2025_a_borrar);

-- 4.5 Eliminar cheques
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_con_ambas AS (
    SELECT 
        student_id,
        COUNT(DISTINCT year) as años_diferentes
    FROM estudiantes_por_año
    GROUP BY student_id
    HAVING COUNT(DISTINCT year) = 2
),
enrollments_2025_a_borrar AS (
    SELECT DISTINCT e.id as enrollment_id
    FROM estudiantes_con_ambas eca
    INNER JOIN enrollment_students es ON es.student_id = eca.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year = 2025
)
DELETE FROM cheques
WHERE enrollment_id IN (SELECT enrollment_id FROM enrollments_2025_a_borrar);

-- 4.6 Eliminar pre_receipts
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_con_ambas AS (
    SELECT 
        student_id,
        COUNT(DISTINCT year) as años_diferentes
    FROM estudiantes_por_año
    GROUP BY student_id
    HAVING COUNT(DISTINCT year) = 2
),
enrollments_2025_a_borrar AS (
    SELECT DISTINCT e.id as enrollment_id
    FROM estudiantes_con_ambas eca
    INNER JOIN enrollment_students es ON es.student_id = eca.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year = 2025
)
DELETE FROM pre_receipts
WHERE enrollment_id IN (SELECT enrollment_id FROM enrollments_2025_a_borrar);

-- 4.7 Eliminar student_academic_records
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_con_ambas AS (
    SELECT 
        student_id,
        COUNT(DISTINCT year) as años_diferentes
    FROM estudiantes_por_año
    GROUP BY student_id
    HAVING COUNT(DISTINCT year) = 2
),
enrollments_2025_a_borrar AS (
    SELECT DISTINCT e.id as enrollment_id
    FROM estudiantes_con_ambas eca
    INNER JOIN enrollment_students es ON es.student_id = eca.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year = 2025
)
DELETE FROM student_academic_records
WHERE enrollment_id IN (SELECT enrollment_id FROM enrollments_2025_a_borrar);

-- 4.8 Eliminar enrollment_students
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_con_ambas AS (
    SELECT 
        student_id,
        COUNT(DISTINCT year) as años_diferentes
    FROM estudiantes_por_año
    GROUP BY student_id
    HAVING COUNT(DISTINCT year) = 2
),
enrollments_2025_a_borrar AS (
    SELECT DISTINCT e.id as enrollment_id
    FROM estudiantes_con_ambas eca
    INNER JOIN enrollment_students es ON es.student_id = eca.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year = 2025
)
DELETE FROM enrollment_students
WHERE enrollment_id IN (SELECT enrollment_id FROM enrollments_2025_a_borrar);

-- 4.9 Eliminar enrollments 2025
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_con_ambas AS (
    SELECT 
        student_id,
        COUNT(DISTINCT year) as años_diferentes
    FROM estudiantes_por_año
    GROUP BY student_id
    HAVING COUNT(DISTINCT year) = 2
),
enrollments_2025_a_borrar AS (
    SELECT DISTINCT e.id as enrollment_id
    FROM estudiantes_con_ambas eca
    INNER JOIN enrollment_students es ON es.student_id = eca.student_id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year = 2025
)
DELETE FROM enrollments
WHERE id IN (SELECT enrollment_id FROM enrollments_2025_a_borrar);

-- ============================================================================
-- PASO 5: VERIFICACIÓN FINAL
-- ============================================================================
WITH estudiantes_por_año AS (
    SELECT 
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as nombre_completo,
        e.year,
        e.id as enrollment_id
    FROM students s
    INNER JOIN enrollment_students es ON es.student_id = s.id
    INNER JOIN enrollments e ON e.id = es.enrollment_id
    WHERE e.year IN (2025, 2026)
),
estudiantes_agrupados AS (
    SELECT 
        student_id,
        nombre_completo,
        COUNT(DISTINCT year) as años_diferentes,
        COUNT(CASE WHEN year = 2025 THEN 1 END) as matriculas_2025,
        COUNT(CASE WHEN year = 2026 THEN 1 END) as matriculas_2026
    FROM estudiantes_por_año
    GROUP BY student_id, nombre_completo
)
SELECT 
    '===== VERIFICACIÓN POST-ELIMINACIÓN =====' as resultado,
    COUNT(*) FILTER (WHERE años_diferentes = 2) as estudiantes_con_ambas_matriculas_restantes,
    COUNT(*) FILTER (WHERE matriculas_2025 > 0 AND matriculas_2026 = 0) as estudiantes_solo_2025,
    COUNT(*) FILTER (WHERE matriculas_2026 > 0 AND matriculas_2025 = 0) as estudiantes_solo_2026
FROM estudiantes_agrupados;
-- Debería mostrar: 0 con ambas matrículas, N solo 2025, M solo 2026

-- ============================================================================
-- COMMIT O ROLLBACK
-- ============================================================================
ROLLBACK;  -- Cambiar a COMMIT cuando estés seguro
