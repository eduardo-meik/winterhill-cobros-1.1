-- Diff views for staging package 14923.
-- Read-only against production tables.

BEGIN;

CREATE OR REPLACE VIEW staging.v_matricula_14923_student_diff AS
WITH ready AS (
  SELECT *
  FROM staging.v_matricula_14923_estudiantes_normalized
  WHERE ready_for_diff
)
SELECT
  'students'::text AS entity_name,
  r.source_row_number,
  r.run_completo_norm AS match_key,
  s.id AS target_id,
  d.field_name,
  d.current_value,
  d.staging_value,
  d.change_reason
FROM ready r
JOIN public.students s ON s.id = r.student_id
CROSS JOIN LATERAL (
  VALUES
    ('first_name', NULLIF(BTRIM(COALESCE(s.first_name, '')), ''), r.first_name_norm, 'direct_exact'),
    ('apellido_paterno', NULLIF(BTRIM(COALESCE(s.apellido_paterno, '')), ''), r.apellido_paterno_norm, 'direct_exact'),
    ('apellido_materno', NULLIF(BTRIM(COALESCE(s.apellido_materno, '')), ''), r.apellido_materno_norm, 'direct_exact'),
    ('whole_name', NULLIF(BTRIM(COALESCE(s.whole_name, '')), ''), r.whole_name_norm, 'derived_from_name_parts'),
    ('run', NULLIF(BTRIM(COALESCE(s.run, '')), ''), r.run_completo_norm, 'derived_run_number_plus_dv'),
    ('run_numero', NULLIF(s.run_numero::text, ''), r.run_numero_norm, 'normalized_digits_only'),
    ('run_verificador', NULLIF(BTRIM(COALESCE(s.run_verificador, '')), ''), r.run_dv_norm, 'direct_exact'),
    ('fecha_matricula', TO_CHAR(s.fecha_matricula, 'YYYY-MM-DD'), TO_CHAR(r.fecha_matricula_norm, 'YYYY-MM-DD'), 'parsed_date'),
    ('date_of_birth', TO_CHAR(s.date_of_birth, 'YYYY-MM-DD'), TO_CHAR(r.fecha_nacimiento_norm, 'YYYY-MM-DD'), 'parsed_date'),
    ('genero', NULLIF(BTRIM(COALESCE(s.genero, '')), ''), r.genero_norm, 'direct_exact'),
    ('nacionalidad', NULLIF(BTRIM(COALESCE(s.nacionalidad, '')), ''), r.nacionalidad_norm, 'direct_exact'),
    ('email', NULLIF(LOWER(BTRIM(COALESCE(s.email, ''))), ''), r.email_norm, 'normalized_lowercase'),
    ('repite_curso_actual', NULLIF(BTRIM(COALESCE(s.repite_curso_actual, '')), ''), r.repite_curso_actual_norm, 'normalized_yes_no'),
    ('comuna', NULLIF(BTRIM(COALESCE(s.comuna, '')), ''), r.comuna_norm, 'direct_exact'),
    ('direccion', NULLIF(BTRIM(COALESCE(s.direccion, '')), ''), r.direccion_norm, 'direct_exact'),
    ('fecha_retiro', TO_CHAR(s.fecha_retiro, 'YYYY-MM-DD'), TO_CHAR(r.fecha_retiro_norm, 'YYYY-MM-DD'), 'parsed_date'),
    ('motivo_retiro', NULLIF(BTRIM(COALESCE(s.motivo_retiro, '')), ''), r.motivo_retiro_norm, 'direct_exact'),
    ('curso', COALESCE(s.curso::text, ''), COALESCE(r.course_id::text, ''), 'resolved_from_curso_plus_anio'),
    ('estado_std', NULLIF(BTRIM(COALESCE(s.estado_std, '')), ''), r.estado_std_norm, 'mapped_vigente_retirado')
) AS d(field_name, current_value, staging_value, change_reason)
WHERE d.staging_value IS NOT NULL
  AND staging.norm_text(d.current_value) IS DISTINCT FROM staging.norm_text(d.staging_value);

