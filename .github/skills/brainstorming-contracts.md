---
name: brainstorming-contracts
description: "Use when designing new features, API endpoints, or database schemas. Forces contract-first design: define schemas, API surface, and error contracts before writing implementation code."
---

# Brainstorming & Contracts — Gestión Escolar

## Overview

Forzar el diseño de API y esquemas **antes** de codificar en **Gestión Escolar**. Ninguna feature debe implementarse sin un contrato aprobado.

## Proceso Obligatorio

### Paso 1 — Definir el Schema de Datos

Usar un formato declarativo para describir las entidades principales:

```
Entidad: [NombreEntidad]
Campos:
  - id: UUID (PK, auto)
  - name: string (required, max 255)
  - status: enum ['draft', 'active', 'archived']
  - created_at: timestamp (auto)
  - updated_at: timestamp (auto, trigger)
Relaciones:
  - belongs_to: [OtraEntidad] (FK: otra_entidad_id)
Índices:
  - (status, created_at) — para listados filtrados
```

### Paso 2 — Diseñar la API Surface

Para cada feature, documentar los endpoints antes de implementar:

```
[MÉTODO] /api/v1/recurso
  Auth: authenticated | role:admin | public
  Request Body: { campo: tipo }
  Query Params: { page: number, pageSize: number }
  Response 200: { success: true, data: tipo }
  Response 400: { success: false, error: { code: string, message: string } }
  Response 401: No autenticado
  Response 403: Sin permisos
```

### Paso 3 — Definir Contratos de Error

| Código | Significado | Cuándo ocurre |
|:---|:---|:---|
| `VALIDATION_ERROR` | Input inválido | Schema falla |
| `NOT_FOUND` | Recurso no existe | ID inexistente |
| `UNAUTHORIZED` | Sin autenticación | Token ausente o inválido |
| `FORBIDDEN` | Sin permisos | Rol insuficiente |
| `CONFLICT` | Estado inconsistente | Duplicado o acción inválida |

### Paso 4 — Revisión del Contrato

Antes de implementar:

- [ ] ¿El schema cubre todos los campos necesarios?
- [ ] ¿Los endpoints siguen REST o la convención del proyecto?
- [ ] ¿Los errores cubren los casos edge principales?
- [ ] ¿Se documentaron los tipos de request y response?
- [ ] ¿Se definieron niveles de auth por endpoint?
- [ ] ¿Se consideró paginación para listados?

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| B1 | Feature implementada sin contrato de API documentado |
| B2 | Endpoint sin definición de errores esperados |
| B3 | Schema sin campos de auditoría (created_at, updated_at) |
| B4 | Listado sin paginación definida |
| B5 | Endpoint sin nivel de auth especificado |
