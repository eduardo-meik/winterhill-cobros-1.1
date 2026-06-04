# Database Audit Report — Winterhill Cobros

**Fecha:** 2025-01-XX  
**Total hallazgos:** 2,260  
**Base de datos:** Supabase PostgreSQL (`yeotpplgerfpxviqazrn`)

---

## Resumen Ejecutivo

| Categoría | Hallazgos | Severidad |
|-----------|-----------|-----------|
| Duplicados (Parte 2) | 494 | 🔴 Alta |
| FKs Huérfanas (Parte 3) | 0 | ✅ OK |
| Inconsistencias Lógicas (Parte 4) | 276 | 🟡 Media-Alta |
| Integridad Relacional (Parte 5) | 1,490 | 🔴 Alta |

---

## Parte 1: Inventario de Tablas (22 tablas)

| Tabla | Registros | Observación |
|-------|-----------|-------------|
| students | 516 | Principal |
| guardians | 491 | |
| fee | 2,921 | Tabla más grande (datos) |
| enrollments | 422 | |
| enrollment_students | 443 | |
| enrollment_documents | 1,391 | |
| cheques | 790 | |
| cursos | 73 | |
| student_guardian | 553 | |
| student_academic_records | 1,001 | |
| audit_logs | 9,517 | Tabla más grande (logs) |
| auth_logs | 2,565 | |
| profiles | 8 | Solo 8 usuarios admin/staff |
| guardian_intake_surveys | 109 | |
| email_logs | 0 | No implementado |
| signatures | 0 | No implementado |
| enrollment_document_receipts | 0 | No implementado |

**Tablas vacías sin uso:** `email_logs`, `signatures`, `enrollment_document_receipts` — candidatas a limpieza si no están planificadas.

`invoices`, `pre_receipts` y `matriculas_detalle` fueron retiradas del esquema activo el 2026-04-07.

---

## Parte 2: Duplicados (494 hallazgos)

### 2f — Cuotas duplicadas (26 registros) 🔴
**Qué:** Fees con el mismo `student_id` + `numero_cuota` + `year_academico`.  
**Impacto:** Cobros dobles, contabilidad incorrecta.  
**Detalle:** Todas tienen `numero_cuota = NULL`, lo que indica fees creadas sin número de cuota asignado. Hasta 5 fees por estudiante sin cuota.  
**Acción:** Asignar `numero_cuota` a fees que no lo tengan. Crear constraint UNIQUE en `(student_id, numero_cuota, year_academico)` donde `numero_cuota IS NOT NULL`.

### 2k — Cheques con `numero_serie` duplicado (100 registros) 🟡
**Qué:** Números de serie de cheques que aparecen más de una vez.  
**Impacto:** Serial `5914649` aparece **32 veces**. Podría ser un número por defecto/placeholder.  
**Detalle:** Muchos serials aparecen 2-4 veces (normal para chequeras), pero los que aparecen 10+ veces son sospechosos.  
**Acción:** Investigar serials con >5 repeticiones — podrían ser datos de prueba o errores de ingreso. Considerar validación en frontend.

### 2l — Documentos de enrollment duplicados (368 registros) 🟡
**Qué:** Mismo `enrollment_id` + `type` aparece múltiples veces.  
**Impacto:** Documentos PRESTACION con 2-5 copias por enrollment, lo que inflará consultas y puede causar confusión sobre cuál es el vigente.  
**Acción:** Conservar solo el documento más reciente (por `created_at`) y eliminar duplicados. Crear constraint UNIQUE en `(enrollment_id, type)`.

### Queries sin hallazgos (0 duplicados):
- ✅ 2a: No hay estudiantes con RUN duplicado
- ✅ 2b: No hay guardians con RUN duplicado
- ✅ 2c: No hay pares student-guardian duplicados
- ✅ 2d: No hay enrollments duplicados (guardian+year)
- ✅ 2e: No hay enrollment_students duplicados
- ✅ 2g: No hay academic_records duplicados
- ✅ 2h: No hay intake_surveys duplicados
- ℹ️ 2i: `matriculas_detalle` fue retirada del esquema; chequeo ya no aplica
- ✅ 2j: No hay profiles con email duplicado

