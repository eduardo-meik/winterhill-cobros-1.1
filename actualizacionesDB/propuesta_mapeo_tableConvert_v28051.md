# Propuesta de mapeo y revision previa

Archivo analizado: `actualizacionesDB/tableConvert.com_v28051 ultimo.xlsx`

## 1. Que contiene el archivo

- 1 hoja (`Sheet 1`)
- 11 filas de trabajo
- Es un set curado de casos con discrepancias entre:
  - `matricula` = datos guardados en `enrollments.meta`
  - `aranceles` = resumen agregado de registros en `fee`
- Incluye columnas `esperado_*`, por lo que el archivo no solo diagnostica: tambien propone el estado objetivo.

## 2. Mapeo propuesto a base de datos

### Claves de cruce

- `ID Matrícula` -> `enrollments.id`
- `ID Estudiante` -> `students.id` y `fee.student_id`
- `RUT` -> validacion secundaria contra `students.run`
- `Curso` -> validacion secundaria contra `cursos.nom_curso`

### Bloque Matricula

Columnas Excel origen:

- `Matrícula: Forma de Pago`
- `Matrícula: Prioritario`
- `Matrícula: N° Cuotas`
- `Matrícula: Monto por Cuota`
- `Matrícula: Total Anual`

Campos destino sugeridos:

- `enrollments.status` <- `Estado Matrícula`
- `enrollments.meta.payment_method` <- `Matrícula: Forma de Pago`
- `enrollments.meta.prioritario` <- `Matrícula: Prioritario`
- `enrollments.meta.cantidad_cuotas` <- `Matrícula: N° Cuotas`
- `enrollments.meta.monto_cuota` <- `Matrícula: Monto por Cuota`
- `enrollments.meta.ingreso_anual` <- `Matrícula: Total Anual`

### Bloque Aranceles

Columnas Excel origen:

- `Aranceles: N° Cuotas`
- `Aranceles: Forma de Pago`
- `Aranceles: Monto Cuota Mínimo`
- `Aranceles: Monto Cuota Máximo`
- `Aranceles: Total`
- `Aranceles: N° Cuota Mínima`
- `Aranceles: N° Cuota Máxima`

Campos destino sugeridos:

- `fee.enrollment_id` = `ID Matrícula`
- `fee.student_id` = `ID Estudiante`
- `fee.payment_method` <- `Aranceles: Forma de Pago`
- `fee.amount` <- monto por cuota esperado
- `fee.numero_cuota` <- secuencia entre cuota minima y maxima
- `fee.year_academico` / `fee.year` = 2026

Regla operativa para `fee`:

- No conviene actualizar `fee` fila por fila solo con el resumen del Excel.
- Conviene regenerar el set de cuotas del alumno para 2026 cuando el objetivo sea `Copiar matrícula hacia aranceles`.
- Si `Aranceles: N° Cuotas = 1`, generar una sola cuota con `amount = total`.
- Si `Aranceles: N° Cuotas > 1` y `Monto Cuota Mínimo = Monto Cuota Máximo`, generar `N` cuotas uniformes.
- Si el total no coincide exactamente con `N x monto`, definir de antemano si se permite diferencia de redondeo de 1-2 pesos o si se ajusta la ultima cuota.

## 3. Criterio de actualizacion recomendado

- Si `resolucion_sugerida = Copiar aranceles hacia matrícula`:
  - actualizar solo `enrollments.meta`
  - no tocar `fee`
- Si `resolucion_sugerida = Copiar matrícula hacia aranceles`:
  - dejar `enrollments.meta` intacto
  - borrar/recrear `fee` 2026 para ese `enrollment_id` o `student_id`

## 4. Revision previa de calidad del archivo

### Resultado general

- 11 filas en total
- 8 filas apuntan a cambios en `enrollments.meta`
- 3 filas apuntan a cambios en `fee`

### Conteo por issue

- `CUOTAS_DISTINTAS|MONTO_DISTINTO`: 4
- `CUOTAS_DISTINTAS|TOTAL_DISTINTO`: 1
- `CUOTAS_DISTINTAS`: 2
- `MONTO_DISTINTO|TOTAL_DISTINTO`: 2
- `MONTO_DISTINTO`: 1
- `FEE_FALTANTE|CUOTAS_DISTINTAS`: 1

### Conteo por resolucion sugerida

- `Copiar aranceles hacia matrícula`: 8
- `Copiar matrícula hacia aranceles`: 3

## 5. Filas que realmente requieren cambio segun el propio Excel

