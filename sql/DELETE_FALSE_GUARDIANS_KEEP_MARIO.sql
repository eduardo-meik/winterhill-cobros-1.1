-- =====================================================
-- LIMPIAR APODERADOS CON EMAILS FALSOS
-- =====================================================
-- Acción 1: BORRAR apoderados completamente (paulo, falso, CARMEN, DIEGO)
-- Acción 2: CONSERVAR apoderados ENZO y MARIO pero eliminar sus enrollments
-- =====================================================

BEGIN;

-- =====================================================
-- PASO 1: BORRAR APODERADOS COMPLETAMENTE (4 apoderados)
-- =====================================================
-- paulo (RUN: 13.333.444-5) - Sin estudiantes
-- falso (RUN: 7.777.188-0) - Sin estudiantes
-- CARMEN (RUN: 8.999.777-0) - Sin estudiantes
-- DIEGO (RUN: 7.888.999-6) - Registro inválido

-- 1.1 Eliminar enrollment_students
DELETE FROM enrollment_students
WHERE enrollment_id IN (
    SELECT id FROM enrollments 
    WHERE guardian_id IN (
        SELECT id FROM guardians 
        WHERE run IN ('13.333.444-5', '7.777.188-0', '8.999.777-0', '7.888.999-6')
    )
);

-- 1.2 Eliminar enrollments
DELETE FROM enrollments
WHERE guardian_id IN (
    SELECT id FROM guardians 
    WHERE run IN ('13.333.444-5', '7.777.188-0', '8.999.777-0', '7.888.999-6')
);

-- 1.3 Eliminar relaciones student_guardian
DELETE FROM student_guardian
WHERE guardian_id IN (
    SELECT id FROM guardians 
    WHERE run IN ('13.333.444-5', '7.777.188-0', '8.999.777-0', '7.888.999-6')
);

-- 1.4 Eliminar apoderados
DELETE FROM guardians
WHERE run IN ('13.333.444-5', '7.777.188-0', '8.999.777-0', '7.888.999-6');

-- =====================================================
-- PASO 2: CONSERVAR ENZO Y MARIO - SOLO ELIMINAR ENROLLMENTS
-- =====================================================
-- ENZO (RUN: 13.029.569-K) - Apoderado real, eliminar enrollments con email falso
-- MARIO (RUN: 123.321.123-2) - Apoderado real, eliminar enrollments con email falso

-- 2.1 Eliminar enrollment_students de ENZO y MARIO
DELETE FROM enrollment_students
WHERE enrollment_id IN (
    SELECT id FROM enrollments 
    WHERE guardian_id IN (
        SELECT id FROM guardians WHERE run IN ('13.029.569-K', '123.321.123-2')
    )
);

-- 2.2 Eliminar enrollments de ENZO y MARIO
DELETE FROM enrollments
WHERE guardian_id IN (
    SELECT id FROM guardians WHERE run IN ('13.029.569-K', '123.321.123-2')
);

-- NOTA: NO eliminamos student_guardian ni guardians de ENZO y MARIO
-- Ellos permanecen en el sistema para futura corrección de email

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================

-- Verificar apoderados completamente eliminados (debe retornar 0)
SELECT 
    'VERIFICACIÓN: Apoderados eliminados completamente' as tipo,
    COUNT(*) as total
FROM guardians
WHERE run IN ('13.333.444-5', '7.777.188-0', '8.999.777-0', '7.888.999-6');

-- Verificar ENZO y MARIO siguen existiendo (debe retornar 2)
SELECT 
    'VERIFICACIÓN: ENZO y MARIO conservados' as tipo,
    g.id,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1)) as nombre,
    g.run,
    g.email,
    g.phone,
    (SELECT COUNT(*) FROM enrollments WHERE guardian_id = g.id) as enrollments_restantes,
    (SELECT COUNT(*) FROM student_guardian WHERE guardian_id = g.id) as relaciones_estudiantes
FROM guardians g
WHERE run IN ('13.029.569-K', '123.321.123-2');

-- Resumen de enrollments eliminados
SELECT 
    'RESUMEN: Enrollments eliminados' as tipo,
    'Se eliminaron todos los enrollments de los 6 apoderados' as descripcion;

-- =====================================================
-- PASO 3: INFORMACIÓN DE ENZO Y MARIO PARA CORRECCIÓN
-- =====================================================

SELECT 
    '===== APODERADOS REALES CON EMAIL FALSO =====' as tipo,
    g.id as guardian_id,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1), ' ', COALESCE(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), ''), '')) as nombre_completo,
    g.run,
    g.email as email_falso_actual,
    g.phone as telefono_contacto,
    g.date_of_birth,
    g.profesion,
    g.estado_civil,
    -- Relaciones con estudiantes (se mantienen)
    (SELECT COUNT(*) FROM student_guardian WHERE guardian_id = g.id) as estudiantes_relacionados,
    (SELECT STRING_AGG(
        CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')), 
        ' | ')
     FROM student_guardian sg
     INNER JOIN students s ON s.id = sg.student_id
     WHERE sg.guardian_id = g.id
    ) as nombres_estudiantes,
    -- Acción recomendada
    CONCAT('UPDATE guardians SET email = ''EMAIL_REAL_AQUI'' WHERE run = ''', g.run, ''';') as sql_para_corregir_email
FROM guardians g
WHERE run IN ('13.029.569-K', '123.321.123-2')
ORDER BY g.first_name;

-- =====================================================
-- IMPORTANTE: Revisar resultados antes de COMMIT
-- =====================================================
-- Si todo está correcto: COMMIT;
-- Si hay error: ROLLBACK;

-- COMMIT; -- Descomentar después de verificar