---

## Parte 3: Foreign Keys Huérfanas (0 hallazgos) ✅

Todas las relaciones FK están íntegras. No hay registros apuntando a entidades inexistentes en:
- fee → students, guardians, cursos, enrollments
- student_guardian → students, guardians
- enrollment_students → enrollments, students
- enrollments → guardians
- student_academic_records → students, cursos
- cheques → enrollments
- enrollment_documents → enrollments
- students → cursos

---

## Parte 4: Inconsistencias Lógicas (276 hallazgos)

### 4a — Fees pagadas sin `payment_date` (7 registros) 🔴
**Qué:** Fees con `status = 'paid'` pero `payment_date IS NULL`.  
**Impacto:** Reportes financieros incompletos, imposible auditar cuándo se pagó.  
**Detalle:** Montos de $24,831 a $128,532, año 2025.  
**Acción:** Requiere investigación manual para asignar fecha real de pago. Como mínimo establecer `payment_date = updated_at` como fallback.

### 4c — Fees con monto = 0 (100 registros) 🟡
**Qué:** 100 fees con `amount = 0.00` y `status = pending` para año 2026.  
**Impacto:** Entradas sin utilidad que inflan reportes.  
**Detalle:** Son fees 2026 que probablemente se generaron automáticamente antes de asignar monto.  
**Acción:** Si el monto real es conocido, actualizar. Si son placeholder, eliminar o marcar como `cancelled`.

### 4e — Fees con `payment_date` absurda (5 registros) 🔴
**Qué:** Fees con `payment_date` en años como 1496, 0025, 0205 — claramente errores de entrada.  
**Impacto:** Diferencias de -193,277 a -730,474 días con la fecha esperada.  
**Detalle:** Probablemente errores de tipeo al ingresar fecha de pago manualmente.  
**Acción:** Corregir manualmente o establecer `payment_date = NULL` y marcar para re-verificación.

### 4f — Estudiantes con datos de "test" (3 registros) 🟡
**Qué:** Estudiantes con nombres seed/test: `GASPAR ALONSO`, `AMARO MAURICIO`, `SANTIAGO RAIMUNDO` con RUN tipo `23.111.722-9`.  
**Nota:** Esto requiere verificación — podrían ser registros reales.

### 4g — Estudiantes sin ningún guardian (41 registros) 🟡
**Qué:** 41 estudiantes sin relación en `student_guardian`.  
**Impacto:** No hay apoderado asignado, lo que impide procesos de enrollment y cobro.  
**Detalle:** Incluye registros de prueba (`mama test`, `nnnnnnnnn`, `nuevo testing`) y registros reales sin apoderado (`KATHERIN ARAVENA`, `NICOL GODOY`, etc.).  
**Acción:** Eliminar registros de prueba. Para registros reales, vincular con guardian existente o crear guardian pendiente.

### 4h — Guardians sin ningún estudiante (8 registros) 🟢
**Qué:** 8 perfiles admin/staff que son usuarios del sistema (ADMIN, ASIST) sin estudiante.  
**Impacto:** Esperado para usuarios administrativos.  
**Acción:** No requiere acción — son usuarios del sistema.

### 4i — Estudiantes retirados sin motivo (4 registros) 🟡
**Qué:** 4 estudiantes con `fecha_retiro` pero sin `motivo_retiro`.  
**Acción:** Completar motivo de retiro para trazabilidad.

### 4j — Estudiantes con fecha de nacimiento sospechosa (60 registros) 🟡
**Qué:** 60 estudiantes con `date_of_birth` fuera de rango razonable.  
**Detalle:** Incluye fechas como `1900-12-31` (edad 125), `20019-05-18` (año 20019), y múltiples con `2025-12-XX` (edad 0) — esto parece un default incorrecto.  
**Acción:** Las fechas `2025-12-XX` probablemente son un valor por defecto del formulario. Agregar validación de rango en el frontend (años 2005-2022 para estudiantes escolares).

