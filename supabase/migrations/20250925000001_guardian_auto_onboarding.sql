-- Guardian Auto-Onboarding & Student Self-Service Helpers
-- Date: 2025-09-25
-- Purpose: Automatizar la creación del registro en guardians al crear perfil (usuario) y
-- proveer funciones para garantizar existencia de apoderado y creación segura de estudiantes.

BEGIN;

-- 1. Function: ensure_guardian_for_user
-- Crea un registro en guardians si no existe para el usuario actual (auth.uid())
-- Retorna el id del guardian.
CREATE OR REPLACE FUNCTION public.ensure_guardian_for_user(p_user_id uuid DEFAULT auth.uid())
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_guardian_id uuid;
    v_email text;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'ensure_guardian_for_user: p_user_id no puede ser NULL';
    END IF;

    -- Buscar si ya existe guardian
    SELECT id INTO v_guardian_id FROM public.guardians WHERE owner_id = p_user_id LIMIT 1;
    IF v_guardian_id IS NOT NULL THEN
        RETURN v_guardian_id; -- Ya existe
    END IF;

    -- Intentar tomar email desde profiles (si existe)
    SELECT email INTO v_email FROM public.profiles WHERE id = p_user_id;

    -- Crear guardian mínimo
    INSERT INTO public.guardians (owner_id, email)
    VALUES (p_user_id, v_email)
    RETURNING id INTO v_guardian_id;

    RETURN v_guardian_id;
END;
$$;

COMMENT ON FUNCTION public.ensure_guardian_for_user IS 'Garantiza la existencia de un guardian para el usuario dado y retorna su id.';

-- 2. Trigger: auto crear guardian al insertar profile (si no existe)
CREATE OR REPLACE FUNCTION public.trg_auto_create_guardian()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    -- Evitar doble creación: sólo si no existe ya
    PERFORM 1 FROM public.guardians WHERE owner_id = NEW.id;
    IF NOT FOUND THEN
        -- Reutiliza la lógica existente
        PERFORM public.ensure_guardian_for_user(NEW.id);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_auto_guardian ON public.profiles;
CREATE TRIGGER trg_profiles_auto_guardian
AFTER INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.trg_auto_create_guardian();

COMMENT ON TRIGGER trg_profiles_auto_guardian ON public.profiles IS 'Crea automáticamente un guardian asociado al nuevo usuario/perfil.';

-- 3. Function: guardian_add_student
-- Permite que el usuario autenticado cree un nuevo estudiante y lo asocie consigo mismo.
-- Valida que el usuario tenga guardian. Retorna el id del estudiante creado.
CREATE OR REPLACE FUNCTION public.guardian_add_student(
    p_whole_name text,
    p_run text,
    p_extra jsonb DEFAULT '{}'::jsonb
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_guardian_id uuid;
    v_student_id uuid;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'guardian_add_student: usuario no autenticado';
    END IF;

    -- Asegurar guardian
    v_guardian_id := public.ensure_guardian_for_user(auth.uid());

    -- Evitar duplicado por RUN (suave): si ya existe alumno con ese run y relación, retornar existente
    IF p_run IS NOT NULL THEN
        SELECT s.id INTO v_student_id
        FROM public.students s
        JOIN public.student_guardian sg ON sg.student_id = s.id
        WHERE s.run = p_run AND sg.guardian_id = v_guardian_id
        LIMIT 1;
    END IF;
    IF v_student_id IS NOT NULL THEN
        RETURN v_student_id; -- ya existe asociado
    END IF;

    -- Crear estudiante (ajusta columnas reales según tu tabla students)
    INSERT INTO public.students (whole_name, run, meta)
    VALUES (p_whole_name, p_run, COALESCE(p_extra, '{}'::jsonb))
    RETURNING id INTO v_student_id;

    -- Asociar
    INSERT INTO public.student_guardian (student_id, guardian_id)
    VALUES (v_student_id, v_guardian_id)
    ON CONFLICT DO NOTHING;

    RETURN v_student_id;
END;
$$;

COMMENT ON FUNCTION public.guardian_add_student IS 'Crea un estudiante y lo vincula al guardian del usuario autenticado.';

-- Nota: Ajustar si la tabla students NO tiene columna meta. Quitar meta del insert en tal caso.

COMMIT;
