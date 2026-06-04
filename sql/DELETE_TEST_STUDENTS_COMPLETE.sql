-- ============================================================================
-- ELIMINAR ESTUDIANTES DE PRUEBA - COMPLETO
-- Created: 2025-12-22
-- Elimina completamente 7 estudiantes de prueba y todos sus datos relacionados
-- ============================================================================

-- IMPORTANTE: Este script eliminará PERMANENTEMENTE estos estudiantes y todos
-- sus datos relacionados (matrículas, documentos, pagos, etc.)

BEGIN;

-- ============================================================================
-- PASO 1: VERIFICAR QUÉ SE VA A BORRAR
-- ============================================================================
SELECT 
    'RESUMEN DE ELIMINACIÓN' as accion,
    COUNT(DISTINCT s.id) as estudiantes_a_borrar,
    COUNT(DISTINCT e.id) as matriculas_a_borrar,
    COUNT(*) as registros_enrollment_students
FROM students s
LEFT JOIN enrollment_students es ON es.student_id = s.id
LEFT JOIN enrollments e ON e.id = es.enrollment_id
WHERE s.id IN (
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,  -- Test1
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,  -- junito
    'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,  -- TESTING
    '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,  -- Estudiante
    '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,  -- ESTUDIANTE
    '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,  -- TESTNUEVO
    '453a4353-fc3a-4682-87ac-815da1186d68'::uuid   -- SANTIAGO (year 2022)
);

-- ============================================================================
-- PASO 2: LISTAR TODOS LOS ESTUDIANTES QUE SE VAN A BORRAR
-- ============================================================================
SELECT 
    s.id,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    s.run as rut,
    COUNT(DISTINCT e.id) as matriculas_count,
    STRING_AGG(DISTINCT e.year::text, ', ' ORDER BY e.year::text) as años_matriculados
FROM students s
LEFT JOIN enrollment_students es ON es.student_id = s.id
LEFT JOIN enrollments e ON e.id = es.enrollment_id
WHERE s.id IN (
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,  -- Test1
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,  -- junito
    'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,  -- TESTING
    '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,  -- Estudiante
    '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,  -- ESTUDIANTE
    '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,  -- TESTNUEVO
    '453a4353-fc3a-4682-87ac-815da1186d68'::uuid   -- SANTIAGO (year 2022)
)
GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno, s.run
ORDER BY s.first_name;

-- ============================================================================
-- PASO 3: ELIMINAR DATOS RELACIONADOS (en orden correcto)
-- ============================================================================

-- 3.1 Eliminar documentos de matrícula (enrollment_documents)
DELETE FROM enrollment_documents
WHERE enrollment_id IN (
    SELECT DISTINCT e.id
    FROM enrollments e
    INNER JOIN enrollment_students es ON es.enrollment_id = e.id
    WHERE es.student_id IN (
        '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,
        '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,
        'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,
        '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,
        '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,
        '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,
        '453a4353-fc3a-4682-87ac-815da1186d68'::uuid
    )
);

-- 3.2 Eliminar recibos de documentos
DELETE FROM enrollment_document_receipts
WHERE enrollment_id IN (
    SELECT DISTINCT e.id
    FROM enrollments e
    INNER JOIN enrollment_students es ON es.enrollment_id = e.id
    WHERE es.student_id IN (
        '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,
        '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,
        'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,
        '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,
        '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,
        '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,
        '453a4353-fc3a-4682-87ac-815da1186d68'::uuid
    )
);

-- 3.3 Eliminar cuotas (fee)
DELETE FROM fee
WHERE enrollment_id IN (
    SELECT DISTINCT e.id
    FROM enrollments e
    INNER JOIN enrollment_students es ON es.enrollment_id = e.id
    WHERE es.student_id IN (
        '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,
        '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,
        'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,
        '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,
        '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,
        '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,
        '453a4353-fc3a-4682-87ac-815da1186d68'::uuid
    )
);

-- 3.4 Eliminar cheques
DELETE FROM cheques
WHERE enrollment_id IN (
    SELECT DISTINCT e.id
    FROM enrollments e
    INNER JOIN enrollment_students es ON es.enrollment_id = e.id
    WHERE es.student_id IN (
        '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,
        '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,
        'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,
        '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,
        '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,
        '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,
        '453a4353-fc3a-4682-87ac-815da1186d68'::uuid
    )
);

-- 3.5 public.pre_receipts fue retirada el 2026-04-07. No se requiere limpieza.

-- 3.6 public.invoices fue retirada el 2026-04-07. No se requiere limpieza.

