-- Generated teacher batch
-- Teacher: Daniel Acevedo
-- Rows: 80

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Daniel Acevedo', 'daniel acevedo')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '10:00'::time, '10:45'::time, 'Electivo Bloque 1 - Fil - Geo - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '10:45'::time, '11:30'::time, 'Electivo Bloque 1 - Fil - Geo - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '12:30'::time, '13:15'::time, 'Electivo Bloque 1 - Geo - Arg - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '14:00'::time, '14:45'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '15:00'::time, '15:45'::time, 'Electivo Bloque 1 - Bio - Hist - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '15:45'::time, '16:30'::time, 'Electivo Bloque 1 - Bio - Hist - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 1, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '10:45'::time, '11:30'::time, 'Electivo Bloque 1 - Bio - Hist - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '11:45'::time, '12:30'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '14:00'::time, '14:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '15:00'::time, '15:45'::time, 'Electivo Bloque 1 - Geo - Arg - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '15:45'::time, '16:30'::time, 'Electivo Bloque 2 - Hist - Bio - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '16:30'::time, '16:45'::time, 'Reunión departamento Historia - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '16:45'::time, '18:00'::time, 'Reunión departamento Historia - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 2, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '09:00'::time, '09:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '10:00'::time, '10:45'::time, 'Electivo Bloque 1 - Bio - Hist - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '10:45'::time, '11:30'::time, 'Electivo Bloque 1 - Bio - Hist - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '11:45'::time, '12:30'::time, 'Electivo Bloque 2 - Hist - Bio - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '14:00'::time, '14:45'::time, 'Electivo Bloque 1 - Fil - Geo - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '15:00'::time, '15:45'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '15:45'::time, '16:30'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 3, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '08:15'::time, '09:00'::time, 'Electivo Bloque 1 - Geo - Arg - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '09:00'::time, '09:45'::time, 'Electivo Bloque 1 - Geo - Arg - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '10:00'::time, '10:45'::time, 'Electivo Bloque 1 - Bio - Hist - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '11:45'::time, '12:30'::time, 'Electivo Bloque 2 - Hist - Bio - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '12:30'::time, '13:15'::time, 'Electivo Bloque 2 - Hist - Bio - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '14:00'::time, '14:45'::time, 'Electivo Bloque 1 - Fil - Geo - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '15:00'::time, '15:45'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '15:45'::time, '16:30'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '16:45'::time, '18:00'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 4, '18:00'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '08:15'::time, '09:00'::time, 'Electivo Bloque 2 - Hist - Bio - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '09:00'::time, '09:45'::time, 'Electivo Bloque 2 - Hist - Bio - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '10:00'::time, '10:45'::time, 'Electivo Bloque 1 - Fil - Geo - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '10:45'::time, '11:30'::time, 'Electivo Bloque 1 - Fil - Geo - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '11:45'::time, '12:30'::time, 'Electivo Bloque 1 - Geo - Arg - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '12:30'::time, '13:15'::time, 'Electivo Bloque 1 - Geo - Arg - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'daniel acevedo', 5, '18:00'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: Gonzalo Muñoz
-- Rows: 80

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Gonzalo Muñoz', 'gonzalo munoz')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '09:00'::time, '09:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '10:00'::time, '10:45'::time, 'Educación Física - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '10:45'::time, '11:30'::time, 'Educación Física - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '11:45'::time, '12:30'::time, 'Educación Física - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '12:30'::time, '13:15'::time, 'Educación Física - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '14:00'::time, '14:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 1, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '08:15'::time, '09:00'::time, 'Educación Física - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '09:00'::time, '09:45'::time, 'Educación Física - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '10:00'::time, '10:45'::time, 'Educación Física - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '10:45'::time, '11:30'::time, 'Educación Física - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '14:00'::time, '14:45'::time, 'Electivo Bloque 3 - Artes - EFI - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '15:00'::time, '15:45'::time, 'Educación Física - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '15:45'::time, '16:30'::time, 'Educación Física - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '16:30'::time, '16:45'::time, 'Reunión departamento EFI - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '16:45'::time, '18:00'::time, 'Reunión departamento EFI - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 2, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '08:15'::time, '09:00'::time, 'Educación Física - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '09:00'::time, '09:45'::time, 'Educación Física - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '10:00'::time, '10:45'::time, 'Electivo Bloque 3 - Artes - EFI - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '10:45'::time, '11:30'::time, 'Electivo Bloque 3 - Artes - EFI - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '11:45'::time, '12:30'::time, 'Educación Física - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '12:30'::time, '13:15'::time, 'Educación Física - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '14:00'::time, '14:45'::time, 'Electivo Bloque 3 - Artes - EFI - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '15:00'::time, '15:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '15:45'::time, '16:30'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 3, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '09:00'::time, '09:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '10:00'::time, '10:45'::time, 'Electivo Bloque 3 - Artes - EFI - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '10:45'::time, '11:30'::time, 'Electivo Bloque 3 - Artes - EFI - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '11:45'::time, '12:30'::time, 'Educación Física - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '12:30'::time, '13:15'::time, 'Educación Física - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '14:00'::time, '14:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '15:00'::time, '15:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '15:45'::time, '16:30'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '16:45'::time, '18:00'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 4, '18:00'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '10:00'::time, '10:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '10:45'::time, '11:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '11:45'::time, '12:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '12:30'::time, '13:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '13:15'::time, '14:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'gonzalo munoz', 5, '18:00'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: Ignacio González
-- Rows: 75

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Ignacio González', 'ignacio gonzalez')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '08:15'::time, '09:00'::time, 'Formación Valórica/Pensamiento crítico - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '09:00'::time, '09:45'::time, 'Formación Valórica/Pensamiento crítico - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '10:00'::time, '10:45'::time, 'Historia - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '10:45'::time, '11:30'::time, 'Historia - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '14:00'::time, '14:45'::time, 'C. de Curso - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '15:00'::time, '15:45'::time, 'Historia - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '15:45'::time, '16:30'::time, 'Historia - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 1, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '08:15'::time, '09:00'::time, 'Historia - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '09:00'::time, '09:45'::time, 'Historia - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '12:30'::time, '13:15'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '13:15'::time, '14:00'::time, 'Historia - 5°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '14:00'::time, '14:45'::time, 'Historia - 5°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '15:00'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '15:45'::time, '16:30'::time, 'Reunión Depto.', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '16:30'::time, '16:45'::time, 'Reunión Depto.', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 2, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '08:15'::time, '09:00'::time, 'Historia - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '09:00'::time, '09:45'::time, 'Historia - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '10:00'::time, '10:45'::time, 'Historia - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '10:45'::time, '11:30'::time, 'Historia - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '14:00'::time, '14:45'::time, 'Orientación - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '15:00'::time, '15:45'::time, 'Historia - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '15:45'::time, '16:30'::time, 'Historia - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 3, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '08:15'::time, '09:00'::time, 'Historia - 6°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '09:00'::time, '09:45'::time, 'Historia - 6°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '10:00'::time, '10:45'::time, 'Historia - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '10:45'::time, '11:30'::time, 'Historia - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '14:00'::time, '14:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '15:00'::time, '15:45'::time, 'Formación Valórica/Pensamiento crítico - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '15:45'::time, '16:30'::time, 'Formación Valórica/Pensamiento crítico - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 4, '16:45'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '08:15'::time, '09:00'::time, 'Historia - 6°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '09:00'::time, '09:45'::time, 'Historia - 6°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '10:00'::time, '10:45'::time, 'Historia - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '10:45'::time, '11:30'::time, 'Historia - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '11:45'::time, '12:30'::time, 'Historia - 5°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '12:30'::time, '13:15'::time, 'Historia - 5°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ignacio gonzalez', 5, '16:45'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: Ingrid Nvarro
-- Rows: 80

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Ingrid Nvarro', 'ingrid nvarro')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '10:00'::time, '10:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '10:45'::time, '11:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '11:45'::time, '12:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '12:30'::time, '13:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '13:15'::time, '14:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 1, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '08:15'::time, '09:00'::time, 'Matemática - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '09:00'::time, '09:45'::time, 'Matemática - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '10:00'::time, '10:45'::time, 'Matemática - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '10:45'::time, '11:30'::time, 'Matemática - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '14:00'::time, '14:45'::time, 'Orientación - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '15:00'::time, '15:45'::time, 'Matemática - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '15:45'::time, '16:30'::time, 'Matemática - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '16:30'::time, '16:45'::time, 'Reunión departamento Ciencias - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '16:45'::time, '18:00'::time, 'Reunión departamento Ciencias - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 2, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '08:15'::time, '09:00'::time, 'Matemática - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '09:00'::time, '09:45'::time, 'Matemática - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '11:45'::time, '12:30'::time, 'Matemática - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '12:30'::time, '13:15'::time, 'Matemática - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '14:00'::time, '14:45'::time, 'C. de Curso - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '15:00'::time, '15:45'::time, 'Matemática - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '15:45'::time, '16:30'::time, 'Matemática - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 3, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '08:15'::time, '09:00'::time, 'Matemática - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '09:00'::time, '09:45'::time, 'Matemática - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '11:45'::time, '12:30'::time, 'Matemática - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '12:30'::time, '13:15'::time, 'Matemática - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '14:00'::time, '14:45'::time, 'Matemática - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '15:00'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '15:45'::time, '16:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '16:45'::time, '18:00'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 4, '18:00'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '09:00'::time, '09:45'::time, 'Matemática - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '10:00'::time, '10:45'::time, 'Matemática - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '10:45'::time, '11:30'::time, 'Matemática - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '11:45'::time, '12:30'::time, 'Matemática - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '13:15'::time, '14:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'ingrid nvarro', 5, '18:00'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: José Luis Olivos
-- Rows: 80

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'José Luis Olivos', 'jose luis olivos')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '09:00'::time, '09:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '10:00'::time, '10:45'::time, 'Matemática - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '10:45'::time, '11:30'::time, 'Matemática - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '11:45'::time, '12:30'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '12:30'::time, '13:15'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '14:00'::time, '14:45'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '15:00'::time, '15:45'::time, 'Taller Habilidades Científicas - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '15:45'::time, '16:30'::time, 'Taller Habilidades Científicas - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 1, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '09:00'::time, '09:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '10:00'::time, '10:45'::time, 'Matemática - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '10:45'::time, '11:30'::time, 'Matemática - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '11:45'::time, '12:30'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '12:30'::time, '13:15'::time, 'Orientación - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '14:00'::time, '14:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '15:00'::time, '15:45'::time, 'Matemática - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '15:45'::time, '16:30'::time, 'Matemática - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '16:30'::time, '16:45'::time, 'Reunión departamento Ciencias - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '16:45'::time, '18:00'::time, 'Reunión departamento Ciencias - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 2, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '08:15'::time, '09:00'::time, 'Matemática - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '09:00'::time, '09:45'::time, 'Matemática - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '14:00'::time, '14:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '15:00'::time, '15:45'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '15:45'::time, '16:30'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '16:45'::time, '18:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 3, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '08:15'::time, '09:00'::time, 'Taller de habilidades científicas - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '09:00'::time, '09:45'::time, 'Taller de habilidades científicas - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '10:00'::time, '10:45'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '10:45'::time, '11:30'::time, 'Matemática - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '11:45'::time, '12:30'::time, 'Matemática - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '12:30'::time, '13:15'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '14:00'::time, '14:45'::time, 'C. de Curso - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '15:00'::time, '15:45'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '15:45'::time, '16:30'::time, 'Electivo Bloque 1 - Geo - Int - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '16:45'::time, '18:00'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 4, '18:00'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '08:15'::time, '09:00'::time, 'Matemática - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '09:00'::time, '09:45'::time, 'Matemática - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '11:45'::time, '12:30'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '12:30'::time, '13:15'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'jose luis olivos', 5, '18:00'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: Juan Carlos Albornoz
-- Rows: 84

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Juan Carlos Albornoz', 'juan carlos albornoz')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '10:00'::time, '10:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '10:45'::time, '11:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '11:45'::time, '12:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '12:30'::time, '13:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '13:15'::time, '14:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '15:00'::time, '15:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '15:30'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '15:45'::time, '16:30'::time, 'Reunión departamento Artes - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '16:30'::time, '16:45'::time, 'Reunión departamento Artes - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '16:45'::time, '17:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 1, '17:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '08:15'::time, '09:00'::time, 'Música/Artes - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '09:00'::time, '09:45'::time, 'Música/Artes - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '11:45'::time, '12:30'::time, 'Música/ArtesVisuales - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '12:30'::time, '13:15'::time, 'Música/ArtesVisuales - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '14:00'::time, '14:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '14:45'::time, '15:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '15:00'::time, '15:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '15:30'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '15:45'::time, '16:30'::time, 'Orientación - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '16:45'::time, '17:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 2, '17:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '08:15'::time, '09:00'::time, 'Música/Artes - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '09:00'::time, '09:45'::time, 'Música/Artes - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '10:00'::time, '10:45'::time, 'Música - 6°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '10:45'::time, '11:30'::time, 'Música - 6°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '11:45'::time, '12:30'::time, 'Música/Artes Visuales - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '12:30'::time, '13:15'::time, 'Música/Artes Visuales - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '15:00'::time, '15:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '15:30'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '16:45'::time, '17:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 3, '17:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '10:00'::time, '10:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '10:45'::time, '11:30'::time, 'C. de Curso - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '14:00'::time, '14:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '14:45'::time, '15:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '15:00'::time, '15:30'::time, 'Música - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '15:45'::time, '16:30'::time, 'Música - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '16:45'::time, '17:00'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 4, '17:00'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '08:15'::time, '09:00'::time, 'Música/Artes - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '09:00'::time, '09:45'::time, 'Música/Artes - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '10:00'::time, '10:45'::time, 'Música - 5°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '10:45'::time, '11:30'::time, 'Música - 5°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '11:45'::time, '12:30'::time, 'Música - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '12:30'::time, '13:15'::time, 'Música - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '15:00'::time, '15:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '15:30'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '16:45'::time, '17:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'juan carlos albornoz', 5, '17:00'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: Karina Montoya
-- Rows: 80

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Karina Montoya', 'karina montoya')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '08:15'::time, '09:00'::time, 'Taller de habilidades científicas - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '09:00'::time, '09:45'::time, 'Taller de habilidades científicas - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '10:00'::time, '10:45'::time, 'Ciencias para la ciudadanía - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '10:45'::time, '11:30'::time, 'Ciencias para la ciudadanía - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '11:45'::time, '12:30'::time, 'Ciencias - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '12:30'::time, '13:15'::time, 'Ciencias - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '14:00'::time, '14:45'::time, 'Orientación - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '15:00'::time, '15:45'::time, 'Química - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '15:45'::time, '16:30'::time, 'Química - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 1, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '08:15'::time, '09:00'::time, 'Química - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '09:00'::time, '09:45'::time, 'Física - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '10:00'::time, '10:45'::time, 'Ciencias para la ciudadanía - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '10:45'::time, '11:30'::time, 'Ciencias para la ciudadanía - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '11:45'::time, '12:30'::time, 'Ciencias - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '12:30'::time, '13:15'::time, 'Ciencias - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '14:00'::time, '14:45'::time, 'C. de Curso - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '15:00'::time, '15:45'::time, 'Ciencias para la ciudadanía - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '15:45'::time, '16:30'::time, 'Ciencias para la ciudadanía - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '16:30'::time, '16:45'::time, 'Reunión departamento Ciencias - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '16:45'::time, '18:00'::time, 'Reunión departamento Ciencias - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 2, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '08:15'::time, '09:00'::time, 'Ciencias para la ciudadanía - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '09:00'::time, '09:45'::time, 'Ciencias para la ciudadanía - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '10:00'::time, '10:45'::time, 'Física - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '10:45'::time, '11:30'::time, 'Física - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '11:45'::time, '12:30'::time, 'Química - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '12:30'::time, '13:15'::time, 'Química - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '14:00'::time, '14:45'::time, 'Química - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '15:00'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '15:45'::time, '16:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '16:45'::time, '18:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 3, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '08:15'::time, '09:00'::time, 'Taller de habilidades científicas - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '09:00'::time, '09:45'::time, 'Taller de habilidades científicas - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '10:00'::time, '10:45'::time, 'Química - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '10:45'::time, '11:30'::time, 'Química - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '11:45'::time, '12:30'::time, 'Física - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '12:30'::time, '13:15'::time, 'Física - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '14:00'::time, '14:45'::time, 'Química - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '15:00'::time, '15:45'::time, 'Física - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '15:45'::time, '16:30'::time, 'Física - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '16:45'::time, '18:00'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 4, '18:00'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '08:15'::time, '09:00'::time, 'Física - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '09:00'::time, '09:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '12:30'::time, '13:15'::time, 'Física - I°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '13:15'::time, '14:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'karina montoya', 5, '18:00'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: Lorena Calderón
-- Rows: 80

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Lorena Calderón', 'lorena calderon')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '09:00'::time, '09:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '10:00'::time, '10:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '10:45'::time, '11:30'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '11:45'::time, '12:30'::time, 'Matemática - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '12:30'::time, '13:15'::time, 'Matemática - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '14:00'::time, '14:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '15:00'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '15:45'::time, '16:30'::time, 'Orientación - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 1, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '08:15'::time, '09:00'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '09:00'::time, '09:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '10:00'::time, '10:45'::time, 'PIE', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '10:45'::time, '11:30'::time, 'PIE', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '11:45'::time, '12:30'::time, 'Matemática - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '12:30'::time, '13:15'::time, 'Matemática - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '14:00'::time, '14:45'::time, 'C. de Curso - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '15:00'::time, '15:45'::time, 'Matemática - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '15:45'::time, '16:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '16:30'::time, '16:45'::time, 'Reunión departamento Ciencias - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '16:45'::time, '18:00'::time, 'Reunión departamento Ciencias - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 2, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '09:00'::time, '09:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '10:00'::time, '10:45'::time, 'Matemática - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '10:45'::time, '11:30'::time, 'Matemática - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '12:30'::time, '13:15'::time, 'Matemática - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '14:00'::time, '14:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '15:00'::time, '15:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '15:45'::time, '16:30'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 3, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '08:15'::time, '09:00'::time, 'Matemática - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '09:00'::time, '09:45'::time, 'Matemática - 7°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '10:00'::time, '10:45'::time, 'Matemática - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '10:45'::time, '11:30'::time, 'Matemática - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '14:00'::time, '14:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '15:00'::time, '15:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '15:45'::time, '16:30'::time, 'Electivo Bloque 3 - EFI - Prob - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '16:45'::time, '18:00'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 4, '18:00'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '10:00'::time, '10:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '10:45'::time, '11:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '11:45'::time, '12:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '12:30'::time, '13:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '13:15'::time, '14:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'lorena calderon', 5, '18:00'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: Paula Navia
-- Rows: 80

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Paula Navia', 'paula navia')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '09:00'::time, '09:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '10:00'::time, '10:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '10:45'::time, '11:30'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '11:45'::time, '12:30'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '12:30'::time, '13:15'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '14:00'::time, '14:45'::time, 'Orientación - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '15:00'::time, '15:45'::time, 'Educación Física - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '15:45'::time, '16:30'::time, 'Educación Física - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 1, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '08:15'::time, '09:00'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '09:00'::time, '09:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '11:45'::time, '12:30'::time, 'Educación Física - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '12:30'::time, '13:15'::time, 'Educación Física - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '14:00'::time, '14:45'::time, 'C. de Curso - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '15:00'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '15:45'::time, '16:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '16:45'::time, '18:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 2, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '09:00'::time, '09:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '14:00'::time, '14:45'::time, 'Electivo Bloque 3 - EFI - Prob - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '15:00'::time, '15:45'::time, 'Educación Física - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '15:45'::time, '16:30'::time, 'Educación Física - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '16:30'::time, '16:45'::time, 'Reunión departamento EFI - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '16:45'::time, '18:00'::time, 'Reunión departamento EFI - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 3, '18:00'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '08:15'::time, '09:00'::time, 'Educación Física - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '09:00'::time, '09:45'::time, 'Educación Física - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '10:00'::time, '10:45'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '11:45'::time, '12:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '12:30'::time, '13:15'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '14:00'::time, '14:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '15:00'::time, '15:45'::time, 'Educación Física - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '15:45'::time, '16:30'::time, 'Educación Física - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '16:45'::time, '18:00'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 4, '18:00'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '08:15'::time, '09:00'::time, 'Educación Física - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '09:00'::time, '09:45'::time, 'Educación Física - I°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '10:00'::time, '10:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '11:45'::time, '12:30'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '12:30'::time, '13:15'::time, 'Electivo Bloque 2 - Int - EFI - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '16:45'::time, '18:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'paula navia', 5, '18:00'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: Priscilla Cajales
-- Rows: 75

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Priscilla Cajales', 'priscilla cajales')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '08:15'::time, '09:00'::time, 'Lengua y Literatura - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '09:00'::time, '09:45'::time, 'Lengua y Literatura - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '10:00'::time, '10:45'::time, 'Electivo Bloque 2 - Lect - Bio - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '10:45'::time, '11:30'::time, 'Electivo Bloque 2 - Lect - Bio - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '11:45'::time, '12:30'::time, 'Lengua y Literatura - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '12:30'::time, '13:15'::time, 'Lengua y Literatura - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '14:00'::time, '14:45'::time, 'Lengua y Literatura - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '14:45'::time, '15:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '15:00'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '15:45'::time, '16:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 1, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '08:15'::time, '09:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '09:00'::time, '09:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '10:00'::time, '10:45'::time, 'Electivo Bloque 2 - Lect - Bio - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '10:45'::time, '11:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '11:45'::time, '12:30'::time, 'Electivo Bloque 2 - Lit - Arg - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '12:30'::time, '13:15'::time, 'Electivo Bloque 2 - Lit - Arg - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '14:00'::time, '14:45'::time, 'Electivo Bloque 2 - Lit - Arg - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '14:45'::time, '15:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '15:00'::time, '15:45'::time, 'Lengua y Literatura - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '15:45'::time, '16:30'::time, 'Lengua y Literatura - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 2, '16:45'::time, '18:15'::time, 'Depto.', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '10:00'::time, '10:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '10:45'::time, '11:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '11:45'::time, '12:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '12:30'::time, '13:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '13:15'::time, '14:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 3, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '08:15'::time, '09:00'::time, 'Electivo Bloque 2 - Lect - Bio - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '09:00'::time, '09:45'::time, 'Electivo Bloque 2 - Lect - Bio - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '10:00'::time, '10:45'::time, 'Lengua y Literatura - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '10:45'::time, '11:30'::time, 'Lengua y Literatura - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '11:45'::time, '12:30'::time, 'Electivo Bloque 2 - Lit - Arg - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '12:30'::time, '13:15'::time, 'Electivo Bloque 2 - Lit - Arg - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '14:00'::time, '14:45'::time, 'Electivo Bloque 2 - Lit - Arg - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '14:45'::time, '15:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '15:00'::time, '15:45'::time, 'Lengua y Literatura - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '15:45'::time, '16:30'::time, 'Lengua y Literatura - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '16:30'::time, '16:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 4, '16:45'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '08:15'::time, '09:00'::time, 'Lengua y Literatura - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '09:00'::time, '09:45'::time, 'Lengua y Literatura - 8°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '10:00'::time, '10:45'::time, 'Lengua y Literatura - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '10:45'::time, '11:30'::time, 'Lengua y Literatura - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '11:45'::time, '12:30'::time, 'Electivo Bloque 2 - Lect - Bio - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '12:30'::time, '13:15'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'priscilla cajales', 5, '16:45'::time, '18:15'::time, 'Sin clases', false)
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