### 4q — Enrollment con year fuera de rango (1 registro) 🟢
**Qué:** 1 enrollment año 2023, status `draft`.  
**Acción:** Considerar eliminarlo si es prueba.

### 4t — Guardian con email inválido (1 registro) 🟡
**Qué:** `zarragaanamaria@gmailcom` (falta el punto en gmail.com).  
**Acción:** Corregir a `zarragaanamaria@gmail.com`.

### 4u — Students con RUN pero sin `run_numero` (41 registros) 🟡
**Qué:** Campo `run_numero` (numérico) es NULL aunque el campo `run` (texto) tiene valor.  
**Impacto:** Búsquedas numéricas no funcionarán.  
**Acción:** Poblar `run_numero` parseando el valor de `run` (quitar puntos y dígito verificador).

### 4v — Posibles estudiantes duplicados por nombre (4 pares) 🟡
**Qué:** 4 pares de estudiantes con nombre completo idéntico pero RUN diferente.  
**Detalle:** ABEL IGNACIO MORAGA MENA, FACUNDO AQUEVEQUE SOLANO, FRANCO ALLEN THOMAS BASAURE, ISIDORA VALENTINA SANTELICES MEZA — posibles errores en RUN o registros genuinamente distintos.  
**Acción:** Verificar manualmente si son la misma persona con RUN erróneo.

### 4w — Posible guardian duplicado por nombre (1 par) 🟢
**Qué:** Guardian "nuevo testing" aparece 2 veces (RUNs diferentes).  
**Acción:** Datos de prueba, eliminar.

### Queries sin hallazgos:
- ✅ 4b: No hay fees con payment_date que no estén marcadas como paid
- ✅ 4d: No hay fees con due_date fuera de rango
- ✅ 4k: No hay cheques con monto ≤ 0
- ✅ 4l: No hay cheques pendientes con fecha muy antigua
- ✅ 4m: No hay documentos signed sin signed_at
- ✅ 4n: No hay documentos con signed_at mal clasificados
- ✅ 4o: No hay profiles con role inválido (pero role usa UPPER: ADMIN, ASIST, GUARDIAN)
- ✅ 4p: No hay fees con year fuera de rango
- ✅ 4r: No hay fees con status inválido
- ✅ 4s: No hay enrollments con status inválido

---

## Parte 5: Integridad Relacional (1,490 hallazgos)

### 5a — Estudiantes en enrollment sin academic record (2 registros) 🟡
**Qué:** TRINIDAD IGNACIA BERTEINS (2024) y SALVADOR GASPAR (2025) están en `enrollment_students` pero no tienen `student_academic_records` para ese año.  
**Acción:** Crear academic_record para estos estudiantes.

### 5c — Estudiantes con cuotas faltantes 2026 (8 registros) 🟡
**Qué:** 8 estudiantes tienen entre 1 y 9 cuotas de 10 esperadas para 2026.  
**Detalle:** Algunos solo tienen 1 cuota (LETICIA COLOMBA), otros tienen 9 de 10 (faltan cuota 1).  
**Acción:** Generar cuotas faltantes o verificar si es intencional (becas parciales, etc.).

### 5d — Discrepancia curso actual vs academic record (11 registros) 🔴
**Qué:** `students.curso` apunta a un curso diferente al de `student_academic_records` con estado activo.  
**Impacto:** Confusión sobre en qué curso está realmente el estudiante.  
**Detalle:** Ej: SILVIO DARIO tiene `students.curso = 3° BASICO B` pero su academic_record activo dice `2° BASICO B`. Algunos mismatch son A vs B, otros son niveles completamente diferentes.  
**Acción:** Determinar cuál es la fuente de verdad y sincronizar. Probablemente el academic_record es correcto y `students.curso` se actualizó mal.

### 5h — Estudiantes con múltiples guardians primarios (26 registros) 🟡
**Qué:** 26 estudiantes tienen 2+ guardians marcados como `is_primary = true`.  
**Impacto:** Ambigüedad sobre quién es el responsable principal.  
**Acción:** Revisar y dejar solo 1 guardian primario por estudiante.

