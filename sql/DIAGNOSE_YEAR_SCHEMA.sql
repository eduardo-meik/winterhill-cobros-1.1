-- ============================================================
-- DIAGNÓSTICO COMPLETO: Verificar schema de enrollments
-- ============================================================

-- Ver el tipo de dato de la columna year
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'enrollments' 
  AND column_name = 'year';

-- Ver valores actuales en year
SELECT 
    year,
    COUNT(*) as count,
    pg_typeof(year) as type
FROM enrollments
GROUP BY year, pg_typeof(year)
ORDER BY count DESC;

-- Ver enrollments con year como string vacío
SELECT 
    id,
    year,
    LENGTH(year::text) as year_length,
    created_at
FROM enrollments
WHERE year::text = ''
LIMIT 10;