### A. Actualizar `enrollments.meta`

1. `794a4776-1e12-40c8-b8d6-1e8f0441ed45` - MIGUEL ESTEBAN VICUÑA PEREZ
   - cambiar `meta.cantidad_cuotas`: `10` -> `1`
   - cambiar `meta.monto_cuota`: `133126` -> `1331260`

2. `124f2fcb-ee42-47a1-8e52-180919137c32` - AMANDA FRANCISCA SALINAS VELIZ
   - cambiar `meta.cantidad_cuotas`: `10` -> `9`
   - cambiar `meta.ingreso_anual`: `1331260` -> `1331262`

3. `6599447f-fd35-4d28-99dd-888c99ee2a62` - MATIAS ANKATU CASTRO CORREA
   - cambiar `meta.cantidad_cuotas`: `10` -> `1`
   - cambiar `meta.monto_cuota`: `133126` -> `1331260`

4. `5ad7dbf2-7183-4c93-a9ad-d700bed09ef7` - RENATA EMILIA IRARRAZABAL BASAEZ
   - cambiar `meta.monto_cuota`: `102870` -> `99324`
   - cambiar `meta.ingreso_anual`: `1028700` -> `993240`

5. `68178644-172b-4e34-9d03-d86125492c65` - DAMIAN IGNACIO MIRANDA ALVAREZ
   - cambiar `meta.cantidad_cuotas`: `10` -> `7`

6. `fba5295b-2960-4398-8ed7-ac1f6ab0cedb` - FLORENCIA GALAZ DURAN
   - cambiar `meta.monto_cuota`: `114300` -> `102870`

7. `1715e001-1157-403f-8e86-66e7d5dd97c2` - BASTIAN ANGEL MAICKOLL LOYOLA GRONDONA
   - cambiar `meta.monto_cuota`: `102870` -> `72009`
   - cambiar `meta.ingreso_anual`: `1028700` -> `720090`

### B. Regenerar `fee` 2026

1. `fe495910-415b-4b30-bd6f-c8c216c6a800` - LUCAS MIGUEL CARRENO SOTO
   - regenerar 10 cuotas para 2026
   - `payment_method` esperado: `PRIORITARIO`
   - monto esperado: `0`
   - total esperado: `0`

## 6. Filas que el Excel marca, pero no muestran cambio real en el lado objetivo

Estas filas vienen con `resolucion_sugerida`, pero al comparar el lado objetivo con las columnas `esperado_*`, no aparece diferencia efectiva:

1. `9755e5d1-e54f-4443-884b-721219622d77` - VIOLETA BEATRIZ GUERRERO BIRKE
   - resolucion: `Copiar aranceles hacia matrícula`
   - observacion: el objetivo ya coincide con el esperado

2. `74f62c36-655c-4b9b-b772-f6b68db41b32` - AMANDA AYELEN PAREDES RIOS
   - resolucion: `Copiar matrícula hacia aranceles`
   - observacion: el objetivo ya coincide con el esperado segun este Excel

3. `b586387a-9d35-40d6-8970-8310b2aafa5a` - RAMIRO PASCUAL FUENZALIDA ANDRADE
   - resolucion: `Copiar matrícula hacia aranceles`
   - observacion: el objetivo ya coincide con el esperado segun este Excel

## 7. Riesgos e inconsistencias detectadas

1. Hay conflicto entre este Excel y snapshots historicos del repo.
   - En `reporte_matriculados_forma_pago_vs_aranceles_2026_20260408 copy_11_casos_con_esperados.csv`, Amanda y Ramiro aparecen con `SIN_FEE` y efectivamente requerian crear aranceles.
   - En este Excel, esas mismas filas ya no muestran diferencia efectiva en el lado `aranceles`.
   - Antes de actualizar produccion, hay que validar contra la BD actual y decidir si el Excel del cliente reemplaza el snapshot historico.

2. La fila de LUCAS MIGUEL CARRENO SOTO trae una inconsistencia de calidad.
   - `Matrícula: Forma de Pago = PRIORITARIO`
   - `Matrícula: Prioritario = false`
   - `esperado_aranceles_forma_pago = PRIORITORIO` (typo)
   - Recomendacion: normalizar a `PRIORITARIO` y confirmar si `meta.prioritario` debe quedar `true`.

3. No hay una columna explicita de `esperado_matricula_prioritario` ni `esperado_aranceles_prioritario`.
   - Para la propuesta se infirio `prioritario = true` cuando la forma de pago esperada es `PRIORITARIO`.
   - Conviene confirmarlo con el cliente antes de una carga masiva.

