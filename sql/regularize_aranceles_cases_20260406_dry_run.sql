-- DRY RUN - Regularizacion administrativa de casos Aranceles 2026
-- Fecha: 2026-04-06
-- Este script NO modifica datos. Solo informa el impacto esperado.

-- ============================================================
-- Resumen general por caso
-- ============================================================
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
  COUNT(f.id) FILTER (WHERE f.year_academico = 2026 AND f.status IN ('pending', 'overdue', 'partial')) AS fee_rows_2026_open,
  COALESCE(SUM(f.amount) FILTER (WHERE f.year_academico = 2026 AND f.status IN ('pending', 'overdue', 'partial')), 0) AS fee_open_amount_2026
FROM public.students s
LEFT JOIN public.enrollment_students es
  ON es.student_id = s.id
LEFT JOIN public.enrollments e
  ON e.id = es.enrollment_id
 AND e.year = 2026
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

-- ============================================================
-- Caso AYUN CEPEDA FOXON
-- Impacto esperado de la regularizacion:
-- - Cancelar cuotas 2026 abiertas
-- - Cancelar matricula 2026
-- - Completar fecha/motivo de retiro si faltan
-- ============================================================

SELECT
  'AYUN_FEES_TO_CANCEL' AS action,
  f.id AS fee_id,
  s.whole_name,
  f.numero_cuota,
  f.amount,
  f.status,
  f.due_date,
  f.enrollment_id,
  f.meta
FROM public.fee f
JOIN public.students s
  ON s.id = f.student_id
WHERE f.student_id = '1d36e401-4922-47d9-8951-d063e423c6d5'
  AND f.year_academico = 2026
  AND f.status IN ('pending', 'overdue', 'partial')
ORDER BY f.numero_cuota;

SELECT
  'AYUN_ENROLLMENT_TO_CANCEL' AS action,
  e.id AS enrollment_id,
  e.year,
  e.status,
  e.updated_at,
  e.meta
FROM public.enrollments e
WHERE e.id = '59d9c8b8-32db-482d-9304-72652f943931';

SELECT
  'AYUN_STUDENT_STATUS_AFTER' AS action,
  s.id,
  s.whole_name,
  s.estado_std AS current_estado_std,
  'RETIRADO'::text AS target_estado_std,
  s.fecha_retiro AS current_fecha_retiro,
  COALESCE(s.fecha_retiro, CURRENT_DATE) AS target_fecha_retiro,
  s.motivo_retiro AS current_motivo_retiro,
  COALESCE(NULLIF(s.motivo_retiro, ''), 'Regularizacion administrativa 2026: matricula anulada y deuda 2026 cancelada') AS target_motivo_retiro
FROM public.students s
WHERE s.id = '1d36e401-4922-47d9-8951-d063e423c6d5';

-- ============================================================
-- Casos Alarcon Huerta
-- Impacto esperado de la regularizacion:
-- - Insertar solo cuotas 2026 faltantes
-- - No tocar cuotas 2026 ya existentes
-- ============================================================

WITH target_students AS (
  SELECT *
  FROM (
    VALUES
      (
        '0caa2000-14bd-4e39-8e85-51bc254c51f9'::uuid,
        'LETICIA COLOMBA ALARCON HUERTA'::text,
        '784c4915-5cb7-47f9-a5fe-d78646a62411'::uuid,
        41148.00::numeric,
        'PAGARE'::text
      ),
      (
        '54ccf79e-f3e8-48c3-bdef-177f1e57d1b4'::uuid,
        'SANTIAGO AMARO ALARCON HUERTA'::text,
        '784c4915-5cb7-47f9-a5fe-d78646a62411'::uuid,
        41148.00::numeric,
        'PAGARE'::text
      )
  ) AS t(student_id, student_name, enrollment_id, cuota_amount, payment_method)
), cuotas AS (
  SELECT
    gs AS numero_cuota,
    (DATE '2026-03-05' + make_interval(months => gs - 1))::date AS due_date
  FROM generate_series(1, 10) AS gs
)
SELECT
  CASE
    WHEN f.id IS NULL THEN 'ALARCON_FEE_MISSING'
    ELSE 'ALARCON_FEE_ALREADY_EXISTS'
  END AS action,
  ts.student_name,
  ts.student_id,
  c.numero_cuota,
  c.due_date,
  ts.cuota_amount AS target_amount,
  ts.payment_method AS target_payment_method,
  f.id AS existing_fee_id,
  f.status AS existing_status,
  f.amount AS existing_amount,
  f.meta AS existing_meta
FROM target_students ts
CROSS JOIN cuotas c
LEFT JOIN public.fee f
  ON f.student_id = ts.student_id
 AND f.year_academico = 2026
 AND f.numero_cuota = c.numero_cuota
ORDER BY ts.student_name, c.numero_cuota;

-- ============================================================
-- Caso SANTIAGO MATTIA PAZ
-- Solo validacion: no deberia entrar a regularizacion.
-- ============================================================

SELECT
  'SANTIAGO_MATTIA_VALIDATION' AS action,
  s.id,
  s.whole_name,
  s.estado_std,
  e.id AS enrollment_id,
  e.status AS enrollment_status,
  COUNT(f.id) FILTER (WHERE f.year_academico = 2026) AS fee_rows_2026,
  COALESCE(SUM(f.amount) FILTER (WHERE f.year_academico = 2026), 0) AS fee_total_2026
FROM public.students s
LEFT JOIN public.enrollment_students es
  ON es.student_id = s.id
LEFT JOIN public.enrollments e
  ON e.id = es.enrollment_id
 AND e.year = 2026
LEFT JOIN public.fee f
  ON f.student_id = s.id
WHERE s.id = '8b3e7d87-6755-447e-a893-ce158df21115'
GROUP BY s.id, s.whole_name, s.estado_std, e.id, e.status;