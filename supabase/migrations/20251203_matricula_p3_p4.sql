-- P3 & P4 - Plan de pagos y cheques
-- Fecha: 2025-12-03
-- Objetivo:
--   P3: Centralizar cálculo de plan de pagos (monto original,
--       descuento, monto neto, cuotas) para matrícula.
--   P4: Exponer un RPC que sugiera cheques a partir de las cuotas.

-- NOTA IMPORTANTE:
-- Esta migration NO modifica tablas existentes, solo agrega funciones
-- RPC para ser usadas por frontend / generación de documentos.

-- Suposiciones mínimas (adaptadas al inventario de columnas):
-- - Tabla public.fees: almacena cuotas asociadas a una matrícula.
--   Campos clave esperados (ajustar si es necesario):
--     id (uuid), enrollment_id (uuid), monto (numeric),
--     due_date (date), discount_amount (numeric, opcional),
--     discount_percent (numeric, opcional), year_academico (int).
-- - Tabla public.enrollments: representa la matrícula.


-- -------------------------------------------------------------------
-- P3: RPC calculate_enrollment_payment_plan(enrollment_id uuid)
-- -------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.calculate_enrollment_payment_plan(p_enrollment_id uuid)
RETURNS TABLE (
  enrollment_id uuid,
  total_original numeric,
  total_discount numeric,
  total_net numeric,
  numero_cuotas int4,
  cuota_index int4,
  cuota_monto_original numeric,
  cuota_discount numeric,
  cuota_monto_net numeric,
  cuota_due_date date,
  cuota_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_original numeric := 0;
  v_total_discount numeric := 0;
  v_total_net numeric := 0;
  v_num_cuotas int4 := 0;
BEGIN
  -- Calcular totales a partir de las cuotas (fees) existentes
  SELECT
    COALESCE(SUM(f.monto), 0) AS total_original,
    COALESCE(SUM(COALESCE(f.discount_amount, 0)), 0) AS total_discount,
    COALESCE(SUM(f.monto - COALESCE(f.discount_amount, 0)), 0) AS total_net,
    COUNT(*) AS num_cuotas
  INTO v_total_original, v_total_discount, v_total_net, v_num_cuotas
  FROM public.fees f
  WHERE f.enrollment_id = p_enrollment_id;

  RETURN QUERY
  SELECT
    p_enrollment_id AS enrollment_id,
    v_total_original AS total_original,
    v_total_discount AS total_discount,
    v_total_net AS total_net,
    v_num_cuotas AS numero_cuotas,
    ROW_NUMBER() OVER (ORDER BY f.due_date, f.id) AS cuota_index,
    f.monto AS cuota_monto_original,
    COALESCE(f.discount_amount, 0) AS cuota_discount,
    (f.monto - COALESCE(f.discount_amount, 0)) AS cuota_monto_net,
    f.due_date AS cuota_due_date,
    f.id AS cuota_id
  FROM public.fees f
  WHERE f.enrollment_id = p_enrollment_id
  ORDER BY f.due_date, f.id;
END;
$$;

COMMENT ON FUNCTION public.calculate_enrollment_payment_plan(uuid) IS
'Calcula el plan de pagos de una matrícula a partir de fees existentes: totales (original, descuento, neto) y detalle de cuotas.';

GRANT EXECUTE ON FUNCTION public.calculate_enrollment_payment_plan(uuid) TO anon, authenticated, service_role;


-- -------------------------------------------------------------------
-- P4: RPC suggest_cheques_for_enrollment(enrollment_id uuid)
-- -------------------------------------------------------------------
-- Esta función NO crea cheques en la tabla cheques. Solo sugiere los
-- montos y fechas a partir del plan de pagos para que el frontend los
-- prellene y el usuario confirme.

CREATE OR REPLACE FUNCTION public.suggest_cheques_for_enrollment(p_enrollment_id uuid)
RETURNS TABLE (
  enrollment_id uuid,
  cheque_index int4,
  monto numeric,
  fecha_emision date,
  fecha_vencimiento date,
  cuota_id uuid
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    plan.enrollment_id,
    plan.cuota_index AS cheque_index,
    plan.cuota_monto_net AS monto,
    CURRENT_DATE::date AS fecha_emision,
    plan.cuota_due_date AS fecha_vencimiento,
    plan.cuota_id AS cuota_id
  FROM public.calculate_enrollment_payment_plan(p_enrollment_id) AS plan
  WHERE plan.cuota_monto_net > 0;
$$;

COMMENT ON FUNCTION public.suggest_cheques_for_enrollment(uuid) IS
'Sugiere cheques (monto y fechas) a partir del plan de pagos calculado para una matrícula. No inserta registros en la tabla cheques.';

GRANT EXECUTE ON FUNCTION public.suggest_cheques_for_enrollment(uuid) TO anon, authenticated, service_role;