CREATE OR REPLACE VIEW staging.v_matricula_14923_guardian_diff AS
WITH ready AS (
  SELECT *
  FROM staging.v_matricula_14923_apoderados_normalized
  WHERE ready_for_diff
)
SELECT
  'guardians'::text AS entity_name,
  r.source_row_number,
  r.guardian_run_completo_norm AS match_key,
  g.id AS target_id,
  d.field_name,
  d.current_value,
  d.staging_value,
  d.change_reason
FROM ready r
JOIN public.guardians g ON g.id = r.guardian_id
CROSS JOIN LATERAL (
  VALUES
    ('first_name', NULLIF(BTRIM(COALESCE(g.first_name, '')), ''), r.guardian_first_name_norm, 'direct_exact'),
    ('apellido_paterno', NULLIF(BTRIM(COALESCE(g.apellido_paterno, '')), ''), r.guardian_apellido_paterno_norm, 'direct_exact'),
    ('apellido_materno', NULLIF(BTRIM(COALESCE(g.apellido_materno, '')), ''), r.guardian_apellido_materno_norm, 'direct_exact'),
    ('last_name', NULLIF(BTRIM(COALESCE(g.last_name, '')), ''), r.guardian_last_name_norm, 'derived_from_apellidos'),
    ('run', NULLIF(BTRIM(COALESCE(g.run, '')), ''), r.guardian_run_completo_norm, 'derived_run_number_plus_dv'),
    ('date_of_birth', TO_CHAR(g.date_of_birth, 'YYYY-MM-DD'), TO_CHAR(r.guardian_date_of_birth_norm, 'YYYY-MM-DD'), 'parsed_date'),
    ('email', NULLIF(LOWER(BTRIM(COALESCE(g.email, ''))), ''), r.guardian_email_norm, 'normalized_lowercase'),
    ('phone', NULLIF(BTRIM(COALESCE(g.phone, '')), ''), r.guardian_phone_norm, 'direct_exact'),
    ('relationship_type', NULLIF(BTRIM(COALESCE(g.relationship_type, '')), ''), r.relationship_type_norm, 'direct_exact'),
    ('nivel_educacional', NULLIF(BTRIM(COALESCE(g.nivel_educacional, '')), ''), r.nivel_educacional_norm, 'direct_exact'),
    ('comuna', NULLIF(BTRIM(COALESCE(g.comuna, '')), ''), r.guardian_comuna_norm, 'direct_exact'),
    ('address', NULLIF(BTRIM(COALESCE(g.address, '')), ''), r.guardian_address_norm, 'direct_exact')
) AS d(field_name, current_value, staging_value, change_reason)
WHERE d.staging_value IS NOT NULL
  AND staging.norm_text(d.current_value) IS DISTINCT FROM staging.norm_text(d.staging_value);

CREATE OR REPLACE VIEW staging.v_matricula_14923_student_guardian_link_diff AS
WITH ready AS (
  SELECT *
  FROM staging.v_matricula_14923_apoderados_normalized
  WHERE ready_for_diff
)
SELECT
  'student_guardian'::text AS entity_name,
  r.source_row_number,
  r.student_run_completo_norm || ' -> ' || r.guardian_run_completo_norm AS match_key,
  NULL::uuid AS target_id,
  'link_exists'::text AS field_name,
  'NO'::text AS current_value,
  'YES'::text AS staging_value,
  'missing_student_guardian_link'::text AS change_reason
FROM ready r
LEFT JOIN public.student_guardian sg
  ON sg.student_id = r.student_id
 AND sg.guardian_id = r.guardian_id
WHERE sg.student_id IS NULL;

CREATE OR REPLACE VIEW staging.v_matricula_14923_diff_all AS
SELECT * FROM staging.v_matricula_14923_student_diff
UNION ALL
SELECT * FROM staging.v_matricula_14923_guardian_diff
UNION ALL
SELECT * FROM staging.v_matricula_14923_student_guardian_link_diff;

COMMIT;

-- Suggested review queries:
-- SELECT * FROM staging.v_matricula_14923_student_diff ORDER BY source_row_number, field_name;
-- SELECT * FROM staging.v_matricula_14923_guardian_diff ORDER BY source_row_number, field_name;
-- SELECT * FROM staging.v_matricula_14923_student_guardian_link_diff ORDER BY source_row_number;
-- SELECT * FROM staging.v_matricula_14923_diff_all ORDER BY entity_name, source_row_number, field_name;