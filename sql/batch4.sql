-- BATCH 4 (migrations 31 to 40)
-- ######################################################################

-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [31/49] MIGRATION: 20251120120000_guardian_intake_course_id
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add student_course_id to guardian intake surveys so we can link cursos directly
ALTER TABLE public.guardian_intake_surveys
  ADD COLUMN IF NOT EXISTS student_course_id uuid REFERENCES public.cursos(id);

CREATE INDEX IF NOT EXISTS idx_guardian_intake_surveys_course_id
  ON public.guardian_intake_surveys(student_course_id);

-- Best-effort backfill by matching existing text values to cursos.nom_curso
WITH normalized AS (
  SELECT gis.id, c.id AS curso_id
  FROM public.guardian_intake_surveys gis
  JOIN public.cursos c
    ON lower(trim(c.nom_curso)) = lower(trim(gis.student_course))
)
UPDATE public.guardian_intake_surveys AS gis
SET student_course_id = normalized.curso_id
FROM normalized
WHERE gis.id = normalized.id AND gis.student_course_id IS NULL;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [32/49] MIGRATION: 20251202_fix_security_issues
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Fix security issues reported by Supabase Linter
-- 1. Remove SECURITY DEFINER from views
-- 2. Enable RLS on public tables

-- 1. Fix database_metadata view
DROP VIEW IF EXISTS public.database_metadata CASCADE;

CREATE VIEW public.database_metadata WITH (security_invoker = true) AS
SELECT 
    t.table_schema,
    t.table_name,
    jsonb_agg(
        jsonb_build_object(
            'column_name', c.column_name,
            'data_type', c.data_type,
            'is_nullable', c.is_nullable,
            'column_default', c.column_default,
            'character_maximum_length', c.character_maximum_length
        ) ORDER BY c.ordinal_position
    ) AS metadata
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
GROUP BY t.table_schema, t.table_name
ORDER BY t.table_name;

GRANT SELECT ON public.database_metadata TO authenticated;


-- 2. Fix v_student_academic_history view
DROP VIEW IF EXISTS public.v_student_academic_history CASCADE;

CREATE VIEW public.v_student_academic_history WITH (security_invoker = true) AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  sar.year_academico,
  c.nom_curso,
  c.nivel,
  sar.estado,
  sar.promedio_anual,
  sar.asistencia_porcentaje,
  sar.observaciones,
  sar.fecha_inicio,
  sar.fecha_termino
FROM public.students s
JOIN public.student_academic_records sar ON sar.student_id = s.id
JOIN public.cursos c ON c.id = sar.curso_id
ORDER BY s.id, sar.year_academico DESC;

COMMENT ON VIEW public.v_student_academic_history IS 
'Complete academic history: shows all courses a student has been enrolled in across years.';

GRANT SELECT ON public.v_student_academic_history TO authenticated;


-- 3. Fix v_current_student_courses view
DROP VIEW IF EXISTS public.v_current_student_courses CASCADE;

CREATE VIEW public.v_current_student_courses WITH (security_invoker = true) AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  s.first_name,
  s.apellido_paterno,
  s.apellido_materno,
  sar.curso_id,
  c.nom_curso,
  c.nivel,
  c.letra_curso,
  c.year_academico,
  sar.estado as enrollment_status,
  sar.promedio_anual,
  sar.asistencia_porcentaje
FROM public.students s
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN public.cursos c ON c.id = sar.curso_id
WHERE UPPER(s.estado_std) = 'ACTIVO' OR s.estado_std IS NULL;

COMMENT ON VIEW public.v_current_student_courses IS 
'Helper view: Shows all active students with their current year course assignment. Uses case-insensitive comparison for estado_std.';

GRANT SELECT ON public.v_current_student_courses TO authenticated;


-- 4. Enable RLS on guardian_claim_logs
ALTER TABLE public.guardian_claim_logs ENABLE ROW LEVEL SECURITY;

-- 5. Enable RLS on rate_limit_counters
ALTER TABLE public.rate_limit_counters ENABLE ROW LEVEL SECURITY;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [33/49] MIGRATION: 20251203_matricula_p1_p2
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- P1 & P2 - MatriculaWizard helpers
-- Fecha: 2025-12-03
-- Objetivo:
--   P1: Exponer RPC para obtener cursos del año académico corriente.
--   P2: Exponer RPC base para obtener el último curso del estudiante
--       y un curso sugerido de promoción para el año actual.

