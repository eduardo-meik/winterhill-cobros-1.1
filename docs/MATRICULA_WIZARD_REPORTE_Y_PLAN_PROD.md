# Matrícula Wizard — Reporte + Plan de Acción (Production-Ready)

Fecha: 2025-12-18  
Rama: `html_pdf`  
Alcance: flujo completo de `src/components/matricula/MatriculaWizard.jsx` y sus integraciones con Supabase (`enrollments`, `enrollment_students`, `enrollment_documents`, `cheques`, `fee`) y RPC `finalize_enrollment`.

## 1) Resumen Ejecutivo

### Objetivo
Asegurar consistencia end-to-end y resiliencia del flujo de matrícula (wizard) para:
- Datos económicos (global vs por estudiante)
- Forma de pago (especialmente cheques)
- Generación de documentos (Contrato PRESTACION, Pagaré/Anexos)
- Finalización (generación de cuotas en `fee`) 

### Hallazgo crítico (impacto producción)
Se detectó pérdida de vínculo entre cheques y documento:
- Existen múltiples `cheques` por `enrollment_id` con `document_id IS NULL`.
- Esto ocurre por persistencia “temprana”/asíncrona de cheques (sin documento) y por la existencia de múltiples documentos `PRESTACION` generados por el mismo enrollment.

Evidencia (DB de usuario):
- Enrollment con 70 cheques, 40 sin `document_id`.
- Enrollment con 20 cheques, 10 sin `document_id`.
- Enrollment con 20 cheques, 20 sin `document_id`.

Además, se observan múltiples `PRESTACION` por enrollment (reintentos/generaciones repetidas), lo que genera ambigüedad de “documento vigente”.

### Principios Production-Ready (propuestos)
- **Fuente única de verdad** para plan/montos: contrato + finalize deben consumir el mismo plan.
- **Persistencia transaccional y determinística**: evitar “delete+insert” repetido sin necesidad, evitar carreras.
- **Compatibilidad hacia atrás**: no romper datos existentes y proveer scripts de reparación.
- **Rollout seguro**: cambios graduales con auditoría, verificación y rollback.

---

## 2) Arquitectura Actual (mapa de flujo)

### Paso 0 — Selección de alumnos
**UI/Estado**: `year`, `assistedMode`, `allMyStudents`, `students`, `debtInfo`, `hasRegularized`, `debtDoc`.  
**DB**:
- Inserta/borra en `enrollment_students`.
- Enrollment se obtiene/crea en `enrollments`.

**Gating**:
- Requiere `students.length > 0`.
- Bloquea si existe deuda y no hay documento de regularización.

### Paso 1 — Datos Económicos y Forma de Pago
**Inputs reales por estudiante**: `studentEconomicMap[studentId]`:
- `monto_matricula`, `colegiatura_anual`, `cantidad_cuotas`, `dia_vencimiento`, `porcentaje_descuento`, `prioritario`, `curso_sugerido`

**Resumen consolidado**:
- `aggregatedEconomicTotals` (matrícula/colegiatura/descuento/neto) y `totalNetMonthlyInstallment`.

**Persistencia**:
- `updateEnrollmentMeta(enrollment.id, patch)` (merge superficial).
- `patch.per_student_economic = studentEconomicMap`.
- Se genera `patch.payment_plan` usando `buildEnrollmentPaymentPlan()`.

**Cheques**:
- Modal `ChequesDataModal` guarda localmente y además persiste `saveChequesForEnrollment()` en background (sin `documentId`).

### Paso 2 — Vista previa, documentos y finalize
**Documentos**:
- `createPrestacionDocument()` inserta `enrollment_documents` con `type='PRESTACION'`, `generated_payload`, `final_content` (si existe).
- Si hay cheques seleccionados, el flujo intenta volver a persistir cheques con `document_id` + `folio_number`.

**Finalize**:
- `finalizeEnrollmentPreview/Confirm` llaman RPC `finalize_enrollment` con `skip_doc_checks: true`.
- La RPC genera `fee` por estudiante x cuota con idempotencia en `ux_fee_student_year_cuota`.
- Resolución de plan en RPC: `options.payment_plan` > `enrollments.meta.payment_plan` > `enrollment_documents.generated_payload`.

---

## 3) Problemas y Riesgos (priorizados)

### P0 — Cheques sin `document_id` (trazabilidad rota)
**Causa raíz**:
- `saveChequesForEnrollment()` usa estrategia “replace”: `DELETE` + `INSERT`.
- Se llama desde el modal sin `documentId` (background), y luego nuevamente al generar documento.
- Si el orden de ejecución es: guardar con doc → luego corre autosave sin doc, se pierde el vínculo.
- Además: existen múltiples `PRESTACION` por enrollment; no hay “documento canónico”.

