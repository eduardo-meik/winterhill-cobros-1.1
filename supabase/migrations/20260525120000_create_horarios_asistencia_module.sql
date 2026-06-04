BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE OR REPLACE FUNCTION public.set_updated_at_horarios_asistencia()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_horario_sala_owner()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.sala_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.salas s
    WHERE s.id = NEW.sala_id
      AND s.owner_id = NEW.owner_id
      AND s.activa = true
  ) THEN
    RAISE EXCEPTION 'La sala no existe, no esta activa, o no pertenece al owner especificado.';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS public.salas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  codigo text NOT NULL,
  nombre text NOT NULL,
  capacidad integer,
  sede text,
  activa boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT salas_capacidad_positiva CHECK (capacidad IS NULL OR capacidad > 0),
  CONSTRAINT salas_owner_codigo_uk UNIQUE (owner_id, codigo)
);

CREATE TABLE IF NOT EXISTS public.docentes_horarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rut_docente text NOT NULL,
  bloque_fecha date NOT NULL,
  hora_inicio time NOT NULL,
  hora_fin time NOT NULL,
  sala_id uuid REFERENCES public.salas(id) ON DELETE RESTRICT,
  curso_id uuid REFERENCES public.cursos(id) ON DELETE SET NULL,
  asignatura text,
  rango_horario tsrange GENERATED ALWAYS AS (
    tsrange(
      (bloque_fecha + hora_inicio)::timestamp,
      (bloque_fecha + hora_fin)::timestamp,
      '[)'
    )
  ) STORED,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT docentes_horarios_hora_valida CHECK (hora_fin > hora_inicio),
  CONSTRAINT docentes_horarios_rut_valido CHECK (rut_docente ~* '^[0-9]{7,8}-[0-9kK]$')
);

CREATE TABLE IF NOT EXISTS public.asistencia_marcas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rut_docente text NOT NULL,
  fecha_hora_marca timestamptz NOT NULL,
  tipo_marca text NOT NULL,
  fuente text NOT NULL DEFAULT 'reloj_control',
  archivo_origen text,
  hash_fila text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT asistencia_marcas_tipo_valido CHECK (tipo_marca IN ('entrada', 'salida')),
  CONSTRAINT asistencia_marcas_rut_valido CHECK (rut_docente ~* '^[0-9]{7,8}-[0-9kK]$'),
  CONSTRAINT asistencia_marcas_unique_uk UNIQUE (owner_id, rut_docente, fecha_hora_marca, tipo_marca)
);

CREATE TABLE IF NOT EXISTS public.asistencia_conciliacion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rut_docente text NOT NULL,
  fecha date NOT NULL,
  minutos_planificados integer NOT NULL DEFAULT 0,
  minutos_efectivos integer NOT NULL DEFAULT 0,
  minutos_atraso integer NOT NULL DEFAULT 0,
  minutos_salida_anticipada integer NOT NULL DEFAULT 0,
  tolerancia_minutos integer NOT NULL DEFAULT 1,
  estado text NOT NULL,
  detalle jsonb NOT NULL DEFAULT '{}'::jsonb,
  calculado_en timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT asistencia_conciliacion_rut_valido CHECK (rut_docente ~* '^[0-9]{7,8}-[0-9kK]$'),
  CONSTRAINT asistencia_conciliacion_planificados_nonneg CHECK (minutos_planificados >= 0),
  CONSTRAINT asistencia_conciliacion_efectivos_nonneg CHECK (minutos_efectivos >= 0),
  CONSTRAINT asistencia_conciliacion_atraso_nonneg CHECK (minutos_atraso >= 0),
  CONSTRAINT asistencia_conciliacion_salida_nonneg CHECK (minutos_salida_anticipada >= 0),
  CONSTRAINT asistencia_conciliacion_tol_nonneg CHECK (tolerancia_minutos >= 0),
  CONSTRAINT asistencia_conciliacion_estado_valido CHECK (
    estado IN ('cumplimiento', 'atraso', 'salida_anticipada', 'incompleto', 'sin_horario')
  ),
  CONSTRAINT asistencia_conciliacion_unique_uk UNIQUE (owner_id, rut_docente, fecha)
);

CREATE TABLE IF NOT EXISTS public.asistencia_discrepancias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conciliacion_id uuid NOT NULL REFERENCES public.asistencia_conciliacion(id) ON DELETE CASCADE,
  tipo text NOT NULL,
  severidad text NOT NULL DEFAULT 'media',
  descripcion text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  resuelta boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT asistencia_discrepancias_tipo_valido CHECK (
    tipo IN ('atraso', 'salida_anticipada', 'marca_faltante', 'sin_horario', 'solapamiento')
  ),
  CONSTRAINT asistencia_discrepancias_severidad_valida CHECK (severidad IN ('baja', 'media', 'alta'))
);

