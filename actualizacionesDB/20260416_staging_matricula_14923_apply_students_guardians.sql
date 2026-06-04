-- Safe apply package for workbook 14923.
-- Scope intentionally limited to:
--   - public.students
--   - public.guardians
--   - missing links in public.student_guardian
-- Explicitly excluded:
--   - public.enrollments
--   - enrollments.meta / per_student_economic / per_student_plans
--   - public.fee

-- Preconditions:
--   1) staging schema and raw imports already created
--   2) actualizacionesDB/20260416_staging_matricula_14923_validation.sql reviewed
--   3) actualizacionesDB/20260416_staging_matricula_14923_diff.sql reviewed

-- =========================================================
-- 1. PREVIEW SUMMARY
-- =========================================================

SELECT
  entity_name,
  COUNT(*) AS diff_rows,
  COUNT(DISTINCT target_id) FILTER (WHERE target_id IS NOT NULL) AS target_rows
FROM staging.v_matricula_14923_diff_all
GROUP BY entity_name
ORDER BY entity_name;

-- =========================================================
-- 2. PREVIEW DETAILS
-- =========================================================

SELECT *
FROM staging.v_matricula_14923_student_diff
ORDER BY source_row_number, field_name;

SELECT *
FROM staging.v_matricula_14923_guardian_diff
ORDER BY source_row_number, field_name;

SELECT *
FROM staging.v_matricula_14923_student_guardian_link_diff
ORDER BY source_row_number;

-- =========================================================
-- 3. CONFLICT CHECKS
-- If any row appears here, stop and resolve it before APPLY.
-- =========================================================

WITH student_field_candidates AS (
  SELECT
    target_id,
    field_name,
    COUNT(DISTINCT staging_value) AS distinct_value_count,
    ARRAY_AGG(DISTINCT staging_value ORDER BY staging_value) AS candidate_values,
    ARRAY_AGG(source_row_number ORDER BY source_row_number) AS source_rows
  FROM staging.v_matricula_14923_student_diff
  GROUP BY target_id, field_name
), guardian_field_candidates AS (
  SELECT
    target_id,
    field_name,
    COUNT(DISTINCT staging_value) AS distinct_value_count,
    ARRAY_AGG(DISTINCT staging_value ORDER BY staging_value) AS candidate_values,
    ARRAY_AGG(source_row_number ORDER BY source_row_number) AS source_rows
  FROM staging.v_matricula_14923_guardian_diff
  GROUP BY target_id, field_name
)
SELECT
  'students'::text AS entity_name,
  target_id,
  field_name,
  distinct_value_count,
  candidate_values,
  source_rows
FROM student_field_candidates
WHERE distinct_value_count > 1

UNION ALL

SELECT
  'guardians'::text AS entity_name,
  target_id,
  field_name,
  distinct_value_count,
  candidate_values,
  source_rows
FROM guardian_field_candidates
WHERE distinct_value_count > 1
ORDER BY entity_name, target_id, field_name;

-- =========================================================
-- 4. APPLY PLAN PREVIEW
-- This shows the final pivoted payload that would be applied.
-- =========================================================

