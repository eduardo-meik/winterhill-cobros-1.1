-- P1 & P2 - MatriculaWizard helpers
-- Fecha: 2025-12-03
-- Objetivo:
--   P1: Exponer RPC para obtener cursos del año académico corriente.
--   P2: Exponer RPC base para obtener el último curso del estudiante
--       y un curso sugerido de promoción para el año actual.

-- -------------------------------------------------------------------
-- P1: RPC get_current_year_cursos()
-- -------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_current_year_cursos()
RETURNS SETOF public.cursos
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT c.*
  FROM public.cursos c
  WHERE c.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)::int
  ORDER BY c.nivel NULLS LAST, c.letra_curso NULLS LAST, c.nom_curso NULLS LAST;
$$;

COMMENT ON FUNCTION public.get_current_year_cursos() IS
'Devuelve todos los cursos del año académico corriente (year_academico = año actual). Pensado para MatriculaWizard.';

GRANT EXECUTE ON FUNCTION public.get_current_year_cursos() TO anon, authenticated, service_role;


-- -------------------------------------------------------------------
-- P2: RPC get_student_promotion_suggestion(student_id uuid)
-- -------------------------------------------------------------------
-- Nota: Esta función NO aplica todavía todas las reglas complejas de
-- promoción (por ejemplo 8° Básica -> I Medio). Solo entrega un
-- esqueleto seguro y coherente con el esquema para que frontend pueda
-- comenzar a integrar la funcionalidad.

CREATE OR REPLACE FUNCTION public.get_student_promotion_suggestion(p_student_id uuid)
RETURNS TABLE (
  current_course_id uuid,
  current_year int4,
  suggested_course_id uuid,
  suggested_year int4
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_year int4 := EXTRACT(YEAR FROM CURRENT_DATE)::int4;
BEGIN
  -- Último curso del estudiante según registros académicos
  RETURN QUERY
  WITH last_record AS (
    SELECT sar.curso_id,
           sar.year_academico
    FROM public.student_academic_records sar
    WHERE sar.student_id = p_student_id
    ORDER BY sar.year_academico DESC
    LIMIT 1
  )
  SELECT
    lr.curso_id AS current_course_id,
    lr.year_academico AS current_year,
    NULL::uuid AS suggested_course_id,
    v_current_year AS suggested_year
  FROM last_record lr;

  -- Nota: En una iteración posterior se puede reemplazar el NULL de
  -- suggested_course_id por la lógica real de promoción usando
  -- public.cursos (por ejemplo, mapa 2° -> 3°, etc.).
END;
$$;

COMMENT ON FUNCTION public.get_student_promotion_suggestion(uuid) IS
'Devuelve el último curso conocido del estudiante y el año académico actual como destino. La lógica de promoción de curso se añadirá en una fase posterior.';

GRANT EXECUTE ON FUNCTION public.get_student_promotion_suggestion(uuid) TO anon, authenticated, service_role;
