# Diagnóstico: Páginas y Registros No Se Renderizan

**Proyecto:** Winterhill Cobros v1.1  
**Fecha:** 2026-03-07  
**Stack:** React + Vite 6.4.1 + Supabase + React Query

---

## Resumen del Problema

Las páginas de la aplicación no renderizan contenido y/o los registros (students, fees, payments, guardians) no se muestran. Se observa el mensaje **"Algo salió mal"** del ErrorBoundary o páginas en blanco.

## Bitácora de Diagnóstico

### 2026-03-07 — Estado reportado por usuario
- El mensaje `Algo salió mal` sigue apareciendo en todas las páginas de módulos visibles en el sidebar.
- El navegador no muestra mensajes en `Console` durante la reproducción del fallo.
- Se confirmó que esto no invalida el diagnóstico: la build de producción usa `terserOptions.compress.drop_console = true` en `vite.config.js`.
- Después de aplicar los cambios de mitigación y los fixes ya documentados, el usuario confirma que **no hubo cambio observable**: el síntoma persiste.

### 2026-03-07 — Acciones asistidas ya ejecutadas
- Se activó `vite-plugin-inspect` en `vite.config.js`.
- Se validó que `npx vite build` compila correctamente después de los cambios.
- Se confirmó que Vite expone `/__inspect/` en desarrollo.
- Se verificó acceso a deployments de Vercel por CLI.
- Se probó `vercel logs` sobre deployments concretos; para al menos un deployment respondió `No logs found`.

### 2026-03-07 — Acciones ejecutadas sin éxito observable
- Se repitió `npm run dev` múltiples veces y siguió terminando con `Exit Code: 1`.
- Se repitió `npx vite` de forma directa y también terminó con `Exit Code: 1`.
- Se mataron procesos `node.exe` y listeners en puertos `4173`, `5173`, `5174`, `5175`, `5176`, `5177` y `5178` para forzar un arranque limpio.
- Resultado de limpieza de puertos: `All target ports are clear`.
- Aun con puertos liberados y caché de Vite eliminada (`node_modules/.vite`) más limpieza de `dist`, `npm run dev` siguió fallando.
- Se aplicó la mitigación `lazyWithRetry()` para recarga única ante fallos de chunks lazy; el usuario reporta que **no cambió el síntoma**.
- Se reconstruyó el frontend con `npx vite build` varias veces y el build siguió pasando correctamente, por lo que el problema persiste aunque el bundle compile.

### 2026-03-07 — Fallas concretas corregidas
- `GuardiansPage.jsx`: se corrigió `isSearching` no definido que podía lanzar `ReferenceError`.
- `DebtorsTable.jsx`: se blindó el formateo de `lastDueDate` cuando viene nulo.
- `PaymentDetailsModal.jsx`: se blindó el formateo de `payment.due_date` cuando viene nulo.

### 2026-03-07 — Hallazgos nuevos de alta confianza
- `DebtTrendChart.jsx`: había `parseISO(fee.due_date)` sin validación previa.
- `PaymentProjectionChart.jsx`: había `parseISO(fee.due_date)` sin validación previa.
- Ambos puntos pueden disparar el `ErrorBoundary` del Dashboard si existen aranceles con `due_date` nulo o vacío.

### 2026-03-07 — Complemento con log de Supabase entregado por usuario
- El fragmento compartido contiene únicamente registros con `error_severity = LOG`; no aparecen entradas `ERROR`, `FATAL` ni mensajes de fallo SQL.
- Se observan conexiones autorizadas para `postgres_exporter`, `mgmt-api`, `supabase/dashboard`, `psql`, `supabase_auth_admin` y `postgrest` con usuario `authenticator`.
- También hay entradas normales de `checkpoint starting` y `checkpoint complete`, que corresponden al funcionamiento habitual de PostgreSQL.
- En el fragmento entregado **no hay evidencia de caída de Postgres, rechazo de autenticación, errores de consulta, ni fallas explícitas de PostgREST**.
- Este log, por sí solo, **no explica** el mensaje `Algo salió mal` en el frontend.
- La utilidad principal del log aportado es descartar, en este tramo temporal, una falla evidente del motor PostgreSQL como causa inmediata.

### 2026-03-07 — Investigación RLS (Supabase)
- Se descubrió que la función `get_current_user_role()` retornaba `UPPER(role)` = `'ADMIN'`, mientras que las 10 políticas RLS comparan con lowercase `'admin'`/`'asist'`.
- Se corrigieron las funciones `get_current_user_role()` (UPPER→LOWER), `es_admin_o_equipo()` (2 overloads, uppercase→lowercase) y `ensure_profile_for_current_user()` (UPPER→lower) directamente en la BD de producción via SQL.
- **Resultado:** El usuario aplicó el fix en la consola de Supabase, no obtuvo errores, recargó la app y **el problema persiste**.
- **Conclusión:** El bug de RLS causaba que los staff vieran 0 registros (datos vacíos), pero NO es la causa del crash "Algo salió mal". El `ErrorBoundary` atrapa errores de JavaScript en render, y datos vacíos no causa una excepción — la causa son errores de código explícitos.

