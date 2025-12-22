-- Create RPC function to generate Libro de Matrícula report
-- Date: 2025-12-19

CREATE OR REPLACE FUNCTION public.generate_libro_matricula_report(
  p_year INTEGER DEFAULT NULL,
  p_estado VARCHAR DEFAULT NULL
)
RETURNS TABLE (
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
BEGIN
  RETURN QUERY
  SELECT
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
  LEFT JOIN public.cursos c ON s.curso = c.id
  
  -- Apoderado principal (titular o primary)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND (sg.is_primary = true OR sg.role = 'titular')
    ORDER BY sg.is_primary DESC NULLS LAST, sg.created_at ASC
    LIMIT 1
  ) g1 ON true
  
  -- Apoderado secundario (suplente)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND sg.is_primary = false
      AND (sg.role = 'suplente' OR sg.role IS NULL)
    ORDER BY sg.created_at ASC
    LIMIT 1
  ) g2 ON true
  
  WHERE 
    (p_year IS NULL OR c.year_academico = p_year)
    AND (p_estado IS NULL OR s.estado_std = p_estado)
  
  ORDER BY c.nivel, c.nom_curso, s.apellido_paterno, s.apellido_materno, s.first_name;
END;
$$;

COMMENT ON FUNCTION public.generate_libro_matricula_report IS 
'Genera reporte completo del Libro de Matrícula con datos de estudiantes, apoderados titular y suplente. Filtros: p_year (año académico), p_estado (PRE_MATRICULADO, MATRICULADO, ACTIVO, RETIRADO)';
