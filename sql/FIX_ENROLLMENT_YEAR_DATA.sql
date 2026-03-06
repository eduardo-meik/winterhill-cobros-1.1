-- ============================================================
-- FIX: Limpiar datos incorrectos en enrollments.year
-- ============================================================
-- Problema: Campo year contiene strings vacíos '' que causan error
-- Solución: Convertir strings vacíos a NULL y derivar year del created_at

-- PASO 1: Verificar el problema
SELECT 
    id,
    year,
    created_at,
    EXTRACT(YEAR FROM created_at)::INTEGER as year_from_date,
    CASE 
        WHEN year IS NULL THEN 'NULL'
        WHEN year = 0 THEN 'ZERO'
        ELSE 'VALID'
    END as year_status
FROM enrollments
WHERE year IS NULL OR year = 0
LIMIT 20;

-- PASO 2: Contar registros afectados
SELECT 
    COUNT(*) as total_enrollments,
    COUNT(CASE WHEN year IS NULL OR year = 0 THEN 1 END) as with_null_year,
    COUNT(CASE WHEN year IS NOT NULL AND year > 0 THEN 1 END) as with_valid_year
FROM enrollments;

-- PASO 3: Actualizar registros con year NULL o 0
BEGIN;

UPDATE enrollments
SET year = EXTRACT(YEAR FROM created_at)::INTEGER
WHERE year IS NULL OR year = 0;

-- Verificar actualización
SELECT 
    COUNT(*) as updated_count,
    MIN(year) as min_year,
    MAX(year) as max_year
FROM enrollments
WHERE year IS NOT NULL;

COMMIT;

-- PASO 4: Verificación final (debe retornar 0)
SELECT COUNT(*) as enrollments_sin_year
FROM enrollments
WHERE year IS NULL OR year = 0;

-- PASO 5: Ver distribución por año
SELECT 
    year,
    COUNT(*) as total,
    MIN(created_at::date) as primera_matricula,
    MAX(created_at::date) as ultima_matricula
FROM enrollments
GROUP BY year
ORDER BY year DESC;
