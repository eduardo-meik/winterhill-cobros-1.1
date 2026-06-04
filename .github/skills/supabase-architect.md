---
name: supabase-architect
description: "Use when working with Supabase: database queries, RLS policies, Auth, Edge Functions, or Storage. Enforces parameterized queries, RLS by default, and migration-based schema changes."
---

# Supabase Architect — Gestión Escolar

## Overview

Directrices para Supabase como backend de **Gestión Escolar**. RLS activado por defecto, consultas parametrizadas, migraciones versionadas.

## Checklist Obligatorio

### 1. Row Level Security (RLS) — Siempre Activado

**Toda** tabla debe tener RLS habilitado. Sin excepciones.

```sql
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own items"
  ON public.items FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own items"
  ON public.items FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

- Evitar policies de escritura con `USING(true)` o `WITH CHECK(true)` salvo casos muy justificados de auditoria interna.
- Revisar y consolidar policies redundantes; multiples policies permissive se combinan con `OR` y pueden ocultar brechas.
- Preferir helpers canonicos de rol como `is_admin_or_asist()` o `is_staff()` sobre subqueries inline repetidas.

### 2. Consultas Parametrizadas

```typescript
// ✅ Correcto: API builder
const { data, error } = await supabase
  .from('items')
  .select('*')
  .eq('user_id', userId);

// ✅ Correcto: RPC con funciones Postgres
const { data } = await supabase.rpc('get_user_items', { p_user_id: userId });
```

```typescript
// ❌ Prohibido: concatenación de strings
const { data } = await supabase.rpc('raw_query', {
  sql: `SELECT * FROM items WHERE user_id = '${userId}'`
});
```

### 3. Autenticación

- Supabase Auth como única fuente de identidad.
- Validar `auth.uid()` en políticas RLS, no en código de aplicación.
- OAuth providers configurados en dashboard, no redirect URLs hardcodeadas.

### 4. Schema de Base de Datos

Campos obligatorios en toda tabla:
- `id` (UUID, default `gen_random_uuid()`)
- `created_at` (timestamptz, default `now()`)
- `updated_at` (timestamptz, trigger automático)

Migraciones versionadas con `supabase migration new`.

### 4.1 Vistas y funciones seguras

- No usar `SECURITY DEFINER` en vistas del schema `public` salvo justificacion excepcional y auditada.
- Preferir vistas `SECURITY INVOKER` para respetar RLS del usuario autenticado.
- Toda funcion publica debe fijar `search_path = public, pg_temp`, especialmente helpers usados por RLS, auth, triggers y operaciones financieras.
- Si una funcion tiene overloads, verificar la firma exacta antes de alterarla.

```sql
ALTER FUNCTION public.nombre_funcion() SET search_path = public, pg_temp;
```

### 5. Edge Functions

- Deno runtime con TypeScript estricto.
- Validar JWT en cada función.
- No exponer secrets en el código de la función.

### 6. Storage

- Buckets privados por defecto.
- Políticas de acceso como RLS.
- Limitar tamaño y tipo MIME de uploads.

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| SBA1 | Tabla sin RLS habilitado |
| SBA2 | Query con concatenación de strings |
| SBA3 | Migración no versionada (cambio directo en dashboard) |
| SBA4 | Tabla sin `created_at`/`updated_at` |
| SBA5 | Storage bucket público sin justificación |
| SBA6 | Auth token validado solo en cliente |
| SBA7 | Variables sensibles en código de Edge Function |
| SBA8 | Vista pública con `SECURITY DEFINER` sin justificación auditada |
| SBA9 | Función pública sin `search_path = public, pg_temp` |
| SBA10 | Policy de escritura con `USING(true)` o `WITH CHECK(true)` sin justificación |
