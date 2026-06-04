# Arquitectura de la aplicación

Esta página describe la arquitectura actual de Winterhill Cobros, sus componentes principales y los flujos de integración entre frontend, base de datos y servicios auxiliares.

## 1) Resumen ejecutivo

Winterhill Cobros sigue una arquitectura **frontend-first**:
- SPA en React + Vite.
- Supabase como backend principal (Auth, Postgres, RLS, Edge Functions).
- Renderizado PDF con dos estrategias:
  - cliente (browser) como flujo principal operativo,
  - servicio remoto Puppeteer (Vercel API o servicio Node) como capacidad complementaria.

---

## 2) Vista de alto nivel

```text
[Usuario Web]
   ↓
[SPA React (Vite)]
   ├─ Auth + Data → [Supabase: Auth + Postgres + RLS]
   ├─ Emails → [Supabase Edge Function: send-email]
   ├─ Reset password → [Supabase Edge Function: request-password-reset]
   └─ PDF
      ├─ Cliente: html2canvas/jsPDF
      └─ Remoto: /api/render-pdf (Vercel + Puppeteer/Chromium)
```

---

## 3) Capa frontend (SPA)

## 3.1 Stack y build
- Framework: React 18.
- Bundler: Vite.
- Rutas: React Router.
- UI: Tailwind + componentes propios.
- Estado principal de sesión/usuario: `AuthContext`.

Archivos de referencia:
- `src/main.jsx`
- `src/App.jsx`
- `vite.config.js`

## 3.2 Organización funcional
- `src/components/*`: pantallas y componentes de negocio.
- `src/services/*`: acceso a datos y lógica transversal (Supabase, matrícula, pagos, PDF, email).
- `src/hooks/*`: permisos, sesión, redirecciones y utilidades de UI.
- `src/contexts/*`: contexto de autenticación y estado cross-cutting.

## 3.3 Navegación y guardas
- `ProtectedRoute`: exige sesión.
- `StaffRoute`: permite staff (`admin`, `asist`) para módulos internos.
- Guardianes (`guardian`) son redirigidos a rutas `/apoderado/*`.

---

## 4) Capa backend principal (Supabase)

## 4.1 Autenticación
- Supabase Auth con sesión persistente en navegador.
- OAuth Google + login tradicional email/password.
- Normalización de rol en `profiles.role` (`admin`, `asist`, `guardian`).

## 4.2 Persistencia
- PostgreSQL en esquema `public`.
- Tablas núcleo: `profiles`, `guardians`, `students`, `student_guardian`, `enrollments`, `enrollment_students`, `enrollment_documents`, `fee`, `guardian_intake_surveys`, `signatures`, `cheques`, `cursos`.

## 4.3 Seguridad de datos
- RLS habilitado en tablas sensibles.
- Restricción por propietario (`owner_id`) y/o relaciones puente (`student_guardian`).
- Soporte de reglas para staff según rol.

Referencias:
- `wiki/02-RBAC.md`
- `wiki/03-Modelo-Datos-RLS.md`

---

## 5) Servicios auxiliares

## 5.1 Edge Function: `send-email`
Responsable de envío transaccional y registro:
- Proveedores soportados por configuración (`mailtrap` / `resend`).
- Rate limiting por usuario/IP (ventana fija).
- Soporte adjuntos (límite de tamaño y cantidad).
- Registro de resultado en tabla de logs (según configuración).

Referencia:
- `supabase/functions/send-email/index.ts`
- `src/services/email.ts`

## 5.2 Edge Function: `request-password-reset`
- Endpoint HTTP para gatillar recuperación de contraseña.
- Construye redirect hacia `/reset-password`.

Referencia:
- `supabase/functions/request-password-reset/index.ts`

## 5.3 API serverless de PDF (`/api/render-pdf`)
- Implementada para Vercel en `api/render-pdf.ts`.
- Usa `puppeteer-core` + `@sparticuz/chromium` en producción.
- En desarrollo puede usar `puppeteer` completo.
- Devuelve PDF binario (`application/pdf`).

