-- Regularizacion 2026-04-07
-- Marca como prioritarios los alumnos reportados sin cuota 2026.
-- Regla de seguridad:
--   - Siempre actualiza per_student_economic y per_student_plans por alumno.
--   - Solo actualiza meta global (prioritario/payment_plan) cuando TODOS los alumnos
--     de la matricula pertenecen al listado objetivo.

with target_runs(run) as (
  values
    ('26.838.566-5'),
    ('23.882.519-9'),
    ('23.701.318-2'),
    ('23.705.014-2'),
    ('23.578.484-K'),
    ('23.399.594-0'),
    ('23.400.372-0'),
    ('23.126.375-6'),
    ('23.111.722-9'),
    ('23.157.963-K'),
    ('22.964.983-3'),
    ('22.969.713-7'),
    ('25.109.214-1'),
    ('25.125.189-4'),
    ('24.786.893-3'),
    ('24.704.324-1'),
    ('24.831.872-4'),
    ('24.386.397-K'),
    ('24.237.064-3')
), target_rows as (
  select
    e.id as enrollment_id,
    e.year,
    s.id as student_id,
    s.whole_name,
    s.run,
    e.meta
  from public.students s
  join target_runs tr on tr.run = s.run
  join public.enrollment_students es on es.student_id = s.id
  join public.enrollments e on e.id = es.enrollment_id
  where e.year = 2026
    and e.status = 'completed'
), enrollment_scope as (
  select
    e.id as enrollment_id,
    count(*) as total_students,
    count(*) filter (where tr.run is not null) as target_students
  from public.enrollments e
  join public.enrollment_students es on es.enrollment_id = e.id
  join public.students s on s.id = es.student_id
  left join target_runs tr on tr.run = s.run
  where e.year = 2026
    and e.status = 'completed'
    and e.id in (select distinct enrollment_id from target_rows)
  group by e.id
), prepared as (
  select
    tr.enrollment_id,
    tr.student_id,
    tr.whole_name,
    tr.run,
    (es.total_students = es.target_students) as all_students_are_targets,
    coalesce(tr.meta, '{}'::jsonb) as meta,
    coalesce(tr.meta->'per_student_economic', '{}'::jsonb) as per_student_economic,
    coalesce(tr.meta->'per_student_plans', '{}'::jsonb) as per_student_plans,
    coalesce(tr.meta->'payment_plan'->>'primer_vencimiento', make_date(tr.year, 3, 5)::text) as primer_vencimiento,
    coalesce(
      nullif((coalesce(tr.meta->'per_student_economic', '{}'::jsonb)->tr.student_id::text->>'monto_matricula'), '')::numeric,
      0
    ) as monto_matricula_actual
  from target_rows tr
  join enrollment_scope es on es.enrollment_id = tr.enrollment_id
), aggregated_updates as (
  select
    p.enrollment_id,
    bool_and(p.all_students_are_targets) as all_students_are_targets,
    min(p.meta::text)::jsonb as meta,
    min(p.per_student_economic::text)::jsonb as per_student_economic,
    min(p.per_student_plans::text)::jsonb as per_student_plans,
    min(p.primer_vencimiento) as primer_vencimiento,
    jsonb_object_agg(
      p.student_id::text,
      coalesce(p.per_student_economic->p.student_id::text, '{}'::jsonb) || jsonb_build_object(
        'prioritario', true,
        'monto_matricula', p.monto_matricula_actual,
        'colegiatura_anual', 0,
        'cantidad_cuotas', 0,
        'monto_cuota', 0,
        'dia_vencimiento', 5,
        'porcentaje_descuento', 0,
        'monto_total_descuento', 0
      )
    ) as target_student_economic,
    jsonb_object_agg(
      p.student_id::text,
      coalesce(p.per_student_plans->p.student_id::text, '{}'::jsonb) || jsonb_build_object(
        'cuotas', '[]'::jsonb,
        'n_cuotas', 0,
        'monto_total', 0,
        'payment_method', null,
        'dia_vencimiento', 5,
        'monto_por_cuota', 0,
        'primer_vencimiento', p.primer_vencimiento
      )
    ) as target_student_plans
  from prepared p
  group by p.enrollment_id
), final_meta as (
  select
    a.enrollment_id,
    case
      when a.all_students_are_targets then
        jsonb_set(
          jsonb_set(
            a.meta || jsonb_build_object(
              'prioritario', true,
              'cantidad_cuotas', 0,
              'monto_cuota', 0,
              'colegiatura_anual', 0,
              'forma_pago_cheques', false,
              'forma_pago_transferencia', false,
              'forma_pago_efectivo', false,
              'forma_pago_tarjeta', false,
              'forma_pago_pagare', false,
              'forma_pago_descuento_planilla', false,
              'payment_plan', jsonb_build_object(
                'cuotas', '[]'::jsonb,
                'n_cuotas', 0,
                'monto_total', 0,
                'payment_method', null,
                'dia_vencimiento', 5,
                'monto_por_cuota', 0,
                'primer_vencimiento', a.primer_vencimiento
              )
            ),
            '{per_student_economic}',
            a.per_student_economic || a.target_student_economic,
            true
          ),
          '{per_student_plans}',
          a.per_student_plans || a.target_student_plans,
          true
        )
      else
        jsonb_set(
          jsonb_set(
            a.meta,
            '{per_student_economic}',
            a.per_student_economic || a.target_student_economic,
            true
          ),
          '{per_student_plans}',
          a.per_student_plans || a.target_student_plans,
          true
        )
    end as new_meta
  from aggregated_updates a
)
update public.enrollments e
   set meta = f.new_meta,
       updated_at = now()
  from final_meta f
 where e.id = f.enrollment_id;
