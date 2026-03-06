# 🔍 Auditoría de Código — winterhill-cobros v1.1

**Rama:** `html_pdf` — Commit `f5b146e`  
**Fecha de Auditoría:** 22 de febrero de 2026  
**Auditor:** Senior QA Automation Engineer  
**Stack:** React 18 + Vite + Supabase + TypeScript/JSX  

---

## 📊 Resumen de Riesgo: 🔴 CRÍTICO

| Categoría | Nivel |
|-----------|-------|
| Seguridad | 🔴 Crítico |
| Lógica | 🟡 Medio |
| Eficiencia | 🟡 Medio |
| Testabilidad | 🟠 Alto |
| Mantenibilidad | 🟡 Medio |

---

## 🚨 Errores Detectados

### 🔴 CRÍTICOS (Requieren corrección inmediata)

#### 1. Escalación de Privilegios — Default a ADMIN cuando no hay perfil
**Archivos:** `src/hooks/usePermissions.ts` líneas 43 y 75  
**Código afectado:**
```typescript
// usePermissions.ts:43
const userProfile = (user?.profile || USER_PROFILES.ADMIN) as UserProfile;

// usePermissions.ts:75 (useUserProfile)
return (authContext.user?.profile || USER_PROFILES.ADMIN) as UserProfile;
```
**Impacto:** Si un usuario no tiene perfil asignado (ej. usuario nuevo, error de DB, campo nulo), **obtiene permisos de ADMIN completos** — puede crear pagos libres, eliminar registros, gestionar usuarios y exportar datos.  
**Riesgo:** Cualquier usuario que se registre y no tenga un perfil asignado en la tabla `profiles` obtiene privilegios de super-administrador.  
**Corrección:**
```typescript
const userProfile = (user?.profile || USER_PROFILES.READONLY) as UserProfile;
```

---

#### 2. URL de Vercel con datos de proyecto/usuario expuestos en producción
**Archivo:** `vite.config.js` líneas 7-9  
**Código afectado:**
```javascript
if (mode === 'production' && !process.env.VITE_SITE_URL) {
  process.env.VITE_SITE_URL = 'https://winterhill-cobros-oeob29ghh-eduardomeiks-projects.vercel.app';
}
```
**Impacto:** Expone el nombre de usuario de Vercel (`eduardomeiks`) y el ID del proyecto. Este valor se usa como `redirectTo` en OAuth, lo que significa que si la variable de entorno no está configurada, los tokens de autenticación se envían a una URL hardcodeada.  
**Corrección:** Eliminar el fallback hardcodeado y requerir la variable de entorno, o usar `window.location.origin` como fallback.

---

#### 3. Source Maps habilitados en producción
**Archivo:** `vite.config.js` línea 17  
**Código afectado:**
```javascript
build: {
  sourcemap: true,  // ← Expone código fuente completo en producción
}
```
**Impacto:** Los source maps permiten a cualquier persona reconstruir el código fuente original de la aplicación, incluyendo lógica de negocio, nombres de funciones internas y comentarios. Facilita la ingeniería inversa y la búsqueda de vulnerabilidades.  
**Corrección:**
```javascript
sourcemap: mode !== 'production', // Solo en desarrollo
```

---

#### 4. Fuga masiva de PII (Datos Personales) en consola
**Archivo:** `src/components/matricula/MatriculaWizard.jsx` (múltiples ubicaciones)  
**Código afectado (ejemplo):**
```javascript
console.log('📋 Generando documentos con datos del wizard:', {
  guardian, student, economicData, enrollmentYear
});
```
**Impacto:** Se loguean a consola datos completos de apoderados (RUN, email, dirección, teléfono, profesión), estudiantes y datos económicos. Aunque `terser` con `drop_console: true` debería eliminarlos en build, **esto depende de que el build se ejecute correctamente** y no protege ambientes de staging/preview de Vercel.  
**Agravante:** El archivo tiene **22+ sentencias console.log** con datos sensibles en un componente de 2,720 líneas.  
**Corrección:** Reemplazar todos los `console.log` con el servicio `Logger` que ya existe en el proyecto, o usar una función wrapper que verifique `import.meta.env.DEV`.

