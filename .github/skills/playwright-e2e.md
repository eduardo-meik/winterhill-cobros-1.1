---
name: playwright-e2e
description: "Use when writing E2E tests, setting up Playwright, or automating browser interactions. Enforces data-testid selectors, test isolation, explicit waits, and CI/CD integration."
---

# Playwright E2E Testing — Gestión Escolar

## Overview

Testing end-to-end con Playwright para **Gestión Escolar**. Stack: React Vite.

## Estructura

```
tests/
├── e2e/
│   ├── auth.spec.ts       # Flujos login/logout/registro
│   ├── [feature].spec.ts  # Un archivo por feature
│   └── fixtures/
│       └── test-data.ts   # Datos de prueba
├── playwright.config.ts
└── .env.test
```

## Checklist Obligatorio

### 1. Selectores

- `data-testid` como selector principal. No CSS classes ni texto.

```tsx
// En el componente:
<button data-testid="submit-form">Enviar</button>

// En el test:
await page.getByTestId('submit-form').click();
```

- Alternativas accesibles: `getByRole`, `getByLabel`, `getByPlaceholder`.

### 2. Aislamiento

- Cada test independiente. No depender del orden de ejecución.
- Datos de prueba en `beforeEach`, cleanup en `afterEach`.
- `test.describe` para agrupar por feature.

### 3. Esperas Explícitas

```typescript
// ✅ Correcto: espera explícita
await expect(page.getByTestId('list')).toBeVisible();
await page.waitForResponse('**/api/items');

// ❌ Incorrecto: timeout arbitrario
await page.waitForTimeout(3000);
```

### 4. Page Object Pattern

```typescript
class LoginPage {
  constructor(private page: Page) {}

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByTestId('login-submit').click();
  }
}
```

### 5. CI/CD

- Headless en CI.
- Retries: `retries: process.env.CI ? 2 : 0`.
- Screenshots y traces en fallos.

### 6. Config Base

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30000,
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| P1 | Selector basado en CSS class o texto literal |
| P2 | `waitForTimeout()` en lugar de espera explícita |
| P3 | Test que depende de otro test |
| P4 | Sin cleanup de datos de prueba |
| P5 | Sin screenshots/traces configurados para CI |
| P6 | Credenciales hardcodeadas en test |
