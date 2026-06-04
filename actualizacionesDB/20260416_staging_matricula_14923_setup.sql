-- Safe staging package for workbook:
-- 14923 - Registro de matrícula - Colegio Winterhill - 13-04-2026 - 11_59.xlsx
--
-- This file is intentionally read-only against production tables.
-- It only creates:
--   1) a dedicated staging schema
--   2) raw import tables
--   3) normalization helpers
--   4) normalized views used by validation and diff scripts

BEGIN;

CREATE SCHEMA IF NOT EXISTS staging;

CREATE OR REPLACE FUNCTION staging.norm_digits(p_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $$
  SELECT NULLIF(LTRIM(REGEXP_REPLACE(COALESCE(p_text, ''), '[^0-9]', '', 'g'), '0'), '')
$$;

CREATE OR REPLACE FUNCTION staging.norm_text(p_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $$
  SELECT NULLIF(
    BTRIM(
      UPPER(
        TRANSLATE(
          COALESCE(p_text, ''),
          'ÁÉÍÓÚÜáéíóúüÑñ',
          'AEIOUUAEIOUUNN'
        )
      )
    ),
    ''
  )
$$;

CREATE OR REPLACE FUNCTION staging.parse_ddmmyyyy(p_text text)
RETURNS date
LANGUAGE plpgsql
IMMUTABLE
SET search_path = pg_catalog
AS $$
DECLARE
  cleaned text := NULLIF(BTRIM(COALESCE(p_text, '')), '');
BEGIN
  IF cleaned IS NULL THEN
    RETURN NULL;
  END IF;

  IF cleaned ~ '^\d{2}/\d{2}/\d{4}$' THEN
    RETURN TO_DATE(cleaned, 'DD/MM/YYYY');
  END IF;

  RETURN NULL;
END;
$$;

CREATE TABLE IF NOT EXISTS staging.matricula_14923_estudiantes_raw (
  source_row_number integer PRIMARY KEY,
  rbd text,
  anio text,
  colegio text,
  local_escolar text,
  codigo_nivel_educativo text,
  nivel_educativo text,
  curso text,
  numero_lista text,
  numero_matricula text,
  fecha_matricula_raw text,
  run_estudiante text,
  run_dv text,
  apellido_paterno text,
  apellido_materno text,
  nombres text,
  estado_estudiante text,
  fecha_nacimiento_raw text,
  genero text,
  origen_indigena text,
  nacionalidad text,
  celular_estudiante text,
  email_estudiante text,
  pie text,
  nee_tipo text,
  diagnostico text,
  pro_retencion text,
  sep text,
  repite_curso_actual text,
  ingreso_anio_establecimiento text,
  observaciones text,
  motivo_ingreso_tardio text,
  region text,
  comuna text,
  direccion text,
  prevision text,
  grupo_sanguineo text,
  estatura_cm text,
  peso_kg text,
  alertas_salud text,
  embarazo_estudiante text,
  fecha_retiro_raw text,
  razon_retiro text,
  foto text,
  source_file text DEFAULT '14923 - Registro de matrícula - Colegio Winterhill - 13-04-2026 - 11_59.xlsx',
  source_sheet text DEFAULT 'Estudiantes',
  imported_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS staging.matricula_14923_apoderados_raw (
  source_row_number integer PRIMARY KEY,
  rbd text,
  anio text,
  colegio text,
  local_escolar text,
  codigo_nivel_educativo text,
  nivel_educativo text,
  curso text,
  numero_lista text,
  numero_matricula text,
  fecha_matricula_raw text,
  run_estudiante text,
  run_estudiante_dv text,
  estudiante_apellido_paterno text,
  estudiante_apellido_materno text,
  estudiante_nombres text,
  estado_estudiante text,
  run_apoderado text,
  run_apoderado_dv text,
  apoderado_apellido_paterno text,
  apoderado_apellido_materno text,
  apoderado_nombres text,
  fecha_nacimiento_apoderado_raw text,
  email_apoderado text,
  telefono_apoderado text,
  registrado_kimche text,
  relacion_con_estudiante text,
  puede_retirar text,
  contacto_emergencia text,
  vive_con_estudiante text,
  nivel_educacional text,
  situacion_laboral text,
  lugar_trabajo text,
  region_apoderado text,
  comuna_apoderado text,
  direccion_apoderado text,
  source_file text DEFAULT '14923 - Registro de matrícula - Colegio Winterhill - 13-04-2026 - 11_59.xlsx',
  source_sheet text DEFAULT 'Apoderados',
  imported_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_staging_m14923_estudiantes_run
  ON staging.matricula_14923_estudiantes_raw (run_estudiante);

CREATE INDEX IF NOT EXISTS idx_staging_m14923_estudiantes_curso_anio
  ON staging.matricula_14923_estudiantes_raw (curso, anio);

CREATE INDEX IF NOT EXISTS idx_staging_m14923_apoderados_student_run
  ON staging.matricula_14923_apoderados_raw (run_estudiante);

CREATE INDEX IF NOT EXISTS idx_staging_m14923_apoderados_guardian_run
  ON staging.matricula_14923_apoderados_raw (run_apoderado);

CREATE OR REPLACE VIEW staging.v_matricula_14923_estudiantes_normalized AS
WITH base AS (
  SELECT
    r.*,
    staging.norm_digits(r.run_estudiante) AS run_numero_norm,
    NULLIF(UPPER(BTRIM(COALESCE(r.run_dv, ''))), '') AS run_dv_norm,
    CASE
      WHEN staging.norm_digits(r.run_estudiante) IS NOT NULL
       AND NULLIF(BTRIM(COALESCE(r.run_dv, '')), '') IS NOT NULL
      THEN staging.norm_digits(r.run_estudiante) || '-' || UPPER(BTRIM(r.run_dv))
      ELSE NULL
    END AS run_completo_norm,
    staging.parse_ddmmyyyy(r.fecha_matricula_raw) AS fecha_matricula_norm,
    staging.parse_ddmmyyyy(r.fecha_nacimiento_raw) AS fecha_nacimiento_norm,
    staging.parse_ddmmyyyy(r.fecha_retiro_raw) AS fecha_retiro_norm,
    CASE
      WHEN NULLIF(BTRIM(COALESCE(r.anio, '')), '') ~ '^\d{4}$' THEN r.anio::integer
      ELSE NULL
    END AS anio_norm,
    NULLIF(BTRIM(COALESCE(r.nombres, '')), '') AS first_name_norm,
    NULLIF(BTRIM(COALESCE(r.apellido_paterno, '')), '') AS apellido_paterno_norm,
    NULLIF(BTRIM(COALESCE(r.apellido_materno, '')), '') AS apellido_materno_norm,
    NULLIF(
      BTRIM(
        CONCAT_WS(
          ' ',
          NULLIF(BTRIM(COALESCE(r.nombres, '')), ''),
          NULLIF(BTRIM(COALESCE(r.apellido_paterno, '')), ''),
          NULLIF(BTRIM(COALESCE(r.apellido_materno, '')), '')
        )
      ),
      ''
    ) AS whole_name_norm,
    NULLIF(BTRIM(COALESCE(r.genero, '')), '') AS genero_norm,
    NULLIF(BTRIM(COALESCE(r.nacionalidad, '')), '') AS nacionalidad_norm,
    CASE
      WHEN NULLIF(BTRIM(COALESCE(r.email_estudiante, '')), '') IS NOT NULL THEN LOWER(BTRIM(r.email_estudiante))
      ELSE NULL
    END AS email_norm,
    CASE
      WHEN staging.norm_text(r.repite_curso_actual) IN ('SI', 'NO') THEN staging.norm_text(r.repite_curso_actual)
      ELSE NULL
    END AS repite_curso_actual_norm,
    NULLIF(BTRIM(COALESCE(r.comuna, '')), '') AS comuna_norm,
    NULLIF(BTRIM(COALESCE(r.direccion, '')), '') AS direccion_norm,
    NULLIF(BTRIM(COALESCE(r.razon_retiro, '')), '') AS motivo_retiro_norm,
    CASE
      WHEN staging.norm_text(r.estado_estudiante) = 'VIGENTE' THEN 'ACTIVO'
      WHEN staging.norm_text(r.estado_estudiante) = 'RETIRADO' THEN 'RETIRADO'
      ELSE NULL
    END AS estado_std_norm,
    staging.norm_text(r.curso) AS curso_key_norm,
    staging.norm_text(r.estado_estudiante) AS estado_estudiante_key
  FROM staging.matricula_14923_estudiantes_raw r
),
student_resolved AS (
  SELECT
    b.*,
    sm.student_id,
    sm.student_match_count,
    sm.owner_id AS student_owner_id,
    sm.current_run AS student_run_current,
    sm.current_whole_name,
    sm.current_course_id
  FROM base b
  LEFT JOIN LATERAL (
    SELECT
      s.id AS student_id,
      COUNT(*) OVER () AS student_match_count,
      s.owner_id,
      s.run AS current_run,
      s.whole_name AS current_whole_name,
      s.curso AS current_course_id
    FROM public.students s
    WHERE (
      staging.norm_digits(s.run_numero::text) = b.run_numero_norm
      OR staging.norm_digits(s.run) = b.run_numero_norm
    )
    ORDER BY s.updated_at DESC NULLS LAST, s.created_at DESC NULLS LAST, s.id
    LIMIT 1
  ) sm ON TRUE
)
SELECT
  sr.*,
  cm.course_id,
  cm.course_match_count,
  cm.matched_course_name,
  cm.matched_course_year,
  (
    sr.run_numero_norm IS NOT NULL
    AND COALESCE(sr.student_match_count, 0) = 1
    AND COALESCE(cm.course_match_count, 0) = 1
  ) AS ready_for_diff
FROM student_resolved sr
LEFT JOIN LATERAL (
  SELECT
    c.id AS course_id,
    COUNT(*) OVER () AS course_match_count,
    c.nom_curso AS matched_course_name,
    c.year_academico AS matched_course_year
  FROM public.cursos c
  WHERE staging.norm_text(c.nom_curso) = sr.curso_key_norm
    AND c.year_academico = sr.anio_norm
  ORDER BY c.id
  LIMIT 1
) cm ON TRUE;

CREATE OR REPLACE VIEW staging.v_matricula_14923_apoderados_normalized AS
WITH base AS (
  SELECT
    r.*,
    staging.norm_digits(r.run_estudiante) AS student_run_numero_norm,
    NULLIF(UPPER(BTRIM(COALESCE(r.run_estudiante_dv, ''))), '') AS student_run_dv_norm,
    CASE
      WHEN staging.norm_digits(r.run_estudiante) IS NOT NULL
       AND NULLIF(BTRIM(COALESCE(r.run_estudiante_dv, '')), '') IS NOT NULL
      THEN staging.norm_digits(r.run_estudiante) || '-' || UPPER(BTRIM(r.run_estudiante_dv))
      ELSE NULL
    END AS student_run_completo_norm,
    staging.norm_digits(r.run_apoderado) AS guardian_run_numero_norm,
    NULLIF(UPPER(BTRIM(COALESCE(r.run_apoderado_dv, ''))), '') AS guardian_run_dv_norm,
    CASE
      WHEN staging.norm_digits(r.run_apoderado) IS NOT NULL
       AND NULLIF(BTRIM(COALESCE(r.run_apoderado_dv, '')), '') IS NOT NULL
      THEN staging.norm_digits(r.run_apoderado) || '-' || UPPER(BTRIM(r.run_apoderado_dv))
      ELSE NULL
    END AS guardian_run_completo_norm,
    staging.parse_ddmmyyyy(r.fecha_nacimiento_apoderado_raw) AS guardian_date_of_birth_norm,
    CASE
      WHEN NULLIF(BTRIM(COALESCE(r.email_apoderado, '')), '') IS NOT NULL THEN LOWER(BTRIM(r.email_apoderado))
      ELSE NULL
    END AS guardian_email_norm,
    NULLIF(BTRIM(COALESCE(r.telefono_apoderado, '')), '') AS guardian_phone_norm,
    NULLIF(BTRIM(COALESCE(r.apoderado_nombres, '')), '') AS guardian_first_name_norm,
    NULLIF(BTRIM(COALESCE(r.apoderado_apellido_paterno, '')), '') AS guardian_apellido_paterno_norm,
    NULLIF(BTRIM(COALESCE(r.apoderado_apellido_materno, '')), '') AS guardian_apellido_materno_norm,
    NULLIF(
      BTRIM(
        CONCAT_WS(
          ' ',
          NULLIF(BTRIM(COALESCE(r.apoderado_apellido_paterno, '')), ''),
          NULLIF(BTRIM(COALESCE(r.apoderado_apellido_materno, '')), '')
        )
      ),
      ''
    ) AS guardian_last_name_norm,
    NULLIF(BTRIM(COALESCE(r.relacion_con_estudiante, '')), '') AS relationship_type_norm,
    NULLIF(BTRIM(COALESCE(r.nivel_educacional, '')), '') AS nivel_educacional_norm,
    NULLIF(BTRIM(COALESCE(r.comuna_apoderado, '')), '') AS guardian_comuna_norm,
    NULLIF(BTRIM(COALESCE(r.direccion_apoderado, '')), '') AS guardian_address_norm,
    CASE
      WHEN staging.norm_text(r.puede_retirar) IN ('SI', 'NO') THEN staging.norm_text(r.puede_retirar)
      ELSE NULL
    END AS puede_retirar_norm,
    CASE
      WHEN staging.norm_text(r.contacto_emergencia) IN ('SI', 'NO') THEN staging.norm_text(r.contacto_emergencia)
      ELSE NULL
    END AS contacto_emergencia_norm,
    CASE
      WHEN staging.norm_text(r.vive_con_estudiante) IN ('SI', 'NO') THEN staging.norm_text(r.vive_con_estudiante)
      ELSE NULL
    END AS vive_con_estudiante_norm,
    CASE
      WHEN staging.norm_text(r.registrado_kimche) IN ('SI', 'NO') THEN staging.norm_text(r.registrado_kimche)
      ELSE NULL
    END AS registrado_kimche_norm,
    NULLIF(BTRIM(COALESCE(r.situacion_laboral, '')), '') AS situacion_laboral_norm,
    NULLIF(BTRIM(COALESCE(r.lugar_trabajo, '')), '') AS lugar_trabajo_norm,
    NULLIF(BTRIM(COALESCE(r.region_apoderado, '')), '') AS region_apoderado_norm
  FROM staging.matricula_14923_apoderados_raw r
),
student_resolved AS (
  SELECT
    b.*,
    sm.student_id,
    sm.student_match_count,
    sm.student_owner_id,
    sm.student_whole_name
  FROM base b
  LEFT JOIN LATERAL (
    SELECT
      s.id AS student_id,
      COUNT(*) OVER () AS student_match_count,
      s.owner_id AS student_owner_id,
      s.whole_name AS student_whole_name
    FROM public.students s
    WHERE (
      staging.norm_digits(s.run_numero::text) = b.student_run_numero_norm
      OR staging.norm_digits(s.run) = b.student_run_numero_norm
    )
    ORDER BY s.updated_at DESC NULLS LAST, s.created_at DESC NULLS LAST, s.id
    LIMIT 1
  ) sm ON TRUE
),
guardian_resolved AS (
  SELECT
    sr.*,
    gm.guardian_id,
    gm.guardian_match_count,
    gm.guardian_owner_id,
    gm.guardian_run_current
  FROM student_resolved sr
  LEFT JOIN LATERAL (
    SELECT
      g.id AS guardian_id,
      COUNT(*) OVER () AS guardian_match_count,
      g.owner_id AS guardian_owner_id,
      g.run AS guardian_run_current
    FROM public.guardians g
    WHERE (
      staging.norm_digits(g.run) = sr.guardian_run_numero_norm
      OR staging.norm_text(g.run) = staging.norm_text(sr.guardian_run_completo_norm)
    )
    ORDER BY g.updated_at DESC NULLS LAST, g.created_at DESC NULLS LAST, g.id
    LIMIT 1
  ) gm ON TRUE
)
SELECT
  gr.*,
  (
    gr.student_run_numero_norm IS NOT NULL
    AND gr.guardian_run_numero_norm IS NOT NULL
    AND COALESCE(gr.student_match_count, 0) = 1
    AND COALESCE(gr.guardian_match_count, 0) = 1
  ) AS ready_for_diff
FROM guardian_resolved gr;

COMMIT;