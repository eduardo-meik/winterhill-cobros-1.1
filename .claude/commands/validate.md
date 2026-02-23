# Winterhill Cobros – Ultimate Validation Command

> Run everything from the repository root in **PowerShell 7+** on Windows. The command below is intentionally verbose so every failure is obvious. Stop immediately on any error and investigate before proceeding to the next phase.

```powershell
#requires -Version 7.3
$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════" -ForegroundColor Cyan
Write-Host " PHASE 0 – ENVIRONMENT BOOTSTRAP" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════" -ForegroundColor Cyan

# 0.1 Install dependencies with a clean node_modules folder
if (Test-Path node_modules) { Remove-Item node_modules -Recurse -Force }
npm ci

# 0.2 Prepare an isolated env file pointing to the local Supabase stack
Copy-Item .env.example .env.validation -Force

(Get-Content .env.validation) |
  ForEach-Object {
    $_ -replace 'VITE_SUPABASE_URL=your-project-url', 'VITE_SUPABASE_URL=http://127.0.0.1:54321' |
        -replace 'VITE_SUPABASE_ANON_KEY=your-anon-key', 'VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.local-dev-anon-key' |
        -replace 'VITE_GOOGLE_CLIENT_ID=your-google-client-id', 'VITE_GOOGLE_CLIENT_ID=test-google-client-id' |
        -replace 'VITE_SITE_URL=http://localhost:5173', 'VITE_SITE_URL=http://localhost:4173'
  } |
  Set-Content .env.validation

$env:VITE_SUPABASE_URL = 'http://127.0.0.1:54321'
$env:VITE_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.local-dev-anon-key'
$env:VITE_GOOGLE_CLIENT_ID = 'test-google-client-id'
$env:VITE_SITE_URL = 'http://localhost:4173'
$env:VITE_PDF_ENGINE = 'browser'

# 0.3 Ensure Supabase CLI is available
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
  throw 'Supabase CLI is required. Install it via scoop, npm, or the official installer before continuing.'
}

# 0.4 Start the local Supabase stack (Postgres + REST + Auth)
Write-Host "Starting Supabase containers (this can take ~1 minute)..." -ForegroundColor Yellow
supabase stop --force | Out-Null
supabase start --debug | Out-String | Write-Verbose

# 0.5 Reset DB to a pristine state (applies all migrations under supabase/migrations)
supabase db reset --force

# 0.6 Output connection hints for later manual SQL verification
$sbStatus = supabase status --json | ConvertFrom-Json
$env:SUPABASE_DB_URL = $sbStatus.services.db.connectionString
Write-Host "Supabase DB URL: $($env:SUPABASE_DB_URL)" -ForegroundColor DarkCyan

Write-Host "═══════════════════════════════════" -ForegroundColor Green
Write-Host " PHASE 1 – TYPE CHECKING" -ForegroundColor Green
Write-Host "═══════════════════════════════════" -ForegroundColor Green
npx tsc --noEmit --pretty

Write-Host "═══════════════════════════════════" -ForegroundColor Green
Write-Host " PHASE 2 – UNIT TESTS" -ForegroundColor Green
Write-Host "═══════════════════════════════════" -ForegroundColor Green
npm test -- --runInBand --detectOpenHandles

Write-Host "═══════════════════════════════════" -ForegroundColor Magenta
Write-Host " PHASE 3 – USER WORKFLOWS (E2E DRILLS)" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════" -ForegroundColor Magenta

Write-Host "Launching Vite dev server on port 4173..." -ForegroundColor Yellow
$DevServer = Start-Job -ScriptBlock { npm run dev -- --host 127.0.0.1 --port 4173 }
Start-Sleep -Seconds 8

Write-Host "Open a Chromium browser (Edge/Chrome) with the .env.validation context and perform the workflows below." -ForegroundColor Yellow
Write-Host "Use the seeded credentials stored in supabase auth (email: admin@winterhill.test / pass: Winterhill!123)." -ForegroundColor Yellow

Write-Host "--- Workflow A: Admin + Asistente Onboarding & Payment Reconciliation ---" -ForegroundColor White
Write-Host "1. Sign in as admin@winterhill.test -> verify dashboard KPIs render (morosidad, vencidos)." -ForegroundColor Gray
Write-Host "2. Navigate to Estudiantes > Nuevo, create a student per ADMIN_STUDENT_REGISTRATION_CHECKLIST.md." -ForegroundColor Gray
Write-Host "3. Navigate to Apoderados > Nuevo, link the student and complete intake per MANUAL_USUARIO_PLATAFORMA §4." -ForegroundColor Gray
Write-Host "4. Go to Pagos > Registrar Pago, log an installment payment. Confirm FeeTable + PaymentDetailsModal update instantly." -ForegroundColor Gray
Write-Host "5. Run SQL sanity checks:" -ForegroundColor Gray
Write-Host "   psql $env:SUPABASE_DB_URL -c 'select whole_name, status from students order by updated_at desc limit 3;'" -ForegroundColor DarkGray
Write-Host "   psql $env:SUPABASE_DB_URL -c 'select guardian_id, student_id from student_guardian order by created_at desc limit 3;'" -ForegroundColor DarkGray
Write-Host "   psql $env:SUPABASE_DB_URL -c 'select student_id, amount, status from fee order by updated_at desc limit 3;'" -ForegroundColor DarkGray

Write-Host "--- Workflow B: Matricula Wizard + Pagare PDF ---" -ForegroundColor White
Write-Host "1. From the same session open Matricula > Wizard." -ForegroundColor Gray
Write-Host "2. Execute the three-step flow described in WORKFLOW_UPDATE_SUMMARY.md: select students, define economic data, generate preview." -ForegroundColor Gray
Write-Host "3. Download the PDF and verify the rules from MEJORAS_PDF_PAGARE_V2.md (logo, folio, margins, tables not split)." -ForegroundColor Gray
Write-Host "4. Validate html2canvas fallback by forcing VITE_PDF_ENGINE=browser, regenerating the PDF, and ensuring no errors surface in the devtools console." -ForegroundColor Gray

Write-Host "--- Workflow C: Guardian Portal Data Surfaces ---" -ForegroundColor White
Write-Host "1. Sign out admin, sign in as guardian_test@winterhill.test." -ForegroundColor Gray
Write-Host "2. The Guardian Welcome page must show AlertBanner + StatusDashboard with intake status and FeeSummary bars." -ForegroundColor Gray
Write-Host "3. Navigate to /apoderado/portal and verify:" -ForegroundColor Gray
Write-Host "   • Students tab lists all linked students (names, RUN, course)." -ForegroundColor DarkGray
Write-Host "   • Aranceles tab shows FeeTable with correct overdue color coding." -ForegroundColor DarkGray
Write-Host "   • Documentos tab exposes generated pagarés when storage is enabled." -ForegroundColor DarkGray
Write-Host "4. Force-refresh guardian data via DevTools localStorage clear, confirm GuardianContext re-fetches bootstrap data without errors." -ForegroundColor Gray

Write-Host "Once the three workflows succeed, stop the dev server job and Supabase stack." -ForegroundColor Yellow
Stop-Job $DevServer | Out-Null
supabase stop --force | Out-Null
Write-Host "Validation complete ✅" -ForegroundColor Green
```

