-- =============================================================
-- FIX: Actualizar students.curso para 27 alumnos
-- Fuente de verdad: update_20260316.csv
-- Fecha: 2026-03-16
-- =============================================================
-- NOTA: Para las 7 filas CSV sin sección (ej. "1° BASICO", "2° BASICO"),
-- se asigna sección A por defecto ya que la tabla cursos requiere sección.
-- =============================================================

BEGIN;

-- ── P1: 1° MEDIO B (7 alumnos, CSV dice "1 MEDIO  B", BD tenía "1° MEDIO A") ──
UPDATE students SET curso = 'cca50b73-6f00-4d49-8593-c8f720aee981' -- 1° MEDIO B
WHERE id = 'f58fe5ef-4868-4203-9c67-f890f3ffd43c'; -- ANTONIO OSVALDO NEIRA FERNÁNDEZ (23622725-1)

UPDATE students SET curso = 'cca50b73-6f00-4d49-8593-c8f720aee981' -- 1° MEDIO B
WHERE id = 'b5d2d7d9-06df-46d0-91a1-d10d0ccd68f1'; -- EIDAN ALEXANDER MARCHANT GARRIDO (23802098-0)

UPDATE students SET curso = 'cca50b73-6f00-4d49-8593-c8f720aee981' -- 1° MEDIO B
WHERE id = 'a23b162c-a255-4e48-a5a5-8a7fcacece00'; -- GASPAR ANDRÉS ARAYA LARA (23808283-8)

UPDATE students SET curso = 'cca50b73-6f00-4d49-8593-c8f720aee981' -- 1° MEDIO B
WHERE id = 'eef2faa0-d445-4f9e-8ba0-20818dfa09be'; -- LEÓN REVECO PÉREZ (23884967-5)

UPDATE students SET curso = 'cca50b73-6f00-4d49-8593-c8f720aee981' -- 1° MEDIO B
WHERE id = 'cd235a94-9927-4ce7-811f-deb993f6800b'; -- LUKAS ANDRÉS CANELO GAETE (23886325-2)

UPDATE students SET curso = 'cca50b73-6f00-4d49-8593-c8f720aee981' -- 1° MEDIO B
WHERE id = 'b994c186-9b36-490b-a2df-027a168c9e1d'; -- MATILDA MAGDALENA GODOY DIDIER (23877976-6)

UPDATE students SET curso = 'cca50b73-6f00-4d49-8593-c8f720aee981' -- 1° MEDIO B
WHERE id = '2a9e7d8d-1cda-4d4c-a836-9fdd64fc11db'; -- MÁXIMO LEONIDAS EGAÑA CABRERA (23705014-2)

-- ── P1: 3° MEDIO B (3 alumnos, CSV dice "3 MEDIO  B", BD tenía "3° MEDIO A") ──
UPDATE students SET curso = 'd51eaf61-114c-452a-97ec-4c4d25a470e8' -- 3° MEDIO B
WHERE id = '6deccde7-c71d-467f-a01b-a3ca2d2ee2b3'; -- FACUNDO AGUILAR BROUSSAIN (23200888-1)

UPDATE students SET curso = 'd51eaf61-114c-452a-97ec-4c4d25a470e8' -- 3° MEDIO B
WHERE id = '5ec89816-98d5-4d29-baab-973cb0b5a849'; -- IGNACIA MIA RAMOS CORNEJO (23157963-K)

UPDATE students SET curso = 'd51eaf61-114c-452a-97ec-4c4d25a470e8' -- 3° MEDIO B
WHERE id = '84ff81f8-d76e-490e-9b85-07f1113a121f'; -- LUCAS PABLO BOBADILLA HECHENLEITNER (23051150-0)

-- ── P1: Par cruzado 3° BASICO A/B ──
UPDATE students SET curso = '94782d32-0dd5-43e4-8427-ea867ec3585e' -- 3° BASICO A
WHERE id = 'b79f3335-ba1a-478a-ab27-9dbaccb5a282'; -- SANDINO TAHIEL LABRÍN MUÑOZ (25969885-5)

UPDATE students SET curso = '5eb8af45-e865-4b42-9474-c6bf883e8fbe' -- 3° BASICO B
WHERE id = 'ddddd93b-730a-4d20-b3b7-34cc53ed591f'; -- ISIDORA IGNACIA SPIGETTH LABRÍN (26057653-4)

-- ── P1: 4° MEDIO A (2 alumnos, CSV dice "4 MEDIO  A", BD tenía "4° MEDIO B") ──
UPDATE students SET curso = '0edaf3bf-47b4-477a-9b3d-60370cc1d129' -- 4° MEDIO A
WHERE id = 'fd553b9a-4aeb-48c4-8725-80c8ad65eeb2'; -- GRACE ABIGAIL LARRONDO ESPINOZA (22948868-6)