-- -------------------------------------------------------------------
-- P1: RPC get_current_year_cursos()
-- -------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_current_year_cursos()
RETURNS SETOF public.cursos
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT c.*
  FROM public.cursos c
  WHERE c.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)::int
  ORDER BY c.nivel NULLS LAST, c.letra_curso NULLS LAST, c.nom_curso NULLS LAST;
$$;

COMMENT ON FUNCTION public.get_current_year_cursos() IS
'Devuelve todos los cursos del año académico corriente (year_academico = año actual). Pensado para MatriculaWizard.';

GRANT EXECUTE ON FUNCTION public.get_current_year_cursos() TO anon, authenticated, service_role;


-- -------------------------------------------------------------------
-- P2: RPC get_student_promotion_suggestion(student_id uuid)
-- -------------------------------------------------------------------
-- Nota: Esta función NO aplica todavía todas las reglas complejas de
-- promoción (por ejemplo 8° Básica -> I Medio). Solo entrega un
-- esqueleto seguro y coherente con el esquema para que frontend pueda
-- comenzar a integrar la funcionalidad.

CREATE OR REPLACE FUNCTION public.get_student_promotion_suggestion(p_student_id uuid)
RETURNS TABLE (
  current_course_id uuid,
  current_year int4,
  suggested_course_id uuid,
  suggested_year int4
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_year int4 := EXTRACT(YEAR FROM CURRENT_DATE)::int4;
BEGIN
  -- Último curso del estudiante según registros académicos
  RETURN QUERY
  WITH last_record AS (
    SELECT sar.curso_id,
           sar.year_academico
    FROM public.student_academic_records sar
    WHERE sar.student_id = p_student_id
    ORDER BY sar.year_academico DESC
    LIMIT 1
  )
  SELECT
    lr.curso_id AS current_course_id,
    lr.year_academico AS current_year,
    NULL::uuid AS suggested_course_id,
    v_current_year AS suggested_year
  FROM last_record lr;

  -- Nota: En una iteración posterior se puede reemplazar el NULL de
  -- suggested_course_id por la lógica real de promoción usando
  -- public.cursos (por ejemplo, mapa 2° -> 3°, etc.).
END;
$$;

COMMENT ON FUNCTION public.get_student_promotion_suggestion(uuid) IS
'Devuelve el último curso conocido del estudiante y el año académico actual como destino. La lógica de promoción de curso se añadirá en una fase posterior.';

GRANT EXECUTE ON FUNCTION public.get_student_promotion_suggestion(uuid) TO anon, authenticated, service_role;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [34/49] MIGRATION: 20251203_matricula_p3_p4
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

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
  -- Calcular totales a partir de las cuotas (fee) existentes
  SELECT
    COALESCE(SUM(f.amount), 0) AS total_original,
    0 AS total_discount,
    COALESCE(SUM(f.amount), 0) AS total_net,
    COUNT(*) AS num_cuotas
  INTO v_total_original, v_total_discount, v_total_net, v_num_cuotas
  FROM public.fee f
  WHERE f.enrollment_id = p_enrollment_id;

  RETURN QUERY
  SELECT
    p_enrollment_id AS enrollment_id,
    v_total_original AS total_original,
    v_total_discount AS total_discount,
    v_total_net AS total_net,
    v_num_cuotas AS numero_cuotas,
    ROW_NUMBER() OVER (ORDER BY f.due_date, f.id) AS cuota_index,
    f.amount AS cuota_monto_original,
    0::numeric AS cuota_discount,
    f.amount AS cuota_monto_net,
    f.due_date AS cuota_due_date,
    f.id AS cuota_id
  FROM public.fee f
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


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [35/49] MIGRATION: 20251217_add_cheques_missing_columns
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- ============================================================
-- MIGRACIÓN: Añadir columnas faltantes a tabla cheques
-- Fecha: 2025-12-17
-- Descripción: Consolida las columnas numero_cuota, document_id 
--              y folio_number necesarias para el flujo de cheques
-- ============================================================

BEGIN;

-- 1) Añadir numero_cuota (correlación cheque -> cuota)
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS numero_cuota integer;

