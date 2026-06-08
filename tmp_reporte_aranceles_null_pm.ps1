$ErrorActionPreference = 'Stop'

$envMap = @{}
Get-Content .env | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $parts = $_ -split '=', 2
  if ($parts.Length -eq 2) { $envMap[$parts[0].Trim()] = $parts[1].Trim().Trim('"') }
}

$baseUrl = $envMap['VITE_SUPABASE_URL']
$serviceKey = $envMap['SUPABASE_SERVICE_ROLE_KEY']
if (-not $baseUrl -or -not $serviceKey) { throw 'Faltan VITE_SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en .env' }

$headers = @{ apikey = $serviceKey; Authorization = "Bearer $serviceKey"; Accept = 'application/json' }

function Get-AllRows {
  param([string]$Endpoint, [string]$Select='*', [string]$Filter='')
  $all = @(); $limit = 1000; $offset = 0
  while ($true) {
    $uri = "$baseUrl/rest/v1/${Endpoint}?select=$([uri]::EscapeDataString($Select))&limit=$limit&offset=$offset"
    if ($Filter) { $uri = "$uri&$Filter" }
    $rows = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    if ($null -eq $rows) { break }
    if ($rows -isnot [System.Array]) { $rows = @($rows) }
    $all += $rows
    if ($rows.Count -lt $limit) { break }
    $offset += $limit
  }
  return $all
}

function Normalize-Rut([string]$rut) {
  if ([string]::IsNullOrWhiteSpace($rut)) { return $null }
  return (($rut -replace '[^0-9Kk]','').ToUpper())
}

function Normalize-Text([object]$value) {
  if ($null -eq $value) { return '' }
  return ([string]$value).Trim().ToUpper()
}

function Parse-Int([object]$value) {
  if ($null -eq $value) { return $null }
  $txt = ([string]$value).Trim()
  if (-not $txt) { return $null }
  $txt = $txt -replace '[^0-9-]',''
  if (-not $txt) { return $null }
  $n = 0
  if ([int]::TryParse($txt, [ref]$n)) { return $n }
  return $null
}

# SIGE
$headersCsv = 'CURSO','ORDEN','RUT','NOMBRE','COL5','COL6','COL7','PAGO','CUOTA_MONTO','CUOTAS','INGRESO_ANUAL','OBS'
$sigeRows = Import-Csv -Path .\sige_2026.csv -Header $headersCsv | Select-Object -Skip 1
$sigeByRut = @{}
foreach ($row in $sigeRows) {
  $rut = Normalize-Rut $row.RUT
  if (-not $rut) { continue }
  if (-not $sigeByRut.ContainsKey($rut)) {
    $sigeByRut[$rut] = [pscustomobject]@{
      rut = $rut
      rut_original = $row.RUT
      nombre_sige = $row.NOMBRE
      pago = Normalize-Text $row.PAGO
      cuotas = Parse-Int $row.CUOTAS
      cuota_monto = $row.CUOTA_MONTO
      ingreso_anual = $row.INGRESO_ANUAL
      curso = $row.CURSO
    }
  }
}

# Fee 2026 con join students
$feeRows = Get-AllRows -Endpoint 'fee' -Select 'id,student_id,payment_method,numero_cuota,year_academico,students!inner(run,whole_name)' -Filter 'year_academico=eq.2026'

$byRut = @{}
foreach ($f in $feeRows) {
  $rut = Normalize-Rut $f.students.run
  if (-not $rut) { continue }

  if (-not $byRut.ContainsKey($rut)) {
    $byRut[$rut] = [ordered]@{
      rut = $rut
      nombre_fee = $f.students.whole_name
      fee_registros = 0
      fee_registros_payment_null = 0
      fee_max_numero_cuota = 0
      fee_metodos_no_nulos = New-Object System.Collections.Generic.HashSet[string]
    }
  }

  $acc = $byRut[$rut]
  $acc.fee_registros++

  if ($null -eq $f.payment_method -or [string]::IsNullOrWhiteSpace([string]$f.payment_method)) {
    $acc.fee_registros_payment_null++
  } else {
    [void]$acc.fee_metodos_no_nulos.Add((Normalize-Text $f.payment_method))
  }

  $nc = Parse-Int $f.numero_cuota
  if ($nc -and $nc -gt $acc.fee_max_numero_cuota) { $acc.fee_max_numero_cuota = $nc }
}

$nullPm = @()
foreach ($kv in $byRut.GetEnumerator()) {
  $acc = $kv.Value
  if ($acc.fee_registros_payment_null -le 0) { continue }

  $sige = $null
  if ($sigeByRut.ContainsKey($acc.rut)) { $sige = $sigeByRut[$acc.rut] }

  $cuotasActuales = if ($acc.fee_max_numero_cuota -gt 0) { $acc.fee_max_numero_cuota } else { $acc.fee_registros }
  $sigePago = if ($sige) { $sige.pago } else { '' }
  $sigeCuotas = if ($sige) { $sige.cuotas } else { $null }
  $requiereAjuste = $false
  if ($sige -and $sigePago -and $sigePago -ne 'PRIORITARIO') { $requiereAjuste = $true }

  $cuotasDifieren = $null
  if ($sigeCuotas) { $cuotasDifieren = ($cuotasActuales -ne $sigeCuotas) }

  $nullPm += [pscustomobject]@{
    rut = $acc.rut
    nombre_fee = $acc.nombre_fee
    fee_registros = $acc.fee_registros
    fee_registros_payment_null = $acc.fee_registros_payment_null
    fee_cuotas_actuales_aprox = $cuotasActuales
    fee_metodos_no_nulos = (@($acc.fee_metodos_no_nulos) -join '|')
    sige_encontrado = [bool]$sige
    sige_nombre = if ($sige) { $sige.nombre_sige } else { '' }
    sige_pago = $sigePago
    sige_cuotas = $sigeCuotas
    requiere_ajuste_no_prioritario = $requiereAjuste
    cuotas_difieren = $cuotasDifieren
  }
}

$nullPm = $nullPm | Sort-Object rut
$ajustes = $nullPm | Where-Object { $_.requiere_ajuste_no_prioritario -eq $true }

$allPath = '.\tmp_fee_2026_payment_method_null_vs_sige.csv'
$adjPath = '.\tmp_fee_2026_ajustes_no_prioritario.csv'
$nullPm | Export-Csv -Path $allPath -NoTypeInformation -Encoding UTF8
$ajustes | Export-Csv -Path $adjPath -NoTypeInformation -Encoding UTF8

$resumen = [pscustomobject]@{
  total_alumnos_con_fee_2026 = $byRut.Count
  alumnos_con_payment_method_null = @($nullPm).Count
  alumnos_no_prioritario_a_ajustar = @($ajustes).Count
  archivo_todos = $allPath
  archivo_ajustes = $adjPath
}
$resumen | ConvertTo-Json -Depth 5
