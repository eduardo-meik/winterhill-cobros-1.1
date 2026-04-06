BEGIN;

-- Regularizacion administrativa de casos Aranceles 2026
-- Fecha: 2026-04-06
-- Alcance:
-- 1) AYUN CEPEDA FOXON: anular deuda 2026 y cancelar matricula 2026, porque no debe quedar matriculado.
-- 2) LETICIA COLOMBA ALARCON HUERTA: asegurar plan 2026 completo de 10 cuotas si faltara alguna.
-- 3) SANTIAGO AMARO ALARCON HUERTA: asegurar plan 2026 completo de 10 cuotas si faltara alguna.
-- 4) SANTIAGO MATTIA PAZ: excluido expresamente, porque hoy si tiene plan 2026 completo.

-- ==============================
-- Pre-validacion
-- ==============================
SELECT
  s.id,
  s.whole_name,
  s.run,
  s.estado_std,
  s.fecha_retiro,
  s.motivo_retiro,
  e.id AS enrollment_id,
  e.year AS enrollment_year,
  e.status AS enrollment_status,
  COUNT(f.id) FILTER (WHERE f.year_academico = 2026) AS fee_rows_2026,
  COALESCE(SUM(f.amount) FILTER (WHERE f.year_academico = 2026 AND f.status IN ('pending', 'overdue', 'partial')), 0) AS pending_amount_2026
FROM public.students s
LEFT JOIN public.enrollment_students es
  ON es.student_id = s.id
LEFT JOIN public.enrollments e
  ON e.id = es.enrollment_id
LEFT JOIN public.fee f
  ON f.student_id = s.id
WHERE s.id IN (
  '1d36e401-4922-47d9-8951-d063e423c6d5',
  '0caa2000-14bd-4e39-8e85-51bc254c51f9',
  '54ccf79e-f3e8-48c3-bdef-177f1e57d1b4',
  '8b3e7d87-6755-447e-a893-ce158df21115'
)
GROUP BY s.id, s.whole_name, s.run, s.estado_std, s.fecha_retiro, s.motivo_retiro, e.id, e.year, e.status
ORDER BY s.whole_name;

-- ==============================
-- Caso 1: AYUN CEPEDA FOXON
-- ==============================
-- Decisiones de regularizacion:
-- - Mantener estado RETIRADO en students.
-- - Completar fecha/motivo de retiro si no existen.
-- - Cancelar cuotas 2026 pendientes/vencidas/parciales.
-- - Cancelar la matricula 2026 asociada.

UPDATE public.fee
SET status = 'cancelled',
    updated_at = now(),
    notes = concat_ws(
      ' | ',
      NULLIF(notes, ''),
      '[REG 2026-04-06] Deuda 2026 anulada: alumno no matriculado para 2026'
    ),
    meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object(
      'regularization_source', 'sql/regularize_aranceles_cases_20260406.sql',
      'regularization_date', '2026-04-06',
      'regularization_action', 'cancel_fee_due_to_not_enrolled_2026'
    )
WHERE student_id = '1d36e401-4922-47d9-8951-d063e423c6d5'
  AND year_academico = 2026
  AND status IN ('pending', 'overdue', 'partial');

UPDATE public.enrollments
SET status = 'cancelled',
    updated_at = now(),
    meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object(
      'regularization_source', 'sql/regularize_aranceles_cases_20260406.sql',
      'regularization_date', '2026-04-06',
      'regularization_action', 'cancel_enrollment_due_to_not_enrolled_2026'
    )
WHERE id = '59d9c8b8-32db-482d-9304-72652f943931'
  AND COALESCE(status, '') <> 'cancelled';

UPDATE public.students
SET estado_std = 'RETIRADO',
    fecha_retiro = COALESCE(fecha_retiro, CURRENT_DATE),
    motivo_retiro = COALESCE(
      NULLIF(motivo_retiro, ''),
      'Regularizacion administrativa 2026: matricula anulada y deuda 2026 cancelada'
    ),
    updated_at = now()