WITH student_field_candidates AS (
  SELECT
    target_id,
    field_name,
    ARRAY_AGG(DISTINCT staging_value ORDER BY staging_value) AS candidate_values,
    COUNT(DISTINCT staging_value) AS distinct_value_count
  FROM staging.v_matricula_14923_student_diff
  GROUP BY target_id, field_name
), student_updates AS (
  SELECT
    target_id AS student_id,
    MAX(CASE WHEN field_name = 'first_name' THEN candidate_values[1] END) AS first_name,
    MAX(CASE WHEN field_name = 'apellido_paterno' THEN candidate_values[1] END) AS apellido_paterno,
    MAX(CASE WHEN field_name = 'apellido_materno' THEN candidate_values[1] END) AS apellido_materno,
    MAX(CASE WHEN field_name = 'whole_name' THEN candidate_values[1] END) AS whole_name,
    MAX(CASE WHEN field_name = 'run' THEN candidate_values[1] END) AS run,
    MAX(CASE WHEN field_name = 'run_numero' THEN candidate_values[1] END) AS run_numero_text,
    MAX(CASE WHEN field_name = 'run_verificador' THEN candidate_values[1] END) AS run_verificador,
    MAX(CASE WHEN field_name = 'fecha_matricula' THEN candidate_values[1] END) AS fecha_matricula_text,
    MAX(CASE WHEN field_name = 'date_of_birth' THEN candidate_values[1] END) AS date_of_birth_text,
    MAX(CASE WHEN field_name = 'genero' THEN candidate_values[1] END) AS genero,
    MAX(CASE WHEN field_name = 'nacionalidad' THEN candidate_values[1] END) AS nacionalidad,
    MAX(CASE WHEN field_name = 'email' THEN candidate_values[1] END) AS email,
    MAX(CASE WHEN field_name = 'repite_curso_actual' THEN candidate_values[1] END) AS repite_curso_actual,
    MAX(CASE WHEN field_name = 'comuna' THEN candidate_values[1] END) AS comuna,
    MAX(CASE WHEN field_name = 'direccion' THEN candidate_values[1] END) AS direccion,
    MAX(CASE WHEN field_name = 'fecha_retiro' THEN candidate_values[1] END) AS fecha_retiro_text,
    MAX(CASE WHEN field_name = 'motivo_retiro' THEN candidate_values[1] END) AS motivo_retiro,
    MAX(CASE WHEN field_name = 'curso' THEN candidate_values[1] END) AS curso_text,
    MAX(CASE WHEN field_name = 'estado_std' THEN candidate_values[1] END) AS estado_std
  FROM student_field_candidates
  WHERE distinct_value_count = 1
  GROUP BY target_id
), guardian_field_candidates AS (
  SELECT
    target_id,
    field_name,
    ARRAY_AGG(DISTINCT staging_value ORDER BY staging_value) AS candidate_values,
    COUNT(DISTINCT staging_value) AS distinct_value_count
  FROM staging.v_matricula_14923_guardian_diff
  GROUP BY target_id, field_name
), guardian_updates AS (
  SELECT
    target_id AS guardian_id,
    MAX(CASE WHEN field_name = 'first_name' THEN candidate_values[1] END) AS first_name,
    MAX(CASE WHEN field_name = 'apellido_paterno' THEN candidate_values[1] END) AS apellido_paterno,
    MAX(CASE WHEN field_name = 'apellido_materno' THEN candidate_values[1] END) AS apellido_materno,
    MAX(CASE WHEN field_name = 'last_name' THEN candidate_values[1] END) AS last_name,
    MAX(CASE WHEN field_name = 'run' THEN candidate_values[1] END) AS run,
    MAX(CASE WHEN field_name = 'date_of_birth' THEN candidate_values[1] END) AS date_of_birth_text,
    MAX(CASE WHEN field_name = 'email' THEN candidate_values[1] END) AS email,
    MAX(CASE WHEN field_name = 'phone' THEN candidate_values[1] END) AS phone,
    MAX(CASE WHEN field_name = 'relationship_type' THEN candidate_values[1] END) AS relationship_type,
    MAX(CASE WHEN field_name = 'nivel_educacional' THEN candidate_values[1] END) AS nivel_educacional,
    MAX(CASE WHEN field_name = 'comuna' THEN candidate_values[1] END) AS comuna,
    MAX(CASE WHEN field_name = 'address' THEN candidate_values[1] END) AS address
  FROM guardian_field_candidates
  WHERE distinct_value_count = 1
  GROUP BY target_id
), missing_links AS (
  SELECT DISTINCT
    n.student_id,
    n.guardian_id
  FROM staging.v_matricula_14923_apoderados_normalized n
  JOIN staging.v_matricula_14923_student_guardian_link_diff d
    ON d.source_row_number = n.source_row_number
  WHERE n.ready_for_diff
)
SELECT 'students'::text AS entity_name, to_jsonb(student_updates.*) AS payload
FROM student_updates