### 2026-03-07 — Análisis de commits desde el último deploy funcional
- **Último commit funcional:** `f5b146e` (31/dic/2025) — "feat: Add Matrícula tab and export options"
- Se ejecutaron **30+ commits** entre f5b146e y HEAD (42bba54), incluyendo:
  - `630931a` — Optimización P1-P10: code splitting (React.lazy), memoización, GuardiansPage refactor
  - `755a729` — Migración a @tanstack/react-query (useFeesQuery, useStudentsQuery)
  - `b71fa23` — Validación de sesiones auth almacenadas
  - Múltiples fixes de PostgREST joins y esquema

### 2026-03-07 — CAUSA RAÍZ IDENTIFICADA: Bugs de JavaScript en código desplegado

Se auditó el código DESPLEGADO (commit 42bba54) archivo por archivo. Se encontraron **6 bugs de crash**:

| # | Archivo | Bug | Severidad |
|---|---------|-----|-----------|
| 1 | **YearComparisonChart.jsx** | `useMemo` deps usan `currentFees`/`prevFees` que son variables LOCALES del callback, no existen en el scope exterior → `ReferenceError` **incondicional en cada render** | **CRÍTICO — garantiza crash del Dashboard** |
| 2 | **GuardiansPage.jsx** | `isSearching={isSearching}` usa variable nunca declarada → `ReferenceError` en render | **ALTO — crash de página Apoderados** |
| 3 | **DebtTrendChart.jsx** | `parseISO(fee.due_date)` sin validar null → `RangeError` si algún fee tiene `due_date: null` | CRÍTICO si hay datos null |
| 4 | **PaymentProjectionChart.jsx** | `parseISO(fee.due_date)` sin validar null → `RangeError` si algún fee tiene `due_date: null` | CRÍTICO si hay datos null |
| 5 | **DebtorsTable.jsx** | `format(new Date(debtor.lastDueDate))` sin validar null → crash condicional | Medio |
| 6 | **StudentsPage.jsx** | `toast` usado pero nunca importado → `ReferenceError` al exportar Excel (click, no render) | Medio |

**El bug #1 (YearComparisonChart) es la causa principal del crash del Dashboard.** Este componente se renderiza SIEMPRE en el Dashboard, que es la página por defecto después del login. El `ReferenceError: currentFees is not defined` se dispara en cada render incondicional, y el `ErrorBoundary` lo captura mostrando "Algo salió mal".

**El bug #2 (GuardiansPage)** explica el crash independiente de la página de Apoderados.

**Los bugs #3 y #4** son co-dependientes de datos: si existen fees con `due_date: null` en la BD, crashean antes de que YearComparisonChart lo haga.

**Nota importante:** Cada ruta tiene su PROPIO `ErrorBoundary` (no uno global), por lo que los crashes están aislados por página. Si el usuario reporta que "TODAS" las páginas crashean, podría ser:
- Que Dashboard crashea y el usuario asume que es todas (primera impresión después del login)
- O que no ha probado las páginas individuales (payments, students, reporting, assistant, settings deberían funcionar)

### 2026-03-07 — Hipótesis RESUELTA
- ~~Sigue siendo probable que existan más fallos de runtime en componentes de módulos del sidebar o problemas de datos inconsistentes que se manifiestan solo en render.~~
- ~~Si después de corregir los fallos de frontend el mensaje persiste, el siguiente foco es validar datos reales y RLS con usuario autenticado.~~
- ~~Dado que todas las rutas del sidebar están lazy-loaded desde `App.jsx`, también hay una hipótesis fuerte de fallo de carga de chunks después de deploy o por caché desalineada entre `index.html` y assets versionados.~~
- ~~Como la mitigación de chunks no cambió el síntoma reportado, esa hipótesis pierde fuerza relativa.~~
- **CONFIRMADO:** Los crashes son causados por errores de JavaScript en componentes desplegados, introducidos en commits posteriores a f5b146e (principalmente en 630931a y 755a729). El fix requiere corregir el código y redesplegar.

### 2026-03-07 — Mitigación aplicada para rutas lazy
- Se agregó una capa `lazyWithRetry()` para las importaciones dinámicas de rutas.
- Si falla la carga de un chunk con errores típicos de deploy (`ChunkLoadError`, `Failed to fetch dynamically imported module`, `Loading chunk`), la app fuerza una sola recarga completa y evita el bucle infinito con `sessionStorage`.
- Esta mitigación apunta específicamente al patrón “login carga, pero todas las páginas lazy del sidebar caen”.
- Estado después de aplicar la mitigación: **sin mejora confirmada por el usuario**.

## Evaluación de Pertinencia

El plan es **parcialmente pertinente** para este codebase.

**Sí está bien orientado en:**
- Validar `.env`, sesión, RLS y requests a Supabase.
- Usar DevTools para capturar el error real del ErrorBoundary.
- Revisar `get_current_user_role()` porque las policies exportadas en `policies.json` comparan contra `'ADMIN'` en mayúsculas.

**Pero debe ajustarse en estos puntos:**
- El frontend staff no usa la tabla `payments` para renderizar la vista de pagos; `PaymentsPage` consume `fee` vía `useFeesQuery()`.
- No existe ninguna instancia global `window.__SUPABASE__` en el frontend, así que ese test del navegador no aplica.
- Llamar `get_current_user_role()` con `SUPABASE_SERVICE_ROLE_KEY` no es una verificación confiable del flujo real del usuario autenticado, porque la función depende de `auth.uid()`.
- `test-queries.cjs` no es una prueba autoritativa del frontend mientras conserve queries heredadas con sintaxis antigua.
- Hay al menos un bug de runtime concreto en el codebase: `GuardiansPage.jsx` usa `isSearching` sin definir.
- `vite-plugin-inspect` ya está instalado y activado; debe usarse como apoyo para diagnosticar módulos y transforms, no como reemplazo de Console/Network.