---

#### 5. Paquetes de servidor (Puppeteer/Chromium) en dependencias de frontend
**Archivo:** `package.json` líneas 17 y 28  
**Código afectado:**
```json
"dependencies": {
  "@sparticuz/chromium": "^141.0.0",  // ~130MB, solo para servidor
  "puppeteer-core": "^24.29.1",       // Solo para servidor
}
```
**Impacto:** Estos paquetes son binarios de servidor (~130MB+) que se incluyen en el bundle del frontend. Incrementan dramáticamente el tamaño del build, los tiempos de deploy y potencialmente el consumo de memoria del navegador. Además, exponen la cadena de dependencias de Chromium a ataques de supply chain en el cliente.  
**Corrección:** Mover a `devDependencies` o crear un `package.json` separado para el servicio de PDF.

---

### 🟠 ALTOS (Corregir antes del próximo release)

#### 6. Violación de Rules of Hooks en PaymentDetailsModal
**Archivo:** `src/components/payments/PaymentDetailsModal.jsx`  
**Código afectado:**
```jsx
// Early return ANTES de llamar hooks
if (!payment) return null;

// Hooks llamados DESPUÉS del return condicional
const { canEditPayment, ... } = usePermissions(); // ← Violación
```
**Impacto:** React requiere que los hooks se llamen siempre en el mismo orden. Un early return antes de hooks causa comportamiento impredecible: crashes intermitentes, estado corrupto, o renders infinitos dependiendo del ciclo de vida del componente.  
**Corrección:** Mover todos los hooks antes de cualquier return condicional.

---

#### 7. Rutas de matrícula/repactación sin control de rol
**Archivo:** `src/App.jsx` líneas 131-132  
**Código afectado:**
```jsx
<Route path="matricula" element={<MatriculaWizard />} />
<Route path="repactacion" element={<RepactacionWizard />} />
```
**Impacto:** Estas rutas están dentro de `<ProtectedRoute>` (requieren autenticación) pero **no** dentro de `<StaffRoute>` (no verifican rol). Un usuario con rol `guardian` podría acceder a `/matricula` directamente escribiendo la URL, potencialmente creando o modificando matrículas sin autorización.  
**Corrección:**
```jsx
<Route path="matricula" element={<StaffRoute><MatriculaWizard /></StaffRoute>} />
<Route path="repactacion" element={<StaffRoute><RepactacionWizard /></StaffRoute>} />
```
> **Nota:** Si el diseño intencional es que los guardians accedan a matrícula, entonces se necesita un `GuardianRoute` y validar en el componente que el guardian solo modifique sus propios datos.

---