## Notes & Rationale
- **Supabase auth seeding**: `supabase db reset` runs every SQL migration which already seeds the `admin@winterhill.test` and `guardian_test@winterhill.test` fixtures used by QA. If additional fixtures are needed, append them to `supabase/migrations/<timestamp>_qa_seed.sql`.
- **Manual verifications** are required because critical flows span UI + Supabase RLS; screenshots of each screen plus the SQL sanity queries above serve as artefacts.
- **PDF fallback** is validated manually by forcing `VITE_PDF_ENGINE=browser`, regenerating the pagaré, and confirming the browser console remains clean.

Run this file end-to-end before shipping any feature or hotfix. If any phase fails, the release is blocked until the underlying issue is resolved.

---

# 🔐 Plan de Mejora de Seguridad – Supabase Linter (2026-02-22)

> Basado en el análisis de:
> - `Public_Schema_Column_Inventory.json` (28 tablas/vistas, 4643 líneas)
> - `Row-level_Policy_Inspector.json` (514 líneas, ~50 policies)
> - Resultados del Supabase Database Linter (3 ERRORs, 25+ WARNs)

## Resumen de Hallazgos

| Severidad | Categoría | Cantidad | Riesgo |
|-----------|-----------|----------|--------|
| 🔴 ERROR | `security_definer_view` | 2 | Vistas con SECURITY DEFINER exponen datos sin respetar RLS del usuario que consulta |
| 🔴 ERROR | `rls_disabled_in_public` | 1 | Tabla backup expuesta públicamente sin RLS |
| 🟡 WARN | `function_search_path_mutable` | 25 | Funciones vulnerables a ataques de search_path |
| 🟡 WARN | `rls_policy_always_true` | 7 | Policies con `USING(true)` / `WITH CHECK(true)` en operaciones de escritura |
| 🟡 WARN | `auth_otp_long_expiry` | 1 | OTP con expiración > 1 hora |
| 🟡 WARN | `auth_leaked_password_protection` | 1 | Protección contra contraseñas filtradas deshabilitada |
| 🟡 WARN | `vulnerable_postgres_version` | 1 | Postgres 15.8.1.111 con parches de seguridad pendientes |

