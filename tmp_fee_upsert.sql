with src(enrollment_id, student_id, target_fee_count, payment_method, amount, total_amount, min_installment, max_installment) as (
  values
  ('f1b103fb-4400-471f-8d2a-4dd789326207'::uuid, '04e6c1a6-e72c-4ccc-aa13-9e900fa3be97'::uuid, 10, 'PAGARE', 102870.00, 1028700.00, 1, 10),
  ('fa19b9ee-9765-487f-b052-b96d8ca2828f'::uuid, '08b2dd2d-0739-46fc-8a4d-19e9013ca0de'::uuid, 10, 'CHEQUE', 102870.00, 1028700.00, 1, 10),
  ('5ad7dbf2-7183-4c93-a9ad-d700bed09ef7'::uuid, '3317705f-7dd3-49ca-b547-21b3155fd611'::uuid, 10, 'PAGARE', 99324.00, 993240.00, 1, 10),
  ('9abd66dc-36cb-42e9-a24e-c7224e8d0951'::uuid, '3a283002-2d43-4568-bd8c-d0fa2463cc81'::uuid, 10, 'PAGARE', 102870.00, 1028700.00, 1, 10),
  ('7de67eb0-a861-4879-95eb-d5ef4246d8cc'::uuid, '55e0c792-a2b9-4712-a4d7-a4ae4cd2d4d4'::uuid, 10, 'PAGARE', 102870.00, 1028700.00, 1, 10),
  ('b64ea244-c5f3-4b3e-a585-d8bb7f2ba257'::uuid, '65189315-ca98-4cb3-b9d6-8ff2eb8e80e1'::uuid, 10, 'PAGARE', 102870.00, 1028700.00, 1, 10),
  ('e47e19b6-75ea-4ff6-9d8d-40a97e56b53a'::uuid, '67bc9321-1484-4d62-b46f-5ab24648d0db'::uuid, 10, 'PAGARE', 102870.00, 1028700.00, 1, 10),
  ('23de1816-62e8-4509-9a66-29b80dbe43b6'::uuid, '6952432f-f7ab-4774-9ef6-1d9d050f1892'::uuid, 10, 'PAGARE', 102870, 1028700, 1, 10),
  ('89c47263-df33-49ce-9bbf-10dcf4d19c00'::uuid, '74b29b66-f821-468f-8308-a41f213dcf58'::uuid, 10, 'PAGARE', 102870, 1028700, 1, 10),
  ('9d5d6220-74d6-4fc6-9a8a-242f6d65d0dd'::uuid, '8131019a-9414-471a-95d2-65087f949cb7'::uuid, 10, 'PAGARE', 133126.00, 1331260.00, 1, 10),
  ('cfde4fbb-f707-414d-b112-e8b6979c390f'::uuid, '94c70054-2428-4e84-9a84-bbafb3171e51'::uuid, 10, 'PAGARE', 133126.00, 1331260.00, 1, 10),
  ('7f9d1595-3c22-4df7-bd43-e2994acc205f'::uuid, '9ce9f734-8aa7-4440-81b8-ba98466f14df'::uuid, 10, 'PAGARE', 102870.00, 1028700.00, 1, 10),
  ('a0999f25-89ae-40ca-b77d-b9d9b73009af'::uuid, 'ae3988c6-e33a-4cd2-acd8-a47898445e59'::uuid, 10, 'PAGARE', 79876.00, 798760.00, 1, 10),
  ('0df0822d-53aa-456d-8677-0a12b5e29895'::uuid, 'd29967d7-ddaf-46e9-9e51-9e3e98c18d63'::uuid, 10, 'PAGARE', 102870.00, 1028700.00, 1, 10),
  ('d407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, 'e0bf1072-fbec-4732-aa38-4b892db92a9f'::uuid, 10, 'CHEQUE', 133126.00, 1331260.00, 1, 10),
  ('f972167c-5003-4247-b8be-0a89536b6d51'::uuid, 'e0fb9baf-658b-402f-8443-2fb6f0484458'::uuid, 10, 'PAGARE', 102870.00, 1028700.00, 1, 10),
  ('80a6e309-c49e-436f-ac1d-d63b45ced2ee'::uuid, 'fb2b948d-6e42-4ce8-9034-c2991c3d3145'::uuid, 10, 'PAGARE', 133126.00, 1331260.00, 1, 10),
  ('f160be4e-e9a9-48e8-87f6-903cf8e57ca1'::uuid, 'feb6954d-6ad9-4ab7-b2c9-e8fd2d5297f2'::uuid, 10, 'PAGARE', 82296.00, 822960.00, 1, 10),
  ('07aa90fc-9a60-4de1-a1b8-1636d9d8c06c'::uuid, 'ff66c43d-8f12-4921-aa9d-5a306a9234e6'::uuid, 10, 'PAGARE', 102870.00, 1028700.00, 1, 10)
), desired_rows as (
  select
    src.student_id,
    e.guardian_id,
    s.owner_id,
    s.curso as fee_curso,
    src.enrollment_id,
    src.payment_method,
    src.amount,
    gs as numero_cuota,
    (date '2026-03-05' + make_interval(months => gs - 1))::date as due_date
  from src
  join public.enrollments e on e.id = src.enrollment_id and e.year = 2026
  join public.students s on s.id = src.student_id
  join lateral generate_series(src.min_installment, src.max_installment) gs on true
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
  year,
  fee_curso
)
select
  dr.student_id,
  dr.guardian_id,
  dr.amount,
  dr.due_date,
  'pending',
  dr.payment_method,
  dr.owner_id,
  2026,
  dr.numero_cuota,
  dr.enrollment_id,
  jsonb_build_object(
    'source', 'reporte_matriculados_forma_pago_vs_aranceles_2026_20260408 copy.csv',
    'sync_reason', 'csv_review_sync_2026_04_10'
  ),
  2026,
  dr.fee_curso
from desired_rows dr
on conflict (student_id, year_academico, numero_cuota)
do update set
  guardian_id = excluded.guardian_id,
  amount = excluded.amount,
  payment_method = excluded.payment_method,
  owner_id = excluded.owner_id,
  enrollment_id = excluded.enrollment_id,
  year = excluded.year,
  year_academico = excluded.year_academico,
  fee_curso = excluded.fee_curso,
  due_date = coalesce(public.fee.due_date, excluded.due_date),
  meta = coalesce(public.fee.meta, '{}'::jsonb) || excluded.meta;