-- ============================================================
-- PRUEBAS DE LA FUNCIÓN generate_libro_matricula_report
-- ============================================================
-- Fecha: 2025-12-19
-- Objetivo: Verificar que el libro de matrícula funciona correctamente
-- después de la limpieza de datos

-- ============================================================
-- PRUEBA 1: Contar total de registros
-- ============================================================
SELECT COUNT(*) as total_registros 
FROM generate_libro_matricula_report(NULL, NULL);

-- ============================================================
-- PRUEBA 2: Ver primeros 10 registros completos
-- ============================================================
SELECT * 
FROM generate_libro_matricula_report(NULL, NULL)
LIMIT 10;

-- ============================================================
-- PRUEBA 3: Verificar que no hay campos vacíos críticos
-- ============================================================
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN nombres = '' THEN 1 END) as sin_nombre,
    COUNT(CASE WHEN apellido_paterno = '' THEN 1 END) as sin_apellido_paterno,
    COUNT(CASE WHEN run_estudiante = '' THEN 1 END) as sin_run,
    COUNT(CASE WHEN curso = '' THEN 1 END) as sin_curso,
    COUNT(CASE WHEN nombre_apoderado = '' THEN 1 END) as sin_apoderado
FROM generate_libro_matricula_report(NULL, NULL);

-- ============================================================
-- PRUEBA 4: Agrupar por curso
-- ============================================================
SELECT 
    nivel,
    curso,
    COUNT(*) as total_estudiantes
FROM generate_libro_matricula_report(NULL, NULL)
GROUP BY nivel, curso
ORDER BY nivel, curso;

-- ============================================================
-- PRUEBA 5: Verificar apoderados secundarios
-- ============================================================
SELECT 
    COUNT(*) as total_estudiantes,
    COUNT(CASE WHEN nombre_apoderado_secundario != '' THEN 1 END) as con_apoderado_secundario,
    COUNT(CASE WHEN nombre_apoderado_secundario = '' THEN 1 END) as sin_apoderado_secundario
FROM generate_libro_matricula_report(NULL, NULL);

-- ============================================================
-- PRUEBA 6: Verificar estados de estudiantes
-- ============================================================
SELECT 
    condicion,
    COUNT(*) as total
FROM generate_libro_matricula_report(NULL, NULL)
GROUP BY condicion
ORDER BY total DESC;

-- ============================================================
-- PRUEBA 7: Verificar datos de contacto
-- ============================================================
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN email_apoderado = '' THEN 1 END) as sin_email,
    COUNT(CASE WHEN telefono_apoderado = '' THEN 1 END) as sin_telefono,
    COUNT(CASE WHEN direccion_estudiante = '' THEN 1 END) as sin_direccion,
    COUNT(CASE WHEN comuna_estudiante = '' THEN 1 END) as sin_comuna
FROM generate_libro_matricula_report(NULL, NULL);

-- ============================================================
-- PRUEBA 8: Buscar registros con problemas potenciales
-- ============================================================
SELECT 
    nombres,
    apellido_paterno,
    run_estudiante,
    curso,
    nombre_apoderado,
    'Sin RUN estudiante' as problema
FROM generate_libro_matricula_report(NULL, NULL)
WHERE run_estudiante = ''
UNION ALL
SELECT 
    nombres,
    apellido_paterno,
    run_estudiante,
    curso,
    nombre_apoderado,
    'Sin apoderado' as problema
FROM generate_libro_matricula_report(NULL, NULL)
WHERE nombre_apoderado = ''
UNION ALL
SELECT 
    nombres,
    apellido_paterno,
    run_estudiante,
    curso,
    nombre_apoderado,
    'Sin curso' as problema
FROM generate_libro_matricula_report(NULL, NULL)
WHERE curso = '';

-- ============================================================
-- PRUEBA 9: Ver ejemplo de registro completo (1 estudiante)
-- ============================================================
SELECT * 
FROM generate_libro_matricula_report(NULL, NULL)
WHERE run_estudiante != ''
LIMIT 1;

-- ============================================================
-- PRUEBA 10: Verificar que se eliminaron los registros de prueba
-- ============================================================
SELECT 
    nombres,
    apellido_paterno,
    run_estudiante,
    nombre_apoderado
FROM generate_libro_matricula_report(NULL, NULL)
WHERE 
    nombres ILIKE '%test%'
    OR apellido_paterno ILIKE '%test%'
    OR nombres ILIKE '%falso%'
    OR apellido_paterno ILIKE '%falso%';
