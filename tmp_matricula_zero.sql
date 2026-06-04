with target_students as (
  select unnest(array[
    '066d269b-8140-4924-8b28-17e2a66df04b'::uuid,
    '0a48d86e-5c9b-4ed2-b7cd-8e93620bdfd7'::uuid,
    '0c44198f-897e-47e7-b1cc-e8b48d1b7254'::uuid,
    '22ebf090-b81d-4f61-b568-5ef850eb6619'::uuid,
    '2850f8bf-078e-4fa1-a9bf-f59e9833c803'::uuid,
    '2f1db604-3118-49ed-ab11-b153a2e3d73a'::uuid,
    '31c0848b-5e70-4280-8a03-6bf32b8f4a4b'::uuid,
    '32b115bc-8cee-4852-9c2c-3f746158c6ab'::uuid,
    '40812bca-c859-4aab-b744-e017cd94d974'::uuid,
    '427b1b11-f193-488a-8f7d-574d0f6df629'::uuid,
    '45b40cfd-43ba-4a0b-a649-7aab0f238f9d'::uuid,
    '45f59244-633c-43b2-8f5a-8175a6739344'::uuid,
    '4f429179-ca0b-44b8-a3a7-ba86bddbaed6'::uuid,
    '5985d0b9-b7bc-48dc-a000-673cc9153aca'::uuid,
    '5a907b42-8a3a-4742-9aa1-4b02b6884045'::uuid,
    '5d5e7d9b-1b8d-437c-8b2b-b9086a792204'::uuid,
    '604757cf-8b2e-4987-a1f9-5b8630e35eac'::uuid,
    '606d5d10-c396-44c3-83a8-742ecddd2ab2'::uuid,
    '613cc43a-5a69-4136-a98f-6813c7186388'::uuid,
    '62f74768-3ff8-4f19-832a-ccec00dbe002'::uuid,
    '64153345-58a7-4027-95c7-2ba709e62461'::uuid,
    '6812c399-a2ac-4f08-9a56-289848c655be'::uuid,
    '69b0d056-1e58-4720-916b-2332ba9f40b4'::uuid,
    '75cba1fd-3b59-4075-bd4d-4a5bad72fe80'::uuid,
    '7bdeb573-3d3d-4111-a03e-21630f6f8d03'::uuid,
    '8100f568-89d1-4330-acb0-5ead711d631d'::uuid,
    '83e031f7-5fae-4c1b-b562-a4a421f352d9'::uuid,
    '84ff81f8-d76e-490e-9b85-07f1113a121f'::uuid,
    '85751556-bf33-4844-8163-8bfd1b16bed2'::uuid,
    '8c1720af-0184-4685-bf42-6c7b45b6ae9e'::uuid,
    '9d83a1dc-cc91-4240-a6c7-045fd31f0a5f'::uuid,
    'a23b162c-a255-4e48-a5a5-8a7fcacece00'::uuid,
    'b25243bb-c96f-4de3-8806-05d1384f0e02'::uuid,
    'b5d2d7d9-06df-46d0-91a1-d10d0ccd68f1'::uuid,
    'b67fb8bd-6073-4cdd-8b96-97e6b9002109'::uuid,
    'b7a68463-1fb5-4631-b37f-2d9229ac31c3'::uuid,
    'b8f0650c-711e-4fa5-a0f2-2ccc64d87296'::uuid,
    'b994c186-9b36-490b-a2df-027a168c9e1d'::uuid,
    'bb2c6214-6875-424e-b6e2-8023f48e36c5'::uuid,
    'bda681e7-4506-4a87-8fd7-27861a23b044'::uuid,
    'bf024ee2-4e96-4c70-97c3-584d5669ddb1'::uuid,
    'c74a4818-aba2-4d58-9bf3-24306841c153'::uuid,
    'cb22756d-b14c-4828-ad6e-1d440b43cfc8'::uuid,
    'cd235a94-9927-4ce7-811f-deb993f6800b'::uuid,
    'd5a8d4b2-9430-4ac2-9ed8-4bcf5c578219'::uuid,
    'd6f5ae44-61cd-4a2b-9d7a-1f3b059651b9'::uuid,
    'd746d6cc-a5d6-452a-bcce-6c076d957938'::uuid,
    'ddddd93b-730a-4d20-b3b7-34cc53ed591f'::uuid,
    'dfb5dd30-be80-4b9d-b755-8348b0581a0d'::uuid,
    'ec5a30f5-0787-4d8e-885a-53cc5b20fd0c'::uuid,
    'f42a98fd-f5f3-481f-ad1f-9d5e10d9935a'::uuid,
    'f58fe5ef-4868-4203-9c67-f890f3ffd43c'::uuid,
    'fbb97d70-5ca2-4ffb-8e58-66ff3f9a7cfc'::uuid
  ]) as student_id
), patched as (
  select
    e.id as enrollment_id,
    s.id as student_id,
    s.id::text as student_key,
    coalesce(e.meta, '{}'::jsonb) as current_meta,
    coalesce(e.meta -> 'per_student_economic' -> (s.id::text), '{}'::jsonb) as current_student_economic,
    (
      select '[]'::jsonb
    ) as cuotas_plan,
    count(es2.student_id) over (partition by e.id) as student_count
  from target_students ts
  join public.students s on s.id = ts.student_id
  join public.enrollment_students es on es.student_id = s.id
  join public.enrollments e on e.id = es.enrollment_id and e.year = 2026
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
                            p.current_meta,
                            array['per_student_economic', p.student_key],
                            p.current_student_economic || jsonb_build_object(
                              'payment_method', 'PRIORITARIO',
                              'prioritario', true,
                              'cantidad_cuotas', 0,
                              'monto_cuota', 0,
                              'colegiatura_anual', 0,
                              'year_academico', 2026,
                              'dia_vencimiento', 5
                            ),
                            true
                          ),
                          array['per_student_plans', p.student_key],
                          jsonb_build_object(
                            'cuotas', '[]'::jsonb,
                            'n_cuotas', 0,
                            'monto_total', 0,
                            'payment_method', null,
                            'dia_vencimiento', 5,
                            'monto_por_cuota', 0,
                            'primer_vencimiento', '2026-03-05'
                          ),
                          true
                        ),
                        array['payment_method'], to_jsonb('PRIORITARIO'::text), true
                      ),
                      array['prioritario'], to_jsonb(true), true
                    ),
                    array['cantidad_cuotas'], to_jsonb(0), true
                  ),
                  array['monto_cuota'], to_jsonb(0), true
                ),
                array['colegiatura_anual'], to_jsonb(0), true
              ),
              array['payment_plan'], jsonb_build_object(
                'cuotas', '[]'::jsonb,
                'n_cuotas', 0,
                'monto_total', 0,
                'payment_method', null,
                'dia_vencimiento', 5,
                'monto_por_cuota', 0,
                'primer_vencimiento', '2026-03-05'
              ), true
            ),
            array['forma_pago_pagare'], to_jsonb(false), true
          ),
          array['forma_pago_cheques'], to_jsonb(false), true
        ),
        array['forma_pago_transferencia'], to_jsonb(false), true
      )
    else
      jsonb_set(
        jsonb_set(
          p.current_meta,
          array['per_student_economic', p.student_key],
          p.current_student_economic || jsonb_build_object(
            'payment_method', 'PRIORITARIO',
            'prioritario', true,
            'cantidad_cuotas', 0,
            'monto_cuota', 0,
            'colegiatura_anual', 0,
            'year_academico', 2026,
            'dia_vencimiento', 5
          ),
          true
        ),
        array['per_student_plans', p.student_key],
        jsonb_build_object(
          'cuotas', '[]'::jsonb,
          'n_cuotas', 0,
          'monto_total', 0,
          'payment_method', null,
          'dia_vencimiento', 5,
          'monto_por_cuota', 0,
          'primer_vencimiento', '2026-03-05'
        ),
        true
      )
  end,
  updated_at = now()
from patched p
where e.id = p.enrollment_id;