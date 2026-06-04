-- ============================================================
-- FIX DEFINITIVO: Convertir year de TEXT a INTEGER
-- ============================================================

-- PASO 1: Crear columna temporal con tipo INTEGER
ALTER TABLE enrollments ADD COLUMN year_temp INTEGER;

-- PASO 2: Migrar datos - convertir strings vacíos y NULL a año del created_at
UPDATE enrollments
SET year_temp = CASE 
    WHEN year IS NULL OR year::text = '' OR year::text = '0' THEN EXTRACT(YEAR FROM created_at)::INTEGER
    ELSE year::integer
END;

-- PASO 3: Verificar que todos los datos se migraron correctamente
SELECT 
    COUNT(*) as total,
    COUNT(year_temp) as con_year_temp,
    COUNT(CASE WHEN year_temp IS NULL THEN 1 END) as nulls
FROM enrollments;

-- PASO 4: Eliminar columna vieja y renombrar
ALTER TABLE enrollments DROP COLUMN year;
ALTER TABLE enrollments RENAME COLUMN year_temp TO year;

-- PASO 5: Agregar constraint para asegurar valores válidos
ALTER TABLE enrollments 
    ADD CONSTRAINT enrollments_year_check 
    CHECK (year BETWEEN 2000 AND 2100);

-- PASO 6: Verificación final
SELECT 
    year,
    COUNT(*) as total,
    pg_typeof(year) as type
FROM enrollments
GROUP BY year
ORDER BY year DESC;