---

## FASE 4 – REMEDIACIÓN DE ERRORES CRÍTICOS (SECURITY)

### 4.1 🔴 Eliminar SECURITY DEFINER de vistas públicas

**Problema:** Las vistas `database_metadata` y `payment_summary` usan `SECURITY DEFINER`, lo que hace que las consultas se ejecuten con los permisos del *creador* de la vista, no del usuario autenticado. Esto bypasea RLS completamente.

**Tablas afectadas:** `public.database_metadata`, `public.payment_summary`

**Remediación – opción A (preferida): recrear como SECURITY INVOKER**

```sql
-- 4.1.1  database_metadata → SECURITY INVOKER
DROP VIEW IF EXISTS public.database_metadata;
CREATE OR REPLACE VIEW public.database_metadata
  WITH (security_invoker = true)
AS
  SELECT
    c.relname            AS table_name,
    CASE c.relkind
      WHEN 'r' THEN 'table'
      WHEN 'v' THEN 'view'
      WHEN 'm' THEN 'materialized view'
    END                  AS table_type,
    a.attname            AS column_name,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    CASE WHEN a.attnotnull THEN 'NO' ELSE 'YES' END AS is_nullable,
    pg_get_expr(ad.adbin, ad.adrelid) AS column_default
  FROM pg_catalog.pg_class c
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
  LEFT JOIN pg_catalog.pg_attrdef ad ON ad.adrelid = c.oid AND ad.adnum = a.attnum
  WHERE n.nspname = 'public'
    AND a.attnum > 0
    AND NOT a.attisdropped
    AND c.relkind IN ('r','v','m');

-- 4.1.2  payment_summary → SECURITY INVOKER
-- NOTA: Verificar la definición actual antes de ejecutar.
--       Reemplazar el cuerpo con el SELECT original de la vista.
DROP VIEW IF EXISTS public.payment_summary;
CREATE OR REPLACE VIEW public.payment_summary
  WITH (security_invoker = true)
AS
  -- << COPIAR AQUÍ el SELECT original de la vista payment_summary >>
  SELECT 1; -- placeholder – reemplazar con definición real
```

**Remediación – opción B: eliminar las vistas si no se usan desde el frontend**

```sql
-- Solo si la app no las usa:
DROP VIEW IF EXISTS public.database_metadata;
DROP VIEW IF EXISTS public.payment_summary;
```