-- Generated teacher batch
-- Teacher: Sergio Pino
-- Rows: 75

BEGIN;

WITH docentes_seed(owner_id, nombre_display, nombre_normalizado) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'Sergio Pino', 'sergio pino')
)
INSERT INTO public.docentes (owner_id, nombre_display, nombre_normalizado)
SELECT owner_id, nombre_display, nombre_normalizado
FROM docentes_seed
ON CONFLICT (owner_id, nombre_normalizado) DO UPDATE
SET nombre_display = EXCLUDED.nombre_display,
    updated_at = now();

WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (
  VALUES
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '08:15'::time, '09:00'::time, 'Historia - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '09:00'::time, '09:45'::time, 'Historia - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '10:00'::time, '10:45'::time, 'Formación Valórica/Pensamiento crítico - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '10:45'::time, '11:30'::time, 'Formación Valórica/Pensamiento crítico - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '11:45'::time, '12:30'::time, 'Educación Ciudadana - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '12:30'::time, '13:15'::time, 'Educación Ciudadana - IV°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '14:00'::time, '14:45'::time, 'Orientación - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '15:00'::time, '15:45'::time, 'Educación Ciudadana - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '15:45'::time, '16:30'::time, 'Educación Ciudadana - IV°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 1, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '08:15'::time, '09:00'::time, 'Volante', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '09:00'::time, '09:45'::time, 'Volante', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '10:00'::time, '10:45'::time, 'Historia - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '10:45'::time, '11:30'::time, 'Historia - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '11:45'::time, '12:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '12:30'::time, '13:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '14:00'::time, '14:45'::time, 'C. de Curso - II°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '15:00'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '15:45'::time, '16:30'::time, 'Reunión depto.', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '16:30'::time, '16:45'::time, 'Reunión depto.', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 2, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '10:00'::time, '10:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '10:45'::time, '11:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '11:45'::time, '12:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '12:30'::time, '13:15'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '13:15'::time, '14:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 3, '16:45'::time, '18:15'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '08:15'::time, '09:00'::time, 'Volante', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '09:00'::time, '09:45'::time, 'Volante', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '10:00'::time, '10:45'::time, 'Volante', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '10:45'::time, '11:30'::time, 'Volante', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '11:45'::time, '12:30'::time, 'Volante', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '12:30'::time, '13:15'::time, 'Volante', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '14:00'::time, '14:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '14:45'::time, '15:00'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '15:00'::time, '15:45'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '15:45'::time, '16:30'::time, 'Permanencia', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '16:30'::time, '16:45'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 4, '16:45'::time, '18:15'::time, 'Consejo de Profesores - Curso', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '08:15'::time, '09:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '09:00'::time, '09:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '09:45'::time, '10:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '10:00'::time, '10:45'::time, 'Educación Ciudadana - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '10:45'::time, '11:30'::time, 'Educación Ciudadana - III°B', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '11:30'::time, '11:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '11:45'::time, '12:30'::time, 'Educación Ciudadana - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '12:30'::time, '13:15'::time, 'Educación Ciudadana - III°A', true),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '13:15'::time, '14:00'::time, 'Almuerzo', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '14:00'::time, '14:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '14:45'::time, '15:00'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '15:00'::time, '15:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '15:45'::time, '16:30'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '16:30'::time, '16:45'::time, 'Sin clases', false),
    ('f4bb5599-a34c-4500-a338-365b6907bd88'::uuid, 'sergio pino', 5, '16:45'::time, '18:15'::time, 'Sin clases', false)
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


