# Operación y soporte

Esta página consolida procedimientos operativos, monitoreo básico y runbooks de soporte para Winterhill Cobros.

## 1) Objetivo

- Estandarizar operación diaria.
- Reducir tiempo de diagnóstico y resolución.
- Definir escalamiento con evidencia mínima.

---

## 2) Operación diaria (checklist)

## 2.1 Inicio de jornada
1. Verificar disponibilidad de app (login + dashboard).
2. Confirmar año lectivo activo en operación.
3. Revisar estado de integraciones críticas:
   - Supabase Auth/DB,
   - Edge Functions (email/reset),
   - generación PDF.
4. Validar que no existan errores masivos en registro de pagos/matrícula.

## 2.2 Cierre de jornada
1. Confirmar flujos críticos completados (matrículas/pagos pendientes).
2. Revisar incidentes abiertos y estado de escalamiento.
3. Documentar hallazgos en bitácora de soporte.

---

## 3) Monitoreo operativo mínimo

## 3.1 Señales a observar
- Error rates en acciones clave (`login`, `registrar pago`, `generar documento`).
- Latencia percibida en reportes y tablas de pagos.
- Fallos de integraciones (`send-email`, `/api/render-pdf`).
- Errores de permisos (`403`, `42501`) y de datos (`23505`, `23503`).

## 3.2 Fuentes
- Logs de frontend (ambiente controlado).
- Logs de Supabase (Auth, DB, Functions).
- Logs de plataforma de deploy (Vercel/alternativo).

---

## 4) Runbooks rápidos por error

## 4.1 `42501` (RLS / insufficient privilege)
1. Confirmar sesión activa y usuario correcto.
2. Validar `profiles.role`.
3. Revisar relación de datos (`owner_id`, `student_guardian`).
4. Consultar políticas activas con `DIAGNOSTIC_RLS_POLICIES.sql`.
5. Reintentar flujo y documentar resultado.

## 4.2 `23505` (duplicado)
1. Identificar entidad y campo único (ej. RUN).
2. Buscar registro existente.
3. Evitar duplicación; corregir o reutilizar registro.

## 4.3 `23503` (FK inválida)
1. Confirmar que el registro referenciado existe (ej. curso, estudiante).
2. Corregir selección de datos maestros.
3. Reintentar operación.

## 4.4 `403` en funcionalidades staff
1. Revisar `role` y `profile` efectivo del usuario.
2. Verificar control de ruta (`StaffRoute`) y permiso de acción (`usePermissions`).
3. Validar que políticas RLS permitan el caso de negocio.

---

## 5) Soporte por integración

## 5.1 Supabase/Auth
- Validar variables `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_SITE_URL`.
- Verificar redirect OAuth y sesión activa.

## 5.2 Email
- Revisar secrets de función (`EMAIL_PROVIDER`, `EMAIL_API_KEY`, `EMAIL_FROM`).
- Confirmar payload requerido: `to`, `subject`, `html`.
- Verificar límites de adjuntos y rate limit.

## 5.3 PDF
- Confirmar motor activo (`VITE_PDF_ENGINE`).
- Si falla remoto, validar fallback cliente.
- Revisar endpoint y timeout (`VITE_PDF_SERVICE_URL`, `VITE_PDF_SERVICE_TIMEOUT_MS`).

---

## 6) Escalamiento

## 6.1 Cuándo escalar
- Incidente bloquea operación crítica (pagos, matrícula, login).
- Error repetitivo con impacto multiusuario.
- Fallo de integración sin workaround operativo.

## 6.2 Evidencia mínima obligatoria
- Usuario afectado (id/email), rol y módulo.
- Acción realizada + timestamp.
- Mensaje/código exacto de error.
- Captura de pantalla o log relevante.
- Resultado de reintento y pasos ejecutados.

---

## 7) Mantenimiento preventivo

- Revisar cambios de rol/permisos semanalmente.
- Validar scripts/migraciones en entorno controlado antes de producción.
- Mantener actualizado el inventario de variables por entorno.
- Ejecutar pruebas smoke después de cambios de seguridad/RLS.

---

## 8) KPIs sugeridos de soporte

- MTTA (tiempo de reconocimiento).
- MTTR (tiempo de resolución).
- % incidencias resueltas en primer contacto.
- % incidentes recurrentes por categoría (RBAC, RLS, Integraciones, Datos).

---

## 9) Referencias cruzadas

- `wiki/01-Workflows.md`
- `wiki/02-RBAC.md`
- `wiki/03-Modelo-Datos-RLS.md`
- `wiki/04-Arquitectura.md`
- `wiki/05-Integraciones.md`
- `DIAGNOSTIC_RLS_POLICIES.sql`
- `MANUAL_USUARIO_PLATAFORMA.md`
