-- Add guardian_role to student_guardian table
ALTER TABLE public.student_guardian
ADD COLUMN guardian_role TEXT;

COMMENT ON COLUMN public.student_guardian.guardian_role IS 'Specifies the role of the guardian in relation to the student (e.g., ECONOMICO, PEDAGOGICO, AMBOS, OTRO)';

-- Optional: You might want to add a check constraint if you have a fixed set of roles
-- and want to enforce them at the database level.
-- Example:
-- ALTER TABLE public.student_guardian
-- ADD CONSTRAINT check_guardian_role CHECK (guardian_role IN ('ECONOMICO', 'PEDAGOGICO', 'AMBOS', 'OTRO'));
