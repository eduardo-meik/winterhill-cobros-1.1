-- LOTE 1 - UPSERT SEGURO (students + guardians)
-- Fuente CSV:
-- 1) tmp_excel_analysis/lote1_actualizacion/lote1_students_upsert.csv
-- 2) tmp_excel_analysis/lote1_actualizacion/lote1_guardians_upsert.csv
--
-- Flujo recomendado en Supabase SQL Editor:
-- 1) Crear tablas temporales de staging (bloque A y B)
-- 2) Importar cada CSV a su tabla tmp correspondiente desde Table Editor
-- 3) Ejecutar bloques C y D (upsert)
-- 4) Revisar conteos de control (bloque E)

BEGIN;

-- ============================================================
-- A) STAGING estudiantes
-- ============================================================
CREATE TEMP TABLE tmp_lote1_students (
  run TEXT,
  date_of_birth DATE,
  genero TEXT,
  direccion TEXT,
  comuna TEXT,
  repite_curso_actual BOOLEAN,
  institucion_procedencia TEXT,
  con_quien_vive TEXT,
  curso TEXT,
  source TEXT
);

-- ============================================================
-- B) STAGING apoderados
-- ============================================================
CREATE TEMP TABLE tmp_lote1_guardians (
  run TEXT,
  first_name TEXT,
  last_name TEXT,
  apellido_paterno TEXT,
  apellido_materno TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  comuna TEXT,
  date_of_birth DATE,
  nivel_educacional TEXT,
  family_tie TEXT,
  relationship_type TEXT,
  source TEXT
);

-- ============================================================
-- C) UPSERT students por run
-- ============================================================
UPDATE public.students s
SET
  date_of_birth = COALESCE(t.date_of_birth, s.date_of_birth),
  genero = COALESCE(NULLIF(t.genero, ''), s.genero),
  direccion = COALESCE(NULLIF(t.direccion, ''), s.direccion),
  comuna = COALESCE(NULLIF(t.comuna, ''), s.comuna),
  repite_curso_actual = COALESCE(t.repite_curso_actual, s.repite_curso_actual),
  institucion_procedencia = COALESCE(NULLIF(t.institucion_procedencia, ''), s.institucion_procedencia),
  con_quien_vive = COALESCE(NULLIF(t.con_quien_vive, ''), s.con_quien_vive),
  curso = COALESCE(NULLIF(t.curso, ''), s.curso),
  updated_at = NOW()
FROM tmp_lote1_students t
WHERE s.run = t.run;

-- ============================================================
-- D) UPSERT guardians por run
-- ============================================================
UPDATE public.guardians g
SET
  first_name = COALESCE(NULLIF(t.first_name, ''), g.first_name),
  last_name = COALESCE(NULLIF(t.last_name, ''), g.last_name),
  apellido_paterno = COALESCE(NULLIF(t.apellido_paterno, ''), g.apellido_paterno),
  apellido_materno = COALESCE(NULLIF(t.apellido_materno, ''), g.apellido_materno),
  email = COALESCE(NULLIF(t.email, ''), g.email),
  phone = COALESCE(NULLIF(t.phone, ''), g.phone),
  address = COALESCE(NULLIF(t.address, ''), g.address),
  comuna = COALESCE(NULLIF(t.comuna, ''), g.comuna),
  date_of_birth = COALESCE(t.date_of_birth, g.date_of_birth),
  date_birth = COALESCE(t.date_of_birth, g.date_birth),
  nivel_educacional = COALESCE(NULLIF(t.nivel_educacional, ''), g.nivel_educacional),
  family_tie = COALESCE(NULLIF(t.family_tie, ''), g.family_tie),
  relationship_type = COALESCE(NULLIF(t.relationship_type, ''), g.relationship_type),
  updated_at = NOW()
FROM tmp_lote1_guardians t
WHERE g.run = t.run;

-- ============================================================
-- E) CONTROL
-- ============================================================
SELECT
  (SELECT COUNT(*) FROM tmp_lote1_students) AS staging_students,
  (SELECT COUNT(*) FROM tmp_lote1_guardians) AS staging_guardians,
  (SELECT COUNT(*) FROM public.students s JOIN tmp_lote1_students t ON s.run = t.run) AS students_match_run,
  (SELECT COUNT(*) FROM public.guardians g JOIN tmp_lote1_guardians t ON g.run = t.run) AS guardians_match_run;

COMMIT;
