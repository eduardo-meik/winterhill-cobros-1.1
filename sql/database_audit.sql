-- ============================================================
-- AUDITORÍA EXHAUSTIVA DE DATOS - winterhill-cobros
-- Ejecutar en Supabase SQL Editor
-- ============================================================

-- ============================================================
-- PARTE 1: CONTEO GENERAL DE REGISTROS
-- ============================================================
SELECT '=== PARTE 1: CONTEO DE REGISTROS ===' AS seccion;

SELECT 'students' AS tabla, COUNT(*) AS total FROM students
UNION ALL SELECT 'guardians', COUNT(*) FROM guardians
UNION ALL SELECT 'student_guardian', COUNT(*) FROM student_guardian
UNION ALL SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL SELECT 'enrollment_students', COUNT(*) FROM enrollment_students
UNION ALL SELECT 'enrollment_documents', COUNT(*) FROM enrollment_documents
UNION ALL SELECT 'enrollment_document_receipts', COUNT(*) FROM enrollment_document_receipts
UNION ALL SELECT 'fee', COUNT(*) FROM fee
UNION ALL SELECT 'cheques', COUNT(*) FROM cheques
UNION ALL SELECT 'cursos', COUNT(*) FROM cursos
UNION ALL SELECT 'profiles', COUNT(*) FROM profiles
UNION ALL SELECT 'student_academic_records', COUNT(*) FROM student_academic_records
UNION ALL SELECT 'matriculas_detalle', COUNT(*) FROM matriculas_detalle
UNION ALL SELECT 'guardian_intake_surveys', COUNT(*) FROM guardian_intake_surveys
UNION ALL SELECT 'guardian_claim_logs', COUNT(*) FROM guardian_claim_logs
UNION ALL SELECT 'signatures', COUNT(*) FROM signatures
UNION ALL SELECT 'invoices', COUNT(*) FROM invoices
UNION ALL SELECT 'pre_receipts', COUNT(*) FROM pre_receipts
UNION ALL SELECT 'document_templates', COUNT(*) FROM document_templates
UNION ALL SELECT 'email_logs', COUNT(*) FROM email_logs
UNION ALL SELECT 'audit_logs', COUNT(*) FROM audit_logs
UNION ALL SELECT 'auth_logs', COUNT(*) FROM auth_logs
ORDER BY tabla;
