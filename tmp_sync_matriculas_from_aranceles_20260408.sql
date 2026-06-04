-- Sincroniza enrollments.meta tomando fee como fuente definitiva.
-- Alcance: enrollments 2026 en estado completed.
-- Recomendado: ejecutar primero el bloque PREVIEW y revisar resultados antes del UPDATE.

with enrollment_base as (
  select
    e.id as enrollment_id,
    es.student_id,
    e.meta,
    count(*) over (partition by e.id) as enrollment_student_count,
    upper(
      coalesce(
        nullif(e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'payment_method', ''),
        nullif(e.meta ->> 'payment_method', ''),
        case when lower(coalesce(e.meta ->> 'prioritario', 'false')) = 'true' then 'PRIORITARIO' else '' end,
        case when lower(coalesce(e.meta ->> 'forma_pago_pagare', 'false')) = 'true' then 'PAGARE' else '' end,
        case when lower(coalesce(e.meta ->> 'forma_pago_cheques', 'false')) = 'true' then 'CHEQUE' else '' end,
        case when lower(coalesce(e.meta ->> 'forma_pago_tarjeta', 'false')) = 'true' then 'TARJETA' else '' end,
        case when lower(coalesce(e.meta ->> 'forma_pago_transferencia', 'false')) = 'true' then 'TRANSFERENCIA' else '' end,
        case when lower(coalesce(e.meta ->> 'forma_pago_descuento_planilla', 'false')) = 'true' then 'PLANILLA' else '' end,
        case when lower(coalesce(e.meta ->> 'forma_pago_efectivo', 'false')) = 'true' then 'EFECTIVO' else '' end,
        null
      )
    ) as current_payment_method,
    lower(
      coalesce(
        e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'prioritario',
        e.meta ->> 'prioritario',
        'false'
      )
    ) = 'true' as current_prioritario,
    case
      when regexp_replace(
        coalesce(
          e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'cantidad_cuotas',
          e.meta ->> 'cantidad_cuotas',
          e.meta #>> '{payment_plan,n_cuotas}',
          ''
        ),
        '[^0-9-]',
        '',
        'g'
      ) <> ''
      then regexp_replace(
        coalesce(
          e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'cantidad_cuotas',
          e.meta ->> 'cantidad_cuotas',
          e.meta #>> '{payment_plan,n_cuotas}',
          ''
        ),
        '[^0-9-]',
        '',
        'g'
      )::int
      else null
    end as current_cuotas,
    case
      when regexp_replace(
        coalesce(
          e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'monto_cuota',
          e.meta ->> 'monto_cuota',
          e.meta #>> '{payment_plan,monto_por_cuota}',
          ''
        ),
        '[^0-9.-]',
        '',
        'g'
      ) <> ''
      then regexp_replace(
        coalesce(
          e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'monto_cuota',
          e.meta ->> 'monto_cuota',
          e.meta #>> '{payment_plan,monto_por_cuota}',
          ''
        ),
        '[^0-9.-]',
        '',
        'g'
      )::numeric
      else null
    end as current_monto_cuota,
    case
      when regexp_replace(
        coalesce(
          e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'colegiatura_anual',
          e.meta ->> 'colegiatura_anual',
          e.meta #>> '{payment_plan,monto_total}',
          ''
        ),
        '[^0-9.-]',
        '',
        'g'
      ) <> ''
      then regexp_replace(
        coalesce(
          e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'colegiatura_anual',
          e.meta ->> 'colegiatura_anual',
          e.meta #>> '{payment_plan,monto_total}',
          ''
        ),
        '[^0-9.-]',
        '',
        'g'
      )::numeric
      else null
    end as current_total_anual
  from public.enrollments e
  join public.enrollment_students es on es.enrollment_id = e.id
  where e.year = 2026
    and e.status = 'completed'
), fee_detail as (
  select
    f.enrollment_id,
    f.student_id,
    case
      when upper(coalesce(f.payment_method, '')) like '%PAGARE%' then 'PAGARE'
      when upper(coalesce(f.payment_method, '')) like '%CHEQ%' then 'CHEQUE'
      when upper(coalesce(f.payment_method, '')) like '%TARJ%' then 'TARJETA'
      when upper(coalesce(f.payment_method, '')) like '%TRANS%' then 'TRANSFERENCIA'
      when upper(coalesce(f.payment_method, '')) like '%PLANILL%' then 'PLANILLA'
      when upper(coalesce(f.payment_method, '')) like '%EFECT%' then 'EFECTIVO'
      when coalesce(f.payment_method, '') = '' then 'SIN_DATO'
      else upper(f.payment_method)
    end as normalized_payment_method,
    f.amount,
    f.numero_cuota,
    f.due_date,
    f.id
  from public.fee f
  where f.year_academico = 2026
), fee_agg as (
  select
    fd.enrollment_id,
    fd.student_id,
    count(*) as fee_count,
    string_agg(distinct fd.normalized_payment_method, '|' order by fd.normalized_payment_method) as fee_payment_method,
    min(fd.amount) as fee_monto_min,
    max(fd.amount) as fee_monto_max,
    sum(fd.amount) as fee_total,
    min(fd.numero_cuota) as fee_min_cuota,
    max(fd.numero_cuota) as fee_max_cuota,
    min(fd.due_date) as fee_first_due_date,
    extract(day from min(fd.due_date))::int as fee_due_day,
    jsonb_agg(
      jsonb_build_object(
        'amount', fd.amount,
        'numero', fd.numero_cuota,
        'due_date', to_char(fd.due_date, 'YYYY-MM-DD')
      )
      order by fd.numero_cuota nulls last, fd.due_date, fd.id
    ) as fee_schedule
  from fee_detail fd
  group by fd.enrollment_id, fd.student_id
), targets as (
  select
    eb.*,
    coalesce(fa.fee_count, 0) as fee_count,
    fa.fee_payment_method,
    fa.fee_monto_min,
    fa.fee_monto_max,
    fa.fee_total,
    fa.fee_min_cuota,
    fa.fee_max_cuota,
    fa.fee_first_due_date,
    fa.fee_due_day,
    fa.fee_schedule,
    case
      when coalesce(fa.fee_count, 0) > 0 then fa.fee_payment_method
      when eb.current_prioritario then 'PRIORITARIO'
      else null
    end as target_payment_method,
    case
      when coalesce(fa.fee_count, 0) > 0 then false
      else eb.current_prioritario
    end as target_prioritario,
    case
      when coalesce(fa.fee_count, 0) > 0 then fa.fee_count
      else null
    end as target_cuotas,
    case
      when coalesce(fa.fee_count, 0) > 0 and fa.fee_monto_min = fa.fee_monto_max then fa.fee_monto_min
      else null
    end as target_monto_cuota,
    case
      when coalesce(fa.fee_count, 0) > 0 then fa.fee_total
      else null
    end as target_total_anual,
    case
      when coalesce(fa.fee_count, 0) > 0 then jsonb_build_object(
        'cuotas', fa.fee_schedule,
        'n_cuotas', fa.fee_count,
        'monto_total', fa.fee_total,
        'payment_method', fa.fee_payment_method,
        'dia_vencimiento', fa.fee_due_day,
        'monto_por_cuota', case when fa.fee_monto_min = fa.fee_monto_max then fa.fee_monto_min else null end,
        'primer_vencimiento', to_char(fa.fee_first_due_date, 'YYYY-MM-DD')
      )
      else null
    end as target_payment_plan
  from enrollment_base eb
  left join fee_agg fa
    on fa.enrollment_id = eb.enrollment_id
   and fa.student_id = eb.student_id
), changes as (
  select
    t.*,
    jsonb_build_object(
      'payment_method', case
        when t.fee_count = 0 and t.target_payment_method is null then to_jsonb(''::text)
        else to_jsonb(t.target_payment_method)
      end,
      'prioritario', to_jsonb(t.target_prioritario),
      'cantidad_cuotas', case
        when t.fee_count = 0 and t.target_cuotas is null then to_jsonb(''::text)
        else to_jsonb(t.target_cuotas)
      end,
      'monto_cuota', case
        when t.fee_count = 0 and t.target_monto_cuota is null then to_jsonb(''::text)
        else to_jsonb(t.target_monto_cuota)
      end,
      'colegiatura_anual', case
        when t.fee_count = 0 and t.target_total_anual is null then to_jsonb(''::text)
        else to_jsonb(t.target_total_anual)
      end,
      'year_academico', to_jsonb(2026),
      'dia_vencimiento', case
        when t.fee_count = 0 then to_jsonb(''::text)
        else to_jsonb(t.fee_due_day)
      end
    ) as student_patch,
    jsonb_build_object(
      'payment_method', to_jsonb(t.target_payment_method),
      'prioritario', to_jsonb(t.target_prioritario),
      'cantidad_cuotas', to_jsonb(t.target_cuotas),
      'monto_cuota', to_jsonb(t.target_monto_cuota),
      'colegiatura_anual', to_jsonb(t.target_total_anual),
      'forma_pago_pagare', to_jsonb(position('PAGARE' in coalesce(t.target_payment_method, '')) > 0),
      'forma_pago_cheques', to_jsonb(position('CHEQUE' in coalesce(t.target_payment_method, '')) > 0),
      'forma_pago_tarjeta', to_jsonb(position('TARJETA' in coalesce(t.target_payment_method, '')) > 0),
      'forma_pago_transferencia', to_jsonb(position('TRANSFERENCIA' in coalesce(t.target_payment_method, '')) > 0),
      'forma_pago_descuento_planilla', to_jsonb(position('PLANILLA' in coalesce(t.target_payment_method, '')) > 0),
      'forma_pago_efectivo', to_jsonb(position('EFECTIVO' in coalesce(t.target_payment_method, '')) > 0)
    ) as root_patch,
    (
      t.current_prioritario is distinct from t.target_prioritario
      or t.current_payment_method is distinct from t.target_payment_method
      or t.current_cuotas is distinct from t.target_cuotas
      or t.current_monto_cuota is distinct from t.target_monto_cuota
      or t.current_total_anual is distinct from t.target_total_anual
    ) as needs_update
  from targets t
), preview as (
  select
    enrollment_id,
    student_id,
    current_payment_method,
    target_payment_method,
    current_prioritario,
    target_prioritario,
    current_cuotas,
    target_cuotas,
    current_monto_cuota,
    target_monto_cuota,
    current_total_anual,
    target_total_anual,
    fee_count,
    enrollment_student_count
  from changes
  where needs_update
)
select *
from preview
order by enrollment_id, student_id;

