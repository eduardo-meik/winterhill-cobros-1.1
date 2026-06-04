# Script para aplicar migraciones del Libro de Matrícula
# Date: 2025-12-19

# Configuración
$PROJECT_REF = "yeotpplgerfpxviqazrn"
$SUPABASE_URL = "https://yeotpplgerfpxviqazrn.supabase.co"
$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inllb3RwcGxnZXJmcHh2aXFhenJuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4OTc4MjYsImV4cCI6MjA2MDQ3MzgyNn0.qfjT0PLm3ff4m3jr7FGEAYCu0Gm97YEtZDUe-tS_urs"

# IMPORTANTE: Necesitas reemplazar esto con tu SERVICE_ROLE_KEY de Supabase
# Lo encuentras en: Supabase Dashboard > Settings > API > service_role key
$SERVICE_ROLE_KEY = "YOUR_SERVICE_ROLE_KEY_HERE"

if ($SERVICE_ROLE_KEY -eq "YOUR_SERVICE_ROLE_KEY_HERE") {
    Write-Host "❌ ERROR: Necesitas configurar SERVICE_ROLE_KEY" -ForegroundColor Red
    Write-Host "1. Ve a: https://supabase.com/dashboard/project/$PROJECT_REF/settings/api" -ForegroundColor Yellow
    Write-Host "2. Copia la clave 'service_role' (secret)" -ForegroundColor Yellow
    Write-Host "3. Reemplaza SERVICE_ROLE_KEY en este script" -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Aplicando migraciones del Libro de Matrícula..." -ForegroundColor Cyan

# Función para ejecutar SQL
function Invoke-SupabaseSQL {
    param(
        [string]$Query,
        [string]$MigrationName
    )
    
    Write-Host "`n📝 Aplicando: $MigrationName" -ForegroundColor Yellow
    
    $headers = @{
        "apikey" = $SERVICE_ROLE_KEY
        "Authorization" = "Bearer $SERVICE_ROLE_KEY"
        "Content-Type" = "application/json"
        "Prefer" = "return=representation"
    }
    
    $body = @{
        query = $Query
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body $body
        Write-Host "✅ $MigrationName aplicada exitosamente" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Error en $MigrationName`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Migración 1: Agregar estado PRE_MATRICULADO
$migration1 = @"
BEGIN;

ALTER TABLE public.students
  DROP CONSTRAINT IF EXISTS students_estado_std_check;

ALTER TABLE public.students
  ADD CONSTRAINT students_estado_std_check
  CHECK (estado_std IN ('ACTIVO','RETIRADO','MATRICULADO','PRE_MATRICULADO'));

UPDATE public.students
SET estado_std = 'PRE_MATRICULADO'
WHERE created_at >= '2025-12-08'::date
  AND estado_std IN ('MATRICULADO', 'ACTIVO');

COMMENT ON COLUMN public.students.estado_std IS 
'Estado del estudiante: PRE_MATRICULADO (matrícula en proceso desde dic 8+), MATRICULADO (confirmado para inicio año escolar en marzo), ACTIVO (cursando), RETIRADO (dado de baja)';

COMMIT;
"@

# Migración 2: Agregar campos a guardians
$migration2 = @"
BEGIN;

ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS date_of_birth DATE;

ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS nivel_educacional VARCHAR(100);

ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

COMMENT ON COLUMN public.guardians.date_of_birth IS 'Fecha de nacimiento del apoderado para Libro de Matrícula';
COMMENT ON COLUMN public.guardians.nivel_educacional IS 'Nivel educacional: Básica Completa, Media Completa, Técnica, Universitaria, Postgrado, etc.';
COMMENT ON COLUMN public.guardians.apellido_paterno IS 'Apellido paterno del apoderado';
COMMENT ON COLUMN public.guardians.apellido_materno IS 'Apellido materno del apoderado';

COMMIT;
"@

# Migración 3: Agregar apellidos a students (ya existen, solo comentarios)
$migration3 = @"
BEGIN;

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

COMMENT ON COLUMN public.students.apellido_paterno IS 'Apellido paterno del estudiante';
COMMENT ON COLUMN public.students.apellido_materno IS 'Apellido materno del estudiante';

COMMIT;
"@

# Leer migración 4 desde archivo
$migration4Path = Join-Path $PSScriptRoot "supabase\migrations\20251219_create_libro_matricula_rpc.sql"
if (Test-Path $migration4Path) {
    $migration4 = Get-Content $migration4Path -Raw
} else {
    Write-Host "❌ No se encontró el archivo de migración RPC" -ForegroundColor Red
    exit 1
}

# Aplicar migraciones
Write-Host "`n════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  APLICANDO MIGRACIONES - LIBRO DE MATRÍCULA" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════`n" -ForegroundColor Cyan

$success = $true

# Nota: Como no tenemos endpoint directo de SQL, vamos a usar la API de Supabase Management
# Alternativa: usar supabase CLI o psql

Write-Host "⚠️  IMPORTANTE: Este script requiere ejecutar SQL directamente." -ForegroundColor Yellow
Write-Host "Recomendación: Usar Supabase CLI o copiar el SQL manualmente.`n" -ForegroundColor Yellow

Write-Host "═══ OPCIÓN 1: Supabase CLI ═══" -ForegroundColor Cyan
Write-Host "supabase db push" -ForegroundColor White
Write-Host ""

Write-Host "═══ OPCIÓN 2: PostgreSQL Client ═══" -ForegroundColor Cyan
Write-Host 'psql "postgresql://postgres.yeotpplgerfpxviqazrn:YOUR_PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres"' -ForegroundColor White
Write-Host ""

Write-Host "═══ OPCIÓN 3: Copiar SQL a Supabase Dashboard ═══" -ForegroundColor Cyan
Write-Host "1. Ve a: https://supabase.com/dashboard/project/$PROJECT_REF/editor" -ForegroundColor White
Write-Host "2. Pega el contenido de cada archivo .sql en orden" -ForegroundColor White
Write-Host ""

Write-Host "📄 Archivos de migración creados:" -ForegroundColor Green
Write-Host "  1. supabase\migrations\20251219_add_pre_matriculado_estado.sql" -ForegroundColor White
Write-Host "  2. supabase\migrations\20251219_add_guardian_fields_libro_matricula.sql" -ForegroundColor White
Write-Host "  3. supabase\migrations\20251219_add_student_apellidos_separated.sql" -ForegroundColor White
Write-Host "  4. supabase\migrations\20251219_create_libro_matricula_rpc.sql" -ForegroundColor White

Write-Host "`n✨ Presiona cualquier tecla para salir..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
