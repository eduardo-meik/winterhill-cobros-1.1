BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS public.docentes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre_display text NOT NULL,
  nombre_normalizado text NOT NULL,
  rut_docente text,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT docentes_nombre_unique UNIQUE (owner_id, nombre_normalizado),
  CONSTRAINT docentes_rut_format CHECK (rut_docente IS NULL OR rut_docente ~* '^[0-9]{7,8}-[0-9kK]$')
);

CREATE TABLE IF NOT EXISTS public.docentes_horarios_plantilla (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  docente_id uuid NOT NULL REFERENCES public.docentes(id) ON DELETE CASCADE,
  dia_semana smallint NOT NULL,
  hora_inicio time NOT NULL,
  hora_fin time NOT NULL,
  minuto_inicio integer GENERATED ALWAYS AS ((EXTRACT(HOUR FROM hora_inicio)::int * 60) + EXTRACT(MINUTE FROM hora_inicio)::int) STORED,
  minuto_fin integer GENERATED ALWAYS AS ((EXTRACT(HOUR FROM hora_fin)::int * 60) + EXTRACT(MINUTE FROM hora_fin)::int) STORED,
  actividad text NOT NULL,
  es_lectivo boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT docentes_horarios_plantilla_dia_semana CHECK (dia_semana BETWEEN 1 AND 7),
  CONSTRAINT docentes_horarios_plantilla_hora_valida CHECK (hora_fin > hora_inicio),
  CONSTRAINT docentes_horarios_plantilla_unique UNIQUE (owner_id, docente_id, dia_semana, hora_inicio, hora_fin, actividad)
);

DO $$
BEGIN
  BEGIN
    ALTER TABLE public.docentes_horarios_plantilla
      ADD CONSTRAINT docentes_horarios_plantilla_no_solape_docente
      EXCLUDE USING gist (
        owner_id WITH =,
        docente_id WITH =,
        dia_semana WITH =,
        int4range(minuto_inicio, minuto_fin, '[)') WITH &&
      );
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END;
$$;

ALTER TABLE public.docentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.docentes_horarios_plantilla ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS docentes_staff_all ON public.docentes;
CREATE POLICY docentes_staff_all ON public.docentes
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS docentes_owner_all ON public.docentes;
CREATE POLICY docentes_owner_all ON public.docentes
  FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS docentes_horarios_plantilla_staff_all ON public.docentes_horarios_plantilla;
CREATE POLICY docentes_horarios_plantilla_staff_all ON public.docentes_horarios_plantilla
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS docentes_horarios_plantilla_owner_all ON public.docentes_horarios_plantilla;
CREATE POLICY docentes_horarios_plantilla_owner_all ON public.docentes_horarios_plantilla
  FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_docentes_owner_nombre ON public.docentes(owner_id, nombre_normalizado);
CREATE INDEX IF NOT EXISTS idx_docentes_horarios_plantilla_owner_dia ON public.docentes_horarios_plantilla(owner_id, dia_semana);
CREATE INDEX IF NOT EXISTS idx_docentes_horarios_plantilla_owner_docente ON public.docentes_horarios_plantilla(owner_id, docente_id);

CREATE OR REPLACE FUNCTION public.set_updated_at_docentes_plantilla()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_docentes_updated_at ON public.docentes;
CREATE TRIGGER trg_docentes_updated_at
  BEFORE UPDATE ON public.docentes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at_docentes_plantilla();

DROP TRIGGER IF EXISTS trg_docentes_horarios_plantilla_updated_at ON public.docentes_horarios_plantilla;
CREATE TRIGGER trg_docentes_horarios_plantilla_updated_at
  BEFORE UPDATE ON public.docentes_horarios_plantilla
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at_docentes_plantilla();

COMMIT;
