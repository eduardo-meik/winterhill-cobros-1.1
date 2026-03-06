-- ============================================================
-- DIAGNÓSTICO: Buscar campos con strings vacíos que deberían ser números
-- ============================================================

-- Verificar campos numéricos en students que podrían tener strings vacíos
SELECT 
    'students.curso' as campo,
    COUNT(*) as total,
    COUNT(CASE WHEN curso::text = '' THEN 1 END) as vacios
FROM students
UNION ALL
SELECT 
    'cursos.year_academico',
    COUNT(*),
    COUNT(CASE WHEN year_academico::text = '' THEN 1 END)
FROM cursos;

-- Ver el tipo de dato de curso en students
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'students' 
  AND column_name = 'curso';

-- Ver el tipo de dato de year_academico en cursos
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'cursos' 
  AND column_name = 'year_academico';

-- Buscar students con curso vacío o NULL
SELECT 
    id,
    first_name,
    apellido_paterno,
    curso,
    pg_typeof(curso) as curso_type
FROM students
WHERE curso IS NULL OR curso::text = ''
LIMIT 10;

-- Buscar cursos con year_academico vacío o NULL
SELECT 
    id,
    nom_curso,
    year_academico,
    pg_typeof(year_academico) as year_type
FROM cursos
WHERE year_academico IS NULL OR year_academico::text = ''
LIMIT 10;
