# RBAC (Role-Based Access Control)

Este documento describe cómo funciona el control de acceso por roles en Winterhill Cobros, tanto a nivel de navegación como de acciones de negocio.

## 1) Objetivo

RBAC define **qué puede ver** y **qué puede hacer** cada usuario según su rol/perfil para:
- reducir errores operativos,
- proteger datos sensibles,
- aplicar principio de mínimo privilegio.

---

## 2) Modelo de roles implementado

La aplicación usa dos conceptos relacionados:

1. **`role`** (en `profiles.role`, minúsculas):
   - `admin`
   - `asist`
   - `guardian`

2. **`profile`** (derivado en frontend, mayúsculas):
   - `ADMIN`
   - `ASIST`
   - `READONLY`

### Mapeo actual

| role (BD) | profile (frontend) | Uso principal |
| --- | --- | --- |
| `admin` | `ADMIN` | Acceso staff total |
| `asist` | `ASIST` | Operación staff limitada por acción |
| `guardian` | `READONLY` | Portal de apoderado / solo lectura staff |
| valor faltante o inválido | `READONLY` | Fallback seguro (mínimo privilegio) |

---

## 3) Dónde se aplica RBAC

## 3.1 Control de acceso a rutas (nivel navegación)
- Las rutas de staff están protegidas por `StaffRoute`.
- Solo pasan usuarios con `role` `admin` o `asist`.
- Si no cumple, se redirige a `/apoderado/bienvenido`.

## 3.2 Control de acciones en UI (nivel funcional)
- El hook `usePermissions` construye un `PermissionChecker` usando `user.profile`.
- Desde ahí se habilitan/ocultan botones de pago libre, edición/eliminación, etc.
- Si no hay perfil, se usa `READONLY` por defecto.

## 3.3 Validación reusable en servicios/backend
- Existe `requirePermission(action)` para responder `401`/`403` según perfil.
- Además, se emiten logs de intentos denegados y acciones permitidas.

---

## 4) Matriz de permisos (estado actual en código)

Acciones definidas:
- Pagos: `CREATE_FREE_PAYMENT`, `CREATE_SPECIFIC_PAYMENT`, `EDIT_PAYMENT`, `DELETE_PAYMENT`, `VIEW_PAYMENTS`
- Estudiantes/Apoderados: `EDIT_STUDENT`, `DELETE_STUDENT`, `EDIT_GUARDIAN`, `DELETE_GUARDIAN`
- Reportes: `GENERATE_REPORTS`, `EXPORT_DATA`
- Sistema: `MANAGE_USERS`, `VIEW_LOGS`

### 4.1 Tabla resumida

| Acción | ADMIN | ASIST | READONLY |
| --- | --- | --- | --- |
| Ver pagos | ✅ | ✅ | ✅ |
| Registrar pago a cuota | ✅ | ✅ | ❌ |
| Registrar pago libre | ✅ | ❌ | ❌ |
| Editar pago | ✅ | ❌ | ❌ |
| Eliminar pago | ✅ | ❌ | ❌ |
| Editar estudiante | ✅ | ✅ | ❌ |
| Eliminar estudiante | ✅ | ✅ | ❌ |
| Editar apoderado | ✅ | ✅ | ❌ |
| Eliminar apoderado | ✅ | ✅ | ❌ |
| Generar reportes | ✅ | ✅ | ✅ |
| Exportar datos | ✅ | ✅ | ❌ |
| Gestionar usuarios | ✅ | ✅ *(ver nota)* | ❌ |
| Ver logs | ✅ | ✅ *(ver nota)* | ❌ |

**Nota:** en mensajes funcionales se menciona “solo administradores” para algunas acciones de sistema. Conviene alinear documentación, mensajes y matriz si se cambia la política.

---

## 5) Flujo de autorización

1. Usuario autentica en Supabase.
2. `AuthContext` consulta `profiles.role`.
3. Se normaliza `role` y se deriva `profile`.
4. `StaffRoute` autoriza navegación staff por `role`.
5. Componentes aplican permisos finos por `profile` con `usePermissions`.
6. Si una acción no está permitida:
   - en UI: botón oculto/deshabilitado + mensaje,
   - en backend/servicio: `403 FORBIDDEN`.

---

## 6) Reglas operativas recomendadas

- Mantener `profiles.role` como única fuente de verdad.
- No otorgar permisos por UI solamente; reforzar en API/RLS.
- Usar siempre fallback `READONLY` si hay duda de rol.
- Auditar cambios de rol en producción.

---

## 7) Checklist de troubleshooting RBAC

1. Confirmar sesión activa del usuario.
2. Verificar valor real de `profiles.role`.
3. Confirmar que el `role` normalizado sea `admin`, `asist` o `guardian`.
4. Validar `profile` derivado (`ADMIN`, `ASIST`, `READONLY`).
5. Revisar si el bloqueo ocurre en:
   - ruta (`StaffRoute`),
   - permiso UI (`usePermissions`),
   - servicio/API (`requirePermission`),
   - política RLS en base de datos.
6. Registrar evidencia: usuario, acción, ruta, timestamp, código de error.

---

## 8) Referencias

- `src/services/permissions.ts`
- `src/hooks/usePermissions.ts`
- `src/components/auth/StaffRoute.tsx`
- `src/contexts/AuthContext.tsx`
- `wiki/01-Workflows.md`
