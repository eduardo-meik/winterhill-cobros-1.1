-- ============================================================
-- PASO 3: CASOS CON CAMBIO DE APODERADO - REVISIÓN MANUAL
-- ============================================================
-- Estos 11 casos requieren tu decisión manual porque:
-- - Tienen diferentes apoderados entre matrículas
-- - Pueden ser cambios legítimos de apoderado
-- - Requieren verificar cuál es el apoderado correcto actual
--
-- INSTRUCCIONES:
-- 1. Revisa cada caso
-- 2. Determina qué matrícula conservar
-- 3. Ejecuta el SQL de DELETE correspondiente

-- ============================================================
-- CASO 1: ALONDRA SOFÍA GUEICO GAETE
-- ============================================================
-- Cambió de apoderado: OCTAVIANA → NATALY
SELECT 
    '1. ALONDRA SOFÍA GUEICO GAETE' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email,
    g.telefono,
    CASE 
        WHEN e.created_at::date = '2025-12-08'::date THEN '❓ Primera matrícula (OCTAVIANA)'
        WHEN e.created_at::date = '2025-12-11'::date THEN '❓ Segunda matrícula (NATALY)'
    END as descripcion
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = '99cbbebd-9d24-4463-a67e-ed6201e32e84'
ORDER BY e.created_at;

-- SQL PARA BORRAR (descomentar la opción correcta):
-- OPCIÓN A: Conservar OCTAVIANA (borrar matrícula con NATALY)
-- DELETE FROM enrollment_students WHERE enrollment_id = 'c500a520-52ed-43c8-b92d-8d450707a58a';
-- DELETE FROM enrollments WHERE id = 'c500a520-52ed-43c8-b92d-8d450707a58a';

-- OPCIÓN B: Conservar NATALY (borrar matrícula con OCTAVIANA)
-- DELETE FROM enrollment_students WHERE enrollment_id = '660a4dec-45ad-41a0-a100-04274626b1f2';
-- DELETE FROM enrollments WHERE id = '660a4dec-45ad-41a0-a100-04274626b1f2';

-- ============================================================
-- CASO 2: BENJAMÍN ARTURO SALAZAR CORNEJO
-- ============================================================
-- MISMO DÍA, dos apoderados CRISTIAN diferentes
SELECT 
    '2. BENJAMÍN ARTURO SALAZAR CORNEJO' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    TO_CHAR(e.created_at, 'HH24:MI:SS') as hora_creacion,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email,
    g.run
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = '333c02fc-08d9-4ca6-bb93-ff11ebaa785c'
ORDER BY e.created_at;

-- SQL PARA BORRAR (descomentar la opción correcta):
-- OPCIÓN A: Conservar primera matrícula (12:25)
-- DELETE FROM enrollment_students WHERE enrollment_id = '1dd277d2-6373-48a5-b8a1-16e5a4d5014a';
-- DELETE FROM enrollments WHERE id = '1dd277d2-6373-48a5-b8a1-16e5a4d5014a';

-- OPCIÓN B: Conservar segunda matrícula (12:31)
-- DELETE FROM enrollment_students WHERE enrollment_id = '0ebeab1e-934d-4b23-aacf-b1c77cbe4673';
-- DELETE FROM enrollments WHERE id = '0ebeab1e-934d-4b23-aacf-b1c77cbe4673';

-- ============================================================
-- CASO 3: EMILIO GAEL CONTRERAS VERGARA
-- ============================================================
-- Cambió de apoderado: JORGE MANUEL → INELIA DEL CARMEN
SELECT 
    '3. EMILIO GAEL CONTRERAS VERGARA' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = '2850f8bf-078e-4fa1-a9bf-f59e9833c803'
ORDER BY e.created_at;

-- SQL PARA BORRAR:
-- OPCIÓN A: Conservar JORGE (borrar INELIA)
-- DELETE FROM enrollment_students WHERE enrollment_id = '34118f30-b3a2-4d23-88d9-37dbef6d2196';
-- DELETE FROM enrollments WHERE id = '34118f30-b3a2-4d23-88d9-37dbef6d2196';

-- OPCIÓN B: Conservar INELIA (borrar JORGE)
-- DELETE FROM enrollment_students WHERE enrollment_id = '11dcf02c-681f-4974-94f7-89ca74969b88';
-- DELETE FROM enrollments WHERE id = '11dcf02c-681f-4974-94f7-89ca74969b88';