-- 3.7 Eliminar relación enrollment_students
DELETE FROM enrollment_students
WHERE student_id IN (
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,  -- Test1
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,  -- junito
    'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,  -- TESTING
    '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,  -- Estudiante
    '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,  -- ESTUDIANTE
    '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,  -- TESTNUEVO
    '453a4353-fc3a-4682-87ac-815da1186d68'::uuid   -- SANTIAGO (year 2022)
);

-- 3.8 Eliminar matrículas huérfanas (enrollments sin estudiantes)
DELETE FROM enrollments
WHERE id IN (
    SELECT e.id
    FROM enrollments e
    LEFT JOIN enrollment_students es ON es.enrollment_id = e.id
    WHERE es.enrollment_id IS NULL
);

-- 3.9 Eliminar registros académicos
DELETE FROM student_academic_records
WHERE student_id IN (
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,
    'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,
    '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,
    '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,
    '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,
    '453a4353-fc3a-4682-87ac-815da1186d68'::uuid
);

-- 3.10 Eliminar relación student_guardian
DELETE FROM student_guardian
WHERE student_id IN (
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,
    'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,
    '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,
    '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,
    '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,
    '453a4353-fc3a-4682-87ac-815da1186d68'::uuid
);

-- 3.11 Eliminar apoderados (si no tienen otros estudiantes)
DELETE FROM guardians
WHERE id IN (
    SELECT DISTINCT g.id
    FROM guardians g
    INNER JOIN student_guardian sg ON sg.guardian_id = g.id
    WHERE sg.student_id IN (
        '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,
        '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,
        'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,
        '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,
        '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,
        '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,
        '453a4353-fc3a-4682-87ac-815da1186d68'::uuid
    )
    -- Solo eliminar si el apoderado no tiene otros estudiantes
    AND NOT EXISTS (
        SELECT 1 FROM student_guardian sg2
        WHERE sg2.guardian_id = g.id
        AND sg2.student_id NOT IN (
            '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,
            '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,
            'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,
            '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,
            '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,
            '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,
            '453a4353-fc3a-4682-87ac-815da1186d68'::uuid
        )
    )
);

-- ============================================================================
-- PASO 4: ELIMINAR LOS ESTUDIANTES
-- ============================================================================
DELETE FROM students
WHERE id IN (
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,  -- Test1
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,  -- junito
    'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,  -- TESTING
    '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,  -- Estudiante
    '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,  -- ESTUDIANTE
    '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,  -- TESTNUEVO
    '453a4353-fc3a-4682-87ac-815da1186d68'::uuid   -- SANTIAGO (year 2022)
);

-- ============================================================================
-- PASO 5: VERIFICAR ELIMINACIÓN
-- ============================================================================
SELECT 
    'VERIFICACIÓN FINAL' as resultado,
    COUNT(*) as estudiantes_test_restantes
FROM students
WHERE id IN (
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid,
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid,
    'bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid,
    '5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid,
    '11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid,
    '1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid,
    '453a4353-fc3a-4682-87ac-815da1186d68'::uuid
);
-- Debería retornar 0

-- ============================================================================
-- COMMIT O ROLLBACK
-- ============================================================================
-- DESCOMENTAR UNA DE LAS SIGUIENTES LÍNEAS:

-- COMMIT;    -- Ejecutar los cambios permanentemente
ROLLBACK;  -- Deshacer todos los cambios (para probar primero)

-- ============================================================================
-- RESUMEN DE ESTUDIANTES ELIMINADOS
-- ============================================================================
/*
ESTUDIANTES DE PRUEBA ELIMINADOS:

1. Test1 (4dce9f5a-cd94-43d1-a4e5-12b9558bd921)
   - Matrículas: 2022, 2025, 2026

2. junito (99f9a557-fd89-4ced-8ffb-b4b800a17f26)
   - Matrículas: 2025, 2026

3. TESTING (bbf7b971-5164-4b5a-a732-996c139f27f7)
   - Matrículas: 2025, 2026

4. Estudiante (5a739ec3-bfde-4b1e-94c1-561d940dc082)
   - Matrículas: 2026

5. ESTUDIANTE (11e1921f-3810-42de-91c7-cddf4bdc8f44)
   - Matrículas: 2026

6. TESTNUEVO (1453bf25-63e3-4d5d-8fe2-56bd370d2fbb)
   - Matrículas: 2026

7. SANTIAGO (453a4353-fc3a-4682-87ac-815da1186d68)
   - Matrículas: 2022, 2026 (year 2022 es dato de prueba)

TOTAL: 7 estudiantes eliminados completamente
*/
