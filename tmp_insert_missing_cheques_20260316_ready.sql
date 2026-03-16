-- SQL generado automaticamente desde update_cheques.csv y tmp_update_cheques_report_20260316.json
-- Inserta cheques faltantes para enrollments 2026 con pago en cheque y sin registros en public.cheques
begin;

-- enrollment_id: 07b47ca6-b02a-462a-8e61-e24768c8cd53 | folio: ENR-2026-000127 | filas CSV: 17
-- alumnos: FERNANDA EMILIA VIDAL SANCHEZ
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633421', 'Scotiabank', '2026-03-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633422', 'Scotiabank', '2026-04-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633423', 'Scotiabank', '2026-05-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633410', 'Scotiabank', '2026-06-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633409', 'Scotiabank', '2026-07-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633414', 'Scotiabank', '2026-08-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633415', 'Scotiabank', '2026-09-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633416', 'Scotiabank', '2026-10-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633417', 'Scotiabank', '2026-11-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid, '9633418', 'Scotiabank', '2026-12-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 17; alumnos: FERNANDA EMILIA VIDAL SANCHEZ; series_csv: 9633421-22-23-410-409-414-415-416-17-18; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000127'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '07b47ca6-b02a-462a-8e61-e24768c8cd53'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 124f2fcb-ee42-47a1-8e52-180919137c32 | folio: ENR-2026-000121 | filas CSV: 5
-- alumnos: AMANDA FRANCISCA SALINAS VELIZ
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '0000367', 'Santander', '2026-03-05'::date, 147918, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 5; alumnos: AMANDA FRANCISCA SALINAS VELIZ; series_csv: 0000367-68-69-70-71-72-73-74-75-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000121'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '0000368', 'Santander', '2026-04-05'::date, 147918, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 5; alumnos: AMANDA FRANCISCA SALINAS VELIZ; series_csv: 0000367-68-69-70-71-72-73-74-75-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000121'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '0000369', 'Santander', '2026-05-05'::date, 147918, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 5; alumnos: AMANDA FRANCISCA SALINAS VELIZ; series_csv: 0000367-68-69-70-71-72-73-74-75-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000121'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '0000370', 'Santander', '2026-06-05'::date, 147918, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 5; alumnos: AMANDA FRANCISCA SALINAS VELIZ; series_csv: 0000367-68-69-70-71-72-73-74-75-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000121'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '0000371', 'Santander', '2026-07-05'::date, 147918, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 5; alumnos: AMANDA FRANCISCA SALINAS VELIZ; series_csv: 0000367-68-69-70-71-72-73-74-75-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000121'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '0000372', 'Santander', '2026-08-05'::date, 147918, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 5; alumnos: AMANDA FRANCISCA SALINAS VELIZ; series_csv: 0000367-68-69-70-71-72-73-74-75-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000121'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '0000373', 'Santander', '2026-09-05'::date, 147918, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 5; alumnos: AMANDA FRANCISCA SALINAS VELIZ; series_csv: 0000367-68-69-70-71-72-73-74-75-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000121'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '0000374', 'Santander', '2026-10-05'::date, 147918, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 5; alumnos: AMANDA FRANCISCA SALINAS VELIZ; series_csv: 0000367-68-69-70-71-72-73-74-75-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000121'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid, '0000375', 'Santander', '2026-11-05'::date, 147918, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 5; alumnos: AMANDA FRANCISCA SALINAS VELIZ; series_csv: 0000367-68-69-70-71-72-73-74-75-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000121'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '124f2fcb-ee42-47a1-8e52-180919137c32'::uuid
    and c.numero_cuota = 9
);

