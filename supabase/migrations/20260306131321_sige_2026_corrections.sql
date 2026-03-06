-- Migración: Correcciones SIGE 2026
-- Fecha: 2026-03-06
-- Descripción: Aplicar correcciones identificadas en el cruce SIGE 2026 vs BD

-- 1. Ampliar constraint estado_std para incluir EGRESADO
ALTER TABLE public.students DROP CONSTRAINT IF EXISTS students_estado_std_check;
ALTER TABLE public.students ADD CONSTRAINT students_estado_std_check 
  CHECK (estado_std = ANY (ARRAY['ACTIVO', 'RETIRADO', 'MATRICULADO', 'PRE_MATRICULADO', 'EGRESADO']));

-- 2. Actualizar trigger para respetar estado EGRESADO
CREATE OR REPLACE FUNCTION public.actualizar_estado_std()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.estado_std = 'EGRESADO' THEN
    RETURN NEW;
  END IF;

  IF NEW.fecha_retiro IS NULL THEN
    NEW.estado_std := 'ACTIVO';
  ELSE
    NEW.estado_std := 'RETIRADO';
  END IF;

  RETURN NEW;
END;
$function$;
