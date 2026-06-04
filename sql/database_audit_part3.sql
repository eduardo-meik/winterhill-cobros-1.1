-- ============================================================
-- PARTE 3: FKs HUÉRFANAS (registros que apuntan a registros inexistentes)
-- ============================================================

-- 3a. fee.student_id → students que no existen
SELECT '=== 3a: fee con student_id huérfano ===' AS seccion;
SELECT f.id, f.student_id, f.amount, f.year_academico, f.numero_cuota
FROM fee f
LEFT JOIN students s ON s.id = f.student_id
WHERE s.id IS NULL;

-- 3b. fee.guardian_id → guardians que no existen
SELECT '=== 3b: fee con guardian_id huérfano ===' AS seccion;
SELECT f.id, f.guardian_id, f.amount, f.year_academico
FROM fee f
LEFT JOIN guardians g ON g.id = f.guardian_id
WHERE f.guardian_id IS NOT NULL AND g.id IS NULL;

-- 3c. fee.fee_curso → cursos que no existen
SELECT '=== 3c: fee con fee_curso huérfano ===' AS seccion;
SELECT f.id, f.fee_curso, f.student_id, f.year_academico
FROM fee f
LEFT JOIN cursos c ON c.id = f.fee_curso
WHERE f.fee_curso IS NOT NULL AND c.id IS NULL;

-- 3d. fee.enrollment_id → enrollments que no existen
SELECT '=== 3d: fee con enrollment_id huérfano ===' AS seccion;
SELECT f.id, f.enrollment_id, f.student_id, f.year_academico
FROM fee f
LEFT JOIN enrollments e ON e.id = f.enrollment_id
WHERE f.enrollment_id IS NOT NULL AND e.id IS NULL;

-- 3e. student_guardian.student_id → students que no existen
SELECT '=== 3e: student_guardian con student_id huérfano ===' AS seccion;
SELECT sg.id, sg.student_id, sg.guardian_id
FROM student_guardian sg
LEFT JOIN students s ON s.id = sg.student_id
WHERE s.id IS NULL;

-- 3f. student_guardian.guardian_id → guardians que no existen
SELECT '=== 3f: student_guardian con guardian_id huérfano ===' AS seccion;
SELECT sg.id, sg.student_id, sg.guardian_id
FROM student_guardian sg
LEFT JOIN guardians g ON g.id = sg.guardian_id
WHERE g.id IS NULL;

-- 3g. enrollment_students.enrollment_id → enrollments que no existen
SELECT '=== 3g: enrollment_students con enrollment_id huérfano ===' AS seccion;
SELECT es.enrollment_id, es.student_id
FROM enrollment_students es
LEFT JOIN enrollments e ON e.id = es.enrollment_id
WHERE e.id IS NULL;

-- 3h. enrollment_students.student_id → students que no existen
SELECT '=== 3h: enrollment_students con student_id huérfano ===' AS seccion;
SELECT es.enrollment_id, es.student_id
FROM enrollment_students es
LEFT JOIN students s ON s.id = es.student_id
WHERE s.id IS NULL;

-- 3i. enrollments.guardian_id → guardians que no existen
SELECT '=== 3i: enrollments con guardian_id huérfano ===' AS seccion;
SELECT e.id, e.guardian_id, e.year, e.status
FROM enrollments e
LEFT JOIN guardians g ON g.id = e.guardian_id
WHERE g.id IS NULL;

-- 3j. student_academic_records.student_id → students que no existen
SELECT '=== 3j: academic_records con student_id huérfano ===' AS seccion;
SELECT sar.id, sar.student_id, sar.year_academico
FROM student_academic_records sar
LEFT JOIN students s ON s.id = sar.student_id
WHERE s.id IS NULL;

-- 3k. student_academic_records.curso_id → cursos que no existen
SELECT '=== 3k: academic_records con curso_id huérfano ===' AS seccion;
SELECT sar.id, sar.curso_id, sar.year_academico
FROM student_academic_records sar
LEFT JOIN cursos c ON c.id = sar.curso_id
WHERE c.id IS NULL;

-- 3l. cheques.enrollment_id → enrollments que no existen
SELECT '=== 3l: cheques con enrollment_id huérfano ===' AS seccion;
SELECT ch.id, ch.enrollment_id, ch.monto
FROM cheques ch
LEFT JOIN enrollments e ON e.id = ch.enrollment_id
WHERE e.id IS NULL;

-- 3m. enrollment_documents.enrollment_id → enrollments que no existen
SELECT '=== 3m: enrollment_documents con enrollment_id huérfano ===' AS seccion;
SELECT ed.id, ed.enrollment_id, ed.type, ed.status
FROM enrollment_documents ed
LEFT JOIN enrollments e ON e.id = ed.enrollment_id
WHERE e.id IS NULL;

-- 3n. students.curso → cursos que no existen
SELECT '=== 3n: students con curso huérfano ===' AS seccion;
SELECT s.id, s.first_name, s.apellido_paterno, s.curso, s.run
FROM students s
LEFT JOIN cursos c ON c.id = s.curso
WHERE c.id IS NULL;

-- 3o. public.matriculas_detalle fue retirada el 2026-04-07
SELECT '=== 3o: matriculas_detalle retirada; auditoria ya no aplica ===' AS seccion;

-- 3p. guardian_intake_surveys.guardian_id → guardians que no existen
SELECT '=== 3p: intake_surveys con guardian_id huérfano ===' AS seccion;
SELECT gis.id, gis.guardian_id, gis.year
FROM guardian_intake_surveys gis
LEFT JOIN guardians g ON g.id = gis.guardian_id
WHERE g.id IS NULL;

-- 3q. signatures.enrollment_document_id → enrollment_documents que no existen
SELECT '=== 3q: signatures con document_id huérfano ===' AS seccion;
SELECT sig.id, sig.enrollment_document_id
FROM signatures sig
LEFT JOIN enrollment_documents ed ON ed.id = sig.enrollment_document_id
WHERE ed.id IS NULL;

-- 3r/3s. public.pre_receipts fue retirada el 2026-04-07
SELECT '=== 3r: pre_receipts retirada; auditoria ya no aplica ===' AS seccion;
SELECT '=== 3s: pre_receipts retirada; auditoria ya no aplica ===' AS seccion;
