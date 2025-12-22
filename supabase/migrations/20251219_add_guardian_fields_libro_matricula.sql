-- Add missing fields to guardians table for Libro de Matrícula
-- Date: 2025-12-19

BEGIN;

-- Add date_of_birth field for guardians
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS date_of_birth DATE;

-- Add nivel_educacional field
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS nivel_educacional VARCHAR(100);

-- Add apellido_paterno and apellido_materno fields
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

-- Add helpful comments
COMMENT ON COLUMN public.guardians.date_of_birth IS 'Fecha de nacimiento del apoderado para Libro de Matrícula';
COMMENT ON COLUMN public.guardians.nivel_educacional IS 'Nivel educacional: Básica Completa, Media Completa, Técnica, Universitaria, Postgrado, etc.';
COMMENT ON COLUMN public.guardians.apellido_paterno IS 'Apellido paterno del apoderado';
COMMENT ON COLUMN public.guardians.apellido_materno IS 'Apellido materno del apoderado';

COMMIT;
