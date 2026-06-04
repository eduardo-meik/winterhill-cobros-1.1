# Carga propuesta de cheques faltantes 2026

- Enrollments faltantes detectados: 30
- Enrollments con SQL generado: 30
- Cheques a insertar: 279
- Enrollments con series placeholder: 2
- Enrollments omitidos por conflicto: 0

## Placeholders requeridos

- 0fd48c9a-ea48-406e-96ae-a08e633b689b | ENR-2026-000326 | filas 29, 30 | DANAE AMELIE CARVAJAL GUTIERREZ | LEONARDO MANUEL CARVAJAL GUTIERREZ
  - series_csv: 2124264-257-258-259-260-261-2632072834-35-36-
  - issues: series_count_mismatch:9->10, placeholder_serials_generated
  - conclusion: no hay forma confiable de reconstruir la serie completa solo con el repo; este enrollment debe quedar fuera de la carga automatica hasta revisar el documento fuente o imagen de cheques.
- 6599447f-fd35-4d28-99dd-888c99ee2a62 | ENR-2026-000239 | filas 44 | MATIAS ANKATU CASTRO CORREA
  - series_csv: solo un cheque
  - issues: series_without_digits, placeholder_serials_generated
  - conclusion: el repo confirma 1 cheque por el total (`update_20260316.csv` y `docs/ANALISIS_SIGE_2026.md`), pero no existe numero de serie. Se puede cargar solo si se acepta placeholder controlado o si se obtiene el numero real.

## Revision de meta antes de cargar

- 211baf57-14f1-46fe-89a9-94d5ebf50af8 | LUCAS IGNACIO ROSSI GONZALEZ
  - hallazgo: el enrollment fue reparado desde CSV y quedo con `meta` minimo (`sync_reason = csv_truth_enrollment_repair`), sin `folio` ni flags de pago.
  - evidencia: `fee` 2026 ya tiene 10 filas por `133126`, `payment_method = CHEQUE`, y el CSV trae 10 cheques Scotiabank con series parseables.
  - conclusion: es candidato seguro para reconstruir `meta` de cheque antes o junto con la carga.
- 626d645e-351b-4860-b9ae-1ec51e296686 | familia ARENAS LANDEROS
  - hallazgo: no es solo un problema de flag. `meta` actual dice `forma_pago_pagare = true`, `forma_pago_cheques = false`, `payment_plan` en 10 cuotas y monto por cuota inconsistente; `fee` ya esta en `CHEQUE` y el CSV habla de 5 cheques por `651107`.
  - evidencia adicional: `docs/ANALISIS_SIGE_2026.md` lo describe como caso anomalo y menciona pagaré en programa.
  - conclusion: este enrollment no debe cargarse ni corregirse en `meta` automaticamente hasta revisar el respaldo fuente.

## Hallazgos para resolucion manual

- `CARVAJAL` | `0fd48c9a-ea48-406e-96ae-a08e633b689b`
  - el monto si cierra: `10 x 266252 = 2662520`, exactamente igual a las 20 filas de `fee` ya existentes (`10 x 133126` por cada alumno).
  - el bloqueo real no es el monto sino la serie: el texto `2124264-257-258-259-260-261-2632072834-35-36-` no permite reconstruir 10 numeros de serie confiables.
  - ademas `meta` quedo mezclado (`forma_pago_cheques = true` y `forma_pago_pagare = true`), pero eso se puede corregir despues de confirmar la serie real.
  - criterio operativo: este caso se puede destrabar apenas se obtengan los 10 numeros de serie correctos desde el documento fuente.
- `MATIAS CASTRO` | `6599447f-fd35-4d28-99dd-888c99ee2a62`
  - hoy hay un desfase de monto entre fuentes: `update_cheques.csv` trae `1334760`, mientras `update_20260316.csv`, `docs/ANALISIS_SIGE_2026.md` y `fee` estan en `1331260`.
  - la diferencia es `3500`, que coincide con `monto_matricula = 3500` en `meta`.
  - conclusion: faltan dos definiciones manuales antes de cargar: el numero de serie real y si el cheque unico debe registrarse por `1331260` o por `1334760` incluyendo matricula.
