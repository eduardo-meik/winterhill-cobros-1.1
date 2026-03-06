-- Add PRE_MATRICULADO state to students.estado_std
-- Date: 2025-12-19
-- 
-- Flow:
--   Estudiante Nuevo (dic 8+)
--     ↓
--   [Proceso de matrícula completado]
--     ↓
--   Estado: PRE_MATRICULADO
--     ↓
--   [Inicio año escolar - MARZO más cercano]
--     ↓
--   Estado: MATRICULADO
--     ↓
--   [Durante año escolar]
--     ↓
--   Estado: ACTIVO

BEGIN;

-- Step 1: Drop existing constraint
ALTER TABLE public.students
  DROP CONSTRAINT IF EXISTS students_estado_std_check;

-- Step 2: Add new constraint with PRE_MATRICULADO
ALTER TABLE public.students
  ADD CONSTRAINT students_estado_std_check
  CHECK (estado_std IN ('ACTIVO','RETIRADO','MATRICULADO','PRE_MATRICULADO'));

-- Step 3: Update all students created from Dec 8, 2025 onwards to PRE_MATRICULADO
-- (Only if they are currently MATRICULADO or ACTIVO, preserve RETIRADO)
UPDATE public.students
SET estado_std = 'PRE_MATRICULADO'
WHERE created_at >= '2025-12-08'::date
  AND estado_std IN ('MATRICULADO', 'ACTIVO');

-- Step 4: Add helpful comment
COMMENT ON COLUMN public.students.estado_std IS 
'Estado del estudiante: PRE_MATRICULADO (matrícula en proceso desde dic 8+), MATRICULADO (confirmado para inicio año escolar en marzo), ACTIVO (cursando), RETIRADO (dado de baja)';

-- Step 5: Verification query (optional, for manual review)
-- SELECT estado_std, COUNT(*) as cantidad, MIN(created_at) as primer_registro, MAX(created_at) as ultimo_registro
-- FROM public.students
-- GROUP BY estado_std
-- ORDER BY estado_std;

COMMIT;