**Verificación:**
```sql
SELECT viewname, definition
FROM pg_views
WHERE schemaname = 'public'
  AND viewname IN ('database_metadata','payment_summary');
-- Debe devolver 0 filas (opción B) o sin security_definer (opción A)
```

---

### 4.2 🔴 Habilitar RLS o eliminar tabla backup huérfana

**Problema:** `student_guardian_backup_20241222` es una tabla de backup temporal que quedó expuesta vía PostgREST sin RLS. Cualquier usuario autenticado (o anónimo) puede leerla.

**Remediación – opción A (preferida): eliminar la tabla**

```sql
-- Verificar que no haya dependencias
SELECT * FROM pg_depend
WHERE refobjid = 'public.student_guardian_backup_20241222'::regclass;

-- Eliminar tabla backup
DROP TABLE IF EXISTS public.student_guardian_backup_20241222;
```

**Remediación – opción B: habilitar RLS si se necesita conservar**

```sql
ALTER TABLE public.student_guardian_backup_20241222 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_guardian_backup_20241222 FORCE ROW LEVEL SECURITY;

-- Bloquear todo acceso público, solo ADMIN puede consultar
CREATE POLICY backup_admin_only ON public.student_guardian_backup_20241222
  FOR ALL
  TO authenticated
  USING (get_current_user_role() = 'ADMIN');
```

---

## FASE 5 – REMEDIACIÓN DE WARNINGS (SECURITY HARDENING)

### 5.1 🟡 Fijar search_path en TODAS las funciones públicas

**Problema:** 25 funciones no tienen `search_path` fijo, lo que permite ataques de "search_path hijacking" donde un atacante crea objetos en un schema que se resuelve antes que `public`.

**Funciones afectadas (25):**

| # | Función | Prioridad |
|---|---------|-----------|
| 1 | `set_updated_at` | ALTA – trigger usado en múltiples tablas |
| 2 | `update_cheques_updated_at` | ALTA – trigger |
| 3 | `update_student_academic_records_updated_at` | ALTA – trigger |
| 4 | `set_academic_year_dates` | MEDIA |
| 5 | `sync_student_current_curso` | MEDIA |
| 6 | `get_student_course` | MEDIA |
| 7 | `get_enrollment_document_url` | MEDIA |
| 8 | `update_pre_matriculado_students` | MEDIA |
| 9 | `get_current_year_cursos` | MEDIA |
| 10 | `get_student_promotion_suggestion` | MEDIA |
| 11 | `actualizar_estado_std` | MEDIA |
| 12 | `sanitize_run` | ALTA – higiene de datos |
| 13 | `validate_run` | ALTA – validación |
| 14 | `set_fee_owner_default` | ALTA – trigger |
| 15 | `calculate_enrollment_payment_plan` | ALTA – cálculos financieros |
| 16 | `get_current_user_role` | **CRÍTICA** – usada en la mayoría de RLS policies |
| 17 | `suggest_cheques_for_enrollment` | MEDIA |
| 18 | `current_academic_year` | MEDIA |
| 19 | `es_admin_o_equipo` | ALTA – usada en RLS |
| 20 | `generate_invoice` | ALTA – operación financiera |
| 21 | `trg_mark_document_signed_from_signature` | MEDIA – trigger |
| 22 | `trg_mark_document_signed_from_receipt` | MEDIA – trigger |
| 23 | `required_enrollment_documents_state` | MEDIA |
| 24 | `current_jwt_role` | **CRÍTICA** – autenticación |
| 25 | `generate_libro_matricula_report` | MEDIA |

**Remediación – Script batch:**

