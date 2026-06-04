# Plan de correcciones concretas: cheques conflictivos

Fecha: 2026-03-16
Base: contraste entre `update_cheques.csv` y la tabla `cheques`

## Criterio

- Si BD y CSV coinciden en cantidad y monto, pero la diferencia es solo de formato, conviene corregir el insumo CSV o normalizar la comparacion, no regrabar BD.
- Si BD contiene duplicados o contaminacion evidente, la correccion debe hacerse en BD.
- Si el caso mezcla problemas de identidad, monto y series, no conviene automatizar sin revisar el documento fuente.

## Estado actual del cruce

- El CSV ya quedo absorbido completamente por el matching: 50 de 50 filas con match a matricula 2026.
- No quedan matriculas con cheques en BD fuera de la cobertura del CSV.
- Hay 11 filas del CSV que hoy apuntan a matriculas con cheques reales en BD.
- De esas 11, solo 1 esta completamente consistente: `DANIELA IBARRA BARRIENTOS`.
- Las otras 10 filas conflictivas se agrupan en 9 casos operativos, que son los que se detallan abajo.

## Correcciones propuestas

### 1. ARANZA LARIOS GUTIERREZ

- Estado: ejecutado en BD el 2026-03-16.

- Matricula: `7d46e5e0-fc62-45c0-98e0-93b57685fbe0`
- Situacion:
  - CSV dice 10 cheques con series `4882627` a `4882636`.
  - BD tiene 30 registros, todos por `133126`, repartidos en 3 series paralelas por cada cuota:
    - serie valida: `4882627` a `4882636`
    - serie extra 1: `4884627` a `4884636`
    - serie extra 2: `39939814882627` a `39939814882636`
- Propuesta concreta:
  - Limpiar BD y dejar solo la serie que coincide exactamente con CSV: `4882627` a `4882636`.
  - Eliminar o archivar 20 registros extra antes de cualquier reproceso.
  - No tocar CSV.
- Resultado aplicado:
  - Se eliminaron 20 registros extra.
  - La matricula quedo con 10 cheques, series `4882627` a `4882636`, todos por `133126`.
- Confianza: alta.
- Riesgo: bajo, porque la serie valida existe completa en BD y coincide con el CSV cuota por cuota.

### 2. MATILDE CAMPUSANO

- Estado: ejecutado en BD el 2026-03-16.

- Matricula: `2ec341e5-2b9d-4cad-81fc-9ac883a724ed`
- Situacion:
  - CSV tiene 10 cheques, valor `134260`, series `000001` a `000010`.
  - BD debe quedar consolidada con series equivalentes `01` a `10` y monto uniforme por cuota.
  - Monto objetivo consolidado: cuota 1 a 10 en `133126`.
- Propuesta concreta:
  - No corregir series: son equivalentes por formato.
  - Corregir BD en montos para dejar las 10 cuotas iguales en `133126`.
  - Tomar `133126` como valor operativo consolidado para el paso posterior a `fee` 2026.
- Resultado aplicado:
  - Las 10 cuotas quedaron uniformadas en `133126`.
  - Las series `01` a `10` se mantuvieron sin cambios.
- Confianza: media.

### 3. MAGDALENA SALAZAR CORNEJO y BENJAMIN SALAZAR CORNEJO

- Estado: ejecutado en BD el 2026-03-16.

- Matricula usada por el matching: `1dd277d2-6373-48a5-b8a1-16e5a4d5014a`
- Situacion:
  - El CSV trae dos filas del mismo grupo familiar: `MAGDALENA SALAZAR CORNEJO` y `BENJAMIN SALAZAR CORNEJO`.
  - Ambas dicen banco `ESTADO`, valor `235996` y una lista de series malformada alrededor de `2271011`.
  - BD tiene 10 cheques en `BancoEstado` con series `2278607` a `2278616`.
  - Corresponde al mismo set de cheques usado para cubrir los montos de ambos hermanos.
- Propuesta concreta:
  - Aplicar las mismas cuotas, las mismas series y el mismo banco para ambos registros.
  - Consolidar los montos por alumno de la siguiente forma:
    - `MAGDALENA SALAZAR CORNEJO` -> `102870`
    - `BENJAMIN SALAZAR CORNEJO` -> `133126`
  - Normalizar el banco a `BancoEstado` o `ESTADO` segun el catalogo elegido.
  - Mantener como series correctas `2278607` a `2278616`.
