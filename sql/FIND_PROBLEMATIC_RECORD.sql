-- ============================================================
-- DIAGNÓSTICO FINAL: Encontrar el registro problemático
-- ============================================================

-- Ejecutar la query interna de la función para ver dónde falla
SELECT 
    s.id as student_id,
    s.first_name,
    s.apellido_paterno,
    e.id as enrollment_id,
    e.year as enrollment_year,
    e.created_at,
    c.id as curso_id,
    c.nom_curso,
    c.year_academico,
    -- Intentar el CASE que está fallando
    CASE 
        WHEN e.year IS NOT NULL AND e.year > 0 THEN e.year 
        ELSE EXTRACT(YEAR FROM e.created_at)::INTEGER 
    END as calculated_year
FROM public.students s
INNER JOIN public.enrollment_students es ON s.id = es.student_id
INNER JOIN public.enrollments e ON es.enrollment_id = e.id
LEFT JOIN public.cursos c ON s.curso = c.id
WHERE e.year IS NULL OR c.year_academico IS NULL
LIMIT 20;

-- Ver si hay algún enrollment sin year válido
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN year IS NULL THEN 1 END) as year_null,
    COUNT(CASE WHEN year = 0 THEN 1 END) as year_zero
FROM enrollments;

-- Ver si hay cursos sin year_academico
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN year_academico IS NULL THEN 1 END) as year_null
FROM cursos;
