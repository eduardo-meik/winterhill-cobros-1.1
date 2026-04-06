-- Diagnostico de aranceles y matriculas para casos reportados el 2026-04-06.
-- Ejecutar en Supabase SQL Editor.

-- Casos:
-- d29967d7-ddaf-46e9-9e51-9e3e98c18d63 = ARA IGNACIA SILVA VARGAS
-- 1d36e401-4922-47d9-8951-d063e423c6d5 = AYUN CEPEDA FOXON
-- 6952432f-f7ab-4774-9ef6-1d9d050f1892 = LETICIA COLOMBA ALARCON HUERTA
-- 70a10f4b-99a0-490d-b5e4-df926d8447a9 = SANTIAGO AMARO ALARCON HUERTA
-- 8b3e7d87-6755-447e-a893-ce158df21115 = SANTIAGO MATTIA PAZ

with target_students as (
  select *
  from public.students
  where id in (
    'd29967d7-ddaf-46e9-9e51-9e3e98c18d63',
    '1d36e401-4922-47d9-8951-d063e423c6d5',
    '6952432f-f7ab-4774-9ef6-1d9d050f1892',
    '70a10f4b-99a0-490d-b5e4-df926d8447a9',
    '8b3e7d87-6755-447e-a893-ce158df21115'
  )
)
select
  s.id as student_id,
  s.whole_name,
  s.run,
  s.estado_std,
  c.nom_curso as curso_actual,
  c.year_academico as curso_year,
  count(*) filter (where f.year_academico = 2025) as fee_2025_total,
  count(*) filter (where f.year_academico = 2026) as fee_2026_total,
  count(*) filter (where f.year_academico = 2026 and f.status = 'paid') as fee_2026_paid,
  count(*) filter (where f.year_academico = 2026 and f.status in ('pending', 'overdue')) as fee_2026_pending
from target_students s
left join public.cursos c on c.id = s.curso
left join public.fee f on f.student_id = s.id
group by s.id, s.whole_name, s.run, s.estado_std, c.nom_curso, c.year_academico
order by s.whole_name;

-- Ultima matricula 2026 por alumno reportado.
with target_students as (
  select *
  from public.students
  where id in (
    'd29967d7-ddaf-46e9-9e51-9e3e98c18d63',
    '1d36e401-4922-47d9-8951-d063e423c6d5',
    '6952432f-f7ab-4774-9ef6-1d9d050f1892',
    '70a10f4b-99a0-490d-b5e4-df926d8447a9',
    '8b3e7d87-6755-447e-a893-ce158df21115'
  )
), ranked_enrollments as (
  select
    s.whole_name,
    s.run,
    es.student_id,
    e.id as enrollment_id,
    e.year,
    e.status,
    e.meta,
    e.created_at,
    e.updated_at,
    row_number() over (partition by es.student_id order by e.year desc, e.updated_at desc nulls last) as rn
  from target_students s
  join public.enrollment_students es on es.student_id = s.id
  join public.enrollments e on e.id = es.enrollment_id
)
select *
from ranked_enrollments
where rn = 1
order by whole_name;

-- Cuotas 2026 faltantes o incompletas para matriculas completadas 2026.
with completed_2026 as (
  select
    s.id as student_id,
    s.whole_name,
    s.run,
    e.id as enrollment_id,
    e.meta,
    e.updated_at
  from public.students s
  join public.enrollment_students es on es.student_id = s.id
  join public.enrollments e on e.id = es.enrollment_id
  where e.year = 2026
    and e.status = 'completed'
), fee_totals as (
  select
    student_id,
    count(*) filter (where year_academico = 2026) as fee_2026_total
  from public.fee
  group by student_id
)
select
  c.whole_name,
  c.run,
  c.enrollment_id,
  coalesce(f.fee_2026_total, 0) as fee_2026_total,
  c.meta
from completed_2026 c
left join fee_totals f on f.student_id = c.student_id
where coalesce(f.fee_2026_total, 0) = 0
   or coalesce(f.fee_2026_total, 0) < 10
order by fee_2026_total, c.whole_name;

-- Matriculas 2026 completadas cuya meta no trae plan de pago usable.
select
  e.id as enrollment_id,
  e.year,
  e.status,
  e.updated_at,
  e.meta ->> 'folio' as folio,
  e.meta ? 'payment_plan' as has_payment_plan,
  e.meta ? 'per_student_plans' as has_per_student_plans,
  e.meta ? 'per_student_economic' as has_per_student_economic,
  array_agg(s.whole_name order by s.whole_name) as students
from public.enrollments e
join public.enrollment_students es on es.enrollment_id = e.id
join public.students s on s.id = es.student_id
where e.year = 2026
  and e.status = 'completed'
group by e.id, e.year, e.status, e.updated_at, e.meta
having not (e.meta ? 'payment_plan')
   and not (e.meta ? 'per_student_plans');

-- Filas 2026 sospechosas creadas por correcciones manuales y no por finalize_enrollment.
select
  s.whole_name,
  s.run,
  f.year_academico,
  f.numero_cuota,
  f.status,
  f.amount,
  f.payment_date,
  f.due_date,
  f.payment_method,
  f.num_boleta,
  f.meta
from public.fee f
join public.students s on s.id = f.student_id
where f.year_academico = 2026
  and (
    coalesce(f.meta ->> 'source', '') <> 'finalize_enrollment'
    or f.meta ? 'sync_reason'
  )
  and s.id in (
    'd29967d7-ddaf-46e9-9e51-9e3e98c18d63',
    '1d36e401-4922-47d9-8951-d063e423c6d5',
    '6952432f-f7ab-4774-9ef6-1d9d050f1892',
    '70a10f4b-99a0-490d-b5e4-df926d8447a9',
    '8b3e7d87-6755-447e-a893-ce158df21115'
  )
order by s.whole_name, f.numero_cuota;

-- Casos 2026 completados pero con estado_std anomalo para seguimiento.
select
  s.id as student_id,
  s.whole_name,
  s.run,
  s.estado_std,
  e.id as enrollment_id,
  e.status as enrollment_status,
  e.updated_at
from public.students s
join public.enrollment_students es on es.student_id = s.id
join public.enrollments e on e.id = es.enrollment_id
where e.year = 2026
  and e.status = 'completed'
  and s.estado_std not in ('ACTIVO', 'MATRICULADO', 'PRE_MATRICULADO')
order by s.whole_name;