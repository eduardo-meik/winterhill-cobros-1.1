-- ══════════════════════════════════════════════════════════════════════
-- ELIMINACIÓN DE ENROLLMENTS VACÍOS
-- Fecha: 2025-12-19
-- 
-- Este script eliminará 371 enrollments que NO tienen estudiantes asociados
-- (matrículas abandonadas/incompletas)
-- ══════════════════════════════════════════════════════════════════════

BEGIN;

-- ══════════════════════════════════════════════════════════════════════
-- ELIMINAR ENROLLMENTS SIN ESTUDIANTES
-- ══════════════════════════════════════════════════════════════════════

DELETE FROM public.enrollments
WHERE id NOT IN (
    SELECT DISTINCT enrollment_id 
    FROM public.enrollment_students
);

-- ══════════════════════════════════════════════════════════════════════
-- VERIFICACIÓN FINAL
-- ══════════════════════════════════════════════════════════════════════

SELECT 
    'Total enrollments restantes' as metrica,
    COUNT(*) as valor
FROM public.enrollments

UNION ALL

SELECT 
    'Enrollments con estudiantes' as metrica,
    COUNT(DISTINCT e.id) as valor
FROM public.enrollments e
WHERE EXISTS (
    SELECT 1 FROM enrollment_students es WHERE es.enrollment_id = e.id
)

UNION ALL

SELECT 
    'Enrollments vacíos restantes' as metrica,
    COUNT(*) as valor
FROM public.enrollments e
WHERE NOT EXISTS (
    SELECT 1 FROM enrollment_students es WHERE es.enrollment_id = e.id
);

-- Si la verificación muestra:
-- - Total enrollments restantes: 414
-- - Enrollments con estudiantes: 414
-- - Enrollments vacíos restantes: 0
-- Entonces ejecuta COMMIT

-- COMMIT;
-- ROLLBACK;