4. El bloque `aranceles` es agregado, no detalle por cuota.
   - El Excel no define fechas de vencimiento.
   - Si se recrean cuotas, hay que usar la logica existente del sistema para `due_date`.

## 8. Propuesta operativa antes de ejecutar cambios

1. Validar en BD actual los 11 `enrollment_id` del Excel.
2. Separar en dos lotes:
   - lote A: 7 updates sobre `enrollments.meta`
   - lote B: 1 regeneracion de `fee` 2026 segura
3. Dejar fuera temporalmente 3 filas ambiguas:
   - VIOLETA BEATRIZ GUERRERO BIRKE
   - AMANDA AYELEN PAREDES RIOS
   - RAMIRO PASCUAL FUENZALIDA ANDRADE
4. Confirmar con el cliente la fila de LUCAS MIGUEL CARRENO SOTO por el typo `PRIORITORIO` y por la contradiccion con `prioritario=false`.

## 9. SQL/logica sugerida

- Para `enrollments.meta`: `jsonb_set` sobre `payment_method`, `cantidad_cuotas`, `monto_cuota`, `ingreso_anual`, `prioritario`.
- Para `fee`: borrar cuotas 2026 del `enrollment_id` objetivo y recrearlas de forma deterministica.
- Siempre respaldar antes con `SELECT ... FOR UPDATE` o export previo por `enrollment_id`.

## 10. Conclusion

Con este Excel, la propuesta conservadora es:

- ejecutar 7 actualizaciones directas en `enrollments.meta`
- ejecutar 1 regeneracion de `fee`
- dejar 3 filas en validacion previa por inconsistencia entre este Excel y snapshots historicos

No recomiendo aplicar las 11 filas en bloque sin una comprobacion contra la BD actual.

## 11. Revision posterior con CSV manual ajustado por el usuario

El CSV manual recibido despues de esta propuesta reemplaza, para estos 11 casos, la lectura operativa anterior de columnas `esperado_*`.

### Nuevo resultado resumido

- 4 filas no requieren cambio efectivo
- 4 filas requieren cambio solo en `enrollments.meta`
- 2 filas requieren alinear `enrollments.meta` y `fee`
- 1 fila requiere cambio seguro en `enrollments.meta` y validacion puntual del total de `fee`

### A. Sin cambio efectivo

1. `9755e5d1-e54f-4443-884b-721219622d77` - VIOLETA BEATRIZ GUERRERO BIRKE
   - matricula actual = esperado
   - aranceles actual = esperado

2. `74f62c36-655c-4b9b-b772-f6b68db41b32` - AMANDA AYELEN PAREDES RIOS
   - matricula actual = esperado
   - aranceles actual = esperado

3. `b586387a-9d35-40d6-8970-8310b2aafa5a` - RAMIRO PASCUAL FUENZALIDA ANDRADE
   - matricula actual = esperado
   - aranceles actual = esperado

4. `fe495910-415b-4b30-bd6f-c8c216c6a800` - LUCAS MIGUEL CARRENO SOTO
   - matricula actual = esperado (`PRIORITARIO`, `true`, `0`, `0`, `0`)
   - el lado `aranceles` queda en cero y sin cuotas, por lo que no recomiendo recrear `fee`
   - la columna `esperado_aranceles_forma_pago = PRIORITORIO` sigue siendo un typo/noise y no una instruccion accionable

### B. Cambiar solo `enrollments.meta`

1. `5ad7dbf2-7183-4c93-a9ad-d700bed09ef7` - RENATA EMILIA IRARRAZABAL BASAEZ
   - `meta.monto_cuota`: `102870` -> `99324`
   - `meta.ingreso_anual`: `1028700` -> `993240`
   - aranceles ya coinciden con el esperado

2. `68178644-172b-4e34-9d03-d86125492c65` - DAMIAN IGNACIO MIRANDA ALVAREZ
   - `meta.cantidad_cuotas`: `10` -> `7`
   - aranceles ya coinciden con el esperado

3. `fba5295b-2960-4398-8ed7-ac1f6ab0cedb` - FLORENCIA GALAZ DURAN
   - `meta.monto_cuota`: `114300` -> `102870`
   - aranceles ya coinciden con el esperado

4. `1715e001-1157-403f-8e86-66e7d5dd97c2` - BASTIAN ANGEL MAICKOLL LOYOLA GRONDONA
   - `meta.monto_cuota`: `102870` -> `72009`
   - `meta.ingreso_anual`: `1028700` -> `720090`
   - aranceles ya coinciden con el esperado

