-- Add MATRICULADO status for students
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'students' AND column_name = 'estado_std'
  ) THEN
    ALTER TABLE public.students
      ADD COLUMN estado_std text DEFAULT 'ACTIVO';
  END IF;
END$$;

ALTER TABLE public.students
  DROP CONSTRAINT IF EXISTS students_estado_std_check;

ALTER TABLE public.students
  ADD CONSTRAINT students_estado_std_check
  CHECK (estado_std IN ('ACTIVO','RETIRADO','MATRICULADO'));

CREATE INDEX IF NOT EXISTS idx_students_estado_std ON public.students(estado_std);
