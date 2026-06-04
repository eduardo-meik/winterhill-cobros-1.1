# Integraciones (Supabase, email, PDF)

Esta página documenta las integraciones externas y de plataforma usadas por Winterhill Cobros.

## 1) Objetivo

- Centralizar contratos de integración.
- Definir variables de entorno por componente.
- Estandarizar troubleshooting operativo.

---

## 2) Supabase

## 2.1 Qué integra
- **Auth**: login email/password + Google OAuth.
- **Postgres**: datos de negocio (students, guardians, fee, enrollments, etc.).
- **RLS**: control de acceso por fila.
- **Edge Functions**: envío de email y recuperación de contraseña.

## 2.2 Cliente en frontend
- Cliente inicializado en `src/services/supabase.ts`.
- Sesión persistente y flujo PKCE.
- Fallback de URL de sitio para callback OAuth.

## 2.3 Variables frontend mínimas
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_GOOGLE_CLIENT_ID`
- `VITE_SITE_URL`

## 2.4 Puntos de fallo típicos
- Variables faltantes (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`).
- Redirect URL OAuth no registrada en Supabase.
- Política RLS que bloquea lectura/escritura (`42501`).

---

## 3) Integración de email

## 3.1 Edge Function `send-email`
- Endpoint: función Supabase `send-email`.
- Invocación desde frontend: `src/services/email.ts`.
- Capacidades:
  - envío HTML,
  - adjuntos base64,
  - BCC automático en tipos documentales,
  - rate limit por usuario/IP.

## 3.2 Proveedores soportados
- `mailtrap`
- `resend`

## 3.3 Variables requeridas en entorno de funciones
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `EMAIL_PROVIDER`
- `EMAIL_API_KEY`
- `EMAIL_FROM`

## 3.4 Contrato funcional recomendado
- **Entrada**: `to`, `subject`, `html`, opcional `attachments`, `type`, `related_id`.
- **Salida**: estado `sent`/`failed` + identificador de proveedor cuando exista.

## 3.5 Edge Function `request-password-reset`
- Endpoint: función Supabase `request-password-reset`.
- Recibe email y gatilla `resetPasswordForEmail`.
- Usa `SITE_URL` para construir redirect de recuperación.

Variables mínimas:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SITE_URL`

---

## 4) Integración PDF

Winterhill soporta dos motores:

## 4.1 Motor cliente (principal operativo)
- Generación local en navegador.
- Útil para continuidad incluso si API PDF remota no responde.

## 4.2 Motor remoto (Puppeteer)
- Endpoint serverless: `api/render-pdf.ts`.
- Runtime:
  - dev: `puppeteer`,
  - prod: `puppeteer-core` + `@sparticuz/chromium`.
- Entrega: `application/pdf` binario.

## 4.3 Servicio alternativo PDF (Node)
- Carpeta `pdf-service/` con Express + Puppeteer.
- Endpoint local/externo: `POST /api/render-pdf`.
- Uso recomendado para pruebas o despliegues fuera de Vercel.

## 4.4 Variables PDF
Frontend:
- `VITE_PDF_ENGINE` (`browser` | `puppeteer`)
- `VITE_PDF_SERVICE_URL`
- `VITE_PDF_SERVICE_TIMEOUT_MS`

Servidor:
- `PDF_ASSET_BASE_URL`

---

## 5) Matriz rápida de integraciones

| Integración | Componente emisor | Destino | Uso |
| --- | --- | --- | --- |
| Auth | Frontend | Supabase Auth | Login, sesión, OAuth |
| Data | Frontend | Supabase Postgres | CRUD de negocio |
| Email | Frontend | Supabase Edge Function `send-email` | Comprobantes/documentos |
| Reset password | Frontend | Supabase Edge Function `request-password-reset` | Recuperación de clave |
| PDF remoto | Frontend | `/api/render-pdf` | Generación de PDF de alta calidad |
| PDF alternativo | Frontend/ops | `pdf-service` | Entornos no Vercel |

---

## 6) Troubleshooting por integración

## 6.1 Supabase/Auth
1. Verificar variables `VITE_*` en build/deploy.
2. Confirmar redirect OAuth y dominio en consola/Supabase.
3. Validar `profiles.role` y políticas RLS.

## 6.2 Email
1. Confirmar secrets de función (`EMAIL_*`, `SUPABASE_*`).
2. Revisar formato de payload (`to`, `subject`, `html`).
3. Validar límites de adjuntos (cantidad/tamaño).
4. Revisar rate limit y logs de la función.

## 6.3 PDF
1. Si falla remoto, confirmar fallback a motor cliente.
2. Revisar `VITE_PDF_ENGINE` y `VITE_PDF_SERVICE_URL`.
3. En Vercel, revisar logs de `/api/render-pdf`.
4. En servicio Node, validar estado de Puppeteer/Chrome.

---

## 7) Buenas prácticas de operación

- No mezclar configuraciones de ambiente (dev/staging/prod).
- Mantener un checklist de secrets por entorno.
- Usar fallback explícito para PDF y manejo de timeout.
- Versionar cambios de integración en wiki y changelog.

---

## 8) Referencias cruzadas

- `wiki/01-Workflows.md`
- `wiki/02-RBAC.md`
- `wiki/03-Modelo-Datos-RLS.md`
- `wiki/04-Arquitectura.md`
- `src/services/supabase.ts`
- `src/services/email.ts`
- `supabase/functions/send-email/index.ts`
- `supabase/functions/request-password-reset/index.ts`
- `api/render-pdf.ts`
- `pdf-service/index.js`
- `PUPPETEER_PDF_SERVICE.md`
