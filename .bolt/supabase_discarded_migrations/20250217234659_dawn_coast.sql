/*
  # Create School Management Tables and Sample Data
  
  1. Tables Created:
    - students
    - guardians
    - student_guardian
    - fee
  
  2. Data Added:
    - Sample student records
    - Sample guardian records
    - Student-guardian relationships
    - Sample fee records
*/

-- Create a default system user ID for initial data
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ 
DECLARE
  v_system_user_id uuid;
BEGIN
  -- Create a consistent system user ID
  v_system_user_id := '00000000-0000-0000-0000-000000000000'::uuid;

  -- Insert sample students
  INSERT INTO "students" ("first_name", "last_name", "date_of_birth", "grade", "created_at", "updated_at", "owner_id", "run", "nivel", "n_inscripcion", "fecha_matricula", "nombre_social", "genero", "nacionalidad", "fecha_incorporacion", "fecha_retiro", "repite_curso_actual", "institucion_procedencia", "direccion", "comuna", "con_quien_vive", "motivo_retiro") 
VALUES 
('MARTINA', 'ALARCON HERRERA', '2025-02-17', '3° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:00:37.378104+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '26141639-5', '110', '', '2023-12-12', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, '', '', '', '', '', '', nullif('', '')),
('RENATA CONSTANZA', 'GUZMAN TORRES', '2007-10-25', '3° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22533775-6', '310', '13', '2023-12-12', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Barros Arana 795 depto. 72 Recreo -', 'VIÑA DEL MAR', 'MADRE', nullif('', '')),
('LUCAS ALONSO', 'VALENZUELA BELTRÁN', '2015-08-10', '3° Básico A', '2025-02-17 17:56:46.273746+00', '2025-02-17 17:56:46.273746+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25118769-K', '110', '212', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'CALLE A 403.', 'CONCÓN', nullif('', ''), nullif('', '')),
('CLEMENTE GABRIEL', 'MOYA ARIAS', '2011-02-11', '7° Básico B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:00:37.378104+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23789601-7', '110', '247', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'PJE PERCY N°917 POB ENAP', 'CONCÓN', 'MADRE', nullif('', '')),
('AGUSTÍN ALONSO', 'SAN MARTÍN ARROYO', '2016-08-17', '1° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25488565-7', '110', '208', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2024-05-03', '2024-11-07', 'SI', 'WINTERHILL', 'De Veer 1043, torre B depto 1401', 'QUILPUÉ', 'PADRE, MADRE', 'cambio,ciudad'),
('BENJAMÍN OCTAVIO', 'MIRANDA ZAMORANO', '2012-02-23', '7° Básico A', '2025-02-17 17:56:46.273746+00', '2025-02-17 17:56:46.273746+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23882519-9', '110', '266', '2024-03-14', '', 'MASCULINO', 'CHILENA', '2024-03-14', nullif('', '')::date, 'NO', 'Antulemu', 'Avda Los Carrera 01074 Dp 204 T1', 'QUILPUÉ', 'MADRE, HERMANO', nullif('', '')),
('MATEO AMARO', 'MIRANDA ZAMORANO', '2014-07-24', '4° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24704324-1', '110', '286', '2024-06-17', '', 'MASCULINO', 'CHILENA', '2024-06-17', nullif('', '')::date, 'NO', 'Antulemu (Quilpué)', 'Avenida Los Carrera 01074 Dp 204 Torre 1', 'QUILPUÉ', 'MADRE', nullif('', '')),
('FLORENCIA', 'OLIVARES FREZ', '2024-10-17', '7° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23774788-7', '110', '284', '2024-05-28', '', 'FEMENINO', 'CHILENA', '2024-05-28', nullif('', '')::date, 'NO', 'King Eswards', 'Avenida Segunda 0650 Casa E', 'QUILPUÉ', 'PADRE', nullif('', '')),
('FLORENCIA ANTONIA', 'FUNES GARVISO', '2010-02-13', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 17:56:46.273746+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23252188-0', '310', '13', '2023-12-27', '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'LUIS URIBE 150 CASA 17, COND.CASAS DE FLORENCIA, EL RETIRO, QUILPUÉ, REGIÓN DE VALPARAÍSO', 'QUILPUÉ', 'MADRE', nullif('', '')),
('MAITE ALMENDRA', 'GONZÁLEZ LEÓN', '2009-06-05', '1° Medio B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23012560-0', '310', '11', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Camilo henriquez 0260', 'QUILPUÉ', 'MADRE', nullif('', '')),
('FERNANDA ALEXIA', 'MUÑOZ MOLINA', '2009-01-03', '2° Medio B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23013869-9', '310', '18', '2023-12-14', '', '', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Frutillar 887 Belloto Norte Quilpue', 'QUILPUÉ', 'MADRE, PADRE', nullif('', '')),
('TOMÁS SALVADOR', 'CAÑÓN BERNOFF', '2008-04-26', '3° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 17:56:46.273746+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22708810-9', '310', '6', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Av los carrera 1360 depto 22 belloto 2000 quilpue', 'QUILPUÉ', 'MADRE', nullif('', '')),
('PABLO ANDRÉS', 'DÍAZ FUENZALIDA', '2008-02-04', '3° Medio A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:00:37.378104+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22684772-3', '310', '11', '2023-12-14', '', 'MASCULINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Calle los Copihues 1187', 'QUILPUÉ', 'MADRE', nullif('', '')),
('GABRIEL ANTONIO', 'FLORES AROS', '2008-10-06', '2° Medio A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22832796-4', '310', '12', '2023-12-19', '', 'MASCULINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Los maitenes 336 villa Berlin cerro los placeres valparaiso', 'VALPARAISO', 'PADRE', nullif('', '')),
('GASPAR TOMÁS', 'CARREÑO SOTO', '2017-05-14', '1° Básico B', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25764187-2', '110', '267', '2024-03-25', '', 'MASCULINO', 'CHILENA', '2024-03-25', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda N° 8 C° Placeres', 'VALPARAISO', 'MADRE, PADRE, HERMANO', nullif('', '')),
('LUCAS MIGUEL', 'CARREÑO SOTO', '2014-11-21', '4° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24805440-9', '110', '276', '2010-04-19', '', 'MASCULINO', 'CHILENA', '2024-09-04', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda 8 Cerrp Placeres', 'VALPARAISO', 'MADRE, PADRE, HERNANA', nullif('', '')),
('LUCIANO MATEO', 'LEONART CORTÉS', '2017-12-28', '1° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25617549-5', '110', '209', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2024-05-03', '2024-11-03', 'SI', 'WINTERHILL', 'jardines del bosque 544 curauma', 'VALPARAISO', 'MADRE', 'cambio a escuela especial'),
('FLORENCIA', 'OLIVARES FREZ', '2024-10-17', '7° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23774788-7', '110', '284', '2024-05-28', '', 'FEMENINO', 'CHILENA', '2024-05-28', nullif('', '')::date, 'NO', 'King Eswards', 'Avenida Segunda 0650 Casa E', 'QUILPUÉ', 'PADRE', nullif('', '')),
('FLORENCIA ANTONIA', 'FUNES GARVISO', '2010-02-13', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23252188-0', '310', '13', '2023-12-27', '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'LUIS URIBE 150 CASA 17, COND.CASAS DE FLORENCIA, EL RETIRO, QUILPUÉ, REGIÓN DE VALPARAÍSO', 'QUILPUÉ', 'MADRE', nullif('', '')),
('MAITE ALMENDRA', 'GONZÁLEZ LEÓN', '2009-06-05', '1° Medio B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23012560-0', '310', '11', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Camilo henriquez 0260', 'QUILPUÉ', 'MADRE', nullif('', '')),
('FERNANDA ALEXIA', 'MUÑOZ MOLINA', '2009-01-03', '2° Medio B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23013869-9', '310', '18', '2023-12-14', '', '', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Frutillar 887 Belloto Norte Quilpue', 'QUILPUÉ', 'MADRE, PADRE', nullif('', '')),
('TOMÁS SALVADOR', 'CAÑÓN BERNOFF', '2008-04-26', '3° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22708810-9', '310', '6', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Av los carrera 1360 depto 22 belloto 2000 quilpue', 'QUILPUÉ', 'MADRE', nullif('', '')),
('PABLO ANDRÉS', 'DÍAZ FUENZALIDA', '2008-02-04', '3° Medio A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22684772-3', '310', '11', '2023-12-14', '', 'MASCULINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Calle los Copihues 1187', 'QUILPUÉ', 'MADRE', nullif('', '')),
('GABRIEL ANTONIO', 'FLORES AROS', '2008-10-06', '2° Medio A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22832796-4', '310', '12', '2023-12-19', '', 'MASCULINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Los maitenes 336 villa Berlin cerro los placeres valparaiso', 'VALPARAISO', 'PADRE', nullif('', '')),
('GASPAR TOMÁS', 'CARREÑO SOTO', '2017-05-14', '1° Básico B', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25764187-2', '110', '267', '2024-03-25', '', 'MASCULINO', 'CHILENA', '2024-03-25', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda N° 8 C° Placeres', 'VALPARAISO', 'MADRE, PADRE, HERMANO', nullif('', '')),
('LUCAS MIGUEL', 'CARREÑO SOTO', '2014-11-21', '4° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24805440-9', '310', '276', '2010-04-19', '', 'MASCULINO', 'CHILENA', '2024-09-04', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda 8 Cerrp Placeres', 'VALPARAISO', 'MADRE, PADRE, HERNANA', nullif('', '')),
('LUCIANO MATEO', 'LEONART CORTÉS', '2017-12-28', '1° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25617549-5', '310', '209', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2024-05-03', '2024-11-03', 'SI', 'WINTERHILL', 'jardines del bosque 544 curauma', 'VALPARAISO', 'MADRE', 'cambio a escuela especial'),
('FLORENCIA', 'OLIVARES FREZ', '2024-10-17', '7° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23774788-7', '310', '284', '2024-05-28', '', 'FEMENINO', 'CHILENA', '2024-05-28', nullif('', '')::date, 'NO', 'King Eswards', 'Avenida Segunda 0650 Casa E', 'QUILPUÉ', 'PADRE', nullif('', '')),
('FLORENCIA ANTONIA', 'FUNES GARVISO', '2010-02-13', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23252188-0', '310', '13', '2023-12-27', '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'LUIS URIBE 150 CASA 17, COND.CASAS DE FLORENCIA, EL RETIRO, QUILPUÉ, REGIÓN DE VALPARAÍSO', 'QUILPUÉ', 'MADRE', nullif('', '')),
('MAITE ALMENDRA', 'GONZÁLEZ LEÓN', '2009-06-05', '1° Medio B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23012560-0', '310', '11', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Camilo henriquez 0260', 'QUILPUÉ', 'MADRE', nullif('', '')),
('FERNANDA ALEXIA', 'MUÑOZ MOLINA', '2009-01-03', '2° Medio B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23013869-9', '310', '18', '2023-12-14', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Frutillar 887 Belloto Norte Quilpue', 'QUILPUÉ', 'MADRE, PADRE', nullif('', '')),
('TOMÁS SALVADOR', 'CAÑÓN BERNOFF', '2008-04-26', '3° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22708810-9', '310', '6', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Av los carrera 1360 depto 22 belloto 2000 quilpue', 'QUILPUÉ', 'MADRE', nullif('', '')),
('PABLO ANDRÉS', 'DÍAZ FUENZALIDA', '2008-02-04', '3° Medio A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22684772-3', '310', '11', '2023-12-14', '', 'MASCULINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Calle los Copihues 1187', 'QUILPUÉ', 'MADRE', nullif('', '')),
('GABRIEL ANTONIO', 'FLORES AROS', '2008-10-06', '2° Medio A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22832796-4', '310', '12', '2023-12-19', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Los maitenes 336 villa Berlin cerro los placeres valparaiso', 'VALPARAISO', 'PADRE', nullif('', '')),
('GASPAR TOMÁS', 'CARREÑO SOTO', '2017-05-14', '1° Básico B', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25764187-2', '110', '267', '2024-03-25', '', 'MASCULINO', 'CHILENA', '2024-03-25', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda N° 8 C° Placeres', 'VALPARAISO', 'MADRE, PADRE, HERMANO', nullif('', '')),
('LUCAS MIGUEL', 'CARREÑO SOTO', '2014-11-21', '4° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24805440-9', '310', '276', '2010-04-19', '', 'MASCULINO', 'CHILENA', '2024-09-04', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda 8 Cerrp Placeres', 'VALPARAISO', 'MADRE, PADRE, HERNANA', nullif('', '')),
('LUCIANO MATEO', 'LEONART CORTÉS', '2017-12-28', '1° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25617549-5', '310', '209', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2024-05-03', '2024-11-03', 'SI', 'WINTERHILL', 'jardines del bosque 544 curauma', 'VALPARAISO', 'MADRE', 'cambio a escuela especial'),
('FLORENCIA', 'OLIVARES FREZ', '2024-10-17', '7° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23774788-7', '310', '284', '2024-05-28', '', 'FEMENINO', 'CHILENA', '2024-05-28', nullif('', '')::date, 'NO', 'King Eswards', 'Avenida Segunda 0650 Casa E', 'QUILPUÉ', 'PADRE', nullif('', '')),
('FLORENCIA ANTONIA', 'FUNES GARVISO', '2010-02-13', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23252188-0', '310', '13', '2023-12-27', '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'LUIS URIBE 150 CASA 17, COND.CASAS DE FLORENCIA, EL RETIRO, QUILPUÉ, REGIÓN DE VALPARAÍSO', 'QUILPUÉ', 'MADRE', nullif('', '')),
('MAITE ALMENDRA', 'GONZÁLEZ LEÓN', '2009-06-05', '1° Medio B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23012560-0', '310', '11', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Camilo henriquez 0260', 'QUILPUÉ', 'MADRE', nullif('', '')),
('FERNANDA ALEXIA', 'MUÑOZ MOLINA', '2009-01-03', '2° Medio B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23013869-9', '310', '18', '2023-12-14', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Frutillar 887 Belloto Norte Quilpue', 'QUILPUÉ', 'MADRE, PADRE', nullif('', '')),
('TOMÁS SALVADOR', 'CAÑÓN BERNOFF', '2008-04-26', '3° Básico A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22708810-9', '310', '6', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Av los carrera 1360 depto 22 belloto 2000 quilpue', 'QUILPUÉ', 'MADRE', nullif('', '')),
('PABLO ANDRÉS', 'DÍAZ FUENZALIDA', '2008-02-04', '3° Medio A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22684772-3', '310', '11', '2023-12-14', '', 'MASCULINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Calle los Copihues 1187', 'QUILPUÉ', 'MADRE', nullif('', '')),
('GABRIEL ANTONIO', 'FLORES AROS', '2008-10-06', '2° Medio A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22832796-4', '310', '12', '2023-12-19', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Los maitenes 336 villa Berlin cerro los placeres valparaiso', 'VALPARAISO', 'PADRE', nullif('', '')),
('GASPAR TOMÁS', 'CARREÑO SOTO', '2017-05-14', '1° Básico B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25764187-2', '110', '267', '2024-03-25', '', 'MASCULINO', 'CHILENA', '2024-03-25', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda N° 8 C° Placeres', 'VALPARAISO', 'MADRE, PADRE, HERMANO', nullif('', '')),
('LUCAS MIGUEL', 'CARREÑO SOTO', '2014-11-21', '4° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24805440-9', '310', '276', '2010-04-19', '', 'MASCULINO', 'CHILENA', '2024-09-04', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda 8 Cerrp Placeres', 'VALPARAISO', 'MADRE, PADRE, HERNANA', nullif('', '')),
('LUCIANO MATEO', 'LEONART CORTÉS', '2017-12-28', '1° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25617549-5', '310', '209', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2024-05-03', '2024-11-03', 'SI', 'WINTERHILL', 'jardines del bosque 544 curauma', 'VALPARAISO', 'MADRE', 'cambio a escuela especial'),
('FLORENCIA', 'OLIVARES FREZ', '2024-10-17', '7° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23774788-7', '310', '284', '2024-05-28', '', 'FEMENINO', 'CHILENA', '2024-05-28', nullif('', '')::date, 'NO', 'King Eswards', 'Avenida Segunda 0650 Casa E', 'QUILPUÉ', 'PADRE', nullif('', '')),
('FLORENCIA ANTONIA', 'FUNES GARVISO', '2010-02-13', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23252188-0', '310', '13', '2023-12-27', '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'LUIS URIBE 150 CASA 17, COND.CASAS DE FLORENCIA, EL RETIRO, QUILPUÉ, REGIÓN DE VALPARAÍSO', 'QUILPUÉ', 'MADRE', nullif('', '')),
('MAITE ALMENDRA', 'GONZÁLEZ LEÓN', '2009-06-05', '1° Medio B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23012560-0', '310', '11', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Camilo henriquez 0260', 'QUILPUÉ', 'MADRE', nullif('', '')),
('FERNANDA ALEXIA', 'MUÑOZ MOLINA', '2009-01-03', '2° Medio B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23013869-9', '310', '18', '2023-12-14', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Frutillar 887 Belloto Norte Quilpue', 'QUILPUÉ', 'MADRE, PADRE', nullif('', '')),
('TOMÁS SALVADOR', 'CAÑÓN BERNOFF', '2008-04-26', '3° Básico A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22708810-9', '310', '6', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Av los carrera 1360 depto 22 belloto 2000 quilpue', 'QUILPUÉ', 'MADRE', nullif('', '')),
('PABLO ANDRÉS', 'DÍAZ FUENZALIDA', '2008-02-04', '3° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22684772-3', '310', '11', '2023-12-14', '', 'MASCULINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Calle los Copihues 1187', 'QUILPUÉ', 'MADRE', nullif('', '')),
('GABRIEL ANTONIO', 'FLORES AROS', '2008-10-06', '2° Medio A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22832796-4', '310', '12', '2023-12-19', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Los maitenes 336 villa Berlin cerro los placeres valparaiso', 'VALPARAISO', 'PADRE', nullif('', '')),
('GASPAR TOMÁS', 'CARREÑO SOTO', '2017-05-14', '1° Básico B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25764187-2', '110', '267', '2024-03-25', '', 'MASCULINO', 'CHILENA', '2024-03-25', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda N° 8 C° Placeres', 'VALPARAISO', 'MADRE, PADRE, HERMANO', nullif('', '')),
('LUCAS MIGUEL', 'CARREÑO SOTO', '2014-11-21', '4° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24805440-9', '310', '276', '2010-04-19', '', 'MASCULINO', 'CHILENA', '2024-09-04', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda 8 Cerrp Placeres', 'VALPARAISO', 'MADRE, PADRE, HERNANA', nullif('', '')),
('LUCIANO MATEO', 'LEONART CORTÉS', '2017-12-28', '1° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25617549-5', '310', '209', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2024-05-03', '2024-11-03', 'SI', 'WINTERHILL', 'jardines del bosque 544 curauma', 'VALPARAISO', 'MADRE', 'cambio a escuela especial'),
('FLORENCIA', 'OLIVARES FREZ', '2024-10-17', '7° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23774788-7', '310', '284', '2024-05-28', '', 'FEMENINO', 'CHILENA', '2024-05-28', nullif('', '')::date, 'NO', 'King Eswards', 'Avenida Segunda 0650 Casa E', 'QUILPUÉ', 'PADRE', nullif('', '')),
('FLORENCIA ANTONIA', 'FUNES GARVISO', '2010-02-13', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23252188-0', '310', '13', '2023-12-27', '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'LUIS URIBE 150 CASA 17, COND.CASAS DE FLORENCIA, EL RETIRO, QUILPUÉ, REGIÓN DE VALPARAÍSO', 'QUILPUÉ', 'MADRE', nullif('', '')),
('MAITE ALMENDRA', 'GONZÁLEZ LEÓN', '2009-06-05', '1° Medio B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23012560-0', '310', '11', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Camilo henriquez 0260', 'QUILPUÉ', 'MADRE', nullif('', '')),
('FERNANDA ALEXIA', 'MUÑOZ MOLINA', '2009-01-03', '2° Medio B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23013869-9', '310', '18', '2023-12-14', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Frutillar 887 Belloto Norte Quilpue', 'QUILPUÉ', 'MADRE, PADRE', nullif('', '')),
('TOMÁS SALVADOR', 'CAÑÓN BERNOFF', '2008-04-26', '3° Básico A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22708810-9', '310', '6', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Av los carrera 1360 depto 22 belloto 2000 quilpue', 'QUILPUÉ', 'MADRE', nullif('', '')),
('PABLO ANDRÉS', 'DÍAZ FUENZALIDA', '2008-02-04', '3° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22684772-3', '310', '11', '2023-12-14', '', 'MASCULINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Calle los Copihues 1187', 'QUILPUÉ', 'MADRE', nullif('', '')),
('GABRIEL ANTONIO', 'FLORES AROS', '2008-10-06', '2° Medio A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22832796-4', '310', '12', '2023-12-19', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Los maitenes 336 villa Berlin cerro los placeres valparaiso', 'VALPARAISO', 'PADRE', nullif('', '')),
('GASPAR TOMÁS', 'CARREÑO SOTO', '2017-05-14', '1° Básico B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25764187-2', '110', '267', '2024-03-25', '', 'MASCULINO', 'CHILENA', '2024-03-25', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda N° 8 C° Placeres', 'VALPARAISO', 'MADRE, PADRE, HERMANO', nullif('', '')),
('LUCAS MIGUEL', 'CARREÑO SOTO', '2014-11-21', '4° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24805440-9', '310', '276', '2010-04-19', '', 'MASCULINO', 'CHILENA', '2024-09-04', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda 8 Cerrp Placeres', 'VALPARAISO', 'MADRE, PADRE, HERNANA', nullif('', '')),
('LUCIANO MATEO', 'LEONART CORTÉS', '2017-12-28', '1° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25617549-5', '310', '209', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2024-05-03', '2024-11-03', 'SI', 'WINTERHILL', 'jardines del bosque 544 curauma', 'VALPARAISO', 'MADRE', 'cambio a escuela especial'),
('FLORENCIA', 'OLIVARES FREZ', '2024-10-17', '7° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23774788-7', '310', '284', '2024-05-28', '', 'FEMENINO', 'CHILENA', '2024-05-28', nullif('', '')::date, 'NO', 'King Eswards', 'Avenida Segunda 0650 Casa E', 'QUILPUÉ', 'PADRE', nullif('', '')),
('FLORENCIA ANTONIA', 'FUNES GARVISO', '2010-02-13', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23252188-0', '310', '13', '2023-12-27', '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'LUIS URIBE 150 CASA 17, COND.CASAS DE FLORENCIA, EL RETIRO, QUILPUÉ, REGIÓN DE VALPARAÍSO', 'QUILPUÉ', 'MADRE', nullif('', '')),
('MAITE ALMENDRA', 'GONZÁLEZ LEÓN', '2009-06-05', '1° Medio B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23012560-0', '310', '11', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Camilo henriquez 0260', 'QUILPUÉ', 'MADRE', nullif('', '')),
('FERNANDA ALEXIA', 'MUÑOZ MOLINA', '2009-01-03', '2° Medio B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23013869-9', '310', '18', '2023-12-14', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Frutillar 887 Belloto Norte Quilpue', 'QUILPUÉ', 'MADRE, PADRE', nullif('', '')),
('TOMÁS SALVADOR', 'CAÑÓN BERNOFF', '2008-04-26', '3° Básico A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22708810-9', '310', '6', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Av los carrera 1360 depto 22 belloto 2000 quilpue', 'QUILPUÉ', 'MADRE', nullif('', '')),
('PABLO ANDRÉS', 'DÍAZ FUENZALIDA', '2008-02-04', '3° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22684772-3', '310', '11', '2023-12-14', '', 'MASCULINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Calle los Copihues 1187', 'QUILPUÉ', 'MADRE', nullif('', '')),
('GABRIEL ANTONIO', 'FLORES AROS', '2008-10-06', '2° Medio A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22832796-4', '310', '12', '2023-12-19', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Los maitenes 336 villa Berlin cerro los placeres valparaiso', 'VALPARAISO', 'PADRE', nullif('', '')),
('GASPAR TOMÁS', 'CARREÑO SOTO', '2017-05-14', '1° Básico B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25764187-2', '110', '267', '2024-03-25', '', 'MASCULINO', 'CHILENA', '2024-03-25', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda N° 8 C° Placeres', 'VALPARAISO', 'MADRE, PADRE, HERMANO', nullif('', '')),
('LUCAS MIGUEL', 'CARREÑO SOTO', '2014-11-21', '4° Básico A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24805440-9', '310', '276', '2010-04-19', '', 'MASCULINO', 'CHILENA', '2024-09-04', nullif('', '')::date, 'NO', 'NO DISPONIBLE', 'Guacolda 8 Cerrp Placeres', 'VALPARAISO', 'MADRE, PADRE, HERNANA', nullif('', '')),
('LUCIANO MATEO', 'LEONART CORTÉS', '2017-12-28', '1° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25617549-5', '310', '209', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2024-05-03', '2024-11-03', 'SI', 'WINTERHILL', 'jardines del bosque 544 curauma', 'VALPARAISO', 'MADRE, PADRE, HNOS', nullif('', '')),
('FLORENCIA', 'OLIVARES FREZ', '2024-10-17', '7° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23774788-7', '310', '284', '2024-05-28', '', 'FEMENINO', 'CHILENA', '2024-05-28', nullif('', '')::date, 'NO', 'King Eswards', 'Avenida Segunda 0650 Casa E', 'QUILPUÉ', 'PADRE', nullif('', '')),
('FLORENCIA ANTONIA', 'FUNES GARVISO', '2010-02-13', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23252188-0', '310', '13', '2023-12-27', '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'LUIS URIBE 150 CASA 17, COND.CASAS DE FLORENCIA, EL RETIRO, QUILPUÉ, REGIÓN DE VALPARAÍSO', 'QUILPUÉ', 'MADRE', nullif('', '')),
('MAITE ALMENDRA', 'GONZÁLEZ LEÓN', '2009-06-05', '1° Medio B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23012560-0', '310', '11', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Camilo henriquez 0260', 'QUILPUÉ', 'MADRE', nullif('', '')),
('FERNANDO EVANS', 'MUÑOZ CARRILLO', '2013-02-25', '6° Básico A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24201235-6', '110', '263', '2024-03-13', '', 'MASCULINO', 'CHILENA', '2023-05-03', '2024-07-06', 'NO', 'Adriana Machado', 'Avda Gregorio Marañon 2415 Dp 147', 'VIÑA DEL MAR', 'MADRE, 1 HERMANO', 'cambio institución'),
('LEONOR ALEXANDRA', 'BARRERA ARANCIBIA', '2008-09-07', '2° Básico B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22767771-6', '310', '5', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'C. P. Momtt', 'Martín de Salvatierra 550 Dp 12 Reñaca', 'VIÑA DEL MAR', 'MADRE', nullif('', '')),
('FELIPE ALEXANDER', 'VERGARA JARAMILLO', '2011-01-21', '7° Básico B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23541383-3', '110', '282', '2024-05-08', '', 'MASCULINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'Col. Afriano Machado', 'Los Boldos 80 Pob. Sabntiago Ferrari Nueva aurora', 'VIÑA DEL MAR', 'MADRE, HERMANO Y PADRASTRO', nullif('', '')),
('EMA FAIRUZ', 'ALFARO ARANCIBIA', '2024-08-14', '1° Básico A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25872208-6', '110', '288', '2024-07-23', '', 'FEMENINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'Col. Blanca Vergara', 'Vergara 775 Block E/18 Dpto 204 -7 Hermanas, Forestal', 'VIÑA DEL MAR', 'PADRE Y MADRE', nullif('', '')),
('GABRIEL ANDRÉS', 'SALAZAR GASSET', '2009-08-04', '1° Medio A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22997676-1', '', '23', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'Col. Nazareno', 'Augusto Velásquez 764 Viña del Mar', 'VIÑA DEL MAR', 'MADRE, PADRE, HERMANO', nullif('', '')),
('EMA FAIRUZ', 'ALFARO ARANCIBIA', '2024-08-14', '1° Básico A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25872208-6', '110', '288', '2024-07-23', '', 'FEMENINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'Col. Blanca Vergara', 'Vergara 775 Block E/18 Dpto 204 -7 Hermanas, Forestal', 'VIÑA DEL MAR', 'PADRE Y MADRE', nullif('', '')),
('GABRIEL ANDRÉS', 'SALAZAR GASSET', '2009-08-04', '1° Medio A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22997676-1', '', '23', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'Col. Nazareno', 'Augusto Velásquez 764 Viña del Mar', 'VIÑA DEL MAR', 'MADRE, PADRE, HERMANO', nullif('', '')),
('IGNACIO JAVIER', 'ALLENDE TABILO', '2014-02-05', '3° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '24609631-7', '110', '254', '2024-03-12', '', 'MASCULINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'Col. San Andrés', 'Avda. Bellamonte sasa 1 Nueva Aurora', 'VIÑA DEL MAR', 'MADRE, PADRE, 2 HNOS', nullif('', '')),
('MUNAY ANTAY', 'AGÜERO VIDAL', '2017-11-11', '1° Básico B', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25980651-8', '110', '257', '2024-03-13', '', 'MASCULINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'Colegio Alemania', 'Irene Frei 126 Nueva aurora', 'VIÑA DEL MAR', 'MADRE', nullif('', '')),
('AMARO MAURICIO', 'LEIVA PALMA', '2015-10-07', '2° Básico B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25038237-5', '110', '262', '2024-03-13', '', 'MASCULINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'Colegio Nacional', 'Av. Marina 84 Dp 46', 'VIÑA DEL MAR', 'MADRE, 1 HERMANO', nullif('', '')),
('THOMAS VALENTIN', 'LASNIER FIGUEROA', '2017-07-14', '1° Básico B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25840798-9', '110', '258', '2024-03-13', '', 'MASCULINO', 'CHILENA', '2023-05-03', nullif('', '')::date, 'NO', 'Colegio Siglo XXI', 'Del Agua 1155 Dp 806', 'VIÑA DEL MAR', 'MADRE', nullif('', '')),
('MATIAS SALVADOR', 'VALPREDA VIVEROS', '2016-12-30', '2° Básico A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '25618895-3', '110', '261', '2024-03-13', '', 'MASCULINO', 'CHILENA', '2023-03-13', nullif('', '')::date, 'NO', 'Escuela Grecia', 'Freire 470 Dp 95', 'VALPARAISO', 'MADRE', nullif('', '')),
('DARÍO FERNANDO', 'NAVARRO GÓMEZ', '2011-03-09', '7° Básico B', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23741211-7', '110', '278', '2024-04-15', '', 'MASCULINO', 'CHILENA', '2024-04-15', nullif('', '')::date, 'NO', 'Montesorri', 'Alvaro Besa 626', 'VALPARAISO', 'MADRE, HERMANOS PAREJA DE LA MADRE', nullif('', '')),
('ARIEL EMILIO', 'BARRÍA ZÁRRAGA', '2009-09-14', '1° Medio A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23126375-6', '310', '4', '2023-12-13', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Pje. Pastene 46 C° Polanco', 'VALPARAISO', 'MADRE, PADRE, HNOS', nullif('', '')),
('CRISTIÁN ENRIQUE', 'BIERMORITZ VIDELA', '2007-08-11', '1° Medio A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22552320-7', '310', '5', '2023-12-27', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Manuel Antonio Matta 3321  Cerro Placeres', 'VALPARAISO', 'MADRE', nullif('', '')),
('DANIELA IGNACIA AURELIA', 'DURÁN FERNÁNDEZ', '2009-11-11', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23167878-6', '310', '10', '2023-12-13', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'San Jorge 238, Barrio Ohiggins,', 'VALPARAISO', 'MADRE, PADRE', nullif('', '')),
('JULIETA', 'HERRERA CARRASCO', '2009-09-01', '1° Medio A', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22921315-6', '310', '15', '2023-12-27', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'ALMTE. MONTT 566', 'VALPARAISO', 'MADRE', nullif('', '')),
('GABRIELA ANTONIA', 'MORALES VELASCO', '2009-03-04', '1° Medio A', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '22989124-3', '310', '17', nullif('', '')::date, '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'toro zambrano 382, C° esperanza', 'VALPARAISO', 'MADFRE', nullif('', '')),
('ANTONELLA IGNACIA', 'NEGRETE IBACACHE', '2010-04-26', '1° Medio A', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23308414-K', '310', '18', '2023-12-13', '', 'FEMENINO', '', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Camino real 256, San Roque', 'VALPARAISO', 'MADRE', nullif('', '')),
('MATILDA ANAÍS', 'FERREIRA CABELLO', '2009-04-30', '1° Medio B', '2025-02-17 18:00:37.378104+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23011054-9', '310', '9', '2023-12-13', '', '', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'Francisco Echaurren block E dpto 2', 'VALPARAISO', 'MADRE', nullif('', '')),
('EMILY LUNA', 'ROJAS AGUILERA', '2010-02-23', '1° Medio B', '2025-02-17 18:03:22.628121+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23268049-0', '310', '20', '2023-12-12', '', 'FEMENINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', '  Calle Beaucheff  120  Barrio OHiggins', 'VALPARAISO', 'TUTORA', nullif('', '')),
('LEÓN IGNACIO', 'TORRES MOLINA', '2009-06-17', '1° Medio B', '2025-02-17 17:56:46.273746+00', '2025-02-17 18:03:22.628121+00', '43271e5f-1433-4536-b4f9-ed4158e6e071', '23051527-1', '310', '23', '2023-12-26', '', 'MASCULINO', 'CHILENA', '2024-05-03', nullif('', '')::date, 'NO', 'WINTERHILL', 'José Tomás Ramos 1011 depto 402', 'VALPARAISO', 'MADRE', nullif('', ''));



  -- Insert student-guardian relationships
  INSERT INTO student_guardian (student_id, guardian_id) VALUES
    ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-1111-1111-111111111111'),
 
   

  -- Insert sample fee records
  INSERT INTO fee (student_id, guardian_id, amount, payment_date, payment_status, payment_method, owner_id) VALUES
    ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-1111-1111-111111111111', 250.00, '2024-02-01', 'Pagado', 'Efectivo', v_system_user_id),
   

  -- Create RLS policies
  ALTER TABLE students ENABLE ROW LEVEL SECURITY;
  ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
  ALTER TABLE student_guardian ENABLE ROW LEVEL SECURITY;
  ALTER TABLE fee ENABLE ROW LEVEL SECURITY;

  -- Students policies
  CREATE POLICY "Users can view all students"
    ON students FOR SELECT
    TO authenticated
    USING (true);

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

  -- Guardians policies
  CREATE POLICY "Users can view all guardians"
    ON guardians FOR SELECT
    TO authenticated
    USING (true);

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

  -- Student-Guardian policies
  CREATE POLICY "Users can view all student-guardian relationships"
    ON student_guardian FOR SELECT
    TO authenticated
    USING (true);

  CREATE POLICY "Users can manage student-guardian relationships"
    ON student_guardian FOR ALL
    TO authenticated
    USING (true);

  -- Fee policies
  CREATE POLICY "Users can view all fees"
    ON fee FOR SELECT
    TO authenticated
    USING (true);

  CREATE POLICY "Users can insert their own fees"
    ON fee FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = owner_id);

  CREATE POLICY "Users can update their own fees"
    ON fee FOR UPDATE
    TO authenticated
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

  CREATE POLICY "Users can delete their own fees"
    ON fee FOR DELETE
    TO authenticated
    USING (auth.uid() = owner_id);

END $$;