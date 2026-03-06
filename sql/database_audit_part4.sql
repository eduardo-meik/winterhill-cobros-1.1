-- ============================================================
-- PARTE 4: INCONSISTENCIAS LÓGICAS
-- ============================================================

-- 4a. Fees pagadas sin fecha de pago
SELECT '=== 4a: Fees pagadas sin payment_date ===' AS seccion;
SELECT id, student_id, amount, status, payment_date, year_academico, numero_cuota
FROM fee
WHERE status = 'paid' AND payment_date IS NULL;

-- 4b. Fees con fecha de pago pero no marcadas como pagadas
SELECT '=== 4b: Fees con payment_date pero status != paid ===' AS seccion;
SELECT id, student_id, amount, status, payment_date, year_academico, numero_cuota
FROM fee
WHERE payment_date IS NOT NULL AND status != 'paid';

-- 4c. Fees con monto <= 0
SELECT '=== 4c: Fees con monto <= 0 ===' AS seccion;
SELECT id, student_id, amount, status, year_academico, numero_cuota
FROM fee
WHERE amount <= 0;

-- 4d. Fees con due_date en el futuro lejano o pasado absurdo
SELECT '=== 4d: Fees con due_date fuera de rango razonable ===' AS seccion;
SELECT id, student_id, amount, due_date, year_academico
FROM fee
WHERE due_date < '2020-01-01' OR due_date > '2027-12-31';

-- 4e. Fees con payment_date anterior a due_date por más de 1 año
SELECT '=== 4e: Fees con payment_date mucho antes de due_date ===' AS seccion;
SELECT id, student_id, amount, due_date, payment_date, 
       payment_date - due_date AS dias_diferencia
FROM fee
WHERE payment_date IS NOT NULL 
  AND payment_date < due_date - INTERVAL '365 days';

-- 4f. Enrollments en estado 'completed' sin enrollment_students
SELECT '=== 4f: Enrollments completed sin estudiantes asignados ===' AS seccion;
SELECT e.id, e.guardian_id, e.year, e.status
FROM enrollments e
LEFT JOIN enrollment_students es ON es.enrollment_id = e.id
WHERE e.status = 'completed' AND es.enrollment_id IS NULL;

-- 4g. Estudiantes sin guardian asignado en student_guardian
SELECT '=== 4g: Estudiantes sin ningún guardian ===' AS seccion;
SELECT s.id, s.first_name, s.apellido_paterno, s.run
FROM students s
LEFT JOIN student_guardian sg ON sg.student_id = s.id
WHERE sg.id IS NULL;

-- 4h. Guardians sin ningún estudiante asignado
SELECT '=== 4h: Guardians sin ningún estudiante ===' AS seccion;
SELECT g.id, g.first_name, g.last_name, g.run
FROM guardians g
LEFT JOIN student_guardian sg ON sg.guardian_id = g.id
WHERE sg.id IS NULL;

-- 4i. Estudiantes con fecha_retiro pero sin motivo_retiro
SELECT '=== 4i: Estudiantes retirados sin motivo ===' AS seccion;
SELECT id, first_name, apellido_paterno, run, fecha_retiro, motivo_retiro
FROM students
WHERE fecha_retiro IS NOT NULL AND (motivo_retiro IS NULL OR motivo_retiro = '');

-- 4j. Estudiantes con fecha de nacimiento inválida
SELECT '=== 4j: Estudiantes con fecha nacimiento sospechosa ===' AS seccion;
SELECT id, first_name, apellido_paterno, run, date_of_birth,
       EXTRACT(YEAR FROM AGE(date_of_birth)) AS edad
FROM students
WHERE date_of_birth < '1990-01-01' OR date_of_birth > '2023-01-01';

-- 4k. Cheques con monto <= 0
SELECT '=== 4k: Cheques con monto <= 0 ===' AS seccion;
SELECT id, enrollment_id, monto, estado, banco
FROM cheques
WHERE monto <= 0;

