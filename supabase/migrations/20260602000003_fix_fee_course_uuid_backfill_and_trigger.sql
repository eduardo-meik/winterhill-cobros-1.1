BEGIN;

CREATE OR REPLACE FUNCTION public.sync_fee_human_readable_snapshot()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_student record;
  v_course record;
  v_resolved_curso_id uuid;
BEGIN
  SELECT
    s.run,
    COALESCE(
      NULLIF(BTRIM(s.whole_name), ''),
      NULLIF(BTRIM(CONCAT_WS(' ', s.first_name, s.apellido_paterno, s.apellido_materno)), '')
    ) AS nombre,
    s.curso AS curso_actual
  INTO v_student
  FROM public.students s
  WHERE s.id = NEW.student_id;

  NEW.student_run_text := v_student.run;
  NEW.student_nombre_text := v_student.nombre;

  v_resolved_curso_id := NEW.fee_curso;

  IF v_resolved_curso_id IS NULL AND NEW.student_id IS NOT NULL THEN
    SELECT sar.curso_id
    INTO v_resolved_curso_id
    FROM public.student_academic_records sar
    WHERE sar.student_id = NEW.student_id
      AND sar.year_academico = COALESCE(NEW.year_academico, NEW.year)
    ORDER BY sar.updated_at DESC NULLS LAST, sar.created_at DESC NULLS LAST
    LIMIT 1;
  END IF;

  IF v_resolved_curso_id IS NULL THEN
    v_resolved_curso_id := v_student.curso_actual;
  END IF;

  NEW.fee_curso := v_resolved_curso_id;

  IF v_resolved_curso_id IS NOT NULL THEN
    SELECT c.nom_curso, c.codigo_curso_matricula
    INTO v_course
    FROM public.cursos c
    WHERE c.id = v_resolved_curso_id;

    NEW.curso_nombre_text := v_course.nom_curso;
    NEW.curso_codigo_text := v_course.codigo_curso_matricula;
  ELSE
    NEW.curso_nombre_text := NULL;
    NEW.curso_codigo_text := NULL;
  END IF;

  NEW.fuente_snapshot_at := now();
  RETURN NEW;
END;
$$;

-- Backfill missing fee.fee_curso UUIDs using year-based academic records first, then current student course.
WITH resolved AS (
  SELECT
    f.id,
    COALESCE(
      f.fee_curso,
      sar.curso_id,
      s.curso
    ) AS resolved_curso_id,
    s.run AS resolved_run,
    COALESCE(
      NULLIF(BTRIM(s.whole_name), ''),
      NULLIF(BTRIM(CONCAT_WS(' ', s.first_name, s.apellido_paterno, s.apellido_materno)), '')
    ) AS resolved_nombre
  FROM public.fee f
  LEFT JOIN public.students s
    ON s.id = f.student_id
  LEFT JOIN LATERAL (
    SELECT sar.curso_id
    FROM public.student_academic_records sar
    WHERE sar.student_id = f.student_id
      AND sar.year_academico = COALESCE(f.year_academico, f.year)
    ORDER BY sar.updated_at DESC NULLS LAST, sar.created_at DESC NULLS LAST
    LIMIT 1
  ) sar ON TRUE
)
UPDATE public.fee f
SET
  fee_curso = r.resolved_curso_id,
  student_run_text = r.resolved_run,
  student_nombre_text = r.resolved_nombre,
  curso_nombre_text = c.nom_curso,
  curso_codigo_text = c.codigo_curso_matricula,
  fuente_snapshot_at = now()
FROM resolved r
LEFT JOIN public.cursos c
  ON c.id = r.resolved_curso_id
WHERE f.id = r.id;

COMMIT;