ALTER TABLE public.salas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.docentes_horarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asistencia_marcas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asistencia_conciliacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asistencia_discrepancias ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS salas_staff_all ON public.salas;
CREATE POLICY salas_staff_all ON public.salas
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS salas_owner_all ON public.salas;
CREATE POLICY salas_owner_all ON public.salas
  FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS docentes_horarios_staff_all ON public.docentes_horarios;
CREATE POLICY docentes_horarios_staff_all ON public.docentes_horarios
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS docentes_horarios_owner_all ON public.docentes_horarios;
CREATE POLICY docentes_horarios_owner_all ON public.docentes_horarios
  FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS asistencia_marcas_staff_all ON public.asistencia_marcas;
CREATE POLICY asistencia_marcas_staff_all ON public.asistencia_marcas
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS asistencia_marcas_owner_all ON public.asistencia_marcas;
CREATE POLICY asistencia_marcas_owner_all ON public.asistencia_marcas
  FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS asistencia_conciliacion_staff_all ON public.asistencia_conciliacion;
CREATE POLICY asistencia_conciliacion_staff_all ON public.asistencia_conciliacion
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS asistencia_conciliacion_owner_all ON public.asistencia_conciliacion;
CREATE POLICY asistencia_conciliacion_owner_all ON public.asistencia_conciliacion
  FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS asistencia_discrepancias_staff_all ON public.asistencia_discrepancias;
CREATE POLICY asistencia_discrepancias_staff_all ON public.asistencia_discrepancias
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS asistencia_discrepancias_owner_all ON public.asistencia_discrepancias;
CREATE POLICY asistencia_discrepancias_owner_all ON public.asistencia_discrepancias
  FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_salas_owner_codigo ON public.salas(owner_id, codigo);
CREATE INDEX IF NOT EXISTS idx_docentes_horarios_owner_fecha ON public.docentes_horarios(owner_id, bloque_fecha);
CREATE INDEX IF NOT EXISTS idx_docentes_horarios_owner_rut_fecha ON public.docentes_horarios(owner_id, rut_docente, bloque_fecha);
CREATE INDEX IF NOT EXISTS idx_asistencia_marcas_owner_rut_fecha ON public.asistencia_marcas(owner_id, rut_docente, fecha_hora_marca);
CREATE INDEX IF NOT EXISTS idx_asistencia_conciliacion_owner_rut_fecha ON public.asistencia_conciliacion(owner_id, rut_docente, fecha);
CREATE INDEX IF NOT EXISTS idx_asistencia_discrepancias_owner_resuelta ON public.asistencia_discrepancias(owner_id, resuelta);

DO $$
BEGIN
  BEGIN
    ALTER TABLE public.docentes_horarios
      ADD CONSTRAINT docentes_horarios_no_solape_docente
      EXCLUDE USING gist (
        owner_id WITH =,
        rut_docente WITH =,
        rango_horario WITH &&
      );
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  BEGIN
    ALTER TABLE public.docentes_horarios
      ADD CONSTRAINT docentes_horarios_no_solape_sala
      EXCLUDE USING gist (
        owner_id WITH =,
        sala_id WITH =,
        rango_horario WITH &&
      )
      WHERE (sala_id IS NOT NULL);
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  BEGIN
    ALTER TABLE public.docentes_horarios
      ADD CONSTRAINT docentes_horarios_no_solape_curso
      EXCLUDE USING gist (
        owner_id WITH =,
        curso_id WITH =,
        rango_horario WITH &&
      )
      WHERE (curso_id IS NOT NULL);
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END;
$$;

DROP TRIGGER IF EXISTS trg_salas_updated_at ON public.salas;
CREATE TRIGGER trg_salas_updated_at
  BEFORE UPDATE ON public.salas
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at_horarios_asistencia();

DROP TRIGGER IF EXISTS trg_docentes_horarios_updated_at ON public.docentes_horarios;
CREATE TRIGGER trg_docentes_horarios_updated_at
  BEFORE UPDATE ON public.docentes_horarios
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at_horarios_asistencia();

DROP TRIGGER IF EXISTS trg_asistencia_marcas_updated_at ON public.asistencia_marcas;
CREATE TRIGGER trg_asistencia_marcas_updated_at
  BEFORE UPDATE ON public.asistencia_marcas
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at_horarios_asistencia();

DROP TRIGGER IF EXISTS trg_asistencia_conciliacion_updated_at ON public.asistencia_conciliacion;
CREATE TRIGGER trg_asistencia_conciliacion_updated_at
  BEFORE UPDATE ON public.asistencia_conciliacion
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at_horarios_asistencia();

DROP TRIGGER IF EXISTS trg_asistencia_discrepancias_updated_at ON public.asistencia_discrepancias;
CREATE TRIGGER trg_asistencia_discrepancias_updated_at
  BEFORE UPDATE ON public.asistencia_discrepancias
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at_horarios_asistencia();

DROP TRIGGER IF EXISTS trg_docentes_horarios_validate_sala_owner ON public.docentes_horarios;
CREATE TRIGGER trg_docentes_horarios_validate_sala_owner
  BEFORE INSERT OR UPDATE ON public.docentes_horarios
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_horario_sala_owner();

COMMIT;
