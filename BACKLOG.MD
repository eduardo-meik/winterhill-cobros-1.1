# 📋 BACKLOG — Winterhill Cobros v1.1

> **Última actualización:** 2 de marzo de 2026 (implementación parcial completada)  
> **Leyenda:** 🔴 Crítico · 🟡 Alto · 🟢 Normal · ⚪ Bajo  
> **Estados:** `[ ]` Pendiente · `[~]` En progreso · `[x]` Completado · `[-]` Descartado

---

## 🗂️ Índice

1. [Transición Anual 2025→2026 (Nuevo)](#transición-anual-20252026)
2. [Generación de Fees y Finanzas (Nuevo)](#generación-de-fees-y-finanzas)
3. [UI/UX — Mejoras de Interfaz (Nuevo)](#uiux--mejoras-de-interfaz)
4. [Bugs Pendientes (Legacy)](#bugs-pendientes-legacy)
5. [Mejoras Pendientes (Legacy)](#mejoras-pendientes-legacy)
6. [Bugs Resueltos (Archivo)](#bugs-resueltos-archivo)
7. [Notas y Decisiones](#notas-y-decisiones)

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
| TA-07 | 🟡 | `[ ]` | Verificar/crear cursos con `year_academico = 2026` en tabla `cursos` | Bloqueante si no existen |

### Fase 2 — Módulo de Estudiantes

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| TA-08 | 🔴 | `[x]` | Crear `AcademicYearContext` (año académico global, persistido en localStorage) | ✅ `src/contexts/AcademicYearContext.jsx` |
| TA-09 | 🔴 | `[x]` | Crear componente `YearSelector` reutilizable | ✅ `src/components/ui/YearSelector.jsx` |
| TA-10 | 🔴 | `[x]` | Agregar `YearSelector` al Sidebar | ✅ Visible admin/asist, compact mode |
| TA-11 | 🔴 | `[x]` | Filtrar `StudentsPage` por año académico vía `cursos.year_academico` | ✅ Filtra por año del contexto |
| TA-12 | 🟡 | `[x]` | Agregar columna "Año Académico" a `StudentsTable` | ✅ Badge con año |
| TA-13 | 🟡 | `[x]` | Crear sección "Historial Académico" en `StudentDetailsModal` | ✅ Tabla con año/curso/estado/período |
| TA-14 | 🟢 | `[ ]` | Lógica visual de "liberar espacio": estudiantes 2025 como solo-lectura al filtrar 2025 | Archivado visual sin eliminar |

### Fase 3 — Dashboard y Pagos

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| TA-15 | 🟡 | `[x]` | Filtrar Dashboard (4 StatCards) por `year_academico` del contexto global | ✅ Usa `academicYear` del contexto |
| TA-16 | 🟡 | `[x]` | Filtrar gráficos (DebtTrend, DebtDistribution, PaymentProjection) por año | ✅ Prop `academicYear` |
| TA-17 | 🟡 | `[x]` | Filtrar `DebtorsTable` por año académico | ✅ Prop `academicYear` |
| TA-18 | 🟡 | `[ ]` | `PaymentsPage`: cambiar filtro de `due_date.year` a `fee.year_academico` | Categorización incorrecta actual |

### Fase 4 — UI/UX y Promoción Masiva

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| TA-19 | 🟡 | `[ ]` | Crear componente `PromotionTool.jsx` (promoción masiva con preview y confirmación) | Accesible desde Sidebar (admin) |
| TA-20 | 🟡 | `[ ]` | Agregar entrada "Promoción" al Sidebar para admin | Nuevo menú |
| TA-21 | 🟢 | `[x]` | Cambiar ícono de Matrícula en Sidebar (actualmente repite el de Apoderados) | ✅ `ClipboardCheck` + `ArrowsRepeat` para Repactación |
| TA-22 | 🟢 | `[ ]` | Corregir nomenclatura de estados: MATRICULADO→Pre-Matriculado, ACTIVO→Confirmado, RETIRADO | Mapeo confuso actualmente |
| TA-23 | 🟢 | `[ ]` | Agregar tabs en `StudentDetailsModal`: Datos | Historial | Fees | Documentos | Mejor organización de info |

---

## Generación de Fees y Finanzas

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| FE-01 | 🔴 | `[ ]` | Verificar que fees generados en `finalize_enrollment` incluyan `year_academico` correcto | Ya funciona parcialmente |
| FE-02 | 🟡 | `[ ]` | Asegurar que fees no se dupliquen al re-ejecutar matrícula | Unique index existe, verificar idempotencia |
| FE-03 | 🟡 | `[ ]` | Separar fees por año en vista de pagos del guardian | Portal guardian sin contexto de año |
| FE-04 | 🟢 | `[ ]` | Dashboard financiero: comparativa año actual vs anterior | Nuevo gráfico |

---

## UI/UX — Mejoras de Interfaz

| ID | Pri | Estado | Descripción | Notas |
|----|-----|--------|-------------|-------|
| UX-01 | 🟡 | `[x]` | Indicador de año académico activo visible en toda la app | ✅ Badge en Dashboard y StudentsPage + Sidebar selector |
| UX-02 | 🟢 | `[ ]` | Mejorar responsive de tablas en móvil | Tablas se cortan en pantallas pequeñas |
| UX-03 | 🟢 | `[ ]` | Agregar breadcrumbs de navegación | Mejor orientación del usuario |
| UX-04 | ⚪ | `[ ]` | Modo oscuro: revisar contrastes en componentes nuevos | Ya existe dark mode parcial |

---

## Bugs Pendientes (Legacy)

> Migrados desde BACKLOG original (mayo 2025). Verificar vigencia.

| ID | Pri | Estado | Descripción | Origen |
|----|-----|--------|-------------|--------|
| BG-01 | 🟡 | `[ ]` | No se cambia automáticamente el nombre en los detalles de los apoderados | May 2025 |
| BG-02 | 🟡 | `[ ]` | `StudentFormModal.jsx`: no persisten datos existentes previo a modificación | May 2025 |
| BG-03 | 🟡 | `[ ]` | Ícono de ojo en estudiantes asociados a apoderado no muestra información | May 2025 |
| BG-04 | 🟡 | `[ ]` | No se muestra RUT de estudiante al acceder desde ícono de ojo en detalle de apoderados | May 2025 |
| BG-05 | 🟡 | `[ ]` | Filtros de reportes no funcionan, no se generan resultados | May 2025 |

---

## Mejoras Pendientes (Legacy)

> Migrados desde BACKLOG original (mayo 2025).

| ID | Pri | Estado | Descripción | Origen |
|----|-----|--------|-------------|--------|
| MJ-01 | 🟢 | `[ ]` | Añadir función de lápiz para editar campos inline | May 2025 |
| MJ-02 | 🟢 | `[ ]` | Mostrar detalle de deuda por cada apoderado | May 2025 |
| MJ-03 | 🟢 | `[ ]` | Crear reportes de deudas por apoderados | May 2025 |
| MJ-04 | 🟡 | `[ ]` | Los cambios en datos no se reflejan inmediatamente (cache/refresh) | May 2025 |
| MJ-05 | ⚪ | `[ ]` | Correos largos salen del menú de perfiles (overflow) | May 2025 |

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

- **IDs con prefijo**: `TA-` (Transición Anual), `FE-` (Fees), `UX-` (UI/UX), `BG-` (Bug), `MJ-` (Mejora), `AR-` (Archivo)
- Cada item tiene un ID único que no se reutiliza
- Al completar un item, mover a la sección de archivo correspondiente o marcar `[x]`
- Para items nuevos, agregar al final de la sección correspondiente con el siguiente ID disponible

### Decisiones técnicas pendientes

| Fecha | Decisión | Estado |
|-------|----------|--------|
| 2026-03-02 | ¿Renombrar estados en DB (MATRICULADO→PRE_MATRICULADO) o solo mapear en UI? | Pendiente |
| 2026-03-02 | ¿Promoción masiva crea matrícula formal o solo pre-asigna curso? | Pendiente |
| 2026-03-02 | ¿Cursos 2026 se crean manualmente o se clonan de 2025? | Pendiente |
