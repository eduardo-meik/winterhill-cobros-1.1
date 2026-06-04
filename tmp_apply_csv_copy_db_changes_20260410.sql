
begin;

with
matricula_src as (
  select *
  from jsonb_to_recordset('[{"enrollment_id": "8e1acbd6-5724-4d81-a55a-b6639b59afde", "student_id": "066d269b-8140-4924-8b28-17e2a66df04b", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "c8da3e53-9681-4431-9e56-2928e28de03f", "student_id": "0a48d86e-5c9b-4ed2-b7cd-8e93620bdfd7", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "895d5a6b-18af-46e8-81b0-ceb746e8f6ee", "student_id": "0c44198f-897e-47e7-b1cc-e8b48d1b7254", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "5e356055-b05c-4672-b660-a215c2ac4c87", "student_id": "22ebf090-b81d-4f61-b568-5ef850eb6619", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "34118f30-b3a2-4d23-88d9-37dbef6d2196", "student_id": "2850f8bf-078e-4fa1-a9bf-f59e9833c803", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "c35c3982-2596-45f5-ae24-686b49a54215", "student_id": "2f1db604-3118-49ed-ab11-b153a2e3d73a", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "ea6fbecb-6060-4a40-9fee-8f491472af35", "student_id": "31c0848b-5e70-4280-8a03-6bf32b8f4a4b", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "b846c3f7-ab7a-4690-bfd1-be5940201540", "student_id": "32b115bc-8cee-4852-9c2c-3f746158c6ab", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "5ad7dbf2-7183-4c93-a9ad-d700bed09ef7", "student_id": "3317705f-7dd3-49ca-b547-21b3155fd611", "payment_method": "PAGARE", "prioritario": "false", "cuotas": "10", "monto_cuota": "102870", "total_anual": "1028700"}, {"enrollment_id": "e23eab60-d5cd-49e5-90a8-189104140ce8", "student_id": "3ae7a468-3363-4790-9ea5-62cd39ab111f", "payment_method": "CHEQUE", "prioritario": "false", "cuotas": "10", "monto_cuota": "102870", "total_anual": "1028700"}, {"enrollment_id": "fe495910-415b-4b30-bd6f-c8c216c6a800", "student_id": "40812bca-c859-4aab-b744-e017cd94d974", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "a12147cc-036e-439a-9889-cdf81549e11f", "student_id": "427b1b11-f193-488a-8f7d-574d0f6df629", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "b586387a-9d35-40d6-8970-8310b2aafa5a", "student_id": "45b40cfd-43ba-4a0b-a649-7aab0f238f9d", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "2ae46f37-efda-4d26-b15b-358f464399ed", "student_id": "45f59244-633c-43b2-8f5a-8175a6739344", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "68178644-172b-4e34-9d03-d86125492c65", "student_id": "4c57b31c-4a96-4ac5-88ff-cdb827f4d862", "payment_method": "PAGARE", "prioritario": "false", "cuotas": "10", "monto_cuota": "190180", "total_anual": "1331260"}, {"enrollment_id": "24c92476-89fc-4290-b19e-5e262199afaa", "student_id": "4f429179-ca0b-44b8-a3a7-ba86bddbaed6", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "6599447f-fd35-4d28-99dd-888c99ee2a62", "student_id": "5945ab89-9c94-4cd6-95ab-5a5767d2bb47", "payment_method": "CHEQUE", "prioritario": "false", "cuotas": "10", "monto_cuota": "133126", "total_anual": "1331260"}, {"enrollment_id": "03c2d150-7804-4e2c-8b8b-32c724079322", "student_id": "5985d0b9-b7bc-48dc-a000-673cc9153aca", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "b586387a-9d35-40d6-8970-8310b2aafa5a", "student_id": "5a907b42-8a3a-4742-9aa1-4b02b6884045", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "c2a56cdf-8ad5-4325-8012-47f7aa2073fb", "student_id": "5d5e7d9b-1b8d-437c-8b2b-b9086a792204", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "2107a703-4075-49a0-918d-4040d5ea1b6a", "student_id": "604757cf-8b2e-4987-a1f9-5b8630e35eac", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "3e57ec66-5ee7-4dfa-91a0-66fe97c6fc26", "student_id": "606d5d10-c396-44c3-83a8-742ecddd2ab2", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "c4163e74-9c69-46d5-915d-020594e3dee3", "student_id": "613cc43a-5a69-4136-a98f-6813c7186388", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "a1a8a8f8-6297-46d1-849c-9d55ff0bc72f", "student_id": "62f74768-3ff8-4f19-832a-ccec00dbe002", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "d3b3e55f-9d8f-4bb6-bd48-8e2a4a2994a9", "student_id": "64153345-58a7-4027-95c7-2ba709e62461", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "9755e5d1-e54f-4443-884b-721219622d77", "student_id": "66bf4d83-cb55-4acc-8658-c714f82c5f0e", "payment_method": "CHEQUE", "prioritario": "false", "cuotas": "10", "monto_cuota": "332815", "total_anual": "1331260"}, {"enrollment_id": "006f2777-5517-42b1-82c3-a540b07125bb", "student_id": "6812c399-a2ac-4f08-9a56-289848c655be", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "23de1816-62e8-4509-9a66-29b80dbe43b6", "student_id": "6952432f-f7ab-4774-9ef6-1d9d050f1892", "payment_method": "PAGARE", "prioritario": "false", "cuotas": "10", "monto_cuota": "102870", "total_anual": "1028700"}, {"enrollment_id": "5386679e-ec03-45fe-bf3b-f8ec1e16142d", "student_id": "69b0d056-1e58-4720-916b-2332ba9f40b4", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "124f2fcb-ee42-47a1-8e52-180919137c32", "student_id": "6c1e2c95-9d30-4eba-a4bc-a3dd5454bb17", "payment_method": "CHEQUE", "prioritario": "false", "cuotas": "10", "monto_cuota": "147918", "total_anual": "1331260"}, {"enrollment_id": "89c47263-df33-49ce-9bbf-10dcf4d19c00", "student_id": "74b29b66-f821-468f-8308-a41f213dcf58", "payment_method": "PAGARE", "prioritario": "false", "cuotas": "10", "monto_cuota": "102870", "total_anual": "1028700"}, {"enrollment_id": "3fe16a66-d78e-48cf-82e3-ab2bf9cf974d", "student_id": "75cba1fd-3b59-4075-bd4d-4a5bad72fe80", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "138f0e5e-6d4d-4ff9-8f06-603cea01c9cc", "student_id": "76efd3a1-8586-46f6-ab08-96ba11ef3334", "payment_method": "CHEQUE", "prioritario": "false", "cuotas": "10", "monto_cuota": "102870", "total_anual": "1028700"}, {"enrollment_id": "794a4776-1e12-40c8-b8d6-1e8f0441ed45", "student_id": "77e94297-b89a-4d0d-829e-8aa373449d14", "payment_method": "CHEQUE", "prioritario": "false", "cuotas": "10", "monto_cuota": "133126", "total_anual": "1331260"}, {"enrollment_id": "41450c85-801e-4653-b45f-70f60e81a196", "student_id": "7bdeb573-3d3d-4111-a03e-21630f6f8d03", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "275d41c7-1374-4d16-a443-4fb524bb4038", "student_id": "8100f568-89d1-4330-acb0-5ead711d631d", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "24c92476-89fc-4290-b19e-5e262199afaa", "student_id": "83e031f7-5fae-4c1b-b562-a4a421f352d9", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "b171da6b-c788-4602-96d7-c344ffc3881c", "student_id": "84ff81f8-d76e-490e-9b85-07f1113a121f", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "a74a6cdb-0b24-43eb-9adf-07134a540215", "student_id": "85751556-bf33-4844-8163-8bfd1b16bed2", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "0e5db320-9da9-44dd-86ae-ff5e2645678f", "student_id": "8c1720af-0184-4685-bf42-6c7b45b6ae9e", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "1715e001-1157-403f-8e86-66e7d5dd97c2", "student_id": "97e49951-e13c-4438-856b-5a9b6db38602", "payment_method": "PAGARE", "prioritario": "false", "cuotas": "10", "monto_cuota": "102870", "total_anual": "1028700"}, {"enrollment_id": "cfa40848-ee92-49f9-b83e-cb2abbf49368", "student_id": "9d83a1dc-cc91-4240-a6c7-045fd31f0a5f", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "f95055bd-fcae-4262-872f-47646d335b17", "student_id": "a23b162c-a255-4e48-a5a5-8a7fcacece00", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "244627ae-109c-43bd-ab01-b1a0774bb2d0", "student_id": "b25243bb-c96f-4de3-8806-05d1384f0e02", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "fba5295b-2960-4398-8ed7-ac1f6ab0cedb", "student_id": "b4719a36-da47-4bbd-9950-8755d3c195b7", "payment_method": "PAGARE", "prioritario": "false", "cuotas": "10", "monto_cuota": "114300", "total_anual": "1028700"}, {"enrollment_id": "bc34f1a8-93f6-4b30-b3b1-71eef095623c", "student_id": "b5d2d7d9-06df-46d0-91a1-d10d0ccd68f1", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "fa155b05-32b5-445b-8d76-e1539110ed42", "student_id": "b67fb8bd-6073-4cdd-8b96-97e6b9002109", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "48a3588a-8964-410b-8e71-6d36b2968613", "student_id": "b7a68463-1fb5-4631-b37f-2d9229ac31c3", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "37725c84-7cca-48ff-9c28-bea450663896", "student_id": "b8f0650c-711e-4fa5-a0f2-2ccc64d87296", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "0a00ccdb-b23f-4857-90a2-f99e45c0775b", "student_id": "b994c186-9b36-490b-a2df-027a168c9e1d", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "c4163e74-9c69-46d5-915d-020594e3dee3", "student_id": "bb2c6214-6875-424e-b6e2-8023f48e36c5", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "77f0d028-5097-48c6-a9d7-2466e1ec30b2", "student_id": "bda681e7-4506-4a87-8fd7-27861a23b044", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "fe495910-415b-4b30-bd6f-c8c216c6a800", "student_id": "bf024ee2-4e96-4c70-97c3-584d5669ddb1", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "24c92476-89fc-4290-b19e-5e262199afaa", "student_id": "c74a4818-aba2-4d58-9bf3-24306841c153", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "2698b4a9-f2da-4096-8358-6a981f63ff2a", "student_id": "cb22756d-b14c-4828-ad6e-1d440b43cfc8", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "ac5b950a-b352-4c70-b508-a4faf7d36b6c", "student_id": "cd235a94-9927-4ce7-811f-deb993f6800b", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "2698b4a9-f2da-4096-8358-6a981f63ff2a", "student_id": "d5a8d4b2-9430-4ac2-9ed8-4bcf5c578219", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "ac46eeca-3202-446a-a6fc-13b1b8b1bd07", "student_id": "d6f5ae44-61cd-4a2b-9d7a-1f3b059651b9", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "39d6b297-fadd-48f4-8026-1778c1e875b5", "student_id": "d746d6cc-a5d6-452a-bcce-6c076d957938", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "1e9bd4aa-286c-4582-9e26-ec5e6c25e31b", "student_id": "ddddd93b-730a-4d20-b3b7-34cc53ed591f", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "b90b828b-bc69-4911-b68d-5d447914e0ea", "student_id": "dfb5dd30-be80-4b9d-b755-8348b0581a0d", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "da85bd5c-2fff-41c9-aaee-a986a3543374", "student_id": "ec5a30f5-0787-4d8e-885a-53cc5b20fd0c", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "2107a703-4075-49a0-918d-4040d5ea1b6a", "student_id": "f42a98fd-f5f3-481f-ad1f-9d5e10d9935a", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "81a62c92-0b2b-47c3-a1c1-125a71194e80", "student_id": "f58fe5ef-4868-4203-9c67-f890f3ffd43c", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "a1468139-53fd-4677-8f72-267c998eea43", "student_id": "fbb97d70-5ca2-4ffb-8e58-66ff3f9a7cfc", "payment_method": "PRIORITARIO", "prioritario": "true", "cuotas": "0", "monto_cuota": "0", "total_anual": "0"}, {"enrollment_id": "07aa90fc-9a60-4de1-a1b8-1636d9d8c06c", "student_id": "ff66c43d-8f12-4921-aa9d-5a306a9234e6", "payment_method": "PAGARE", "prioritario": "true", "cuotas": "10", "monto_cuota": "102870", "total_anual": "1028700"}]'::jsonb) as s(
    enrollment_id uuid,
    student_id uuid,
    payment_method text,
    prioritario text,
    cuotas text,
    monto_cuota text,
    total_anual text
  )
),
matricula_norm as (
  select
    enrollment_id,
    student_id,
    student_id::text as student_key,
    upper(nullif(trim(payment_method), '')) as payment_method,
    upper(nullif(trim(payment_method), '')) = 'PRIORITARIO' as prioritario,
    case when nullif(trim(coalesce(cuotas, '')), '') is null then null else trim(cuotas)::int end as cuotas,
    case when nullif(trim(coalesce(monto_cuota, '')), '') is null then null else trim(monto_cuota)::numeric end as monto_cuota,
    case when nullif(trim(coalesce(total_anual, '')), '') is null then null else trim(total_anual)::numeric end as total_anual
  from matricula_src
),
enrollment_counts as (
  select enrollment_id, count(*) as student_count
  from public.enrollment_students
  group by enrollment_id
),
matricula_prepared as (
  select
    m.*, 
    ec.student_count,
    coalesce(e.meta, '{}'::jsonb) as current_meta,
    coalesce(e.meta -> 'per_student_economic' -> m.student_key, '{}'::jsonb) as current_student_economic,
    (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'numero', gs,
            'amount', coalesce(m.monto_cuota, 0),
            'due_date', (date '2026-03-05' + make_interval(months => gs - 1))::date
          ) order by gs
        ),
        '[]'::jsonb
      )
      from generate_series(1, greatest(coalesce(m.cuotas, 0), 0)) as gs
    ) as cuotas_plan
  from matricula_norm m
  join public.enrollments e on e.id = m.enrollment_id and e.year = 2026
  left join enrollment_counts ec on ec.enrollment_id = m.enrollment_id
),
matricula_patched as (
  select
    mp.enrollment_id,
    mp.student_id,
    case
      when coalesce(mp.student_count, 0) = 1 then
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
                                jsonb_set(
                                  mp.current_meta,
                                  array['per_student_economic', mp.student_key],
                                  mp.current_student_economic || jsonb_build_object(
                                    'payment_method', mp.payment_method,
                                    'prioritario', mp.prioritario,
                                    'cantidad_cuotas', coalesce(mp.cuotas, 0),
                                    'monto_cuota', coalesce(mp.monto_cuota, 0),
                                    'colegiatura_anual', coalesce(mp.total_anual, 0),
                                    'year_academico', 2026,
                                    'dia_vencimiento', 5
                                  ),
                                  true
                                ),
                                array['per_student_plans', mp.student_key],
                                jsonb_build_object(
                                  'cuotas', mp.cuotas_plan,
                                  'n_cuotas', coalesce(mp.cuotas, 0),
                                  'monto_total', coalesce(mp.total_anual, 0),
                                  'payment_method', case when mp.prioritario then null else mp.payment_method end,
                                  'dia_vencimiento', 5,
                                  'monto_por_cuota', coalesce(mp.monto_cuota, 0),
                                  'primer_vencimiento', '2026-03-05'
                                ),
                                true
                              ),
                              array['payment_method'],
                              to_jsonb(mp.payment_method),
                              true
                            ),
                            array['prioritario'],
                            to_jsonb(mp.prioritario),
                            true
                          ),
                          array['cantidad_cuotas'],
                          to_jsonb(coalesce(mp.cuotas, 0)),
                          true
                        ),
                        array['monto_cuota'],
                        to_jsonb(coalesce(mp.monto_cuota, 0)),
                        true
                      ),
                      array['colegiatura_anual'],
                      to_jsonb(coalesce(mp.total_anual, 0)),
                      true
                    ),
                    array['payment_plan'],
                    jsonb_build_object(
                      'cuotas', mp.cuotas_plan,
                      'n_cuotas', coalesce(mp.cuotas, 0),
                      'monto_total', coalesce(mp.total_anual, 0),
                      'payment_method', case when mp.prioritario then null else mp.payment_method end,
                      'dia_vencimiento', 5,
                      'monto_por_cuota', coalesce(mp.monto_cuota, 0),
                      'primer_vencimiento', '2026-03-05'
                    ),
                    true
                  ),
                  array['forma_pago_pagare'],
                  to_jsonb(mp.payment_method = 'PAGARE'),
                  true
                ),
                array['forma_pago_cheques'],
                to_jsonb(mp.payment_method = 'CHEQUE'),
                true
              ),
              array['forma_pago_tarjeta'],
              to_jsonb(mp.payment_method = 'TARJETA'),
              true
            ),
            array['forma_pago_transferencia'],
            to_jsonb(mp.payment_method = 'TRANSFERENCIA'),
            true
          ),
          array['forma_pago_descuento_planilla'],
          to_jsonb(mp.payment_method = 'PLANILLA'),
          true
        )
      else
        jsonb_set(
          jsonb_set(
            mp.current_meta,
            array['per_student_economic', mp.student_key],
            mp.current_student_economic || jsonb_build_object(
              'payment_method', mp.payment_method,
              'prioritario', mp.prioritario,
              'cantidad_cuotas', coalesce(mp.cuotas, 0),
              'monto_cuota', coalesce(mp.monto_cuota, 0),
              'colegiatura_anual', coalesce(mp.total_anual, 0),
              'year_academico', 2026,
              'dia_vencimiento', 5
            ),
            true
          ),
          array['per_student_plans', mp.student_key],
          jsonb_build_object(
            'cuotas', mp.cuotas_plan,
            'n_cuotas', coalesce(mp.cuotas, 0),
            'monto_total', coalesce(mp.total_anual, 0),
            'payment_method', case when mp.prioritario then null else mp.payment_method end,
            'dia_vencimiento', 5,
            'monto_por_cuota', coalesce(mp.monto_cuota, 0),
            'primer_vencimiento', '2026-03-05'
          ),
          true
        )
    end as new_meta
  from matricula_prepared mp
),
matricula_updates as (
  update public.enrollments e
  set meta = mp.new_meta,
      updated_at = now()
  from matricula_patched mp
  where e.id = mp.enrollment_id
  returning mp.student_id, e.id as enrollment_id
),
fee_src as (
  select *
  from jsonb_to_recordset('[{"enrollment_id": "f1b103fb-4400-471f-8d2a-4dd789326207", "student_id": "04e6c1a6-e72c-4ccc-aa13-9e900fa3be97", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "fa19b9ee-9765-487f-b052-b96d8ca2828f", "student_id": "08b2dd2d-0739-46fc-8a4d-19e9013ca0de", "target_fee_count": "10", "target_payment_method": "CHEQUE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "74f62c36-655c-4b9b-b772-f6b68db41b32", "student_id": "195577c6-a45c-4e97-9de3-76ebc4af4f09", "target_fee_count": "0", "target_payment_method": "SIN_FEE", "target_min_amount": "", "target_total": "", "target_min_installment": "", "target_max_installment": ""}, {"enrollment_id": "5ad7dbf2-7183-4c93-a9ad-d700bed09ef7", "student_id": "3317705f-7dd3-49ca-b547-21b3155fd611", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "99324.00", "target_total": "993240.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "9abd66dc-36cb-42e9-a24e-c7224e8d0951", "student_id": "3a283002-2d43-4568-bd8c-d0fa2463cc81", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "fe495910-415b-4b30-bd6f-c8c216c6a800", "student_id": "40812bca-c859-4aab-b744-e017cd94d974", "target_fee_count": "0", "target_payment_method": "SIN_FEE", "target_min_amount": "", "target_total": "", "target_min_installment": "", "target_max_installment": ""}, {"enrollment_id": "7de67eb0-a861-4879-95eb-d5ef4246d8cc", "student_id": "55e0c792-a2b9-4712-a4d7-a4ae4cd2d4d4", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "b586387a-9d35-40d6-8970-8310b2aafa5a", "student_id": "5a907b42-8a3a-4742-9aa1-4b02b6884045", "target_fee_count": "0", "target_payment_method": "SIN_FEE", "target_min_amount": "", "target_total": "", "target_min_installment": "", "target_max_installment": ""}, {"enrollment_id": "b64ea244-c5f3-4b3e-a585-d8bb7f2ba257", "student_id": "65189315-ca98-4cb3-b9d6-8ff2eb8e80e1", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "e47e19b6-75ea-4ff6-9d8d-40a97e56b53a", "student_id": "67bc9321-1484-4d62-b46f-5ab24648d0db", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "006f2777-5517-42b1-82c3-a540b07125bb", "student_id": "6812c399-a2ac-4f08-9a56-289848c655be", "target_fee_count": "0", "target_payment_method": "SIN_FEE", "target_min_amount": "", "target_total": "", "target_min_installment": "", "target_max_installment": ""}, {"enrollment_id": "23de1816-62e8-4509-9a66-29b80dbe43b6", "student_id": "6952432f-f7ab-4774-9ef6-1d9d050f1892", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "102870.00", "target_min_installment": "1", "target_max_installment": "1"}, {"enrollment_id": "89c47263-df33-49ce-9bbf-10dcf4d19c00", "student_id": "74b29b66-f821-468f-8308-a41f213dcf58", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "1028700.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "1"}, {"enrollment_id": "275d41c7-1374-4d16-a443-4fb524bb4038", "student_id": "8100f568-89d1-4330-acb0-5ead711d631d", "target_fee_count": "0", "target_payment_method": "SIN_FEE", "target_min_amount": "", "target_total": "", "target_min_installment": "", "target_max_installment": ""}, {"enrollment_id": "9d5d6220-74d6-4fc6-9a8a-242f6d65d0dd", "student_id": "8131019a-9414-471a-95d2-65087f949cb7", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "133126.00", "target_total": "1331260.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "403769b3-aaee-4b41-a25a-10134cb9140e", "student_id": "83ea7cec-45c4-4b60-b89e-f141671108ed", "target_fee_count": "0", "target_payment_method": "SIN_FEE", "target_min_amount": "", "target_total": "", "target_min_installment": "", "target_max_installment": ""}, {"enrollment_id": "cfde4fbb-f707-414d-b112-e8b6979c390f", "student_id": "94c70054-2428-4e84-9a84-bbafb3171e51", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "133126.00", "target_total": "1331260.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "7f9d1595-3c22-4df7-bd43-e2994acc205f", "student_id": "9ce9f734-8aa7-4440-81b8-ba98466f14df", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "a0999f25-89ae-40ca-b77d-b9d9b73009af", "student_id": "ae3988c6-e33a-4cd2-acd8-a47898445e59", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "79876.00", "target_total": "798760.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "fe495910-415b-4b30-bd6f-c8c216c6a800", "student_id": "bf024ee2-4e96-4c70-97c3-584d5669ddb1", "target_fee_count": "0", "target_payment_method": "SIN_FEE", "target_min_amount": "", "target_total": "", "target_min_installment": "", "target_max_installment": ""}, {"enrollment_id": "0df0822d-53aa-456d-8677-0a12b5e29895", "student_id": "d29967d7-ddaf-46e9-9e51-9e3e98c18d63", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "d407e4ba-fb8e-4c6e-b547-46448ee4a06d", "student_id": "e0bf1072-fbec-4732-aa38-4b892db92a9f", "target_fee_count": "10", "target_payment_method": "CHEQUE", "target_min_amount": "133126.00", "target_total": "1331260.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "f972167c-5003-4247-b8be-0a89536b6d51", "student_id": "e0fb9baf-658b-402f-8443-2fb6f0484458", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "80a6e309-c49e-436f-ac1d-d63b45ced2ee", "student_id": "fb2b948d-6e42-4ce8-9034-c2991c3d3145", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "133126.00", "target_total": "1331260.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "f160be4e-e9a9-48e8-87f6-903cf8e57ca1", "student_id": "feb6954d-6ad9-4ab7-b2c9-e8fd2d5297f2", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "82296.00", "target_total": "822960.00", "target_min_installment": "1", "target_max_installment": "10"}, {"enrollment_id": "07aa90fc-9a60-4de1-a1b8-1636d9d8c06c", "student_id": "ff66c43d-8f12-4921-aa9d-5a306a9234e6", "target_fee_count": "10", "target_payment_method": "PAGARE", "target_min_amount": "102870.00", "target_total": "1028700.00", "target_min_installment": "1", "target_max_installment": "10"}]'::jsonb) as s(
    enrollment_id uuid,
    student_id uuid,
    target_fee_count text,
    target_payment_method text,
    target_min_amount text,
    target_total text,
    target_min_installment text,
    target_max_installment text
  )
),
fee_norm as (
  select
    fs.enrollment_id,
    fs.student_id,
    case when nullif(trim(coalesce(fs.target_fee_count, '')), '') is null then 0 else trim(fs.target_fee_count)::int end as target_fee_count,
    upper(nullif(trim(fs.target_payment_method), '')) as target_payment_method,
    case when nullif(trim(coalesce(fs.target_min_amount, '')), '') is null then null else trim(fs.target_min_amount)::numeric end as target_amount,
    case when nullif(trim(coalesce(fs.target_total, '')), '') is null then null else trim(fs.target_total)::numeric end as target_total,
    case when nullif(trim(coalesce(fs.target_min_installment, '')), '') is null then 1 else trim(fs.target_min_installment)::int end as min_installment,
    case
      when nullif(trim(coalesce(fs.target_max_installment, '')), '') is null and nullif(trim(coalesce(fs.target_fee_count, '')), '') is null then 0
      when nullif(trim(coalesce(fs.target_max_installment, '')), '') is null then trim(fs.target_fee_count)::int
      else trim(fs.target_max_installment)::int
    end as max_installment,
    mn.cuotas as matricula_cuotas,
    mn.monto_cuota as matricula_amount,
    mn.total_anual as matricula_total,
    mn.payment_method as matricula_payment_method
  from fee_src fs
  left join matricula_norm mn
    on mn.enrollment_id = fs.enrollment_id
   and mn.student_id = fs.student_id
),
fee_effective as (
  select
    enrollment_id,
    student_id,
    target_fee_count,
    coalesce(target_payment_method, matricula_payment_method) as target_payment_method,
    case
      when target_fee_count > 1 and (
        target_amount is null
        or target_total is null
        or target_amount * target_fee_count <> target_total
      ) then coalesce(matricula_amount, target_amount)
      else target_amount
    end as target_amount,
    case
      when target_fee_count > 1 and (
        target_amount is null
        or target_total is null
        or target_amount * target_fee_count <> target_total
      ) then coalesce(matricula_total, target_total)
      else target_total
    end as target_total,
    case
      when target_fee_count <= 0 then 0
      else coalesce(nullif(min_installment, 0), 1)
    end as min_installment,
    case
      when target_fee_count <= 0 then 0
      else greatest(coalesce(nullif(max_installment, 0), target_fee_count), target_fee_count)
    end as max_installment
  from fee_norm
),
fee_deletes as (
  delete from public.fee f
  using fee_effective fn
  where f.student_id = fn.student_id
    and f.year_academico = 2026
    and (fn.target_fee_count = 0 or fn.target_payment_method = 'SIN_FEE')
  returning f.id, f.student_id
),
fee_anchor as (
  select distinct
    fn.student_id,
    fn.enrollment_id,
    e.guardian_id,
    s.owner_id,
    s.curso as fee_curso,
    fn.target_payment_method,
    fn.target_amount,
    fn.target_total,
    fn.min_installment,
    fn.max_installment,
    fn.target_fee_count
  from fee_effective fn
  join public.enrollments e on e.id = fn.enrollment_id and e.year = 2026
  join public.students s on s.id = fn.student_id
  where fn.target_fee_count > 0 and fn.target_payment_method <> 'SIN_FEE'
),
fee_desired_rows as (
  select
    fa.student_id,
    fa.guardian_id,
    fa.owner_id,
    fa.fee_curso,
    fa.enrollment_id,
    fa.target_payment_method as payment_method,
    coalesce(fa.target_amount, case when fa.target_fee_count > 0 then round(fa.target_total / fa.target_fee_count, 2) else 0 end, 0) as amount,
    gs as numero_cuota,
    (date '2026-03-05' + make_interval(months => gs - 1))::date as due_date
  from fee_anchor fa
  join lateral generate_series(greatest(fa.min_installment, 1), greatest(fa.max_installment, 0)) gs on true
),
fee_upserts as (
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
  from fee_desired_rows dr
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
    meta = coalesce(public.fee.meta, '{}'::jsonb) || excluded.meta
  returning student_id, numero_cuota
),
fee_extra_cleanup as (
  delete from public.fee f
  using fee_anchor fa
  where f.student_id = fa.student_id
    and f.year_academico = 2026
    and (f.numero_cuota is null or f.numero_cuota < fa.min_installment or f.numero_cuota > fa.max_installment)
    and coalesce(f.status, 'pending') <> 'paid'
  returning f.id, f.student_id
)
select json_build_object(
  'matricula_updates', (select count(*) from matricula_updates),
  'fee_deleted', (select count(*) from fee_deletes),
  'fee_upserted', (select count(*) from fee_upserts),
  'fee_extra_deleted', (select count(*) from fee_extra_cleanup)
) as summary;

commit;
