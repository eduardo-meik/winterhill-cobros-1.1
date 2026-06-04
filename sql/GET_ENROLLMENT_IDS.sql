-- Query para obtener los IDs de matrículas recientes
-- Copia uno de estos IDs y úsalo en DIAGNOSE_400_ERROR.sql

SELECT 
  e.id,
  e.year_academico as year,
  e.status,
  TRIM(CONCAT_WS(' ', g.first_name, g.last_name)) as guardian,
  g.run as guardian_run,
  COUNT(es.student_id) as num_students,
  e.created_at,
  e.updated_at
FROM public.enrollments e
JOIN public.guardians g ON g.id = e.guardian_id
LEFT JOIN public.enrollment_students es ON es.enrollment_id = e.id
GROUP BY e.id, e.year_academico, e.status, TRIM(CONCAT_WS(' ', g.first_name, g.last_name)), g.run, e.created_at, e.updated_at
ORDER BY e.created_at DESC
LIMIT 20;