## 5.4 Servicio Node PDF (alternativo)
- `pdf-service/` expone `POST /api/render-pdf` con Express + Puppeteer.
- Útil para pruebas o despliegues alternativos fuera de Vercel.

---

## 6) Flujos de arquitectura por caso de uso

## 6.1 Login + autorización
1. Cliente autentica en Supabase.
2. `AuthContext` consulta `profiles.role`.
3. Se deriva `profile` (ADMIN/ASIST/READONLY) para permisos UI.
4. `ProtectedRoute` y `StaffRoute` aplican control de navegación.

## 6.2 Matrícula + documentos
1. UI crea/actualiza `enrollments` y `enrollment_students`.
2. Genera vista previa HTML.
3. Descarga PDF por motor cliente (principal) o remoto (según configuración).
4. Registra metadata en `enrollment_documents`.

## 6.3 Cobranza/pagos
1. UI consulta `fee` con filtros (estado, curso, fechas, cuota, método).
2. Operador registra/edita según permisos RBAC.
3. Reportería consume las mismas fuentes con agregaciones.

## 6.4 Comunicación por email
1. Frontend invoca Edge Function `send-email`.
2. Edge valida payload + rate limit.
3. Proveedor externo envía correo.
4. Se retorna estado al frontend para feedback de usuario.

---

## 7) Configuración y ambientes

Variables frontend clave:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_GOOGLE_CLIENT_ID`
- `VITE_SITE_URL`
- `VITE_PDF_ENGINE` (browser / puppeteer)
- `VITE_PDF_SERVICE_URL`
- `VITE_PDF_SERVICE_TIMEOUT_MS`

Variables servidor/funciones (según componente):
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- `SITE_URL`
- `EMAIL_PROVIDER`, `EMAIL_API_KEY`, `EMAIL_FROM`
- `PDF_ASSET_BASE_URL`

Archivos de referencia:
- `README.md`
- `PUPPETEER_PDF_SERVICE.md`

---

## 8) Despliegue

## 8.1 Frontend
- Build SPA con Vite.
- Rewrites para SPA y API en `vercel.json`.
- Política de caché para estáticos en `netlify.toml` (si aplica ese canal).

## 8.2 Edge Functions
- `supabase/functions/*` desplegadas en Supabase.
- Requieren secrets/vars en entorno del proyecto.

## 8.3 PDF remoto
- Opción A: Vercel Serverless Function (`api/render-pdf.ts`).
- Opción B: servicio Node independiente (`pdf-service/`).

---

## 9) Seguridad y resiliencia

Controles implementados:
- Mínimo privilegio por defecto (`READONLY` fallback).
- Guardas de rutas por rol.
- RLS en BD para control por fila.
- Límite de tasa en función de email.
- Manejo de errores y fallback de PDF para continuidad operativa.

Riesgos a vigilar:
- Desalineación entre matriz RBAC de UI y políticas RLS.
- Variables de entorno faltantes en producción.
- Deriva de políticas por múltiples scripts SQL históricos.

---

## 10) Decisiones de evolución recomendadas

1. Consolidar un único motor PDF por ambiente (evitar ambigüedad operativa).
2. Versionar matriz RBAC + RLS como artefacto único auditable.
3. Formalizar diagrama C4 (Contexto/Contenedores/Componentes).
4. Definir estrategia de observabilidad unificada (logs de app + funciones + SQL).

---

## 11) Referencias cruzadas

- `wiki/01-Workflows.md`
- `wiki/02-RBAC.md`
- `wiki/03-Modelo-Datos-RLS.md`
- `src/App.jsx`
- `src/contexts/AuthContext.tsx`
- `src/services/supabase.ts`
- `supabase/functions/send-email/index.ts`
- `supabase/functions/request-password-reset/index.ts`
- `api/render-pdf.ts`
- `pdf-service/index.js`
