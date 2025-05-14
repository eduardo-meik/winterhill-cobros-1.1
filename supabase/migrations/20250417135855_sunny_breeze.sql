/*
  # Create and configure students table with owner_id
  
  1. Table Creation
    - Creates students table if it doesn't exist
    - Adds all required columns including owner_id
  
  2. Security
    - Enables RLS
    - Adds policies for authenticated users
    - Sets up proper ownership constraints
*/

-- Create students table if it doesn't exist
CREATE TABLE IF NOT EXISTS students (
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

-- Enable RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users
DO $$ 
BEGIN
  -- Insert policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'students' AND policyname = 'Users can insert their own students'
  ) THEN
    CREATE POLICY "Users can insert their own students"
      ON students
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = owner_id);
  END IF;

  -- Update policy  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'students' AND policyname = 'Users can update their own students'
  ) THEN
    CREATE POLICY "Users can update their own students"
      ON students
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = owner_id)
      WITH CHECK (auth.uid() = owner_id);
  END IF;

  -- Delete policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'students' AND policyname = 'Users can delete their own students'
  ) THEN
    CREATE POLICY "Users can delete their own students"
      ON students
      FOR DELETE
      TO authenticated
      USING (auth.uid() = owner_id);
  END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_students_owner_id ON students(owner_id);
CREATE INDEX IF NOT EXISTS idx_students_run ON students(run);
CREATE INDEX IF NOT EXISTS idx_students_grade ON students(grade);