# Aplicar Migraciones de Base de Datos

## Problema
La tabla `guardian_intake_surveys` no existe en la base de datos remota de Supabase, causando errores 404.

## Solución

### Opción 1: Usar Supabase CLI (Recomendado)

```powershell
# 1. Instalar Supabase CLI si no lo tienes
scoop install supabase
# o
npm install -g supabase

# 2. Enlazar tu proyecto
supabase link --project-ref yeotpplgerfpxviqazrn

# 3. Aplicar migraciones pendientes
supabase db push
```

### Opción 2: Ejecutar SQL manualmente en Supabase Dashboard

1. Abre: https://supabase.com/dashboard/project/yeotpplgerfpxviqazrn
2. Ve a **SQL Editor**
3. Ejecuta estos archivos en orden:

#### 1. Matrícula Base (enrollments, enrollment_students, etc.)
Ejecuta el contenido completo de:
`supabase/migrations/20250924_matricula_base.sql`

#### 2. Guardian Intake Survey
Ejecuta el contenido completo de:
`supabase/migrations/20250925_guardian_intake_survey.sql`

## Verificación

Después de aplicar las migraciones, verifica que las tablas existan:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'enrollments',
  'enrollment_students',
  'guardian_intake_surveys'
);
```

Deberías ver las 3 tablas listadas.

## Tablas creadas

1. **enrollments** - Una matrícula por apoderado por año
2. **enrollment_students** - Estudiantes asociados a cada matrícula
3. **document_templates** - Plantillas de documentos legales (pagaré, etc.)
4. **enrollment_documents** - Documentos generados por matrícula
5. **signatures** - Auditoría de firmas
6. **pre_receipts** - Recibos previos
7. **guardian_intake_surveys** - Encuesta anual de ingreso del apoderado

## Después de aplicar

Recarga la aplicación y verifica:
- ✅ No más errores 404 en `guardian_intake_surveys`
- ✅ La encuesta se pre-carga con datos existentes
- ✅ El portal de aranceles muestra estudiantes y cuotas
