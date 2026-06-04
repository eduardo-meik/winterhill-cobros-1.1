-- ============================================================
-- PASO 1: BORRAR ESTUDIANTES DE PRUEBA COMPLETAMENTE
-- ============================================================
-- Este script elimina 3 estudiantes de prueba identificados:
-- 1. FALSO HIJO FALSO FALSO (5275f00b-5192-44a8-b40c-8270430bbbb2)
-- 2. Test2 TESTING-2 (3265dd7b-16e2-47b6-85ad-0747c125ec3b)
-- 3. ttestHIJO (5113c728-3185-4498-a5ed-6362e7e8c6d9)

-- VERIFICACIÓN ANTES DE BORRAR
SELECT 
    s.id,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    COUNT(DISTINCT es.enrollment_id) as total_enrollments,
    COUNT(DISTINCT sg.guardian_id) as total_guardians
FROM students s
LEFT JOIN enrollment_students es ON s.id = es.student_id
LEFT JOIN student_guardian sg ON s.id = sg.student_id
WHERE s.id IN (
    '5275f00b-5192-44a8-b40c-8270430bbbb2',  -- FALSO HIJO
    '3265dd7b-16e2-47b6-85ad-0747c125ec3b',  -- Test2 TESTING-2
    '5113c728-3185-4498-a5ed-6362e7e8c6d9'   -- ttestHIJO
)
GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno
ORDER BY s.first_name;

-- BORRAR EN ORDEN DE DEPENDENCIAS
BEGIN;

-- 1. Borrar de enrollment_students (tabla de unión)
DELETE FROM enrollment_students
WHERE student_id IN (
    '5275f00b-5192-44a8-b40c-8270430bbbb2',
    '3265dd7b-16e2-47b6-85ad-0747c125ec3b',
    '5113c728-3185-4498-a5ed-6362e7e8c6d9'
);

-- 2. Borrar de student_guardian (tabla de unión)
DELETE FROM student_guardian
WHERE student_id IN (
    '5275f00b-5192-44a8-b40c-8270430bbbb2',
    '3265dd7b-16e2-47b6-85ad-0747c125ec3b',
    '5113c728-3185-4498-a5ed-6362e7e8c6d9'
);

-- 3. Borrar de students (tabla principal)
DELETE FROM students
WHERE id IN (
    '5275f00b-5192-44a8-b40c-8270430bbbb2',
    '3265dd7b-16e2-47b6-85ad-0747c125ec3b',
    '5113c728-3185-4498-a5ed-6362e7e8c6d9'
);

COMMIT;

-- VERIFICACIÓN POST-DELETE (debe retornar 0 filas)
SELECT 
    s.id,
    s.first_name,
    s.apellido_paterno
FROM students s
WHERE s.id IN (
    '5275f00b-5192-44a8-b40c-8270430bbbb2',
    '3265dd7b-16e2-47b6-85ad-0747c125ec3b',
    '5113c728-3185-4498-a5ed-6362e7e8c6d9'
);