- Resultado aplicado:
  - En `cheques` quedaron 10 cuotas en `BancoEstado`, con series `2278607` a `2278616`, todas por `102870`.
  - En `fee` se mantuvo la separacion por alumno sin duplicar cheques:
    - `MAGDALENA LEONOR SALAZAR CORNEJO`: 10 cuotas de `102870`
    - `BENJAMIN ARTURO SALAZAR CORNEJO`: 10 cuotas de `133126`
  - En `fee` se normalizo `institucion_financiera = BancoEstado` para ambos alumnos.
  - En `update_cheques.csv` se normalizo el banco a `BANCOESTADO`, se corrigieron las series a `2278607` a `2278616` y se ajustaron los valores a `102870` para MAGDALENA y `133126` para BENJAMIN.
- Confianza: media.

### 4. ALONSO TOMAS MARTORI COVARRUBIAS

- Estado: validado sin cambios el 2026-03-16.

- Matricula: `05d4264e-b81e-4b4f-a8e2-3e873ebdc833`
- Situacion:
  - CSV dice 10 cheques por `133826`.
  - BD tiene 10 cheques por `133126`.
  - Banco y cantidad coinciden; el conflicto es solo de monto.
- Propuesta concreta:
  - No hacer cambios en BD.
  - Corregir el CSV para dejar `133126` como valor correcto.
- Resultado aplicado:
  - `update_cheques.csv` quedo corregido a `133126`.
- Confianza: media.
- Riesgo: medio, porque el diferencial de monto sigue existiendo si luego se consolida a `fee` 2026 sin nueva validacion.

### 5. ALVARO MEDINA FIGUEROA

- Estado: corregido en CSV el 2026-03-16.

- Matricula: `0a35a2ef-a9c2-4008-9352-6f0ec09ac582`
- Situacion:
  - CSV dice `10` cheques.
  - CSV lista 11 series: `0000012` a `0000022`, incluyendo `0000016`.
  - BD tiene 10 cheques, todos por `133126`, con series `12,13,14,15,17,18,19,20,21,22`.
- Propuesta concreta:
  - No tocar BD por ahora.
  - Corregir el insumo operativo para que la serie quede consistente con 10 cheques: `12,13,14,15,17,18,19,20,21,22`.
  - Marcar `0000016` como error de digitacion en CSV.
- Resultado aplicado:
  - `update_cheques.csv` quedo con la serie `0000012-13-14-15-17-18-19-20-21-22`.
- Confianza: media.
- Riesgo: si el documento fuente realmente tiene 11 cheques, entonces la BD estaria incompleta.

### 6. AMPARO VILCHES

- Estado: corregido en CSV el 2026-03-16.

- Matricula: `ba39cf44-16b7-4e94-86da-f38282845904`
- Situacion:
  - CSV dice `10` cheques, pero solo enumera 9 series: `0000037` a `0000045`.
  - BD tiene 10 cheques, todos por `102870`, con series `0000036` a `0000045`.
- Propuesta concreta:
  - Corregir el CSV/insumo manual agregando la serie faltante `0000036`.
  - Serie corregida esperada: `0000036-37-38-39-40-41-42-43-44-45`.
  - Mantener BD como esta.
- Resultado aplicado:
  - `update_cheques.csv` quedo con la serie `0000036-37-38-39-40-41-42-43-44-45`.
- Confianza: alta.

### 7. LORETO RIOS CHAVEZ

- Estado: corregido en CSV el 2026-03-16.

- Matricula: `e55c3cd1-6202-4bb2-9101-120f353fe238`
- Situacion:
  - CSV tiene 9 series parseables y el final esta mal unido como `003435`.
  - BD tiene 10 cheques por `102870` con series `hco0000026` a `hco0000035`.
  - Banco y monto coinciden.
- Propuesta concreta:
  - Mantener BD.
  - Corregir el CSV o insumo manual a una secuencia de 10 series:
    - `000026-27-28-29-30-31-32-33-34-35`
  - En futuras comparaciones, normalizar quitando el prefijo `hco` para evitar falso positivo.
- Resultado aplicado:
  - `update_cheques.csv` quedo con la serie `000026-27-28-29-30-31-32-33-34-35`.
