-- Resolucion manual de casos bloqueados del plan de carga de cheques 2026.
-- Ejecutar despues de tmp_insert_missing_cheques_20260316_ready.sql.
-- Criterios adoptados el 2026-03-16:
--   1) CARVAJAL: usar placeholder numerico 1..10 y dejar trazabilidad en fee.notes.
--   2) MATIAS: usar monto 1331260 y placeholder numerico 1; dejar trazabilidad en fee.notes.
--   3) ARENAS: tomar el CSV familiar como fuente autoritativa.

begin;

-- Caso seguro arrastrado de la revision previa: reconstruir meta de LUCAS ROSSI.
update public.enrollments
set
  meta = coalesce(meta, '{}'::jsonb)
    || jsonb_build_object(
      'forma_pago_cheques', true,
      'forma_pago_pagare', false,
      'forma_pago_transferencia', false,
      'cantidad_cuotas', 10,
      'dia_vencimiento', 5,
      'monto_cuota', 133126,
      'payment_plan', jsonb_build_object(
        'n_cuotas', 10,
        'monto_total', 1331260,
        'payment_method', 'CHEQUE',
        'dia_vencimiento', 5,
        'monto_por_cuota', 133126,
        'primer_vencimiento', '2026-03-05',
        'cuotas', jsonb_build_array(
          jsonb_build_object('amount', 133126, 'numero', 1, 'due_date', '2026-03-05'),
          jsonb_build_object('amount', 133126, 'numero', 2, 'due_date', '2026-04-05'),
          jsonb_build_object('amount', 133126, 'numero', 3, 'due_date', '2026-05-05'),
          jsonb_build_object('amount', 133126, 'numero', 4, 'due_date', '2026-06-05'),
          jsonb_build_object('amount', 133126, 'numero', 5, 'due_date', '2026-07-05'),
          jsonb_build_object('amount', 133126, 'numero', 6, 'due_date', '2026-08-05'),
          jsonb_build_object('amount', 133126, 'numero', 7, 'due_date', '2026-09-05'),
          jsonb_build_object('amount', 133126, 'numero', 8, 'due_date', '2026-10-05'),
          jsonb_build_object('amount', 133126, 'numero', 9, 'due_date', '2026-11-05'),
          jsonb_build_object('amount', 133126, 'numero', 10, 'due_date', '2026-12-05')
        )
      ),
      'review_note', 'Meta rebuilt from fee + update_cheques review 2026-03-16'
    ),
  updated_at = now()
where id = '211baf57-14f1-46fe-89a9-94d5ebf50af8'::uuid;

-- CARVAJAL: limpiar meta y dejar trazabilidad por series faltantes.
update public.enrollments
set
  meta = coalesce(meta, '{}'::jsonb)
    || jsonb_build_object(
      'forma_pago_cheques', true,
      'forma_pago_pagare', false,
      'forma_pago_transferencia', false,
      'cantidad_cuotas', 10,
      'dia_vencimiento', 5,
      'monto_cuota', 266252,
      'payment_plan', jsonb_build_object(
        'n_cuotas', 10,
        'monto_total', 2662520,
        'payment_method', 'CHEQUE',
        'dia_vencimiento', 5,
        'monto_por_cuota', 266252,
        'primer_vencimiento', '2026-03-05',
        'cuotas', jsonb_build_array(
          jsonb_build_object('amount', 266252, 'numero', 1, 'due_date', '2026-03-05'),
          jsonb_build_object('amount', 266252, 'numero', 2, 'due_date', '2026-04-05'),
          jsonb_build_object('amount', 266252, 'numero', 3, 'due_date', '2026-05-05'),
          jsonb_build_object('amount', 266252, 'numero', 4, 'due_date', '2026-06-05'),
          jsonb_build_object('amount', 266252, 'numero', 5, 'due_date', '2026-07-05'),
          jsonb_build_object('amount', 266252, 'numero', 6, 'due_date', '2026-08-05'),
          jsonb_build_object('amount', 266252, 'numero', 7, 'due_date', '2026-09-05'),
          jsonb_build_object('amount', 266252, 'numero', 8, 'due_date', '2026-10-05'),
          jsonb_build_object('amount', 266252, 'numero', 9, 'due_date', '2026-11-05'),
          jsonb_build_object('amount', 266252, 'numero', 10, 'due_date', '2026-12-05')
        )
      ),
      'review_note', 'Manual resolution 2026-03-16: placeholder cheque sequence 1-10 pending real serials'
    ),
  updated_at = now()
