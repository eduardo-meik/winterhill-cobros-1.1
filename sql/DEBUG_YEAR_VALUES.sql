-- ============================================================
-- VERIFICAR EXACTAMENTE QUÉ HAY EN e.year
-- ============================================================

-- Ver TODOS los valores únicos de year (incluyendo raros)
SELECT 
    year,
    COUNT(*) as count,
    pg_typeof(year) as type,
    CASE 
        WHEN year IS NULL THEN 'NULL'
        WHEN year = 0 THEN 'ZERO'
        WHEN year > 0 THEN 'VALID'
        ELSE 'OTHER'
    END as category
FROM enrollments
GROUP BY year
ORDER BY year DESC NULLS LAST;

-- Intentar el mismo CASE que está en la función
SELECT 
    id,
    year,
    created_at,
    CASE 
        WHEN year IS NOT NULL AND year > 0 THEN year 
        ELSE EXTRACT(YEAR FROM created_at)::INTEGER 
    END as calculated_year
FROM enrollments
LIMIT 10;

-- Ver si hay algún enrollment que cause problema
SELECT 
    e.id,
    e.year,
    e.created_at,
    s.id as student_id,
    s.first_name
FROM enrollments e
INNER JOIN enrollment_students es ON e.id = es.enrollment_id
INNER JOIN students s ON es.student_id = s.id
LIMIT 5;
