/*
  # Create guardians and students management tables

  1. New Tables
    - guardians
      - Basic information for student guardians
      - RLS enabled with owner-based policies
    - student_guardian
      - Links students with their guardians
      - Supports multiple guardians per student
      - RLS enabled with owner-based policies

  2. Security
    - RLS enabled on all tables
    - Policies for CRUD operations
    - Owner-based access control

  3. Indexes
    - Optimized queries for common operations
    - Foreign key relationships
*/

-- Drop existing tables if they exist with CASCADE to handle dependencies
DROP TABLE IF EXISTS student_guardian CASCADE;
DROP TABLE IF EXISTS guardians CASCADE;
DROP TABLE IF EXISTS students CASCADE;

-- Create guardians table
CREATE TABLE guardians (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  run text NOT NULL UNIQUE,
  email text,
  phone text,
  address text,
  relationship_type text CHECK (relationship_type IN ('Padre', 'Madre', 'Tutor')),
  owner_id uuid REFERENCES auth.users(id) NOT NULL
);

-- Create students table
CREATE TABLE students (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  run text NOT NULL UNIQUE,
  date_of_birth date NOT NULL,
  grade text NOT NULL,
  email text,
  owner_id uuid REFERENCES auth.users(id) NOT NULL,
  nivel text,
  n_inscripcion integer,
  fecha_matricula date NOT NULL,
  nombre_social text,
  genero text CHECK (genero IN ('MASCULINO', 'FEMENINO', 'NO BINARIO')),
  nacionalidad text,
  fecha_incorporacion date,
  fecha_retiro date,
  repite_curso_actual text,
  institucion_procedencia text,
  direccion text,
  comuna text,
  con_quien_vive text,
  motivo_retiro text
);

-- Create student_guardian relationship table
CREATE TABLE student_guardian (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  student_id uuid REFERENCES students(id) ON DELETE CASCADE NOT NULL,
  guardian_id uuid REFERENCES guardians(id) ON DELETE CASCADE NOT NULL,
  is_primary boolean DEFAULT false,
  UNIQUE(student_id, guardian_id)
);

-- Enable RLS
ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_guardian ENABLE ROW LEVEL SECURITY;

-- Create policies for guardians
CREATE POLICY "Users can view their own guardians"
  ON guardians FOR SELECT
  TO authenticated
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert their own guardians"
  ON guardians FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own guardians"
  ON guardians FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own guardians"
  ON guardians FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- Create policies for students
CREATE POLICY "Users can view their own students"
  ON students FOR SELECT
  TO authenticated
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert their own students"
  ON students FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own students"
  ON students FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own students"
  ON students FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- Create policies for student_guardian relationships
CREATE POLICY "Users can view student_guardian relationships"
  ON student_guardian FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.id = student_id AND s.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert student_guardian relationships"
  ON student_guardian FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.id = student_id AND s.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update student_guardian relationships"
  ON student_guardian FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.id = student_id AND s.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.id = student_id AND s.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete student_guardian relationships"
  ON student_guardian FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.id = student_id AND s.owner_id = auth.uid()
    )
  );

-- Create indexes
CREATE INDEX idx_guardians_run ON guardians(run);
CREATE INDEX idx_guardians_owner ON guardians(owner_id);
CREATE INDEX idx_students_run ON students(run);
CREATE INDEX idx_students_owner ON students(owner_id);
CREATE INDEX idx_student_guardian_student ON student_guardian(student_id);
CREATE INDEX idx_student_guardian_guardian ON student_guardian(guardian_id);