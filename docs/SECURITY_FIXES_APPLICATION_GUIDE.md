# Security Hardening Runbook

## Scope

Documento canonico para aplicar y verificar el hardening de seguridad de Supabase en Winterhill Cobros. Consolida la guia operativa, el plan de remediacion y el checklist posterior.

## Resumen Ejecutivo

Hallazgos principales cubiertos por este runbook:

- Vistas publicas con `SECURITY DEFINER`
- Tabla backup expuesta sin RLS
- Funciones publicas sin `search_path` fijo
- Policies RLS permisivas con `USING(true)` o `WITH CHECK(true)`
- Configuracion de Auth pendiente en Dashboard

Objetivo realista al cerrar este runbook:

- `supabase db lint` con `0 ERRORs`
- Maximo `3 WARNs` residuales aceptados por limitaciones del plan Free o de la plataforma

## Prioridad de Ejecucion

1. Remediacion critica de vistas y tablas publicas
2. Hardening de funciones y policies RLS
3. Configuracion manual de Auth en Dashboard
4. Verificacion tecnica y rerun del linter

## 1. Remediacion Critica

### 1.1 Vistas con `SECURITY DEFINER`

Problema:

- `public.database_metadata`
- `public.payment_summary`

Estas vistas pueden ejecutar consultas con privilegios del creador y bypassear RLS.

Remediacion preferida:

- recrearlas como `SECURITY INVOKER`, o
- eliminarlas si no son necesarias desde la aplicacion

```sql
DROP VIEW IF EXISTS public.database_metadata;
CREATE OR REPLACE VIEW public.database_metadata
    WITH (security_invoker = true)
AS
    SELECT
        c.relname AS table_name,
        CASE c.relkind
            WHEN 'r' THEN 'table'
            WHEN 'v' THEN 'view'
            WHEN 'm' THEN 'materialized view'
        END AS table_type,
        a.attname AS column_name,
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
        AND c.relkind IN ('r', 'v', 'm');
```

Para `payment_summary`, reutilizar el `SELECT` real de la vista antes de recrearla.

### 1.2 Tabla backup publica sin RLS

Problema:

- `public.student_guardian_backup_20241222`

Remediacion preferida:

- eliminar la tabla si era temporal

```sql
DROP TABLE IF EXISTS public.student_guardian_backup_20241222;
```

Si debe conservarse, habilitar y forzar RLS y restringir acceso a staff autorizado.

## 2. Hardening de Base de Datos

### 2.1 `search_path` fijo en funciones publicas

Problema:

- Funciones publicas sin `search_path` fijo son vulnerables a `search_path hijacking`

Patron canonico:

```sql
ALTER FUNCTION public.nombre_funcion() SET search_path = public, pg_temp;
```

Prioridad alta para helpers y funciones usadas por RLS o autenticacion:

- `get_current_user_role()`
- `current_jwt_role()`
- `es_admin_o_equipo()`
- triggers transversales como `set_updated_at()`
- operaciones financieras como `generate_invoice()` y `calculate_enrollment_payment_plan()`

Antes de alterar funciones overload, verificar firma exacta:

```sql
SELECT proname, pg_get_function_identity_arguments(oid)
FROM pg_proc
WHERE proname = '<function_name>'
    AND pronamespace = 'public'::regnamespace;
```

### 2.2 Policies RLS permisivas

Problema:

- Policies con `USING(true)` o `WITH CHECK(true)` equivalen a desactivar RLS en escritura

Tablas que deben revisarse de inmediato:

- `invoices`
- `matriculas_detalle`
- `student_guardian`

Excepcion controlada:

- tablas de logs como `auth_logs` o `audit_logs` pueden requerir otro tratamiento, pero deben justificarse

Patron recomendado:

```sql
CREATE POLICY tabla_staff_policy ON public.mi_tabla
    FOR ALL
    TO authenticated
    USING (is_admin_or_asist())
    WITH CHECK (is_admin_or_asist());
```

## 3. Configuracion Manual de Auth

Menu base en Supabase Dashboard:

- `Authentication`
- `Sign In / Providers`
- `Attack Protection`
- `Sessions`
- `Rate Limits`

### 3.1 OTP Expiry

Cambiar el valor a `600` segundos.

### 3.2 Leaked Password Protection

Estado actual:

- bloqueado en plan Free

Mitigacion en Free:

- mantener validacion fuerte de password en frontend
- activar hCaptcha en `Attack Protection`

### 3.3 PostgreSQL Upgrade

Estado actual:

- no controlable desde este runbook si la plataforma no ofrece upgrade en el plan activo

Mitigacion:

- continuar reduciendo superficie de ataque via RLS y hardening de funciones

### 3.4 Rate Limits y Sessions

Revisar manualmente:

- limite de intentos de email sign-in
- limite de OTP/SMS
- duracion maxima de sesion
- time-boxing de sesiones si aplica por rol

## 4. Observaciones de Diseño del Schema

### 4.1 Policies redundantes

Revisar tablas con policies duplicadas o superpuestas:

- `profiles`
- `students`
- `guardians`
- `student_guardian`
- `enrollments`
- `matriculas_detalle`
- `cursos`

Objetivo:

- reducir redundancia
- evitar brechas escondidas por combinacion OR de policies permissive

### 4.2 Helpers de rol

Estandarizar verificaciones de rol en helpers canonicos como:

- `is_admin_or_asist()`
- `is_staff()`

Evitar mezclar subqueries inline, comparaciones directas y helpers distintos sin criterio.

## 5. Aplicacion

Si la migracion ya existe en `supabase/migrations/`, preferir el flujo versionado:

```bash
supabase db push
```

Para ambiente local:

```bash
supabase db reset --force
```

Solo usar SQL Editor para acciones manuales o diagnostico puntual cuando no exista migracion versionada.

## 6. Verificacion Posterior

Checklist minimo:

- [ ] `supabase db lint` devuelve `0 ERRORs`
- [ ] No existen vistas publicas con `SECURITY DEFINER`
- [ ] No existen tablas publicas sin RLS habilitado
- [ ] Las funciones publicas criticas tienen `search_path = public, pg_temp`
- [ ] No quedan policies de escritura con `USING(true)` o `WITH CHECK(true)` sin justificacion
- [ ] `OTP expiry <= 600`
- [ ] hCaptcha activado si sigue en plan Free
- [ ] Flujos criticos siguen funcionando despues del hardening

Consulta util para verificar configuracion de funciones:

```sql
SELECT p.proname, p.proconfig
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY p.proname;
```

## 7. Warnings Residuales Aceptados

Aceptables temporalmente si no dependen del repo:

- `auth_leaked_password_protection` mientras el proyecto siga en plan Free
- `vulnerable_postgres_version` mientras Supabase no habilite upgrade

No aceptable como residual:

- `auth_otp_long_expiry`, porque si es accionable desde Dashboard

## Referencias

- `supabase/migrations/20260222_security_hardening.sql`
- `docs/COMPLETE_SECURITY_FIXES.md`
- `docs/SECURITY_FIXES_DOCUMENTATION.md`
