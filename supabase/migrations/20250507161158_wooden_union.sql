/*
  # Fix infinite recursion in students RLS policy

  1. Changes
    - Drop existing RLS policies on students table that may cause recursion
    - Create new, simplified RLS policies that avoid recursive joins
    - Maintain security while preventing infinite loops

  2. Security
    - Maintain row-level security on students table
    - Ensure users can only access their own data
    - Allow admins and team members to access all data
    - Prevent infinite recursion in policy evaluation
*/

-- Drop existing policies that may cause recursion
DROP POLICY IF EXISTS "Admin u otros roles con acceso total a students" ON students;
DROP POLICY IF EXISTS "Apoderado edita estudiantes vinculados" ON students;
DROP POLICY IF EXISTS "Apoderado ve estudiantes vinculados" ON students;
DROP POLICY IF EXISTS "Users can delete their own students" ON students;
DROP POLICY IF EXISTS "Users can insert their own students" ON students;
DROP POLICY IF EXISTS "Users can update their own students" ON students;
DROP POLICY IF EXISTS "Users can view their own students" ON students;

-- Create new, simplified policies
CREATE POLICY "Admin access" ON students
  FOR ALL 
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'ADMIN'
    )
  );

CREATE POLICY "Team member access" ON students
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('FINANCE_MANAGER', 'REGISTRAR')
    )
  );

CREATE POLICY "Guardian access" ON students
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM student_guardian
      WHERE student_guardian.student_id = students.id
      AND student_guardian.guardian_id = auth.uid()
    )
  );

CREATE POLICY "Owner access" ON students
  FOR ALL
  TO authenticated
  USING (students.owner_id = auth.uid());