-- ============================================================
-- CASO 4: FACUNDO RODRIGO MARTÍNEZ LUCERO
-- ============================================================
-- Cambió de ENZO (falso, ya marcado para borrar) → MARÍA JOSÉ
SELECT 
    '4. FACUNDO RODRIGO MARTÍNEZ LUCERO' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email,
    CASE 
        WHEN g.first_name = 'ENZO' THEN '⚠️ ENZO (apoderado falso - ya marcado para borrar)'
        ELSE '✅ Apoderado válido'
    END as nota
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = 'fc9488b5-7c2c-46cb-a125-26a100f86897'
ORDER BY e.created_at;

-- DECISIÓN AUTOMÁTICA: Borrar matrícula con ENZO (apoderado falso)
-- DELETE FROM enrollment_students WHERE enrollment_id = 'cb2b3380-8884-4d39-9062-088b0ca8482f';
-- DELETE FROM enrollments WHERE id = 'cb2b3380-8884-4d39-9062-088b0ca8482f';

-- ============================================================
-- CASO 5: FLORENCIA AYELEN TERUEL
-- ============================================================
-- Dos apoderados JAVIERA IGNACIA (misma persona, IDs diferentes)
SELECT 
    '5. FLORENCIA AYELEN TERUEL' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.run,
    g.email,
    g.telefono
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = '08b2dd2d-0739-46fc-8a4d-19e9013ca0de'
ORDER BY e.created_at;

-- DECISIÓN SUGERIDA: Conservar la más reciente (dic 9)
-- DELETE FROM enrollment_students WHERE enrollment_id = '9aee70a5-b076-437f-852d-a36df36e49a2';
-- DELETE FROM enrollments WHERE id = '9aee70a5-b076-437f-852d-a36df36e49a2';

-- ============================================================
-- CASO 6: GASPAR ANDRÉS ARAYA LARA
-- ============================================================
-- Cambió de HUMBERTO → KARLA
SELECT 
    '6. GASPAR ANDRÉS ARAYA LARA' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = 'a23b162c-a255-4e48-a5a5-8a7fcacece00'
ORDER BY e.created_at;

-- SQL PARA BORRAR:
-- OPCIÓN A: Conservar HUMBERTO
-- DELETE FROM enrollment_students WHERE enrollment_id = 'f95055bd-fcae-4262-872f-47646d335b17';
-- DELETE FROM enrollments WHERE id = 'f95055bd-fcae-4262-872f-47646d335b17';

-- OPCIÓN B: Conservar KARLA
-- DELETE FROM enrollment_students WHERE enrollment_id = '781dad64-74bb-4743-a1ca-ccad7e045ed4';
-- DELETE FROM enrollments WHERE id = '781dad64-74bb-4743-a1ca-ccad7e045ed4';

-- ============================================================
-- CASO 7: GASPAR MENDOZA DAZA
-- ============================================================
-- Cambió de FERNANDA → PATRICIO
SELECT 
    '7. GASPAR MENDOZA DAZA' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = 'b57e2273-d378-44ca-ac6b-ef263df10836'
ORDER BY e.created_at;

-- SQL PARA BORRAR:
-- OPCIÓN A: Conservar FERNANDA
-- DELETE FROM enrollment_students WHERE enrollment_id = '4df75291-7705-467c-b5fa-621682981d3d';
-- DELETE FROM enrollments WHERE id = '4df75291-7705-467c-b5fa-621682981d3d';

-- OPCIÓN B: Conservar PATRICIO
-- DELETE FROM enrollment_students WHERE enrollment_id = '32cff3f9-e488-4f62-a494-fd6653fa335c';
-- DELETE FROM enrollments WHERE id = '32cff3f9-e488-4f62-a494-fd6653fa335c';

-- ============================================================
-- CASO 8: LEONOR CAROLINA CARVAJAL GUAJARDO
-- ============================================================
-- Cambió de CAROLINA ANDREA → RODRIGO
SELECT 
    '8. LEONOR CAROLINA CARVAJAL GUAJARDO' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = 'f1fa9589-cce4-4ef0-adb0-1fde475373d8'
ORDER BY e.created_at;

-- SQL PARA BORRAR:
-- OPCIÓN A: Conservar CAROLINA
-- DELETE FROM enrollment_students WHERE enrollment_id = '977f8fff-a1d4-4677-97f3-09e6a306b6b3';
-- DELETE FROM enrollments WHERE id = '977f8fff-a1d4-4677-97f3-09e6a306b6b3';