-- Constraint: numero_cuota debe ser >= 1 si tiene valor
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'cheques_numero_cuota_check'
  ) THEN
    ALTER TABLE public.cheques
      ADD CONSTRAINT cheques_numero_cuota_check 
      CHECK (numero_cuota IS NULL OR numero_cuota >= 1);
  END IF;
END $$;

-- Índice compuesto para búsquedas por enrollment + cuota
CREATE INDEX IF NOT EXISTS idx_cheques_enrollment_cuota 
  ON public.cheques(enrollment_id, numero_cuota);

-- 2) Añadir document_id (FK al pagaré en enrollment_documents)
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS document_id uuid;

-- Añadir FK si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'cheques_document_id_fkey'
  ) THEN
    ALTER TABLE public.cheques
      ADD CONSTRAINT cheques_document_id_fkey 
      FOREIGN KEY (document_id) 
      REFERENCES public.enrollment_documents(id) 
      ON DELETE SET NULL;
  END IF;
END $$;

-- Índice para búsquedas por document_id
CREATE INDEX IF NOT EXISTS idx_cheques_document_id 
  ON public.cheques(document_id);

-- 3) Añadir folio_number (desnormalización del folio del pagaré)
ALTER TABLE public.cheques
  ADD COLUMN IF NOT EXISTS folio_number text;

-- Índice para búsquedas por folio
CREATE INDEX IF NOT EXISTS idx_cheques_folio_number 
  ON public.cheques(folio_number);

-- 4) Comentarios descriptivos
COMMENT ON COLUMN public.cheques.numero_cuota IS 'Número de cuota que este cheque cubre (1-N)';
COMMENT ON COLUMN public.cheques.document_id IS 'FK al documento pagaré asociado en enrollment_documents';
COMMENT ON COLUMN public.cheques.folio_number IS 'Número de folio del pagaré (desnormalizado para consultas rápidas)';

COMMIT;

-- ============================================================
-- VERIFICACIÓN (ejecutar después del COMMIT)
-- ============================================================
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'cheques' 
--   AND column_name IN ('numero_cuota', 'document_id', 'folio_number');


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [36/49] MIGRATION: 20251219_add_guardian_fields_libro_matricula
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Add missing fields to guardians table for Libro de Matrícula
-- Date: 2025-12-19

BEGIN;

-- Add date_of_birth field for guardians
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS date_of_birth DATE;

-- Add nivel_educacional field
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS nivel_educacional VARCHAR(100);

-- Add apellido_paterno and apellido_materno fields
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

-- Add helpful comments
COMMENT ON COLUMN public.guardians.date_of_birth IS 'Fecha de nacimiento del apoderado para Libro de Matrícula';
COMMENT ON COLUMN public.guardians.nivel_educacional IS 'Nivel educacional: Básica Completa, Media Completa, Técnica, Universitaria, Postgrado, etc.';
COMMENT ON COLUMN public.guardians.apellido_paterno IS 'Apellido paterno del apoderado';
COMMENT ON COLUMN public.guardians.apellido_materno IS 'Apellido materno del apoderado';

COMMIT;


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [37/49] MIGRATION: 20251219_add_pre_matriculado_estado
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

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


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [38/49] MIGRATION: 20251219_add_student_apellidos_separated
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

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


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [39/49] MIGRATION: 20251219_create_libro_matricula_rpc
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Create RPC function to generate Libro de Matrícula report
-- Date: 2025-12-19