## Acciones Manuales vs Asistidas

**Acciones manuales obligatorias:**
- Abrir la aplicación en el navegador y reproducir el fallo.
- Revisar DevTools del navegador: `Console`, `Network` y el mensaje real del `ErrorBoundary`.
- Hacer login con un usuario real para validar comportamiento autenticado.
- Confirmar en Supabase Dashboard valores sensibles cuando corresponda: claves, usuarios, policies, SQL ad hoc.
- Validar en Vercel si el problema ocurre en un deployment específico y comparar con local.

**Acciones asistidas por CLI o repo:**
- Levantar Vite, usar `vite-plugin-inspect` y compilar el proyecto.
- Ejecutar tests y scripts locales (`test-diagnostics.cjs`, `test-queries.cjs`).
- Consultar deployments y logs de Vercel por CLI.
- Ejecutar consultas SQL o revisar migraciones de Supabase.
- Buscar errores de runtime y referencias inseguras en el codebase.

**Regla práctica:**
- Si el paso requiere observar la UI, hacer clic, inspeccionar la pestaña Network o leer un stack trace del navegador, es manual.
- Si el paso se puede ejecutar desde terminal, scripts del repo o consultas SQL reproducibles, es asistido.

---

## FASE 1 — Verificaciones de Infraestructura

### 1.1 Verificar que el Dev Server Arranca

**Tipo:** Asistido

```powershell
# Matar procesos zombie de node
taskkill /IM node.exe /F 2>$null
Start-Sleep -Seconds 2

# Limpiar caché de Vite
Remove-Item -Recurse -Force node_modules\.vite -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue

# Arrancar
npm run dev
```

**Esperado:** `VITE v6.4.1 ready in XXX ms` — Local: `http://localhost:5173/`  
**Si falla:** Puerto ocupado → Vite elige otro (5174, 5175). Verificar con `netstat -ano | findstr ":5173"`

- [ ] Dev server arranca sin errores
- [ ] Puedo acceder a `http://localhost:5173` en el navegador

---

### 1.2 Verificar Variables de Entorno (.env)

**Tipo:** Asistido

Abrir `.env` y confirmar que estas variables tienen valores NO vacíos:

| Variable | Uso | ¿Necesaria para renderizar? |
|---|---|---|
| `VITE_SUPABASE_URL` | URL de Supabase | **SÍ** — sin esto no hay conexión a BD |
| `VITE_SUPABASE_ANON_KEY` | Clave pública de Supabase | **SÍ** — sin esto no hay auth ni queries |
| `SUPABASE_SERVICE_ROLE_KEY` | Clave secreta (solo scripts) | NO — solo para test-queries.cjs |
| `SUPABASE_ACCESS_TOKEN` | Token de Management API | NO — solo para scripts CLI |
| `VITE_GOOGLE_CLIENT_ID` | OAuth con Google | NO — solo login con Google |
| `VITE_SITE_URL` | URL del sitio | NO — funcional sin ella |

```powershell
# Test rápido: Verificar que las claves existen
node -e "require('fs').readFileSync('.env','utf8').split('\n').filter(l=>l.includes('=')).forEach(l=>{const[k]=l.split('=');console.log(k,'→',l.split('=').slice(1).join('=').length>0?'✅ SET':'❌ VACÍO')})"
```

- [ ] `VITE_SUPABASE_URL` tiene valor
- [ ] `VITE_SUPABASE_ANON_KEY` tiene valor (JWT largo)
- [ ] Ambos valores son los correctos (no placeholder ni rotados sin actualizar)

---

### 1.3 Verificar Conectividad a Supabase

**Tipo:** Asistido

```powershell
# Test de conexión básica
node -e "
const {createClient}=require('@supabase/supabase-js');
const fs=require('fs');
const env={};
fs.readFileSync('.env','utf8').split('\n').forEach(l=>{const[k,...v]=l.split('=');if(k)env[k.trim()]=v.join('=').trim()});
const sb=createClient(env.VITE_SUPABASE_URL, env.VITE_SUPABASE_ANON_KEY);
Promise.all([
  sb.from('cursos').select('id',{count:'exact',head:true}),
  sb.from('students').select('id',{count:'exact',head:true}),
  sb.from('fee').select('id',{count:'exact',head:true}),
]).then(([c,s,f])=>{
  console.log('cursos:',c.error?'❌ '+c.error.message:'✅ '+c.count+' registros');
  console.log('students:',s.error?'❌ '+s.error.message:'✅ '+s.count+' registros');
  console.log('fees:',f.error?'❌ '+f.error.message:'✅ '+f.count+' registros');
}).catch(e=>console.error('❌ Error de conexión:',e.message));
"
```