-- OPCIÓN B: Conservar RODRIGO
-- DELETE FROM enrollment_students WHERE enrollment_id = '73435dec-b050-4d90-8f54-86c1f23847ff';
-- DELETE FROM enrollments WHERE id = '73435dec-b050-4d90-8f54-86c1f23847ff';

-- ============================================================
-- CASO 9: LUCAS LEÓN GÓMEZ PERALTA
-- ============================================================
-- Cambió de CRISTIAN ANDRÉS → JAVIERA FERNANDA
SELECT 
    '9. LUCAS LEÓN GÓMEZ PERALTA' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = '7e81d144-6448-46bf-911e-9993e8cce163'
ORDER BY e.created_at;

-- SQL PARA BORRAR:
-- OPCIÓN A: Conservar CRISTIAN
-- DELETE FROM enrollment_students WHERE enrollment_id = 'd7ca8df8-705b-4a77-95de-ab090e1117cd';
-- DELETE FROM enrollments WHERE id = 'd7ca8df8-705b-4a77-95de-ab090e1117cd';

-- OPCIÓN B: Conservar JAVIERA
-- DELETE FROM enrollment_students WHERE enrollment_id = '9a788342-9f8d-42eb-9c7f-996b878c067d';
-- DELETE FROM enrollments WHERE id = '9a788342-9f8d-42eb-9c7f-996b878c067d';

-- ============================================================
-- CASO 10: MAXIMILIANO VICENTE PIÑA BOMBAL
-- ============================================================
-- Cambió de LEOPOLDO → KARINA ALEJANDRA
SELECT 
    '10. MAXIMILIANO VICENTE PIÑA BOMBAL' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = 'b6b51637-05bb-43ee-81d6-898336e5e906'
ORDER BY e.created_at;

-- SQL PARA BORRAR:
-- OPCIÓN A: Conservar LEOPOLDO
-- DELETE FROM enrollment_students WHERE enrollment_id = 'f061a94a-76ff-4b69-8cb7-c6f7a160f29b';
-- DELETE FROM enrollments WHERE id = 'f061a94a-76ff-4b69-8cb7-c6f7a160f29b';

-- OPCIÓN B: Conservar KARINA
-- DELETE FROM enrollment_students WHERE enrollment_id = '50bebbba-c6bd-448f-b073-1cd3cee89d78';
-- DELETE FROM enrollments WHERE id = '50bebbba-c6bd-448f-b073-1cd3cee89d78';

-- ============================================================
-- CASO 11: TRINIDAD ANTONIA JIMÉNEZ ZEGERS
-- ============================================================
-- Cambió de JENNIFER ALEJANDRA → MICHAEL
SELECT 
    '11. TRINIDAD ANTONIA JIMÉNEZ ZEGERS' as caso,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(g.apellido_paterno, '') || ' ' || COALESCE(g.apellido_materno, '') as apoderado_nombre,
    g.id as guardian_id,
    g.email
FROM enrollment_students es
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON es.student_id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.student_id = '5cf2dbcc-91c7-426a-8147-91ee36c174bf'
ORDER BY e.created_at;

-- SQL PARA BORRAR:
-- OPCIÓN A: Conservar JENNIFER
-- DELETE FROM enrollment_students WHERE enrollment_id = '9d37be52-9dbb-4412-9b9c-d95a79f6cd44';
-- DELETE FROM enrollments WHERE id = '9d37be52-9dbb-4412-9b9c-d95a79f6cd44';

-- OPCIÓN B: Conservar MICHAEL
-- DELETE FROM enrollment_students WHERE enrollment_id = 'e66f1e29-80da-4797-bd98-3a4a82c79854';
-- DELETE FROM enrollments WHERE id = 'e66f1e29-80da-4797-bd98-3a4a82c79854';

-- ============================================================
-- RESUMEN Y RECOMENDACIONES
-- ============================================================

SELECT 
    'RESUMEN DE CASOS PARA REVISIÓN MANUAL' as titulo,
    11 as total_casos,
    'Ejecuta cada query SELECT para ver detalles' as instruccion_1,
    'Descomenta el DELETE correspondiente según tu decisión' as instruccion_2,
    'Caso 4 (ENZO) se recomienda borrar automáticamente' as nota_especial;
