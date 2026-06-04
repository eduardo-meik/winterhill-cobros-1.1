# Modelo de datos y RLS

Este documento resume el modelo de datos operativo de Winterhill Cobros y cómo se protege con Row Level Security (RLS).

## 1) Objetivo

- Explicar tablas clave y relaciones.
- Describir cómo se filtra acceso por usuario/rol.
- Entregar guías rápidas de diagnóstico para errores de permisos.

---

## 2) Fuente de verdad

- Inventario estructural: `.claude/commands/Public_Schema_Column_Inventory.json`.
- Uso real desde frontend/servicios: consultas de `src/services/*` y `src/components/*`.
- Política y diagnóstico RLS: `RLS_POLICY_REVIEW_2025-11-12.md` y `DIAGNOSTIC_RLS_POLICIES.sql`.

---

## 3) Entidades núcleo (dominio académico-financiero)

## 3.1 Identidad y control
- **`profiles`**: identidad aplicativa del usuario autenticado.
  - Campo clave: `role` (`admin`, `asist`, `guardian`).
- **`auth_logs`** / **`audit_logs`**: trazabilidad operativa y de seguridad.

## 3.2 Personas y relaciones
- **`guardians`**: apoderados/tutores.
  - Campo clave: `owner_id` (relación con `auth.uid()` del usuario dueño).
- **`students`**: alumnos.
  - FK: `curso` → `cursos.id`.
- **`student_guardian`**: tabla puente N:N entre alumnos y apoderados.
  - FKs: `student_id` → `students.id`, `guardian_id` → `guardians.id`.

## 3.3 Matrícula y documentos
- **`enrollments`**: proceso anual por apoderado.
  - FK: `guardian_id` → `guardians.id`.
- **`enrollment_students`**: alumnos incluidos en una matrícula.
  - FKs: `enrollment_id` → `enrollments.id`, `student_id` → `students.id`.
- **`enrollment_documents`**: pagarés/contratos vinculados a matrícula.
  - FK: `enrollment_id` → `enrollments.id`.
- **`document_templates`**: plantillas versionadas de documentos.
- **`signatures`**: evidencia de firma por documento.
  - FK: `enrollment_document_id` → `enrollment_documents.id`.
- **`cheques`**: detalle de cheques asociados a matrícula/documento.

## 3.4 Cobranza
- **`fee`**: cuotas y estado financiero por alumno/apoderado.
  - FKs: `student_id`, `guardian_id`, `enrollment_id`, `fee_curso`.
- **`payment_summary`** (vista): consolidación de pagos/cuotas.

## 3.5 Portal apoderado y soporte
- **`guardian_intake_surveys`**: encuesta/ficha de apoderado por año.
  - FK: `guardian_id` → `guardians.id`.
- **`enrollment_document_receipts`**, **`email_logs`**, **`invoices`**, **`pre_receipts`**: soporte documental y notificaciones.

---

## 4) Relaciones críticas (lectura rápida)

1. Usuario autenticado → `profiles`.
2. Usuario dueño (`auth.uid`) → `guardians.owner_id`.
3. `guardians` ↔ `students` vía `student_guardian`.
4. `guardians` → `enrollments` → `enrollment_students`.
5. `enrollments` → `enrollment_documents` → `signatures`.
6. `students`/`guardians`/`enrollments` → `fee`.

---

## 5) Ciclo de datos por workflow

## 5.1 Alta académica
1. Crear/editar `students`.
2. Crear/editar `guardians`.
3. Vincular en `student_guardian`.

## 5.2 Matrícula
1. Abrir/recuperar `enrollments` por año.
2. Asociar alumnos en `enrollment_students`.
3. Generar registro documental en `enrollment_documents`.
4. Capturar firma en `signatures` cuando corresponda.

## 5.3 Cobranza
1. Crear/actualizar cuotas en `fee`.
2. Consultar estado por dashboard/reportes.
3. Consumir agregados en vistas/reportes.

---

## 6) Estrategia RLS (cómo se protege)

RLS se aplica para asegurar que cada usuario vea/edite solo lo autorizado.

Capas de control:
1. **Autenticación**: sesión válida en Supabase.
2. **RBAC app**: restricciones por `role/profile` en rutas y acciones.
3. **RLS DB**: políticas por fila usando `auth.uid()` + relaciones (`owner_id`, tablas puente).
4. **Funciones seguras (SECURITY DEFINER)**: para casos donde el cliente no debe operar directo.

Principios:
- Mínimo privilegio por defecto.
- Política explícita para staff (`admin`, `asist`) cuando aplique.
- Aislamiento por propietario para `guardian`.

---

## 7) Patrones RLS recomendados en este proyecto

## 7.1 Patrón owner-based
- Tabla con `owner_id` (ej. `guardians`).
- Condición típica: `owner_id = auth.uid()` para apoderado dueño.

## 7.2 Patrón relación N:N
- Validar acceso por existencia en tabla puente (ej. `student_guardian`).
- Útil para consultas de alumnos/cuotas de un apoderado.

## 7.3 Patrón staff override
- Política adicional para staff según `profiles.role` (`admin`, `asist`).
- Mantener diferenciación entre owner y staff para auditoría.

---

## 8) Problemas históricos a vigilar

1. Predicados con UUID incompatibles en joins de RLS (ej. comparar `guardian_id` con `auth.uid()` directamente cuando no representan la misma entidad).
2. Políticas faltantes para tablas usadas por portal apoderado (`students`, `student_guardian`, `fee`, `guardians`).
3. Escrituras desde cliente en tablas de logging con RLS cerrado (preferir RPC segura).
4. Dependencia de funciones sin `SECURITY DEFINER` o sin `search_path` seguro.

Referencia: `RLS_POLICY_REVIEW_2025-11-12.md`.

---

## 9) Diagnóstico rápido de errores RLS

Error típico: `42501` (insufficient_privilege)

Checklist:
1. Validar sesión y `auth.uid()` activo.
2. Verificar `profiles.role` real del usuario.
3. Confirmar relación de negocio (`owner_id`, `student_guardian`, etc.).
4. Revisar políticas activas en `pg_policies`.
5. Confirmar que RLS esté habilitado en `pg_tables.rowsecurity`.

Archivo utilitario: `DIAGNOSTIC_RLS_POLICIES.sql`.

---

## 10) Tablas más usadas por módulo

- **Autenticación/RBAC**: `profiles`, `auth_logs`.
- **Estudiantes**: `students`, `cursos`, `student_guardian`.
- **Apoderados**: `guardians`, `student_guardian`, `guardian_intake_surveys`.
- **Matrícula**: `enrollments`, `enrollment_students`, `enrollment_documents`, `document_templates`, `signatures`, `cheques`.
- **Pagos/Reportes**: `fee`, `payment_summary`.

---

## 11) Convenciones para cambios de esquema

1. Cambios DDL con script versionado (`*.sql`) y validación post-migración.
2. Si se agrega tabla sensible: habilitar RLS desde el inicio.
3. Agregar política owner/staff explícita y pruebas mínimas por rol.
4. Documentar impacto en wiki (modelo + workflow + RBAC).

---

## 12) Referencias cruzadas

- `wiki/01-Workflows.md`
- `wiki/02-RBAC.md`
- `RLS_POLICY_REVIEW_2025-11-12.md`
- `DIAGNOSTIC_RLS_POLICIES.sql`
- `FINAL_SECURITY_AND_PERFORMANCE_FIXES.sql`
- `.claude/commands/Public_Schema_Column_Inventory.json`