-- enrollment_id: 138f0e5e-6d4d-4ff9-8f06-603cea01c9cc | folio: ENR-2026-000413 | filas CSV: 46
-- alumnos: PASCAL ALUDY VEGA PLAZA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000012', 'Falabella', '2026-03-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000013', 'Falabella', '2026-04-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000014', 'Falabella', '2026-05-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000015', 'Falabella', '2026-06-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000016', 'Falabella', '2026-07-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000017', 'Falabella', '2026-08-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000018', 'Falabella', '2026-09-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000019', 'Falabella', '2026-10-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000020', 'Falabella', '2026-11-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid, '0000021', 'Falabella', '2026-12-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 46; alumnos: PASCAL ALUDY VEGA PLAZA; series_csv: 0000012-13-14-15-16-17-18-19-20-21-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000413'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '138f0e5e-6d4d-4ff9-8f06-603cea01c9cc'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 1aaca118-c47b-478d-9dda-1b60d3ebe85e | folio: ENR-2026-000039 | filas CSV: 35, 36
-- alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118374', 'Banco de Chile', '2026-03-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118375', 'Banco de Chile', '2026-04-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118376', 'Banco de Chile', '2026-05-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118377', 'Banco de Chile', '2026-06-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118378', 'Banco de Chile', '2026-07-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118379', 'Banco de Chile', '2026-08-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118380', 'Banco de Chile', '2026-09-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118381', 'Banco de Chile', '2026-10-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118382', 'Banco de Chile', '2026-11-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid, '5118383', 'Banco de Chile', '2026-12-05'::date, 205740, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 35, 36; alumnos: SAMUEL SIMON VALDES COVARRUBIAS | SANTIAGO VALDES COVARRUBIAS; series_csv: 5118374-75-76-77-78-79-80-81-82-83; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000039'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '1aaca118-c47b-478d-9dda-1b60d3ebe85e'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 211baf57-14f1-46fe-89a9-94d5ebf50af8 | folio: SIN_FOLIO | filas CSV: 42
-- alumnos: LUCAS IGNACIO ROSSI GONZALEZ
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655623', 'Scotiabank', '2026-03-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 1, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655624', 'Scotiabank', '2026-04-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 2, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655625', 'Scotiabank', '2026-05-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 3, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655626', 'Scotiabank', '2026-06-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 4, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655627', 'Scotiabank', '2026-07-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 5, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655628', 'Scotiabank', '2026-08-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 6, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655630', 'Scotiabank', '2026-09-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 7, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655631', 'Scotiabank', '2026-10-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 8, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655632', 'Scotiabank', '2026-11-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 9, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid, '1655633', 'Scotiabank', '2026-12-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 42; alumnos: LUCAS IGNACIO ROSSI GONZALEZ; series_csv: 1655623-24-25-26-27-28-30-31-32-33-; parse_mode: parsed_basic', NULL, 10, ''
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 32544798-ccc3-4f37-b63b-913c0794316e | folio: ENR-2026-000106 | filas CSV: 13
-- alumnos: CRISTOBAL LEON ROMANI GUTIERREZ
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330397', 'Scotiabank', '2026-03-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330398', 'Scotiabank', '2026-04-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330399', 'Scotiabank', '2026-05-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330400', 'Scotiabank', '2026-06-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330401', 'Scotiabank', '2026-07-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330402', 'Scotiabank', '2026-08-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330403', 'Scotiabank', '2026-09-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330404', 'Scotiabank', '2026-10-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330405', 'Scotiabank', '2026-11-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '32544798-ccc3-4f37-b63b-913c0794316e'::uuid, '8330406', 'Scotiabank', '2026-12-05'::date, 79876, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 13; alumnos: CRISTOBAL LEON ROMANI GUTIERREZ; series_csv: 8330397-98-99-400-401-402-403-404-405-406; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000106'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '32544798-ccc3-4f37-b63b-913c0794316e'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 34673862-ec1a-43d1-ba0a-328da6291be6 | folio: ENR-2026-000011 | filas CSV: 19
-- alumnos: GAEL EMILIANO FUENTES TORO
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112463', 'BCI', '2026-03-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112464', 'BCI', '2026-04-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112465', 'BCI', '2026-05-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112466', 'BCI', '2026-06-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112467', 'BCI', '2026-07-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112468', 'BCI', '2026-08-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112469', 'BCI', '2026-09-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112470', 'BCI', '2026-10-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112471', 'BCI', '2026-11-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid, '112472', 'BCI', '2026-12-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 19; alumnos: GAEL EMILIANO FUENTES TORO; series_csv: 112463-64-65-66-67-68-69-70-71-72; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000011'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '34673862-ec1a-43d1-ba0a-328da6291be6'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 38d5b7f9-8113-445d-8ea8-722de2a0769e | folio: ENR-2026-000148 | filas CSV: 48
-- alumnos: RENATO ALONSO OPAZO CABELLO
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001341', 'Santander', '2026-03-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001342', 'Santander', '2026-04-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001343', 'Santander', '2026-05-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001344', 'Santander', '2026-06-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001345', 'Santander', '2026-07-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001346', 'Santander', '2026-08-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001347', 'Santander', '2026-09-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001348', 'Santander', '2026-10-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001349', 'Santander', '2026-11-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid, '0001350', 'Santander', '2026-12-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 48; alumnos: RENATO ALONSO OPAZO CABELLO; series_csv: 0001341-42-43-44-45-46-47-48-49-50; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000148'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '38d5b7f9-8113-445d-8ea8-722de2a0769e'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d | folio: ENR-2026-000085 | filas CSV: 8
-- alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170367', 'Banco de Chile', '2026-03-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170368', 'Banco de Chile', '2026-04-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170369', 'Banco de Chile', '2026-05-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170370', 'Banco de Chile', '2026-06-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170371', 'Banco de Chile', '2026-07-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170372', 'Banco de Chile', '2026-08-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170373', 'Banco de Chile', '2026-09-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170374', 'Banco de Chile', '2026-10-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170375', 'Banco de Chile', '2026-11-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid, '9170376', 'Banco de Chile', '2026-12-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 8; alumnos: GIULIANO ANTONINO CANTARUTTI CONCHA; series_csv: 9170367-68-69-70-71-72-73-7475-76; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000085'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 54fa273b-de64-4d52-a026-71b4ccf8b1a5 | folio: ENR-2026-000422 | filas CSV: 10
-- alumnos: AURORA MAGDALENA GONZALEZ KIMER
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548615', 'Banco de Chile', '2026-03-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548616', 'Banco de Chile', '2026-04-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548617', 'Banco de Chile', '2026-05-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548618', 'Banco de Chile', '2026-06-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548619', 'Banco de Chile', '2026-07-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548620', 'Banco de Chile', '2026-08-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548625', 'Banco de Chile', '2026-09-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548622', 'Banco de Chile', '2026-10-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548623', 'Banco de Chile', '2026-11-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid, '3548624', 'Banco de Chile', '2026-12-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 10; alumnos: AURORA MAGDALENA GONZALEZ KIMER; series_csv: 3548615-16-17-18-19--20-25-22-23-24; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000422'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '54fa273b-de64-4d52-a026-71b4ccf8b1a5'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 5b70b39b-0634-4e88-b182-63a6532fa981 | folio: ENR-2026-000120 | filas CSV: 40
-- alumnos: LEON VLADIMIR DIAZ GONZALEZ
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946891', 'BancoEstado', '2026-03-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946892', 'BancoEstado', '2026-04-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946893', 'BancoEstado', '2026-05-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946894', 'BancoEstado', '2026-06-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946895', 'BancoEstado', '2026-07-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946896', 'BancoEstado', '2026-08-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946897', 'BancoEstado', '2026-09-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946898', 'BancoEstado', '2026-10-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946899', 'BancoEstado', '2026-11-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid, '7946900', 'BancoEstado', '2026-12-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 40; alumnos: LEON VLADIMIR DIAZ GONZALEZ; series_csv: 7946891-92-93-94-95-96-97-98-99-900; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000120'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '5b70b39b-0634-4e88-b182-63a6532fa981'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 70285275-2e4b-4da0-a838-28ed5b062b26 | folio: ENR-2026-000142 | filas CSV: 37, 38
-- alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825654', 'Banco de Chile', '2026-03-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825655', 'Banco de Chile', '2026-04-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825656', 'Banco de Chile', '2026-05-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825657', 'Banco de Chile', '2026-06-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825658', 'Banco de Chile', '2026-07-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825659', 'Banco de Chile', '2026-08-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825660', 'Banco de Chile', '2026-09-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825661', 'Banco de Chile', '2026-10-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825662', 'Banco de Chile', '2026-11-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid, '8825663', 'Banco de Chile', '2026-12-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 37, 38; alumnos: GASPAR ALFONSO CACES SEPULVEDA | LIBERTAD CACES SEPÚLVEDA; series_csv: 8825654-55-56-57-58-59-60-61-62-63; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000142'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '70285275-2e4b-4da0-a838-28ed5b062b26'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 79fb8e49-c458-4f9f-a7cd-13763d35d9f3 | folio: ENR-2026-000105 | filas CSV: 18
-- alumnos: FRANCISCA IGNACIA BARRAZA MELO
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176474', 'BancoEstado', '2026-03-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176475', 'BancoEstado', '2026-04-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176477', 'BancoEstado', '2026-05-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176478', 'BancoEstado', '2026-06-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176479', 'BancoEstado', '2026-07-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176480', 'BancoEstado', '2026-08-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176481', 'BancoEstado', '2026-09-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176482', 'BancoEstado', '2026-10-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176483', 'BancoEstado', '2026-11-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid, '1176484', 'BancoEstado', '2026-12-05'::date, 106501, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 18; alumnos: FRANCISCA IGNACIA BARRAZA MELO; series_csv: 1176474-75-77-78-79-80-81-82-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000105'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '79fb8e49-c458-4f9f-a7cd-13763d35d9f3'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 918c6611-d1af-4d87-842e-fb502ff3bef5 | folio: ENR-2026-000012 | filas CSV: 16
-- alumnos: FACUNDO AQUEVEQUE SOLANO
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560025', 'Banco de Chile', '2026-03-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 1, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560026', 'Banco de Chile', '2026-04-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 2, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560027', 'Banco de Chile', '2026-05-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 3, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560028', 'Banco de Chile', '2026-06-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 4, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560029', 'Banco de Chile', '2026-07-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 5, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560030', 'Banco de Chile', '2026-08-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 6, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560031', 'Banco de Chile', '2026-09-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 7, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560033', 'Banco de Chile', '2026-10-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 8, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560034', 'Banco de Chile', '2026-11-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 9, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid, '5560035', 'Banco de Chile', '2026-12-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 16; alumnos: FACUNDO AQUEVEQUE SOLANO; series_csv: 5560025-26-27-28-29-30-31-33-34-35; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 10, 'ENR-2026-000012'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '918c6611-d1af-4d87-842e-fb502ff3bef5'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 949f452f-c039-4da0-ac5a-0afa3658b058 | folio: ENR-2026-000421 | filas CSV: 31, 32
-- alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963496', 'Itaú', '2026-03-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963497', 'Itaú', '2026-04-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963506', 'Itaú', '2026-05-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963499', 'Itaú', '2026-06-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963500', 'Itaú', '2026-07-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963501', 'Itaú', '2026-08-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963502', 'Itaú', '2026-09-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963503', 'Itaú', '2026-10-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963504', 'Itaú', '2026-11-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid, '6963505', 'Itaú', '2026-12-05'::date, 273252, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 31, 32; alumnos: DANIEL ERNESTO CONEJEROS BELTRAMI | JAVIERA VIOLETA CONEJEROS BELTRAMI; series_csv: 6963496-97-506-499-500-501-502-503-504-505; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000421'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '949f452f-c039-4da0-ac5a-0afa3658b058'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: 9755e5d1-e54f-4443-884b-721219622d77 | folio: ENR-2026-000162 | filas CSV: 51
-- alumnos: VIOLETA BEATRIZ GUERRERO BIRKE
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '9755e5d1-e54f-4443-884b-721219622d77'::uuid, '1419282', 'BancoEstado', '2026-03-05'::date, 332815, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 51; alumnos: VIOLETA BEATRIZ GUERRERO BIRKE; series_csv: 1419282-85-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000162'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '9755e5d1-e54f-4443-884b-721219622d77'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '9755e5d1-e54f-4443-884b-721219622d77'::uuid, '1419285', 'BancoEstado', '2026-04-05'::date, 332815, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 51; alumnos: VIOLETA BEATRIZ GUERRERO BIRKE; series_csv: 1419282-85-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000162'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '9755e5d1-e54f-4443-884b-721219622d77'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '9755e5d1-e54f-4443-884b-721219622d77'::uuid, '1419283', 'BancoEstado', '2026-05-05'::date, 332815, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 51; alumnos: VIOLETA BEATRIZ GUERRERO BIRKE; series_csv: 1419282-85-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000162'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '9755e5d1-e54f-4443-884b-721219622d77'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '9755e5d1-e54f-4443-884b-721219622d77'::uuid, '1419284', 'BancoEstado', '2026-06-05'::date, 332815, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 51; alumnos: VIOLETA BEATRIZ GUERRERO BIRKE; series_csv: 1419282-85-83-84-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000162'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = '9755e5d1-e54f-4443-884b-721219622d77'::uuid
    and c.numero_cuota = 4
);