```sql
-- Patrón: ALTER FUNCTION <name>(...args...) SET search_path = public, pg_temp;
-- Ejecutar en orden de prioridad CRÍTICA primero

-- CRÍTICAS (usadas en RLS / autenticación)
ALTER FUNCTION public.get_current_user_role() SET search_path = public, pg_temp;
ALTER FUNCTION public.current_jwt_role() SET search_path = public, pg_temp;
ALTER FUNCTION public.es_admin_o_equipo() SET search_path = public, pg_temp;

-- ALTAS (triggers y operaciones financieras)
ALTER FUNCTION public.set_updated_at() SET search_path = public, pg_temp;
ALTER FUNCTION public.update_cheques_updated_at() SET search_path = public, pg_temp;
ALTER FUNCTION public.update_student_academic_records_updated_at() SET search_path = public, pg_temp;
ALTER FUNCTION public.set_fee_owner_default() SET search_path = public, pg_temp;
ALTER FUNCTION public.calculate_enrollment_payment_plan() SET search_path = public, pg_temp;
ALTER FUNCTION public.sanitize_run() SET search_path = public, pg_temp;
ALTER FUNCTION public.validate_run() SET search_path = public, pg_temp;
ALTER FUNCTION public.generate_invoice() SET search_path = public, pg_temp;

-- MEDIAS (resto)
ALTER FUNCTION public.set_academic_year_dates() SET search_path = public, pg_temp;
ALTER FUNCTION public.sync_student_current_curso() SET search_path = public, pg_temp;
ALTER FUNCTION public.get_student_course() SET search_path = public, pg_temp;
ALTER FUNCTION public.get_enrollment_document_url() SET search_path = public, pg_temp;
ALTER FUNCTION public.update_pre_matriculado_students() SET search_path = public, pg_temp;
ALTER FUNCTION public.get_current_year_cursos() SET search_path = public, pg_temp;
ALTER FUNCTION public.get_student_promotion_suggestion() SET search_path = public, pg_temp;
ALTER FUNCTION public.actualizar_estado_std() SET search_path = public, pg_temp;
ALTER FUNCTION public.suggest_cheques_for_enrollment() SET search_path = public, pg_temp;
ALTER FUNCTION public.current_academic_year() SET search_path = public, pg_temp;
ALTER FUNCTION public.trg_mark_document_signed_from_signature() SET search_path = public, pg_temp;
ALTER FUNCTION public.trg_mark_document_signed_from_receipt() SET search_path = public, pg_temp;
ALTER FUNCTION public.required_enrollment_documents_state() SET search_path = public, pg_temp;
ALTER FUNCTION public.generate_libro_matricula_report() SET search_path = public, pg_temp;
```

> ⚠️ **NOTA:** Si alguna función tiene argumentos con overloads, verificar la firma completa con:
> ```sql
> SELECT proname, pg_get_function_identity_arguments(oid) FROM pg_proc WHERE proname = '<function_name>' AND pronamespace = 'public'::regnamespace;
> ```

---

### 5.2 🟡 Endurecer RLS Policies con `USING(true)` / `WITH CHECK(true)`

**Problema:** 7 policies permiten operaciones de escritura sin restricciones, lo que equivale a desactivar RLS para esas operaciones.

| Tabla | Policy | Comando | Riesgo |
|-------|--------|---------|--------|
| `auth_logs` | `auth_logs_insert_all` | INSERT | BAJO – tabla de log, INSERT abierto es intencional |
| `invoices` | `invoices_authenticated_policy` | ALL | **ALTO** – cualquier autenticado puede CRUD facturas |
| `matriculas_detalle` | `matriculas_detalle_delete_policy` | DELETE | **ALTO** – cualquier autenticado puede borrar |
| `matriculas_detalle` | `matriculas_detalle_insert_policy` | INSERT | **ALTO** – cualquier autenticado puede insertar |
| `matriculas_detalle` | `matriculas_detalle_update_policy` | UPDATE | **ALTO** – cualquier autenticado puede editar |
| `student_guardian` | `student_guardian_authenticated_policy` | ALL | **ALTO** – cualquier autenticado puede manipular relaciones |
| `audit_logs` | `audit_logs_postgres_insert` | INSERT | BAJO – log interno |

**Remediación:**

