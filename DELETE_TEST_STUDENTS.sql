-- =====================================================
-- ELIMINAR ESTUDIANTES DE PRUEBA
-- =====================================================
-- Eliminar estudiantes: junito testing y Test1 TESTING-1
-- =====================================================

BEGIN;

-- =====================================================
-- PASO 1: ELIMINAR ESTUDIANTES DE PRUEBA
-- =====================================================

-- 1.1 Eliminar de enrollment_students
DELETE FROM enrollment_students
WHERE student_id IN (
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26',  -- junito testing
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'   -- Test1 TESTING-1
);

-- 1.2 Eliminar de student_guardian
DELETE FROM student_guardian
WHERE student_id IN (
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26',
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'
);

-- 1.3 Eliminar estudiantes
DELETE FROM students
WHERE id IN (
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26',
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'
);

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

SELECT 
    'VERIFICACIÓN' as tipo,
    COUNT(*) as estudiantes_prueba_restantes
FROM students
WHERE id IN (
    '99f9a557-fd89-4ced-8ffb-b4b800a17f26',
    '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'
);

-- Debe retornar 0

-- COMMIT; -- Descomentar después de verificar
