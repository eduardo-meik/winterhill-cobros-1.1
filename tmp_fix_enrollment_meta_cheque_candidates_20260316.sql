-- Propuesta de reparacion de meta para enrollments revisados antes de cargar cheques.
-- Caso seguro: 211baf57-14f1-46fe-89a9-94d5ebf50af8 (LUCAS IGNACIO ROSSI GONZALEZ)
-- Caso bloqueado: 626d645e-351b-4860-b9ae-1ec51e296686 (ARENAS LANDEROS) requiere documento fuente.

begin;

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

-- No aplicar actualizacion automatica sobre 626d645e-351b-4860-b9ae-1ec51e296686.
-- Ese enrollment tiene conflicto entre meta, fee, CSV y analisis historico.

commit;