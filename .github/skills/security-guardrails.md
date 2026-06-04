---
name: security-guardrails
description: "Use when creating or modifying API routes, handling user input, managing secrets, or reviewing code for security vulnerabilities. Enforces Zod/Pydantic validation, parameterized queries, and OWASP Top 10 prevention."
---

# Security Guardrails — Gestión Escolar

## Overview

Reglas estrictas de seguridad para **Gestión Escolar**. Todo input externo debe validarse antes de cualquier lógica de negocio. Stack: React Vite + Supabase.

## Checklist Obligatorio

### 1. Validación de Datos en el Borde

- **Todo** input externo (formularios, query params, body de API, headers) debe validarse antes de cualquier lógica de negocio.
- En TypeScript/JavaScript usar **Zod** para definir schemas estrictos.
- En Python usar **Pydantic** con `strict=True`.
- Nunca confiar en datos del cliente sin validar en el servidor.

```typescript
// ✅ Correcto: Schema Zod antes del endpoint
import { z } from 'zod';

export const createItemSchema = z.object({
  name: z.string().min(1).max(255),
  price: z.number().positive(),
  email: z.string().email(),
});

type CreateItemInput = z.infer<typeof createItemSchema>;
```

```typescript
// ❌ Incorrecto: Input directo sin validación
const body = await request.json();
await db.insert(body); // Peligroso
```

### 2. Prevención de Inyección SQL

- Usar **siempre** consultas parametrizadas o un ORM.
- Prohibido concatenar strings para construir queries SQL.

| Correcto | Incorrecto |
|:---|:---|
| `supabase.from('items').eq('id', userId)` | `query("SELECT * FROM items WHERE id = '" + id + "'")` |
| `db.execute(text, [param])` | `db.execute(f"SELECT * FROM items WHERE id = {id}")` |

### 3. Prevención de XSS

- Escapar todo contenido dinámico renderizado en HTML.
- No usar `dangerouslySetInnerHTML` ni equivalentes sin sanitización previa con `DOMPurify`.
- Configurar `Content-Security-Policy` headers en producción.

### 4. Autenticación y Autorización

- No implementar auth custom: usar proveedores probados (Supabase Auth, NextAuth, Firebase Auth).
- Validar tokens en cada request del servidor, no solo en el cliente.
- Aplicar principio de mínimo privilegio en roles y permisos.
- Para APIs protegidas, usar un HOF o middleware de auth:

```typescript
// Patrón HOF (Higher-Order Function)
export const POST = withAuth(async (req, ctx, { user, orgId }) => {
  // user ya está verificado
}, { level: 'authenticated' });
```

- Reducir `OTP expiry` a 600 segundos cuando el proveedor lo permita.
- Revisar `Rate Limits`, `Sessions` y `Attack Protection` antes de cada release importante.
- Si el plan no permite leaked password protection, activar al menos captcha y mantener validación fuerte de contraseñas en cliente y servidor.
- No asumir que configuraciones de Auth del dashboard son seguras por defecto; deben formar parte del checklist de salida a producción.

### 5. Secrets y Variables de Entorno

- Nunca hardcodear API keys, tokens o contraseñas en el código.
- Usar `.env` + `.env.example` (sin valores reales) en el repositorio.
- Verificar que `.env` esté en `.gitignore`.
- Variables client-side deben usar prefijo `NEXT_PUBLIC_` o `VITE_`.

### 6. Dependencias

- Ejecutar `npm audit` o `pip audit` antes de cada release.
- No instalar paquetes sin verificar mantenimiento activo y licencia.
- Licencias GPL/AGPL son incompatibles con código propietario.

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| SG1 | Input externo sin validación Zod/Pydantic |
| SG2 | Query SQL con concatenación de strings |
| SG3 | `dangerouslySetInnerHTML` sin sanitización DOMPurify |
| SG4 | Secret hardcodeado en código fuente |
| SG5 | `.env` no incluido en `.gitignore` |
| SG6 | API route sin verificación de auth en servidor |
| SG7 | Dependencia con licencia GPL en proyecto propietario |
| SG8 | Variable sensible expuesta al cliente sin prefijo adecuado |
| SG9 | OTP expiry mayor a 600 segundos sin justificación operativa |
| SG10 | Attack Protection/captcha deshabilitado sin mitigación equivalente |
| SG11 | Configuración de sesiones o rate limits no revisada para producción |
