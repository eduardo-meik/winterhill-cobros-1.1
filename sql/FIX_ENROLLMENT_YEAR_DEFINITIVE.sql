-- ============================================================================
-- FIX DEFINITIVO: Limpiar enrollments.year con strings vacíos
-- ============================================================================

-- PASO 1: Ver cuántos enrollments tienen year problemático
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN year IS NULL THEN 1 END) as year_null,
    COUNT(CASE WHEN year::TEXT = '' THEN 1 END) as year_empty_string
FROM enrollments;

-- PASO 2: Actualizar todos los year que sean NULL o empty string
UPDATE enrollments
SET year = EXTRACT(YEAR FROM created_at)::INTEGER
WHERE year IS NULL 
   OR year::TEXT = '';

-- PASO 3: Verificar resultado
SELECT 
    COUNT(*) as total,
    MIN(year) as min_year,
    MAX(year) as max_year,
    COUNT(CASE WHEN year IS NULL THEN 1 END) as year_null_restantes
FROM enrollments;

-- PASO 4: Probar la función
SELECT * FROM generate_libro_matricula_report(NULL, NULL, NULL) LIMIT 3;
