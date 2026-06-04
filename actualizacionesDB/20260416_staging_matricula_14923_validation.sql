-- Validation views and queries for staging package 14923.
-- This file does not modify production data.

BEGIN;

CREATE OR REPLACE VIEW staging.v_matricula_14923_validation_issues AS
SELECT
  'Estudiantes'::text AS sheet_name,
  source_row_number,
  COALESCE(run_completo_norm, run_estudiante) AS match_key,
  'RUN_INVALIDO'::text AS issue_code,
  'RUN Estudiante no pudo normalizarse a solo dígitos + DV.'::text AS issue_detail
FROM staging.v_matricula_14923_estudiantes_normalized
WHERE run_numero_norm IS NULL

UNION ALL

SELECT
  'Estudiantes',
  source_row_number,
  COALESCE(run_completo_norm, run_estudiante),
  'STUDENT_NOT_FOUND',
  'No existe un student único en producción para el RUN del archivo.'
FROM staging.v_matricula_14923_estudiantes_normalized
WHERE run_numero_norm IS NOT NULL
  AND COALESCE(student_match_count, 0) = 0

UNION ALL

SELECT
  'Estudiantes',
  source_row_number,
  COALESCE(run_completo_norm, run_estudiante),
  'STUDENT_AMBIGUOUS',
  'El RUN del archivo coincide con más de un student en producción.'
FROM staging.v_matricula_14923_estudiantes_normalized
WHERE COALESCE(student_match_count, 0) > 1

UNION ALL

SELECT
  'Estudiantes',
  source_row_number,
  COALESCE(run_completo_norm, run_estudiante),
  'COURSE_NOT_FOUND',
  'No se pudo resolver cursos.id con Curso + Año.'
FROM staging.v_matricula_14923_estudiantes_normalized
WHERE curso_key_norm IS NOT NULL
  AND anio_norm IS NOT NULL
  AND COALESCE(course_match_count, 0) = 0

UNION ALL

SELECT
  'Estudiantes',
  source_row_number,
  COALESCE(run_completo_norm, run_estudiante),
  'COURSE_AMBIGUOUS',
  'Curso + Año coincide con más de un curso en producción.'
FROM staging.v_matricula_14923_estudiantes_normalized
WHERE COALESCE(course_match_count, 0) > 1

UNION ALL

SELECT
  'Estudiantes',
  source_row_number,
  COALESCE(run_completo_norm, run_estudiante),
  'INVALID_FECHA_MATRICULA',
  'Fecha de Matrícula tiene formato inválido.'
FROM staging.v_matricula_14923_estudiantes_normalized
WHERE NULLIF(BTRIM(COALESCE(fecha_matricula_raw, '')), '') IS NOT NULL
  AND fecha_matricula_norm IS NULL

UNION ALL

SELECT
  'Estudiantes',
  source_row_number,
  COALESCE(run_completo_norm, run_estudiante),
  'INVALID_FECHA_NACIMIENTO',
  'Fecha de Nacimiento tiene formato inválido.'
FROM staging.v_matricula_14923_estudiantes_normalized
WHERE NULLIF(BTRIM(COALESCE(fecha_nacimiento_raw, '')), '') IS NOT NULL
  AND fecha_nacimiento_norm IS NULL

UNION ALL

SELECT
  'Estudiantes',
  source_row_number,
  COALESCE(run_completo_norm, run_estudiante),
  'INVALID_FECHA_RETIRO',
  'Fecha de Retiro tiene formato inválido.'
FROM staging.v_matricula_14923_estudiantes_normalized
WHERE NULLIF(BTRIM(COALESCE(fecha_retiro_raw, '')), '') IS NOT NULL
  AND fecha_retiro_norm IS NULL

UNION ALL

SELECT
  'Apoderados',
  source_row_number,
  COALESCE(guardian_run_completo_norm, run_apoderado),
  'GUARDIAN_RUN_INVALIDO',
  'RUN Apoderado no pudo normalizarse a solo dígitos + DV.'
FROM staging.v_matricula_14923_apoderados_normalized
WHERE guardian_run_numero_norm IS NULL

UNION ALL

SELECT
  'Apoderados',
  source_row_number,
  COALESCE(student_run_completo_norm, run_estudiante),
  'APODERADO_STUDENT_NOT_FOUND',
  'La fila de apoderado no encuentra un student único en producción.'
FROM staging.v_matricula_14923_apoderados_normalized
WHERE student_run_numero_norm IS NOT NULL
  AND COALESCE(student_match_count, 0) = 0

UNION ALL

SELECT
  'Apoderados',
  source_row_number,
  COALESCE(student_run_completo_norm, run_estudiante),
  'APODERADO_STUDENT_AMBIGUOUS',
  'La fila de apoderado coincide con más de un student en producción.'
FROM staging.v_matricula_14923_apoderados_normalized
WHERE COALESCE(student_match_count, 0) > 1

UNION ALL

SELECT
  'Apoderados',
  source_row_number,
  COALESCE(guardian_run_completo_norm, run_apoderado),
  'GUARDIAN_NOT_FOUND',
  'No existe un guardian único en producción para el RUN del archivo.'
FROM staging.v_matricula_14923_apoderados_normalized
WHERE guardian_run_numero_norm IS NOT NULL
  AND COALESCE(guardian_match_count, 0) = 0

UNION ALL

SELECT
  'Apoderados',
  source_row_number,
  COALESCE(guardian_run_completo_norm, run_apoderado),
  'GUARDIAN_AMBIGUOUS',
  'El RUN de apoderado coincide con más de un guardian en producción.'
FROM staging.v_matricula_14923_apoderados_normalized
WHERE COALESCE(guardian_match_count, 0) > 1

UNION ALL

SELECT
  'Apoderados',
  source_row_number,
  COALESCE(guardian_run_completo_norm, run_apoderado),
  'INVALID_GUARDIAN_BIRTH_DATE',
  'Fecha de Nacimiento Apoderado tiene formato inválido.'
FROM staging.v_matricula_14923_apoderados_normalized
WHERE NULLIF(BTRIM(COALESCE(fecha_nacimiento_apoderado_raw, '')), '') IS NOT NULL
  AND guardian_date_of_birth_norm IS NULL;

CREATE OR REPLACE VIEW staging.v_matricula_14923_validation_summary AS
SELECT
  sheet_name,
  issue_code,
  COUNT(*) AS issue_count
FROM staging.v_matricula_14923_validation_issues
GROUP BY sheet_name, issue_code

UNION ALL

SELECT
  'Estudiantes' AS sheet_name,
  'READY_FOR_DIFF' AS issue_code,
  COUNT(*) AS issue_count
FROM staging.v_matricula_14923_estudiantes_normalized
WHERE ready_for_diff

UNION ALL

SELECT
  'Apoderados' AS sheet_name,
  'READY_FOR_DIFF' AS issue_code,
  COUNT(*) AS issue_count
FROM staging.v_matricula_14923_apoderados_normalized
WHERE ready_for_diff;

COMMIT;

-- Suggested checks after import:
-- SELECT * FROM staging.v_matricula_14923_validation_summary ORDER BY sheet_name, issue_code;
-- SELECT * FROM staging.v_matricula_14923_validation_issues ORDER BY sheet_name, source_row_number, issue_code;