- Confianza: alta.

### 8. ANTONELLA PAZ NAVARRO AVILES

- Estado: corregido en CSV el 2026-03-16.

- Matricula: `a3e1b488-8df0-4d03-9da7-452de10c810f`
- Situacion:
  - CSV trae banco `SEGURITY`.
  - BD trae banco `SECURITY`.
  - Monto, cantidad y cobertura de cheques coinciden.
- Propuesta concreta:
  - Corregir el CSV a `SECURITY`.
  - Alternativamente, implementar un normalizador de catalogo bancario para absorber errores ortograficos previsibles.
  - No tocar BD.
- Resultado aplicado:
  - `update_cheques.csv` quedo con banco `SECURITY`.
- Confianza: alta.

### 9. HELENA SEPULVEDA OJEDA

- Matricula: `712b7e35-7965-4fd8-bdd7-e061c0a381df`
- Situacion:
  - CSV trae banco `CHILE`.
  - BD trae `BANCO DE CHILE`.
  - Monto, cantidad y cobertura coinciden.
- Propuesta concreta:
  - No tocar ni CSV ni BD si se define una normalizacion de catalogo bancario que equipare `CHILE` con `BANCO DE CHILE`.
  - Si se prefiere dato literal estandarizado, corregir el CSV a `BANCO DE CHILE`.
  - No es un caso bloqueante para fee 2026.
- Confianza: alta.

## Prioridad sugerida

1. ARANZA LARIOS GUTIERREZ: limpiar duplicados o contaminacion en BD.
2. MATILDE CAMPUSANO: revisar y corregir montos en BD.
3. MAGDALENA/BENJAMIN: aplicar mismo banco y series, con monto diferenciado por alumno.
4. ALONSO TOMAS MARTORI COVARRUBIAS: mantener sin cambios por ahora.
5. ALVARO MEDINA FIGUEROA: validar si `16` es error de digitacion o cheque faltante.
6. AMPARO VILCHES: corregir serie faltante en CSV.
7. LORETO RIOS CHAVEZ: corregir typo final y normalizar comparacion de prefijo.
8. ANTONELLA PAZ NAVARRO AVILES: corregir spelling del banco en CSV.
9. HELENA SEPULVEDA OJEDA: resolver por catalogo bancario o estandarizacion literal.

## Nota operativa para fee 2026

- Los casos 1 a 4 son los que realmente pueden contaminar la consolidacion hacia `fee` 2026, porque afectan duplicacion en BD o monto por cuota.
- Los casos 5 a 9 son principalmente de calidad de insumo o normalizacion y pueden resolverse antes o durante la preparacion del import.
- Mientras no se carguen en `cheques` los otros 39 casos del CSV que hoy no existen en BD, el universo de cheques consolidados sigue incompleto para poblar `fee` 2026 desde esta fuente.

## Decisiones manuales incorporadas

- `MATILDE CAMPUSANO`: se toma `133126` como monto uniforme objetivo por cuota.
- `MAGDALENA SALAZAR CORNEJO`: se consolida con monto `102870`.
- `BENJAMIN SALAZAR CORNEJO`: se consolida con monto `133126`.
- `ALONSO TOMAS MARTORI COVARRUBIAS`: se mantiene sin cambios por ahora.

- `ALVARO MEDINA FIGUEROA`: el cheque `0000016` se considera inexistente y debe corregirse solo en CSV.
- `ANTONELLA PAZ NAVARRO AVILES`: el banco debe corregirse literal a `SECURITY` en el CSV.
- `HELENA SEPULVEDA OJEDA`: `CHILE` y `BANCO DE CHILE` se consideran equivalentes; no requiere cambio en BD.

## Revision manual previa a la carga automatica restante

### 10. CARVAJAL GUTIERREZ

- Estado: ejecutado en BD el 2026-03-16.

- Matricula: `0fd48c9a-ea48-406e-96ae-a08e633b689b`
- Situacion:
  - `update_cheques.csv` trae 10 cheques por `266252` para dos alumnos, pero la serie viene corrupta: `2124264-257-258-259-260-261-2632072834-35-36-`.
  - El monto es coherente con la distribucion ya cargada en `fee`: 20 filas de `133126` (`10` por cada alumno), total `2662520`.
  - El enrollment quedo con `forma_pago_cheques = true` y `forma_pago_pagare = true`, por lo que la matricula tambien requiere limpieza de `meta` una vez resuelta la serie.
