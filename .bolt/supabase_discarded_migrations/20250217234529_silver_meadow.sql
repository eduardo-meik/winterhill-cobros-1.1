/*
  # Add RLS Policies for Students Table

  1. Purpose
    - Enable secure access control for student records
    - Allow authenticated users to manage student data
    - Ensure data isolation between different users

  2. Changes
    - Add INSERT policy for authenticated users
    - Add UPDATE policy for authenticated users
    - Add DELETE policy for authenticated users
    - Add owner_id column to track record ownership
*/

-- Add owner_id column to students table
ALTER TABLE students 
ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES auth.users(id);

-- Update existing records to use the current user as owner
UPDATE students 
SET owner_id = auth.uid()
WHERE owner_id IS NULL;

-- Make owner_id required for new records
ALTER TABLE students 
ALTER COLUMN owner_id SET NOT NULL;

-- Create policies for authenticated users
CREATE POLICY "Users can insert their own students"
  ON students
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own students"
  ON students
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own students"
  ON students
  FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);