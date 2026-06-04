-- =====================================================
-- DETALLES COMPLETOS DE APODERADOS SOSPECHOSOS
-- =====================================================
-- Análisis detallado de MARIO, ENZO, DIEGO
-- Para ver estudiantes reales y determinar validez
-- =====================================================

-- =====================================================
-- 1. INFORMACIÓN COMPLETA: APODERADO + ESTUDIANTES
-- =====================================================

SELECT 
    '===== APODERADO Y SUS ESTUDIANTES =====' as tipo_registro,
    -- Datos del apoderado
    g.id as guardian_id,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1), ' ', COALESCE(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), ''), '')) as apoderado_nombre_completo,
    g.run as apoderado_run,
    g.email as apoderado_email,
    g.phone as apoderado_telefono,
    g.date_of_birth as apoderado_fecha_nac,
    g.profesion,
    g.estado_civil,
    g.nivel_educacional,
    -- Datos del estudiante
    s.id as student_id,
    CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as estudiante_nombre_completo,
    s.run as estudiante_run,
    s.email as estudiante_email,
    s.date_of_birth as estudiante_fecha_nac,
    s.estado_std,
    -- Datos del curso
    c.nom_curso,
    c.nivel,
    c.year_academico,
    -- Relación
    sg.guardian_role,
    sg.is_primary as apoderado_principal,
    -- Enrollment
    e.id as enrollment_id,
    e.year as enrollment_year,
    e.status as enrollment_status,
    e.created_at as fecha_matricula,
    -- Análisis de validez
    CASE 
        WHEN s.run IS NOT NULL AND s.run != '' THEN '✅ Estudiante con RUN válido'
        ELSE '❌ Estudiante sin RUN'
    END as validez_estudiante,
    CASE 
        WHEN g.run IS NOT NULL AND g.run != '' THEN '✅ Apoderado con RUN'
        ELSE '❌ Apoderado sin RUN'
    END as validez_apoderado_run,
    CASE 
        WHEN g.phone IS NOT NULL AND LENGTH(g.phone) >= 8 THEN '✅ Teléfono válido'
        ELSE '❌ Sin teléfono'
    END as validez_telefono
FROM guardians g
LEFT JOIN enrollments e ON e.guardian_id = g.id
LEFT JOIN enrollment_students es ON es.enrollment_id = e.id
LEFT JOIN students s ON s.id = es.student_id
LEFT JOIN student_guardian sg ON sg.guardian_id = g.id AND sg.student_id = s.id
LEFT JOIN cursos c ON c.id = s.curso
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%')
ORDER BY g.email, s.apellido_paterno, s.apellido_materno, s.first_name;

-- =====================================================
-- 2. VISTA RESUMIDA POR APODERADO
-- =====================================================

SELECT 
    '===== RESUMEN POR APODERADO =====' as tipo,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1)) as apoderado,
    g.run as apoderado_run,
    g.email as apoderado_email,
    g.phone as apoderado_telefono,
    g.created_at as fecha_creacion_apoderado,
    -- Contar estudiantes
    COUNT(DISTINCT s.id) as total_estudiantes,
    COUNT(DISTINCT e.id) as total_enrollments,
    -- Listar estudiantes
    STRING_AGG(DISTINCT 
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, ''), 
               ' (RUN: ', COALESCE(s.run, 'sin RUN'), ')'), 
        ' | ') as lista_estudiantes,
    -- Listar cursos
    STRING_AGG(DISTINCT c.nom_curso, ', ') as cursos,
    -- Validaciones
    CASE 
        WHEN COUNT(DISTINCT s.id) > 0 THEN '⚠️ TIENE ESTUDIANTES REALES - REVISAR'
        ELSE '✅ Sin estudiantes - Seguro borrar'
    END as recomendacion,
    CASE 
        WHEN g.run IS NOT NULL AND g.run != '' THEN '✅ RUN: ' || g.run
        ELSE '❌ SIN RUN'
    END as validez_run,
    CASE 
        WHEN g.phone IS NOT NULL AND LENGTH(g.phone) >= 8 THEN '✅ Tel: ' || g.phone
        ELSE '❌ SIN TELÉFONO'
    END as validez_telefono,
    -- RUNs de estudiantes para verificar
    STRING_AGG(DISTINCT COALESCE(s.run, 'sin-run'), ', ') as runs_estudiantes
FROM guardians g
LEFT JOIN enrollments e ON e.guardian_id = g.id
LEFT JOIN enrollment_students es ON es.enrollment_id = e.id
LEFT JOIN students s ON s.id = es.student_id
LEFT JOIN cursos c ON c.id = s.curso
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%')
GROUP BY g.id, g.first_name, split_part(COALESCE(g.last_name, ''), ' ', 1), g.email, g.run, g.phone, g.created_at
ORDER BY g.email;

