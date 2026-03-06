-- ============================================================
-- REGISTROS PARA REVISIÓN MANUAL
-- ============================================================

-- A. DATOS DE PRUEBA / TEST en students
SELECT '=== A: Estudiantes sospechosos (test/falso/prueba) ===' AS seccion;
SELECT id, first_name, apellido_paterno, COALESCE(apellido_materno,'') AS apellido_materno, 
       run, fecha_retiro, created_at::date
FROM students 
WHERE LOWER(first_name) ~ '(test|prueba|falso|nuevo|mama|papa|nnnnn|no disponible)'
   OR LOWER(apellido_paterno) ~ '(test|prueba|falso|nuevo)'
ORDER BY created_at;

-- B. DATOS DE PRUEBA / TEST en guardians
SELECT '=== B: Guardians sospechosos (test/falso/prueba) ===' AS seccion;
SELECT id, first_name, last_name, run, email, created_at::date
FROM guardians 
WHERE LOWER(first_name) ~ '(test|prueba|falso|nuevo|mama|papa|nnnnn|no disponible|apoderado test)'
   OR LOWER(last_name) ~ '(test|prueba|falso|nuevo)'
ORDER BY created_at;

-- C. FEES PAGADAS SIN FECHA DE PAGO
SELECT '=== C: Fees pagadas sin payment_date ===' AS seccion;
SELECT f.id, f.student_id, 
       s.first_name || ' ' || s.apellido_paterno AS nombre_alumno,
       f.amount, f.status, f.payment_date, f.year_academico, f.numero_cuota,
       f.created_at::date, f.updated_at::date
FROM fee f
JOIN students s ON s.id = f.student_id
WHERE f.status = 'paid' AND f.payment_date IS NULL;

-- D. FEES CON FECHAS DE PAGO ABSURDAS
SELECT '=== D: Fees con payment_date absurda ===' AS seccion;
SELECT f.id, f.student_id, 
       s.first_name || ' ' || s.apellido_paterno AS nombre_alumno,
       f.amount, f.status, f.due_date, f.payment_date,
       f.year_academico, f.numero_cuota
FROM fee f
JOIN students s ON s.id = f.student_id
WHERE f.payment_date IS NOT NULL 
  AND (f.payment_date < '2020-01-01' OR f.payment_date > '2027-12-31');

-- E. ESTUDIANTES CON FECHA DE NACIMIENTO SOSPECHOSA
SELECT '=== E: Estudiantes con fecha nacimiento invalida ===' AS seccion;
SELECT id, first_name, apellido_paterno, run, date_of_birth,
       EXTRACT(YEAR FROM AGE(date_of_birth))::int AS edad_calculada
FROM students
WHERE date_of_birth IS NOT NULL 
  AND (date_of_birth < '1990-01-01' OR date_of_birth > '2023-01-01')
ORDER BY date_of_birth;

-- F. ESTUDIANTES RETIRADOS SIN MOTIVO
SELECT '=== F: Estudiantes retirados sin motivo ===' AS seccion;
SELECT id, first_name, apellido_paterno, run, fecha_retiro, motivo_retiro
FROM students
WHERE fecha_retiro IS NOT NULL AND (motivo_retiro IS NULL OR motivo_retiro = '');

-- G. DISCREPANCIA CURSO ACTUAL vs ACADEMIC RECORD
SELECT '=== G: Curso en students != academic_record activo ===' AS seccion;
SELECT s.id, s.first_name || ' ' || s.apellido_paterno AS nombre,
       s.run,
       c1.nom_curso AS curso_en_students,
       c2.nom_curso AS curso_en_academic_record,
       sar.year_academico
FROM students s
JOIN student_academic_records sar ON sar.student_id = s.id AND sar.estado = 'activo'
LEFT JOIN cursos c1 ON c1.id = s.curso
LEFT JOIN cursos c2 ON c2.id = sar.curso_id
WHERE s.curso != sar.curso_id
ORDER BY sar.year_academico, s.apellido_paterno;

-- H. POSIBLES ESTUDIANTES DUPLICADOS POR NOMBRE
SELECT '=== H: Posibles estudiantes duplicados ===' AS seccion;
SELECT s.id, s.first_name, s.apellido_paterno, s.apellido_materno, s.run, 
       c.nom_curso, s.created_at::date
FROM students s
LEFT JOIN cursos c ON c.id = s.curso
WHERE (s.first_name, s.apellido_paterno, COALESCE(s.apellido_materno, '')) IN (
  SELECT first_name, apellido_paterno, COALESCE(apellido_materno, '')
  FROM students
  GROUP BY first_name, apellido_paterno, COALESCE(apellido_materno, '')
  HAVING COUNT(*) > 1
)
ORDER BY s.apellido_paterno, s.first_name, s.run;

-- I. POSIBLES GUARDIANS DUPLICADOS POR NOMBRE
SELECT '=== I: Posibles guardians duplicados ===' AS seccion;
SELECT g.id, g.first_name, g.last_name, g.run, g.email, g.created_at::date
FROM guardians g
WHERE (g.first_name, g.last_name) IN (
  SELECT first_name, last_name
  FROM guardians
  GROUP BY first_name, last_name
  HAVING COUNT(*) > 1
)
ORDER BY g.last_name, g.first_name, g.run;

-- J. GUARDIAN CON EMAIL INVÁLIDO
SELECT '=== J: Guardians con email invalido ===' AS seccion;
SELECT id, first_name, last_name, run, email
FROM guardians
WHERE email IS NOT NULL AND email != '' AND email NOT LIKE '%@%.%';

-- K. ENROLLMENT AÑO FUERA DE RANGO
SELECT '=== K: Enrollments con year fuera de rango ===' AS seccion;
SELECT e.id, e.guardian_id, 
       g.first_name || ' ' || g.last_name AS nombre_guardian,
       e.year, e.status, e.created_at::date
FROM enrollments e
LEFT JOIN guardians g ON g.id = e.guardian_id
WHERE e.year < 2024 OR e.year > 2027;

-- L. ESTUDIANTES SIN NINGÚN GUARDIAN (solo los que NO parecen test)
SELECT '=== L: Estudiantes reales sin guardian ===' AS seccion;
SELECT s.id, s.first_name, s.apellido_paterno, s.run,
       c.nom_curso, s.created_at::date
FROM students s
LEFT JOIN student_guardian sg ON sg.student_id = s.id
LEFT JOIN cursos c ON c.id = s.curso
WHERE sg.id IS NULL
ORDER BY s.apellido_paterno;

-- M. MÚLTIPLES GUARDIANS PRIMARIOS
SELECT '=== M: Estudiantes con 2+ guardians primarios ===' AS seccion;
SELECT s.id AS student_id, 
       s.first_name || ' ' || s.apellido_paterno AS nombre_alumno,
       s.run,
       sg.guardian_id,
       g.first_name || ' ' || g.last_name AS nombre_guardian
FROM student_guardian sg
JOIN students s ON s.id = sg.student_id
JOIN guardians g ON g.id = sg.guardian_id
WHERE sg.is_primary = true
  AND sg.student_id IN (
    SELECT student_id FROM student_guardian WHERE is_primary = true
    GROUP BY student_id HAVING COUNT(*) > 1
  )
ORDER BY s.apellido_paterno, s.first_name, sg.guardian_id;
