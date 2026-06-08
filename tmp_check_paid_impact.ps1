$ErrorActionPreference = 'Stop'

$envMap=@{}
Get-Content .\.env | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $parts = $_ -split '=',2
  if ($parts.Length -eq 2) { $envMap[$parts[0].Trim()] = $parts[1].Trim().Trim('"') }
}
$baseUrl = $envMap['VITE_SUPABASE_URL']
$serviceKey = $envMap['SUPABASE_SERVICE_ROLE_KEY']
if (-not $baseUrl -or -not $serviceKey) { throw 'Faltan variables en .env' }
$headers = @{ apikey = $serviceKey; Authorization = "Bearer $serviceKey"; Accept='application/json' }

function Get-AllRows {
  param([string]$endpoint, [string]$select='*', [string]$filter='')
  $all=@(); $limit=1000; $offset=0
  while ($true) {
    $uri = "$baseUrl/rest/v1/$endpoint?select=$([uri]::EscapeDataString($select))&limit=$limit&offset=$offset"
    if ($filter) { $uri = "$uri&$filter" }
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

$target = Import-Csv .\tmp_fee_2026_ajustes_no_prioritario.csv
$targetRuts = @{}
foreach ($r in $target) { if ($r.rut) { $targetRuts[$r.rut] = $true } }

$feeRows = Get-AllRows -endpoint 'fee' -select 'id,status,payment_method,numero_cuota,year_academico,students:student_id(run,whole_name)' -filter 'year_academico=eq.2026'

$affected = @()
foreach ($f in $feeRows) {
  $rut = Normalize-Rut $f.students.run
  if (-not $rut -or -not $targetRuts.ContainsKey($rut)) { continue }
  $status = ([string]$f.status).Trim()
  if ($status -match '^(?i)paid|pagad') {
    $affected += [pscustomobject]@{
      rut = $rut
      nombre_fee = $f.students.whole_name
      fee_id = $f.id
      status = $f.status
      payment_method = $f.payment_method
      numero_cuota = $f.numero_cuota
    }
  }
}

$byStudent = $affected | Group-Object rut | ForEach-Object {
  $first = $_.Group | Select-Object -First 1
  [pscustomobject]@{
    rut = $_.Name
    nombre_fee = $first.nombre_fee
    cuotas_pagadas_count = $_.Count
    estados = (($_.Group | ForEach-Object { [string]$_.status } | Sort-Object -Unique) -join '|')
    metodos = (($_.Group | ForEach-Object { [string]$_.payment_method } | Where-Object { $_ -and $_.Trim() -ne '' } | Sort-Object -Unique) -join '|')
    cuotas_pagadas = (($_.Group | ForEach-Object { [string]$_.numero_cuota } | Sort-Object -Unique) -join ',')
  }
} | Sort-Object rut

$out = '.\tmp_fee_2026_ajustes_no_prioritario_con_paid.csv'
$byStudent | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8

$allStatuses = $feeRows | ForEach-Object { [string]$_.status } | Group-Object | Sort-Object Count -Descending | ForEach-Object { [pscustomobject]@{status=$_.Name; count=$_.Count} }

[pscustomobject]@{
  alumnos_objetivo = $target.Count
  alumnos_con_cuotas_paid = @($byStudent).Count
  registros_paid_en_objetivo = @($affected).Count
  archivo_detalle = $out
  top_estados_fee_2026 = ($allStatuses | Select-Object -First 8)
} | ConvertTo-Json -Depth 6