### C. Cambiar `enrollments.meta` y `fee`

1. `794a4776-1e12-40c8-b8d6-1e8f0441ed45` - MIGUEL ESTEBAN VICUNA PEREZ
   - matricula esperada: `CHEQUE`, `1`, `1331260`, `1331260`
   - arancel esperado: `1` cuota, `CHEQUE`, monto `1331260`, total `1331260`
   - aqui ya no basta con copiar `fee` hacia matricula: ambos lados deben converger al nuevo objetivo del CSV manual

2. `6599447f-fd35-4d28-99dd-888c99ee2a62` - MATIAS ANKATU CASTRO CORREA
   - matricula esperada: `CHEQUE`, `1`, `1331260`, `1331260`
   - arancel esperado: `1` cuota, `CHEQUE`, monto `1331260`, total `1331260`
   - mismo criterio: hay que alinear ambos lados al estado objetivo

### D. Cambiar `enrollments.meta` y validar `fee` antes de tocarlo

1. `124f2fcb-ee42-47a1-8e52-180919137c32` - AMANDA FRANCISCA SALINAS VELIZ
   - matricula esperada: `CHEQUE`, `9`, `147918`, `1331262`
   - el agregado actual de aranceles trae `9` cuotas, monto minimo/maximo `147918`, pero total `1331260`
   - el esperado de aranceles es `1331262`, que coincide exactamente con `9 x 147918`
   - recomendacion: actualizar `enrollments.meta` y validar en BD si el desfase en `fee` es real o si proviene del reporte previo

### Impacto sobre la propuesta anterior

- se mantienen 7 cambios en `enrollments.meta`
- deja de ser correcto el caso anterior de regenerar `fee` para LUCAS MIGUEL CARRENO SOTO
- aparecen 2 casos donde el CSV manual fija un nuevo objetivo comun para matricula y aranceles: MIGUEL y MATIAS
- AMANDA FRANCISCA pasa a revision puntual de total en `fee`, no a regeneracion ciega

### Nueva recomendacion antes del paso de validacion en BD

1. Confirmar contra BD los 3 casos con componente `fee`:
   - MIGUEL ESTEBAN VICUNA PEREZ
   - MATIAS ANKATU CASTRO CORREA
   - AMANDA FRANCISCA SALINAS VELIZ
2. Tratar como no-op estos 4 casos:
   - VIOLETA BEATRIZ GUERRERO BIRKE
   - AMANDA AYELEN PAREDES RIOS
   - RAMIRO PASCUAL FUENZALIDA ANDRADE
   - LUCAS MIGUEL CARRENO SOTO
3. Preparar desde ya el lote seguro de 4 updates solo sobre `enrollments.meta`:
   - RENATA EMILIA IRARRAZABAL BASAEZ
   - DAMIAN IGNACIO MIRANDA ALVAREZ
   - FLORENCIA GALAZ DURAN
   - BASTIAN ANGEL MAICKOLL LOYOLA GRONDONA

## 12. Validacion en BD actual de los 11 enrollment_id

Se valido directamente en la BD actual el estado de `enrollments.meta`, `per_student_economic`, `per_student_plans` y el agregado de `fee` 2026 para los 11 casos del Excel, aislando al alumno objetivo cuando la matricula contiene mas de un estudiante.

### Resultado operativo actualizado

- 1 caso queda efectivamente como no-op
- 10 casos requieren ajuste en `enrollments.meta`
- 0 casos requieren tocar `fee`

### A. No-op confirmado en BD actual

1. `9755e5d1-e54f-4443-884b-721219622d77` - VIOLETA BEATRIZ GUERRERO BIRKE
   - `per_student_economic` ya esta en `CHEQUE`, `4`, `332815`, `1331260`
   - `fee` ya tiene 4 cuotas `CHEQUE` por `332815` con total `1331260`
   - no se detecta desajuste operativo

### B. Casos que en la BD actual requieren ajuste solo en `enrollments.meta`

1. `74f62c36-655c-4b9b-b772-f6b68db41b32` - AMANDA AYELEN PAREDES RIOS
   - la clasificacion previa como no-op queda refutada por la BD actual
   - `per_student_economic` sigue en `PAGARE|TRANSFERENCIA`, `false`, `10`, `102870`, `1028700`
   - no existen registros `fee` 2026 para este alumno
   - el objetivo del CSV manual sigue siendo el estado prioritario en cero: `PRIORITARIO`, `true`, `0`, `0`, `0`

