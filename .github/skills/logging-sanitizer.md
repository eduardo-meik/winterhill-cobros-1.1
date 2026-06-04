---
name: logging-sanitizer
description: "Use when reviewing logs for PII exposure, implementing structured logging, or ensuring GDPR/ISO 27701 compliance in log output. Verifies log integrity, PII masking, and audit trail completeness."
---

# Log Integrity & Privacy Guard — Gestión Escolar

## Overview

Asegurar que los logs de **Gestión Escolar** sean enterprise-ready y cumplan con normativas de privacidad (GDPR, ISO 27701). Stack: React Vite + Supabase.

## Checklist Obligatorio

### 1. Estructura de Logs

| Correcto | Incorrecto |
|:---|:---|
| JSON estructurado `{ level, timestamp, message, context }` | `console.log("error: " + msg)` |
| Niveles `debug`, `info`, `warn`, `error` | Solo `console.log` para todo |
| Context con requestId, userId hasheado | Datos sueltos sin contexto |

### 2. PII Masking

Campos que NUNCA deben aparecer en logs sin enmascarar:

| Campo | Patrón de búsqueda | Acción |
|:---|:---|:---|
| Email | `email`, `correo`, `userEmail` | Enmascarar: `u***@domain.com` |
| Password | `password`, `contraseña`, `pwd` | NUNCA loguear — eliminar |
| Token | `token`, `jwt`, `accessToken` | Truncar: `eyJ...***` |
| Teléfono | `phone`, `telefono`, `celular` | Enmascarar: `+56 9 **** **78` |
| Documento ID | `rut`, `dni`, `ssn` | Enmascarar: `**.***.***-K` |

```typescript
function maskEmail(email: string): string {
  const [user, domain] = email.split('@');
  return `${user[0]}***@${domain}`;
}

function maskToken(token: string): string {
  return token.length > 10 ? `${token.slice(0, 6)}...***` : '***';
}
```

### 3. Eventos de Auditoría Obligatorios

| Evento | Debe loguearse | Nivel mínimo |
|:---|:---|:---|
| Login exitoso | ✅ | `info` |
| Login fallido | ✅ | `warn` |
| Logout | ✅ | `info` |
| Cambio de permisos/rol | ✅ | `warn` |
| Eliminación de datos | ✅ | `warn` |
| Acceso a datos sensibles | ✅ | `info` |
| Error de API no manejado | ✅ | `error` |
| Exportación de datos | ✅ | `info` |

### 4. Helper de Logging

```typescript
interface StructuredLog {
  severity: 'INFO' | 'WARNING' | 'ERROR';
  message: string;
  context: {
    route?: string;
    userId?: string;
    requestId?: string;
  };
  timestamp: string;
}

function log(severity: StructuredLog['severity'], message: string, context = {}) {
  const entry: StructuredLog = {
    severity,
    message,
    context,
    timestamp: new Date().toISOString(),
  };
  const fn = severity === 'ERROR' ? console.error : console.log;
  fn(JSON.stringify(entry));
}
```

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| L1 | `console.log(user)` que expone PII completa |
| L2 | Login/logout sin log de evento |
| L3 | Delete sin auditoría (log antes de eliminar) |
| L4 | Email sin enmascarar en log output |
| L5 | Token o password en log |
| L6 | `console.log` como único mecanismo de logging en producción |
| L7 | Stack trace con paths internos en producción |
