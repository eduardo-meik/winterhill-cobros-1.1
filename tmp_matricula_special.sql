with src(enrollment_id, student_id, payment_method, prioritario, cuotas, monto_cuota, total_anual) as (
  values
  ('5ad7dbf2-7183-4c93-a9ad-d700bed09ef7'::uuid, '3317705f-7dd3-49ca-b547-21b3155fd611'::uuid, 'PAGARE', false, 10, 102870, 1028700),
  ('e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '3ae7a468-3363-4790-9ea5-62cd39ab111f'::uuid, 'CHEQUE', false, 10, 102870, 1028700),
  ('68178644-172b-4e34-9d03-d86125492c65'::uuid, '4c57b31c-4a96-4ac5-88ff-cdb827f4d862'::uuid, 'PAGARE', false, 10, 190180, 1331260),
  ('6599447f-fd35-4d28-99dd-888c99ee2a62'::uuid, '5945ab89-9c94-4cd6-95ab-5a5767d2bb47'::uuid, 'CHEQUE', false, 10, 133126, 1331260),
  ('9755e5d1-e54f-4443-884b-721219622d77'::uuid, '66bf4d83-cb55-4acc-8658-c714f82c5f0e'::uuid, 'CHEQUE', false, 10, 332815, 1331260),
  ('23de1816-62e8-4509-9a66-29b80dbe43b6'::uuid, '6952432f-f7ab-4774-9ef6-1d9d050f1892'::uuid, 'PAGARE', false, 10, 102870, 1028700),
  ('124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '6c1e2c95-9d30-4eba-a4bc-a3dd5454bb17'::uuid, 'CHEQUE', false, 10, 147918, 1331260),
  ('89c47263-df33-49ce-9bbf-10dcf4d19c00'::uuid, '74b29b66-f821-468f-8308-a41f213dcf58'::uuid, 'PAGARE', false, 10, 102870, 1028700),
  ('138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '76efd3a1-8586-46f6-ab08-96ba11ef3334'::uuid, 'CHEQUE', false, 10, 102870, 1028700),
  ('794a4776-1e12-40c8-b8d6-1e8f0441ed45'::uuid, '77e94297-b89a-4d0d-829e-8aa373449d14'::uuid, 'CHEQUE', false, 10, 133126, 1331260),
  ('1715e001-1157-403f-8e86-66e7d5dd97c2'::uuid, '97e49951-e13c-4438-856b-5a9b6db38602'::uuid, 'PAGARE', false, 10, 102870, 1028700),
  ('fba5295b-2960-4398-8ed7-ac1f6ab0cedb'::uuid, 'b4719a36-da47-4bbd-9950-8755d3c195b7'::uuid, 'PAGARE', false, 10, 114300, 1028700),
  ('07aa90fc-9a60-4de1-a1b8-1636d9d8c06c'::uuid, 'ff66c43d-8f12-4921-aa9d-5a306a9234e6'::uuid, 'PAGARE', false, 10, 102870, 1028700)
), prepared as (
  select
    src.*, src.student_id::text as student_key,
    coalesce(e.meta, '{}'::jsonb) as current_meta,
    coalesce(e.meta -> 'per_student_economic' -> (src.student_id::text), '{}'::jsonb) as current_student_economic,
    count(es2.student_id) over (partition by e.id) as student_count,
    (
      select coalesce(jsonb_agg(jsonb_build_object('numero', gs, 'amount', src.monto_cuota, 'due_date', (date '2026-03-05' + make_interval(months => gs - 1))::date) order by gs), '[]'::jsonb)
      from generate_series(1, greatest(src.cuotas, 0)) gs
    ) as cuotas_plan
  from src
  join public.enrollments e on e.id = src.enrollment_id and e.year = 2026
  join public.enrollment_students es2 on es2.enrollment_id = e.id
)
update public.enrollments e
set meta = case
    when p.student_count = 1 then
      jsonb_set(
        jsonb_set(
          jsonb_set(
            jsonb_set(
              jsonb_set(
                jsonb_set(
                  jsonb_set(
                    jsonb_set(
                      jsonb_set(
                        jsonb_set(
                          jsonb_set(
                            jsonb_set(
                              p.current_meta,
                              array['per_student_economic', p.student_key],
                              p.current_student_economic || jsonb_build_object(
                                'payment_method', p.payment_method,
                                'prioritario', p.prioritario,
                                'cantidad_cuotas', p.cuotas,
                                'monto_cuota', p.monto_cuota,
                                'colegiatura_anual', p.total_anual,
                                'year_academico', 2026,
                                'dia_vencimiento', 5
                              ),
                              true
                            ),
                            array['per_student_plans', p.student_key],
                            jsonb_build_object(
                              'cuotas', p.cuotas_plan,
                              'n_cuotas', p.cuotas,
                              'monto_total', p.total_anual,
                              'payment_method', case when p.prioritario then null else p.payment_method end,
                              'dia_vencimiento', 5,
                              'monto_por_cuota', p.monto_cuota,
                              'primer_vencimiento', '2026-03-05'
                            ),
                            true
                          ),
                          array['payment_method'], to_jsonb(p.payment_method), true
                        ),
                        array['prioritario'], to_jsonb(p.prioritario), true
                      ),
                      array['cantidad_cuotas'], to_jsonb(p.cuotas), true
                    ),
                    array['monto_cuota'], to_jsonb(p.monto_cuota), true
                  ),
                  array['colegiatura_anual'], to_jsonb(p.total_anual), true
                ),
                array['payment_plan'], jsonb_build_object(
                  'cuotas', p.cuotas_plan,
                  'n_cuotas', p.cuotas,
                  'monto_total', p.total_anual,
                  'payment_method', case when p.prioritario then null else p.payment_method end,
                  'dia_vencimiento', 5,
                  'monto_por_cuota', p.monto_cuota,
                  'primer_vencimiento', '2026-03-05'
                ), true
              ),
              array['forma_pago_pagare'], to_jsonb(p.payment_method = 'PAGARE'), true
            ),
            array['forma_pago_cheques'], to_jsonb(p.payment_method = 'CHEQUE'), true
          ),
          array['forma_pago_transferencia'], to_jsonb(p.payment_method = 'TRANSFERENCIA'), true
        ),
        array['forma_pago_descuento_planilla'], to_jsonb(p.payment_method = 'PLANILLA'), true
      )
    else
      jsonb_set(
        jsonb_set(
          p.current_meta,
          array['per_student_economic', p.student_key],
          p.current_student_economic || jsonb_build_object(
            'payment_method', p.payment_method,
            'prioritario', p.prioritario,
            'cantidad_cuotas', p.cuotas,
            'monto_cuota', p.monto_cuota,
            'colegiatura_anual', p.total_anual,
            'year_academico', 2026,
            'dia_vencimiento', 5
          ), true
        ),
        array['per_student_plans', p.student_key],
        jsonb_build_object(
          'cuotas', p.cuotas_plan,
          'n_cuotas', p.cuotas,
          'monto_total', p.total_anual,
          'payment_method', case when p.prioritario then null else p.payment_method end,
          'dia_vencimiento', 5,
          'monto_por_cuota', p.monto_cuota,
          'primer_vencimiento', '2026-03-05'
        ), true
      )
  end,
  updated_at = now()
from prepared p
where e.id = p.enrollment_id;