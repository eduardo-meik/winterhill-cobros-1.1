/*
  # Create cursos table and update students schema
  
  1. New Tables
    - cursos: Stores course information
      - id (uuid, primary key)
      - nom_curso (text, course name)
      - nivel (text, course level)
      - year (integer, academic year)
  
  2. Changes
    - Add curso_id to students table
    - Update existing queries to use new schema
*/

-- Create cursos table
CREATE TABLE IF NOT EXISTS cursos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  nom_curso text NOT NULL,
  nivel text,
  year integer
);

-- Add curso_id to students
ALTER TABLE students 
ADD COLUMN IF NOT EXISTS curso_id uuid REFERENCES cursos(id);

-- Enable RLS on cursos
ALTER TABLE cursos ENABLE ROW LEVEL SECURITY;

-- Create policies for cursos
CREATE POLICY "Users can view all courses"
  ON cursos FOR SELECT
  TO authenticated
  USING (true);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_cursos_nom_curso ON cursos(nom_curso);
CREATE INDEX IF NOT EXISTS idx_students_curso_id ON students(curso_id);