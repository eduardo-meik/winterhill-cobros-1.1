with source_rows as (
  select *
  from jsonb_to_recordset('[]'::jsonb) as r(
    run text,
    nombre text,
    student_id uuid,
    owner_id uuid,
    guardian_id uuid,
    enrollment_id uuid,
    metodo_csv text,
    metodo_normalizado text,
    metodo_db text,
    monto_mensual numeric,
    numero_cuotas integer,
    arancel_anual numeric
  )
), fee_rows as (
  select
    student_id,
    owner_id,
    guardian_id,
    enrollment_id,
    metodo_db as payment_method,
    metodo_csv,
    metodo_normalizado,
    monto_mensual as amount,
    cuota_num as numero_cuota,
    (date '2026-03-05' + make_interval(months => cuota_num - 1))::date as due_date
  from source_rows s
  join lateral generate_series(1, s.numero_cuotas) as cuota_num on true
)
insert into public.fee (
  student_id,
  guardian_id,
  amount,
  due_date,
  status,
  payment_method,
  owner_id,
  year_academico,
  numero_cuota,
  enrollment_id,
  meta,
  year
)
select
  student_id,
  guardian_id,
  amount,
  due_date,
  'pending',
  payment_method,
  owner_id,
  2026,
  numero_cuota,
  enrollment_id,
  jsonb_build_object(
    'source', 'update_20260316.csv',
    'sync_reason', 'unexpected_fee_2026_missing_repair',
    'csv_payment_method', metodo_csv,
    'normalized_payment_method', metodo_normalizado
  ),
  2026
from fee_rows
on conflict (student_id, year_academico, numero_cuota) do nothing
returning student_id, numero_cuota;