-- enrollment_id: a0bb84d1-20ce-420d-837c-6e43283bf8e0 | folio: ENR-2026-000418 | filas CSV: 39
-- alumnos: LAURA RENATA DÍAZ NOVOA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058329', 'BancoEstado', '2026-03-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058328', 'BancoEstado', '2026-04-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058327', 'BancoEstado', '2026-05-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058326', 'BancoEstado', '2026-06-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058325', 'BancoEstado', '2026-07-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058324', 'BancoEstado', '2026-08-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058323', 'BancoEstado', '2026-09-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058322', 'BancoEstado', '2026-10-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058321', 'BancoEstado', '2026-11-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid, '3058320', 'BancoEstado', '2026-12-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 39; alumnos: LAURA RENATA DÍAZ NOVOA; series_csv: 3058329-28-272625-24-23-22-2120; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000418'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a0bb84d1-20ce-420d-837c-6e43283bf8e0'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: a392bde7-871d-44ed-b57f-5180fddb97a1 | folio: ENR-2026-000198 | filas CSV: 50
-- alumnos: SIMON EMILIO LAZCANO MALDONADO
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814143', 'Itaú', '2026-03-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814144', 'Itaú', '2026-04-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814145', 'Itaú', '2026-05-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814146', 'Itaú', '2026-06-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814147', 'Itaú', '2026-07-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814148', 'Itaú', '2026-08-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814149', 'Itaú', '2026-09-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814150', 'Itaú', '2026-10-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814141', 'Itaú', '2026-11-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid, '2814142', 'Itaú', '2026-12-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 50; alumnos: SIMON EMILIO LAZCANO MALDONADO; series_csv: 2814143-4-5-6-7-8-9-150-1-2; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000198'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'a392bde7-871d-44ed-b57f-5180fddb97a1'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: b3db34df-a0f9-49c8-90b9-ed413c2cc855 | folio: ENR-2026-000219 | filas CSV: 12
-- alumnos: CRISTOBAL GERMAN FICK IBACETA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207277', 'Scotiabank', '2026-03-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207278', 'Scotiabank', '2026-04-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207279', 'Scotiabank', '2026-05-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207280', 'Scotiabank', '2026-06-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207281', 'Scotiabank', '2026-07-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207282', 'Scotiabank', '2026-08-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207283', 'Scotiabank', '2026-09-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207284', 'Scotiabank', '2026-10-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207285', 'Scotiabank', '2026-11-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid, '8207286', 'Scotiabank', '2026-12-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 12; alumnos: CRISTOBAL GERMAN FICK IBACETA; series_csv: 8207277-78-79-80-81-82-83-84-85-86-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000219'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b3db34df-a0f9-49c8-90b9-ed413c2cc855'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: b9f8dcd1-7a96-4414-85af-33a4c89ee0f9 | folio: ENR-2026-000074 | filas CSV: 2
-- alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000048', 'Falabella', '2026-03-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000049', 'Falabella', '2026-04-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000050', 'Falabella', '2026-05-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000051', 'Falabella', '2026-06-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000052', 'Falabella', '2026-07-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000053', 'Falabella', '2026-08-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000054', 'Falabella', '2026-09-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000055', 'Falabella', '2026-10-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000056', 'Falabella', '2026-11-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid, '0000057', 'Falabella', '2026-12-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 2; alumnos: AGUSTIN IGNACIO ZAMORA INOSTROZA; series_csv: 0000048-49-50-51-52-53-54-55-56-57-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000074'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'b9f8dcd1-7a96-4414-85af-33a4c89ee0f9'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: d407e4ba-fb8e-4c6e-b547-46448ee4a06d | folio: ENR-2026-000384 | filas CSV: 21, 22
-- alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145056', 'Banco de Chile', '2026-03-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 1, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145057', 'Banco de Chile', '2026-04-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 2, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145058', 'Banco de Chile', '2026-05-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 3, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145059', 'Banco de Chile', '2026-06-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 4, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145060', 'Banco de Chile', '2026-07-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 5, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145061', 'Banco de Chile', '2026-08-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 6, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145062', 'Banco de Chile', '2026-09-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 7, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145063', 'Banco de Chile', '2026-10-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 8, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145064', 'Banco de Chile', '2026-11-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 9, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid, '9145065', 'Banco de Chile', '2026-12-05'::date, 235996, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 21, 22; alumnos: AGUSTINA ALARCÓN HERRERA | MARTINA ALARCON HERRERA; series_csv: 9145056-57-58-59-60-61-62-63-64-65-; parse_mode: parsed_basic', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 10, 'ENR-2026-000384'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd407e4ba-fb8e-4c6e-b547-46448ee4a06d'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: d83a358c-b4fe-4191-8ec2-54c990b95ca8 | folio: ENR-2026-000410 | filas CSV: 11
-- alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460237', 'Itaú', '2026-03-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460238', 'Itaú', '2026-04-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460239', 'Itaú', '2026-05-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460240', 'Itaú', '2026-06-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460241', 'Itaú', '2026-07-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460242', 'Itaú', '2026-08-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460243', 'Itaú', '2026-09-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460244', 'Itaú', '2026-10-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460245', 'Itaú', '2026-11-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid, '3460246', 'Itaú', '2026-12-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 11; alumnos: AYLIN MAITE ELOISA ALARCON OYARZUN; series_csv: 3460237-38-39-40-41-42-43-44-45-46; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000410'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'd83a358c-b4fe-4191-8ec2-54c990b95ca8'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: e23eab60-d5cd-49e5-90a8-189104140ce8 | folio: ENR-2026-000213 | filas CSV: 26, 27, 28
-- alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338029', 'Banco de Chile', '2026-03-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338030', 'Banco de Chile', '2026-04-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338031', 'Banco de Chile', '2026-05-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338032', 'Banco de Chile', '2026-06-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338033', 'Banco de Chile', '2026-07-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338034', 'Banco de Chile', '2026-08-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338035', 'Banco de Chile', '2026-09-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338036', 'Banco de Chile', '2026-10-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338037', 'Banco de Chile', '2026-11-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid, '4338038', 'Banco de Chile', '2026-12-05'::date, 338866, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 26, 27, 28; alumnos: CONSTANZA PAZ CARRASCO SEPULVEDA | CRISTIAN ANDRES CARRASCO SEPULVEDA | FRANCISCO GABRIEL CARRASCO SEPULVEDA; series_csv: 4338029-30-31-32-33-34-35-36-37-38; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000213'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e23eab60-d5cd-49e5-90a8-189104140ce8'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9 | folio: ENR-2026-000153 | filas CSV: 49
-- alumnos: RENATO ALONSO RODRIGUEZ BARRERA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245063', 'Banco de Chile', '2026-03-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245064', 'Banco de Chile', '2026-04-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245055', 'Banco de Chile', '2026-05-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245056', 'Banco de Chile', '2026-06-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245057', 'Banco de Chile', '2026-07-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245058', 'Banco de Chile', '2026-08-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245059', 'Banco de Chile', '2026-09-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245060', 'Banco de Chile', '2026-10-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245061', 'Banco de Chile', '2026-11-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid, '4245062', 'Banco de Chile', '2026-12-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 49; alumnos: RENATO ALONSO RODRIGUEZ BARRERA; series_csv: 4245063-64-55-56-57-58-59-60-61-62-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000153'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e2ddf8e0-8374-46fb-8ce9-9f201d91d6e9'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: e7829e3e-6340-462f-9965-426314b2086e | folio: ENR-2026-000086 | filas CSV: 15
-- alumnos: DOMINGA REBOLLEDO STHANDIER
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544156', 'BCI', '2026-03-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544157', 'BCI', '2026-04-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544158', 'BCI', '2026-05-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544159', 'BCI', '2026-06-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544160', 'BCI', '2026-07-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544161', 'BCI', '2026-08-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544162', 'BCI', '2026-09-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544163', 'BCI', '2026-10-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544164', 'BCI', '2026-11-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e7829e3e-6340-462f-9965-426314b2086e'::uuid, '4544165', 'BCI', '2026-12-05'::date, 102870, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 15; alumnos: DOMINGA REBOLLEDO STHANDIER; series_csv: 4544156-57-58-59-60-61-6263-64-65; parse_mode: parsed_even_chunks; issues: raw_series_required_chunk_split', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000086'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e7829e3e-6340-462f-9965-426314b2086e'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: e81dc188-09e2-421b-9a48-f1fcc380f093 | folio: ENR-2026-000328 | filas CSV: 47
-- alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584783', 'Banco de Chile', '2026-03-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584785', 'Banco de Chile', '2026-04-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584786', 'Banco de Chile', '2026-05-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584787', 'Banco de Chile', '2026-06-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584788', 'Banco de Chile', '2026-07-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584789', 'Banco de Chile', '2026-08-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584790', 'Banco de Chile', '2026-09-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584791', 'Banco de Chile', '2026-10-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584792', 'Banco de Chile', '2026-11-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid, '4584793', 'Banco de Chile', '2026-12-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 47; alumnos: RAFAELA ANTONIA GUTIERREZ SEPULVEDA; series_csv: 4584783-85-86-87-88-89-90-91-92-93; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000328'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'e81dc188-09e2-421b-9a48-f1fcc380f093'::uuid
    and c.numero_cuota = 10
);