#### 8. Servicio de password reset apunta a URL hardcodeada de Supabase
**Archivo:** `src/contexts/AuthContext.tsx` línea 199  
**Código afectado:**
```typescript
const functionUrl = 'https://yeotpplgerfpxviqazrn.supabase.co/functions/v1/password-recovery';
```
**Impacto:** La URL del proyecto de Supabase está hardcodeada en el código fuente. Si el proyecto cambia o se migra, esta función dejará de funcionar silenciosamente. Además, expone el ID del proyecto Supabase (`yeotpplgerfpxviqazrn`).  
**Corrección:**
```typescript
const functionUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/password-recovery`;
```

---

#### 9. HTML sin escape en templates de documentos legales
**Archivos:** `src/services/autorizacionDescuento.ts`, `src/services/enrollmentReceipt.ts`  
**Código afectado:**
```typescript
// autorizacionDescuento.ts
`<td>${guardian.first_name} ${guardian.last_name}</td>`
`<td>${guardian.run}</td>`
```
**Impacto:** Los valores del usuario se interpolan directamente en HTML sin escapar. Si un nombre de apoderado contiene `<script>alert('xss')</script>`, este HTML se inyecta en iframes de preview y potencialmente en PDFs. Aunque el riesgo es atenuado por el contexto (datos vienen de la DB), un atacante que modifique su nombre podría ejecutar código en el navegador de un administrador.  
**Corrección:** Crear un helper `escapeHtml()` y aplicarlo a todos los valores interpolados:
```typescript
function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
```

---

### 🟡 MEDIOS (Corregir en sprints regulares)

#### 10. PaymentsPage carga TODOS los registros sin paginación de servidor
**Archivo:** `src/components/payments/PaymentsPage.jsx`  
**Impacto:** La consulta trae **todas** las cuotas (fee) de la base de datos a memoria del navegador. Con cientos de estudiantes y 10+ cuotas por año, esto puede significar miles de registros cargados de una sola vez.  
**Corrección:** Implementar paginación en servidor con `.range(from, to)` de Supabase.

---

#### 11. Patrón N+1 en búsqueda de estudiantes en PaymentsPage
**Archivo:** `src/components/payments/PaymentsPage.jsx`  
**Impacto:** La búsqueda por nombre de estudiante ejecuta una query separada a la tabla `students` y luego re-filtra los fees — dos queries por cada keystroke de búsqueda.  
**Corrección:** Usar un join en la query principal o implementar debounce + búsqueda en servidor con `ilike` en el campo joined.

---

#### 12. Caches a nivel de módulo sin invalidación por cambio de usuario
**Archivo:** `src/services/matricula.ts` (líneas 107-111)  
**Código afectado:**
```typescript
let _guardianCache: Record<string, GuardianRecord | null | undefined> = {};
let _guardianFetchInFlight: Record<string, Promise<GuardianRecord | null> | undefined> = {};
```
**Impacto:** Si un usuario cierra sesión y otro inicia sesión en la misma pestaña (sin recargar), el cache sirve datos del usuario anterior. Esto podría exponer información de un apoderado a otro.  
**Corrección:** Invalidar caches en el listener de `onAuthStateChange` cuando el evento es `SIGNED_OUT` o `SIGNED_IN`.

---

#### 13. `window.location.href` para redirecciones en lugar de React Router
**Archivo:** `src/components/matricula/MatriculaWizard.jsx`  
**Impacto:** Usar `window.location.href = '/some-path'` causa un full page reload, destruyendo todo el estado de React y forzando una recarga completa de la aplicación (re-fetch de sesión, datos, etc.).  
**Corrección:** Usar `useNavigate()` de React Router.

---

#### 14. Timeout de sesión inactiva deshabilitado
**Archivo:** `src/contexts/AuthContext.tsx` línea 11  
**Código afectado:**
```typescript
const ENABLE_IDLE_TIMEOUT = false;
```
**Impacto:** No hay timeout por inactividad. Si un usuario deja la sesión abierta en un computador público, la sesión permanece activa indefinidamente.  
**Corrección:** Habilitar el idle timeout (`true`) al menos en producción.

---

#### 15. `session` tipado como `any` en AuthState
**Archivo:** `src/types/auth.ts` línea 12  
**Código afectado:**
```typescript
session: any | null;
```
**Impacto:** Pierde toda la type-safety de `@supabase/supabase-js`. Cualquier acceso a propiedades de session no se verifica en compile-time.  
**Corrección:**
```typescript
import { Session } from '@supabase/supabase-js';
session: Session | null;
```

---

#### 16. Placeholders sin reemplazar en templates de documentos
**Archivo:** `src/services/autorizacionDescuento.ts`  
**Código afectado:**
```html
<p>[Dirección del Colegio]</p>
<p>[Teléfono]</p>
```
**Impacto:** Los documentos legales generados para los apoderados muestran placeholders en lugar de información real del colegio. Esto resta profesionalismo y puede invalidar legalmente los documentos.  
**Corrección:** Reemplazar con datos reales o parametrizar desde variables de entorno/configuración.

---

#### 17. MatriculaWizard tiene 2,720 líneas — violación severa de SRP
**Archivo:** `src/components/matricula/MatriculaWizard.jsx`  
**Impacto:** Un solo componente con 2,720 líneas, 30+ useState hooks y 15+ useEffect hooks es extremadamente difícil de mantener, testear y debuggear. Cualquier cambio tiene alto riesgo de regresión.  
**Corrección:** Descomponer en sub-componentes por paso del wizard (GuardianStep, StudentStep, EconomicStep, DocumentStep, ReviewStep) y extraer lógica a custom hooks (`useEnrollmentWizard`, `useDocumentGeneration`).

---

#### 18. Memory leak en preview de PDF
**Archivo:** `src/services/enrollmentReceipt.ts`  
**Código afectado:**
```typescript
const url = URL.createObjectURL(blob);
window.open(url, '_blank');
// ← Falta URL.revokeObjectURL(url)
```
**Impacto:** Cada preview de PDF crea un Object URL que nunca se libera, acumulando blobs en memoria. Con uso repetido, puede degradar el rendimiento del navegador.  
**Corrección:** Usar `URL.revokeObjectURL(url)` después de un timeout o en un cleanup handler.

---

### 🟢 BAJOS (Mejoras recomendadas)

#### 19. Logs duplicados con mismo código
**Archivo:** `src/types/logging.ts`  
Los códigos `AUTH_PASSWORD_UPDATE_SUCCESS` y `AUTH_PASSWORD_UPDATE_FAILED` comparten prefijo `AUTH005` — puede causar confusión en análisis de logs.

#### 20. `email.ts` loguea respuestas completas de email
**Archivo:** `src/services/email.ts`  
Tres `console.log` que podrían incluir IDs de mensaje o contenido parcial del email. Aunque `terser` los elimina, es mejor práctica usar `Logger`.

#### 21. Función `normalizeRun` duplicada
La función existe en `src/utils/rut.ts` y también se define localmente en `src/services/reporting.js` — viola DRY.

---

## 💡 Sugerencias de Mejora (Código Refactorizado)

### Fix #1 — Corregir escalación de privilegios
```typescript
// src/hooks/usePermissions.ts
export const usePermissions = (): PermissionHookReturn => {
  const authContext = useContext(AuthContext);
  if (!authContext) {
    throw new Error('usePermissions must be used within an AuthProvider');
  }
  const { user } = authContext;
  // ✅ READONLY como default seguro en vez de ADMIN
  const userProfile = (user?.profile || USER_PROFILES.READONLY) as UserProfile;
  // ... resto igual
};

