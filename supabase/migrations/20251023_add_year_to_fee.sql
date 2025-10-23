-- Add year column to fee table for filtering by academic year
-- This allows querying fees by year without extracting from due_date

ALTER TABLE public.fee 
ADD COLUMN IF NOT EXISTS year integer;

-- Set default year based on due_date for existing records
UPDATE public.fee 
SET year = EXTRACT(YEAR FROM due_date)
WHERE year IS NULL;

-- Add constraint to ensure year is always set
ALTER TABLE public.fee 
ALTER COLUMN year SET NOT NULL;

-- Add check constraint for reasonable year values
ALTER TABLE public.fee 
ADD CONSTRAINT fee_year_valid CHECK (year >= 2020 AND year <= 2100);

-- Add index for faster year-based queries
CREATE INDEX IF NOT EXISTS idx_fee_year ON public.fee(year);

-- Add index for combined student + year queries (most common)
CREATE INDEX IF NOT EXISTS idx_fee_student_year ON public.fee(student_id, year);

COMMENT ON COLUMN public.fee.year IS 'Academic year for the fee. Allows efficient filtering without date extraction.';
