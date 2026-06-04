-- Expose human-readable course name for fee rows without breaking FK integrity.
-- fee.fee_curso (uuid) remains untouched in base table.

BEGIN;

CREATE OR REPLACE VIEW public.v_fee_course WITH (security_invoker = true) AS
SELECT
  f.id,
  f.created_at,
  f.updated_at,
  f.student_id,
  f.guardian_id,
  f.amount,
  f.due_date,
  f.payment_date,
  f.status,
  f.payment_method,
  f.num_boleta,
  f.mov_bancario,
  f.notes,
  f.owner_id,
  c.nom_curso::text AS fee_curso,
  f.fee_curso AS fee_curso_id,
  f.numero_cuota,
  f.institucion_financiera,
  f.year_academico,
  f.enrollment_id,
  f.meta,
  f.year,
  f.es_beca
FROM public.fee f
LEFT JOIN public.cursos c ON c.id = f.fee_curso;

COMMENT ON VIEW public.v_fee_course IS
  'Read-only projection of fee with fee_curso as cursos.nom_curso and fee_curso_id preserving the original UUID.';

GRANT SELECT ON public.v_fee_course TO anon, authenticated, service_role;

COMMIT;