where id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid;

update public.fee
set
  institucion_financiera = 'Banco de Chile',
  notes = concat_ws(' | ', nullif(notes, ''), 'Series reales de cheques pendientes; se usa placeholder numerico 1-10 en public.cheques segun decision manual 2026-03-16')
where enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid
  and coalesce(notes, '') not ilike '%placeholder numerico 1-10%';

-- MATIAS: monto confirmado en 1331260 y serie real pendiente.
update public.enrollments
set
  meta = coalesce(meta, '{}'::jsonb)
    || jsonb_build_object(
      'forma_pago_cheques', true,
      'forma_pago_pagare', false,
      'forma_pago_transferencia', false,
      'cantidad_cuotas', 1,
      'dia_vencimiento', 5,
      'monto_cuota', 1331260,
      'payment_plan', jsonb_build_object(
        'n_cuotas', 1,
        'monto_total', 1331260,
        'payment_method', 'CHEQUE',
        'dia_vencimiento', 5,
        'monto_por_cuota', 1331260,
        'primer_vencimiento', '2026-03-05',
        'cuotas', jsonb_build_array(
          jsonb_build_object('amount', 1331260, 'numero', 1, 'due_date', '2026-03-05')
        )
      ),
      'review_note', 'Manual resolution 2026-03-16: amount fixed at 1331260 and real cheque serial still pending'
    ),
  updated_at = now()
where id = '6599447f-fd35-4d28-99dd-888c99ee2a62'::uuid;

update public.fee
set
  institucion_financiera = 'Santander',
  notes = concat_ws(' | ', nullif(notes, ''), 'Numero de serie real pendiente; se usa placeholder numerico 1 en public.cheques y monto confirmado en 1331260 por decision manual 2026-03-16')
where enrollment_id = '6599447f-fd35-4d28-99dd-888c99ee2a62'::uuid
  and coalesce(notes, '') not ilike '%monto confirmado en 1331260%';

-- ARENAS: el CSV familiar pasa a ser la fuente autoritativa.
update public.enrollments
set
  meta = coalesce(meta, '{}'::jsonb)
    || jsonb_build_object(
      'forma_pago_cheques', true,
      'forma_pago_pagare', false,
      'forma_pago_transferencia', false,
      'cantidad_cuotas', 5,
      'dia_vencimiento', 5,
      'monto_cuota', 651107,
      'payment_plan', jsonb_build_object(
        'n_cuotas', 5,
        'monto_total', 3255535,
        'payment_method', 'CHEQUE',
        'dia_vencimiento', 5,
        'monto_por_cuota', 651107,
        'primer_vencimiento', '2026-03-05',
        'cuotas', jsonb_build_array(
          jsonb_build_object('amount', 651107, 'numero', 1, 'due_date', '2026-03-05'),
          jsonb_build_object('amount', 651107, 'numero', 2, 'due_date', '2026-04-05'),
          jsonb_build_object('amount', 651107, 'numero', 3, 'due_date', '2026-05-05'),
          jsonb_build_object('amount', 651107, 'numero', 4, 'due_date', '2026-06-05'),
          jsonb_build_object('amount', 651107, 'numero', 5, 'due_date', '2026-07-05')
        )
      ),
      'review_note', 'Manual resolution 2026-03-16: CSV familiar taken as authoritative for cheque load'
    ),
  updated_at = now()
where id = '626d645e-351b-4860-b9ae-1ec51e296686'::uuid;

update public.fee
set
  institucion_financiera = 'Banco de Chile',
  notes = concat_ws(' | ', nullif(notes, ''), 'CSV familiar Winterhill tomado como fuente autoritativa: 5 cheques familiares x 651107 (decision manual 2026-03-16)')
where enrollment_id = '626d645e-351b-4860-b9ae-1ec51e296686'::uuid
  and coalesce(notes, '') not ilike '%CSV familiar Winterhill tomado como fuente autoritativa%';

