-- ============================================================================
-- LIMPIEZA: Enrollments con year inválido
-- ============================================================================

-- Verificar enrollments con year problemático
SELECT 
    id,
    year,
    created_at,
    EXTRACT(YEAR FROM created_at) as year_from_timestamp
FROM enrollments
WHERE year IS NULL OR year::TEXT = '';

-- Actualizar enrollments con year NULL o vacío
UPDATE enrollments
SET year = EXTRACT(YEAR FROM created_at)::INTEGER
WHERE year IS NULL;

-- Verificar resultado
SELECT 
    COUNT(*) as total_enrollments,
    COUNT(year) as enrollments_con_year,
    COUNT(*) - COUNT(year) as enrollments_sin_year
FROM enrollments;