```sql
-- 5.2.1  invoices → restringir a ADMIN / FINANCE_MANAGER
DROP POLICY IF EXISTS invoices_authenticated_policy ON public.invoices;
CREATE POLICY invoices_staff_policy ON public.invoices
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST', 'FINANCE_MANAGER')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('ADMIN', 'ASIST', 'FINANCE_MANAGER')
    )
  );

-- 5.2.2  matriculas_detalle → restringir escritura a staff
DROP POLICY IF EXISTS matriculas_detalle_delete_policy ON public.matriculas_detalle;
DROP POLICY IF EXISTS matriculas_detalle_insert_policy ON public.matriculas_detalle;
DROP POLICY IF EXISTS matriculas_detalle_update_policy ON public.matriculas_detalle;

CREATE POLICY matriculas_detalle_staff_write ON public.matriculas_detalle
  FOR ALL
  TO authenticated
  USING (is_admin_or_asist())
  WITH CHECK (is_admin_or_asist());
-- Nota: mantener matriculas_detalle_read_policy (SELECT, USING true) para lectura pública

-- 5.2.3  student_guardian → restringir a staff + owner
DROP POLICY IF EXISTS student_guardian_authenticated_policy ON public.student_guardian;
-- Las policies student_guardian_admin_access y student_guardian_asist_access ya cubren staff.
-- Agregar policy para guardians que son dueños:
CREATE POLICY student_guardian_owner_policy ON public.student_guardian
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = student_guardian.guardian_id
        AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = student_guardian.guardian_id
        AND g.owner_id = auth.uid()
    )
  );

-- 5.2.4  auth_logs INSERT → aceptable pero agregar rate-limit check
-- DECISIÓN: Mantener auth_logs_insert_all como está (tabla de log).
-- Considerar agregar constraint de rate-limit en la app.

-- 5.2.5  audit_logs INSERT → aceptable (log interno del sistema)
-- DECISIÓN: Mantener audit_logs_postgres_insert como está.
```

---

## FASE 6 – CONFIGURACIÓN DE AUTH Y PLATAFORMA (Manual – Dashboard)

> 📍 Menú de Supabase Authentication:
> `Users | OAuth Apps | Notifications > Email | Configuration > Policies |`
> `Sign In / Providers | OAuth Server | Sessions | Rate Limits |`
> `Multi-Factor | URL Configuration | Attack Protection | Auth Hooks | Audit Logs | Performance`

### 6.1 🟡 Reducir expiración de OTP

**Problema:** El OTP de email expira en más de 1 hora, incrementando la ventana de ataque.

**Paso a paso:**
1. Abrir **Supabase Dashboard** → Panel izquierdo → **Authentication**
2. En el submenú ir a **Sign In / Providers**
3. Buscar la sección **Email** → clic para expandir
4. Localizar el campo **OTP Expiry** (en segundos)
5. Cambiar de su valor actual (>3600) a **600** (10 minutos)
6. Clic en **Save**

> 💡 Ref: https://supabase.com/docs/guides/platform/going-into-prod#security

### 6.2 � ~~Habilitar protección de contraseñas filtradas~~ — BLOQUEADO (Plan Free)

**Problema:** La protección contra contraseñas comprometidas (HaveIBeenPwned) está deshabilitada.

**Estado:** ❌ **NO DISPONIBLE en plan Free.** Requiere plan **Pro ($25/mes)** o superior.

**Ubicación en Dashboard (para futuro upgrade):**
1. **Authentication → Attack Protection**
2. Toggle **Prevent use of leaked passwords** → ON

**Mitigación alternativa en plan Free:**
- Implementar validación de fortaleza de contraseña en el frontend (mínimo 8 chars, mayúsculas, números, símbolo)
- Ya existe en el flujo de registro; verificar que se aplique también en cambio de contraseña

**Acción sí disponible en Free:**
1. **Authentication → Attack Protection**
2. Toggle **Enable Captcha protection** → ON (hCaptcha gratuito)
   - Registrarse en https://www.hcaptcha.com/ para obtener Site Key y Secret Key
   - Configurar ambas keys en el formulario que aparece al activar

> 💡 Ref: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

