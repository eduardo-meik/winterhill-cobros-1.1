-- ============================================================================
-- LIBRO DE MATRÍCULA - FIX DEFINITIVO
-- Fecha: 22 diciembre 2025
-- ============================================================================
-- Fix: Evitar CUALQUIER cast de "" a integer en todos los paths
-- - p_year TEXT con parse regex
-- - c.year_academico comparado como texto (sin cast a int)
-- - WHERE sin casts que puedan explotar
-- ============================================================================

-- 1) BORRAR FUNCIÓN VIEJA (si existe con firma integer)
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(integer, character varying, character varying);

-- 2) CREAR FUNCIÓN NUEVA (100% blindada contra 22P02)
CREATE OR REPLACE FUNCTION public.generate_libro_matricula_report(
  p_year TEXT DEFAULT NULL,
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
  -- p_year llega como texto: convertir solo si es año válido YYYY
  v_year := CASE
    WHEN p_year IS NULL THEN NULL
    WHEN btrim(p_year) ~ '^[0-9]{4}$' THEN btrim(p_year)::int
    ELSE NULL
  END;

  v_estado := NULLIF(TRIM(COALESCE(p_estado, '')), '');
  v_status := NULLIF(TRIM(COALESCE(p_enrollment_status, '')), '');

  RETURN QUERY
  SELECT
    -- Numeración correlativa por orden de matrícula
    ROW_NUMBER() OVER (ORDER BY e.created_at ASC)::BIGINT,
    COALESCE(e.year, EXTRACT(YEAR FROM e.created_at)::INTEGER)::INTEGER,
    e.created_at,
    
    -- Curso (nivel convertido a texto descriptivo para separar Básica/Media)
    CASE 
      WHEN c.nivel BETWEEN 100 AND 199 THEN 'Enseñanza Básica'
      WHEN c.nivel BETWEEN 300 AND 399 THEN 'Enseñanza Media'
      ELSE COALESCE(c.nivel::text, '')
    END::TEXT AS nivel,
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

    -- Condición/Estado
    CASE
      WHEN s.estado_std = 'PRE_MATRICULADO' THEN 'Matrícula en proceso'
      WHEN s.estado_std = 'MATRICULADO' THEN 'Confirmado para año escolar'
      WHEN s.estado_std = 'ACTIVO' THEN 'Cursando'
      WHEN s.estado_std = 'RETIRADO' THEN 'Retirado'
      ELSE COALESCE(s.estado_std, '')
    END::TEXT

  FROM public.students s
  INNER JOIN public.enrollment_students es ON s.id = es.student_id
  INNER JOIN public.enrollments e ON es.enrollment_id = e.id
  LEFT JOIN public.cursos c ON s.curso = c.id
  
  -- Apoderado principal (titular o primary)
  LEFT JOIN LATERAL (
    SELECT 
      g.first_name,
      g.last_name AS apellido_paterno,
      ''::text AS apellido_materno,
      g.relationship_type,
      g.date_of_birth,
      g.run,
      g.nivel_educacional,
      g.address,
      g.comuna,
      g.email,
      g.phone,
      sg.guardian_role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND (sg.is_primary = true OR sg.guardian_role = 'titular')
    ORDER BY sg.is_primary DESC NULLS LAST, sg.created_at ASC
    LIMIT 1
  ) g1 ON true
  
  -- Apoderado secundario (suplente)
  LEFT JOIN LATERAL (
    SELECT 
      g.first_name,
      g.last_name AS apellido_paterno,
      ''::text AS apellido_materno,
      g.date_of_birth,
      g.run,
      g.phone,
      g.email,
      sg.guardian_role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND sg.is_primary = false
      AND (sg.guardian_role = 'suplente' OR sg.guardian_role IS NULL)
    ORDER BY sg.created_at ASC
    LIMIT 1
  ) g2 ON true
  
  WHERE
    -- FIX CRÍTICO: comparar year_academico como TEXT (sin cast a int)
    -- para evitar 22P02 con valores vacíos o inválidos
    (
      v_year IS NULL
      OR e.year = v_year
      OR NULLIF(btrim(c.year_academico::text), '') = v_year::text
    )
    AND (v_estado IS NULL OR s.estado_std = v_estado)
    AND (v_status IS NULL OR e.status = v_status)
  
  ORDER BY e.created_at ASC, c.nivel, c.nom_curso, s.apellido_paterno, s.apellido_materno, s.first_name;
END;
$$;

COMMENT ON FUNCTION public.generate_libro_matricula_report IS 
'Genera Libro de Matrícula con numeración correlativa por fecha de matrícula.
Parámetros: p_year (año como texto, ej: ''2026''), p_estado (estado estudiante), p_enrollment_status (estado enrollment).
Todos opcionales - usar NULL para traer todos los registros.';

-- ============================================================================
-- PRUEBAS
-- ============================================================================

-- Prueba 1: Traer todos los registros (sin filtros)
SELECT * FROM public.generate_libro_matricula_report(NULL, NULL, NULL) LIMIT 5;

-- Prueba 2: Filtrar por año 2026
SELECT * FROM public.generate_libro_matricula_report('2026', NULL, NULL) LIMIT 5;

-- Prueba 3: String vacío (debería funcionar sin error)
SELECT * FROM public.generate_libro_matricula_report('', NULL, NULL) LIMIT 5;

-- Prueba 4: Contar por nivel
SELECT 
  nivel,
  COUNT(*) as total
FROM public.generate_libro_matricula_report(NULL, NULL, NULL)
GROUP BY nivel;

-- ============================================================================
-- DIAGNÓSTICO: Verificar cursos con year_academico problemático
-- ============================================================================
SELECT
  'Cursos con year_academico vacío o NULL' as diagnostico,
  COUNT(*) AS total
FROM public.cursos
WHERE NULLIF(btrim(year_academico::text), '') IS NULL;
