-- Migration: Add guardian identity fields for contract templates
-- Created: 2025-11-19
-- Purpose: Ensure pagaré/autorización documents can render nationality, profession and marital status

ALTER TABLE public.guardians
ADD COLUMN IF NOT EXISTS nacionalidad VARCHAR(50) DEFAULT 'Chilena';

ALTER TABLE public.guardians
ADD COLUMN IF NOT EXISTS profesion VARCHAR(100);

ALTER TABLE public.guardians
ADD COLUMN IF NOT EXISTS estado_civil VARCHAR(20);

-- Backfill nationality for existing guardians so templates show a friendly default
UPDATE public.guardians
SET nacionalidad = 'Chilena'
WHERE nacionalidad IS NULL OR nacionalidad = '';

COMMENT ON COLUMN public.guardians.nacionalidad IS 'Guardian nationality displayed in pagare/autorizacion templates.';
COMMENT ON COLUMN public.guardians.profesion IS 'Guardian profession or occupation displayed in contract templates.';
COMMENT ON COLUMN public.guardians.estado_civil IS 'Guardian marital status displayed in contract templates.';