export const useUserProfile = (): UserProfile => {
  const authContext = useContext(AuthContext);
  if (!authContext) {
    throw new Error('useUserProfile must be used within an AuthProvider');
  }
  // ✅ READONLY como default seguro
  return (authContext.user?.profile || USER_PROFILES.READONLY) as UserProfile;
};
```

### Fix #2 — Eliminar URL hardcodeada y source maps
```javascript
// vite.config.js
export default defineConfig(({ mode }) => {
  if (mode === 'production' && !process.env.VITE_SITE_URL) {
    // ✅ No usar fallback hardcodeado — forzar configuración explícita
    console.error('❌ VITE_SITE_URL is required for production builds.');
    // Se usará window.location.origin como fallback en runtime
  }

  return {
    plugins: [react()],
    build: {
      outDir: 'dist',
      sourcemap: mode !== 'production', // ✅ Solo en desarrollo
      minify: 'terser',
      terserOptions: {
        compress: {
          drop_console: true,
          drop_debugger: true
        }
      }
    },
    // ...
  };
});
```

### Fix #3 — Proteger rutas de matrícula
```jsx
// src/App.jsx
<Route path="matricula" element={<StaffRoute><MatriculaWizard /></StaffRoute>} />
<Route path="repactacion" element={<StaffRoute><RepactacionWizard /></StaffRoute>} />
```

### Fix #4 — Función helper para escapar HTML
```typescript
// src/utils/html.ts
export function escapeHtml(unsafe: string | null | undefined): string {
  if (!unsafe) return '';
  return String(unsafe)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
```

### Fix #5 — Invalidar cache al cambiar de usuario
```typescript
// src/services/matricula.ts — agregar función exportada
export function clearGuardianCaches() {
  _guardianCache = {};
  _guardianFetchInFlight = {};
  _attemptedAutoCreate = {};
  _attemptedManualCreate = {};
}

// src/contexts/AuthContext.tsx — en onAuthStateChange
if (event === 'SIGNED_OUT') {
  clearGuardianCaches(); // ✅ Limpiar datos del usuario anterior
  navigate('/login');
}
```

---

## 🧪 Plan de Pruebas

### Pruebas Unitarias Críticas

| # | Componente/Función | Caso de Prueba | Input | Output Esperado |
|---|-------------------|----------------|-------|-----------------|
| 1 | `usePermissions` | Usuario sin perfil → permisos de READONLY | `user.profile = undefined` | `userProfile === 'READONLY'`, `canCreateFreePayment() === false` |
| 2 | `usePermissions` | Usuario ADMIN → permisos completos | `user.profile = 'ADMIN'` | `canCreateFreePayment() === true`, `isAdmin() === true` |
| 3 | `usePermissions` | Usuario ASIST → sin pagos libres | `user.profile = 'ASIST'` | `canCreateFreePayment() === false`, `canCreateSpecificPayment() === true` |
| 4 | `validateRun` | RUN válido | `'12.345.678-5'` | `true` |
| 5 | `validateRun` | RUN con K | `'11.111.111-K'` | `true` (si DV correcto) |
| 6 | `validateRun` | RUN inválido (DV incorrecto) | `'12.345.678-0'` | `false` |
| 7 | `normalizeRun` | RUN con puntos y guión | `'12.345.678-5'` | `'123456785'` |
| 8 | `processFeesWithStatus` | Cuota vencida | `{ due_date: '2025-01-01', status: 'pending' }` | `status === 'overdue'` |
| 9 | `processFeesWithStatus` | Cuota pagada sigue pagada | `{ due_date: '2025-01-01', status: 'paid' }` | `status === 'paid'` |
| 10 | `calculateFeeStats` | Array vacío | `[]` | `{ totalFees: 0, totalPaid: 0, ... }` |
| 11 | `escapeHtml` | Input con tags HTML | `'<script>alert(1)</script>'` | `'&lt;script&gt;alert(1)&lt;/script&gt;'` |
| 12 | `formatCurrency` | Peso chileno sin decimales | `150000` | `'$150.000'` |
| 13 | `getDaysUntilDue` | Fecha pasada | `'2025-01-01'` | Número negativo |
| 14 | `hasPermission` | Perfil inexistente | `('UNKNOWN', 'EDIT_PAYMENT')` | `false` |
| 15 | `mapSupabaseUserToLocalUser` | User null | `null` | `null` |

### Pruebas de Integración Críticas

| # | Flujo | Descripción | Validación |
|---|-------|-------------|------------|
| 1 | Auth → Permisos | Login → verificar perfil → verificar permisos aplicados | El perfil se obtiene de DB y se aplica correctamente |
| 2 | Auth → Signout → Signin otro usuario | Cerrar sesión → abrir sesión con otro usuario | Caches limpiados, datos del usuario anterior no visibles |
| 3 | Registro de pago (ASIST) | Intentar pago libre con perfil ASIST | Debe ser rechazado con mensaje descriptivo |
| 4 | Registro de pago (ADMIN) | Crear pago libre | Debe aceptarse y guardarse correctamente |
| 5 | Matrícula Wizard completo | Step 1-5 → generar documentos → finalizar | Documentos generados con datos correctos, sin placeholders |
| 6 | Ruta protegida sin auth | Acceder a `/payments` sin sesión | Redirige a `/login` |
| 7 | Ruta staff por guardian | Acceder a `/dashboard` con rol guardian | Redirige a `/apoderado/bienvenido` |
| 8 | Idle timeout | Sesión activa → inactividad 30 min | Sesión cerrada automáticamente (cuando se habilite) |
| 9 | PDF Generation | Generar PDF con nombre que contiene HTML | PDF generado sin XSS, caracteres escapados |
| 10 | Export Excel | Exportar con dataset vacío | Archivo generado con headers pero sin filas |

### Pruebas de Seguridad

| # | Vector | Descripción | Validación |
|---|--------|-------------|------------|
| 1 | Privilege Escalation | Crear usuario sin perfil en DB → verificar permisos | Debe tener permisos READONLY, no ADMIN |
| 2 | XSS en nombres | Crear guardian con nombre `<img onerror=alert(1)>` | No ejecuta JS en previews de documentos |
| 3 | IDOR en matrícula | Acceder a `/matricula` como guardian | Debe estar bloqueado o limitado a datos propios |
| 4 | Session Fixation | Abrir 2 tabs → logout en tab 1 | Tab 2 debe detectar logout y redirigir |
| 5 | Source Maps | Verificar build de producción | No debe contener `.map` files |

---

## 📈 Métricas del Proyecto

| Métrica | Valor | Estado |
|---------|-------|--------|
| Archivos fuente analizados | 25+ | ✅ |
| Líneas de código auditadas | ~8,500+ | ✅ |
| Vulnerabilidades críticas | 5 | 🔴 |
| Vulnerabilidades altas | 4 | 🟠 |
| Vulnerabilidades medias | 9 | 🟡 |
| Vulnerabilidades bajas | 3 | 🟢 |
| Cobertura de tests existente | ~5% (solo 5 test files) | 🔴 |
| Componente más grande | MatriculaWizard (2,720 líneas) | 🔴 |
| Principio SOLID más violado | SRP (Single Responsibility) | 🟡 |

---

## ⚖️ Veredicto Final

# 🔴 RECHAZADO

**Justificación:** La aplicación contiene una **vulnerabilidad de escalación de privilegios** (Error #1) que permite a cualquier usuario sin perfil obtener permisos de administrador. Combinado con source maps expuestos en producción, URLs hardcodeadas con credenciales de proyecto, y rutas de matrícula sin protección de rol, el riesgo de seguridad es inaceptable para un sistema que maneja datos financieros y personales de estudiantes y apoderados (datos protegidos por la Ley 19.628 de Chile sobre Protección de Datos Personales).

### Acciones requeridas antes de re-auditoría:

1. ✅ **INMEDIATO:** Cambiar default de permisos de `ADMIN` a `READONLY` (Error #1)
2. ✅ **INMEDIATO:** Deshabilitar source maps en producción (Error #3)
3. ✅ **INMEDIATO:** Eliminar URL hardcodeada de Vercel (Error #2)
4. ✅ **CORTO PLAZO:** Proteger rutas de matrícula con `StaffRoute` (Error #7)
5. ✅ **CORTO PLAZO:** Corregir Rules of Hooks en PaymentDetailsModal (Error #6)
6. ✅ **CORTO PLAZO:** Construir función `resetPassword` con variable de entorno (Error #8)
7. ✅ **MEDIANO PLAZO:** Implementar escape de HTML en templates (Error #9)
8. ✅ **MEDIANO PLAZO:** Mover puppeteer/chromium a devDependencies (Error #5)
9. ✅ **MEDIANO PLAZO:** Aumentar cobertura de tests a >60% en módulos críticos

---

*Reporte generado el 22/02/2026 — Próxima auditoría recomendada después de aplicar correcciones críticas (Errores 1-3).*