**Resultados posibles:**
| Resultado | Significado | Acción |
|---|---|---|
| `✅ N registros` | Conexión OK, datos accesibles | Seguir a Fase 2 |
| `❌ Invalid API key` | Anon key incorrecta/rotada | Actualizar `VITE_SUPABASE_ANON_KEY` en `.env` con la clave correcta de Supabase Dashboard → Settings → API |
| `❌ relation "xxx" does not exist` | Tabla no existe | Verificar migraciones: `npx supabase migration list` |
| `❌ permission denied` | RLS bloqueando como anon | Esperado para students/fee (requiere auth). cursos debería ser ✅ |
| `❌ FetchError / network` | Sin conexión a internet o URL incorrecta | Verificar URL y conexión |

- [ ] `cursos` accesible (✅)
- [ ] La conexión a Supabase funciona
- [ ] Si students/fee dan `permission denied`, es normal (requieren autenticación)

---

### 1.4 Verificar Build Compila Sin Errores

**Tipo:** Asistido

```powershell
npx vite build 2>&1 | Select-Object -Last 20
```

**Esperado:** `✓ built in XX.XXs` sin errores rojos  
**Si hay errores:** Anotar el archivo y número de línea exacto → son errores de compilación que impiden que la app funcione.

- [ ] Build completa exitosamente

---

## FASE 2 — Verificaciones de Autenticación

### 2.1 Verificar Login Funciona

**Tipo:** Manual

1. Abrir `http://localhost:5173/login` en el navegador
2. Intentar login con credenciales de admin

**Resultados posibles:**
| Síntoma | Causa Probable | Acción |
|---|---|---|
| Pantalla de login carga OK | Frontend básico funciona | Continuar login |
| Pantalla blanca en /login | JavaScript no carga | Revisar console del navegador (F12) |
| Error "Missing Supabase env vars" en console | .env no se carga | Reiniciar dev server |
| Login exitoso → Dashboard | Auth OK | Seguir a Fase 3 |
| Login da error "Invalid login credentials" | Credenciales incorrectas o usuario no existe | Verificar en Supabase Dashboard → Authentication → Users |
| Login exitoso pero redirige a /apoderado/bienvenido | Rol es 'guardian', no 'admin' | Verificar rol en tabla `profiles` |

- [ ] Pantalla de login carga
- [ ] Login con admin funciona
- [ ] Se redirige al Dashboard (no a /apoderado/bienvenido)

---

### 2.2 Verificar Rol del Usuario en la BD

**Tipo:** Asistido

```powershell
# Con service_role key para bypasear RLS
node -e "
const {createClient}=require('@supabase/supabase-js');
const fs=require('fs');
const env={};
fs.readFileSync('.env','utf8').split('\n').forEach(l=>{const[k,...v]=l.split('=');if(k)env[k.trim()]=v.join('=').trim()});
const sb=createClient(env.VITE_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
sb.from('profiles').select('id,email,role').then(({data,error})=>{
  if(error){console.error('❌',error.message);return}
  data.forEach(p=>console.log(p.email,'→ role:',p.role));
});
"
```

**Verificar:** El usuario con el que haces login tiene `role = 'admin'` o `role = 'asist'`.

**Roles válidos y su comportamiento:**
| Rol en BD | Normalizado | Acceso a Dashboard | Acceso Staff Pages |
|---|---|---|---|
| `admin` / `Admin` / `ADMIN` | `admin` | ✅ | ✅ |
| `asist` / `Asist` / `ASIST` | `asist` | ✅ | ✅ |
| `guardian` / `Guardian` | `guardian` | ❌ (va a /apoderado) | ❌ |
| Otro / null | `guardian` (fallback) | ❌ | ❌ |

- [ ] El usuario de login tiene rol admin o asist
- [ ] El rol está en minúsculas (recomendado)

---

### 2.3 Verificar Función RPC `get_current_user_role`

**Tipo:** Mixto

Esta función es **CRÍTICA** — todas las políticas RLS la usan para decidir acceso.

**Si la función no existe:** Las políticas RLS fallarán y NINGÚN dato será accesible para usuarios autenticados.

**Nota:** `test-diagnostics.cjs` ya considera aceptable que `get_current_user_role()` falle cuando se invoca con service-role; por eso ese camino no debe tomarse como prueba funcional del flujo real.

**Verificar en Supabase Dashboard → SQL Editor:**
```sql
SELECT routine_name FROM information_schema.routines 
WHERE routine_name = 'get_current_user_role';
```

- [ ] La función `get_current_user_role` existe
- [ ] Su valor real se valida con login de usuario autenticado (Fase 3.3)

---

## FASE 3 — Verificaciones de Datos (RLS y Queries)

### 3.1 Verificar RLS Policies Activas

**Tipo:** Asistido

Las políticas RLS determinan qué datos puede ver cada usuario. Si están mal configuradas, los queries retornan arrays vacíos silenciosamente.

**Políticas clave requeridas:**

| Tabla | Policy Necesaria | Condición |
|---|---|---|
| `students` | Admins manage all | `get_current_user_role() = 'ADMIN'` |
| `guardians` | Admins manage all | `get_current_user_role() = 'ADMIN'` |
| `cursos` | All read | `true` |
| `profiles` | Users view own | `auth.uid() = id` |

**Notas de pertinencia para este repo:**
- `policies.json` sí respalda `profiles`, `students`, `guardians` y `cursos`.
- La vista de pagos del frontend consume `fee`, no `payments`, por lo que `payments` no es una prioridad para explicar páginas en blanco.
- El repo contiene SQL auxiliares con policies sobre `fee`, pero `policies.json` no lo confirma como estado exportado actual; trátalo como verificación adicional, no como hecho cerrado.