- Decision manual adoptada:
  - Usar placeholder numerico `1` a `10` en `cheques`.
  - Agregar en `fee.notes` que faltan las series reales de los cheques.
- Criterio operativo:
  - Se asume que el monto ya esta resuelto y que la unica deuda documental es la serie real.
  - SQL preparado en `tmp_resolve_blocked_cheque_cases_20260316.sql`.

### 11. MATIAS ANKATU CASTRO CORREA

- Estado: ejecutado en BD el 2026-03-16.

- Matricula: `6599447f-fd35-4d28-99dd-888c99ee2a62`
- Situacion:
  - `update_cheques.csv` dice `1` cheque Santander por `1334760`, con texto `solo un cheque` en vez de numero de serie.
  - `update_20260316.csv`, `docs/ANALISIS_SIGE_2026.md` y `fee` apuntan a `1` cuota por `1331260`.
  - La diferencia es `3500`, igual a `monto_matricula = 3500` presente en `meta`.
- Decision manual adoptada:
  - Tomar `1331260` como monto correcto.
  - Mantener placeholder numerico `1` mientras no aparezca la serie real.
  - Agregar trazabilidad en `fee.notes`.
- Criterio operativo:
  - La discrepancia de `3500` se interpreta como ruido entre colegiatura y matricula, y no bloquea la carga.
  - SQL preparado en `tmp_resolve_blocked_cheque_cases_20260316.sql`.

### 12. FAMILIA ARENAS LANDEROS

- Estado: ejecutado en BD el 2026-03-16.

- Matricula: `626d645e-351b-4860-b9ae-1ec51e296686`
- Situacion:
  - `update_cheques.csv` trae `5` cheques por `651107` para los tres alumnos de la familia.
  - `fee` actual esta distribuido como `5 x 205740` para ELOISA, `5 x 205740` para DANTE y `5 x 266252` para OCTAVIO, total `3388660`.
  - El CSV totaliza `3255535`; la diferencia con `fee` es `133125`, practicamente el mismo descuento de `133126` que figura en `meta` para OCTAVIO.
  - `docs/ANALISIS_SIGE_2026.md` ya lo dejaba marcado como acuerdo especial en 5 cuotas y con pagaré anomalo en programa.
- Lectura operativa:
  - Se toma el CSV familiar como fuente autoritativa.
  - Para cuadrar ese total, OCTAVIO debe bajar de `266252` a `239627` por cuota en `fee`.
- Decision manual adoptada:
  - Cargar `5` cheques familiares por `651107`.
  - Reescribir el `payment_plan` del enrollment en `meta` a `5` cuotas `CHEQUE`.
  - Ajustar `fee` para que el total del grupo cuadre con el CSV familiar.
- Criterio operativo:
  - SQL preparado en `tmp_resolve_blocked_cheque_cases_20260316.sql`.

## Ejecucion adicional sobre bloqueados resueltos

- Se ejecuto `tmp_resolve_blocked_cheque_cases_20260316.sql` sobre BD.
- Resultado verificado:
  - `CARVAJAL` (`ENR-2026-000326`):
    - `meta` quedo en `CHEQUE`, `10` cuotas por `266252`, total `2662520`.
    - se insertaron `10` cheques con series placeholder `1` a `10`.
    - `fee.institucion_financiera` quedo en `Banco de Chile` y `fee.notes` registra que faltan las series reales.
  - `MATIAS` (`ENR-2026-000239`):
    - `meta` quedo en `CHEQUE`, `1` cuota por `1331260`, total `1331260`.
    - se inserto `1` cheque con serie placeholder `1`.
    - `fee.institucion_financiera` quedo en `Santander` y `fee.notes` registra que falta la serie real.
  - `ARENAS LANDEROS` (`ENR-2026-000365`):
    - `meta` quedo en `CHEQUE`, `5` cuotas por `651107`, total `3255535`.
    - se insertaron `5` cheques con series `3662644` a `3662648`.
    - `fee` se alineo con el CSV familiar: DANTE `1028700`, ELOISA `1028700`, OCTAVIO `1198135`.
    - `fee.institucion_financiera` quedo en `Banco de Chile` y `fee.notes` registra que el CSV familiar fue tomado como fuente autoritativa.
  - `LUCAS ROSSI`:
    - se reconstruyo `meta` como pago por `CHEQUE` con `10` cuotas de `133126`.

