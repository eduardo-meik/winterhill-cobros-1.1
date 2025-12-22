-- ══════════════════════════════════════════════════════════════════════
-- BÚSQUEDA DE DATOS DE PRUEBA/FALSOS
-- Fecha: 2025-12-19
-- 
-- Busca registros con palabras como "FALSO", "TEST", "testing" en nombres/apellidos
-- ══════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════
-- ESTUDIANTES CON DATOS DE PRUEBA (DETALLE COMPLETO)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    ROW_NUMBER() OVER (ORDER BY s.created_at DESC) as num,
    s.id,
    s.first_name as nombre,
    s.apellido_paterno,
    s.apellido_materno,
    s.run,
    s.email,
    c.nom_curso as curso,
    c.nivel,
    TO_CHAR(s.created_at, 'DD/MM/YYYY HH24:MI') as fecha_creacion
FROM public.students s
LEFT JOIN public.cursos c ON s.curso = c.id
WHERE 
    LOWER(s.first_name) LIKE '%falso%'
    OR LOWER(s.first_name) LIKE '%test%'
    OR LOWER(s.first_name) LIKE '%prueba%'
    OR LOWER(s.apellido_paterno) LIKE '%falso%'
    OR LOWER(s.apellido_paterno) LIKE '%test%'
    OR LOWER(s.apellido_paterno) LIKE '%prueba%'
    OR LOWER(s.apellido_materno) LIKE '%falso%'
    OR LOWER(s.apellido_materno) LIKE '%test%'
    OR LOWER(s.apellido_materno) LIKE '%prueba%'
    OR LOWER(s.email) LIKE '%test%'
    OR LOWER(s.email) LIKE '%fake%'
    OR LOWER(s.email) LIKE '%falso%'
ORDER BY s.created_at DESC;

-- ══════════════════════════════════════════════════════════════════════
-- APODERADOS CON DATOS DE PRUEBA (DETALLE COMPLETO)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    ROW_NUMBER() OVER (ORDER BY g.created_at DESC) as num,
    g.id,
    g.first_name as nombre,
    g.apellido_paterno,
    g.apellido_materno,
    g.run,
    g.email,
    g.phone,
    TO_CHAR(g.created_at, 'DD/MM/YYYY HH24:MI') as fecha_creacion,
    (SELECT COUNT(*) FROM student_guardian sg WHERE sg.guardian_id = g.id) as estudiantes_asociados
FROM public.guardians g
WHERE 
    LOWER(g.first_name) LIKE '%falso%'
    OR LOWER(g.first_name) LIKE '%test%'
    OR LOWER(g.first_name) LIKE '%prueba%'
    OR LOWER(g.apellido_paterno) LIKE '%falso%'
    OR LOWER(g.apellido_paterno) LIKE '%test%'
    OR LOWER(g.apellido_paterno) LIKE '%prueba%'
    OR LOWER(g.apellido_materno) LIKE '%falso%'
    OR LOWER(g.apellido_materno) LIKE '%test%'
    OR LOWER(g.apellido_materno) LIKE '%prueba%'
    OR LOWER(g.email) LIKE '%test%'
    OR LOWER(g.email) LIKE '%fake%'
    OR LOWER(g.email) LIKE '%falso%'
ORDER BY g.created_at DESC;

-- ══════════════════════════════════════════════════════════════════════
-- ENROLLMENTS CON DATOS DE PRUEBA (DETALLE COMPLETO)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    ROW_NUMBER() OVER (ORDER BY e.created_at DESC) as num,
    e.id,
    e.year as año,
    e.status,
    g.first_name as guardian_nombre,
    g.apellido_paterno as guardian_apellido_paterno,
    g.apellido_materno as guardian_apellido_materno,
    g.email as guardian_email,
    TO_CHAR(e.created_at, 'DD/MM/YYYY HH24:MI') as fecha_creacion,
    (SELECT COUNT(*) FROM enrollment_students es WHERE es.enrollment_id = e.id) as estudiantes_asociados