WHERE id = '1d36e401-4922-47d9-8951-d063e423c6d5';

-- ==============================
-- Casos 2 y 3: Alarcon Huerta
-- ==============================
-- Hoy ambos ya muestran 10 cuotas 2026 generadas por una reparacion previa.
-- Esta seccion es idempotente: solo inserta cuotas faltantes, no modifica las existentes.

WITH target_students AS (
  SELECT *
  FROM (
    VALUES
      (
        '0caa2000-14bd-4e39-8e85-51bc254c51f9'::uuid,
        'LETICIA COLOMBA ALARCON HUERTA'::text,
        '784c4915-5cb7-47f9-a5fe-d78646a62411'::uuid,
        'b4e4e966-b4ca-4639-a565-7e254c6df4b7'::uuid,
        'bd72b98b-e2e7-43a1-a225-21c0fbbbf918'::uuid,
        41148.00::numeric,
        'PAGARE'::text
      ),
      (
        '54ccf79e-f3e8-48c3-bdef-177f1e57d1b4'::uuid,
        'SANTIAGO AMARO ALARCON HUERTA'::text,
        '784c4915-5cb7-47f9-a5fe-d78646a62411'::uuid,
        'b4e4e966-b4ca-4639-a565-7e254c6df4b7'::uuid,
        'bd72b98b-e2e7-43a1-a225-21c0fbbbf918'::uuid,
        41148.00::numeric,
        'PAGARE'::text
      )
  ) AS t(student_id, student_name, enrollment_id, guardian_id, owner_id, cuota_amount, payment_method)
), cuotas AS (
  SELECT
    gs AS numero_cuota,
    (DATE '2026-03-05' + make_interval(months => gs - 1))::date AS due_date
  FROM generate_series(1, 10) AS gs
)
INSERT INTO public.fee (
  student_id,
  guardian_id,
  amount,
  due_date,
  status,
  payment_method,
  owner_id,
  year_academico,
  numero_cuota,
  enrollment_id,
  meta,
  notes,
  year
)
SELECT
  ts.student_id,
  ts.guardian_id,
  ts.cuota_amount,
  c.due_date,
  'pending',
  ts.payment_method,
  ts.owner_id,
  2026,
  c.numero_cuota,
  ts.enrollment_id,
  jsonb_build_object(
    'source', 'sql_regularizacion_20260406',
    'sync_reason', 'ensure_alarcon_2026_plan_complete',
    'student_name', ts.student_name
  ),
  '[REG 2026-04-06] Cuota regenerada para completar plan 2026',
  2026
FROM target_students ts
CROSS JOIN cuotas c
WHERE NOT EXISTS (
  SELECT 1
  FROM public.fee f
  WHERE f.student_id = ts.student_id
    AND f.year_academico = 2026
    AND f.numero_cuota = c.numero_cuota
);

-- ==============================
-- Post-validacion
-- ==============================
SELECT
  s.whole_name,
  s.estado_std,
  e.status AS enrollment_status,
  f.year_academico,
  f.status,
  COUNT(*) AS fee_rows,
  COALESCE(SUM(f.amount), 0) AS total_amount
FROM public.students s
JOIN public.fee f
  ON f.student_id = s.id
LEFT JOIN public.enrollment_students es
  ON es.student_id = s.id
LEFT JOIN public.enrollments e
  ON e.id = es.enrollment_id
 AND e.year = 2026
WHERE s.id IN (
  '1d36e401-4922-47d9-8951-d063e423c6d5',
  '0caa2000-14bd-4e39-8e85-51bc254c51f9',
  '54ccf79e-f3e8-48c3-bdef-177f1e57d1b4'
)
  AND f.year_academico = 2026
GROUP BY s.whole_name, s.estado_std, e.status, f.year_academico, f.status
ORDER BY s.whole_name, f.status;

COMMIT;