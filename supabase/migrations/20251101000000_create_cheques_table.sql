-- Migration: Create cheques table for managing check payment details
-- Created: 2025-11-01
-- Purpose: Store check information when "Cheque" payment method is selected during enrollment

-- Create cheques table
CREATE TABLE IF NOT EXISTS public.cheques (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Link to enrollment
  enrollment_id UUID NOT NULL REFERENCES public.enrollments(id) ON DELETE CASCADE,
  
  -- Check details
  numero_serie VARCHAR(100) NOT NULL, -- Check series number
  banco VARCHAR(200) NOT NULL, -- Bank name
  fecha_emision DATE NOT NULL, -- Issue date
  monto NUMERIC(12,2) NOT NULL CHECK (monto > 0), -- Amount
  
  -- Status tracking
  estado VARCHAR(50) NOT NULL DEFAULT 'pendiente' 
    CHECK (estado IN ('pendiente', 'cobrado', 'rechazado', 'anulado')),
  
  -- Additional info
  notas TEXT, -- Optional notes
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- Create indexes for performance
CREATE INDEX idx_cheques_enrollment_id ON public.cheques(enrollment_id);
CREATE INDEX idx_cheques_estado ON public.cheques(estado);
CREATE INDEX idx_cheques_fecha_emision ON public.cheques(fecha_emision);

-- Add RLS policies
ALTER TABLE public.cheques ENABLE ROW LEVEL SECURITY;

-- ADMIN and ASIST can see all checks
CREATE POLICY "ADMIN and ASIST can view all cheques"
  ON public.cheques
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ADMIN', 'ASIST')
    )
  );

-- ADMIN and ASIST can insert checks
CREATE POLICY "ADMIN and ASIST can insert cheques"
  ON public.cheques
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ADMIN', 'ASIST')
    )
  );

-- ADMIN and ASIST can update checks
CREATE POLICY "ADMIN and ASIST can update cheques"
  ON public.cheques
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ADMIN', 'ASIST')
    )
  );

-- Guardians can view their own checks
CREATE POLICY "Guardians can view their own cheques"
  ON public.cheques
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.enrollments
      JOIN public.guardians ON enrollments.guardian_id = guardians.id
      WHERE enrollments.id = cheques.enrollment_id
      AND guardians.owner_id = auth.uid()
    )
  );

-- Guardians can insert checks for their own enrollments
CREATE POLICY "Guardians can insert cheques for own enrollments"
  ON public.cheques
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.enrollments
      JOIN public.guardians ON enrollments.guardian_id = guardians.id
      WHERE enrollments.id = enrollment_id
      AND guardians.owner_id = auth.uid()
    )
  );

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cheques_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_cheques_timestamp
  BEFORE UPDATE ON public.cheques
  FOR EACH ROW
  EXECUTE FUNCTION update_cheques_updated_at();

-- Add comment to table
COMMENT ON TABLE public.cheques IS 'Stores check payment details for enrollments';
COMMENT ON COLUMN public.cheques.numero_serie IS 'Check series/number';
COMMENT ON COLUMN public.cheques.banco IS 'Bank name that issued the check';
COMMENT ON COLUMN public.cheques.fecha_emision IS 'Check issue date';
COMMENT ON COLUMN public.cheques.monto IS 'Check amount in CLP';
COMMENT ON COLUMN public.cheques.estado IS 'Check status: pendiente, cobrado, rechazado, anulado';


