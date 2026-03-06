-- ============================================================
-- LIMPIEZA RÁPIDA: Corregir enrollments.year
-- ============================================================
-- Actualiza registros con year NULL o 0 usando la fecha de creación

UPDATE enrollments
SET year = EXTRACT(YEAR FROM created_at)::INTEGER
WHERE year IS NULL OR year = 0;

-- Verificación (debe retornar 0)
SELECT COUNT(*) as registros_con_year_invalido
FROM enrollments
WHERE year IS NULL OR year = 0;