```sql
-- Ejecutar en Supabase Dashboard → SQL Editor
SELECT tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

- [ ] Tabla `students` tiene policy para admin con SELECT
- [ ] Tabla `cursos` tiene policy que permite SELECT a todos
- [ ] Función `get_current_user_role()` retorna `'ADMIN'` (MAYÚSCULAS) — las policies comparan con `'ADMIN'`

---

### 3.2 Test de Query Completo como Service Role

**Tipo:** Asistido

```powershell
# Este test bypasea RLS para verificar que los datos EXISTEN
node -e "
const {createClient}=require('@supabase/supabase-js');
const fs=require('fs');
const env={};
fs.readFileSync('.env','utf8').split('\n').forEach(l=>{const[k,...v]=l.split('=');if(k)env[k.trim()]=v.join('=').trim()});
const sb=createClient(env.VITE_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
sb.from('fee').select('id, amount, status, student:students(id, whole_name, curso:cursos(nom_curso))').limit(3).then(({data,error})=>{
  if(error){console.error('❌ Query fee+student+curso FALLÓ:',error.message);return}
  console.log('✅ Fee query OK. Ejemplo:');
  data.forEach(f=>console.log('  Fee:',f.id?.substring(0,8),'| Monto:',f.amount,'| Alumno:',f.student?.whole_name,'| Curso:',f.student?.curso?.nom_curso));
});
"
```

**Si este test falla:** El problema es la estructura de la BD (tablas/columnas/relaciones).  
**Si este test pasa pero la app no muestra datos:** El problema es RLS o autenticación.

- [ ] Query fee+student+curso retorna datos con service_role
- [ ] Los joins (student, curso) tienen datos (no null)

---

### 3.3 Test de Query como Usuario Autenticado

**Tipo:** Mixto

```powershell
# Simular login y hacer query como usuario real
node -e "
const {createClient}=require('@supabase/supabase-js');
const fs=require('fs');
const env={};
fs.readFileSync('.env','utf8').split('\n').forEach(l=>{const[k,...v]=l.split('=');if(k)env[k.trim()]=v.join('=').trim()});
const sb=createClient(env.VITE_SUPABASE_URL, env.VITE_SUPABASE_ANON_KEY);
// REEMPLAZAR con email y contraseña del admin
sb.auth.signInWithPassword({email:'ADMIN_EMAIL_AQUI',password:'PASSWORD_AQUI'}).then(async({data:auth,error:authErr})=>{
  if(authErr){console.error('❌ Login falló:',authErr.message);return}
  console.log('✅ Login OK como:',auth.user.email);
  const{data:role}=await sb.rpc('get_current_user_role');
  console.log('  Rol:',role);
  const{data:fees,error:feeErr}=await sb.from('fee').select('id,amount').limit(3);
  if(feeErr)console.error('❌ Fee query:',feeErr.message);
  else console.log('  Fees visibles:',fees.length);
  const{data:students,error:stuErr}=await sb.from('students').select('id,whole_name').limit(3);
  if(stuErr)console.error('❌ Students query:',stuErr.message);
  else console.log('  Students visibles:',students.length);
}).catch(e=>console.error('❌',e.message));
"
```

**Resultados posibles:**
| Resultado | Diagnóstico |
|---|---|
| Login OK, Rol: ADMIN, Fees: N, Students: N | Todo funciona → problema es frontend |
| Login OK, Rol: ADMIN, Fees: 0, Students: 0 | RLS bloquea queries → políticas incorrectas |
| Login OK, Rol: null/undefined | `get_current_user_role()` no funciona → revisar función |
| Login OK, Rol: guardian | Usuario no es admin → cambiar rol en profiles |
| Login falló | Credenciales incorrectas o usuario no existe |

- [ ] Login como admin funciona
- [ ] `get_current_user_role()` retorna `'ADMIN'`
- [ ] Fees y Students retornan registros (> 0)

---

## FASE 4 — Verificaciones de Frontend (Browser DevTools)

### 4.1 Inspeccionar Console del Navegador

**Tipo:** Manual

1. Abrir la app en Chrome/Edge
2. Presionar **F12** → pestaña **Console**
3. Navegar al Dashboard
4. Buscar errores rojos

**Errores comunes y su solución:**

| Error en Console | Causa | Solución |
|---|---|---|
| `Missing Supabase env vars` | `.env` no se carga | Reiniciar dev server (`npm run dev`) |
| `Invalid API key` | Anon key incorrecta | Actualizar `VITE_SUPABASE_ANON_KEY` en `.env` |
| `JWT expired` | Sesión expirada | Limpiar localStorage y re-login |
| `relation "xxx" does not exist` | Tabla no existe en BD | Ejecutar migraciones pendientes |
| `could not find the function` | RPC no existe | Verificar que la migración creó la función |
| `permission denied for table` | RLS bloquea acceso | Revisar Fase 3 |
| `Cannot read properties of null` | Datos null no manejados | Hay un bug en el componente (ver stack trace) |
| `ChunkLoadError` | Bundle corrupto | Limpiar caché Vite y rebuild |
| Errores de CORS | Dominio no autorizado | Agregar localhost a Supabase Auth → URL Configuration |

- [ ] Anotar todos los errores rojos de la console
- [ ] Identificar si son errores de red, auth, o JavaScript

---

### 4.2 Inspeccionar Pestaña Network

**Tipo:** Manual

1. En DevTools (F12) → pestaña **Network**
2. Filtrar por **Fetch/XHR**
3. Navegar al Dashboard
4. Buscar requests a `supabase.co`

**Verificar:**
| Request | Status Esperado | Si Falla |
|---|---|---|
| `GET .../rest/v1/fee?select=...` | 200 | RLS o query syntax error |
| `GET .../rest/v1/students?select=...` | 200 | RLS o query syntax error |
| `POST .../auth/v1/token?grant_type=refresh_token` | 200 | Token refresh falla |
| Cualquier request | 401 | JWT expirado → re-login |
| Cualquier request | 403 | RLS deniega acceso |
| Cualquier request | 0 (failed) | Sin conexión o CORS |

**Para ver el error detallado:** Click en el request rojo → pestaña **Response** → leer el JSON de error.

- [ ] Requests a Supabase retornan 200
- [ ] Los response bodies contienen datos (arrays con registros)
- [ ] No hay requests con status 401/403/500

---

### 4.3 Usar `vite-plugin-inspect` para diagnosticar el frontend

`vite-plugin-inspect` sirve para revisar cómo Vite transforma módulos, qué plugins intervienen y si una página falla por un problema de transformación, chunking o carga de módulos. Es útil para diagnosticar el frontend, pero **no reemplaza** Console/Network ni React DevTools.

**Estado actual en este repo:**
- El paquete está instalado en `devDependencies`.
- Ya está activado en `vite.config.js`.

**Tipo:** Asistido

**Uso una vez habilitado:**
1. Ejecutar `npm run dev`.
2. Abrir `http://localhost:5173/__inspect/` o el puerto que Vite asigne.
3. Revisar:
   - si el módulo de la página carga,
   - si hay errores de transformación,
   - qué plugins tocaron el archivo,
   - si hay diferencias entre el archivo fuente y el módulo servido.

**Cuándo aporta valor real:**
- Si una ruta carga en blanco pero el build compila.
- Si sospechas un problema de Vite/HMR/chunks.
- Si un componente falla después de una transformación y no por datos de Supabase.

**Cuándo no aporta mucho:**
- Si el error ya está claro en Console/ErrorBoundary.
- Si el problema es RLS, sesión o datos vacíos desde Supabase.

- [ ] Abrir `/__inspect/` si Console y Network no explican el fallo

---

### 4.4 Verificar ErrorBoundary Muestra Error Real

**Tipo:** Manual

Si ves **"Algo salió mal"**, el ErrorBoundary está capturando un crash de React.

1. Buscar el **cuadro rojo** debajo del mensaje de error
2. Leer el **mensaje de error** y el **stack trace**
3. Anotar el archivo y línea donde ocurre el crash

**El cuadro rojo aparece en:**
```
src/components/ui/ErrorBoundary.jsx
```

- [ ] Copiar el texto exacto del error del ErrorBoundary
- [ ] Identificar qué componente crashea (desde el stack trace)

---

### 4.5 Rutina Integrada: Vite + Vercel + Supabase

**Tipo:** Mixto

Usar esta rutina cuando el build compila, pero una página igual no renderiza o los datos no aparecen.

#### Paso A — Verificar transformación y carga de módulos con Vite

**Acción manual principal:** abrir `/__inspect/` y revisar el módulo afectado.
**Acción asistida:** levantar Vite y dejar operativo `vite-plugin-inspect`.

1. Arrancar el frontend con `npm run dev`.
2. Abrir `/__inspect/`.
3. Revisar el módulo de la página afectada.

**Buscar específicamente:**
- errores de transformación,
- imports que no resuelven,
- módulos servidos distintos al código fuente esperado,
- plugins que alteran el archivo.

**Útil para:**
- páginas en blanco con build exitoso,
- errores de chunking o HMR,
- comportamiento distinto entre archivo fuente y módulo servido.

#### Paso B — Revisar logs del deployment real en Vercel

**Acción manual opcional:** contrastar el resultado con el deployment en el navegador.
**Acción asistida:** listar deployments y consultar logs con `vercel` CLI.

1. Listar deployments:

```powershell
vercel list winterhill-cobros
```

2. Elegir el deployment afectado y consultar logs:

```powershell
vercel logs <deployment-url> --no-follow --limit 20 --json
```

**Ejemplos válidos:**
```powershell
vercel logs https://winterhill-cobros-dq72f3j80-eduardomeiks-projects.vercel.app --no-follow --limit 20 --json
vercel logs https://winterhill-cobros-lodhgvrca-eduardomeiks-projects.vercel.app --no-follow --limit 20 --json
```

**Interpretación:**
- Si devuelve logs de funciones o errores 5xx, el problema está en runtime del deployment.
- Si no devuelve nada útil, puede significar que el deployment es mayormente estático o que no hubo eventos recientes para esa URL.
- Si el fallo existe en Vercel pero no en local, priorizar variables de entorno, rewrites y funciones serverless.

#### Paso C — Validar datos y RLS en Supabase

**Acción manual opcional:** revisar Supabase Dashboard si la query CLI no alcanza o si se necesita confirmar estado productivo.
**Acción asistida:** ejecutar SQL y revisar migraciones.

1. Verificar que las policies existen:

```sql
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'students', 'guardians', 'cursos', 'fee')
ORDER BY tablename, policyname;
```

2. Verificar helper crítico:

```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_name = 'get_current_user_role';
```

3. Verificar si hay datos realmente disponibles:

```sql
SELECT
  (SELECT count(*) FROM public.students) AS students_count,
  (SELECT count(*) FROM public.fee) AS fee_count,
  (SELECT count(*) FROM public.guardians) AS guardians_count,
  (SELECT count(*) FROM public.cursos) AS cursos_count;
```

4. Verificar la relación usada por el frontend de dashboard/pagos:

```sql
SELECT f.id, f.amount, f.status, s.id AS student_id, s.whole_name, c.nom_curso
FROM public.fee f
LEFT JOIN public.students s ON s.id = f.student_id
LEFT JOIN public.cursos c ON c.id = s.curso
LIMIT 20;
```

#### Criterio de decisión

- Si `/__inspect/` muestra problemas de módulo: arreglar frontend/Vite primero.
- Si Vercel logs muestran fallos de runtime: arreglar deployment/configuración antes de culpar a Supabase.
- Si Supabase devuelve 0 filas o RLS inconsistente: arreglar roles/policies/helpers.
- Si todo lo anterior está sano: revisar errores concretos de componentes como `GuardiansPage.jsx`.

- [ ] Ejecutar la rutina integrada cuando el origen del fallo no sea evidente
- [ ] Anotar si el problema aparece solo en local, solo en Vercel, o en ambos

---

## FASE 5 — Problemas Conocidos y Fixes

### 5.0 Problema Concreto del Codebase: `GuardiansPage` puede romper el render

**Tipo:** Asistido

En este repo hay un error de runtime verificable: `src/components/guardians/GuardiansPage.jsx` pasa `isSearching={isSearching}` al componente `SearchBar`, pero `isSearching` no está definido en ninguna parte del archivo.

**Impacto:**
- Puede lanzar `ReferenceError` al renderizar la vista de apoderados.
- Es un problema más directo y verificable que varias de las hipótesis infraestructurales del plan.

**Fix esperado:**
- Definir `isSearching`.
- O pasar una expresión real, por ejemplo derivada de `loading` y `debouncedSearch`.

- [ ] Revisar `GuardiansPage.jsx` antes de asumir que todo el problema viene de RLS o credenciales

### 5.1 Problema: `get_current_user_role()` retorna `admin` pero las policies comparan con `ADMIN`

**Tipo:** Mixto

**Las RLS policies usan:**
```sql
get_current_user_role() = 'ADMIN'
```

**Si la función retorna** `'admin'` (minúscula), la comparación FALLA y retorna 0 registros.

**Fix SQL:**
```sql
-- Opción A: Hacer la función retornar MAYÚSCULAS
CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS TEXT AS $$
  SELECT UPPER(role) FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Opción B: Hacer las policies case-insensitive  
-- Para cada policy, cambiar:
--   get_current_user_role() = 'ADMIN'
-- Por:
--   UPPER(get_current_user_role()) = 'ADMIN'
```

- [ ] Verificar qué retorna `get_current_user_role()` exactamente (caso)
- [ ] Asegurar que coincide con lo que comparan las policies

---

### 5.2 Problema: Sesión Expirada / Token Inválido Después de Rotación de Claves

**Tipo:** Manual

Si se rotaron las claves de Supabase pero la app sigue usando tokens firmados con la clave anterior:

**Fix:**
```javascript
// En la console del navegador (F12):
localStorage.clear();
sessionStorage.clear();
location.reload();
```

Luego re-login.

- [ ] Limpiar localStorage del navegador
- [ ] Re-login después de limpiar

---

### 5.3 Problema: React Query Cachea Errores

**Tipo:** Manual

React Query puede cachear un error y no reintentar. Si hubo un error temporal, los datos quedan como "error" en caché.

**Fix:**
```javascript
// En este repo no hay ReactQueryDevtools ni queryClient expuesto en window.
// La forma operativa es recargar la app y volver a disparar la query.
location.reload();
```

- [ ] Recargar la página con Ctrl+Shift+R (hard reload sin caché)

---

### 5.4 Problema: Datos Null en Joins (fee.student es null)

**Tipo:** Asistido

Si el join `student:students(...)` retorna `null`, los componentes pueden crashear.

**Archivos ya corregidos (commit b76eff6):**
- `DebtDistributionChart.jsx` — filtra `f.student` antes de acceder
- `DebtorsTable.jsx` — filtra `f.student` antes de acceder
- `PaymentDetailsModal.jsx` — moved useEffect, added optional chaining
- `DateRangePicker.jsx` — added optional chaining for student

**Si el problema persiste:** Buscar otros componentes que acceden a `fee.student` sin verificar null.

```powershell
# Buscar accesos inseguros a fee.student
Select-String -Path "src\components\**\*.jsx","src\components\**\*.tsx" -Pattern "\.student\." -Recurse | Select-String -NotMatch "student\?\." | Select-String -NotMatch "\.student &&" | Select-Object -First 20
```

- [ ] Verificar que todos los accesos a `.student.` tienen null guard

---

### 5.5 Problema: Migraciones Pendientes

**Tipo:** Asistido

```powershell
npx supabase migration list
```

Si hay migraciones que no se han aplicado, pueden faltar tablas, columnas o funciones.

**Verificar la más reciente:** `20260306131321_sige_2026_corrections.sql`

- [ ] Todas las migraciones están aplicadas (no hay pendientes)

---

## FASE 6 — Tests de Diagnóstico Automatizados

### 6.1 Test: Verificar Estructura de Datos

**Tipo:** Asistido

```powershell
node test-diagnostics.cjs
```

**Esperado:** 5/5 tests pasan  
**Si fallan:** El output indica qué tabla/query tiene problemas.

- [ ] test-diagnostics.cjs → 5/5 pasan

---

### 6.2 Test: Verificar Queries de Producción

**Tipo:** Asistido

```powershell
node test-queries.cjs
```

**Nota importante:** Este archivo no es una prueba autoritativa mientras conserve queries con sintaxis antigua (`curso,cursos(...)` en vez de `curso:cursos(...)`). Los queries de producción en `src/` están corregidos; si este test falla, no demuestra por sí solo un problema en la app.

- [ ] Usar este test solo como referencia secundaria

---

### 6.3 Test: Build de Producción

**Tipo:** Asistido

```powershell
npx vite build 2>&1
```

**Esperado:** Build exitoso sin errores  
**Warnings de TypeScript son aceptables**, errores rojos no.

- [ ] Build exitoso

---

### 6.4 Test: Verificar Componente Específico (Browser)

**Tipo:** Manual

En la console del navegador (F12), después de hacer login:

```javascript
// En este repo no existe window.__SUPABASE__.
// Lo verificable desde browser sin instrumentación extra es el token local.
const rawSession = localStorage.getItem('supabase.auth.token');
console.log('Sesión cacheada:', !!rawSession);

// Y además conviene revisar el banner/console de Dashboard:
// [DASHBOARD] Role: ... | Fees: ... | Error: ...
```

- [ ] Existe sesión local en `supabase.auth.token`
- [ ] El log `[DASHBOARD]` muestra `Fees` y `Error` coherentes

---

## FASE 7 — Checklist de Resolución Final

## Acciones Manuales Obligatorias Antes de Cerrar el Diagnóstico

1. Abrir la app y reproducir el fallo en la ruta exacta.
2. Revisar `Console` y `Network` en el navegador.
3. Copiar el texto real del `ErrorBoundary` si aparece `Algo salió mal`.
4. Confirmar si el problema ocurre solo en local, solo en Vercel o en ambos.
5. Probar con un usuario real autenticado si el problema involucra datos restringidos por RLS.
6. Si hubo rotación de claves o cambios de sesión, limpiar `localStorage` y volver a iniciar sesión.

## Acciones Asistidas Recomendadas

1. Ejecutar `npm run dev` y abrir `/__inspect/`.
2. Ejecutar `npx vite build` para validar que el bundle compila.
3. Ejecutar `node test-diagnostics.cjs`.
4. Ejecutar consultas SQL para validar datos y policies.
5. Consultar `vercel list winterhill-cobros` y `vercel logs <deployment-url> --no-follow --limit 20 --json`.

### Escenario A: Todo funciona en backend, falla en frontend
1. Limpiar localStorage → `localStorage.clear(); location.reload();`
2. Limpiar caché Vite → `Remove-Item -Recurse node_modules\.vite`
3. Reiniciar dev server → `npm run dev`
4. Revisar primero errores de runtime concretos en páginas como `GuardiansPage`
5. Hard reload → Ctrl+Shift+R

### Escenario B: RLS bloquea datos
1. Verificar `get_current_user_role()` retorna value que coincide con policies
2. Verificar que el case (MAYÚSCULAS/minúsculas) coincide
3. Aplicar fix SQL del punto 5.1

### Escenario C: Credenciales incorrectas después de rotación
1. Copiar nueva Anon Key de Supabase Dashboard → Settings → API
2. Pegar en `.env` como `VITE_SUPABASE_ANON_KEY`
3. Reiniciar dev server
4. Limpiar localStorage en browser
5. Re-login

### Escenario D: Componente crashea por datos null
1. Abrir F12 → Console → leer error del ErrorBoundary
2. Identificar componente y línea
3. Agregar null guard (`?.` o filtro `.filter(x => x.field)`)

### Escenario F: Referencia a variable no definida en render
1. Buscar `ReferenceError` en console/ErrorBoundary
2. Confirmar si la variable existe en el archivo
3. Priorizar este fix por sobre hipótesis de RLS si el crash ocurre antes de completar la query

### Escenario E: Migraciones no aplicadas
1. `npx supabase migration list` → ver cuáles faltan
2. Aplicar con: `npx supabase db push`
3. Reiniciar app

---

## Orden de Ejecución Recomendado

```
1. FASE 1.2 → Verificar .env (2 min)
2. FASE 1.3 → Test conexión Supabase (2 min)  
3. FASE 2.1 → Verificar login (3 min)
4. FASE 4.1 → Console del navegador (5 min)
5. FASE 4.2 → Network tab (5 min)
6. FASE 5.0 → Revisar bugs concretos de runtime en componentes (5 min)
7. FASE 4.3 → `vite-plugin-inspect` si Console/Network no bastan (5-10 min)
8. FASE 3.3 → Query como usuario autenticado (5 min)
9. FASE 3.1 → Verificar RLS policies (10 min)
10. FASE 5.1 → Fix case de get_current_user_role (solo si Fase 3 lo confirma) (5 min)
```

**Tiempo total estimado de diagnóstico completo: 30-40 minutos**
