-- ============================================================
-- PARTE 5: INTEGRIDAD RELACIONAL Y CONSISTENCIA CRUZADA
-- ============================================================

-- 5a. Estudiantes en enrollment_students sin academic_record para ese año
SELECT '=== 5a: Estudiantes en enrollment sin academic_record ===' AS seccion;
SELECT es.student_id, es.enrollment_id, e.year,
       s.first_name || ' ' || s.apellido_paterno AS nombre
FROM enrollment_students es
JOIN enrollments e ON e.id = es.enrollment_id
JOIN students s ON s.id = es.student_id
LEFT JOIN student_academic_records sar 
  ON sar.student_id = es.student_id AND sar.year_academico = e.year
WHERE sar.id IS NULL
ORDER BY e.year, s.apellido_paterno;

-- 5b. Academic records sin enrollment_students correspondiente
SELECT '=== 5b: Academic records sin enrollment_students ===' AS seccion;
SELECT sar.id, sar.student_id, sar.year_academico, sar.curso_id,
       s.first_name || ' ' || s.apellido_paterno AS nombre
FROM student_academic_records sar
JOIN students s ON s.id = sar.student_id
LEFT JOIN enrollments e ON e.id = sar.enrollment_id
LEFT JOIN enrollment_students es 
  ON es.student_id = sar.student_id AND es.enrollment_id = sar.enrollment_id
WHERE sar.enrollment_id IS NOT NULL AND es.enrollment_id IS NULL;

-- 5c. Fee sin cuota para todos los meses esperados (10 cuotas mar-dic)
SELECT '=== 5c: Estudiantes con cuotas faltantes (año vigente 2026) ===' AS seccion;
WITH expected AS (
  SELECT DISTINCT student_id 
  FROM fee 
  WHERE year_academico = 2026
),
cuota_check AS (
  SELECT e.student_id,
         array_agg(DISTINCT f.numero_cuota ORDER BY f.numero_cuota) AS cuotas_existentes,
         COUNT(DISTINCT f.numero_cuota) AS total_cuotas
  FROM expected e
  LEFT JOIN fee f ON f.student_id = e.student_id AND f.year_academico = 2026
  GROUP BY e.student_id
)
SELECT cc.student_id, 
       s.first_name || ' ' || s.apellido_paterno AS nombre,
       cc.total_cuotas, cc.cuotas_existentes
FROM cuota_check cc
JOIN students s ON s.id = cc.student_id
WHERE cc.total_cuotas < 10
ORDER BY cc.total_cuotas, s.apellido_paterno;

-- 5d. Estudiante con curso actual diferente al de su academic_record activo
SELECT '=== 5d: Discrepancia curso actual vs academic_record ===' AS seccion;
SELECT s.id, s.first_name || ' ' || s.apellido_paterno AS nombre,
       s.curso AS curso_students, sar.curso_id AS curso_academic,
       c1.nom_curso AS nom_curso_student, c2.nom_curso AS nom_curso_academic,
       sar.year_academico
FROM students s
JOIN student_academic_records sar ON sar.student_id = s.id AND sar.estado = 'activo'
LEFT JOIN cursos c1 ON c1.id = s.curso
LEFT JOIN cursos c2 ON c2.id = sar.curso_id
WHERE s.curso != sar.curso_id;

-- 5e. Guardians con user_id (owner_id) sin profile correspondiente
SELECT '=== 5e: Guardians con owner_id sin profile ===' AS seccion;
SELECT g.id, g.first_name, g.last_name, g.owner_id, g.run
FROM guardians g
LEFT JOIN profiles p ON p.id = g.owner_id
WHERE p.id IS NULL;

-- 5f. Students con owner_id sin profile correspondiente
SELECT '=== 5f: Students con owner_id sin profile ===' AS seccion;
SELECT s.id, s.first_name, s.apellido_paterno, s.owner_id
FROM students s
LEFT JOIN profiles p ON p.id = s.owner_id
WHERE p.id IS NULL;

-- 5g. Enrollment_documents sin signatures cuando status = 'signed'
SELECT '=== 5g: Documents signed sin signature record ===' AS seccion;
SELECT ed.id, ed.enrollment_id, ed.type, ed.status
FROM enrollment_documents ed
LEFT JOIN signatures sig ON sig.enrollment_document_id = ed.id
WHERE ed.status = 'signed' AND sig.id IS NULL;