-- UPDATE
-- Descomenta desde BEGIN hasta COMMIT cuando hayas validado el PREVIEW.

-- begin;
-- with enrollment_base as (
--   select
--     e.id as enrollment_id,
--     es.student_id,
--     e.meta,
--     count(*) over (partition by e.id) as enrollment_student_count,
--     upper(
--       coalesce(
--         nullif(e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'payment_method', ''),
--         nullif(e.meta ->> 'payment_method', ''),
--         case when lower(coalesce(e.meta ->> 'prioritario', 'false')) = 'true' then 'PRIORITARIO' else '' end,
--         case when lower(coalesce(e.meta ->> 'forma_pago_pagare', 'false')) = 'true' then 'PAGARE' else '' end,
--         case when lower(coalesce(e.meta ->> 'forma_pago_cheques', 'false')) = 'true' then 'CHEQUE' else '' end,
--         case when lower(coalesce(e.meta ->> 'forma_pago_tarjeta', 'false')) = 'true' then 'TARJETA' else '' end,
--         case when lower(coalesce(e.meta ->> 'forma_pago_transferencia', 'false')) = 'true' then 'TRANSFERENCIA' else '' end,
--         case when lower(coalesce(e.meta ->> 'forma_pago_descuento_planilla', 'false')) = 'true' then 'PLANILLA' else '' end,
--         case when lower(coalesce(e.meta ->> 'forma_pago_efectivo', 'false')) = 'true' then 'EFECTIVO' else '' end,
--         null
--       )
--     ) as current_payment_method,
--     lower(
--       coalesce(
--         e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'prioritario',
--         e.meta ->> 'prioritario',
--         'false'
--       )
--     ) = 'true' as current_prioritario,
--     case
--       when regexp_replace(coalesce(e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'cantidad_cuotas', e.meta ->> 'cantidad_cuotas', e.meta #>> '{payment_plan,n_cuotas}', ''), '[^0-9-]', '', 'g') <> ''
--       then regexp_replace(coalesce(e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'cantidad_cuotas', e.meta ->> 'cantidad_cuotas', e.meta #>> '{payment_plan,n_cuotas}', ''), '[^0-9-]', '', 'g')::int
--       else null
--     end as current_cuotas,
--     case
--       when regexp_replace(coalesce(e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'monto_cuota', e.meta ->> 'monto_cuota', e.meta #>> '{payment_plan,monto_por_cuota}', ''), '[^0-9.-]', '', 'g') <> ''
--       then regexp_replace(coalesce(e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'monto_cuota', e.meta ->> 'monto_cuota', e.meta #>> '{payment_plan,monto_por_cuota}', ''), '[^0-9.-]', '', 'g')::numeric
--       else null
--     end as current_monto_cuota,
--     case
--       when regexp_replace(coalesce(e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'colegiatura_anual', e.meta ->> 'colegiatura_anual', e.meta #>> '{payment_plan,monto_total}', ''), '[^0-9.-]', '', 'g') <> ''
--       then regexp_replace(coalesce(e.meta -> 'per_student_economic' -> (es.student_id::text) ->> 'colegiatura_anual', e.meta ->> 'colegiatura_anual', e.meta #>> '{payment_plan,monto_total}', ''), '[^0-9.-]', '', 'g')::numeric
--       else null
--     end as current_total_anual
--   from public.enrollments e
--   join public.enrollment_students es on es.enrollment_id = e.id
--   where e.year = 2026
--     and e.status = 'completed'
-- ), fee_detail as (
--   select
--     f.enrollment_id,
--     f.student_id,
--     case
--       when upper(coalesce(f.payment_method, '')) like '%PAGARE%' then 'PAGARE'
--       when upper(coalesce(f.payment_method, '')) like '%CHEQ%' then 'CHEQUE'
--       when upper(coalesce(f.payment_method, '')) like '%TARJ%' then 'TARJETA'
--       when upper(coalesce(f.payment_method, '')) like '%TRANS%' then 'TRANSFERENCIA'
--       when upper(coalesce(f.payment_method, '')) like '%PLANILL%' then 'PLANILLA'
--       when upper(coalesce(f.payment_method, '')) like '%EFECT%' then 'EFECTIVO'
--       when coalesce(f.payment_method, '') = '' then 'SIN_DATO'
--       else upper(f.payment_method)
--     end as normalized_payment_method,
--     f.amount,
--     f.numero_cuota,
--     f.due_date,
--     f.id
--   from public.fee f
--   where f.year_academico = 2026
-- ), fee_agg as (
--   select
--     fd.enrollment_id,
--     fd.student_id,
--     count(*) as fee_count,
--     string_agg(distinct fd.normalized_payment_method, '|' order by fd.normalized_payment_method) as fee_payment_method,
--     min(fd.amount) as fee_monto_min,
--     max(fd.amount) as fee_monto_max,
--     sum(fd.amount) as fee_total,
--     min(fd.numero_cuota) as fee_min_cuota,
--     max(fd.numero_cuota) as fee_max_cuota,
--     min(fd.due_date) as fee_first_due_date,
--     extract(day from min(fd.due_date))::int as fee_due_day,
--     jsonb_agg(
--       jsonb_build_object(
--         'amount', fd.amount,
--         'numero', fd.numero_cuota,
--         'due_date', to_char(fd.due_date, 'YYYY-MM-DD')
--       )
--       order by fd.numero_cuota nulls last, fd.due_date, fd.id
--     ) as fee_schedule
--   from fee_detail fd
--   group by fd.enrollment_id, fd.student_id
-- ), targets as (
--   select
--     eb.*,
--     coalesce(fa.fee_count, 0) as fee_count,
--     fa.fee_payment_method,
--     fa.fee_monto_min,
--     fa.fee_monto_max,
--     fa.fee_total,
--     fa.fee_min_cuota,
--     fa.fee_max_cuota,
--     fa.fee_first_due_date,
--     fa.fee_due_day,
--     fa.fee_schedule,
--     case when coalesce(fa.fee_count, 0) > 0 then fa.fee_payment_method when eb.current_prioritario then 'PRIORITARIO' else null end as target_payment_method,
--     case when coalesce(fa.fee_count, 0) > 0 then false else eb.current_prioritario end as target_prioritario,
--     case when coalesce(fa.fee_count, 0) > 0 then fa.fee_count else null end as target_cuotas,
--     case when coalesce(fa.fee_count, 0) > 0 and fa.fee_monto_min = fa.fee_monto_max then fa.fee_monto_min else null end as target_monto_cuota,
--     case when coalesce(fa.fee_count, 0) > 0 then fa.fee_total else null end as target_total_anual,
--     case when coalesce(fa.fee_count, 0) > 0 then jsonb_build_object(
--       'cuotas', fa.fee_schedule,
--       'n_cuotas', fa.fee_count,
--       'monto_total', fa.fee_total,
--       'payment_method', fa.fee_payment_method,
--       'dia_vencimiento', fa.fee_due_day,
--       'monto_por_cuota', case when fa.fee_monto_min = fa.fee_monto_max then fa.fee_monto_min else null end,
--       'primer_vencimiento', to_char(fa.fee_first_due_date, 'YYYY-MM-DD')
--     ) else null end as target_payment_plan
--   from enrollment_base eb
--   left join fee_agg fa on fa.enrollment_id = eb.enrollment_id and fa.student_id = eb.student_id
-- ), changes as (
--   select
--     t.*,
--     jsonb_build_object(
--       'payment_method', case
--         when t.fee_count = 0 and t.target_payment_method is null then to_jsonb(''::text)
--         else to_jsonb(t.target_payment_method)
--       end,
--       'prioritario', to_jsonb(t.target_prioritario),
--       'cantidad_cuotas', case
--         when t.fee_count = 0 and t.target_cuotas is null then to_jsonb(''::text)
--         else to_jsonb(t.target_cuotas)
--       end,
--       'monto_cuota', case
--         when t.fee_count = 0 and t.target_monto_cuota is null then to_jsonb(''::text)
--         else to_jsonb(t.target_monto_cuota)
--       end,
--       'colegiatura_anual', case
--         when t.fee_count = 0 and t.target_total_anual is null then to_jsonb(''::text)
--         else to_jsonb(t.target_total_anual)
--       end,
--       'year_academico', to_jsonb(2026),
--       'dia_vencimiento', case
--         when t.fee_count = 0 then to_jsonb(''::text)
--         else to_jsonb(t.fee_due_day)
--       end
--     ) as student_patch,
--     jsonb_build_object(
--       'payment_method', to_jsonb(t.target_payment_method),
--       'prioritario', to_jsonb(t.target_prioritario),
--       'cantidad_cuotas', to_jsonb(t.target_cuotas),
--       'monto_cuota', to_jsonb(t.target_monto_cuota),
--       'colegiatura_anual', to_jsonb(t.target_total_anual),
--       'forma_pago_pagare', to_jsonb(position('PAGARE' in coalesce(t.target_payment_method, '')) > 0),
--       'forma_pago_cheques', to_jsonb(position('CHEQUE' in coalesce(t.target_payment_method, '')) > 0),
--       'forma_pago_tarjeta', to_jsonb(position('TARJETA' in coalesce(t.target_payment_method, '')) > 0),
--       'forma_pago_transferencia', to_jsonb(position('TRANSFERENCIA' in coalesce(t.target_payment_method, '')) > 0),
--       'forma_pago_descuento_planilla', to_jsonb(position('PLANILLA' in coalesce(t.target_payment_method, '')) > 0),
--       'forma_pago_efectivo', to_jsonb(position('EFECTIVO' in coalesce(t.target_payment_method, '')) > 0)
--     ) as root_patch,
--     (
--       t.current_prioritario is distinct from t.target_prioritario
--       or t.current_payment_method is distinct from t.target_payment_method
--       or t.current_cuotas is distinct from t.target_cuotas
--       or t.current_monto_cuota is distinct from t.target_monto_cuota
--       or t.current_total_anual is distinct from t.target_total_anual
--     ) as needs_update
--   from targets t
-- ), root_prepared as (
--   select distinct on (c.enrollment_id)
--     c.enrollment_id,
--     case
--       when c.enrollment_student_count = 1 then jsonb_set(
--         coalesce(c.meta, '{}'::jsonb) || c.root_patch,
--         '{payment_plan}',
--         coalesce(c.target_payment_plan, 'null'::jsonb),
--         true
--       )
--       else coalesce(c.meta, '{}'::jsonb)
--     end as root_synced_meta
--   from changes c
--   where c.needs_update
--   order by c.enrollment_id, c.student_id
-- ), student_objects as (
--   select
--     c.enrollment_id,
--     jsonb_object_agg(
--       c.student_id::text,
--       coalesce(c.meta -> 'per_student_economic' -> (c.student_id::text), '{}'::jsonb)
--         || c.student_patch
--     ) as student_objects
--   from changes c
--   where c.needs_update
--   group by c.enrollment_id
-- ), final_payload as (
--   select
--     rp.enrollment_id,
--     jsonb_set(
--       rp.root_synced_meta,
--       '{per_student_economic}',
--       coalesce(rp.root_synced_meta -> 'per_student_economic', '{}'::jsonb)
--         || so.student_objects,
--       true
--     ) as new_meta
--   from root_prepared rp
--   join student_objects so
--     on so.enrollment_id = rp.enrollment_id
-- )
-- update public.enrollments e
-- set meta = fp.new_meta,
--     updated_at = now()
-- from final_payload fp
-- where e.id = fp.enrollment_id;
-- commit;