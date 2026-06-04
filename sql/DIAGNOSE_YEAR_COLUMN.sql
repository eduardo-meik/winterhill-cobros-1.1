-- =====================================================
-- DIAGNÓSTICO COMPLETO DE ENROLLMENTS.YEAR
-- =====================================================
-- Fecha: 22 de diciembre 2025
-- Problema: Column year NO permite NULL pero tiene strings vacíos

-- 1. Ver tipos de valores en year
SELECT 
    'Valores únicos en year' as diagnostico,
    year::TEXT as valor_texto,
    LENGTH(year::TEXT) as longitud,
    COUNT(*) as cantidad
FROM public.enrollments
GROUP BY year::TEXT
ORDER BY cantidad DESC;

-- 2. Ver enrollments con year problemático
SELECT 
    id,
    year::TEXT as year_text,
    LENGTH(year::TEXT) as longitud,
    created_at,
    status,
    EXTRACT(YEAR FROM created_at)::INTEGER as year_from_created_at
FROM public.enrollments
WHERE year::TEXT = '' 
   OR year::TEXT IS NULL
   OR LENGTH(year::TEXT) = 0
LIMIT 10;

-- 3. Contar enrollments problemáticos
SELECT 
    COUNT(*) as total_enrollments_con_year_vacio
FROM public.enrollments
WHERE year::TEXT = '' 
   OR LENGTH(year::TEXT) = 0;

-- 4. Ver si hay NULLs (no debería porque column es NOT NULL)
SELECT 
    COUNT(*) as total_nulls
FROM public.enrollments
WHERE year IS NULL;
