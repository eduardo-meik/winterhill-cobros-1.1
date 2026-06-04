-- Add student_course_id to guardian intake surveys so we can link cursos directly
ALTER TABLE public.guardian_intake_surveys
  ADD COLUMN IF NOT EXISTS student_course_id uuid REFERENCES public.cursos(id);

CREATE INDEX IF NOT EXISTS idx_guardian_intake_surveys_course_id
  ON public.guardian_intake_surveys(student_course_id);

-- Best-effort backfill by matching existing text values to cursos.nom_curso
WITH normalized AS (
  SELECT gis.id, c.id AS curso_id
  FROM public.guardian_intake_surveys gis
  JOIN public.cursos c
    ON lower(trim(c.nom_curso)) = lower(trim(gis.student_course))
)
UPDATE public.guardian_intake_surveys AS gis
SET student_course_id = normalized.curso_id
FROM normalized
WHERE gis.id = normalized.id AND gis.student_course_id IS NULL;