-- =====================================================
-- 3. DETALLES DE CADA ESTUDIANTE INDIVIDUAL
-- =====================================================

SELECT 
    '===== DETALLE INDIVIDUAL DE ESTUDIANTES =====' as tipo,
    -- Apoderado
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1)) as apoderado,
    g.email as email_apoderado,
    g.run as run_apoderado,
    -- Estudiante completo
    ROW_NUMBER() OVER (PARTITION BY g.id ORDER BY s.apellido_paterno, s.apellido_materno) as num_hijo,
    s.id as student_id,
    s.first_name as nombre_estudiante,
    s.apellido_paterno as apellido_pat_estudiante,
    s.apellido_materno as apellido_mat_estudiante,
    s.run as run_estudiante,
    s.email as email_estudiante,
    s.date_of_birth as fecha_nac,
    s.genero,
    s.direccion,
    s.estado_std,
    -- Curso
    c.nom_curso,
    c.nivel,
    c.year_academico,
    -- Matrícula
    e.created_at as fecha_matricula,
    e.status as estado_matricula,
    -- Relación familiar
    sg.guardian_role as rol_familiar,
    sg.is_primary as es_apoderado_principal
FROM guardians g
INNER JOIN enrollments e ON e.guardian_id = g.id
INNER JOIN enrollment_students es ON es.enrollment_id = e.id
INNER JOIN students s ON s.id = es.student_id
LEFT JOIN student_guardian sg ON sg.guardian_id = g.id AND sg.student_id = s.id
LEFT JOIN cursos c ON c.id = s.curso
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%')
ORDER BY g.email, num_hijo;

-- =====================================================
-- 4. ANÁLISIS DE DECISIÓN
-- =====================================================

SELECT 
    '===== ANÁLISIS PARA DECISIÓN =====' as tipo,
    g.first_name as nombre_apoderado,
    split_part(COALESCE(g.last_name, ''), ' ', 1) as apellido_paterno_apoderado,
    NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '') as apellido_materno_apoderado,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1), ' ', COALESCE(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), ''), '')) as apoderado_nombre_completo,
    g.email,
    -- Indicadores de registro real
    CASE WHEN g.run IS NOT NULL AND g.run != '' THEN '✅ SÍ' ELSE '❌ NO' END as tiene_run,
    CASE WHEN g.phone IS NOT NULL AND LENGTH(g.phone) >= 8 THEN '✅ SÍ' ELSE '❌ NO' END as tiene_telefono,
    CASE WHEN g.date_of_birth IS NOT NULL THEN '✅ SÍ' ELSE '❌ NO' END as tiene_fecha_nac,
    CASE WHEN g.profesion IS NOT NULL AND g.profesion != '' THEN '✅ SÍ' ELSE '❌ NO' END as tiene_profesion,
    -- Estudiantes asociados
    COUNT(DISTINCT s.id) as estudiantes_reales,
    COUNT(DISTINCT CASE WHEN s.run IS NOT NULL AND s.run != '' THEN s.id END) as estudiantes_con_run,
    -- Decisión
    CASE 
        WHEN COUNT(DISTINCT s.id) = 0 THEN '🗑️ BORRAR - No tiene estudiantes'
        WHEN COUNT(DISTINCT s.id) > 0 AND (g.run IS NULL OR g.run = '') THEN '⚠️ REVISAR - Tiene estudiantes pero apoderado sin RUN'
        WHEN COUNT(DISTINCT s.id) > 0 AND g.run IS NOT NULL THEN '✏️ CORREGIR EMAIL - Apoderado real con email falso'
        ELSE '❓ REVISAR MANUALMENTE'
    END as accion_recomendada,
    -- Datos para corrección
    g.run as run_para_buscar_email_real,
    g.phone as telefono_contacto,
    -- Listar nombres de estudiantes para contexto
    STRING_AGG(DISTINCT 
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')), 
        ' | ') as nombres_estudiantes
FROM guardians g
LEFT JOIN enrollments e ON e.guardian_id = g.id
LEFT JOIN enrollment_students es ON es.enrollment_id = e.id
LEFT JOIN students s ON s.id = es.student_id
WHERE 
    LOWER(g.email) IN ('no_disponible@test.cl', 'falso@gmail.com')
    OR (LOWER(g.first_name) = 'mario' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'enzo' AND LOWER(g.email) LIKE '%no_disponible%')
    OR (LOWER(g.first_name) = 'diego' AND LOWER(g.email) LIKE '%falso%')
GROUP BY g.id, g.first_name, split_part(COALESCE(g.last_name, ''), ' ', 1), NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), ''), g.email, g.run, g.phone, g.date_of_birth, g.profesion
ORDER BY accion_recomendada, g.email;
