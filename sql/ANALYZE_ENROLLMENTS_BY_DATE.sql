-- ══════════════════════════════════════════════════════════════════════
-- ANÁLISIS DE ENROLLMENTS POR AÑO Y FECHA
-- Fecha: 2025-12-19
-- ══════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════
-- ENROLLMENTS POR AÑO (según campo year)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Por campo YEAR' as tipo_analisis,
    COALESCE(e.year, 0) as año,
    COUNT(*) as total_enrollments,
    MIN(e.created_at) as primera_matricula,
    MAX(e.created_at) as ultima_matricula
FROM public.enrollments e
GROUP BY e.year
ORDER BY e.year DESC;

-- ══════════════════════════════════════════════════════════════════════
-- ENROLLMENTS POR AÑO (según created_at timestamp)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Por TIMESTAMP created_at' as tipo_analisis,
    EXTRACT(YEAR FROM e.created_at)::INTEGER as año_creacion,
    COUNT(*) as total_enrollments,
    MIN(e.created_at) as primera_matricula,
    MAX(e.created_at) as ultima_matricula
FROM public.enrollments e
GROUP BY EXTRACT(YEAR FROM e.created_at)
ORDER BY año_creacion DESC;

-- ══════════════════════════════════════════════════════════════════════
-- ENROLLMENTS DESDE DICIEMBRE 8, 2025 (fecha correcta)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Desde 08/12/2025' as periodo,
    COUNT(*) as total_enrollments,
    COUNT(DISTINCT e.guardian_id) as apoderados_unicos,
    (SELECT COUNT(*) FROM enrollment_students es 
     JOIN enrollments e2 ON es.enrollment_id = e2.id 
     WHERE e2.created_at >= '2025-12-08'::date) as estudiantes_matriculados
FROM public.enrollments e
WHERE e.created_at >= '2025-12-08'::date;

-- ══════════════════════════════════════════════════════════════════════
-- DETALLE: Enrollments recientes (desde dic 8, 2025)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    e.id,
    e.year as año_campo,
    EXTRACT(YEAR FROM e.created_at)::INTEGER as año_timestamp,
    TO_CHAR(e.created_at, 'DD/MM/YYYY HH24:MI') as fecha_creacion,
    e.status,
    g.first_name || ' ' || COALESCE(split_part(COALESCE(g.last_name, ''), ' ', 1), '') as apoderado,
    (SELECT COUNT(*) FROM enrollment_students es WHERE es.enrollment_id = e.id) as cant_estudiantes
FROM public.enrollments e
LEFT JOIN public.guardians g ON e.guardian_id = g.id
WHERE e.created_at >= '2025-12-08'::date
ORDER BY e.created_at DESC
LIMIT 50;

-- ══════════════════════════════════════════════════════════════════════
-- DISTRIBUCIÓN COMPLETA POR MES Y AÑO
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    EXTRACT(YEAR FROM e.created_at)::INTEGER as año,
    EXTRACT(MONTH FROM e.created_at)::INTEGER as mes,
    TO_CHAR(e.created_at, 'Month YYYY') as periodo,
    COUNT(*) as total_enrollments,
    COUNT(DISTINCT e.guardian_id) as apoderados_unicos
FROM public.enrollments e
GROUP BY 
    EXTRACT(YEAR FROM e.created_at),
    EXTRACT(MONTH FROM e.created_at),
    TO_CHAR(e.created_at, 'Month YYYY')
ORDER BY año DESC, mes DESC;

-- ══════════════════════════════════════════════════════════════════════
-- ENROLLMENTS ANTIGUOS (antes de 2025)
-- ══════════════════════════════════════════════════════════════════════
SELECT 
    'Enrollments ANTIGUOS (antes 2025)' as categoria,
    COUNT(*) as total,
    MIN(e.created_at) as mas_antiguo,
    MAX(e.created_at) as mas_reciente
FROM public.enrollments e
WHERE e.created_at < '2025-01-01'::date;