-- 5h. Estudiantes con multiple is_primary guardians
SELECT '=== 5h: Estudiantes con múltiples guardians primarios ===' AS seccion;
SELECT student_id, COUNT(*) AS primary_count, 
       array_agg(guardian_id) AS guardian_ids
FROM student_guardian
WHERE is_primary = true
GROUP BY student_id
HAVING COUNT(*) > 1;

-- 5i. Estudiantes sin ningún guardian primario
SELECT '=== 5i: Estudiantes sin guardian primario ===' AS seccion;
SELECT s.id, s.first_name || ' ' || s.apellido_paterno AS nombre, s.run
FROM students s
JOIN student_guardian sg ON sg.student_id = s.id
GROUP BY s.id, s.first_name, s.apellido_paterno, s.run
HAVING bool_or(sg.is_primary) IS NOT TRUE;

-- 5j. Cursos sin estudiantes asignados
SELECT '=== 5j: Cursos sin estudiantes ===' AS seccion;
SELECT c.id, c.nom_curso, c.letra_curso, c.year_academico
FROM cursos c
LEFT JOIN students s ON s.curso = c.id
WHERE s.id IS NULL
ORDER BY c.year_academico, c.nom_curso;

-- 5k. Datos económicos: Fee total por estudiante vs enrollment data
SELECT '=== 5k: Resumen fees por estudiante 2026 ===' AS seccion;
SELECT s.id, s.first_name || ' ' || s.apellido_paterno AS nombre,
       c.nom_curso,
       COUNT(f.id) AS total_fees,
       SUM(f.amount) AS monto_total,
       SUM(CASE WHEN f.status = 'paid' THEN f.amount ELSE 0 END) AS total_pagado,
       SUM(CASE WHEN f.status IN ('pending', 'overdue') THEN f.amount ELSE 0 END) AS total_pendiente
FROM students s
LEFT JOIN cursos c ON c.id = s.curso
LEFT JOIN fee f ON f.student_id = s.id AND f.year_academico = 2026
GROUP BY s.id, s.first_name, s.apellido_paterno, c.nom_curso
HAVING COUNT(f.id) > 0
ORDER BY total_pendiente DESC;

-- 5l. Guardians con claimed_at pero sin owner_id válido en profiles
SELECT '=== 5l: Guardians claimed sin profile vinculado ===' AS seccion;
SELECT g.id, g.first_name, g.last_name, g.run, g.claimed_at
FROM guardians g
WHERE g.claimed_at IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = g.owner_id AND p.role = 'guardian'
  );

-- 5m. Whitespace issues en nombres
SELECT '=== 5m: Estudiantes con espacios extra en nombres ===' AS seccion;
SELECT id, run,
       '>' || first_name || '<' AS first_name_check,
       '>' || apellido_paterno || '<' AS apellido_check
FROM students
WHERE first_name != TRIM(first_name)
   OR apellido_paterno != TRIM(apellido_paterno)
   OR first_name LIKE '%  %'
   OR apellido_paterno LIKE '%  %';

-- 5n. Whitespace issues en guardians
SELECT '=== 5n: Guardians con espacios extra en nombres ===' AS seccion;
SELECT id, run,
       '>' || first_name || '<' AS first_name_check,
       '>' || last_name || '<' AS last_name_check
FROM guardians
WHERE first_name != TRIM(first_name)
   OR last_name != TRIM(last_name)
   OR first_name LIKE '%  %'
   OR last_name LIKE '%  %';

-- 5o. RUN format validation (should be like 12345678-9 or 1234567-K)
SELECT '=== 5o: Students con RUN mal formateado ===' AS seccion;
SELECT id, first_name, apellido_paterno, run
FROM students
WHERE run !~ '^\d{7,8}-[\dkK]$';

-- 5p. Guardian RUN format validation
SELECT '=== 5p: Guardians con RUN mal formateado ===' AS seccion;
SELECT id, first_name, last_name, run
FROM guardians
WHERE run !~ '^\d{7,8}-[\dkK]$';

-- 5q. updated_at anterior a created_at
SELECT '=== 5q: Registros con updated_at < created_at ===' AS seccion;
SELECT 'students' AS tabla, id, created_at, updated_at FROM students WHERE updated_at < created_at
UNION ALL
SELECT 'guardians', id, created_at, updated_at FROM guardians WHERE updated_at < created_at
UNION ALL
SELECT 'fee', id, created_at, updated_at FROM fee WHERE updated_at < created_at
UNION ALL
SELECT 'enrollments', id, created_at, updated_at FROM enrollments WHERE updated_at < created_at;
