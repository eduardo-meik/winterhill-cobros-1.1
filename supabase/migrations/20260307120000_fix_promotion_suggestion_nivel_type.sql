-- Fix: get_student_promotion_suggestion used string comparisons on nivel
-- (e.g. WHEN 'PRE-KINDER', '1B') but nivel column is integer (110, 310).
-- Rewritten to parse nom_curso (e.g. "3° BASICO A") for grade progression.

CREATE OR REPLACE FUNCTION public.get_student_promotion_suggestion(p_student_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_current_curso RECORD;
  v_next_curso RECORD;
  v_current_year int;
  v_next_year int;
  v_next_nom_curso text;
  v_grade int;
  v_category text;  -- BASICO or MEDIO
  v_letra text;
BEGIN
  v_current_year := EXTRACT(YEAR FROM CURRENT_DATE)::int;
  v_next_year := v_current_year + 1;

  -- Get the student's current curso
  SELECT c.id, c.nom_curso, c.nivel, c.letra_curso, c.year_academico
    INTO v_current_curso
    FROM public.students s
    JOIN public.cursos c ON c.id = s.curso
   WHERE s.id = p_student_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'suggestion', NULL,
      'reason', 'Student has no current curso assigned'
    );
  END IF;

  -- Parse nom_curso: e.g. "3° BASICO A" → grade=3, category=BASICO, letra=A
  v_grade    := (regexp_match(v_current_curso.nom_curso, '^(\d+)°'))[1]::int;
  v_category := (regexp_match(v_current_curso.nom_curso, '° (\w+)'))[1];
  v_letra    := COALESCE(v_current_curso.letra_curso,
                  (regexp_match(v_current_curso.nom_curso, '\s([A-Z])$'))[1]);

  IF v_grade IS NULL OR v_category IS NULL THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'current_curso', jsonb_build_object(
        'id', v_current_curso.id,
        'nom_curso', v_current_curso.nom_curso,
        'nivel', v_current_curso.nivel,
        'year', v_current_curso.year_academico
      ),
      'suggestion', NULL,
      'reason', format('Cannot parse nom_curso: %s', v_current_curso.nom_curso)
    );
  END IF;

  -- Determine next course name
  IF v_category = 'BASICO' AND v_grade < 8 THEN
    v_next_nom_curso := format('%s° BASICO %s', v_grade + 1, v_letra);
  ELSIF v_category = 'BASICO' AND v_grade = 8 THEN
    v_next_nom_curso := format('1° MEDIO %s', v_letra);
  ELSIF v_category = 'MEDIO' AND v_grade < 4 THEN
    v_next_nom_curso := format('%s° MEDIO %s', v_grade + 1, v_letra);
  ELSIF v_category = 'MEDIO' AND v_grade = 4 THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'current_curso', jsonb_build_object(
        'id', v_current_curso.id,
        'nom_curso', v_current_curso.nom_curso,
        'nivel', v_current_curso.nivel,
        'year', v_current_curso.year_academico
      ),
      'suggestion', NULL,
      'reason', 'Student is in final year (4° MEDIO) — graduating'
    );
  ELSE
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'current_curso', jsonb_build_object(
        'id', v_current_curso.id,
        'nom_curso', v_current_curso.nom_curso,
        'nivel', v_current_curso.nivel,
        'year', v_current_curso.year_academico
      ),
      'suggestion', NULL,
      'reason', format('Unrecognized course pattern: %s', v_current_curso.nom_curso)
    );
  END IF;

  -- Find the next curso in the next academic year
  SELECT c.id, c.nom_curso, c.nivel, c.year_academico
    INTO v_next_curso
    FROM public.cursos c
   WHERE c.year_academico = v_next_year
     AND c.nom_curso = v_next_nom_curso
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'student_id', p_student_id,
      'current_curso', jsonb_build_object(
        'id', v_current_curso.id,
        'nom_curso', v_current_curso.nom_curso,
        'nivel', v_current_curso.nivel,
        'year', v_current_curso.year_academico
      ),
      'suggestion', NULL,
      'reason', format('No curso found for %s in year %s', v_next_nom_curso, v_next_year)
    );
  END IF;

  RETURN jsonb_build_object(
    'student_id', p_student_id,
    'current_curso', jsonb_build_object(
      'id', v_current_curso.id,
      'nom_curso', v_current_curso.nom_curso,
      'nivel', v_current_curso.nivel,
      'year', v_current_curso.year_academico
    ),
    'suggestion', jsonb_build_object(
      'id', v_next_curso.id,
      'nom_curso', v_next_curso.nom_curso,
      'nivel', v_next_curso.nivel,
      'year', v_next_curso.year_academico
    ),
    'reason', 'Promotion suggested based on level sequence'
  );
END;
$function$;
