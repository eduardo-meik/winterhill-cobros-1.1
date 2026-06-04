-- Generated teacher batch
-- Teacher: Lorena Pizarro
-- Rows: 75

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Lorena Pizarro', 'lorena pizarro')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '08:15'::time, '09:00'::time, 'Inglés - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '09:00'::time, '09:45'::time, 'Inglés - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '10:00'::time, '10:45'::time, 'Inglés - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '10:45'::time, '11:30'::time, 'Inglés - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '11:45'::time, '12:30'::time, 'Inglés - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '12:30'::time, '13:15'::time, 'Inglés - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 1, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '08:15'::time, '09:00'::time, 'Inglés - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '09:00'::time, '09:45'::time, 'Inglés - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '10:00'::time, '10:45'::time, 'Inglés - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '10:45'::time, '11:30'::time, 'Inglés - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '11:45'::time, '12:30'::time, 'Inglés - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '12:30'::time, '13:15'::time, 'Inglés - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '14:00'::time, '14:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '14:45'::time, '15:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '15:00'::time, '15:45'::time, 'Inglés - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '15:45'::time, '16:30'::time, 'Inglés - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '16:30'::time, '16:45'::time, 'Reunión Depto.', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 2, '16:45'::time, '18:15'::time, 'Reunión Depto.', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '08:15'::time, '09:00'::time, 'Inglés - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '09:00'::time, '09:45'::time, 'Inglés - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '10:00'::time, '10:45'::time, 'Inglés - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '10:45'::time, '11:30'::time, 'Inglés - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '11:45'::time, '12:30'::time, 'Inglés - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '12:30'::time, '13:15'::time, 'Inglés - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 3, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '08:15'::time, '09:00'::time, 'Inglés - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '09:00'::time, '09:45'::time, 'Inglés - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '15:00'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '15:45'::time, '16:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 4, '16:45'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '08:15'::time, '09:00'::time, 'Inglés - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '09:00'::time, '09:45'::time, 'Inglés - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '10:00'::time, '10:45'::time, 'Inglés - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '10:45'::time, '11:30'::time, 'Inglés - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '11:45'::time, '12:30'::time, 'Inglés - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '12:30'::time, '13:15'::time, 'Inglés - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena pizarro', 5, '16:45'::time, '18:15'::time, 'Sin clases', false)
), docentes_ref AS (
  SELECT id, owner_id, nombre_normalizado
  FROM public.docentes
  WHERE owner_id = 'f4bb5599-a34c-4500-a338-365b6907bd88'::uuid
)
INSERT INTO public.docentes_horarios_plantilla (
  owner_id,
  docente_id,
  dia_semana,
  hora_inicio,
  hora_fin,
  actividad,
  es_lectivo
)
SELECT
  hs.owner_id,
  d.id,
  hs.dia_semana,
  hs.hora_inicio,
  hs.hora_fin,
  hs.actividad,
  hs.es_lectivo
FROM horarios_seed hs
JOIN docentes_ref d
  ON d.owner_id = hs.owner_id
 AND d.nombre_normalizado = hs.nombre_normalizado
ON CONFLICT (owner_id, docente_id, dia_semana, hora_inicio, hora_fin, actividad) DO NOTHING;

COMMIT;