-- 4l. Cheques pendientes con fecha muy antigua
SELECT '=== 4l: Cheques pendientes con fecha antigua (> 6 meses) ===' AS seccion;
SELECT id, enrollment_id, monto, estado, fecha_emision, banco
FROM cheques
WHERE estado = 'pendiente' AND fecha_emision < CURRENT_DATE - INTERVAL '180 days';

-- 4m. Enrollment documents firmados (signed) sin signed_at
SELECT '=== 4m: Documents signed sin signed_at ===' AS seccion;
SELECT id, enrollment_id, type, status, signed_at
FROM enrollment_documents
WHERE status = 'signed' AND signed_at IS NULL;

-- 4n. Enrollment documents con signed_at pero status != signed
SELECT '=== 4n: Documents con signed_at pero no signed ===' AS seccion;
SELECT id, enrollment_id, type, status, signed_at
FROM enrollment_documents
WHERE signed_at IS NOT NULL AND status != 'signed';

-- 4o. Profiles con role inválido
SELECT '=== 4o: Profiles con role inválido ===' AS seccion;
SELECT id, email, role, first_name, last_name
FROM profiles
WHERE role NOT IN ('admin', 'guardian', 'superadmin', 'viewer', 'staff');

-- 4p. Fee con year_academico fuera de rango
SELECT '=== 4p: Fees con year_academico fuera de rango ===' AS seccion;
SELECT id, student_id, amount, year_academico, numero_cuota
FROM fee
WHERE year_academico < 2024 OR year_academico > 2027;

-- 4q. Enrollments con year fuera de rango
SELECT '=== 4q: Enrollments con year fuera de rango ===' AS seccion;
SELECT id, guardian_id, year, status
FROM enrollments
WHERE year < 2024 OR year > 2027;

-- 4r. Fee con status inválido
SELECT '=== 4r: Fees con status inválido ===' AS seccion;
SELECT id, student_id, status, amount, year_academico
FROM fee
WHERE status NOT IN ('pending', 'paid', 'overdue', 'cancelled', 'partial', 'waived');

-- 4s. Enrollments con status inválido
SELECT '=== 4s: Enrollments con status inválido ===' AS seccion;
SELECT id, guardian_id, year, status
FROM enrollments
WHERE status NOT IN ('draft', 'in_progress', 'completed', 'cancelled', 'active', 'archived');

-- 4t. Guardians con email inválido (sin @)
SELECT '=== 4t: Guardians con email inválido ===' AS seccion;
SELECT id, first_name, last_name, email
FROM guardians
WHERE email IS NOT NULL AND email != '' AND email NOT LIKE '%@%.%';

-- 4u. Students con run_numero NULL pero run NOT NULL
SELECT '=== 4u: Students con run pero sin run_numero ===' AS seccion;
SELECT id, first_name, apellido_paterno, run, run_numero
FROM students
WHERE run IS NOT NULL AND run != '' AND run_numero IS NULL;

-- 4v. Estudiantes con mismo nombre completo (posibles duplicados)
SELECT '=== 4v: Posibles estudiantes duplicados por nombre ===' AS seccion;
SELECT first_name, apellido_paterno, COALESCE(apellido_materno, '') AS apellido_materno,
       COUNT(*) AS cnt, array_agg(id) AS ids, array_agg(run) AS runs
FROM students
GROUP BY first_name, apellido_paterno, COALESCE(apellido_materno, '')
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- 4w. Guardians con mismo nombre completo (posibles duplicados)
SELECT '=== 4w: Posibles guardians duplicados por nombre ===' AS seccion;
SELECT first_name, last_name, COUNT(*) AS cnt, 
       array_agg(id) AS ids, array_agg(run) AS runs
FROM guardians
GROUP BY first_name, last_name
HAVING COUNT(*) > 1
ORDER BY cnt DESC;
