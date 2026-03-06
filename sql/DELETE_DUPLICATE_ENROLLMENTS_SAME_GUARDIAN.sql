-- ============================================================
-- PASO 2: BORRAR MATRÍCULAS DUPLICADAS (MISMO APODERADO)
-- ============================================================
-- Este script elimina las matrículas ANTIGUAS cuando:
-- - El mismo estudiante está matriculado 2+ veces
-- - Con el MISMO apoderado
-- - Se conserva la matrícula MÁS RECIENTE
--
-- Total: 15 matrículas a borrar

-- VERIFICACIÓN ANTES DE BORRAR
-- Muestra las matrículas que se van a eliminar
SELECT 
    s.first_name || ' ' || COALESCE(s.apellido_paterno, '') || ' ' || COALESCE(s.apellido_materno, '') as estudiante,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(split_part(COALESCE(g.last_name, ''), ' ', 1), '') as apoderado,
    g.id as guardian_id,
    '❌ BORRAR (antigua)' as accion
FROM enrollment_students es
JOIN students s ON es.student_id = s.id
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON s.id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE es.enrollment_id IN (
    -- ALMA DUQUE PUGAS (borrar dic 8)
    '8734e35e-03bb-409d-94cf-9005ff62efc5',
    
    -- AMANDA SAYEN BRIONES (borrar dic 1)
    '2bceace9-07a6-4c63-9bfd-70b5ac0d1eaa',
    
    -- BORJA LEÓN MORAGA (borrar dic 9)
    '70845a18-dd98-4063-b581-50af25040548',
    
    -- EMA FAIRUZ ALFARO (borrar dic 8)
    '2ee6c1e4-0f4c-47f4-b7dd-87fe63541ff7',
    
    -- ENYA FENRIR ROJAS (borrar dic 8)
    '8734e35e-03bb-409d-94cf-9005ff62efc5',
    
    -- FACUNDO GASPAR CUADRO (borrar dic 8)
    'bd8d1bab-a97e-45d3-9160-2dc3f7bbe751',
    
    -- HELENA MAILEN BRIONES (borrar dic 1)
    '2bceace9-07a6-4c63-9bfd-70b5ac0d1eaa',
    
    -- JAVIERA VALENTINA GUAJARDO (borrar oct 30)
    '40251341-81b9-4b48-809c-dd28c2b33e5a',
    
    -- JULIÁN EDUARDO RAMÍREZ (borrar dic 8)
    'fdd9bf33-be85-464a-8245-a629fed80295',
    
    -- MATILDA ESPERANZA CUADRO (borrar dic 8)
    'bd8d1bab-a97e-45d3-9160-2dc3f7bbe751',
    
    -- RAFAELA FLORENCIA RIQUELME (borrar nov 3)
    '7bbe312b-1c03-4660-ac45-6314f894e472',
    
    -- ROQUE ARIEL MORAGA (borrar dic 9)
    '70845a18-dd98-4063-b581-50af25040548',
    
    -- TRINIDAD IGNACIA BERTEINS (borrar dic 8)
    'd28bb16b-abce-490c-b514-682bc6e91366',
    
    -- LEÓN REVECO PÉREZ (borrar las 2 primeras: dic 8 y dic 10 primera)
    '07d05095-86f9-4499-b012-b972ad464e9c',
    '247d9d05-b059-4ae6-9b01-f6342819945b'
)
ORDER BY estudiante, e.created_at;

-- MOSTRAR LAS MATRÍCULAS QUE SE CONSERVARÁN
SELECT 
    s.first_name || ' ' || COALESCE(s.apellido_paterno, '') || ' ' || COALESCE(s.apellido_materno, '') as estudiante,
    e.id as enrollment_id,
    e.created_at::date as fecha_matricula,
    g.first_name || ' ' || COALESCE(split_part(COALESCE(g.last_name, ''), ' ', 1), '') as apoderado,
    '✅ CONSERVAR (más reciente)' as accion