2. `b586387a-9d35-40d6-8970-8310b2aafa5a` - RAMIRO PASCUAL FUENZALIDA ANDRADE
   - la clasificacion previa como no-op tambien queda refutada por la BD actual
   - `per_student_economic` sigue en `PAGARE`, `false`, `10`, `102870`, `1028700`
   - `per_student_plan` ya esta vacio y no hay `fee`
   - el objetivo del CSV manual sigue siendo `PRIORITARIO`, `true`, `0`, `0`, `0`

3. `fe495910-415b-4b30-bd6f-c8c216c6a800` - LUCAS MIGUEL CARRENO SOTO
   - tampoco queda como no-op al revisar el bloque por alumno
   - a nivel raiz la matricula ya muestra el patron prioritario en cero, pero `per_student_economic` de LUCAS sigue con valores inconsistentes: `SIN_DATO`, `false`, `10`, `0`, `0`
   - no hay `fee` 2026 para este alumno
   - requiere normalizar el bloque por alumno a `PRIORITARIO`, `true`, `0`, `0`, `0`

4. `5ad7dbf2-7183-4c93-a9ad-d700bed09ef7` - RENATA EMILIA IRARRAZABAL BASAEZ
   - `per_student_economic` sigue en `102870` y `1028700`
   - `fee` ya esta correcto en `99324` x `10` = `993240`
   - corresponde actualizar solo `meta`

5. `68178644-172b-4e34-9d03-d86125492c65` - DAMIAN IGNACIO MIRANDA ALVAREZ
   - `per_student_economic` sigue en `10` cuotas
   - `fee` ya esta correcto en `7` cuotas de `190180` con total `1331260`
   - corresponde actualizar solo `meta`

6. `fba5295b-2960-4398-8ed7-ac1f6ab0cedb` - FLORENCIA GALAZ DURAN
   - `per_student_economic` sigue en `114300`
   - `fee` del alumno objetivo ya esta correcto en `102870` x `10` = `1028700`
   - el agregado anterior de 20 cuotas era ruido por matricula compartida; para FLORENCIA el lado `fee` ya esta alineado
   - corresponde actualizar solo `meta`

7. `1715e001-1157-403f-8e86-66e7d5dd97c2` - BASTIAN ANGEL MAICKOLL LOYOLA GRONDONA
   - `per_student_economic` sigue en `102870` y `1028700`
   - `fee` ya esta correcto en `72009` x `10` = `720090`
   - corresponde actualizar solo `meta`

8. `794a4776-1e12-40c8-b8d6-1e8f0441ed45` - MIGUEL ESTEBAN VICUNA PEREZ
   - la validacion en BD actual cambia la conclusion anterior
   - `fee` ya esta en el objetivo del CSV manual: 1 cuota `CHEQUE` por `1331260`, total `1331260`
   - lo que sigue desalineado es `per_student_economic`, que aun esta en `10` cuotas de `133126`
   - por tanto ya no requiere tocar `fee`; requiere solo actualizar `meta`

9. `6599447f-fd35-4d28-99dd-888c99ee2a62` - MATIAS ANKATU CASTRO CORREA
   - mismo patron que MIGUEL
   - `fee` ya esta en 1 cuota `CHEQUE` por `1331260`, total `1331260`
   - `per_student_economic` sigue en `10` cuotas de `133126`
   - por tanto ya no requiere tocar `fee`; requiere solo actualizar `meta`

10. `124f2fcb-ee42-47a1-8e52-180919137c32` - AMANDA FRANCISCA SALINAS VELIZ
   - la validacion en BD resolvio la duda anterior sobre `fee`
   - `fee` ya suma `1331262` con 9 registros `CHEQUE` de `147918`
   - lo que sigue viejo es `per_student_economic`, que permanece en `10` cuotas y total `1331260`
   - por tanto ya no requiere validacion adicional de `fee`; requiere solo actualizar `meta` al objetivo `9`, `147918`, `1331262`

### Impacto sobre la siguiente etapa

- la recomendacion anterior de revisar 3 casos con componente `fee` queda cerrada por la validacion en BD actual
- no se justifica ningun `delete/insert` ni regeneracion de `fee` para estos 11 casos
- el siguiente paso seguro es preparar un lote de 10 updates puntuales sobre `enrollments.meta`
- en matriculas compartidas, el update debe priorizar `per_student_economic` y `per_student_plans` del alumno objetivo; no basta con mirar solo los campos raiz