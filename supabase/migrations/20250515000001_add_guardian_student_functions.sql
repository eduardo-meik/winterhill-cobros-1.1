/*
  # Add helper functions for guardian-student relationships

  Add functions to help reliably query student-guardian relationships.
  This is especially important for the reporting page functionality.

  1. Functions
    - get_students_by_guardian_ids: Get all student_ids for given guardian_ids
*/

-- Function to get student IDs for a list of guardian IDs
CREATE OR REPLACE FUNCTION get_students_by_guardian_ids(guardian_ids uuid[])
RETURNS TABLE (student_id uuid)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT sg.student_id 
  FROM student_guardian sg 
  WHERE sg.guardian_id = ANY(guardian_ids);
$$;

-- Function to get guardian IDs for a list of student IDs
CREATE OR REPLACE FUNCTION get_guardians_by_student_ids(student_ids uuid[])
RETURNS TABLE (guardian_id uuid)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT sg.guardian_id 
  FROM student_guardian sg 
  WHERE sg.student_id = ANY(student_ids);
$$;
