---
name: testing-domain
description: "Use when writing unit tests, integration tests, creating mocks, or setting up test infrastructure. Covers Jest/Vitest patterns, mock strategies, API route testing, and coverage thresholds."
---

# Testing Domain — Gestión Escolar

## Overview

Patrones de testing para **Gestión Escolar**. Stack: React Vite + Supabase. Cubre: unit tests, integration tests, mocks y coverage.

## Stack de Testing

| Herramienta | Uso |
|:---|:---|
| Jest / Vitest | Test runner |
| Testing Library | Component testing |
| MSW | API mocking |

**Threshold:** 40% mínimo (branches, functions, lines, statements)

## Checklist Obligatorio

### 1. Mocks de Backend/DB

El backend NUNCA debe conectarse a producción en tests.

```typescript
// Mock de Supabase
jest.mock('@/lib/supabase', () => ({
  supabase: {
    from: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(),
    eq: jest.fn().mockResolvedValue({ data: [], error: null }),
  },
}));

// Mock de Firebase Admin
jest.mock('@/lib/firebase/admin', () => ({
  adminDb: {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn().mockResolvedValue({ exists: true, data: () => ({}) }),
  },
}));
```

### 2. Testing de API Routes

```typescript
import { POST } from '../route';
import { NextRequest } from 'next/server';

describe('POST /api/items', () => {
  it('should create item with valid payload', async () => {
    const req = new NextRequest('http://localhost/api/items', {
      method: 'POST',
      body: JSON.stringify({ name: 'Test', price: 10 }),
    });

    const res = await POST(req);
    const body = await res.json();

    expect(res.status).toBe(201);
    expect(body.success).toBe(true);
  });

  it('should reject invalid payload', async () => {
    const req = new NextRequest('http://localhost/api/items', {
      method: 'POST',
      body: JSON.stringify({ name: '' }),
    });

    const res = await POST(req);
    expect(res.status).toBe(400);
    expect((await res.json()).error.code).toBe('VALIDATION_ERROR');
  });
});
```

### 3. Testing de Schemas

```typescript
import { createItemSchema } from '@/lib/api/schemas/items';

describe('createItemSchema', () => {
  it('should accept valid input', () => {
    const result = createItemSchema.safeParse({ name: 'Test', price: 10 });
    expect(result.success).toBe(true);
  });

  it('should reject empty name', () => {
    const result = createItemSchema.safeParse({ name: '', price: 10 });
    expect(result.success).toBe(false);
  });
});
```

### 4. Testing RBAC

```typescript
it('should return 403 for unauthorized role', async () => {
  const req = mockAuthenticatedRequest('viewer');
  const res = await POST(req);
  expect(res.status).toBe(403);
});
```

### 5. Testing Multi-tenant

```typescript
it('should not return data from other organizations', async () => {
  const req = mockAuthenticatedRequest('admin', 'org-B');
  const res = await GET(req);
  expect((await res.json()).data).toHaveLength(0);
});
```

## Errores Comunes

| Error | Fix |
|:---|:---|
| `Cannot find module '@/lib/...'` | Verificar moduleNameMapper en jest config |
| `Request is not defined` | Usar `NextRequest` de `next/server` |
| `Timeout - Async callback` | Stream no cerrado — usar `reader.cancel()` |
| `App already initialized` | `jest.clearAllMocks()` en `beforeEach` |

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| TD1 | Test que conecta a DB de producción |
| TD2 | Credenciales reales en test |
| TD3 | Test sin cleanup (estado leak entre tests) |
| TD4 | API protegida sin test de rol incorrecto |
| TD5 | POST endpoint sin test de payload inválido |
| TD6 | Coverage por debajo del threshold |
| TD7 | Test que depende del orden de ejecución |