-- enrollment_id: eae29906-dc8a-4fe4-9bd4-bada71977dba | folio: ENR-2026-000194 | filas CSV: 43
-- alumnos: MAGDALENA SOLIS GOMEZ
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725245', 'Scotiabank', '2026-03-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725246', 'Scotiabank', '2026-04-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 2, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725247', 'Scotiabank', '2026-05-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 3, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725248', 'Scotiabank', '2026-06-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 4, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725249', 'Scotiabank', '2026-07-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 5, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725250', 'Scotiabank', '2026-08-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 6, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725251', 'Scotiabank', '2026-09-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 7, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725252', 'Scotiabank', '2026-10-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 8, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725253', 'Scotiabank', '2026-11-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 9, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid, '7725255', 'Scotiabank', '2026-12-05'::date, 133126, 'pendiente', 'Carga inicial desde update_cheques.csv fila(s) 43; alumnos: MAGDALENA SOLIS GOMEZ; series_csv: 7725245-46-47-48-49-50-51-52-53-55-; parse_mode: parsed_basic', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 10, 'ENR-2026-000194'
where not exists (
  select 1
  from public.cheques c
  where c.enrollment_id = 'eae29906-dc8a-4fe4-9bd4-bada71977dba'::uuid
    and c.numero_cuota = 10
);

commit;
