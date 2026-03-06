-- ============================================================================
-- BACKFILL student_academic_records FROM enrollment data
-- MP-01: Poblar tabla student_academic_records desde enrollments existentes
-- ============================================================================
-- This script populates student_academic_records from finalized enrollments
-- that were processed before the trigger was added to finalize_enrollment().
--
-- Safe to run multiple times (uses ON CONFLICT DO UPDATE).
-- ============================================================================

BEGIN;

-- Backfill from enrollment_students joined with enrollments
INSERT INTO public.student_academic_records (
  student_id,
  curso_id,
  year_academico,
  fecha_inicio,
  estado,
  enrollment_id,
  created_at
)
SELECT
  es.student_id,
  s.curso AS curso_id,
  e.year AS year_academico,
  e.created_at::date AS fecha_inicio,
  'activo' AS estado,
  e.id AS enrollment_id,
  e.created_at
FROM public.enrollment_students es
JOIN public.enrollments e ON e.id = es.enrollment_id
JOIN public.students s ON s.id = es.student_id
WHERE e.status = 'completed'
  AND s.curso IS NOT NULL
  AND e.year IS NOT NULL
ON CONFLICT (student_id, year_academico) DO UPDATE
  SET curso_id = EXCLUDED.curso_id,
      enrollment_id = EXCLUDED.enrollment_id,
      fecha_inicio = COALESCE(student_academic_records.fecha_inicio, EXCLUDED.fecha_inicio),
      updated_at = now();

-- Report results
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.student_academic_records;
  RAISE NOTICE 'student_academic_records now has % rows', v_count;
END $$;

COMMIT;