update public.fee f
set
  amount = 239627,
  notes = concat_ws(' | ', nullif(f.notes, ''), 'Monto ajustado a 239627 para cuadrar el acuerdo familiar del CSV y el descuento implicito del enrollment (decision manual 2026-03-16)')
from public.students s
where f.student_id = s.id
  and f.enrollment_id = '626d645e-351b-4860-b9ae-1ec51e296686'::uuid
  and s.whole_name = 'OCTAVIO ANDRES ARENAS LANDEROS'
  and f.amount <> 239627;

-- Inserciones bloqueadas originalmente.
-- CARVAJAL
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '1', 'Banco de Chile', '2026-03-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 1, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '2', 'Banco de Chile', '2026-04-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 2, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '3', 'Banco de Chile', '2026-05-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 3, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '4', 'Banco de Chile', '2026-06-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 4, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '5', 'Banco de Chile', '2026-07-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 5, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 5
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '6', 'Banco de Chile', '2026-08-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 6, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 6
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '7', 'Banco de Chile', '2026-09-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 7, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 7
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '8', 'Banco de Chile', '2026-10-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 8, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 8
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '9', 'Banco de Chile', '2026-11-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 9, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 9
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid, '10', 'Banco de Chile', '2026-12-05'::date, 266252, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 29, 30; placeholder numerico 1-10 por falta de series reales', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 10, 'ENR-2026-000326'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '0fd48c9a-ea48-406e-96ae-a08e633b689b'::uuid and c.numero_cuota = 10
);

-- ARENAS
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '626d645e-351b-4860-b9ae-1ec51e296686'::uuid, '3662644', 'Banco de Chile', '2026-03-05'::date, 651107, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 23, 24, 25; CSV familiar tomado como fuente autoritativa', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 1, 'ENR-2026-000365'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '626d645e-351b-4860-b9ae-1ec51e296686'::uuid and c.numero_cuota = 1
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '626d645e-351b-4860-b9ae-1ec51e296686'::uuid, '3662645', 'Banco de Chile', '2026-04-05'::date, 651107, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 23, 24, 25; CSV familiar tomado como fuente autoritativa', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 2, 'ENR-2026-000365'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '626d645e-351b-4860-b9ae-1ec51e296686'::uuid and c.numero_cuota = 2
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '626d645e-351b-4860-b9ae-1ec51e296686'::uuid, '3662646', 'Banco de Chile', '2026-05-05'::date, 651107, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 23, 24, 25; CSV familiar tomado como fuente autoritativa', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 3, 'ENR-2026-000365'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '626d645e-351b-4860-b9ae-1ec51e296686'::uuid and c.numero_cuota = 3
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '626d645e-351b-4860-b9ae-1ec51e296686'::uuid, '3662647', 'Banco de Chile', '2026-06-05'::date, 651107, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 23, 24, 25; CSV familiar tomado como fuente autoritativa', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 4, 'ENR-2026-000365'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '626d645e-351b-4860-b9ae-1ec51e296686'::uuid and c.numero_cuota = 4
);

insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '626d645e-351b-4860-b9ae-1ec51e296686'::uuid, '3662648', 'Banco de Chile', '2026-07-05'::date, 651107, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 23, 24, 25; CSV familiar tomado como fuente autoritativa', 'cca2d2ee-dffd-4ba2-9e87-0825730e00ce'::uuid, 5, 'ENR-2026-000365'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '626d645e-351b-4860-b9ae-1ec51e296686'::uuid and c.numero_cuota = 5
);

-- MATIAS
insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)
select '6599447f-fd35-4d28-99dd-888c99ee2a62'::uuid, '1', 'Santander', '2026-03-05'::date, 1331260, 'pendiente', 'Carga manual 2026-03-16 desde update_cheques.csv fila(s) 44; placeholder numerico 1 por falta de serie real; monto confirmado en 1331260', '23daf698-8cfb-4697-ad90-1966c4e4de0a'::uuid, 1, 'ENR-2026-000239'
where not exists (
  select 1 from public.cheques c where c.enrollment_id = '6599447f-fd35-4d28-99dd-888c99ee2a62'::uuid and c.numero_cuota = 1
);

commit;