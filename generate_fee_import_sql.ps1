# ============================================================================
# GENERADOR DE SQL PARA IMPORTACION DE CUOTAS DESDE CSV
# ============================================================================
# Descripcion: Convierte CSV de cuotas a codigo SQL ejecutable
# Uso: .\generate_fee_import_sql.ps1 -CsvPath "cuotas.csv" -OwnerUuid "tu-uuid-aqui"
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$CsvPath = "cuotas_importacion.csv",
    
    [Parameter(Mandatory=$false)]
    [string]$OwnerUuid = "TU_USER_ID_AQUI",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "IMPORT_FEES_GENERATED.sql"
)

# Funcion para limpiar y parsear monto
function Parse-Amount {
    param([string]$AmountStr)
    
    # Quitar simbolos: $, espacios, puntos de miles
    $clean = $AmountStr -replace '[\$\s\.]', ''
    # Convertir a numero
    try {
        return [decimal]$clean
    } catch {
        Write-Warning "No se pudo parsear monto: $AmountStr"
        return 0
    }
}

# Funcion para formatear fecha DD-MM-YYYY a YYYY-MM-DD
function Format-Date {
    param([string]$DateStr)
    
    if ($DateStr -match '^(\d{2})-(\d{2})-(\d{4})$') {
        $day = $matches[1]
        $month = $matches[2]
        $year = $matches[3]
        return "$year-$month-$day"
    }
    
    Write-Warning "Formato de fecha no reconocido: $DateStr"
    return $DateStr
}

Write-Host "Generador de SQL para importacion de cuotas" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

# Verificar que existe el archivo CSV
if (-not (Test-Path $CsvPath)) {
    Write-Host "ERROR: No se encuentra el archivo CSV: $CsvPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Creando archivo CSV de ejemplo..." -ForegroundColor Yellow
    
    $exampleCsv = @"
"APELLIDO PATERNO","APELLIDO MATERNO","NOMBRES","RUN","VERIFICADOR","CURSO","CUOTA"," MONTO ","FECHA","ESTADO"
"CATALÁN","VÁSQUEZ","INARA SAYEN","25372029","","3° básico A","1"," `$99.324 ","05-03-2025","PAGADO"
"CATALÁN","VÁSQUEZ","INARA SAYEN","25372029","","3° básico A","2"," `$99.324 ","05-04-2025","PAGADO"
"@
    
    $exampleCsv | Out-File -FilePath "cuotas_ejemplo.csv" -Encoding UTF8
    Write-Host "Archivo de ejemplo creado: cuotas_ejemplo.csv" -ForegroundColor Green
    Write-Host ""
    Write-Host "Edita este archivo con tus datos y vuelve a ejecutar:" -ForegroundColor Cyan
    Write-Host ".\generate_fee_import_sql.ps1 -CsvPath 'cuotas_ejemplo.csv' -OwnerUuid 'tu-uuid'" -ForegroundColor Cyan
    exit 1
}

Write-Host "Leyendo CSV: $CsvPath" -ForegroundColor Cyan

# Leer CSV (con encoding UTF8 para caracteres especiales)
try {
    $data = Import-Csv -Path $CsvPath -Encoding UTF8
} catch {
    Write-Host "ERROR al leer CSV: $_" -ForegroundColor Red
    exit 1
}

Write-Host "CSV cargado: $($data.Count) registros" -ForegroundColor Green
Write-Host ""

# Generar SQL
$sqlHeader = @"
-- ============================================================================
-- SCRIPT DE IMPORTACIÓN DE CUOTAS - GENERADO AUTOMÁTICAMENTE
-- ============================================================================
-- Generado: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Registros a importar: $($data.Count)
-- ============================================================================

DO `$`$
DECLARE
  v_owner_id uuid := '$OwnerUuid'::uuid;
  v_result RECORD;
  v_inserted_count integer := 0;
  v_updated_count integer := 0;
  v_error_count integer := 0;
BEGIN
  RAISE NOTICE 'Iniciando importacion de $($data.Count) cuotas...';
  RAISE NOTICE 'Fecha: %', now();
  RAISE NOTICE '';
  
  -- Validar que se cambio el owner_id
  IF v_owner_id = 'TU_USER_ID_AQUI'::uuid OR v_owner_id IS NULL THEN
    RAISE EXCEPTION 'ERROR: Debes cambiar TU_USER_ID_AQUI por tu UUID de usuario real';
  END IF;
  
"@

$sqlFooter = @"
  
  -- ============================================================================
  -- RESUMEN DE IMPORTACIÓN
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'IMPORTACION COMPLETADA';
  RAISE NOTICE '================================';
  RAISE NOTICE 'Cuotas insertadas: %', v_inserted_count;
  RAISE NOTICE 'Cuotas actualizadas: %', v_updated_count;
  RAISE NOTICE 'Errores: %', v_error_count;
  RAISE NOTICE 'Total procesado: %', v_inserted_count + v_updated_count + v_error_count;
END`$`$;
"@

# Generar líneas de importación
$sqlLines = @()
$lineNumber = 0

foreach ($row in $data) {
    $lineNumber++
    
    # Extraer campos (ajustar nombres según tu CSV)
    $run = $row.RUN
    $curso = $row.CURSO
    $cuota = $row.CUOTA
    $monto = Parse-Amount $row.' MONTO '
    $fecha = Format-Date $row.FECHA
    $estado = $row.ESTADO
    
    # Validar datos minimos
    if ([string]::IsNullOrWhiteSpace($run)) {
        Write-Warning "Linea ${lineNumber}: RUN vacio, omitiendo..."
        continue
    }
    
    # Generar SQL para esta cuota
    $nombres = $row.NOMBRES
    $apellido = $row.'APELLIDO PATERNO'
    $sqlLine = @"
  -- Linea ${lineNumber}: $nombres $apellido - Cuota $cuota
  FOR v_result IN SELECT * FROM import_fee('$run', '$curso', $cuota, $monto, '$fecha'::date, '$estado', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea ${lineNumber}: %', v_result.message;
    END IF;
  END LOOP;

"@
    
    $sqlLines += $sqlLine
}

# Combinar todo
$fullSql = $sqlHeader + ($sqlLines -join "") + $sqlFooter

# Guardar a archivo
$fullSql | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "Archivo SQL generado: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Estadisticas:" -ForegroundColor Cyan
Write-Host "   - Registros CSV: $($data.Count)" -ForegroundColor White
Write-Host "   - Lineas SQL generadas: $($sqlLines.Count)" -ForegroundColor White
Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Yellow
Write-Host "   1. Abre Supabase SQL Editor" -ForegroundColor White
Write-Host "   2. Primero ejecuta: IMPORT_FEES_FROM_CSV.sql (funciones base)" -ForegroundColor White
Write-Host "   3. Luego ejecuta: $OutputFile (datos generados)" -ForegroundColor White
Write-Host "   4. Si OwnerUuid='TU_USER_ID_AQUI', cambialo en el archivo generado" -ForegroundColor White
Write-Host ""

# Mostrar preview
Write-Host "Preview del SQL generado:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor DarkGray
$fullSql.Substring(0, [Math]::Min(1000, $fullSql.Length)) + "`n..." | Write-Host -ForegroundColor DarkGray
Write-Host "================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Listo!" -ForegroundColor Green
