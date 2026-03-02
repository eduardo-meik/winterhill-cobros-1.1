-- ============================================================================
-- Rename estado_std values to match their real meaning
-- ============================================================================
-- Current values → New values:
--   PRE_MATRICULADO → PRE_MATRICULADO  (no change)
--   MATRICULADO     → CONFIRMADO       (was displayed as "Pre-Matriculado" 🤯)
--   ACTIVO          → CURSANDO         (was displayed as "Confirmado")
--   RETIRADO        → RETIRADO         (no change)
-- ============================================================================

BEGIN;

-- ──────────────────────────────────────────────────────────────────────────────
-- 1. Drop existing CHECK constraint
-- ──────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.students DROP CONSTRAINT IF EXISTS students_estado_std_check;
ALTER TABLE public.students DROP CONSTRAINT IF EXISTS check_estado_std;

-- ──────────────────────────────────────────────────────────────────────────────
-- 2. Update data in-place
-- ──────────────────────────────────────────────────────────────────────────────
UPDATE public.students SET estado_std = 'CONFIRMADO' WHERE estado_std = 'MATRICULADO';
UPDATE public.students SET estado_std = 'CURSANDO'   WHERE estado_std = 'ACTIVO';

-- ──────────────────────────────────────────────────────────────────────────────
-- 3. Add new CHECK constraint with renamed values
-- ──────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.students
  ADD CONSTRAINT students_estado_std_check
  CHECK (estado_std IN ('PRE_MATRICULADO', 'CONFIRMADO', 'CURSANDO', 'RETIRADO'));

-- ──────────────────────────────────────────────────────────────────────────────
-- 4. Fix actualizar_estado_std function (bug: was updating wrong column)
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.actualizar_estado_std(
    p_student_id uuid,
    p_new_status text
)
RETURNS void
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.students
    SET estado_std = p_new_status,
        updated_at = now()
    WHERE id = p_student_id;
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- 5. Recreate v_current_student_courses view with new value
-- ──────────────────────────────────────────────────────────────────────────────
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
WHERE UPPER(s.estado_std) = 'CURSANDO' OR s.estado_std IS NULL;

COMMENT ON VIEW public.v_current_student_courses IS
'Helper view: Shows all active (CURSANDO) students with their current year course assignment.';

GRANT SELECT ON public.v_current_student_courses TO authenticated;

-- ──────────────────────────────────────────────────────────────────────────────
-- 6. Update finalize_enrollment to use new values
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_enrollment record;
  v_plan       jsonb;
  v_cuotas     jsonb;
  v_year       int;
  v_dry_run    boolean;
  v_students   int;
  v_created    int := 0;
  v_skipped    int := 0;
  v_uid        uuid;
  v_summary    jsonb;
  v_folio      text := null;
  r_es         record;
  r_cuota      record;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_enrollment FROM public.enrollments WHERE id = p_enrollment_id;
  IF v_enrollment IS NULL THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;

  v_dry_run := COALESCE((p_options->>'dry_run')::boolean, true);
  v_year    := v_enrollment.year;

  SELECT count(*) INTO v_students
    FROM public.enrollment_students
   WHERE enrollment_id = p_enrollment_id;

  v_plan := v_enrollment.payment_plan;
  IF v_plan IS NULL AND p_options ? 'payment_plan' THEN
    v_plan := p_options->'payment_plan';
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'No payment plan found for enrollment %', p_enrollment_id;
  END IF;

  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_array_length(v_cuotas) = 0 THEN
    DECLARE
      v_num   int := COALESCE((v_plan->>'numero_cuotas')::int, 10);
      v_amt   numeric := COALESCE((v_plan->>'monto_cuota')::numeric, 0);
      v_first date := COALESCE((v_plan->>'primera_cuota')::date, make_date(v_year, 3, 1));
      i       int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      WHILE i <= v_num LOOP
        v_synth := v_synth || jsonb_build_object(
          'numero', i,
          'amount', v_amt,
          'due_date', (v_first + make_interval(months := i-1))::date
        );
        i := i + 1;
      END LOOP;
      v_cuotas := v_synth;
    END;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id, es.curso_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          ON CONFLICT (student_id, year_academico, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    v_folio := 'ENR-' || v_year || '-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || substring(p_enrollment_id::text, 1, 8);

    UPDATE public.enrollments
       SET status = 'completed',
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    FOR r_es IN
      SELECT es.student_id, es.curso_id
        FROM public.enrollment_students es
       WHERE es.enrollment_id = p_enrollment_id
         AND es.curso_id IS NOT NULL
    LOOP
      UPDATE public.students
         SET curso = r_es.curso_id,
             estado_std = 'CONFIRMADO',
             updated_at = now()
       WHERE id = r_es.student_id;

      INSERT INTO public.student_academic_records (
        student_id, curso_id, year_academico, fecha_inicio, estado, enrollment_id, created_by
      ) VALUES (
        r_es.student_id, r_es.curso_id, v_year, CURRENT_DATE, 'activo', p_enrollment_id, v_uid
      )
      ON CONFLICT (student_id, year_academico) DO UPDATE
        SET curso_id = EXCLUDED.curso_id,
            enrollment_id = EXCLUDED.enrollment_id,
            updated_at = now(),
            updated_by = v_uid;
    END LOOP;

    UPDATE public.students
       SET estado_std = 'CONFIRMADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
          AND es.curso_id IS NULL
     )
       AND COALESCE(estado_std, '') <> 'CONFIRMADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary,
    'folio', v_folio,
    'year', v_year
  );
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- 7. Update generate_libro_matricula_report CASE mapping
-- ──────────────────────────────────────────────────────────────────────────────
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
SET search_path = public
AS $$
DECLARE
  v_year INTEGER;
  v_estado VARCHAR;
  v_status VARCHAR;