UNION ALL

SELECT 'guardians'::text AS entity_name, to_jsonb(guardian_updates.*) AS payload
FROM guardian_updates

UNION ALL

SELECT 'student_guardian'::text AS entity_name, to_jsonb(missing_links.*) AS payload
FROM missing_links
ORDER BY entity_name;

-- =========================================================
-- 5. APPLY
-- Descomenta desde BEGIN hasta COMMIT solo después de aprobar el PREVIEW.
-- =========================================================

-- BEGIN;
--
-- DO $$
-- DECLARE
--   student_conflicts integer;
--   guardian_conflicts integer;
-- BEGIN
--   WITH student_field_conflicts AS (
--     SELECT 1
--     FROM staging.v_matricula_14923_student_diff
--     GROUP BY target_id, field_name
--     HAVING COUNT(DISTINCT staging_value) > 1
--   ), guardian_field_conflicts AS (
--     SELECT 1
--     FROM staging.v_matricula_14923_guardian_diff
--     GROUP BY target_id, field_name
--     HAVING COUNT(DISTINCT staging_value) > 1
--   )
--   SELECT
--     (SELECT COUNT(*) FROM student_field_conflicts),
--     (SELECT COUNT(*) FROM guardian_field_conflicts)
--   INTO student_conflicts, guardian_conflicts;
--
--   IF student_conflicts > 0 OR guardian_conflicts > 0 THEN
--     RAISE EXCEPTION
--       'Conflictos detectados en staging: student_conflicts=%, guardian_conflicts=%',
--       student_conflicts,
--       guardian_conflicts;
--   END IF;
-- END $$;
--
-- CREATE TABLE IF NOT EXISTS staging.matricula_14923_apply_backup_rows (
--   entity_name text NOT NULL,
--   target_id uuid NULL,
--   backup_taken_at timestamptz NOT NULL DEFAULT now(),
--   source_tag text NOT NULL,
--   row_data jsonb NOT NULL
-- );
--
-- WITH student_field_candidates AS (
--   SELECT
--     target_id,
--     field_name,
--     ARRAY_AGG(DISTINCT staging_value ORDER BY staging_value) AS candidate_values,
--     COUNT(DISTINCT staging_value) AS distinct_value_count
--   FROM staging.v_matricula_14923_student_diff
--   GROUP BY target_id, field_name
-- ), student_updates AS (
--   SELECT
--     target_id::uuid AS student_id,
--     MAX(CASE WHEN field_name = 'first_name' THEN candidate_values[1] END) AS first_name,
--     MAX(CASE WHEN field_name = 'apellido_paterno' THEN candidate_values[1] END) AS apellido_paterno,
--     MAX(CASE WHEN field_name = 'apellido_materno' THEN candidate_values[1] END) AS apellido_materno,
--     MAX(CASE WHEN field_name = 'whole_name' THEN candidate_values[1] END) AS whole_name,
--     MAX(CASE WHEN field_name = 'run' THEN candidate_values[1] END) AS run,
--     MAX(CASE WHEN field_name = 'run_numero' THEN candidate_values[1]::bigint END) AS run_numero,
--     MAX(CASE WHEN field_name = 'run_verificador' THEN candidate_values[1] END) AS run_verificador,
--     MAX(CASE WHEN field_name = 'fecha_matricula' THEN candidate_values[1]::date END) AS fecha_matricula,
--     MAX(CASE WHEN field_name = 'date_of_birth' THEN candidate_values[1]::date END) AS date_of_birth,
--     MAX(CASE WHEN field_name = 'genero' THEN candidate_values[1] END) AS genero,
--     MAX(CASE WHEN field_name = 'nacionalidad' THEN candidate_values[1] END) AS nacionalidad,
--     MAX(CASE WHEN field_name = 'email' THEN candidate_values[1] END) AS email,
--     MAX(CASE WHEN field_name = 'repite_curso_actual' THEN candidate_values[1] END) AS repite_curso_actual,
--     MAX(CASE WHEN field_name = 'comuna' THEN candidate_values[1] END) AS comuna,
--     MAX(CASE WHEN field_name = 'direccion' THEN candidate_values[1] END) AS direccion,
--     MAX(CASE WHEN field_name = 'fecha_retiro' THEN candidate_values[1]::date END) AS fecha_retiro,
--     MAX(CASE WHEN field_name = 'motivo_retiro' THEN candidate_values[1] END) AS motivo_retiro,
--     MAX(CASE WHEN field_name = 'curso' THEN candidate_values[1]::uuid END) AS curso,
--     MAX(CASE WHEN field_name = 'estado_std' THEN candidate_values[1] END) AS estado_std
--   FROM student_field_candidates
--   WHERE distinct_value_count = 1
--   GROUP BY target_id
-- ), guardian_field_candidates AS (
--   SELECT
--     target_id,
--     field_name,
--     ARRAY_AGG(DISTINCT staging_value ORDER BY staging_value) AS candidate_values,
--     COUNT(DISTINCT staging_value) AS distinct_value_count
--   FROM staging.v_matricula_14923_guardian_diff
--   GROUP BY target_id, field_name
-- ), guardian_updates AS (
--   SELECT
--     target_id::uuid AS guardian_id,
--     MAX(CASE WHEN field_name = 'first_name' THEN candidate_values[1] END) AS first_name,
--     MAX(CASE WHEN field_name = 'apellido_paterno' THEN candidate_values[1] END) AS apellido_paterno,
--     MAX(CASE WHEN field_name = 'apellido_materno' THEN candidate_values[1] END) AS apellido_materno,
--     MAX(CASE WHEN field_name = 'last_name' THEN candidate_values[1] END) AS last_name,
--     MAX(CASE WHEN field_name = 'run' THEN candidate_values[1] END) AS run,
--     MAX(CASE WHEN field_name = 'date_of_birth' THEN candidate_values[1]::date END) AS date_of_birth,
--     MAX(CASE WHEN field_name = 'email' THEN candidate_values[1] END) AS email,
--     MAX(CASE WHEN field_name = 'phone' THEN candidate_values[1] END) AS phone,
--     MAX(CASE WHEN field_name = 'relationship_type' THEN candidate_values[1] END) AS relationship_type,
--     MAX(CASE WHEN field_name = 'nivel_educacional' THEN candidate_values[1] END) AS nivel_educacional,
--     MAX(CASE WHEN field_name = 'comuna' THEN candidate_values[1] END) AS comuna,
--     MAX(CASE WHEN field_name = 'address' THEN candidate_values[1] END) AS address
--   FROM guardian_field_candidates
--   WHERE distinct_value_count = 1
--   GROUP BY target_id
-- ), missing_links AS (
--   SELECT DISTINCT
--     n.student_id,
--     n.guardian_id
--   FROM staging.v_matricula_14923_apoderados_normalized n
--   JOIN staging.v_matricula_14923_student_guardian_link_diff d
--     ON d.source_row_number = n.source_row_number
--   WHERE n.ready_for_diff
-- )
-- INSERT INTO staging.matricula_14923_apply_backup_rows (entity_name, target_id, source_tag, row_data)
-- SELECT 'students', s.id, '20260416_staging_matricula_14923_apply_students_guardians', to_jsonb(s)
-- FROM public.students s
-- JOIN student_updates u ON u.student_id = s.id
--
-- UNION ALL
--
-- SELECT 'guardians', g.id, '20260416_staging_matricula_14923_apply_students_guardians', to_jsonb(g)
-- FROM public.guardians g
-- JOIN guardian_updates u ON u.guardian_id = g.id
--
-- UNION ALL
--
-- SELECT
--   'student_guardian_planned_insert',
--   NULL,
--   '20260416_staging_matricula_14923_apply_students_guardians',
--   jsonb_build_object('student_id', l.student_id, 'guardian_id', l.guardian_id)
-- FROM missing_links l;
--
-- WITH student_field_candidates AS (
--   SELECT
--     target_id,
--     field_name,
--     ARRAY_AGG(DISTINCT staging_value ORDER BY staging_value) AS candidate_values,
--     COUNT(DISTINCT staging_value) AS distinct_value_count
--   FROM staging.v_matricula_14923_student_diff
--   GROUP BY target_id, field_name
-- ), student_updates AS (
--   SELECT
--     target_id::uuid AS student_id,
--     MAX(CASE WHEN field_name = 'first_name' THEN candidate_values[1] END) AS first_name,
--     MAX(CASE WHEN field_name = 'apellido_paterno' THEN candidate_values[1] END) AS apellido_paterno,
--     MAX(CASE WHEN field_name = 'apellido_materno' THEN candidate_values[1] END) AS apellido_materno,
--     MAX(CASE WHEN field_name = 'whole_name' THEN candidate_values[1] END) AS whole_name,
--     MAX(CASE WHEN field_name = 'run' THEN candidate_values[1] END) AS run,
--     MAX(CASE WHEN field_name = 'run_numero' THEN candidate_values[1]::bigint END) AS run_numero,
--     MAX(CASE WHEN field_name = 'run_verificador' THEN candidate_values[1] END) AS run_verificador,
--     MAX(CASE WHEN field_name = 'fecha_matricula' THEN candidate_values[1]::date END) AS fecha_matricula,
--     MAX(CASE WHEN field_name = 'date_of_birth' THEN candidate_values[1]::date END) AS date_of_birth,
--     MAX(CASE WHEN field_name = 'genero' THEN candidate_values[1] END) AS genero,
--     MAX(CASE WHEN field_name = 'nacionalidad' THEN candidate_values[1] END) AS nacionalidad,
--     MAX(CASE WHEN field_name = 'email' THEN candidate_values[1] END) AS email,
--     MAX(CASE WHEN field_name = 'repite_curso_actual' THEN candidate_values[1] END) AS repite_curso_actual,
--     MAX(CASE WHEN field_name = 'comuna' THEN candidate_values[1] END) AS comuna,
--     MAX(CASE WHEN field_name = 'direccion' THEN candidate_values[1] END) AS direccion,
--     MAX(CASE WHEN field_name = 'fecha_retiro' THEN candidate_values[1]::date END) AS fecha_retiro,
--     MAX(CASE WHEN field_name = 'motivo_retiro' THEN candidate_values[1] END) AS motivo_retiro,
--     MAX(CASE WHEN field_name = 'curso' THEN candidate_values[1]::uuid END) AS curso,
--     MAX(CASE WHEN field_name = 'estado_std' THEN candidate_values[1] END) AS estado_std
--   FROM student_field_candidates
--   WHERE distinct_value_count = 1
--   GROUP BY target_id
-- )
-- UPDATE public.students s
-- SET
--   first_name = COALESCE(u.first_name, s.first_name),
--   apellido_paterno = COALESCE(u.apellido_paterno, s.apellido_paterno),
--   apellido_materno = COALESCE(u.apellido_materno, s.apellido_materno),
--   whole_name = COALESCE(u.whole_name, s.whole_name),
--   run = COALESCE(u.run, s.run),
--   run_numero = COALESCE(u.run_numero, s.run_numero),
--   run_verificador = COALESCE(u.run_verificador, s.run_verificador),
--   fecha_matricula = COALESCE(u.fecha_matricula, s.fecha_matricula),
--   date_of_birth = COALESCE(u.date_of_birth, s.date_of_birth),
--   genero = COALESCE(u.genero, s.genero),
--   nacionalidad = COALESCE(u.nacionalidad, s.nacionalidad),
--   email = COALESCE(u.email, s.email),
--   repite_curso_actual = COALESCE(u.repite_curso_actual, s.repite_curso_actual),
--   comuna = COALESCE(u.comuna, s.comuna),
--   direccion = COALESCE(u.direccion, s.direccion),
--   fecha_retiro = COALESCE(u.fecha_retiro, s.fecha_retiro),
--   motivo_retiro = COALESCE(u.motivo_retiro, s.motivo_retiro),
--   curso = COALESCE(u.curso, s.curso),
--   estado_std = COALESCE(u.estado_std, s.estado_std),
--   updated_at = now()
-- FROM student_updates u
-- WHERE s.id = u.student_id;
--
-- WITH guardian_field_candidates AS (
--   SELECT
--     target_id,
--     field_name,
--     ARRAY_AGG(DISTINCT staging_value ORDER BY staging_value) AS candidate_values,
--     COUNT(DISTINCT staging_value) AS distinct_value_count
--   FROM staging.v_matricula_14923_guardian_diff
--   GROUP BY target_id, field_name
-- ), guardian_updates AS (
--   SELECT
--     target_id::uuid AS guardian_id,
--     MAX(CASE WHEN field_name = 'first_name' THEN candidate_values[1] END) AS first_name,
--     MAX(CASE WHEN field_name = 'apellido_paterno' THEN candidate_values[1] END) AS apellido_paterno,
--     MAX(CASE WHEN field_name = 'apellido_materno' THEN candidate_values[1] END) AS apellido_materno,
--     MAX(CASE WHEN field_name = 'last_name' THEN candidate_values[1] END) AS last_name,
--     MAX(CASE WHEN field_name = 'run' THEN candidate_values[1] END) AS run,
--     MAX(CASE WHEN field_name = 'date_of_birth' THEN candidate_values[1]::date END) AS date_of_birth,
--     MAX(CASE WHEN field_name = 'email' THEN candidate_values[1] END) AS email,
--     MAX(CASE WHEN field_name = 'phone' THEN candidate_values[1] END) AS phone,
--     MAX(CASE WHEN field_name = 'relationship_type' THEN candidate_values[1] END) AS relationship_type,
--     MAX(CASE WHEN field_name = 'nivel_educacional' THEN candidate_values[1] END) AS nivel_educacional,
--     MAX(CASE WHEN field_name = 'comuna' THEN candidate_values[1] END) AS comuna,
--     MAX(CASE WHEN field_name = 'address' THEN candidate_values[1] END) AS address
--   FROM guardian_field_candidates
--   WHERE distinct_value_count = 1
--   GROUP BY target_id
-- )
-- UPDATE public.guardians g
-- SET
--   first_name = COALESCE(u.first_name, g.first_name),
--   apellido_paterno = COALESCE(u.apellido_paterno, g.apellido_paterno),
--   apellido_materno = COALESCE(u.apellido_materno, g.apellido_materno),
--   last_name = COALESCE(u.last_name, g.last_name),
--   run = COALESCE(u.run, g.run),
--   date_of_birth = COALESCE(u.date_of_birth, g.date_of_birth),
--   email = COALESCE(u.email, g.email),
--   phone = COALESCE(u.phone, g.phone),
--   relationship_type = COALESCE(u.relationship_type, g.relationship_type),
--   nivel_educacional = COALESCE(u.nivel_educacional, g.nivel_educacional),
--   comuna = COALESCE(u.comuna, g.comuna),
--   address = COALESCE(u.address, g.address),
--   updated_at = now()
-- FROM guardian_updates u
-- WHERE g.id = u.guardian_id;
--
-- WITH missing_links AS (
--   SELECT DISTINCT
--     n.student_id,
--     n.guardian_id
--   FROM staging.v_matricula_14923_apoderados_normalized n
--   JOIN staging.v_matricula_14923_student_guardian_link_diff d
--     ON d.source_row_number = n.source_row_number
--   WHERE n.ready_for_diff
-- )
-- INSERT INTO public.student_guardian (student_id, guardian_id)
-- SELECT l.student_id, l.guardian_id
-- FROM missing_links l
-- WHERE NOT EXISTS (
--   SELECT 1
--   FROM public.student_guardian sg
--   WHERE sg.student_id = l.student_id
--     AND sg.guardian_id = l.guardian_id
-- );
--
-- COMMIT;
