-- Diagnostico: alumnos realmente sin cuotas 2026.
-- Excluye casos exentos/prioritarios y matriculas con plan explicitamente en cero.
-- Ejecutar en Supabase SQL Editor.

with params as (
  select 2026::int as target_year
), completed_enrollments as (
  select
    e.id as enrollment_id,
    es.student_id,
    s.whole_name,
    s.run,
    s.estado_std,
    s.fecha_matricula,
    c.nom_curso as curso_actual,
    e.created_at as enrollment_created_at,
    e.updated_at as enrollment_updated_at,
    e.meta,
    (
      coalesce((e.meta->>'prioritario')::boolean, false)
      or coalesce((e.meta->'per_student_economic'->es.student_id::text->>'prioritario')::boolean, false)
    ) as prioritario,
    coalesce(
      nullif(e.meta->>'cantidad_cuotas', '')::int,
      nullif(e.meta->'payment_plan'->>'n_cuotas', '')::int,
      0
    ) as planned_installments,
    coalesce(
      nullif(e.meta->>'monto_cuota', '')::numeric,
      nullif(e.meta->'payment_plan'->>'monto_por_cuota', '')::numeric,
      0
    ) as planned_installment_amount,
    coalesce(
      nullif(e.meta->>'colegiatura_anual', '')::numeric,
      nullif(e.meta->'payment_plan'->>'monto_total', '')::numeric,
      0
    ) as planned_total,
    e.meta ? 'payment_plan' as has_payment_plan,
    e.meta ? 'per_student_plans' as has_per_student_plans
  from public.enrollments e
  join params p on p.target_year = e.year
  join public.enrollment_students es on es.enrollment_id = e.id
  join public.students s on s.id = es.student_id
  left join public.cursos c on c.id = s.curso
  where e.status = 'completed'
), fee_agg as (
  select
    f.student_id,
    count(*) filter (where f.year_academico = (select target_year from params)) as fee_count_target_year,
    array_agg(distinct coalesce(f.meta->>'source', 'unknown'))
      filter (where f.year_academico = (select target_year from params)) as fee_sources_target_year
  from public.fee f
  group by f.student_id
)
select
  ce.whole_name,
  ce.run,
  ce.estado_std,
  ce.fecha_matricula,
  ce.curso_actual,
  ce.enrollment_id,
  ce.enrollment_created_at,
  ce.enrollment_updated_at,
  coalesce(fa.fee_count_target_year, 0) as fee_count_target_year,
  ce.prioritario,
  ce.planned_installments,
  ce.planned_installment_amount,
  ce.planned_total,
  ce.has_payment_plan,
  ce.has_per_student_plans,
  fa.fee_sources_target_year,
  case
    when not ce.has_payment_plan and not ce.has_per_student_plans then 'missing_plan_metadata'
    when ce.has_per_student_plans and not ce.has_payment_plan then 'per_student_plan_only'
    else 'plan_present_but_fee_missing'
  end as diagnostic_reason,
  ce.meta as enrollment_meta
from completed_enrollments ce
left join fee_agg fa on fa.student_id = ce.student_id
where coalesce(fa.fee_count_target_year, 0) = 0
  and not ce.prioritario
  and (
    ce.planned_installments > 0
    or ce.planned_installment_amount > 0
    or ce.planned_total > 0
    or (not ce.has_payment_plan and not ce.has_per_student_plans)
  )
order by ce.curso_actual nulls last, ce.whole_name;