**Impacto**:
- Consultas/impresiones/auditoría por documento fallan o son incompletas.
- UX inconsistente ("yo ya cargué cheques" pero no quedan ligados a la prestación).

### P0 — Inconsistencia de fuente de verdad (contrato ≠ finalize)
**Causa raíz**:
- Resumen y plan se derivan desde fuentes diferentes según el paso:
  - Inputs reales: `studentEconomicMap`.
  - Contrato: `enrollment.meta` (preferido) + fallback a `economic` global.
  - Finalize preview: plan reconstruido desde agregados actuales.

**Impacto**:
- Usuario ve un contrato con valores y el sistema genera cuotas distintas (riesgo legal/operacional).

### P1 — Finalize sin verificación documental
**Hecho actual**:
- Frontend siempre envía `skip_doc_checks: true`.

**Impacto**:
- Se pueden generar cuotas (`fee`) sin firmas requeridas (si ese era el control original).

### P1 — Migraciones y divergencia de esquemas
**Hecho**:
- `prompt/Recent Schema Migrations.json` enumera migraciones tempranas (feb–may 2025) y no contiene las de matrícula (sep–dic 2025 del repo).

**Impacto**:
- No se puede asumir el esquema real sin auditar tabla `supabase_migrations.schema_migrations`.

---

## 4) Recomendación de Diseño (robusta)

### A) Definir un “Contract Snapshot” canónico
**Objetivo**: que contrato, cheques y finalización usen el mismo snapshot.

Propuesta:
- En el momento de “Generar Vista Previa” (Paso 2), construir un objeto `contract_snapshot` (JSON) con:
  - `per_student_economic` (normalizado)
  - `aggregated_totals`
  - `payment_method_flags`
  - `payment_plan` (el plan final que se usará)
  - `cheques` (si aplica)
- Guardarlo en:
  - `enrollment_documents.generated_payload` (ya existe)
  - y opcionalmente en `enrollments.meta.contract_snapshot_latest` (para acceso rápido).

### B) Cheques: enlace determinístico y sin carreras
**Objetivo**: eliminar cheques huérfanos y evitar pérdidas.

Propuesta recomendada (mínimo riesgo):
1) En el modal, **guardar sólo local** (estado UI). No persistir en background si no existe `documentRecord.id`.
2) Al generar `PRESTACION`:
   - Persistir cheques una sola vez con `document_id = doc.id` y `folio_number`.
3) Si se requiere persistencia temprana (modo asistido):
   - Persistir con `document_id` apuntando al **último PRESTACION existente** (si existe), o dejar sin `document_id` pero **bloquear** el autosave posterior que pueda pisar datos.

Mejora alternativa (más robusta, requiere cambios DB o de servicio):
- Cambiar de “delete+insert” a **upsert por (enrollment_id, numero_cuota)**.

### C) Finalize: endurecer controles por rol
Propuesta:
- **Guardian**: `skip_doc_checks=false` en confirmación.
- **Staff (ADMIN/ASIST)**: se permite `skip_doc_checks=true` con auditoría/flag explícito.

---

## 5) Plan de Acción (Production-Ready)

### Fase 0 — Auditoría (sin cambios)
1) Ejecutar script de auditoría:
   - Verificar columnas, índices, policies, funciones.
   - Confirmar migraciones aplicadas (`supabase_migrations.schema_migrations`).
2) Medir estado actual:
   - `cheques` sin `document_id` por enrollment.
   - conteo de `PRESTACION` por enrollment.

### Fase 1 — Salvaguarda de datos existentes (DB repair)
**Objetivo**: vincular cheques huérfanos al documento correcto sin perder información.

Regla de enlace recomendada:
- Para cheques de colegiatura, asignar al último `PRESTACION` por enrollment.

SQL (idempotente):
```sql
update public.cheques c
set document_id = d.id,
    folio_number = upper(left(d.id::text, 8))
from (
  select distinct on (enrollment_id)
         id, enrollment_id
  from public.enrollment_documents
  where type = 'PRESTACION'
  order by enrollment_id, created_at desc
) d
where c.enrollment_id = d.enrollment_id
  and c.document_id is null;
```

Validación post-repair:
- Re-ejecutar `6b) cheques_linkage` y verificar `without_document_id = 0`.

### Fase 2 — Cambios de aplicación (minimal-risk)
1) Eliminar persistencia background de cheques sin `document_id`.
2) Persistir cheques sólo al generar `PRESTACION` (cuando tenga `doc.id`).
3) Unificar plan:
   - Asegurar que el plan utilizado en contrato sea el mismo plan enviado a finalize.

