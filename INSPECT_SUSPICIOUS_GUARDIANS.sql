-- =====================================================
-- INSPECCIÓN DETALLADA DE APODERADOS SOSPECHOSOS
-- =====================================================
-- Análisis de: MARIO, ENZO, DIEGO
-- Para determinar si son registros de prueba o reales
-- =====================================================

-- =====================================================
-- 1. DETALLES COMPLETOS DE LOS 3 APODERADOS
-- =====================================================

SELECT 
    '===== DATOS DEL APODERADO =====' as seccion,
    g.id as guardian_id,
    g.first_name,
    g.apellido_paterno,
    g.apellido_materno,
    g.email,
    g.run,
    g.phone,
    g.date_of_birth,
    g.nivel_educacional,
    g.profesion,
    g.estado_civil,
    g.created_at,
    g.updated_at
FROM guardians g
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%')
ORDER BY g.created_at DESC;

-- =====================================================
-- 2. ENROLLMENTS ASOCIADOS A CADA APODERADO
-- =====================================================

SELECT 
    '===== ENROLLMENTS =====' as seccion,
    g.first_name as apoderado,
    g.email,
    e.id as enrollment_id,
    e.year,
    e.status,
    e.created_at as fecha_enrollment,
    e.updated_at,
    -- Contar estudiantes en este enrollment
    (SELECT COUNT(*) FROM enrollment_students es WHERE es.enrollment_id = e.id) as cantidad_estudiantes
FROM guardians g
INNER JOIN enrollments e ON e.guardian_id = g.id
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%')
ORDER BY g.email, e.created_at;

-- =====================================================
-- 3. ESTUDIANTES ASOCIADOS VÍA ENROLLMENTS
-- =====================================================

SELECT 
    '===== ESTUDIANTES VÍA ENROLLMENT =====' as seccion,
    g.first_name as apoderado,
    g.email as email_apoderado,
    s.id as student_id,
    s.first_name as estudiante_nombre,
    s.apellido_paterno,
    s.apellido_materno,
    s.run as estudiante_run,
    s.email as estudiante_email,
    s.estado_std,
    c.nom_curso,
    c.nivel,
    e.created_at as fecha_enrollment
FROM guardians g
INNER JOIN enrollments e ON e.guardian_id = g.id
INNER JOIN enrollment_students es ON es.enrollment_id = e.id
INNER JOIN students s ON s.id = es.student_id
LEFT JOIN cursos c ON c.id = s.curso
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%')
ORDER BY g.email, s.first_name;

-- =====================================================
-- 4. ESTUDIANTES ASOCIADOS VÍA STUDENT_GUARDIAN
-- =====================================================

SELECT 
    '===== ESTUDIANTES VÍA STUDENT_GUARDIAN =====' as seccion,
    g.first_name as apoderado,
    g.email as email_apoderado,
    s.id as student_id,
    s.first_name as estudiante_nombre,
    s.apellido_paterno,
    s.apellido_materno,
    s.run as estudiante_run,
    s.email as estudiante_email,
    sg.guardian_role,
    sg.is_primary,
    c.nom_curso,
    c.nivel
FROM guardians g
INNER JOIN student_guardian sg ON sg.guardian_id = g.id
INNER JOIN students s ON s.id = sg.student_id
LEFT JOIN cursos c ON c.id = s.curso
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%')
ORDER BY g.email, s.first_name;

-- =====================================================
-- 5. ANÁLISIS: ¿Son datos reales o de prueba?
-- =====================================================

SELECT 
    '===== ANÁLISIS DE VALIDEZ =====' as seccion,
    g.first_name as apoderado,
    g.email,
    CASE 
        WHEN g.run IS NULL OR g.run = '' THEN '❌ Sin RUN'
        WHEN g.run ~ '^[0-9]{7,8}-[0-9Kk]$' THEN '✅ RUN válido'
        ELSE '⚠️ RUN sospechoso: ' || g.run
    END as validez_run,
    CASE 
        WHEN g.phone IS NULL OR g.phone = '' THEN '❌ Sin teléfono'
        WHEN LENGTH(g.phone) >= 8 THEN '✅ Teléfono registrado'
        ELSE '⚠️ Teléfono corto'
    END as validez_telefono,
    CASE 
        WHEN LOWER(g.email) LIKE '%test%' OR LOWER(g.email) LIKE '%falso%' OR LOWER(g.email) LIKE '%no_disponible%' 
        THEN '❌ Email de prueba'
        ELSE '✅ Email válido'
    END as validez_email,
    CASE 
        WHEN g.date_of_birth IS NULL THEN '⚠️ Sin fecha nacimiento'
        WHEN g.date_of_birth > '1950-01-01' AND g.date_of_birth < '2007-01-01' THEN '✅ Fecha razonable'
        ELSE '⚠️ Fecha sospechosa'
    END as validez_fecha_nacimiento,
    (SELECT COUNT(*) FROM enrollments WHERE guardian_id = g.id) as total_enrollments,
    (SELECT COUNT(DISTINCT es.student_id) 
     FROM enrollments e 
     INNER JOIN enrollment_students es ON es.enrollment_id = e.id 
     WHERE e.guardian_id = g.id) as total_estudiantes_reales,
    CASE 
        WHEN (SELECT COUNT(DISTINCT es.student_id) 
              FROM enrollments e 
              INNER JOIN enrollment_students es ON es.enrollment_id = e.id 
              WHERE e.guardian_id = g.id) > 0 
        THEN '⚠️ TIENE ESTUDIANTES REALES - NO BORRAR'
        ELSE '✅ Seguro borrar'
    END as recomendacion
FROM guardians g
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%')
ORDER BY g.email;

-- =====================================================
-- 6. RESUMEN EJECUTIVO
-- =====================================================

SELECT 
    '===== RESUMEN EJECUTIVO =====' as seccion,
    COUNT(DISTINCT g.id) as total_apoderados_analizados,
    COUNT(DISTINCT e.id) as total_enrollments,
    COUNT(DISTINCT es.student_id) as total_estudiantes_asociados,
    STRING_AGG(DISTINCT g.email, ', ') as emails_analizados
FROM guardians g
LEFT JOIN enrollments e ON e.guardian_id = g.id
LEFT JOIN enrollment_students es ON es.enrollment_id = e.id
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%');
