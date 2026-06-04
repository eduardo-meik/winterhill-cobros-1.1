-- =====================================================
-- ELIMINAR APODERADOS DE PRUEBA DETECTADOS EN ANÁLISIS DE DUPLICADOS
-- =====================================================
-- Este script elimina apoderados que contienen palabras clave de prueba
-- en su nombre o email, y sus enrollments asociados del mismo día
--
-- Criterios de detección:
-- - Nombres: test, ttest, mama, papa, nnnnnnnnn, apoderado (case insensitive)
-- - Emails: @test.cl, @test.com, test@, @tses.lc, @falson.cl
-- =====================================================

BEGIN;

-- =====================================================
-- PASO 1: Identificar apoderados de prueba
-- =====================================================

-- Vista previa de apoderados a eliminar
SELECT 
    'VISTA PREVIA' as tipo,
    g.id,
    CONCAT(g.first_name, ' ', split_part(COALESCE(g.last_name, ''), ' ', 1)) as nombre_completo,
    g.email,
    COUNT(DISTINCT e.id) as total_enrollments,
    STRING_AGG(DISTINCT e.id::TEXT, ' | ') as enrollment_ids
FROM guardians g
LEFT JOIN enrollments e ON e.guardian_id = g.id
WHERE 
    -- Nombres de prueba (case insensitive)
    LOWER(g.first_name) ~ 'test|ttest|mama|papa|nnnnnnnnn|apoderado|prueb|nuevo|falso|diego'
    OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) ~ 'test|prueba|apoderado'
    -- Emails de prueba
    OR LOWER(g.email) ~ '@test\.(cl|com)|test@|@tses\.lc|@falson\.cl|@gmail\.com.*falso'
GROUP BY g.id, g.first_name, split_part(COALESCE(g.last_name, ''), ' ', 1), g.email
ORDER BY g.email;

-- =====================================================
-- PASO 2: Eliminar enrollment_students de enrollments de prueba
-- =====================================================

DELETE FROM enrollment_students
WHERE enrollment_id IN (
    SELECT e.id
    FROM enrollments e
    INNER JOIN guardians g ON g.id = e.guardian_id
    WHERE 
        LOWER(g.first_name) ~ 'test|ttest|mama|papa|nnnnnnnnn|apoderado|prueb|nuevo|falso|diego'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) ~ 'test|prueba|apoderado'
        OR LOWER(g.email) ~ '@test\.(cl|com)|test@|@tses\.lc|@falson\.cl|@gmail\.com.*falso'
);

-- =====================================================
-- PASO 3: Eliminar student_guardian de apoderados de prueba
-- =====================================================

DELETE FROM student_guardian
WHERE guardian_id IN (
    SELECT g.id
    FROM guardians g
    WHERE 
        LOWER(g.first_name) ~ 'test|ttest|mama|papa|nnnnnnnnn|apoderado|prueb|nuevo|falso|diego'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) ~ 'test|prueba|apoderado'
        OR LOWER(g.email) ~ '@test\.(cl|com)|test@|@tses\.lc|@falson\.cl|@gmail\.com.*falso'
);

-- =====================================================
-- PASO 4: Eliminar enrollments de apoderados de prueba
-- =====================================================

DELETE FROM enrollments
WHERE guardian_id IN (
    SELECT g.id
    FROM guardians g
    WHERE 
        LOWER(g.first_name) ~ 'test|ttest|mama|papa|nnnnnnnnn|apoderado|prueb|nuevo|falso|diego'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) ~ 'test|prueba|apoderado'
        OR LOWER(g.email) ~ '@test\.(cl|com)|test@|@tses\.lc|@falson\.lc|@gmail\.com.*falso'
);

-- =====================================================
-- PASO 5: Eliminar apoderados de prueba
-- =====================================================

DELETE FROM guardians
WHERE 
    LOWER(first_name) ~ 'test|ttest|mama|papa|nnnnnnnnn|apoderado|prueb|nuevo|falso|diego'
    OR LOWER(apellido_paterno) ~ 'test|prueba|apoderado'
    OR LOWER(email) ~ '@test\.(cl|com)|test@|@tses\.lc|@falson\.cl|@gmail\.com.*falso';

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================

-- Verificar que no quedan apoderados de prueba
SELECT 
    'VERIFICACIÓN' as tipo,
    COUNT(*) as apoderados_prueba_restantes
FROM guardians
WHERE 
    LOWER(first_name) ~ 'test|ttest|mama|papa|nnnnnnnnn|apoderado|prueb|nuevo|falso|diego'
    OR LOWER(apellido_paterno) ~ 'test|prueba|apoderado'
    OR LOWER(email) ~ '@test\.(cl|com)|test@|@tses\.lc|@falson\.cl|@gmail\.com.*falso';

-- Resumen de eliminación
SELECT 
    'RESUMEN' as tipo,
    'Apoderados de prueba eliminados' as descripcion,
    (
        SELECT COUNT(*)
        FROM guardians
        WHERE created_at < NOW()
    ) as total_apoderados_actuales;

-- =====================================================
-- IMPORTANTE: Revisar resultados antes de hacer COMMIT
-- =====================================================
-- Si los resultados son correctos, ejecutar: COMMIT;
-- Si algo está mal, ejecutar: ROLLBACK;

-- COMMIT; -- Descomentar después de verificar