### Fase 3 — Hardening
1) Endurecer finalize por rol (skip_doc_checks).
2) Reducir duplicidad de documentos:
   - Deshabilitar “generar” si existe documento reciente y no hubo cambios.
   - O marcar `enrollment_documents` con un campo “is_latest” (si se decide a nivel DB).

### Fase 4 — Observabilidad y soporte
- Log estructurado (frontend) del snapshot usado.
- Dashboard/consulta para soporte: enrollment → último PRESTACION → cheques → plan → cuotas.

---

## 6) Script de Auditoría SQL (read-only)

> **Copiar/pegar en Supabase SQL Editor**. No modifica datos; sólo inspecciona esquema, migraciones, RLS/policies y funciones/RPC relacionadas con matrícula/cheques/finalize.

```sql
-- ============================================================
-- WINTERHILL - Auditoría de esquema / RLS / RPC (read-only)
-- Ejecutar en Supabase SQL Editor (o psql) con rol con permisos de lectura.
-- ============================================================

-- 0) Migraciones aplicadas (si existe tabla estándar de Supabase)
-- Si falla, omite esta sección y usa la alternativa 0b.
select '0) schema_migrations' as section, *
from supabase_migrations.schema_migrations
order by version desc;

-- 0b) Alternativa: buscar tablas de migraciones conocidas
-- (descomenta si 0) falla)
-- select schemaname, tablename
-- from pg_tables
-- where tablename ilike '%migrations%' or tablename ilike '%schema_migrations%';

-- 1) Snapshot rápido: columnas críticas esperadas
with expected as (
  select * from (values
    ('public','enrollments','id'),
    ('public','enrollments','guardian_id'),
    ('public','enrollments','year'),
    ('public','enrollments','status'),
    ('public','enrollments','meta'),

    ('public','enrollment_students','enrollment_id'),
    ('public','enrollment_students','student_id'),

    ('public','enrollment_documents','id'),
    ('public','enrollment_documents','enrollment_id'),
    ('public','enrollment_documents','type'),
    ('public','enrollment_documents','status'),
    ('public','enrollment_documents','generated_payload'),
    ('public','enrollment_documents','final_content'),
    ('public','enrollment_documents','content_hash'),

    ('public','cheques','id'),
    ('public','cheques','enrollment_id'),
    ('public','cheques','numero_serie'),
    ('public','cheques','banco'),
    ('public','cheques','fecha_emision'),
    ('public','cheques','monto'),
    ('public','cheques','estado'),
    ('public','cheques','created_by'),
    ('public','cheques','numero_cuota'),
    ('public','cheques','document_id'),
    ('public','cheques','folio_number'),

    ('public','fee','id'),
    ('public','fee','student_id'),
    ('public','fee','guardian_id'),
    ('public','fee','amount'),
    ('public','fee','due_date'),
    ('public','fee','status'),
    ('public','fee','payment_method'),
    ('public','fee','owner_id'),
    ('public','fee','year_academico'),
    ('public','fee','numero_cuota'),
    ('public','fee','enrollment_id'),
    ('public','fee','meta')
  ) as t(table_schema, table_name, column_name)
),
actual as (
  select c.table_schema, c.table_name, c.column_name, c.data_type, c.is_nullable, c.column_default
  from information_schema.columns c
  where c.table_schema='public'
    and c.table_name in ('enrollments','enrollment_students','enrollment_documents','cheques','fee')
)
select
  '1) expected_columns' as section,
  e.table_name,
  e.column_name,
  case when a.column_name is null then 'MISSING' else 'OK' end as status,
  a.data_type,
  a.is_nullable,
  a.column_default
from expected e
left join actual a
  on a.table_schema=e.table_schema and a.table_name=e.table_name and a.column_name=e.column_name
order by e.table_name, e.column_name;

-- 2) Índices clave (cheques y fee idempotencia)
select
  '2) indexes' as section,
  schemaname,
  tablename,
  indexname,
  indexdef
from pg_indexes
where schemaname='public'
  and (
    (tablename='cheques' and indexname ilike '%cheques%')
    or (tablename='fee' and indexname in ('ux_fee_student_year_cuota','idx_fee_due_date','idx_fee_student_id','idx_fee_guardian_id'))
  )
order by tablename, indexname;

-- 3) Constraints clave (FK cheques.document_id y checks)
select
  '3) constraints' as section,
  conrelid::regclass as table_name,
  conname,
  contype,
  pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid::regclass::text in ('public.cheques','public.fee','public.enrollment_documents','public.enrollments','public.enrollment_students')
order by conrelid::regclass::text, conname;

-- 4) RLS habilitado + policies
select
  '4) rls_enabled' as section,
  n.nspname as schema,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and c.relname in ('enrollments','enrollment_students','enrollment_documents','cheques','fee')
order by c.relname;

select
  '4b) policies' as section,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_expr,
  with_check
from pg_policies
where schemaname='public'
  and tablename in ('enrollments','enrollment_students','enrollment_documents','cheques','fee')
order by tablename, policyname;

-- 5) Funciones/RPC relevantes (finalize, helpers, metadata)
select
  '5) functions' as section,
  n.nspname as schema,
  p.proname as function_name,
  p.prosecdef as security_definer,
  pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in (
    'finalize_enrollment',
    'is_staff',
    'get_table_metadata',
    'get_guardian_outstanding_debt'
  )
order by p.proname;

-- (Opcional) Ver definición completa de finalize_enrollment
select
  '5b) finalize_enrollment_def' as section,
  pg_get_functiondef(p.oid) as ddl
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname='finalize_enrollment'
limit 1;

-- 6) Sanity checks de datos (NO modifica)
-- 6a) enrollments recientes y meta (muestra tamaño meta)
select
  '6a) enrollments_sample' as section,
  e.id,
  e.year,
  e.status,
  jsonb_typeof(e.meta) as meta_type,
  coalesce(length(e.meta::text),0) as meta_chars,
  e.updated_at
from public.enrollments e
order by e.updated_at desc
limit 20;

-- 6b) cheques huérfanos o sin vínculo a documento (si existen)
select
  '6b) cheques_linkage' as section,
  c.enrollment_id,
  count(*) as cheques_count,
  sum(case when c.document_id is null then 1 else 0 end) as without_document_id,
  sum(case when c.numero_cuota is null then 1 else 0 end) as without_numero_cuota
from public.cheques c
group by c.enrollment_id
order by cheques_count desc
limit 50;

-- 6c) fee duplicados (sólo si NO existe o no aplica el unique index)
select
  '6c) fee_duplicates' as section,
  f.student_id,
  f.year_academico,
  f.numero_cuota,
  count(*) as count_rows
from public.fee f
where f.student_id is not null and f.year_academico is not null and f.numero_cuota is not null
group by f.student_id, f.year_academico, f.numero_cuota
having count(*) > 1
order by count_rows desc
limit 50;
```

