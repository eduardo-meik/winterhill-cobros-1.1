-- ============================================================================
-- ENROLLMENT DATA CLEANUP - BASED ON JSON ANALYSIS
-- Created: 2025-12-22
-- Identifies specific issues from the provided JSON dataset
-- ============================================================================

-- ============================================================================
-- PART 1: ENROLLMENT ID SHARING ISSUE
-- These enrollment IDs have MULTIPLE students (data integrity error)
-- ============================================================================

-- CRITICAL: One enrollment_id should NOT be shared by multiple students
-- This violates data integrity

WITH shared_enrollment_ids AS (
    SELECT * FROM (VALUES
        ('2107a703-4075-49a0-918d-4040d5ea1b6a'::uuid, 'VIOLETA CAROLINA + SIMÓN MIJAHIL'),
        ('c1538293-107a-44c3-9637-59c645eb1237'::uuid, 'RAFAEL ALONSO + MAILEN PAZ'),
        ('04222237-6603-4006-9e94-91d087a8594f'::uuid, 'TESTING + junito'),
        ('b83ba7c0-607c-44da-a943-ed1339654b8c'::uuid, 'junito + TESTING'),
        ('807f89e5-9efe-4d4d-bcca-b855339174fb'::uuid, 'GABRIEL LUIS + JORGE ANTONIO'),
        ('046a97cc-99b4-4640-9762-730e5545031f'::uuid, 'LUCIANO EMILIO + RAFAEL IGNACIO'),
        ('4fc6e3dc-a88f-4edb-910e-2685806930f0'::uuid, 'MATILDA ESPERANZA + FACUNDO GASPAR'),
        ('184d6e71-b4c8-40d7-bef1-20440137dc1e'::uuid, 'ELENA FRANCISCA + MÁXIMO'),
        ('9b6a77af-49d1-4778-bc13-6f9941aa9cc7'::uuid, 'SAMUEL SIMÓN + SANTIAGO (2025)'),
        ('1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, 'SAMUEL SIMÓN + SANTIAGO (2026)'),
        ('fe495910-415b-4b30-bd6f-c8c216c6a800'::uuid, 'GASPAR TOMÁS + LUCAS MIGUEL'),
        ('625ea87a-1cb2-4232-b3df-0091dcf62ee2'::uuid, 'SALVADOR EMILIANO + IGNACIA'),
        ('77d06178-a240-478c-a274-d72c81dd7069'::uuid, 'OLIVER MILOVAN + IAN ANDRÉ (2025)'),
        ('d3b3e55f-9d8f-4bb6-bd48-8e2a4a2994a9'::uuid, 'OLIVER MILOVAN + IAN ANDRÉ (2026)'),
        ('d407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, 'MARTINA + AGUSTINA'),
        ('52c3d36c-2bf8-435b-acdf-34cf19e05485'::uuid, 'SOFÍA IGNACIA + LUKAS (2025)'),
        ('ac5b950a-b352-4c70-b508-a4faf7d36b6c'::uuid, 'SOFÍA IGNACIA + LUKAS (2026)'),
        ('6b255bb0-5be4-4929-8be7-eeb0d4239eb4'::uuid, 'DOMINIQUE + RAFFAELLA VALENTINA (2025)'),
        ('41450c85-801e-4653-b45f-70f60e81a196'::uuid, 'DOMINIQUE + RAFFAELLA VALENTINA (2026) - complex'),
        ('2e032bd2-e49f-4ab3-8eba-edaafe1819ce'::uuid, 'ALEXANDER ANDRES + CHARLOTTE'),
        ('50c55e54-4e1e-43cf-8a42-19e2c8bb7ba7'::uuid, 'ALEXANDER ANDRES + CHARLOTTE (2026)'),
        ('26aa7318-095a-460e-9a05-da0b457377bb'::uuid, 'ENYA FENRIR + ALMA'),
        ('2698b4a9-f2da-4096-8358-6a981f63ff2a'::uuid, 'FACUNDO AMARO + MAGDALENA LUNA'),
        ('b171da6b-c788-4602-96d7-c344ffc3881c'::uuid, 'VICENTE + LUCAS'),
        ('42ba9123-89b4-46ca-9435-a123e6e2b69e'::uuid, 'IGNACIO TOMÁS + JAVIERA EMILIA'),
        ('18bb695b-649e-4ce9-bf41-8505d0eadbcf'::uuid, 'EMILIANA SARAH MAGDALENA + GONZALO ALONSO'),
        ('0e5db320-9da9-44dd-86ae-ff5e2645678f'::uuid, 'ISAAC GAEL + DAHLIA DESIREÉ'),
        ('fba5295b-2960-4398-8ed7-ac1f6ab0cedb'::uuid, 'OLIVIA + FLORENCIA'),
        ('e8c57d50-cbb7-4600-bd0f-7677b062ce57'::uuid, 'LEÓN EMILIO + CATALINA ANTONIA'),
        ('f8fc5beb-0848-4473-9131-fd8c0fb189fe'::uuid, 'ISABEL LEONARDA + AURORA KÜYEN + JACINTA PASTORA'),
        ('39d6b297-fadd-48f4-8026-1778c1e875b5'::uuid, 'BORJA LEÓN + ROQUE ARIEL'),
        ('b24ab5d5-09d9-4d09-a18e-f646f409993c'::uuid, 'TAMAR ANAÍS + GRACE'),
        ('7f114e6a-35b2-4d9f-a383-efeab93a1c01'::uuid, 'MATILDA JAVIERA + AGUSTINA EMILIA'),
        ('cf60d160-b537-469a-b902-46be1ce87b7c'::uuid, 'GABRIEL ANDRÉS + DHANIEL HÉCTOR'),
        ('fbacdb30-1132-48eb-a38a-21f42b643059'::uuid, 'VIOLETA AMARANTA + SALVADOR AUKAN + LU (2025)'),
        ('24c92476-89fc-4290-b19e-5e262199afaa'::uuid, 'VIOLETA AMARANTA + SALVADOR AUKAN + LU (2026)'),
        ('102549df-93dd-44bb-a183-4fc553539658'::uuid, 'LEONOR + JOAQUIN CAMILO'),
        ('02879867-f809-4403-8d7b-0f9a7f8d1491'::uuid, 'MARTÍN ALONSO + DIEGO'),
        ('92378912-deeb-4e93-88ea-0f98bdf52f97'::uuid, 'FRANCO-RENE + JULIÁN BENJAMÍN'),
        ('dca666f4-0667-43ae-8dd6-9fe6054a7528'::uuid, 'ITALO BASTIÁN + ALANIZ SOFÍA'),
        ('70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, 'LIBERTAD + GASPAR ALFONSO'),
        ('c6f20d30-8204-4b3e-be68-0d61b574a5b3'::uuid, 'RENATA PASCUALA + MATEO ENRIQUE + LUCAS VICENTE'),
        ('72eb0c3f-beb2-4916-934e-3db4ef3555b7'::uuid, 'MARTÍN IGNACIO + SOFÍA ANTONIA'),
        ('38c9f70d-1084-42a5-955a-d32eada5adac'::uuid, 'VIOLETA GALA + MARÍA GRACIA'),
        ('f3857d9f-4cb6-4f29-b814-d321df8a18fa'::uuid, 'MÁXIMO LEÓN + LEONARDO GABRIEL'),
        ('32407e30-16df-4539-b46e-a1aba5bc67b9'::uuid, 'FRANCISCO JAVIER + VICENTE ALONSO + BRIANA (complex)'),
        ('d34519c9-e0bc-4be4-8f1e-ecdabddc40ea'::uuid, 'MISAEL ANTONIO + BRIANA'),
        ('a0421dcb-e14b-4ee4-901c-2ded703645ec'::uuid, 'JULIETA SOLEDAD + ROBERTA ANAÍS'),
        ('72c4ea03-234e-424e-956d-437edc00915b'::uuid, 'RENATO EDUARDO + ISABELLA DE JESÚS'),
        ('e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, 'CRISTIAN ANDRÉS + CONSTANZA PAZ + FRANCISCO GABRIEL'),
        ('ed5775ea-e394-45b5-8718-714db1cbd734'::uuid, 'RENATO ANTONIO + ALONSO PATRICIO + LEONOR ANTUMALEN'),
        ('626d645e-351b-4860-b9ae-1ec51e296686'::uuid, 'DANTE LEÓN + OCTAVIO ANDRÉS + ELOISA'),
        ('23de1816-62e8-4509-9a66-29b80dbe43b6'::uuid, 'SANTIAGO AMARO + LETICIA'),
        ('127eb37a-2702-4512-9626-e5be0c9d3db9'::uuid, 'ALONSO MARTIN + ANAÍS MARIEN'),
        ('ac6cefb2-5cd6-4b68-bfbf-faa7f5df3b29'::uuid, 'RAMIRO PASCUAL + SANTIAGO NICOLÁS (2025)'),
        ('b586387a-9d35-40d6-8970-8310b2aafa5a'::uuid, 'RAMIRO PASCUAL + SANTIAGO NICOLÁS (2026)'),
        ('1a72e2e9-fb59-4d21-8716-a2c447f7bda7'::uuid, 'GLINTON MATTEO + ÍZAN EDUARDO'),
        ('9e874df1-f34d-40b8-bb73-6648097415e3'::uuid, 'INARA SAYEN + SOFÍA AGUSTINA'),
        ('0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, 'LEONARDO MANUEL + DANAE AMELIE'),
        ('a7379488-e1f2-4370-9169-350a5c058900'::uuid, 'ROMÁN + ELOÍSA'),
        ('5386679e-ec03-45fe-bf3b-f8ec1e16142d'::uuid, 'ROBERTO EMILIANO + PASCAL'),
        ('b0e15295-effe-4d52-8b14-aaf4e717fd68'::uuid, 'IGNACIA + INÉS + SIMÓN'),
        ('d5c42a9f-07c0-4c06-9a64-1d9352660f84'::uuid, 'EMILY LUNA + DANTE')
    ) AS t(enrollment_id, students_affected)
)
SELECT 
    'ENROLLMENT ID SHARING ISSUE' as problem,
    COUNT(*) as total_shared_enrollments,
    'Each enrollment should have only ONE student' as note
FROM shared_enrollment_ids;

-- List all shared enrollment IDs
SELECT 
    enrollment_id,
    students_affected
FROM (VALUES
    ('2107a703-4075-49a0-918d-4040d5ea1b6a'::uuid, 'VIOLETA CAROLINA + SIMÓN MIJAHIL'),
    ('c1538293-107a-44c3-9637-59c645eb1237'::uuid, 'RAFAEL ALONSO + MAILEN PAZ')
    -- ... all 61+ cases
) AS t(enrollment_id, students_affected)
ORDER BY students_affected;

-- ============================================================================
-- PART 2: DUPLICATE ENROLLMENTS (Same student, same year)
-- ============================================================================

-- Students with multiple enrollments in the SAME year
WITH duplicate_students AS (
    SELECT * FROM (VALUES
        ('02fd7937-561a-4a53-ae18-0a3dc8e4517f'::uuid, 'ISIDORA ALINE', 2025, 2026, 'Different years'),
        ('a2715c76-93b7-4caf-aae5-34cdb370d11d'::uuid, 'AGUSTINA JACQUELINE', 2025, 2026, 'Different years'),
        ('4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid, 'Test1', 2025, 2026, 'TEST STUDENT + multiple enrollments'),
        ('99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid, 'junito', 2025, 2026, 'TEST STUDENT + multiple enrollments'),
        ('757b4b99-525f-4297-8d00-fc5457163bcc'::uuid, 'ARACELY', 2025, 2026, 'Different years'),
        ('aaca0235-1659-4bd0-9d69-35b52e9aa287'::uuid, 'SIMONE ANTONIA', 2025, 2026, 'Different years'),
        ('7d8bd993-c168-468a-971f-16f225d06396'::uuid, 'AMELIE PAZ', 2025, 2026, 'Different years'),
        ('c74de41d-6735-4848-8fb9-939355b45af0'::uuid, 'GAEL DAMIÁN', 2025, 2026, 'Different years'),
        ('5a0be0bf-e267-428c-8bdb-ab7054b3984a'::uuid, 'AYLIN MAITE ELOÍSA', 2025, 2026, 'Different years'),
        ('2fb5c543-fb89-418a-b2c4-47e93a2514ff'::uuid, 'DANTE ARITZ', 2025, 2026, 'Different years'),
        ('76efd3a1-8586-46f6-ab08-96ba11ef3334'::uuid, 'PASCAL ALUDY', 2025, 2026, 'Different years'),
        ('0668b381-e359-4261-9dfb-d0b509e61ca7'::uuid, 'SOFÍA ANTONELLA', 2025, 2026, 'Different years'),
        ('a817284c-e60d-4ebb-9f4e-70dd274a8805'::uuid, 'AMARANTA ROSA', 2025, 2026, 'Different years'),
        ('2b5cf256-baf0-4480-b60d-e3b34fce18d4'::uuid, 'EMILIANA SARAH MAGDALENA', 2025, 2026, 'Different years'),
        ('64153345-58a7-4027-95c7-2ba709e62461'::uuid, 'OLIVER MILOVAN', 2025, 2026, 'Different years'),
        ('e0bf1072-fbec-4732-aa38-4b892db92a9f'::uuid, 'AGUSTINA', 2025, 2026, 'Different years'),
        ('0caebc6c-149f-41d7-9a45-9a8d592722da'::uuid, 'SOFÍA IGNACIA', 2025, 2026, 'Different years'),
        ('cd235a94-9927-4ce7-811f-deb993f6800b'::uuid, 'LUKAS', 2025, 2026, 'Different years'),
        ('b34b32d0-cf7e-4468-84a5-4ad03262d1e9'::uuid, 'SALVADOR IGNACIO', 2025, 2026, 'Different years'),
        ('abb521ab-c183-4b68-93e3-f9f6b8f0de08'::uuid, 'RAFFAELLA VALENTINA', 2025, 2026, 'Different years + shared enrollment'),
        ('60c4befb-08f4-46a3-abce-bcecbe2fc11b'::uuid, 'ALEXANDER ANDRES', 2025, 2026, 'Different years'),
        ('735e186f-e63e-443d-b0e7-117cc58f6d15'::uuid, 'CHARLOTTE', 2025, 2026, 'Different years'),
        ('ddec83ec-d790-4aa8-a1a4-9688904049ef'::uuid, 'LEON', 2025, 2026, 'Different years'),
        ('c688eabf-ddc0-41bf-9a1c-694adbac43bb'::uuid, 'IAN ANDRÉ', 2025, 2026, 'Different years'),
        ('9ce9f734-8aa7-4440-81b8-ba98466f14df'::uuid, 'AMANDA', 2025, 2026, 'Different years'),
        ('42f7c90e-4104-46ad-a53d-db691ec22e17'::uuid, 'CATALINA ISIDORA', 2025, 2026, 'Different years'),
        ('46045c21-4a42-4ab0-9089-f94bc14b2729'::uuid, 'SALVADOR', 2025, 2026, 'Different years'),
        ('55d92ff7-dd27-4a2b-be91-52f45b087039'::uuid, 'MARTINA ALEXIA', 2025, 2026, 'Different years'),
        ('d6f5ae44-61cd-4a2b-9d7a-1f3b059651b9'::uuid, 'NICANOR', 2025, 2026, 'Different years'),
        ('d40e5b97-dea2-4de5-bf0a-8f04c182812c'::uuid, 'LEÓN EMILIO', 2025, 2026, 'Different years'),
        ('38f676cb-d38a-4ef0-be60-ba7baea47a50'::uuid, 'BORJA MANUEL', 2025, 2026, 'Different years'),
        ('742755bb-0cc2-4080-bcaa-f316b3734e8b'::uuid, 'ROBERT KLAUS', 2025, 2026, 'Different years'),
        ('44034a94-540c-42db-a352-5537717c0e13'::uuid, 'LAURA FRANCISCA', 2025, 2026, 'Different years'),
        ('39653d77-4fec-41ba-b9c9-5a73efd860de'::uuid, 'FABRICIO ABDEL', 2025, 2026, 'Different years'),
        ('453a4353-fc3a-4682-87ac-815da1186d68'::uuid, 'SANTIAGO', 2022, 2026, 'Year 2022 + 2026'),
        ('3e97526f-732e-4695-9a6a-6ac54ad8050b'::uuid, 'DANIELA IGNACIA', 2025, 2026, 'Different years'),
        ('333c02fc-08d9-4ca6-bb93-ff11ebaa785c'::uuid, 'BENJAMÍN ARTURO', 2025, 2026, 'Different years'),
        ('8aa4be45-205e-46bd-9025-9199a246c02b'::uuid, 'LUCAS IGNACIO', 2025, 2026, 'Year 2025 only - needs investigation'),
        ('9094ad36-32c6-42d4-9963-70bd14754a64'::uuid, 'AURORA', 2025, 2026, 'Different years')
    ) AS t(student_id, student_name, year1, year2, notes)
)
SELECT 
    'DUPLICATE ENROLLMENTS (SAME STUDENT)' as problem,
    COUNT(*) as students_with_duplicates
FROM duplicate_students;

-- ============================================================================
-- PART 3: TEST/PLACEHOLDER STUDENTS
-- ============================================================================
WITH test_students AS (
    SELECT * FROM (VALUES
        ('4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid, 'Test1', 'CLEAR TEST DATA'),
        ('99f9a557-fd89-4ced-8ffb-b4b800a17f26'::uuid, 'junito', 'CLEAR TEST DATA'),
        ('bbf7b971-5164-4b5a-a732-996c139f27f7'::uuid, 'TESTING', 'CLEAR TEST DATA'),
        ('5a739ec3-bfde-4b1e-94c1-561d940dc082'::uuid, 'Estudiante', 'GENERIC PLACEHOLDER'),
        ('11e1921f-3810-42de-91c7-cddf4bdc8f44'::uuid, 'ESTUDIANTE', 'GENERIC PLACEHOLDER'),
        ('1453bf25-63e3-4d5d-8fe2-56bd370d2fbb'::uuid, 'TESTNUEVO', 'CLEAR TEST DATA')
    ) AS t(student_id, student_name, reason)
)
SELECT 
    'TEST/PLACEHOLDER STUDENTS' as problem,
    COUNT(*) as test_students_count,
    'Should be deleted from production' as action
FROM test_students;

-- ============================================================================
-- PART 4: YEAR 2022 ENROLLMENTS (Created in 2025!)
-- ============================================================================
SELECT 
    'YEAR 2022 ENROLLMENTS' as problem,
    1 as enrollment_count,
    'c93c2e13-8579-4d14-aad4-f87997af2b6f' as enrollment_id,
    'SANTIAGO' as student_name,
    '453a4353-fc3a-4682-87ac-815da1186d68' as student_id,
    'Created 2025-12-16 but year=2022 (test data)' as note;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT 
    '============ SUMMARY ============' as section,
    '' as detail;

SELECT 'Enrollment ID Sharing' as issue_type, 61 as count, 'CRITICAL - Multiple students on one enrollment' as severity
UNION ALL
SELECT 'Duplicate Enrollments', 40, 'HIGH - Same student, different years'
UNION ALL
SELECT 'Test Students', 6, 'HIGH - Should be removed'
UNION ALL
SELECT 'Year 2022 Enrollments', 1, 'MEDIUM - Likely test data';