### 6.3 � ~~Actualizar versión de PostgreSQL~~ — NO DISPONIBLE

**Problema:** `supabase-postgres-15.8.1.111` tiene parches de seguridad pendientes.

**Estado actual verificado (Feb 2026):**
| Componente | Versión |
|---|---|
| Auth | 2.186.0 |
| PostgREST | 12.2.3 |
| Postgres | 15.8.1.111 |

**Estado:** ❌ **No hay opción de upgrade disponible** en el Dashboard.

Esto puede deberse a:
- Plan Free no ofrece upgrades de Postgres bajo demanda
- Supabase aún no ha liberado el parche para la plataforma free-tier

**Mitigación:**
- Las mejoras de RLS/search_path de esta migración (`20260222_security_hardening.sql`) reducen significativamente la superficie de ataque independientemente de la versión de Postgres
- Monitorear periódicamente **Project Settings → Infrastructure** para cuando aparezca la opción
- Considerar upgrade a plan Pro si se requiere control sobre versiones de Postgres

> 💡 Ref: https://supabase.com/docs/guides/platform/upgrading

### 6.4 🟡 (Recomendado) Revisar Rate Limits

**Paso a paso adicional:**
1. **Authentication → Rate Limits**
2. Verificar que los límites están configurados para:
   - Email sign-in: ≤ 5 intentos por minuto
   - SMS OTP: ≤ 3 por minuto
   - Token refresh: razonable para tu tráfico

### 6.5 🟡 (Recomendado) Revisar Sessions

**Paso a paso adicional:**
1. **Authentication → Sessions**
2. Verificar **Time-box user sessions** → activar si no está activo
3. Configurar duración máxima de sesión según necesidad (ej: 24h para staff, 7d para guardians)

---

## FASE 7 – OBSERVACIONES ADICIONALES DEL SCHEMA

### 7.1 Policies duplicadas / redundantes detectadas

| Tabla | Policies potencialmente redundantes | Recomendación |
|-------|--------------------------------------|---------------|
| `profiles` | `profiles_own_record` + `profiles_owner_policy` | Ambas usan `id = auth.uid()`. Eliminar una |
| `students` | `students_admin_access` + `students_admin_asist_full_access` | La segunda ya cubre ambos roles. Eliminar `students_admin_access` y `students_asist_access` |
| `guardians` | `guardians_admin_access` + `guardians_asist_access` + `guardians_staff_all` | `guardians_staff_all` ya cubre ambos. Eliminar las dos primeras |
| `student_guardian` | `student_guardian_admin_access` + `student_guardian_asist_access` | Redundantes si se consolidan con la policy propuesta en 5.2.3 |
| `enrollments` | `enrollments_admin_asist_access` + `enrollments_admin_full_access` + `enrollments_asist_full_access` | Triple redundancia. Mantener solo una |
| `matriculas_detalle` | `matriculas_detalle_admin_full_access` + `matriculas_detalle_asist_full_access` + nueva `staff_write` | Consolidar en una sola |
| `cursos` | `cursos_admin_full_access` + `cursos_asist_full_access` | Usar `is_admin_or_asist()` y consolidar |

> ⚠️ Las policies PERMISSIVE se combinan con OR. Tener duplicadas no causa errores pero
> dificulta la auditoría y puede enmascarar brechas de seguridad.

### 7.2 Inconsistencia en helpers de rol

Las policies usan **tres patrones distintos** para verificar roles:
1. `get_current_user_role() = 'ADMIN'` — función helper
2. `is_admin_or_asist()` / `is_staff()` — funciones booleanas
3. `EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = ...)` — subquery inline

**Recomendación:** Estandarizar en `is_admin_or_asist()` / `is_staff()` para legibilidad y rendimiento (las funciones pueden cachear el resultado por transacción). Verificar que ambas funciones tengan `search_path` fijo tras la fase 5.1.

### 7.3 Vistas que deberían tener RLS (SECURITY INVOKER)

