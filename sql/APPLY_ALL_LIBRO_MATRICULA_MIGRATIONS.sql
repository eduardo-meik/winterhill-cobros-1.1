-- ══════════════════════════════════════════════════════════════════════
-- MIGRACIONES CONSOLIDADAS: LIBRO DE MATRÍCULA
-- Fecha: 2025-12-19
-- 
-- Este archivo contiene todas las migraciones necesarias para implementar
-- el sistema de Libro de Matrícula.
-- 
-- INSTRUCCIONES:
-- 1. Ve a: https://supabase.com/dashboard/project/yeotpplgerfpxviqazrn/sql/new
-- 2. Copia y pega este archivo completo
-- 3. Ejecuta (Run)
-- ══════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════
-- MIGRACIÓN 1: Agregar estado PRE_MATRICULADO (OPCIONAL)
-- ══════════════════════════════════════════════════════════════════════
-- NOTA: Esta migración es opcional. El Libro de Matrícula funciona 
-- directamente desde enrollment_students sin necesidad de actualizar estados.

BEGIN;

ALTER TABLE public.students
  DROP CONSTRAINT IF EXISTS students_estado_std_check;

ALTER TABLE public.students
  ADD CONSTRAINT students_estado_std_check
  CHECK (estado_std IN ('ACTIVO','RETIRADO','MATRICULADO','PRE_MATRICULADO'));

COMMENT ON COLUMN public.students.estado_std IS 
'Estado del estudiante: PRE_MATRICULADO (matrícula en proceso desde dic 8+), MATRICULADO (confirmado para inicio año escolar en marzo), ACTIVO (cursando), RETIRADO (dado de baja)';

COMMIT;

-- ══════════════════════════════════════════════════════════════════════
-- MIGRACIÓN 2: Agregar campos faltantes a guardians
-- ══════════════════════════════════════════════════════════════════════

BEGIN;

ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS date_of_birth DATE;

ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS nivel_educacional VARCHAR(100);

ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

COMMENT ON COLUMN public.guardians.date_of_birth IS 'Fecha de nacimiento del apoderado para Libro de Matrícula';
COMMENT ON COLUMN public.guardians.nivel_educacional IS 'Nivel educacional: Básica Completa, Media Completa, Técnica, Universitaria, Postgrado, etc.';
COMMENT ON COLUMN public.guardians.apellido_paterno IS 'Apellido paterno del apoderado';
COMMENT ON COLUMN public.guardians.apellido_materno IS 'Apellido materno del apoderado';

COMMIT;

-- ══════════════════════════════════════════════════════════════════════
-- MIGRACIÓN 3: Agregar apellidos separados a students (si no existen)
-- ══════════════════════════════════════════════════════════════════════

BEGIN;

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

COMMENT ON COLUMN public.students.apellido_paterno IS 'Apellido paterno del estudiante';
COMMENT ON COLUMN public.students.apellido_materno IS 'Apellido materno del estudiante';

COMMIT;

-- ══════════════════════════════════════════════════════════════════════
-- MIGRACIÓN 4: Crear función RPC para generar Libro de Matrícula
-- ══════════════════════════════════════════════════════════════════════

-- Eliminar versiones anteriores de la función
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR);
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report();