-- Drop ALL existing overloads to avoid ambiguity
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report();
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER);
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR);
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION public.generate_libro_matricula_report(
  p_year INTEGER DEFAULT NULL,
  p_estado VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  nivel TEXT,
  curso TEXT,
  nombres TEXT,
  apellido_paterno TEXT,
  apellido_materno TEXT,
  run_estudiante TEXT,
  fecha_nac_estudiante TEXT,
  nacionalidad TEXT,
  genero_estudiante TEXT,
  con_quien_vive TEXT,
  direccion_estudiante TEXT,
  comuna_estudiante TEXT,
  repite_curso TEXT,
  institucion_procedencia TEXT,
  nombre_apoderado TEXT,
  apellido_paterno_apoderado TEXT,
  apellido_materno_apoderado TEXT,
  relacion_apoderado TEXT,
  fecha_nac_apoderado TEXT,
  run_apoderado TEXT,
  nivel_educacional_apoderado TEXT,
  direccion_apoderado TEXT,
  comuna_apoderado TEXT,
  email_apoderado TEXT,
  telefono_apoderado TEXT,
  nombre_apoderado_secundario TEXT,
  run_apoderado_secundario TEXT,
  fecha_nac_apoderado_secundario TEXT,
  telefono_apoderado_secundario TEXT,
  email_apoderado_secundario TEXT,
  fecha_retiro TEXT,
  motivo_retiro TEXT,
  condicion TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    -- Curso info
    COALESCE(c.nivel, '')::TEXT,
    COALESCE(c.nom_curso, '')::TEXT,
    
    -- Estudiante
    COALESCE(s.first_name, '')::TEXT AS nombres,
    COALESCE(s.apellido_paterno, '')::TEXT,
    COALESCE(s.apellido_materno, '')::TEXT,
    COALESCE(s.run, '')::TEXT,
    COALESCE(TO_CHAR(s.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    UPPER(COALESCE(s.nacionalidad, 'CHILENA'))::TEXT,
    COALESCE(s.genero, '')::TEXT,
    COALESCE(s.con_quien_vive, '')::TEXT,
    COALESCE(s.direccion, '')::TEXT,
    COALESCE(s.comuna, '')::TEXT,
    CASE WHEN COALESCE(s.repite_curso_actual, 'No') ILIKE 'si%' THEN 'Sí' ELSE 'No' END::TEXT,
    COALESCE(s.institucion_procedencia, '')::TEXT,
    
    -- Apoderado principal
    COALESCE(g1.first_name, '')::TEXT,
    COALESCE(g1.apellido_paterno, '')::TEXT,
    COALESCE(g1.apellido_materno, '')::TEXT,
    COALESCE(g1.relationship_type, '')::TEXT,
    COALESCE(TO_CHAR(g1.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g1.run, '')::TEXT,
    COALESCE(g1.nivel_educacional, '')::TEXT,
    COALESCE(g1.address, '')::TEXT,
    COALESCE(g1.comuna, '')::TEXT,
    COALESCE(g1.email, '')::TEXT,
    COALESCE(g1.phone, '')::TEXT,
    
    -- Apoderado secundario
    COALESCE(g2.first_name || ' ' || COALESCE(g2.apellido_paterno, '') || ' ' || COALESCE(g2.apellido_materno, ''), '')::TEXT,
    COALESCE(g2.run, '')::TEXT,
    COALESCE(TO_CHAR(g2.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g2.phone, '')::TEXT,
    COALESCE(g2.email, '')::TEXT,
    
    -- Retiro
    COALESCE(TO_CHAR(s.fecha_retiro, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(s.motivo_retiro, '')::TEXT,
    
    -- Condición
    CASE 
      WHEN s.estado_std = 'PRE_MATRICULADO' THEN 'Matrícula en proceso'
      WHEN s.estado_std = 'MATRICULADO' THEN 'Confirmado para año escolar'
      WHEN s.estado_std = 'ACTIVO' THEN 'Cursando'
      WHEN s.estado_std = 'RETIRADO' THEN 'Retirado'
      ELSE COALESCE(s.estado_std, '')
    END::TEXT
    
  FROM public.students s
  LEFT JOIN public.cursos c ON s.curso = c.id
  
  -- Apoderado principal (titular o primary)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND (sg.is_primary = true OR sg.role = 'titular')
    ORDER BY sg.is_primary DESC NULLS LAST, sg.created_at ASC
    LIMIT 1
  ) g1 ON true
  
  -- Apoderado secundario (suplente)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND sg.is_primary = false
      AND (sg.role = 'suplente' OR sg.role IS NULL)
    ORDER BY sg.created_at ASC
    LIMIT 1
  ) g2 ON true
  
  WHERE 
    (p_year IS NULL OR c.year_academico = p_year)
    AND (p_estado IS NULL OR s.estado_std = p_estado)
  
  ORDER BY c.nivel, c.nom_curso, s.apellido_paterno, s.apellido_materno, s.first_name;
END;
$$;

COMMENT ON FUNCTION public.generate_libro_matricula_report(INTEGER, VARCHAR) IS 
'Genera reporte completo del Libro de Matrícula con datos de estudiantes, apoderados titular y suplente. Filtros: p_year (año académico), p_estado (PRE_MATRICULADO, MATRICULADO, ACTIVO, RETIRADO)';


-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ
-- [40/49] MIGRATION: 20251219_fix_libro_matricula_report
-- â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆ

-- Fix generate_libro_matricula_report function to handle empty strings in year field
-- Date: 2025-12-19

-- STEP 1: Clean up bad data in enrollments.year
-- Handle NULL, 0, and potentially empty strings if year is text/varchar
DO $$
BEGIN
  -- Try to update assuming year is integer
  UPDATE public.enrollments
  SET year = EXTRACT(YEAR FROM created_at)::INTEGER
  WHERE year IS NULL OR year = 0;
EXCEPTION
  WHEN OTHERS THEN
    -- If year is text/varchar type, handle empty strings
    EXECUTE 'UPDATE public.enrollments SET year = EXTRACT(YEAR FROM created_at)::INTEGER WHERE year IS NULL OR year::text = '''' OR year::text = ''0''';
END $$;

-- STEP 2: Drop old function versions
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS public.generate_libro_matricula_report(INTEGER, VARCHAR);

CREATE OR REPLACE FUNCTION public.generate_libro_matricula_report(
  p_year INTEGER DEFAULT NULL,
  p_estado VARCHAR DEFAULT NULL,
  p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  numero_correlativo BIGINT,
  year_matricula INTEGER,
  fecha_matricula TIMESTAMPTZ,
  nivel TEXT,
  curso TEXT,
  nombres TEXT,
  apellido_paterno TEXT,
  apellido_materno TEXT,
  run_estudiante TEXT,
  fecha_nac_estudiante TEXT,
  nacionalidad TEXT,
  genero_estudiante TEXT,
  con_quien_vive TEXT,
  direccion_estudiante TEXT,
  comuna_estudiante TEXT,
  repite_curso TEXT,
  institucion_procedencia TEXT,
  nombre_apoderado TEXT,
  apellido_paterno_apoderado TEXT,
  apellido_materno_apoderado TEXT,
  relacion_apoderado TEXT,
  fecha_nac_apoderado TEXT,
  run_apoderado TEXT,
  nivel_educacional_apoderado TEXT,
  direccion_apoderado TEXT,
  comuna_apoderado TEXT,
  email_apoderado TEXT,
  telefono_apoderado TEXT,
  nombre_apoderado_secundario TEXT,
  run_apoderado_secundario TEXT,
  fecha_nac_apoderado_secundario TEXT,
  telefono_apoderado_secundario TEXT,
  email_apoderado_secundario TEXT,
  fecha_retiro TEXT,
  motivo_retiro TEXT,
  condicion TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_year INTEGER;
  v_estado VARCHAR;
  v_status VARCHAR;
BEGIN
  -- Sanitize parameters
  v_year := NULLIF(p_year, 0);
  v_estado := NULLIF(TRIM(p_estado), '');
  v_status := NULLIF(TRIM(p_status), '');

  RETURN QUERY
  SELECT
    -- Numeración y fecha de matrícula
    ROW_NUMBER() OVER (ORDER BY e.created_at ASC)::BIGINT,
    COALESCE(
      CASE WHEN e.year IS NOT NULL AND e.year > 0 THEN e.year 
           ELSE EXTRACT(YEAR FROM e.created_at)::INTEGER 
      END,
      EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER
    ),
    e.created_at,
    
    -- Curso info
    COALESCE(c.nivel, '')::TEXT,
    COALESCE(c.nom_curso, '')::TEXT,
    
    -- Estudiante
    COALESCE(s.first_name, '')::TEXT AS nombres,
    COALESCE(s.apellido_paterno, '')::TEXT,
    COALESCE(s.apellido_materno, '')::TEXT,
    COALESCE(s.run, '')::TEXT,
    COALESCE(TO_CHAR(s.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    UPPER(COALESCE(s.nacionalidad, 'CHILENA'))::TEXT,
    COALESCE(s.genero, '')::TEXT,
    COALESCE(s.con_quien_vive, '')::TEXT,
    COALESCE(s.direccion, '')::TEXT,
    COALESCE(s.comuna, '')::TEXT,
    CASE WHEN COALESCE(s.repite_curso_actual, 'No') ILIKE 'si%' THEN 'Sí' ELSE 'No' END::TEXT,
    COALESCE(s.institucion_procedencia, '')::TEXT,
    
    -- Apoderado principal
    COALESCE(g1.first_name, '')::TEXT,
    COALESCE(g1.apellido_paterno, '')::TEXT,
    COALESCE(g1.apellido_materno, '')::TEXT,
    COALESCE(g1.relationship_type, '')::TEXT,
    COALESCE(TO_CHAR(g1.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g1.run, '')::TEXT,
    COALESCE(g1.nivel_educacional, '')::TEXT,
    COALESCE(g1.address, '')::TEXT,
    COALESCE(g1.comuna, '')::TEXT,
    COALESCE(g1.email, '')::TEXT,
    COALESCE(g1.phone, '')::TEXT,
    
    -- Apoderado secundario
    COALESCE(g2.first_name || ' ' || COALESCE(g2.apellido_paterno, '') || ' ' || COALESCE(g2.apellido_materno, ''), '')::TEXT,
    COALESCE(g2.run, '')::TEXT,
    COALESCE(TO_CHAR(g2.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g2.phone, '')::TEXT,
    COALESCE(g2.email, '')::TEXT,
    
    -- Retiro
    COALESCE(TO_CHAR(s.fecha_retiro, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(s.motivo_retiro, '')::TEXT,
    
    -- Condición
    CASE 
      WHEN s.estado_std = 'PRE_MATRICULADO' THEN 'Matrícula en proceso'
      WHEN s.estado_std = 'MATRICULADO' THEN 'Confirmado para año escolar'
      WHEN s.estado_std = 'ACTIVO' THEN 'Cursando'
      WHEN s.estado_std = 'RETIRADO' THEN 'Retirado'
      ELSE COALESCE(s.estado_std, '')
    END::TEXT
    
  FROM public.students s
  
  -- Vincular con enrollment para filtrar por fecha de matrícula
  INNER JOIN public.enrollment_students es ON s.id = es.student_id
  INNER JOIN public.enrollments e ON es.enrollment_id = e.id
  
  LEFT JOIN public.cursos c ON s.curso = c.id
  
  -- Apoderado principal (titular o primary)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.guardian_role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND (sg.is_primary = true OR sg.guardian_role = 'titular')
    ORDER BY sg.is_primary DESC NULLS LAST, sg.created_at ASC
    LIMIT 1
  ) g1 ON true
  
  -- Apoderado secundario (suplente)
  LEFT JOIN LATERAL (
    SELECT g.*, sg.guardian_role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND sg.is_primary = false
      AND (sg.guardian_role = 'suplente' OR sg.guardian_role IS NULL)
    ORDER BY sg.created_at ASC
    LIMIT 1
  ) g2 ON true
  
  WHERE 
    (v_year IS NULL OR e.year = v_year OR (c.year_academico IS NOT NULL AND c.year_academico = v_year))
    AND (v_estado IS NULL OR s.estado_std = v_estado)
    AND (v_status IS NULL OR e.status = v_status)
  
  ORDER BY e.created_at ASC, c.nivel, c.nom_curso, s.apellido_paterno, s.apellido_materno, s.first_name;
END;
$$;

COMMENT ON FUNCTION public.generate_libro_matricula_report(INTEGER, VARCHAR, VARCHAR) IS 
'Genera reporte completo del Libro de Matrícula con datos de estudiantes, apoderados titular y suplente. 
Filtros: 
- p_year (año académico)
- p_estado (PRE_MATRICULADO, MATRICULADO, ACTIVO, RETIRADO)
- p_status (draft, pending, completed, rejected)
Retorna numeración correlativa, año de matrícula, y fecha de matrícula además de todos los datos del estudiante.';



-- ######################################################################