| Vista | Estado actual | Recomendación |
|-------|---------------|---------------|
| `database_metadata` | SECURITY DEFINER | Cambiar a INVOKER o eliminar (ver 4.1) |
| `payment_summary` | SECURITY DEFINER | Cambiar a INVOKER o eliminar (ver 4.1) |
| `v_current_student_courses` | Sin info | Verificar si tiene SECURITY DEFINER |
| `v_student_academic_history` | Sin info | Verificar si tiene SECURITY DEFINER |

---

## Orden de Ejecución Recomendado

> ✅ **Pasos 1-4 y 8 implementados** en migración: `supabase/migrations/20260222_security_hardening.sql`

```
Paso 1 ─ FASE 4.1  → Eliminar/recrear vistas SECURITY DEFINER     ✅ EN MIGRACIÓN
Paso 2 ─ FASE 4.2  → Eliminar tabla backup huérfana                ✅ EN MIGRACIÓN
Paso 3 ─ FASE 5.1  → Fijar search_path en 25 funciones             ✅ EN MIGRACIÓN
Paso 4 ─ FASE 5.2  → Endurecer 5 RLS policies permisivas           ✅ EN MIGRACIÓN
Paso 5 ─ FASE 6.1  → Reducir OTP expiry                            [2 min, Dashboard]
Paso 6 ─ FASE 6.2  → Leaked password protection                    🚫 BLOQUEADO (Plan Free)
Paso 7 ─ FASE 6.3  → Upgrade PostgreSQL                            🚫 NO DISPONIBLE
Paso 8 ─ FASE 7.1  → Limpiar policies redundantes                  ✅ EN MIGRACIÓN
Paso 9 ─ FASE 6.2b → Activar hCaptcha en Attack Protection         [10 min, Dashboard]
Paso 10 ─ FASE 7.2  → Estandarizar helpers de rol (opcional)       [10 min]
Paso 11 ─ Re-run Supabase Linter → Verificar 0 ERRORs, ≤3 WARNs   [5 min]
```

> 📝 **Nota plan Free:** Los warnings `auth_leaked_password_protection` y `vulnerable_postgres_version`
> **no son resolvables** en el plan actual. El linter seguirá reportándolos. Objetivo realista:
> **0 ERRORs + máximo 3 WARNs residuales** (leaked passwords + postgres version + OTP si no se cambia).

### Para aplicar la migración:
```powershell
# Local (con Supabase CLI):
supabase db reset --force

# Producción (push al proyecto remoto):
supabase db push
```

**Acciones manuales restantes (Dashboard):** Pasos 5, 6, 7 (~8 min)

---

## Checklist de Verificación Post-Remediación

- [ ] `supabase db lint` devuelve 0 errores y ≤3 warnings residuales
- [ ] Todas las funciones públicas muestran `search_path = public, pg_temp` en `pg_proc`
- [ ] No existen vistas con `SECURITY DEFINER` en el schema `public`
- [ ] No existen tablas públicas sin RLS habilitado
- [ ] No existen policies con `USING(true)` en operaciones de escritura (excepto logs)
- [ ] OTP expiry ≤ 600 segundos
- [x] ~~Leaked password protection activada~~ → 🚫 Requiere Plan Pro
- [x] ~~PostgreSQL actualizado~~ → 🚫 Sin upgrade disponible en Free
- [ ] hCaptcha activado en Attack Protection (alternativa gratuita)
- [ ] Tests E2E (FASE 3) pasan sin regresiones tras los cambios de RLS
- [ ] Guardian portal sigue funcionando correctamente (verificar que las policies nuevas no bloquean acceso legítimo)

### Warnings residuales aceptados (Plan Free)

| Warning | Razón | Acción futura |
|---------|-------|---------------|
| `auth_leaked_password_protection` | Requiere Plan Pro ($25/mes) | Activar al migrar a Pro |
| `vulnerable_postgres_version` | Sin upgrade disponible en free-tier | Monitorear Dashboard periódicamente |
| `auth_otp_long_expiry` | **Accionable** – reducir en Dashboard | Paso 5 de este plan |