CREATE OR REPLACE FUNCTION public.generate_libro_matricula_report(
  p_year INTEGER DEFAULT NULL,
  p_estado VARCHAR DEFAULT NULL,
  p_enrollment_status VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  numero_correlativo BIGINT,
  year_matricula INTEGER,
  fecha_matricula TIMESTAMP WITH TIME ZONE,
  nivel TEXT,
  curso TEXT,
  nombres TEXT,
  apellido_paterno TEXT,
  apellido_materno TEXT,
  run_estudiante TEXT,
  fecha_nac_estudiante TEXT,
  nacionalidad TEXT,
  genero_estudiante TEXT,
  con_quien_vive TEXT,
  direccion_estudiante TEXT,
  comuna_estudiante TEXT,
  repite_curso TEXT,
  institucion_procedencia TEXT,
  nombre_apoderado TEXT,
  apellido_paterno_apoderado TEXT,
  apellido_materno_apoderado TEXT,
  relacion_apoderado TEXT,
  fecha_nac_apoderado TEXT,
  run_apoderado TEXT,
  nivel_educacional_apoderado TEXT,
  direccion_apoderado TEXT,
  comuna_apoderado TEXT,
  email_apoderado TEXT,
  telefono_apoderado TEXT,
  nombre_apoderado_secundario TEXT,
  run_apoderado_secundario TEXT,
  fecha_nac_apoderado_secundario TEXT,
  telefono_apoderado_secundario TEXT,
  email_apoderado_secundario TEXT,
  fecha_retiro TEXT,
  motivo_retiro TEXT,
  condicion TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_year INTEGER;
  v_estado VARCHAR;
  v_status VARCHAR;
BEGIN
  -- Manejar parámetros NULL y strings vacíos
  v_year := p_year;
  v_estado := NULLIF(TRIM(COALESCE(p_estado, '')), '');
  v_status := NULLIF(TRIM(COALESCE(p_enrollment_status, '')), '');
  
  RETURN QUERY
  SELECT
    -- Numeración y fecha de matrícula
    ROW_NUMBER() OVER (ORDER BY e.created_at ASC)::BIGINT,
    COALESCE(e.year, EXTRACT(YEAR FROM e.created_at)::INTEGER),
    e.created_at,
    
    -- Curso info
    COALESCE(c.nivel, '')::TEXT,
    COALESCE(c.nom_curso, '')::TEXT,
    
    -- Estudiante
    COALESCE(s.first_name, '')::TEXT AS nombres,
    COALESCE(s.apellido_paterno, '')::TEXT,
    COALESCE(s.apellido_materno, '')::TEXT,
    COALESCE(s.run, '')::TEXT,
    COALESCE(TO_CHAR(s.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    UPPER(COALESCE(s.nacionalidad, 'CHILENA'))::TEXT,
    COALESCE(s.genero, '')::TEXT,
    COALESCE(s.con_quien_vive, '')::TEXT,
    COALESCE(s.direccion, '')::TEXT,
    COALESCE(s.comuna, '')::TEXT,
    CASE WHEN COALESCE(s.repite_curso_actual, 'No') ILIKE 'si%' THEN 'Sí' ELSE 'No' END::TEXT,
    COALESCE(s.institucion_procedencia, '')::TEXT,
    
    -- Apoderado principal
    COALESCE(g1.first_name, '')::TEXT,
    COALESCE(g1.apellido_paterno, '')::TEXT,
    COALESCE(g1.apellido_materno, '')::TEXT,
    COALESCE(g1.relationship_type, '')::TEXT,
    COALESCE(TO_CHAR(g1.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g1.run, '')::TEXT,
    COALESCE(g1.nivel_educacional, '')::TEXT,
    COALESCE(g1.address, '')::TEXT,
    COALESCE(g1.comuna, '')::TEXT,
    COALESCE(g1.email, '')::TEXT,
    COALESCE(g1.phone, '')::TEXT,
    
    -- Apoderado secundario
    COALESCE(g2.first_name || ' ' || COALESCE(g2.apellido_paterno, '') || ' ' || COALESCE(g2.apellido_materno, ''), '')::TEXT,
    COALESCE(g2.run, '')::TEXT,
    COALESCE(TO_CHAR(g2.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g2.phone, '')::TEXT,
    COALESCE(g2.email, '')::TEXT,
    
    -- Retiro
    COALESCE(TO_CHAR(s.fecha_retiro, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(s.motivo_retiro, '')::TEXT,
    
    -- Condición
    CASE 
      WHEN s.estado_std = 'PRE_MATRICULADO' THEN 'Matrícula en proceso'
      WHEN s.estado_std = 'MATRICULADO' THEN 'Confirmado para año escolar'
      WHEN s.estado_std = 'ACTIVO' THEN 'Cursando'
      WHEN s.estado_std = 'RETIRADO' THEN 'Retirado'
      ELSE COALESCE(s.estado_std, '')
    END::TEXT
    
  FROM public.students s
  -- Vincular con enrollment para filtrar por fecha de matrícula
  INNER JOIN public.enrollment_students es ON s.id = es.student_id
  INNER JOIN public.enrollments e ON es.enrollment_id = e.id
  LEFT JOIN public.cursos c ON s.curso = c.id
  
  -- Apoderado principal (titular o primary)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.guardian_role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND (sg.is_primary = true OR sg.guardian_role = 'titular')
    ORDER BY sg.is_primary DESC NULLS LAST, sg.created_at ASC
    LIMIT 1
  ) g1 ON true
  
  -- Apoderado secundario (suplente)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.guardian_role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND sg.is_primary = false
      AND (sg.guardian_role = 'suplente' OR sg.guardian_role IS NULL)
    ORDER BY sg.created_at ASC
    LIMIT 1
  ) g2 ON true
  
  WHERE 
    (v_year IS NULL OR e.year = v_year OR c.year_academico = v_year)
    AND (v_estado IS NULL OR s.estado_std = v_estado)
    AND (v_status IS NULL OR e.status = v_status)
  
  ORDER BY e.created_at ASC, c.nivel, c.nom_curso, s.apellido_paterno, s.apellido_materno, s.first_name;
END;
$$;

COMMENT ON FUNCTION public.generate_libro_matricula_report IS 
'Genera Libro de Matrícula desde enrollment_students con numeración correlativa. Parámetros: p_year (año, ej: 2026), p_estado (filtro opcional por estado_std), p_enrollment_status (filtro opcional por status de enrollment). Usar todos NULL para traer todos los estudiantes matriculados.';
-- ══════════════════════════════════════════════════════════════════════
-- ✅ MIGRACIONES COMPLETADAS
-- ══════════════════════════════════════════════════════════════════════

-- Verificar migraciones aplicadas
SELECT 
    'Matrículas desde dic 8' as migracion,
    COUNT(DISTINCT e.id) as total
FROM public.enrollments e
WHERE e.created_at >= '2025-12-08'::date

UNION ALL

SELECT 
    'Estudiantes en enrollment_students (dic 8+)' as migracion,
    COUNT(DISTINCT es.student_id) as total
FROM public.enrollment_students es
JOIN public.enrollments e ON es.enrollment_id = e.id
WHERE e.created_at >= '2025-12-08'::date

UNION ALL

SELECT 
    'Función RPC creada' as migracion,
    COUNT(*) as total
FROM pg_proc 
WHERE proname = 'generate_libro_matricula_report';

-- Prueba manual: Ver primeros 5 registros del Libro de Matrícula
-- SELECT * FROM generate_libro_matricula_report(NULL, NULL, NULL) LIMIT 5;