- `ARENAS LANDEROS` | `626d645e-351b-4860-b9ae-1ec51e296686`
  - el CSV familiar dice `5 x 651107 = 3255535`.
  - el `fee` actual suma `3388660` (`5 x 205740`, `5 x 205740`, `5 x 266252`).
  - la diferencia es `133125`, practicamente el mismo descuento de `133126` que aparece en `meta` para OCTAVIO.
  - lectura mas probable: el CSV refleja un acuerdo familiar con descuento, pero `fee` hoy refleja los montos por alumno sin consolidar ese descuento en la distribucion final.
  - criterio operativo: no cargar cheques aqui hasta definir cual fuente manda, porque insertar `5 x 651107` consolidaria una logica distinta de la que hoy tiene `fee`.

## Decision operativa sugerida

- Listos para seguir: mantener en el SQL automatico los casos normales y `LUCAS ROSSI`.
- Resueltos por decision manual del 2026-03-16:
  - `CARVAJAL`: placeholder numerico `1..10` y nota en `fee` por series reales pendientes.
  - `MATIAS CASTRO`: monto final `1331260`, placeholder numerico `1` y nota en `fee` por serie real pendiente.
  - `ARENAS LANDEROS`: el CSV familiar pasa a ser la fuente autoritativa y se ajusta `fee` para cuadrar el total familiar.
- SQL operativo generado: `tmp_resolve_blocked_cheque_cases_20260316.sql`.
- SQL operativo ejecutado en BD el 2026-03-16.

## Archivos

- tmp_insert_missing_cheques_20260316.sql
- tmp_insert_missing_cheques_20260316_summary.json

## Ejecucion de la carga segura restante

- El 2026-03-16 se ejecuto `tmp_insert_missing_cheques_20260316_ready.sql` en lotes por enrollment mediante la Management API de Supabase.
- La ejecucion efectiva cubrio `27` enrollments seguros adicionales, equivalentes a `263` cheques, porque los `3` casos previamente bloqueados (`CARVAJAL`, `MATIAS`, `ARENAS`) ya habian sido resueltos y ejecutados aparte en `tmp_resolve_blocked_cheque_cases_20260316.sql`.
- Tambien se ejecuto backfill de `fee.institucion_financiera` desde `cheques` para enrollments con un unico banco consistente.
- Resultado aplicado en `fee`: `314` filas actualizadas con banco.

## Estado final 2026 despues de la carga

- Universo 2026 con indicador de cheque en `meta`: `40` enrollments.
- Enrollments 2026 con `cheques` ya cargados: `38`.
- Enrollments 2026 aun sin `cheques`: `2`.
- Filas totales en `public.cheques` para ese universo 2026: `359`.
- Filas `fee 2026` con `institucion_financiera` pendiente para enrollments que ya tienen `cheques`: `0`.
- No quedaron registros con banco mojibake `ItaÃº` en `public.cheques`.

## Pendientes reales despues de la carga

- `794a4776-1e12-40c8-b8d6-1e8f0441ed45` | `ENR-2026-000234` | `MIGUEL ESTEBAN VICUÑA PÉREZ`
  - sigue sin `cheques` en BD.
  - tiene `1` fila en `fee 2026`.
- `fa19b9ee-9765-487f-b052-b96d8ca2828f` | `ENR-2026-000403` | `FLORENCIA AYALÉN TERUEL`
  - sigue sin `cheques` en BD.
  - tiene `10` filas en `fee 2026`.

- Ambos quedaron fuera del universo efectivamente cargado y requieren revision puntual de fuente o de `meta` antes de preparar un nuevo SQL de insercion.
