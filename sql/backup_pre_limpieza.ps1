## backup_pre_limpieza.ps1
## Backup de todas las tablas afectadas ANTES de la limpieza de datos
## Fecha: 2026-03-06

# Read token from environment variable — NEVER hardcode secrets
$token = $env:SUPABASE_ACCESS_TOKEN
if (-not $token) {
    Write-Host "ERROR: Set SUPABASE_ACCESS_TOKEN environment variable first" -ForegroundColor Red
    exit 1
}
$projectRef = "yeotpplgerfpxviqazrn"
$baseUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$backupDir = "sql\backups_pre_limpieza_2026-03-06"

# Crear directorio de backup
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

function Export-Table {
    param(
        [string]$TableName,
        [string]$Query
    )
    
    Write-Host "  Exportando $TableName..." -NoNewline
    
    $body = @{ query = $Query } | ConvertTo-Json -Depth 1
    
    try {
        $response = Invoke-RestMethod -Uri $baseUrl -Method POST -Headers $headers -Body $body
        $json = $response | ConvertTo-Json -Depth 10
        $outFile = Join-Path $backupDir "$TableName.json"
        $json | Out-File -FilePath $outFile -Encoding utf8
        $count = ($response | Measure-Object).Count
        Write-Host " OK ($count registros)" -ForegroundColor Green
    }
    catch {
        Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "=== BACKUP PRE-LIMPIEZA ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Directorio: $backupDir"
Write-Host ""

# 1. Tablas CRITICAS (serán modificadas directamente)
Write-Host "[CRITICAS]" -ForegroundColor Red
Export-Table "cheques" "SELECT * FROM cheques ORDER BY id"
Export-Table "fee" "SELECT * FROM fee ORDER BY id"

# 2. Tablas ALTAS (serán modificadas)
Write-Host "[ALTAS]" -ForegroundColor Yellow
Export-Table "guardians" "SELECT * FROM guardians ORDER BY id"
Export-Table "students" "SELECT * FROM students ORDER BY id"
Export-Table "student_guardian" "SELECT * FROM student_guardian ORDER BY id"

# 3. Tablas REFERENCIA (contexto)
Write-Host "[REFERENCIA]" -ForegroundColor White
Export-Table "profiles" "SELECT * FROM profiles ORDER BY id"
Export-Table "enrollments" "SELECT * FROM enrollments ORDER BY id"
Export-Table "enrollment_students" "SELECT * FROM enrollment_students ORDER BY enrollment_id, student_id"
Export-Table "student_academic_records" "SELECT * FROM student_academic_records ORDER BY id"
Export-Table "cursos" "SELECT * FROM cursos ORDER BY id"

Write-Host ""
Write-Host "=== BACKUP COMPLETADO ===" -ForegroundColor Green
Write-Host "Archivos guardados en: $backupDir"
Get-ChildItem $backupDir | Format-Table Name, @{N='Size(KB)';E={[math]::Round($_.Length/1KB,1)}} -AutoSize