## Ejecucion realizada en BD

- Se ejecuto correccion SQL sobre `ARANZA LARIOS GUTIERREZ`, `MATILDE CAMPUSANO` y `MAGDALENA/BENJAMIN`.
- Resultado verificado:
  - `ARANZA`: 10 cheques finales, todos por `133126`, series `4882627` a `4882636`.
  - `MATILDE`: 10 cheques finales, todos por `133126`, series `01` a `10`.
  - `MAGDALENA/BENJAMIN`: cheques en `BancoEstado` con series `2278607` a `2278616`; `fee` diferenciado por alumno (`102870` y `133126`).

## Validacion posterior sobre fee 2026

- Se reejecuto el cruce con el CSV corregido.
- Resultado general del cruce:
  - `matched_rows = 50`
  - `rows_full_match = 6`
  - `bank_mismatches = 1`
  - `amount_mismatches = 1`
- Validacion sobre las 10 matriculas con cheques reales en BD:
  - Inicialmente se detecto 1 matricula inconsistente en `fee`: `7273117b-4ffe-4e7d-9929-7ef27d08bd19` (`DANIELA IGNACIA IBARRA BARRIENTOS`).
  - El problema consistia en 20 filas en `fee` para 10 cheques y 1 alumna, con duplicacion por cuota:
    - una fila `paid` por `128532`
    - una fila `pending` por `133126`
- Observacion operativa:
  - Inicialmente, en 9 de las 10 matriculas con cheques, `fee.institucion_financiera` estaba en `NULL`.

## Ejecucion adicional en fee 2026

- Se eliminaron 10 filas absurdas de `fee` para `DANIELA IGNACIA IBARRA BARRIENTOS` asociadas al enrollment `7273117b-4ffe-4e7d-9929-7ef27d08bd19`.
- Criterio aplicado:
  - se borraron solo las filas `paid` por `128532`, con `due_date` en 2025 y `meta.source = finalize_enrollment`.
  - se mantuvieron las 10 filas `pending` 2026 por `133126`, que son las consistentes con `cheques` y con el CSV corregido.
- Se ejecuto backfill de `institucion_financiera` en `fee` desde `cheques` para enrollments con un unico banco consistente.
- Resultado aplicado:
  - `DANIELA`: quedo con 10 cuotas `pending`, todas por `133126`, con `institucion_financiera = Santander`.
  - Se actualizaron 90 filas de `fee` con el banco proveniente de `cheques`.
  - Las 10 matriculas con cheques reales en BD quedaron con cantidad de filas `fee` consistente con lo esperado segun alumnos x cuotas.
  - Las 10 matriculas con cheques reales en BD quedaron con `institucion_financiera` poblada en `fee`.

## Diagnostico final y carga propuesta de faltantes

- Se genero un SQL idempotente para insertar los `cheques` faltantes detectados desde el cruce entre `update_cheques.csv` y BD.
- Archivos generados:
  - `tmp_generate_missing_cheques_sql_20260316.ps1`
  - `tmp_insert_missing_cheques_20260316.sql`
  - `tmp_insert_missing_cheques_20260316_summary.json`
  - `tmp_insert_missing_cheques_20260316_review.md`
- Resultado del generador:
  - `30` enrollments faltantes detectados desde el CSV.
  - `279` cheques a insertar.
  - `0` enrollments omitidos por conflicto.
  - `2` enrollments quedaron con series placeholder, porque el CSV no permite reconstruir una secuencia confiable:
    - `0fd48c9a-ea48-406e-96ae-a08e633b689b` (`ENR-2026-000326`), filas CSV `29` y `30`.
    - `6599447f-fd35-4d28-99dd-888c99ee2a62` (`ENR-2026-000239`), fila CSV `44`.
- Diagnostico global de `fee 2026` sobre enrollments con `forma_pago_cheques = true`:
  - `39` enrollments en total.
  - `10` con cheques reales ya cargados en BD.
  - `29` sin cheques en BD.
  - `4` con desajuste de cantidad de filas en `fee` respecto de `students_count x expected_cuotas`.
  - `29` con `fee.institucion_financiera` aun vacia, explicado por la ausencia de `cheques`.
  - `0` enrollments con cheques reales y `fee.payment_method` distinto de `CHEQUE`.
