/*
  # Insert initial student data
  
  1. Data Changes
    - Insert sample student records with duplicate checking
    - Handle NULL values for numeric fields properly
    - Set owner_id to system user for initial data
  
  2. Data Integrity
    - Check for existing records before insert
    - Use proper NULL handling for bigint fields
    - Ensure consistent date formats
*/

-- Create a default system user ID for initial data
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ 
DECLARE
  v_system_user_id uuid;
BEGIN
  -- Create a consistent system user ID
  v_system_user_id := '00000000-0000-0000-0000-000000000000'::uuid;

  -- Insert sample students with duplicate checking
  IF NOT EXISTS (SELECT 1 FROM students WHERE run = '26141639-5') THEN
    INSERT INTO students (
      first_name, last_name, date_of_birth, grade, created_at, updated_at,
      owner_id, run, nivel, n_inscripcion, fecha_matricula, nombre_social,
      genero, nacionalidad, fecha_incorporacion, fecha_retiro,
      repite_curso_actual, institucion_procedencia, direccion, comuna,
      con_quien_vive, motivo_retiro
    ) VALUES (
      'MARTINA', 'ALARCON HERRERA', '2025-02-17', '3° Básico A',
      '2025-02-17 18:00:37.378104+00', '2025-02-17 18:00:37.378104+00',
      v_system_user_id, '26141639-5', '110', NULL, '2023-12-12', '',
      'FEMENINO', 'CHILENA', '2024-05-03', NULL, '', '', '', '', '', ''
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM students WHERE run = '22533775-6') THEN
    INSERT INTO students (
      first_name, last_name, date_of_birth, grade, created_at, updated_at,
      owner_id, run, nivel, n_inscripcion, fecha_matricula, nombre_social,
      genero, nacionalidad, fecha_incorporacion, fecha_retiro,
      repite_curso_actual, institucion_procedencia, direccion, comuna,
      con_quien_vive, motivo_retiro
    ) VALUES (
      'RENATA CONSTANZA', 'GUZMAN TORRES', '2007-10-25', '3° Básico A',
      '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00',
      v_system_user_id, '22533775-6', '310', 13, '2023-12-12', '',
      'FEMENINO', 'CHILENA', '2024-05-03', NULL, 'NO', 'NO DISPONIBLE',
      'Barros Arana 795 depto. 72 Recreo -', 'VIÑA DEL MAR', 'MADRE', ''
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM students WHERE run = '25118769-K') THEN
    INSERT INTO students (
      first_name, last_name, date_of_birth, grade, created_at, updated_at,
      owner_id, run, nivel, n_inscripcion, fecha_matricula, nombre_social,
      genero, nacionalidad, fecha_incorporacion, fecha_retiro,
      repite_curso_actual, institucion_procedencia, direccion, comuna,
      con_quien_vive, motivo_retiro
    ) VALUES (
      'LUCAS ALONSO', 'VALENZUELA BELTRÁN', '2015-08-10', '3° Básico A',
      '2025-02-17 17:56:46.273746+00', '2025-02-17 17:56:46.273746+00',
      v_system_user_id, '25118769-K', '110', 212, '2023-12-26', '',
      'MASCULINO', 'CHILENA', '2023-05-03', NULL, 'NO', 'WINTERHILL',
      'CALLE A 403.', 'CONCÓN', '', ''
    );
  END IF;

END $$;