UPDATE students SET curso = '0edaf3bf-47b4-477a-9b3d-60370cc1d129' -- 4° MEDIO A
WHERE id = '1bcf03fc-71b0-4766-a8de-ea9a36627a28'; -- JOSEFA RENATA RODRÍGUEZ ABURTO (22878786-8)

-- ── P1: Par cruzado 4° BASICO A/B ──
UPDATE students SET curso = '607d315d-5c3b-43bd-8975-92d6c27eef07' -- 4° BASICO A
WHERE id = '5a0be0bf-e267-428c-8bdb-ab7054b3984a'; -- AYLIN MAITE ELOÍSA ALARCÓN OYARZÚN (25511928-1)

UPDATE students SET curso = 'f0ddacc2-9993-4d74-8fd6-4d9f5d18c807' -- 4° BASICO B
WHERE id = '5985d0b9-b7bc-48dc-a000-673cc9153aca'; -- BRISA OLIVIA AVDALOV SAGREDO (25605450-7)

-- ── P2: CSV muestra nivel correcto según fuente de verdad ──
UPDATE students SET curso = 'cbb1029f-07db-49ac-ab27-56cc3ff879c3' -- 1° MEDIO A
WHERE id = '6fb76534-e07e-4d31-8acf-4844a2fc2795'; -- FRANCISCO TOMÁS VIZCARRA GANDARA (23470102-9)

UPDATE students SET curso = 'cca50b73-6f00-4d49-8593-c8f720aee981' -- 1° MEDIO B
WHERE id = '05855245-38ee-44eb-90ca-7b8c81e58784'; -- TRINIDAD IGNACIA BERTEINS VÁSQUEZ (23578484-K)

UPDATE students SET curso = 'a6bea2ea-c852-4e39-a676-1161f76c45d1' -- 1° BASICO A (CSV sin sección, default A)
WHERE id = 'baebae9a-d591-4b60-9a14-68bc69010563'; -- ANAÍS MARIEN WILSON CÁRCAMO (26746827-3)

UPDATE students SET curso = 'c3589804-f0d5-4e9a-ba29-4698bd800d9b' -- 2° BASICO A (CSV sin sección, default A)
WHERE id = '735e186f-e63e-443d-b0e7-117cc58f6d15'; -- CHARLOTTE ANDREA BIEHL SALAZAR (26559159-0)

UPDATE students SET curso = 'c3589804-f0d5-4e9a-ba29-4698bd800d9b' -- 2° BASICO A (CSV sin sección, default A)
WHERE id = 'fb4e23f6-f3a3-46ca-8235-a15094a02ebc'; -- DANTE ÁVALOS QUIÑONES (25938092-8)

UPDATE students SET curso = 'd51eaf61-114c-452a-97ec-4c4d25a470e8' -- 3° MEDIO B
WHERE id = '05ad76c9-d992-4e64-a5d6-5fd12a889bf5'; -- PHILIP ANTONIO VANI GUAJARDO (23251961-4)

UPDATE students SET curso = '800403ec-60bd-451a-b583-f4ec15251a52' -- 5° BASICO A (CSV sin sección, default A)
WHERE id = 'aff41538-7713-4127-8840-ff2b5b9148f2'; -- MAXIMILIANO ANDREÉ FILÚN SANTIBÁÑEZ (25227177-5)

UPDATE students SET curso = '9972dccb-64cc-407e-82fe-317792b69953' -- 7° BASICO A (CSV sin sección, default A)
WHERE id = 'a7997e1c-29c7-47dc-a645-21e664bcb585'; -- ELENA FRANCISCA EGAÑA CABRERA (24386397-K)

-- ── P3: Regresiones → CSV es fuente de verdad, se aplica igual ──
UPDATE students SET curso = 'c3589804-f0d5-4e9a-ba29-4698bd800d9b' -- 2° BASICO A (CSV sin sección, default A)
WHERE id = '8b3e7d87-6755-447e-a893-ce158df21115'; -- SANTIAGO MATTIA PAZ (26211725-1)

UPDATE students SET curso = 'f981cff8-b83a-42e4-9f95-d03bbe6f16b8' -- 4° MEDIO B
WHERE id = '719fba12-9be5-486c-9906-9c26418eefe7'; -- AMANDA ANTONIA ARÉVALO TOLEDO (22692513-9)

UPDATE students SET curso = 'e9040663-b175-4add-b59c-56d314e1a571' -- 6° BASICO A (CSV sin sección, default A)
WHERE id = 'b1f87e41-a351-4103-aea3-0713766c64ec'; -- ELOÍSA ANAÍS ALTAMIRANO MONSALVE (24830996-2)

COMMIT;
