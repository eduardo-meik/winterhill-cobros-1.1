# Instrucciones del Proyecto

## Estilo y Convenciones de Código
* **Frontend:** Usa `VITE_` como prefijo para todas las variables de entorno (ej. `VITE_SUPABASE_URL`).
* Prioriza React funcional con TailwindCSS para los estilos visuales.

## Arquitectura
* **Vite-Supabase:** El proyecto utiliza Supabase como backend (Auth, DB y RLS) y Vercel/Netlify para Edge Functions y despliegue estático.
* **Base de Datos:** Antes de modificar el código frontend del backend (como inserciones/mutaciones), verifica si el cambio requiere una actualización en las políticas RLS o en el esquema (ref: `docs/db_schema.md`).

## Construcción y Testing
* **Instalación:** `npm install`
* **Desarrollo:** `npm run dev`
* **Construcción:** `npm run build`
* **Tests Unitarios:** `npm run test`

## Protocolo de Debugging (PIV Loop)
Cuando se reporte un bug, sigue este ciclo:
1. **Plan (P):** Investiga si el error es de cliente (Vite), de permisos (RLS) o de datos (DB).
2. **Implement (I):** Aplica cambios y sugerencias.
3. **Validate (V):** Sugiere comandos de prueba y verifica la consistencia con la Base de datos de Supabase.