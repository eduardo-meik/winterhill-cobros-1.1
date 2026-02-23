# Winterhill Cobros Wiki

Esta wiki documenta la operación funcional y técnica de la aplicación Winterhill Cobros.

## Estado
- ✅ Base inicial creada
- ✅ Sección de workflows funcionales
- ✅ Estructura base completa (workflows, RBAC, datos/RLS, arquitectura, integraciones, operación)

## Índice
1. [Workflows funcionales](01-Workflows.md)
2. [RBAC y permisos](02-RBAC.md)
3. [Modelo de datos y RLS](03-Modelo-Datos-RLS.md)
4. [Arquitectura de la aplicación](04-Arquitectura.md)
5. [Integraciones (Supabase, email, PDF)](05-Integraciones.md)
6. [Operación y soporte](06-Operacion-Soporte.md)

## Alcance de esta wiki
- Flujo de trabajo para roles `ADMIN`, `ASIST`, `READONLY` y `guardian`.
- Ruta de navegación principal por módulo.
- Puntos de control operativos para reducir errores de permisos/datos.

## Fuentes usadas
- `README.md`
- `MANUAL_USUARIO_PLATAFORMA.md`
- `WORKFLOW_UPDATE_SUMMARY.md`
- Código de rutas y módulos (`src/App.jsx`, `src/components/matricula/MatriculaWizard.jsx`, `src/components/payments/PaymentsPage.jsx`, `src/hooks/usePermissions.ts`)