- Observacion de consistencia:
  - Hay enrollments matcheados desde el CSV que hoy no tienen `forma_pago_cheques = true` en `meta`, por ejemplo `211baf57-14f1-46fe-89a9-94d5ebf50af8` y `626d645e-351b-4860-b9ae-1ec51e296686`.
  - Antes de usar `fee` como universo final para validar el import, conviene decidir si esos enrollments deben marcarse formalmente como pago por cheque.

## Revision previa a la carga automatica

- `211baf57-14f1-46fe-89a9-94d5ebf50af8` (`LUCAS IGNACIO ROSSI GONZALEZ`):
  - El enrollment tiene `meta` minimo por una reparacion desde CSV, pero `fee` 2026 y `update_cheques.csv` son consistentes con `10` cheques Scotiabank por `133126`.
  - Se considera candidato seguro para reconstruir `meta` como pago por cheque antes o junto con la carga.
- `626d645e-351b-4860-b9ae-1ec51e296686` (familia `ARENAS LANDEROS`):
  - No debe marcarse automaticamente como cheque todavia.
  - `meta` actual indica `PAGARE` y `10` cuotas; `fee` esta en `CHEQUE`; el CSV habla de `5` cheques por `651107`; y `docs/ANALISIS_SIGE_2026.md` lo marca como caso anomalo con pagaré en programa.
  - Requiere revisar documento fuente antes de tocar `meta` o ejecutar la carga en `cheques`.
- Placeholders del SQL generado:
  - `0fd48c9a-ea48-406e-96ae-a08e633b689b` (`CARVAJAL`): serie corrupta, no reconstruible con evidencia suficiente del repo.
  - `6599447f-fd35-4d28-99dd-888c99ee2a62` (`MATIAS ANKATU CASTRO CORREA`): se confirma que es `1` cheque por el total, pero no aparece el numero de serie en las fuentes revisadas.
  - Ambos casos deben quedar fuera de una carga automatica ciega, salvo que se acepte explicitamente usar placeholder temporal en `numero_serie`.

## Ejecucion de la carga automatica restante

- Estado: ejecutada en BD el 2026-03-16.

- Se ejecuto `tmp_insert_missing_cheques_20260316_ready.sql` en lotes por enrollment para evitar el limite de tamano del RPC SQL.
- La ejecucion cubrio `27` enrollments seguros adicionales y `263` cheques.
- Los `3` casos que originalmente estaban fuera de esa carga (`CARVAJAL`, `MATIAS`, `ARENAS`) ya estaban resueltos y ejecutados aparte en `tmp_resolve_blocked_cheque_cases_20260316.sql`.
- Despues de la carga se ejecuto backfill de `fee.institucion_financiera` desde `cheques` para enrollments con banco unico consistente.
- Resultado aplicado en `fee`: `314` filas actualizadas con banco.

## Estado final del universo 2026 con cheque

- Resultado verificado:
  - `40` enrollments 2026 quedaron dentro del universo con indicador de cheque en `meta`.
  - `38` enrollments 2026 tienen `cheques` cargados en BD.
  - `2` enrollments 2026 siguen sin `cheques`.
  - `359` filas totales existen en `public.cheques` para ese universo 2026.
  - `0` filas de `fee 2026` quedaron con `institucion_financiera` pendiente cuando el enrollment ya tiene `cheques`.
  - `0` cheques quedaron con banco mal codificado `ItaÃº`.

## Pendientes residuales despues de la consolidacion

- `794a4776-1e12-40c8-b8d6-1e8f0441ed45` (`ENR-2026-000234`) | `MIGUEL ESTEBAN VICUÑA PÉREZ`
  - sigue sin `cheques` en BD.
  - mantiene `1` fila en `fee 2026`.
- `fa19b9ee-9765-487f-b052-b96d8ca2828f` (`ENR-2026-000403`) | `FLORENCIA AYALÉN TERUEL`
  - sigue sin `cheques` en BD.
  - mantiene `10` filas en `fee 2026`.

- Criterio operativo:
  - la consolidacion principal ya quedo ejecutada.
  - los dos pendientes residuales requieren revision puntual de fuente o de `meta` antes de generar un ultimo SQL complementario.