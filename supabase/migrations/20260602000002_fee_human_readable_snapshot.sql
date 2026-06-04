BEGIN;

ALTER TABLE public.fee
  ADD COLUMN IF NOT EXISTS student_run_text text,
  ADD COLUMN IF NOT EXISTS student_nombre_text text,
  ADD COLUMN IF NOT EXISTS curso_nombre_text text,
  ADD COLUMN IF NOT EXISTS curso_codigo_text text,
  ADD COLUMN IF NOT EXISTS fuente_snapshot_at timestamptz;

CREATE OR REPLACE FUNCTION public.sync_fee_human_readable_snapshot()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_student record;
  v_course record;
BEGIN
  IF NEW.student_id IS NOT NULL THEN
    SELECT
      s.run,
      COALESCE(
        NULLIF(BTRIM(s.whole_name), ''),
        NULLIF(
          BTRIM(
            CONCAT_WS(' ', s.first_name, s.apellido_paterno, s.apellido_materno)
          ),
          ''
        )
      ) AS nombre
    INTO v_student
    FROM public.students s
    WHERE s.id = NEW.student_id;

    NEW.student_run_text := v_student.run;
    NEW.student_nombre_text := v_student.nombre;
  ELSE
    NEW.student_run_text := NULL;
    NEW.student_nombre_text := NULL;
  END IF;

  IF NEW.fee_curso IS NOT NULL THEN
    SELECT
      c.nom_curso,
      c.codigo_curso_matricula
    INTO v_course
    FROM public.cursos c
    WHERE c.id = NEW.fee_curso;

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

DROP TRIGGER IF EXISTS trg_sync_fee_human_readable_snapshot ON public.fee;

CREATE TRIGGER trg_sync_fee_human_readable_snapshot
BEFORE INSERT OR UPDATE OF student_id, fee_curso
ON public.fee
FOR EACH ROW
EXECUTE FUNCTION public.sync_fee_human_readable_snapshot();

UPDATE public.fee f
SET
  student_run_text = x.student_run_text,
  student_nombre_text = x.student_nombre_text,
  curso_nombre_text = x.curso_nombre_text,
  curso_codigo_text = x.curso_codigo_text,
  fuente_snapshot_at = now()
FROM (
  SELECT
    f2.id,
    s.run AS student_run_text,
    COALESCE(
      NULLIF(BTRIM(s.whole_name), ''),
      NULLIF(BTRIM(CONCAT_WS(' ', s.first_name, s.apellido_paterno, s.apellido_materno)), '')
    ) AS student_nombre_text,
    c.nom_curso AS curso_nombre_text,
    c.codigo_curso_matricula AS curso_codigo_text
  FROM public.fee f2
  LEFT JOIN public.students s ON s.id = f2.student_id
  LEFT JOIN public.cursos c ON c.id = f2.fee_curso
) x
WHERE f.id = x.id;

CREATE INDEX IF NOT EXISTS idx_fee_year_course_name
  ON public.fee (year_academico, curso_nombre_text);

CREATE INDEX IF NOT EXISTS idx_fee_student_run_text
  ON public.fee (student_run_text);

COMMENT ON COLUMN public.fee.student_run_text IS
  'Snapshot legible del RUN del estudiante para revision manual en Supabase UI.';
COMMENT ON COLUMN public.fee.student_nombre_text IS
  'Snapshot legible del nombre del estudiante para revision manual en Supabase UI.';
COMMENT ON COLUMN public.fee.curso_nombre_text IS
  'Snapshot legible del nombre del curso para revision manual en Supabase UI.';
COMMENT ON COLUMN public.fee.curso_codigo_text IS
  'Snapshot legible del codigo de curso matricula para revision manual en Supabase UI.';
COMMENT ON COLUMN public.fee.fuente_snapshot_at IS
  'Timestamp de ultima sincronizacion de columnas legibles desde students/cursos.';

COMMIT;
