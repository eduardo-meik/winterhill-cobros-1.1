-- Add unique constraint to student_guardian table to ensure student_id and guardian_id pairs are unique.
ALTER TABLE public.student_guardian
ADD CONSTRAINT student_guardian_student_id_guardian_id_key UNIQUE (student_id, guardian_id);

COMMENT ON CONSTRAINT student_guardian_student_id_guardian_id_key ON public.student_guardian IS 'Ensures that each student-guardian pair is unique, allowing upsert operations to correctly update roles.';
