-- Fix generate_libro_matricula_report function to handle empty strings in year field
-- Date: 2025-12-19

-- STEP 1: Clean up bad data in enrollments.year
-- Handle NULL, 0, and potentially empty strings if year is text/varchar
DO $$
BEGIN
  -- Try to update assuming year is integer
  UPDATE public.enrollments
  SET year = EXTRACT(YEAR FROM created_at)::INTEGER
  WHERE year IS NULL OR year = 0;
EXCEPTION
  WHEN OTHERS THEN
    -- If year is text/varchar type, handle empty strings
    EXECUTE 'UPDATE public.enrollments SET year = EXTRACT(YEAR FROM created_at)::INTEGER WHERE year IS NULL OR year::text = '''' OR year::text = ''0''';
END $$;

-- STEP 2: Drop old function versions
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR);

CREATE OR REPLACE FUNCTION public.generate_libro_matricula_report(
  p_year INTEGER DEFAULT NULL,
  p_estado VARCHAR DEFAULT NULL,
  p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  numero_correlativo BIGINT,
  year_matricula INTEGER,
  fecha_matricula TIMESTAMPTZ,
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
  -- Sanitize parameters
  v_year := NULLIF(p_year, 0);
  v_estado := NULLIF(TRIM(p_estado), '');
  v_status := NULLIF(TRIM(p_status), '');

  RETURN QUERY
  SELECT
    -- Numeración y fecha de matrícula
    ROW_NUMBER() OVER (ORDER BY e.created_at ASC)::BIGINT,
    COALESCE(
      CASE WHEN e.year IS NOT NULL AND e.year > 0 THEN e.year 
           ELSE EXTRACT(YEAR FROM e.created_at)::INTEGER 
      END,
      EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER
    ),
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
    (v_year IS NULL OR e.year = v_year OR (c.year_academico IS NOT NULL AND c.year_academico = v_year))
    AND (v_estado IS NULL OR s.estado_std = v_estado)
    AND (v_status IS NULL OR e.status = v_status)
  
  ORDER BY e.created_at ASC, c.nivel, c.nom_curso, s.apellido_paterno, s.apellido_materno, s.first_name;
END;
$$;

COMMENT ON FUNCTION public.generate_libro_matricula_report IS 
'Genera reporte completo del Libro de Matrícula con datos de estudiantes, apoderados titular y suplente. 
Filtros: 
- p_year (año académico)
- p_estado (PRE_MATRICULADO, MATRICULADO, ACTIVO, RETIRADO)
- p_status (draft, pending, completed, rejected)
Retorna numeración correlativa, año de matrícula, y fecha de matrícula además de todos los datos del estudiante.';