### 5i — Estudiantes sin guardian primario (6 registros) 🟡
**Qué:** 6 estudiantes tienen guardians asignados pero ninguno marcado como primario.  
**Acción:** Marcar al guardian más relevante como primario.

### 5j — Cursos sin estudiantes asignados (32 registros) 🟢
**Qué:** 32 cursos (mayormente 2024 y sección B) sin estudiantes con ese `curso` en `students`.  
**Impacto:** Esperado para cursos históricos (2024) y cursos recién creados. Los 2025 sección B podrían necesitar atención.  
**Acción:** Depurar cursos 2024 si ya no se usan. Verificar cursos 2025/2026 vacíos.

### 5k — Resumen fees por estudiante 2026 (100 registros) 🔴
**Qué:** 100 estudiantes con fees 2026 pendientes.  
**Detalle:** Montos van desde $13,312,600 (LEONOR CAROLINA CARVAJAL, 4° MEDIO A) hasta $1,331,260 (promedio). Total pagado = $0 para casi todos.  
**Impacto:** Esto parece normal — son fees 2026 recién generadas. El hallazgo es informativo.  
**Acción:** Revisar si los montos son correctos. Los montos de $13M y $11M parecen excesivamente altos comparados con el promedio de ~$1.3M.

### 5m — Estudiantes con espacios extra en nombres (319 registros) 🟡
**Qué:** 319 estudiantes (61% del total) tienen leading/trailing spaces o dobles espacios en nombres.  
**Impacto:** Búsquedas y comparaciones de texto fallan, reportes se ven inconsistentes.  
**Acción:** Ejecutar TRIM masivo: `UPDATE students SET first_name = BTRIM(first_name), apellido_paterno = BTRIM(apellido_paterno) WHERE ...`

### 5n — Guardians con espacios extra en nombres (490 registros) 🔴
**Qué:** 490 de 491 guardians (99.8%) tienen problemas de whitespace.  
**Impacto:** Prácticamente todos los guardians — probablemente viene de la importación de datos.  
**Acción:** `UPDATE guardians SET first_name = BTRIM(REGEXP_REPLACE(first_name, '\s+', ' ', 'g')), last_name = BTRIM(REGEXP_REPLACE(last_name, '\s+', ' ', 'g'))`

### 5o — Students con RUN mal formateado (496 registros) 🟡
**Qué:** 496 de 516 estudiantes (96%) tienen RUN con formato no estandarizado.  
**Detalle:** Incluye RUNs con puntos (`22.398.005-8` vs `22398005-8`), sin guión, o con formatos extraños (`100.589.843-5`, `2.547.943-5`).  
**Impacto:** El regex esperaba `^\d{7,8}-[\dkK]$` (sin puntos). Si el formato estándar incluye puntos, esto es un falso positivo.  
**Acción:** Decidir formato canónico (con o sin puntos) y normalizar. Agregar validación en frontend.

### 5p — Guardians con RUN mal formateado (490 registros) 🟡
**Qué:** Similar a 5o, para guardians.  
**Acción:** Misma normalización que para estudiantes.

### Queries sin hallazgos:
- ✅ 5b: No hay academic_records sin enrollment_students
- ✅ 5e: No hay guardians con owner_id sin profile
- ✅ 5f: No hay students con owner_id sin profile
- ✅ 5g: No hay documents signed sin signature
- ✅ 5l: No hay guardians claimed sin profile
- ✅ 5q: No hay registros con updated_at < created_at

---

## Prioridades de Corrección

### 🔴 Prioridad Alta (datos incorrectos que afectan funcionalidad)

1. **5m+5n: Limpiar whitespace en nombres** (809 registros)  
   - Afecta al 61% de estudiantes y 99.8% de guardians  
   - Fix automático con UPDATE + BTRIM + REGEXP_REPLACE  
   - Riesgo: bajo (solo trim de espacios)

2. **4a+4e: Corregir fechas de pago absurdas** (12 registros)  
   - Fees pagadas sin payment_date o con fechas de año 0025/1496  
   - Requiere intervención manual  

3. **5d: Sincronizar curso actual vs academic record** (11 registros)  
   - Datos contradictorios sobre curso del estudiante  
   - Requiere verificación caso a caso