FROM enrollment_students es
JOIN students s ON es.student_id = s.id
JOIN enrollments e ON es.enrollment_id = e.id
JOIN student_guardian sg ON s.id = sg.student_id
JOIN guardians g ON sg.guardian_id = g.id
WHERE s.id IN (
    '1c84595f-aab3-459d-bf26-2dd26dbded8e',  -- ALMA
    '95ef84e0-4aab-4c7f-873c-4eb635e8d1d7',  -- AMANDA
    'd746d6cc-a5d6-452a-bcce-6c076d957938',  -- BORJA
    'a69bf1eb-c487-4e3c-8a35-8c9e62bad84f',  -- EMA
    'ebc8c578-b7c0-4211-aa98-19d279cfaabc',  -- ENYA
    'e4db2a7f-f46b-4043-a96b-00fe319462b8',  -- FACUNDO GASPAR
    '0c44198f-897e-47e7-b1cc-e8b48d1b7254',  -- HELENA
    '78622561-1e4d-4bff-8b29-c20226a65fe1',  -- JAVIERA
    '0caa2000-14bd-4e39-8e85-51bc254c51f9',  -- JULIÁN
    '3d811053-ed05-41cd-8782-f6a5486e7395',  -- MATILDA
    '8347c106-83b2-42c0-8beb-dea200e8b8a7',  -- RAFAELA
    '3cdbeff9-d011-46d3-b0b5-3cb18970e29e',  -- ROQUE
    '05855245-38ee-44eb-90ca-7b8c81e58784',  -- TRINIDAD
    'eef2faa0-d445-4f9e-8ba0-20818dfa09be'   -- LEÓN (conserva la última)
)
AND es.enrollment_id NOT IN (
    '8734e35e-03bb-409d-94cf-9005ff62efc5',
    '2bceace9-07a6-4c63-9bfd-70b5ac0d1eaa',
    '70845a18-dd98-4063-b581-50af25040548',
    '2ee6c1e4-0f4c-47f4-b7dd-87fe63541ff7',
    'bd8d1bab-a97e-45d3-9160-2dc3f7bbe751',
    '40251341-81b9-4b48-809c-dd28c2b33e5a',
    'fdd9bf33-be85-464a-8245-a629fed80295',
    '7bbe312b-1c03-4660-ac45-6314f894e472',
    'd28bb16b-abce-490c-b514-682bc6e91366',
    '07d05095-86f9-4499-b012-b972ad464e9c',
    '247d9d05-b059-4ae6-9b01-f6342819945b'
)
ORDER BY estudiante, e.created_at DESC;

-- ============================================================
-- BORRAR MATRÍCULAS DUPLICADAS
-- ============================================================

BEGIN;

-- Borrar de enrollment_students primero
DELETE FROM enrollment_students
WHERE enrollment_id IN (
    '8734e35e-03bb-409d-94cf-9005ff62efc5',  -- ALMA (dic 8)
    '2bceace9-07a6-4c63-9bfd-70b5ac0d1eaa',  -- AMANDA (dic 1)
    '70845a18-dd98-4063-b581-50af25040548',  -- BORJA (dic 9)
    '2ee6c1e4-0f4c-47f4-b7dd-87fe63541ff7',  -- EMA (dic 8)
    -- ENYA usa el mismo enrollment_id que ALMA (8734e35e) - ya incluido
    'bd8d1bab-a97e-45d3-9160-2dc3f7bbe751',  -- FACUNDO GASPAR (dic 8)
    -- HELENA usa el mismo enrollment_id que AMANDA (2bceace9) - ya incluido
    '40251341-81b9-4b48-809c-dd28c2b33e5a',  -- JAVIERA (oct 30)
    'fdd9bf33-be85-464a-8245-a629fed80295',  -- JULIÁN (dic 8)
    -- MATILDA usa el mismo enrollment_id que FACUNDO (bd8d1bab) - ya incluido
    '7bbe312b-1c03-4660-ac45-6314f894e472',  -- RAFAELA (nov 3)
    -- ROQUE usa el mismo enrollment_id que BORJA (70845a18) - ya incluido
    'd28bb16b-abce-490c-b514-682bc6e91366',  -- TRINIDAD (dic 8)
    '07d05095-86f9-4499-b012-b972ad464e9c',  -- LEÓN (dic 8)
    '247d9d05-b059-4ae6-9b01-f6342819945b'   -- LEÓN (dic 10 primera)
);

