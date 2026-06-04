# Sistema de Cobros Escolares

Sistema de gestión de cobros y pagos escolares desarrollado con React, Supabase y TailwindCSS.

## Características

- Gestión de estudiantes y apoderados
- Control de pagos y aranceles
- Reportes y estadísticas
- **Autenticación con Google OAuth** 🆕
- Autenticación tradicional con email/password
- Interfaz responsiva
- Modo oscuro/claro

## Tecnologías

- React 18
- Supabase (Base de datos y autenticación)
- TailwindCSS
- React Router
- React Hook Form
- Recharts
- **Google OAuth 2.0** 🆕

## Configuración

### Variables de Entorno

Crea un archivo `.env.local` con las siguientes variables:

```bash
VITE_SUPABASE_URL=tu-proyecto-supabase-url
VITE_SUPABASE_ANON_KEY=tu-supabase-anon-key
VITE_GOOGLE_CLIENT_ID=tu-google-client-id
VITE_SITE_URL=http://localhost:5173
```

### Configuración de Google OAuth

Para configurar la autenticación con Google, consulta `docs/GOOGLE_AUTH_SETUP.md`, que contiene instrucciones detalladas para:

- Configurar Google Cloud Console
- Configurar Supabase OAuth
- Variables de entorno de producción
- Mejores prácticas de seguridad

### Documentación Clave

- `BACKLOG.MD`: estado de trabajo y prioridades activas
- `wiki/Home.md`: mapa de conocimiento estable del proyecto
- `docs/QUICK_START.md`: arranque rápido operativo
- `docs/SECURITY_FIXES_APPLICATION_GUIDE.md`: runbook canónico de hardening

## Desarrollo

```bash
# Instalar dependencias
npm install

# Iniciar servidor de desarrollo
npm run dev

# Construir para producción
npm run build
```

## Autenticación

El sistema soporta dos métodos de autenticación:

### 1. Email/Password Tradicional
- Registro con email y contraseña
- Recuperación de contraseña
- Verificación de email

### 2. Google OAuth (Nuevo)
- Inicio de sesión con cuenta de Google
- Registro automático con datos de Google
- No requiere verificación adicional de email

## Desarrollo

```bash
# Instalar dependencias
npm install

# Iniciar servidor de desarrollo
npm run dev

# Construir para producción
npm run build
```

## Licencia

MIT