**Notas para interpretar resultados:**
- Si en **`1) expected_columns`** aparece `MISSING` en `cheques.numero_cuota/document_id/folio_number`, entonces la DB aún no tiene aplicada `20251217_add_cheques_missing_columns.sql` (o equivalente).
- Si en **`2) indexes`** no aparece `ux_fee_student_year_cuota`, el finalize puede crear duplicados y/o la DB no tiene la migración `20251115_finalize_enrollment_rpc.sql`.
- Si en **`4) rls_enabled`** está `false` para `cheques`/`enrollments`, hay discrepancia con el repo (o se deshabilitó manualmente).
- Si en **`6b) cheques_linkage`** hay enrollments con `without_document_id > 0`, aplicar el script de reparación de la Fase 1

---

## 7) UX: Salvaguardas y comportamiento esperado

### Objetivo UX
- El usuario nunca debe “perder” cheques al navegar entre pasos.
- La vista previa debe corresponder al plan que se finalizea.

### Ajustes UX recomendados
- Mostrar estado: “Cheques guardados localmente” vs “Cheques vinculados al documento (folio XXXXXXXX)”.
- Si el usuario re-genera documento, advertir: “Se creará una nueva versión del contrato. Los cheques se asociarán al documento más reciente”.
- Botón “Guardar datos” debe clarificar qué se persiste: meta + plan + (no necesariamente cheques).

---

## 8) Notas sobre `prompt/Recent Schema Migrations.json`
Este archivo enumera migraciones tempranas (feb–may 2025) enfocadas en RLS/policies y base de tablas (`profiles`, `students`, `fee`, `auth_logs`) y creación de `database_metadata/get_table_metadata`.

No reemplaza la auditoría de migraciones ejecutadas para matrícula/cheques/finalize (sep–dic 2025) presentes en `supabase/migrations/`.

---

## 9) Próximos pasos (decisión)

Elegir enfoque para producción:
- **Opción Recomendada (mínimo riesgo):** persistir cheques sólo al generar `PRESTACION` + repair de DB para cheques existentes.
- **Opción Robusta (más cambios):** upsert cheques por `(enrollment_id, numero_cuota)` + snapshot canónico + finalize con doc checks por rol.

Cuando confirmes la opción, se implementa en código y se valida con un set de pruebas manuales guiadas.