-- Borrar de enrollments (tabla principal)
DELETE FROM enrollments
WHERE id IN (
    '8734e35e-03bb-409d-94cf-9005ff62efc5',
    '2bceace9-07a6-4c63-9bfd-70b5ac0d1eaa',
    '70845a18-dd98-4063-b581-50af25040548',
    '2ee6c1e4-0f4c-47f4-b7dd-87fe63541ff7',
    'bd8d1bab-a97e-45d3-9160-2dc3f7bbe751',
    '40251341-81b9-4b48-809c-dd28c2b33e5a',
    'fdd9bf33-be85-464a-8245-a629fed80295',
    '7bbe312b-1c03-4660-ac45-6314f894e472',
    'd28bb16b-abce-490c-b514-682bc6e91366',
    '07d05095-86f9-4499-b012-b972ad464e9c',
    '247d9d05-b059-4ae6-9b01-f6342819945b'
);

COMMIT;

-- ============================================================
-- VERIFICACIÓN POST-DELETE
-- ============================================================

-- Debe retornar 0 filas (matrículas eliminadas)
SELECT COUNT(*) as enrollments_borrados_verificacion
FROM enrollments
WHERE id IN (
    '8734e35e-03bb-409d-94cf-9005ff62efc5',
    '2bceace9-07a6-4c63-9bfd-70b5ac0d1eaa',
    '70845a18-dd98-4063-b581-50af25040548',
    '2ee6c1e4-0f4c-47f4-b7dd-87fe63541ff7',
    'bd8d1bab-a97e-45d3-9160-2dc3f7bbe751',
    '40251341-81b9-4b48-809c-dd28c2b33e5a',
    'fdd9bf33-be85-464a-8245-a629fed80295',
    '7bbe312b-1c03-4660-ac45-6314f894e472',
    'd28bb16b-abce-490c-b514-682bc6e91366',
    '07d05095-86f9-4499-b012-b972ad464e9c',
    '247d9d05-b059-4ae6-9b01-f6342819945b'
);

-- Verificar que cada estudiante ahora tiene solo 1 matrícula
SELECT 
    s.first_name || ' ' || COALESCE(s.apellido_paterno, '') || ' ' || COALESCE(s.apellido_materno, '') as estudiante,
    COUNT(DISTINCT es.enrollment_id) as total_enrollments,
    CASE 
        WHEN COUNT(DISTINCT es.enrollment_id) = 1 THEN '✅ CORRECTO'
        ELSE '❌ ERROR'
    END as estado
FROM students s
JOIN enrollment_students es ON s.id = es.student_id
WHERE s.id IN (
    '1c84595f-aab3-459d-bf26-2dd26dbded8e',
    '95ef84e0-4aab-4c7f-873c-4eb635e8d1d7',
    'd746d6cc-a5d6-452a-bcce-6c076d957938',
    'a69bf1eb-c487-4e3c-8a35-8c9e62bad84f',
    'ebc8c578-b7c0-4211-aa98-19d279cfaabc',
    'e4db2a7f-f46b-4043-a96b-00fe319462b8',
    '0c44198f-897e-47e7-b1cc-e8b48d1b7254',
    '78622561-1e4d-4bff-8b29-c20226a65fe1',
    '0caa2000-14bd-4e39-8e85-51bc254c51f9',
    '3d811053-ed05-41cd-8782-f6a5486e7395',
    '8347c106-83b2-42c0-8beb-dea200e8b8a7',
    '3cdbeff9-d011-46d3-b0b5-3cb18970e29e',
    '05855245-38ee-44eb-90ca-7b8c81e58784',
    'eef2faa0-d445-4f9e-8ba0-20818dfa09be'
)
GROUP BY s.id, s.first_name, s.apellido_paterno, s.apellido_materno
ORDER BY estudiante;