4. **2f: Resolver fees con cuota NULL** (26 registros)
   - Impide identificación única de cuotas

### 🟡 Prioridad Media (calidad de datos)

5. **4j: Corregir fechas de nacimiento incorrectas** (60 registros)  
6. **4u: Poblar `run_numero` desde `run`** (41 registros)  
7. **4g: Limpiar estudiantes sin guardian** (41 registros, incluye datos test)  
8. **2l: Eliminar documentos de enrollment duplicados** (368 registros)  
9. **5h: Resolver múltiples guardians primarios** (26 registros)  
10. **5i: Asignar guardian primario faltante** (6 registros)  

### 🟢 Prioridad Baja (depuración y mejoras)

11. **2k: Revisar cheques con serial duplicado** (100 registros)  
12. **5j: Depurar cursos sin estudiantes** (32 registros)  
13. **5o+5p: Normalizar formato de RUN** (986 registros) — requiere decisión de formato  
14. **Eliminar datos de prueba** (registros con nombres "test", "falso", "nuevo", "NO DISPONIBLE")  
15. **Eliminar tablas vacías no usadas** (email_logs, signatures, enrollment_document_receipts, etc.)

---

## Acciones Automáticas Seguras (ejecutables con SQL)

```sql
-- 1. Limpiar whitespace en estudiantes
UPDATE students 
SET first_name = BTRIM(REGEXP_REPLACE(first_name, '\s+', ' ', 'g')),
    apellido_paterno = BTRIM(REGEXP_REPLACE(apellido_paterno, '\s+', ' ', 'g')),
    apellido_materno = BTRIM(REGEXP_REPLACE(COALESCE(apellido_materno, ''), '\s+', ' ', 'g'))
WHERE first_name != BTRIM(REGEXP_REPLACE(first_name, '\s+', ' ', 'g'))
   OR apellido_paterno != BTRIM(REGEXP_REPLACE(apellido_paterno, '\s+', ' ', 'g'));

-- 2. Limpiar whitespace en guardians
UPDATE guardians 
SET first_name = BTRIM(REGEXP_REPLACE(first_name, '\s+', ' ', 'g')),
    last_name = BTRIM(REGEXP_REPLACE(last_name, '\s+', ' ', 'g'))
WHERE first_name != BTRIM(REGEXP_REPLACE(first_name, '\s+', ' ', 'g'))
   OR last_name != BTRIM(REGEXP_REPLACE(last_name, '\s+', ' ', 'g'));

-- 3. Corregir email inválido
UPDATE guardians 
SET email = 'zarragaanamaria@gmail.com' 
WHERE id = '7db6bc08-3f52-46ef-a3e7-535d47709959';

-- 4. Poblar run_numero desde run
UPDATE students
SET run_numero = CAST(
  REPLACE(REPLACE(SPLIT_PART(run, '-', 1), '.', ''), ' ', '') 
  AS INTEGER
)
WHERE run IS NOT NULL AND run != '' AND run_numero IS NULL
  AND REPLACE(REPLACE(SPLIT_PART(run, '-', 1), '.', ''), ' ', '') ~ '^\d+$';
```

---

## Validaciones a Agregar en Frontend

1. **Fecha de nacimiento:** Rango 2005-2022 para estudiantes nuevos
2. **Fecha de pago:** Rango 2024-2027, no permitir años < 2020
3. **RUN:** Validación de formato al ingresar
4. **Nombres:** Trim automático en submit (ya existe `GUARDIAN_FULL_NAME_TRIM_FIX`)
5. **Número de cuota:** Requerido al crear fee manualmente

---

## Constraints Recomendados

```sql
-- Prevenir enrollment_documents duplicados
ALTER TABLE enrollment_documents 
ADD CONSTRAINT uq_enrollment_doc_type 
UNIQUE (enrollment_id, type);

-- Prevenir cuotas duplicadas (cuando numero_cuota es conocido)  
CREATE UNIQUE INDEX uq_fee_student_cuota_year 
ON fee (student_id, numero_cuota, year_academico) 
WHERE numero_cuota IS NOT NULL;
```