FROM public.enrollments e
LEFT JOIN public.guardians g ON e.guardian_id = g.id
WHERE 
    LOWER(g.first_name) LIKE '%falso%'
    OR LOWER(g.first_name) LIKE '%test%'
    OR LOWER(g.first_name) LIKE '%prueba%'
    OR LOWER(g.apellido_paterno) LIKE '%falso%'
    OR LOWER(g.apellido_paterno) LIKE '%test%'
    OR LOWER(g.apellido_paterno) LIKE '%prueba%'
    OR LOWER(g.apellido_materno) LIKE '%falso%'
    OR LOWER(g.apellido_materno) LIKE '%test%'
    OR LOWER(g.apellido_materno) LIKE '%prueba%'
    OR LOWER(g.email) LIKE '%test%'
    OR LOWER(g.email) LIKE '%fake%'
    OR LOWER(g.email) LIKE '%falso%'
ORDER BY e.created_at DESC;

-- ══════════════════════════════════════════════════════════════════════
-- LISTADO COMPLETO PARA CONFIRMAR ELIMINACIÓN
-- ══════════════════════════════════════════════════════════════════════

-- ESTUDIANTES DE PRUEBA (9 registros)
SELECT 
    '🎓 ESTUDIANTE' as tipo,
    s.id,
    s.first_name || ' ' || COALESCE(s.apellido_paterno, '') || ' ' || COALESCE(s.apellido_materno, '') as nombre_completo,
    s.run,
    s.email,
    c.nom_curso as curso,
    TO_CHAR(s.created_at, 'DD/MM/YYYY HH24:MI') as fecha_creacion
FROM public.students s
LEFT JOIN public.cursos c ON s.curso = c.id
WHERE 
    LOWER(s.first_name) LIKE '%falso%'
    OR LOWER(s.first_name) LIKE '%test%'
    OR LOWER(s.first_name) LIKE '%prueba%'
    OR LOWER(s.apellido_paterno) LIKE '%falso%'
    OR LOWER(s.apellido_paterno) LIKE '%test%'
    OR LOWER(s.apellido_paterno) LIKE '%prueba%'
    OR LOWER(s.apellido_materno) LIKE '%falso%'
    OR LOWER(s.apellido_materno) LIKE '%test%'
    OR LOWER(s.apellido_materno) LIKE '%prueba%'
    OR LOWER(s.email) LIKE '%test%'
    OR LOWER(s.email) LIKE '%fake%'
    OR LOWER(s.email) LIKE '%falso%'
ORDER BY s.created_at DESC;

-- APODERADOS DE PRUEBA (24 registros)
SELECT 
    '👤 APODERADO' as tipo,
    g.id,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as nombre_completo,
    g.run,
    g.email,
    g.phone as telefono,
    TO_CHAR(g.created_at, 'DD/MM/YYYY HH24:MI') as fecha_creacion
FROM public.guardians g
WHERE 
    LOWER(g.first_name) LIKE '%falso%'
    OR LOWER(g.first_name) LIKE '%test%'
    OR LOWER(g.first_name) LIKE '%prueba%'
    OR LOWER(g.apellido_paterno) LIKE '%falso%'
    OR LOWER(g.apellido_paterno) LIKE '%test%'
    OR LOWER(g.apellido_paterno) LIKE '%prueba%'
    OR LOWER(g.apellido_materno) LIKE '%falso%'
    OR LOWER(g.apellido_materno) LIKE '%test%'
    OR LOWER(g.apellido_materno) LIKE '%prueba%'
    OR LOWER(g.email) LIKE '%test%'
    OR LOWER(g.email) LIKE '%fake%'
    OR LOWER(g.email) LIKE '%falso%'
ORDER BY g.created_at DESC;

-- ENROLLMENTS DE PRUEBA (41 registros)
SELECT 
    '📋 ENROLLMENT' as tipo,
    e.id,
    e.year as año,
    e.status,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') as apoderado,
    g.email as apoderado_email,
    (SELECT COUNT(*) FROM enrollment_students es WHERE es.enrollment_id = e.id) as cant_estudiantes,
    TO_CHAR(e.created_at, 'DD/MM/YYYY HH24:MI') as fecha_creacion
