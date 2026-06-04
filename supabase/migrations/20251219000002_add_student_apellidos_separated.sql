-- Add apellido_paterno and apellido_materno to students table
-- Date: 2025-12-19

BEGIN;

-- Add apellido_paterno and apellido_materno fields
ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

-- Add helpful comments
COMMENT ON COLUMN public.students.apellido_paterno IS 'Apellido paterno del estudiante';
COMMENT ON COLUMN public.students.apellido_materno IS 'Apellido materno del estudiante';

COMMIT;
