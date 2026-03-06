# 📋 BACKLOG — Winterhill Cobros v1.1

> **Última actualización:** 5 de marzo de 2026 (análisis de performance y seguridad)  
> **Leyenda:** 🔴 Crítico · 🟡 Alto · 🟢 Normal · ⚪ Bajo  
> **Estados:** `[ ]` Pendiente · `[~]` En progreso · `[x]` Completado · `[-]` Descartado

---

## 🗂️ Índice

1. [Transición Anual 2025→2026 (Nuevo)](#transición-anual-20252026)
2. [Generación de Fees y Finanzas (Nuevo)](#generación-de-fees-y-finanzas)
3. [UI/UX — Mejoras de Interfaz (Nuevo)](#uiux--mejoras-de-interfaz)
4. [Integridad de Datos — Folio Matrícula (Nuevo)](#integridad-de-datos--folio-matrícula)
5. [Query Performance (Nuevo)](#query-performance)
6. [Seguridad (Nuevo)](#seguridad)
7. [Mejoras Propuestas (Nuevo)](#mejoras-propuestas)
8. [Bugs Pendientes (Legacy)](#bugs-pendientes-legacy)
9. [Mejoras Pendientes (Legacy)](#mejoras-pendientes-legacy)
10. [Bugs Resueltos (Archivo)](#bugs-resueltos-archivo)
11. [Notas y Decisiones](#notas-y-decisiones)

---

## Transición Anual 2025→2026

> **Ref:** [PLAN_TRANSICION_ANUAL_Y_MEJORAS_UX.md](PLAN_TRANSICION_ANUAL_Y_MEJORAS_UX.md)

### Fase 1 — Backend: RPCs y Migraciones

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| TA-01 | 🔴 | `[x]` | Modificar `finalize_enrollment` para actualizar `student.curso` al curso 2026 | ✅ Migración `20260302_annual_transition_academic_records.sql` |
| TA-02 | 🔴 | `[x]` | Modificar `finalize_enrollment` para insertar en `student_academic_records` | ✅ Mismo archivo de migración |
| TA-03 | 🔴 | `[x]` | Marcar registro anterior en `student_academic_records` como PROMOVIDO al finalizar matrícula | ✅ `batch_promote_students` marca 'completado' |
| TA-04 | 🔴 | `[x]` | Reescribir `get_student_promotion_suggestion` (actualmente stub NULL) | ✅ Implementación real con secuencia de niveles |
| TA-05 | 🟡 | `[x]` | Crear RPC `promote_students_batch(from_year, to_year, student_ids[], dry_run)` | ✅ `batch_promote_students(uuid[], int)` |
| TA-06 | 🟡 | `[x]` | Migración de datos: poblar `student_academic_records` con datos 2025 existentes | ✅ Backfill en misma migración |
| TA-07 | 🟡 | `[x]` | Verificar/crear cursos con `year_academico = 2026` en tabla `cursos` | ✅ Migración clona cursos 2025→2026 idempotente |

### Fase 2 — Módulo de Estudiantes

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| TA-08 | 🔴 | `[x]` | Crear `AcademicYearContext` (año académico global, persistido en localStorage) | ✅ `src/contexts/AcademicYearContext.jsx` |
| TA-09 | 🔴 | `[x]` | Crear componente `YearSelector` reutilizable | ✅ `src/components/ui/YearSelector.jsx` |
| TA-10 | 🔴 | `[x]` | Agregar `YearSelector` al Sidebar | ✅ Visible admin/asist, compact mode |
| TA-11 | 🔴 | `[x]` | Filtrar `StudentsPage` por año académico vía `cursos.year_academico` | ✅ Filtra por año del contexto |
| TA-12 | 🟡 | `[x]` | Agregar columna "Año Académico" a `StudentsTable` | ✅ Badge con año |
| TA-13 | 🟡 | `[x]` | Crear sección "Historial Académico" en `StudentDetailsModal` | ✅ Reescrito 2026-03-05: timeline con datos reales de enrollment_students/enrollments/cursos/fee, cards expandibles por año |
| TA-14 | 🟢 | `[x]` | Lógica visual de "liberar espacio": estudiantes 2025 como solo-lectura al filtrar 2025 | ✅ `isReadOnly` banner + botones deshabilitados en StudentsPage/StudentsTable |

### Fase 3 — Dashboard y Pagos

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| TA-15 | 🟡 | `[x]` | Filtrar Dashboard (4 StatCards) por `year_academico` del contexto global | ✅ Usa `academicYear` del contexto |
| TA-16 | 🟡 | `[x]` | Filtrar gráficos (DebtTrend, DebtDistribution, PaymentProjection) por año | ✅ Prop `academicYear` |
| TA-17 | 🟡 | `[x]` | Filtrar `DebtorsTable` por año académico | ✅ Prop `academicYear` |
| TA-18 | 🟡 | `[x]` | `PaymentsPage`: cambiar filtro de `due_date.year` a `fee.year_academico` | ✅ Server-side filter con AcademicYearContext, year dropdown removido |

### Fase 4 — UI/UX y Promoción Masiva

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| TA-19 | 🟡 | `[x]` | Crear componente `PromotionTool.jsx` (promoción masiva con preview y confirmación) | ✅ PromotionTool con preview (dry-run), enrollment formal + fees, migración `promote_and_enroll_batch` |
| TA-20 | 🟡 | `[x]` | Agregar entrada "Promoción" al Sidebar para admin | ✅ GraduationCap icon, ruta /promocion, admin-only |
| TA-21 | 🟢 | `[x]` | Cambiar ícono de Matrícula en Sidebar (actualmente repite el de Apoderados) | ✅ `ClipboardCheck` + `ArrowsRepeat` para Repactación |
| TA-22 | 🟢 | `[x]` | Corregir nomenclatura de estados: MATRICULADO→Pre-Matriculado, ACTIVO→Confirmado, RETIRADO | ✅ Actualizado en studentStatus.js + 7 archivos |
| TA-23 | 🟢 | `[x]` | Tabs en `StudentDetailsModal`: Datos \| Apoderados \| Historial — usando `TabsContainer`/`TabButton` existentes | Mejor organización de info |

---

## Generación de Fees y Finanzas

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| FE-01 | 🔴 | `[x]` | Verificar que fees generados en `finalize_enrollment` incluyan `year_academico` correcto | ✅ ON CONFLICT corregido a (student_id, year_academico, numero_cuota) |
| FE-02 | 🟡 | `[x]` | Asegurar que fees no se dupliquen al re-ejecutar matrícula | ✅ ON CONFLICT ahora coincide con unique index ux_fee_student_year_cuota |
| FE-03 | 🟡 | `[x]` | Separar fees por año en vista de pagos del guardian — **ya implementado**: dropdown de año + filtro client-side en `GuardianPortalPage` | Portal guardian ya tiene contexto de año |
| FE-04 | 🟢 | `[x]` | Dashboard financiero: comparativa año actual vs anterior | ✅ `YearComparisonChart.jsx` — BarChart Recharts comparando pagado/pendiente/vencido año actual vs anterior |

---

## UI/UX — Mejoras de Interfaz

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| UX-01 | 🟡 | `[x]` | Indicador de año académico activo visible en toda la app | ✅ Badge en Dashboard y StudentsPage + Sidebar selector. Mejorado 2026-03-05: badge verde "Activo" / gris "Consulta" en YearSelector |
| UX-02 | 🟢 | `[x]` | Mejorar responsive de tablas en móvil | Mobile card view en StudentsTable y PaymentsTable |
| UX-03 | 🟢 | `[x]` | Agregar breadcrumbs de navegación | Breadcrumbs.jsx integrado en MainLayout |
| UX-04 | ⚪ | `[x]` | Modo oscuro: revisar contrastes en componentes nuevos | ✅ Dark mode en YearSelector compact |
| UX-05 | 🟡 | `[x]` | PaymentsPage: modo solo-lectura para años pasados con banner informativo | ✅ 2026-03-05: `isReadOnly` condicional, banner azul con enlace "Volver a 2026", botón Registrar Pago oculto |
| UX-06 | 🟡 | `[x]` | GuardianDetailsModal: mostrar estado de matrícula por estudiante | ✅ 2026-03-05: badges verde/amarillo/rojo de matrícula 2026 junto a cada estudiante asociado |
| UX-07 | 🟢 | `[x]` | Exportación a Excel/CSV desde UI de pagos y estudiantes | ✅ Botón "Exportar Excel" en StudentsPage usando ExcelJS (mismo patrón que PaymentsPage) |

---

## Integridad de Datos — Folio Matrícula

> **Fuente:** Análisis de flujo de folio matrícula — 5 de marzo de 2026  
> **IDs con prefijo:** `FO-` (Folio)  
> **Archivo SQL:** [`FILL_MISSING_FOLIOS_2026.sql`](FILL_MISSING_FOLIOS_2026.sql)

### Diagnóstico

El folio matrícula (`ENR-2026-NNNNNN`) debería ser el **número de expediente** que unifica todo el proceso de matrícula (pagaré, cheques, comprobante). Actualmente existen **3 valores distintos** donde debería haber uno solo:

| Componente | Valor actual | Valor esperado |
|------------|-------------|----------------|
| `enrollments.meta->>'folio'` | `ENR-2026-000058` (correcto) | `ENR-2026-000058` |
| `cheques.folio_number` | UUID substring 8 chars (`doc.id.substring(0,8)`) | `ENR-2026-000058` |
| Pagaré `{{folio_number}}` | UUID substring 8 chars (`enrollment.id.slice(0,8)`) | `ENR-2026-000058` |
| Comprobante matrícula | `ENR-2026-000058` (correcto) | `ENR-2026-000058` |

**Causa raíz:** Problema de orden temporal — el pagaré y cheques se crean/persisten ANTES de que `finalize_enrollment` genere el folio `ENR-YYYY-NNNNNN`. El folio real solo existe después de la confirmación.

### Items

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| FO-01 | 🔴 | `[x]` | Rellenar folios faltantes en matrículas 2026 — algunas enrollments no tienen `meta->>'folio'` | ✅ 2026-03-05: Ejecutado `FILL_MISSING_FOLIOS_2026.sql` Steps 1-3 en Supabase SQL Editor |
| FO-02 | 🔴 | `[x]` | Unificar folio matrícula como expediente: pagaré y cheques deben usar `ENR-YYYY-NNNNNN` en vez de UUID substring | ✅ 2026-03-05: Nuevo RPC `assign_enrollment_folio` pre-asigna folio secuencial antes de generar pagaré. `useDocumentGeneration.js` llama al RPC antes de construir payload. Migración: `20260305_folio_unification.sql`. Solo afecta matrículas nuevas — pagarés firmados no cambian |
| FO-03 | 🔴 | `[x]` | Corregir flujo temporal: tras `finalize_enrollment`, actualizar `cheques.folio_number` con el folio real generado | ✅ 2026-03-05: `finalize_enrollment` ahora reutiliza folio pre-asignado (si existe) y ejecuta `UPDATE cheques SET folio_number = v_folio WHERE enrollment_id = p_enrollment_id`. También corregido formato de folio de timestamp a secuencial |
| FO-04 | 🟡 | `[x]` | Backfill: actualizar `cheques.folio_number` de cheques existentes con el folio real de su matrícula asociada | ✅ 2026-03-05: Ejecutado `FILL_MISSING_FOLIOS_2026.sql` Steps 4a-4c en Supabase SQL Editor |

---

## Query Performance

> **Fuente:** Análisis de `pg_stat_statements` — 5 de marzo de 2026  
> **IDs con prefijo:** `QP-` (Query Performance)

### 🔴 Críticos

| ID | Pri | Estado | Descripción | Impacto |
|----|-----|--------|-------------|--------|
| QP-01 | 🔴 | `[x]` | Query de fee con filtro `year_academico` en frontend — `RegisterPaymentModal`, `ReportingPage`, `DebtorsTable`, 3 charts | Reduce dataset ~80% vs sin filtro |
| QP-02 | 🔴 | `[x]` | Implementar **debounce** (300ms) en búsqueda de guardians — `useAssistedMode.js` + `RepactacionWizard.jsx` | Reduce calls ~90% — `debouncedSearchGuardians` con `useRef`/`clearTimeout` |

### 🟡 Altos

| ID | Pri | Estado | Descripción | Impacto |
|----|-----|--------|-------------|--------|
| QP-03 | 🟡 | `[x]` | Enrollments con 3 lateral joins (guardians + enrollment_students + students) — 532 calls, media 186ms, 20.4% del total | ✅ 2026-03-05: Índices creados en `20260305_performance_indexes.sql`, ejecutado en Supabase |
| QP-04 | 🟡 | `[x]` | Búsqueda ILIKE de students (whole_name, first_name, apellido_paterno, run) — 168 calls, media 190ms | ✅ 2026-03-05: Índice GIN trigram creado en `20260305_performance_indexes.sql`, ejecutado en Supabase |
| QP-05 | 🟡 | `[x]` | Fee con triple join students+cursos — 44 calls, media 518ms | ✅ 2026-03-05: Índice creado en `20260305_performance_indexes.sql`, ejecutado en Supabase |

### SQL de índices recomendados

```sql
-- Performance: índices prioritarios
CREATE INDEX IF NOT EXISTS idx_fee_year_academico ON fee(year_academico);
CREATE INDEX IF NOT EXISTS idx_fee_student_year ON fee(student_id, year_academico);
CREATE INDEX IF NOT EXISTS idx_enrollments_created_at ON enrollments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_enrollment_students_enrollment ON enrollment_students(enrollment_id);

-- Performance: búsqueda trigram (requiere extensión)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_guardians_name_trgm ON guardians USING gin (first_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_guardians_lastname_trgm ON guardians USING gin (last_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_students_wholename_trgm ON students USING gin (whole_name gin_trgm_ops);
```

---

## Seguridad

> **Fuente:** Supabase Database Linter — 5 de marzo de 2026  
> **IDs con prefijo:** `SC-` (Seguridad)

### 🔴 ERROR — Acción inmediata

| ID | Pri | Estado | Descripción | Remediación |
|----|-----|--------|-------------|------------|
| SC-01 | 🔴 | `[x]` | Views `database_metadata` y `payment_summary` con SECURITY DEFINER — ejecutan con permisos del creador, no del usuario | Recrear como SECURITY INVOKER — **migración:** `20260222_security_hardening.sql` (pendiente ejecutar) |
| SC-02 | 🔴 | `[x]` | Tabla `student_guardian_backup_20241222` sin RLS — expuesta vía PostgREST | DROP TABLE — **migración:** `20260222_security_hardening.sql` (pendiente ejecutar) |

### 🟡 WARN — Riesgo medio

| ID | Pri | Estado | Descripción | Remediación |
|----|-----|--------|-------------|------------|
| SC-03 | 🟡 | `[x]` | 24 funciones sin `search_path` fijo — vulnerables a search_path hijacking | ALTER FUNCTION SET search_path — **migración:** `20260222_security_hardening.sql` (pendiente ejecutar) |
| SC-04 | 🟡 | `[x]` | RLS policy always true en `invoices` (ALL) — bypasses RLS para cualquier authenticated | Reemplazado por staff_write/update/delete — **migración:** `20260222_security_hardening.sql` (pendiente ejecutar) |
| SC-05 | 🟡 | `[x]` | RLS policy always true en `student_guardian` (ALL) | Reemplazado por owner_policy — **migración:** `20260222_security_hardening.sql` (pendiente ejecutar) |
| SC-06 | 🟡 | `[x]` | RLS policy always true en `matriculas_detalle` (DELETE/INSERT/UPDATE) — 3 policies permisivas | Reemplazado por staff-only — **migración:** `20260222_security_hardening.sql` (pendiente ejecutar) |
| SC-07 | 🟡 | `[x]` | RLS policy always true en `auth_logs` (INSERT) — cualquier usuario puede insertar logs | Reemplazado por auth_logs_insert_own — **migración:** `20260305_security_hardening_supplement.sql` (pendiente ejecutar) |
| SC-08 | ⚪ | `[N/A]` | Leaked password protection deshabilitado en Supabase Auth | Feature de pago (plan Pro+). No aplica. |
| SC-09 | � | `[x]` | Postgres actualizado | Ya actualizado desde Supabase Dashboard. |

### ℹ️ INFO

| ID | Pri | Estado | Descripción | Remediación |
|----|-----|--------|-------------|------------|
| SC-10 | ⚪ | `[x]` | `guardian_claim_logs` — RLS habilitado pero sin policies | SELECT staff-only policy — **migración:** `20260305_security_hardening_supplement.sql` (pendiente ejecutar) |
| SC-11 | ⚪ | `[x]` | `rate_limit_counters` — RLS habilitado pero sin policies | service_role-only policy — **migración:** `20260305_security_hardening_supplement.sql` (pendiente ejecutar) |

---

## Mejoras Propuestas

> **Fuente:** Análisis de código — 5 de marzo de 2026  
> **IDs con prefijo:** `MP-` (Mejora Propuesta)

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| MP-01 | 🟡 | `[x]` | Tabla `student_academic_records` vacía — poblar desde enrollments o eliminar con sus triggers | Backfill SQL: 20260305_backfill_academic_records.sql |
| MP-02 | 🟡 | `[x]` | Portal guardian: no muestra estado de matrícula ni documentos pendientes | Estado matrícula, folio, docs en GuardianPortalPage |
| MP-03 | 🟢 | `[x]` | Organizar ~80+ archivos SQL sueltos en raíz del proyecto en carpeta `sql/` | 98 archivos movidos a sql/ |
| MP-04 | 🟢 | `[x]` | Organizar archivos .md de documentación/fix en carpeta `docs/` | 88 archivos movidos a docs/ |

---

## Bugs Pendientes (Legacy)

> Migrados desde BACKLOG original (mayo 2025). Verificar vigencia.

| ID | Pri | Estado | Descripción | Origen |
|----|-----|--------|-------------|--------|
| BG-01 | 🟡 | `[x]` | No se cambia automáticamente el nombre en los detalles de los apoderados | ✅ Local state guardianData se actualiza tras save |
| BG-02 | 🟡 | `[x]` | `StudentFormModal.jsx`: no persisten datos existentes previo a modificación | ✅ Agregado defaultValues a useForm |
| BG-03 | 🟡 | `[x]` | Ícono de ojo en estudiantes asociados a apoderado no muestra información | ✅ Sección Estudiantes Asociados agregada en vista apoderado |
| BG-04 | 🟡 | `[x]` | No se muestra RUT de estudiante al acceder desde ícono de ojo en detalle de apoderados | ✅ `run` incluido en query + display |
| BG-05 | 🟡 | `[x]` | Filtros de reportes no funcionan, no se generan resultados | ✅ ReferenceError de processedStudents corregido |

---

## Mejoras Pendientes (Legacy)

> Migrados desde BACKLOG original (mayo 2025).

| ID | Pri | Estado | Descripción | Origen |
|----|-----|--------|-------------|--------|
| MJ-01 | 🟢 | `[x]` | Añadir función de lápiz para editar campos inline | ✅ Ya implementado en StudentDetailsModal y GuardianDetailsModal — pencil icon hover con save/cancel inline |
| MJ-02 | 🟢 | `[x]` | Mostrar detalle de deuda por cada apoderado | Debt summary en GuardianDetailsModal |
| MJ-03 | 🟢 | `[x]` | Crear reportes de deudas por apoderados | Columnas deuda en GuardianReportTable + guardianDebtMap |
| MJ-04 | 🟡 | `[x]` | Los cambios en datos no se reflejan inmediatamente (cache/refresh) | Cache clear en saveIntakeDraft + visibilitychange refresh en Dashboard |
| MJ-05 | ⚪ | `[x]` | Correos largos salen del menú de perfiles (overflow) | ✅ truncate + title tooltip en UserMenu |

---

## Bugs Resueltos (Archivo)

> Completados previamente. Se mantienen como referencia.

| ID | Estado | Descripción | Fecha |
|----|--------|-------------|-------|
| AR-01 | `[x]` | No funcionan los filtros de aranceles | May 2025 |
| AR-02 | `[x]` | Botón Agregar Apoderado no funciona | May 2025 |
| AR-03 | `[x]` | Botón de guardar cambios en tarjeta estudiante no funciona | May 2025 |
| AR-04 | `[x]` | Botón Registrar Estudiante no salva cambios | May 2025 |
| AR-05 | `[x]` | No se muestran las cuotas 1 a 6 | May 2025 |

---

## Notas y Decisiones

### Convenciones de este archivo

- **IDs con prefijo**: `TA-` (Transición Anual), `FE-` (Fees), `UX-` (UI/UX), `FO-` (Folio), `BG-` (Bug), `MJ-` (Mejora), `AR-` (Archivo)
- Cada item tiene un ID único que no se reutiliza
- Al completar un item, mover a la sección de archivo correspondiente o marcar `[x]`
- Para items nuevos, agregar al final de la sección correspondiente con el siguiente ID disponible

### Decisiones técnicas pendientes

| Fecha | Decisión | Estado |
|-------|----------|--------|
| 2026-03-02 | ¿Renombrar estados en DB (MATRICULADO→PRE_MATRICULADO) o solo mapear en UI? | ✅ Resuelto: mantener DB como está, mapear en UI via studentStatus.js |
| 2026-03-02 | ¿Promoción masiva crea matrícula formal o solo pre-asigna curso? | ✅ Resuelto: crea matrícula formal (enrollment + fees) via promote_and_enroll_batch |
| 2026-03-02 | ¿Cursos 2026 se crean manualmente o se clonan de 2025? | ✅ Resuelto: migración clona automáticamente |
| 2026-03-05 | ¿Historial académico usa tabla `student_academic_records` o datos de enrollment? | ✅ Resuelto: usa enrollment_students + enrollments + cursos + fee (datos reales) |
| 2026-03-05 | ¿Portal guardian se ve afectado por cambios de año académico admin? | ✅ Resuelto: portal es independiente, tiene su propio selector de año basado en datos de fee |
| 2026-03-05 | ¿Folio matrícula debe ser el número de expediente unificado? | ✅ Resuelto: SÍ — pagaré, cheques y comprobante deben usar el mismo folio ENR-YYYY-NNNNNN. Actualmente desconectados (pagaré/cheques usan UUID substring) |

### Prioridad recomendada de ejecución

1. **FO-01** — Rellenar folios faltantes 2026 (ejecutar SQL)
2. **FO-02 + FO-03** — Unificar folio matrícula como expediente en pagaré/cheques + fix flujo temporal
3. **FO-04** — Backfill cheques existentes con folio real
4. **QP-01** — Fix query fee sin filtro (34% del tiempo total de DB)
5. **QP-02** — Debounce en búsquedas frontend
6. **SC-01 + SC-02** — SECURITY DEFINER views + tabla backup sin RLS
7. **QP-03 a QP-05** — Crear índices SQL recomendados
8. **FE-03** — Fees por año en portal guardian
9. **MJ-04** — Cache invalidation / reactive refresh
10. **TA-23** — Tabs en StudentDetailsModal
