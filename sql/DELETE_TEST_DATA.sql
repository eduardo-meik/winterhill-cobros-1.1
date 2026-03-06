-- ══════════════════════════════════════════════════════════════════════
-- ELIMINACIÓN DE DATOS DE PRUEBA
-- Fecha: 2025-12-19
-- 
-- ADVERTENCIA: Este script eliminará PERMANENTEMENTE los registros de prueba
-- y todos los datos relacionados (enrollments, guardians, etc.)
-- 
-- Total a eliminar:
-- - 9 Estudiantes de prueba
-- - 24 Apoderados de prueba
-- - 41 Enrollments de prueba
-- ══════════════════════════════════════════════════════════════════════

BEGIN;

-- ══════════════════════════════════════════════════════════════════════
-- PASO 1: Eliminar enrollment_students (tabla intermedia)
-- ══════════════════════════════════════════════════════════════════════

-- Eliminar enlaces de estudiantes con enrollments de prueba
DELETE FROM public.enrollment_students
WHERE student_id IN (
    SELECT s.id
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
);

-- Eliminar enrollment_students de enrollments de apoderados de prueba
DELETE FROM public.enrollment_students
WHERE enrollment_id IN (
    SELECT e.id
    FROM public.enrollments e
    LEFT JOIN public.guardians g ON e.guardian_id = g.id
    WHERE 
        LOWER(g.first_name) LIKE '%falso%'
        OR LOWER(g.first_name) LIKE '%test%'
        OR LOWER(g.first_name) LIKE '%prueba%'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%falso%'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%test%'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%prueba%'
        OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%falso%'
        OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%test%'
        OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%prueba%'
        OR LOWER(g.email) LIKE '%test%'
        OR LOWER(g.email) LIKE '%fake%'
        OR LOWER(g.email) LIKE '%falso%'
);

-- ══════════════════════════════════════════════════════════════════════
-- PASO 2: Eliminar student_guardian (relación estudiante-apoderado)
-- ══════════════════════════════════════════════════════════════════════

-- Eliminar relaciones de estudiantes de prueba
DELETE FROM public.student_guardian
WHERE student_id IN (
    SELECT s.id
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
);

-- Eliminar relaciones de apoderados de prueba
DELETE FROM public.student_guardian
WHERE guardian_id IN (
    SELECT g.id
    FROM public.guardians g
    WHERE 
        LOWER(g.first_name) LIKE '%falso%'
        OR LOWER(g.first_name) LIKE '%test%'
        OR LOWER(g.first_name) LIKE '%prueba%'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%falso%'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%test%'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%prueba%'
        OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%falso%'
        OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%test%'
        OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%prueba%'
        OR LOWER(g.email) LIKE '%test%'
        OR LOWER(g.email) LIKE '%fake%'
        OR LOWER(g.email) LIKE '%falso%'
);

-- ══════════════════════════════════════════════════════════════════════
-- PASO 3: Eliminar enrollments de apoderados de prueba
-- ══════════════════════════════════════════════════════════════════════

DELETE FROM public.enrollments
WHERE guardian_id IN (
    SELECT g.id
    FROM public.guardians g
    WHERE 
        LOWER(g.first_name) LIKE '%falso%'
        OR LOWER(g.first_name) LIKE '%test%'
        OR LOWER(g.first_name) LIKE '%prueba%'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%falso%'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%test%'
        OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%prueba%'
        OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%falso%'
        OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%test%'
        OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%prueba%'
        OR LOWER(g.email) LIKE '%test%'
        OR LOWER(g.email) LIKE '%fake%'
        OR LOWER(g.email) LIKE '%falso%'
);

-- ══════════════════════════════════════════════════════════════════════
-- PASO 4: Eliminar estudiantes de prueba
-- ══════════════════════════════════════════════════════════════════════

DELETE FROM public.students
WHERE 
    LOWER(first_name) LIKE '%falso%'
    OR LOWER(first_name) LIKE '%test%'
    OR LOWER(first_name) LIKE '%prueba%'
    OR LOWER(apellido_paterno) LIKE '%falso%'
    OR LOWER(apellido_paterno) LIKE '%test%'
    OR LOWER(apellido_paterno) LIKE '%prueba%'
    OR LOWER(apellido_materno) LIKE '%falso%'
    OR LOWER(apellido_materno) LIKE '%test%'
    OR LOWER(apellido_materno) LIKE '%prueba%'
    OR LOWER(email) LIKE '%test%'
    OR LOWER(email) LIKE '%fake%'
    OR LOWER(email) LIKE '%falso%';

-- ══════════════════════════════════════════════════════════════════════
-- PASO 5: Eliminar apoderados de prueba
-- ══════════════════════════════════════════════════════════════════════

DELETE FROM public.guardians
WHERE 
    LOWER(first_name) LIKE '%falso%'
    OR LOWER(first_name) LIKE '%test%'
    OR LOWER(first_name) LIKE '%prueba%'
    OR LOWER(apellido_paterno) LIKE '%falso%'
    OR LOWER(apellido_paterno) LIKE '%test%'
    OR LOWER(apellido_paterno) LIKE '%prueba%'
    OR LOWER(apellido_materno) LIKE '%falso%'
    OR LOWER(apellido_materno) LIKE '%test%'
    OR LOWER(apellido_materno) LIKE '%prueba%'
    OR LOWER(email) LIKE '%test%'
    OR LOWER(email) LIKE '%fake%'
    OR LOWER(email) LIKE '%falso%';

-- ══════════════════════════════════════════════════════════════════════
-- VERIFICACIÓN FINAL
-- ══════════════════════════════════════════════════════════════════════

SELECT 
    'Estudiantes de prueba restantes' as verificacion,
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
    'Apoderados de prueba restantes' as verificacion,
    COUNT(*) as total
FROM public.guardians g
WHERE 
    LOWER(g.first_name) LIKE '%falso%'
    OR LOWER(g.first_name) LIKE '%test%'
    OR LOWER(g.first_name) LIKE '%prueba%'
    OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%falso%'
    OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%test%'
    OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%prueba%'
    OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%falso%'
    OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%test%'
    OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%prueba%'
    OR LOWER(g.email) LIKE '%test%'
    OR LOWER(g.email) LIKE '%fake%'
    OR LOWER(g.email) LIKE '%falso%'

UNION ALL

SELECT 
    'Enrollments de prueba restantes' as verificacion,
    COUNT(*) as total
FROM public.enrollments e
LEFT JOIN public.guardians g ON e.guardian_id = g.id
WHERE 
    LOWER(g.first_name) LIKE '%falso%'
    OR LOWER(g.first_name) LIKE '%test%'
    OR LOWER(g.first_name) LIKE '%prueba%'
    OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%falso%'
    OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%test%'
    OR LOWER(split_part(COALESCE(g.last_name, ''), ' ', 1)) LIKE '%prueba%'
    OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%falso%'
    OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%test%'
    OR LOWER(NULLIF(regexp_replace(COALESCE(g.last_name, ''), '^\S+\s*', ''), '')) LIKE '%prueba%'
    OR LOWER(g.email) LIKE '%test%'
    OR LOWER(g.email) LIKE '%fake%'
    OR LOWER(g.email) LIKE '%falso%';

-- Si la verificación muestra 0 en todo, ejecuta COMMIT
-- Si hay algún problema, ejecuta ROLLBACK

-- COMMIT;
-- ROLLBACK;
