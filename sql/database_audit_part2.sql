-- ============================================================
-- PARTE 2: DUPLICADOS
-- ============================================================

-- 2a. Estudiantes con RUN duplicado
SELECT '=== 2a: Estudiantes con RUN duplicado ===' AS seccion;
SELECT run, COUNT(*) AS cnt, 
       array_agg(id) AS ids,
       array_agg(first_name || ' ' || apellido_paterno) AS nombres
FROM students
GROUP BY run
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- 2b. Guardians con RUN duplicado
SELECT '=== 2b: Guardians con RUN duplicado ===' AS seccion;
SELECT run, COUNT(*) AS cnt,
       array_agg(id) AS ids,
       array_agg(first_name || ' ' || last_name) AS nombres
FROM guardians
GROUP BY run
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- 2c. student_guardian duplicados (misma pareja student-guardian)
SELECT '=== 2c: student_guardian duplicados ===' AS seccion;
SELECT student_id, guardian_id, COUNT(*) AS cnt, array_agg(id) AS ids
FROM student_guardian
GROUP BY student_id, guardian_id
HAVING COUNT(*) > 1;

-- 2d. Enrollments duplicados (mismo guardian + mismo año)
SELECT '=== 2d: Enrollments duplicados (guardian_id + year) ===' AS seccion;
SELECT guardian_id, year, COUNT(*) AS cnt, array_agg(id) AS ids
FROM enrollments
GROUP BY guardian_id, year
HAVING COUNT(*) > 1;

-- 2e. enrollment_students duplicados (mismo enrollment + student)
SELECT '=== 2e: enrollment_students duplicados ===' AS seccion;
SELECT enrollment_id, student_id, COUNT(*) AS cnt
FROM enrollment_students
GROUP BY enrollment_id, student_id
HAVING COUNT(*) > 1;

-- 2f. Fee duplicadas (mismo student + numero_cuota + year_academico)
SELECT '=== 2f: Cuotas duplicadas (student + cuota + año) ===' AS seccion;
SELECT student_id, numero_cuota, year_academico, COUNT(*) AS cnt, array_agg(id) AS ids
FROM fee
GROUP BY student_id, numero_cuota, year_academico
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- 2g. student_academic_records duplicados (student + year)
SELECT '=== 2g: Academic records duplicados (student + año) ===' AS seccion;
SELECT student_id, year_academico, COUNT(*) AS cnt, array_agg(id) AS ids
FROM student_academic_records
GROUP BY student_id, year_academico
HAVING COUNT(*) > 1;

-- 2h. guardian_intake_surveys duplicados (guardian + year)
SELECT '=== 2h: Intake surveys duplicados (guardian + año) ===' AS seccion;
SELECT guardian_id, year, COUNT(*) AS cnt, array_agg(id) AS ids
FROM guardian_intake_surveys
GROUP BY guardian_id, year
HAVING COUNT(*) > 1;

-- 2i. public.matriculas_detalle fue retirada el 2026-04-07
SELECT '=== 2i: matriculas_detalle retirada; auditoria ya no aplica ===' AS seccion;

-- 2j. Profiles con email duplicado
SELECT '=== 2j: Profiles con email duplicado ===' AS seccion;
SELECT email, COUNT(*) AS cnt, array_agg(id) AS ids
FROM profiles
GROUP BY email
HAVING COUNT(*) > 1;

-- 2k. Cheques con numero_serie duplicado
SELECT '=== 2k: Cheques con numero_serie duplicado ===' AS seccion;
SELECT numero_serie, COUNT(*) AS cnt, array_agg(id) AS ids
FROM cheques
GROUP BY numero_serie
HAVING COUNT(*) > 1;

-- 2l. enrollment_documents duplicados (enrollment + type)
SELECT '=== 2l: Documentos duplicados (enrollment + tipo) ===' AS seccion;
SELECT enrollment_id, type, COUNT(*) AS cnt, array_agg(id) AS ids
FROM enrollment_documents
GROUP BY enrollment_id, type
HAVING COUNT(*) > 1;
