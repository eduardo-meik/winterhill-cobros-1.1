BEGIN;

WITH student_year_with_multiple_fees AS (
  SELECT
    student_id,
    year_academico
  FROM public.fee
  GROUP BY student_id, year_academico
  HAVING COUNT(*) > 1
)
UPDATE public.fee f
SET
  amount = 133126,
  updated_at = now()
FROM student_year_with_multiple_fees g
WHERE f.student_id = g.student_id
  AND f.year_academico IS NOT DISTINCT FROM g.year_academico
  AND f.amount = 1331260;

COMMIT;
