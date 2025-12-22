-- =====================================================
-- BÚSQUEDA DE OTROS APODERADOS DE LOS ESTUDIANTES
-- =====================================================
-- Para DIEGO, ENZO, MARIO con emails falsos
-- Verificar si los estudiantes tienen otros apoderados (mamá u otros)
-- =====================================================

-- =====================================================
-- 1. IDENTIFICAR LOS ESTUDIANTES DE CADA APODERADO
-- =====================================================

WITH apoderados_sospechosos AS (
    SELECT 
        g.id as guardian_id,
        CONCAT(g.first_name, ' ', g.apellido_paterno) as apoderado_nombre,
        g.run as apoderado_run,
        g.email as apoderado_email
    FROM guardians g
    WHERE g.run IN ('7.888.999-6', '13.029.569-K', '123.321.123-2')
),
estudiantes_de_sospechosos AS (
    SELECT DISTINCT
        ap.apoderado_nombre,
        ap.apoderado_run,
        ap.apoderado_email,
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre,
        s.run as estudiante_run
    FROM apoderados_sospechosos ap
    INNER JOIN enrollments e ON e.guardian_id = ap.guardian_id
    INNER JOIN enrollment_students es ON es.enrollment_id = e.id
    INNER JOIN students s ON s.id = es.student_id
)
SELECT 
    '===== ESTUDIANTE Y SUS APODERADOS =====' as seccion,
    eds.apoderado_nombre as apoderado_con_email_falso,
    eds.apoderado_run as run_apoderado_falso,
    eds.apoderado_email as email_falso,
    eds.estudiante_nombre,
    eds.estudiante_run,
    '---' as separador,
    -- Todos los apoderados del estudiante
    g2.id as otro_guardian_id,
    CONCAT(g2.first_name, ' ', g2.apellido_paterno, ' ', COALESCE(g2.apellido_materno, '')) as otro_apoderado_nombre,
    g2.run as otro_apoderado_run,
    g2.email as otro_apoderado_email,
    g2.phone as otro_apoderado_telefono,
    sg.guardian_role as rol_familiar,
    sg.is_primary as es_apoderado_principal,
    CASE 
        WHEN g2.run IN ('7.888.999-6', '13.029.569-K', '123.321.123-2') THEN '⚠️ ES EL MISMO (email falso)'
        WHEN g2.email IS NOT NULL AND LOWER(g2.email) NOT LIKE '%test%' AND LOWER(g2.email) NOT LIKE '%falso%' 
        THEN '✅ APODERADO CON EMAIL VÁLIDO'
        ELSE '⚠️ Email sospechoso'
    END as validez_email
FROM estudiantes_de_sospechosos eds
INNER JOIN student_guardian sg ON sg.student_id = eds.student_id
INNER JOIN guardians g2 ON g2.id = sg.guardian_id
ORDER BY eds.estudiante_nombre, sg.is_primary DESC, sg.guardian_role;

-- =====================================================
-- 2. RESUMEN: ¿Tienen otros apoderados?
-- =====================================================

WITH apoderados_sospechosos AS (
    SELECT 
        g.id as guardian_id,
        CONCAT(g.first_name, ' ', g.apellido_paterno) as apoderado_nombre,
        g.run as apoderado_run
    FROM guardians g
    WHERE g.run IN ('7.888.999-6', '13.029.569-K', '123.321.123-2')
),
estudiantes_de_sospechosos AS (
    SELECT DISTINCT
        ap.apoderado_nombre,
        ap.apoderado_run,
        ap.guardian_id as guardian_id_falso,
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre,
        s.run as estudiante_run
    FROM apoderados_sospechosos ap
    INNER JOIN enrollments e ON e.guardian_id = ap.guardian_id
    INNER JOIN enrollment_students es ON es.enrollment_id = e.id
    INNER JOIN students s ON s.id = es.student_id
)
SELECT 
    '===== RESUMEN POR ESTUDIANTE =====' as seccion,
    eds.apoderado_nombre as apoderado_email_falso,
    eds.apoderado_run,
    eds.estudiante_nombre,
    eds.estudiante_run,
    COUNT(DISTINCT sg.guardian_id) as total_apoderados,
    COUNT(DISTINCT CASE 
        WHEN sg.guardian_id != eds.guardian_id_falso THEN sg.guardian_id 
    END) as otros_apoderados_ademas_del_falso,
    STRING_AGG(
        DISTINCT CASE 
            WHEN sg.guardian_id != eds.guardian_id_falso 
            THEN CONCAT(g2.first_name, ' ', g2.apellido_paterno, ' (', g2.email, ') - ', sg.guardian_role)
        END, 
        ' | '
    ) as lista_otros_apoderados,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN sg.guardian_id != eds.guardian_id_falso THEN sg.guardian_id END) > 0 
        THEN '✅ TIENE OTROS APODERADOS - Puedes cambiar el enrollment al otro apoderado'
        ELSE '❌ NO TIENE OTROS APODERADOS - Necesitas conseguir email real de este apoderado'
    END as recomendacion
FROM estudiantes_de_sospechosos eds
INNER JOIN student_guardian sg ON sg.student_id = eds.student_id
INNER JOIN guardians g2 ON g2.id = sg.guardian_id
GROUP BY 
    eds.apoderado_nombre, 
    eds.apoderado_run, 
    eds.estudiante_nombre, 
    eds.estudiante_run,
    eds.guardian_id_falso
ORDER BY eds.apoderado_nombre, eds.estudiante_nombre;

-- =====================================================
-- 3. DETALLE: Información completa de otros apoderados
-- =====================================================