FROM public.enrollments e
LEFT JOIN public.guardians g ON e.guardian_id = g.id
WHERE 
    LOWER(g.first_name) LIKE '%falso%'
    OR LOWER(g.first_name) LIKE '%test%'
    OR LOWER(g.first_name) LIKE '%prueba%'
    OR LOWER(g.apellido_paterno) LIKE '%falso%'
    OR LOWER(g.apellido_paterno) LIKE '%test%'
    OR LOWER(g.apellido_paterno) LIKE '%prueba%'
    OR LOWER(g.apellido_materno) LIKE '%falso%'
    OR LOWER(g.apellido_materno) LIKE '%test%'
    OR LOWER(g.apellido_materno) LIKE '%prueba%'
    OR LOWER(g.email) LIKE '%test%'
    OR LOWER(g.email) LIKE '%fake%'
    OR LOWER(g.email) LIKE '%falso%'
ORDER BY e.created_at DESC;

-- ══════════════════════════════════════════════════════════════════════
-- RESUMEN DE DATOS DE PRUEBA
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Estudiantes de prueba' as categoria,
    COUNT(*) as total
FROM public.students s
WHERE 
    LOWER(s.first_name) LIKE '%falso%'
    OR LOWER(s.first_name) LIKE '%test%'
    OR LOWER(s.first_name) LIKE '%prueba%'
    OR LOWER(s.apellido_paterno) LIKE '%falso%'
    OR LOWER(s.apellido_paterno) LIKE '%test%'
    OR LOWER(s.apellido_paterno) LIKE '%prueba%'
    OR LOWER(s.apellido_materno) LIKE '%falso%'
    OR LOWER(s.apellido_materno) LIKE '%test%'
    OR LOWER(s.apellido_materno) LIKE '%prueba%'
    OR LOWER(s.email) LIKE '%test%'
    OR LOWER(s.email) LIKE '%fake%'
    OR LOWER(s.email) LIKE '%falso%'

UNION ALL

SELECT 
    'Apoderados de prueba' as categoria,
    COUNT(*) as total
FROM public.guardians g
WHERE 
    LOWER(g.first_name) LIKE '%falso%'
    OR LOWER(g.first_name) LIKE '%test%'
    OR LOWER(g.first_name) LIKE '%prueba%'
    OR LOWER(g.apellido_paterno) LIKE '%falso%'
    OR LOWER(g.apellido_paterno) LIKE '%test%'
    OR LOWER(g.apellido_paterno) LIKE '%prueba%'
    OR LOWER(g.apellido_materno) LIKE '%falso%'
    OR LOWER(g.apellido_materno) LIKE '%test%'
    OR LOWER(g.apellido_materno) LIKE '%prueba%'
    OR LOWER(g.email) LIKE '%test%'
    OR LOWER(g.email) LIKE '%fake%'
    OR LOWER(g.email) LIKE '%falso%'

UNION ALL

SELECT 
    'Enrollments de prueba' as categoria,
    COUNT(*) as total
FROM public.enrollments e
LEFT JOIN public.guardians g ON e.guardian_id = g.id
WHERE 
    LOWER(g.first_name) LIKE '%falso%'
    OR LOWER(g.first_name) LIKE '%test%'
    OR LOWER(g.first_name) LIKE '%prueba%'
    OR LOWER(g.apellido_paterno) LIKE '%falso%'
    OR LOWER(g.apellido_paterno) LIKE '%test%'
    OR LOWER(g.apellido_paterno) LIKE '%prueba%'
    OR LOWER(g.apellido_materno) LIKE '%falso%'
    OR LOWER(g.apellido_materno) LIKE '%test%'
    OR LOWER(g.apellido_materno) LIKE '%prueba%'
    OR LOWER(g.email) LIKE '%test%'
    OR LOWER(g.email) LIKE '%fake%'
    OR LOWER(g.email) LIKE '%falso%';
