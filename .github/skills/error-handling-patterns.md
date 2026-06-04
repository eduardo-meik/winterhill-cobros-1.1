---
name: error-handling-patterns
description: "Use when implementing error boundaries, API error responses, retry logic, stream error recovery, or structured error logging. Covers UI error boundaries, typed API errors, and SSE stream patterns."
---

# Error Handling Patterns — Gestión Escolar

## Overview

Convenciones de manejo de errores para **Gestión Escolar**. Stack: React Vite + Supabase. Cubre: error boundaries (UI), API error responses, retry patterns y logging estructurado.

## Checklist Obligatorio

### 1. Error Boundaries (UI)

Cada route group debe tener su propio `error.tsx` (Next.js) o error boundary (React):

```typescript
// error.tsx (Next.js App Router)
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('[ErrorBoundary]', {
      message: error.message,
      digest: error.digest,
      timestamp: new Date().toISOString(),
    });
  }, [error]);

  return (
    <div>
      <h2>Algo salió mal</h2>
      <button onClick={reset}>Intentar de nuevo</button>
    </div>
  );
}
```

**Reglas:**
- NUNCA mostrar `error.message` al usuario (puede contener datos internos)
- Loggear el error con contexto estructurado
- Proveer acción de recovery (`reset`, retry, volver al inicio)

### 2. Errores Tipados de API

```typescript
export class ApiError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 500
  ) {
    super(message);
  }
}

export class ApiValidationError extends ApiError {
  constructor(public details?: unknown) {
    super('VALIDATION_ERROR', 'Validation failed', 400);
  }
}

// Uso en endpoints:
throw new ApiError('NOT_FOUND', 'Resource not found', 404);
throw new ApiError('FORBIDDEN', 'Insufficient permissions', 403);
```

```typescript
// Handler centralizado
export function handleApiError(error: unknown) {
  if (error instanceof ApiValidationError) {
    return Response.json({
      success: false,
      error: { code: error.code, message: error.message, details: error.details },
    }, { status: 400 });
  }

  if (error instanceof ApiError) {
    return Response.json({
      success: false,
      error: { code: error.code, message: error.message },
    }, { status: error.statusCode });
  }

  console.error('Unhandled API error:', error);
  return Response.json({
    success: false,
    error: { code: 'INTERNAL_ERROR', message: 'Internal server error' },
  }, { status: 500 });
}
```

### 3. Retry con Backoff Exponencial

```typescript
interface RetryOptions {
  maxRetries: number;
  baseDelay: number;
  maxDelay: number;
  retryableStatuses: number[];
}

const DEFAULTS: RetryOptions = {
  maxRetries: 3,
  baseDelay: 1000,
  maxDelay: 10000,
  retryableStatuses: [429, 502, 503],
};

export async function fetchWithRetry(
  url: string,
  options: RequestInit,
  retryOptions = DEFAULTS
): Promise<Response> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= retryOptions.maxRetries; attempt++) {
    try {
      const response = await fetch(url, options);
      if (!retryOptions.retryableStatuses.includes(response.status)) {
        return response;
      }
      lastError = new Error(`HTTP ${response.status}`);
    } catch (error) {
      lastError = error as Error;
    }

    if (attempt < retryOptions.maxRetries) {
      const delay = Math.min(
        retryOptions.baseDelay * Math.pow(2, attempt),
        retryOptions.maxDelay
      );
      await new Promise((r) => setTimeout(r, delay));
    }
  }

  throw lastError;
}
```

### 4. Logging Estructurado

```typescript
function logError(message: string, error: unknown, context: Record<string, string> = {}) {
  const log = {
    severity: 'ERROR',
    message,
    context,
    error: error instanceof Error
      ? { name: error.name, message: error.message }
      : { name: 'Unknown', message: String(error) },
    timestamp: new Date().toISOString(),
  };
  console.error(JSON.stringify(log));
}
```

**Reglas de logging:**
- NUNCA loggear: email, nombre completo, tokens, passwords, request body con PII
- SIEMPRE loggear: userId (UID), route path, status code, timestamp
- Stack traces solo en `development`

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| E1 | Route group sin error boundary |
| E2 | `error.message` expuesto al usuario en UI |
| E3 | `try/catch` vacío o con solo `console.log` |
| E4 | API route sin `handleApiError()` centralizado |
| E5 | Log con email, nombre o token de usuario |
| E6 | Stack trace en producción |
| E7 | Fetch a endpoint externo sin retry para 429/503 |
| E8 | Error 500 genérico sin código de error tipado |