WITH apoderados_sospechosos AS (
    SELECT 
        g.id as guardian_id,
        CONCAT(g.first_name, ' ', g.apellido_paterno) as apoderado_nombre,
        g.run as apoderado_run
    FROM guardians g
    WHERE g.run IN ('7.888.999-6', '13.029.569-K', '123.321.123-2')
),
estudiantes_de_sospechosos AS (
    SELECT DISTINCT
        ap.guardian_id as guardian_id_falso,
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre
    FROM apoderados_sospechosos ap
    INNER JOIN enrollments e ON e.guardian_id = ap.guardian_id
    INNER JOIN enrollment_students es ON es.enrollment_id = e.id
    INNER JOIN students s ON s.id = es.student_id
)
SELECT 
    '===== OTROS APODERADOS - DATOS COMPLETOS =====' as seccion,
    eds.estudiante_nombre,
    g2.id as guardian_id,
    g2.first_name as nombre,
    g2.apellido_paterno,
    g2.apellido_materno,
    g2.run,
    g2.email,
    g2.phone,
    g2.date_of_birth,
    g2.profesion,
    g2.estado_civil,
    g2.nivel_educacional,
    sg.guardian_role,
    sg.is_primary as es_principal,
    -- Verificar si tiene enrollments propios
    (SELECT COUNT(*) FROM enrollments WHERE guardian_id = g2.id) as enrollments_propios,
    CASE 
        WHEN g2.email IS NOT NULL 
             AND LOWER(g2.email) NOT LIKE '%test%' 
             AND LOWER(g2.email) NOT LIKE '%falso%'
             AND LOWER(g2.email) NOT LIKE '%no_disponible%'
        THEN '✅ Email válido - Puedes transferir enrollment a este apoderado'
        ELSE '⚠️ Este apoderado también tiene email sospechoso'
    END as estado_email
FROM estudiantes_de_sospechosos eds
INNER JOIN student_guardian sg ON sg.student_id = eds.student_id
INNER JOIN guardians g2 ON g2.id = sg.guardian_id
WHERE g2.id != eds.guardian_id_falso  -- Excluir el apoderado con email falso
ORDER BY eds.estudiante_nombre, sg.is_primary DESC;

-- =====================================================
-- 4. ACCIÓN RECOMENDADA POR CADA CASO
-- =====================================================

WITH apoderados_sospechosos AS (
    SELECT 
        g.id as guardian_id,
        CONCAT(g.first_name, ' ', g.apellido_paterno) as apoderado_nombre,
        g.run as apoderado_run,
        g.email
    FROM guardians g
    WHERE g.run IN ('7.888.999-6', '13.029.569-K', '123.321.123-2')
),
estudiantes_de_sospechosos AS (
    SELECT DISTINCT
        ap.guardian_id as guardian_id_falso,
        ap.apoderado_nombre,
        ap.apoderado_run,
        ap.email as email_falso,
        s.id as student_id,
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre
    FROM apoderados_sospechosos ap
    INNER JOIN enrollments e ON e.guardian_id = ap.guardian_id
    INNER JOIN enrollment_students es ON es.enrollment_id = e.id
    INNER JOIN students s ON s.id = es.student_id
)
SELECT 
    '===== PLAN DE ACCIÓN =====' as seccion,
    eds.apoderado_nombre,
    eds.apoderado_run,
    eds.email_falso,
    eds.estudiante_nombre,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN sg.guardian_id != eds.guardian_id_falso THEN sg.guardian_id END) > 0 
        THEN '📋 OPCIÓN 1: Transferir enrollment al otro apoderado'
        ELSE '📋 OPCIÓN ÚNICA: Corregir email de este apoderado'
    END as opcion_1,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN sg.guardian_id != eds.guardian_id_falso THEN sg.guardian_id END) > 0 
        THEN CONCAT('📋 OPCIÓN 2: Corregir email de ', eds.apoderado_nombre, ' (', eds.apoderado_run, ')')
        ELSE 'Contactar al apoderado para obtener email real'
    END as opcion_2,
    -- ID del otro apoderado para transferir
    (SELECT g2.id 
     FROM student_guardian sg2 
     INNER JOIN guardians g2 ON g2.id = sg2.guardian_id
     WHERE sg2.student_id = eds.student_id 
       AND g2.id != eds.guardian_id_falso
       AND LOWER(g2.email) NOT LIKE '%test%'
       AND LOWER(g2.email) NOT LIKE '%falso%'
       AND LOWER(g2.email) NOT LIKE '%no_disponible%'
     LIMIT 1
    ) as id_apoderado_alternativo,
    -- Email del otro apoderado
    (SELECT g2.email
     FROM student_guardian sg2 
     INNER JOIN guardians g2 ON g2.id = sg2.guardian_id
     WHERE sg2.student_id = eds.student_id 
       AND g2.id != eds.guardian_id_falso
       AND LOWER(g2.email) NOT LIKE '%test%'
       AND LOWER(g2.email) NOT LIKE '%falso%'
       AND LOWER(g2.email) NOT LIKE '%no_disponible%'
     LIMIT 1
    ) as email_apoderado_alternativo
FROM estudiantes_de_sospechosos eds
INNER JOIN student_guardian sg ON sg.student_id = eds.student_id
GROUP BY 
    eds.apoderado_nombre,
    eds.apoderado_run,
    eds.email_falso,
    eds.estudiante_nombre,
    eds.student_id,
    eds.guardian_id_falso
ORDER BY eds.apoderado_nombre;
