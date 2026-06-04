-- ============================================================
-- VERIFICAR Y LIMPIAR DATOS DE ENROLLMENTS
-- ============================================================

-- Ver enrollments con problemas de year
SELECT 
    id,
    year,
    pg_typeof(year) as year_type,
    created_at,
    status
FROM enrollments
WHERE year::text = '' OR year IS NULL
LIMIT 20;

-- Contar todos los problemas
SELECT 
    COUNT(*) as total_enrollments,
    COUNT(CASE WHEN year::text = '' THEN 1 END) as year_empty_string,
    COUNT(CASE WHEN year IS NULL THEN 1 END) as year_null,
    COUNT(CASE WHEN year = 0 THEN 1 END) as year_zero
FROM enrollments;