BEGIN
  v_year := NULLIF(p_year, 0);
  v_estado := NULLIF(TRIM(p_estado), '');
  v_status := NULLIF(TRIM(p_status), '');

  RETURN QUERY
  SELECT
    ROW_NUMBER() OVER (ORDER BY e.created_at ASC)::BIGINT,
    COALESCE(
      CASE WHEN e.year IS NOT NULL AND e.year > 0 THEN e.year
           ELSE EXTRACT(YEAR FROM e.created_at)::INTEGER
      END,
      EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER
    ),
    e.created_at,
    COALESCE(c.nivel, '')::TEXT,
    COALESCE(c.nom_curso, '')::TEXT,
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
    COALESCE(g2.first_name || ' ' || COALESCE(g2.apellido_paterno, '') || ' ' || COALESCE(g2.apellido_materno, ''), '')::TEXT,
    COALESCE(g2.run, '')::TEXT,
    COALESCE(TO_CHAR(g2.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g2.phone, '')::TEXT,
    COALESCE(g2.email, '')::TEXT,
    COALESCE(TO_CHAR(s.fecha_retiro, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(s.motivo_retiro, '')::TEXT,
    CASE
      WHEN s.estado_std = 'PRE_MATRICULADO' THEN 'Matrícula en proceso'
      WHEN s.estado_std = 'CONFIRMADO'      THEN 'Confirmado para año escolar'
      WHEN s.estado_std = 'CURSANDO'        THEN 'Cursando'
      WHEN s.estado_std = 'RETIRADO'        THEN 'Retirado'
      ELSE COALESCE(s.estado_std, '')
    END::TEXT

  FROM public.students s
  INNER JOIN public.enrollment_students es ON s.id = es.student_id
  INNER JOIN public.enrollments e ON es.enrollment_id = e.id
  LEFT JOIN public.cursos c ON s.curso = c.id
  LEFT JOIN LATERAL (
    SELECT g.*, sg.guardian_role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND (sg.is_primary = true OR sg.guardian_role = 'titular')
    ORDER BY sg.is_primary DESC NULLS LAST, sg.created_at ASC
    LIMIT 1
  ) g1 ON true
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

COMMENT ON FUNCTION public.generate_libro_matricula_report IS
'Genera reporte completo del Libro de Matrícula.
Filtros:
- p_year (año académico)
- p_estado (PRE_MATRICULADO, CONFIRMADO, CURSANDO, RETIRADO)
- p_status (draft, pending, completed, rejected)';

COMMIT;
