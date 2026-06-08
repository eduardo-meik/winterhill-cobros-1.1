$ErrorActionPreference = 'Stop'

$targets = Import-Csv .\tmp_fee_2026_ajustes_ejecutables_sin_paid.csv

$envMap=@{}
Get-Content .\.env | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $parts = $_ -split '=',2
  if ($parts.Length -eq 2) { $envMap[$parts[0].Trim()] = $parts[1] }
}
$baseUrl = $envMap['VITE_SUPABASE_URL']
$serviceKey = $envMap['SUPABASE_SERVICE_ROLE_KEY']
if (-not $baseUrl -or -not $serviceKey) { throw 'Faltan variables .env' }

$headers = @{ apikey = $serviceKey; Authorization = "Bearer $serviceKey"; Accept='application/json' }

function Normalize-Rut([string]$rut) {
  if ([string]::IsNullOrWhiteSpace($rut)) { return $null }
  return (($rut -replace '[^0-9Kk]','').ToUpper())
}

function Map-DbMethod([string]$m){
  $x = (($m+'').Trim().ToUpper())
  switch($x){
    'PAGARE' { 'PAGARE' }
    'PREFERENTE' { 'PAGARE' }
    'CHEQUE' { 'CHEQUE' }
    'CHEQUES' { 'CHEQUE' }
    'TARJETA' { 'TARJETA' }
    'TC' { 'TARJETA' }
    'TRANSFERENCIA' { 'TRANSFERENCIA' }
    'TRANFERENCIA' { 'TRANSFERENCIA' }
    'BECA' { 'TRANSFERENCIA' }
    'DESCUENTO' { 'DESCUENTO PLANILLA' }
    'DESCUENTO PLANILLA' { 'DESCUENTO PLANILLA' }
    default { $null }
  }
}

# Desired method by rut
$desiredByRut = @{}
foreach($t in $targets){
  $rut = Normalize-Rut $t.rut
  $m = Map-DbMethod $t.sige_pago
  if($rut -and $m){ $desiredByRut[$rut] = $m }
}

# Fetch fee 2026 with student run
$fees=@(); $offset=0; $limit=1000

do {
  $url = "$baseUrl/rest/v1/fee?select=id,student_id,status,payment_method,numero_cuota,year_academico,students!inner(run,whole_name)&year_academico=eq.2026&limit=$limit&offset=$offset"
  $page = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
  if($page){ $fees += $page }
  $count = @($page).Count
  $offset += $limit
} while($count -eq $limit)

$candidates = @()
foreach($f in $fees){
  $rut = Normalize-Rut $f.students.run
  if(-not $rut -or -not $desiredByRut.ContainsKey($rut)){ continue }

  $status = ([string]$f.status).Trim().ToLower()
  if($status -eq 'paid'){ continue }

  $desired = [string]$desiredByRut[$rut]
  $current = [string]$f.payment_method

  if([string]::IsNullOrWhiteSpace($current) -or $current.Trim().ToUpper() -ne $desired.ToUpper()){
    $candidates += [pscustomobject]@{
      rut = $rut
      nombre_fee = $f.students.whole_name
      fee_id = $f.id
      student_id = $f.student_id
      status = $f.status
      numero_cuota = $f.numero_cuota
      payment_method_old = $f.payment_method
      payment_method_new = $desired
    }
  }
}

$prePath = '.\tmp_fee_2026_payment_method_pre_candidates.csv'
$candidates | Export-Csv -Path $prePath -NoTypeInformation -Encoding UTF8

# Apply updates row by row (safe: only candidate non-paid rows)
$updated = @()
foreach($c in $candidates){
  $id = [string]$c.fee_id
  $uri = "$baseUrl/rest/v1/fee?id=eq.$id"
  $body = @{ payment_method = $c.payment_method_new } | ConvertTo-Json -Compress
  Invoke-RestMethod -Uri $uri -Headers $headers -Method Patch -ContentType 'application/json' -Body $body | Out-Null
  $updated += $c
}

$postPath = '.\tmp_fee_2026_payment_method_updated_rows.csv'
$updated | Export-Csv -Path $postPath -NoTypeInformation -Encoding UTF8

# Post validation
$feesPost=@(); $offset=0

do {
  $url = "$baseUrl/rest/v1/fee?select=id,status,payment_method,numero_cuota,year_academico,students!inner(run,whole_name)&year_academico=eq.2026&limit=$limit&offset=$offset"
  $page = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
  if($page){ $feesPost += $page }
  $count = @($page).Count
  $offset += $limit
} while($count -eq $limit)

$remaining = @()
foreach($f in $feesPost){
  $rut = Normalize-Rut $f.students.run
  if(-not $rut -or -not $desiredByRut.ContainsKey($rut)){ continue }

  $status = ([string]$f.status).Trim().ToLower()
  if($status -eq 'paid'){ continue }

  $desired = [string]$desiredByRut[$rut]
  $current = [string]$f.payment_method

  if([string]::IsNullOrWhiteSpace($current) -or $current.Trim().ToUpper() -ne $desired.ToUpper()){
    $remaining += [pscustomobject]@{
      rut = $rut
      fee_id = $f.id
      status = $f.status
      numero_cuota = $f.numero_cuota
      payment_method_current = $f.payment_method
      payment_method_expected = $desired
    }
  }
}

$remPath = '.\tmp_fee_2026_payment_method_remaining_mismatches.csv'
$remaining | Export-Csv -Path $remPath -NoTypeInformation -Encoding UTF8

[pscustomobject]@{
  alumnos_objetivo_lote_seguro = $targets.Count
  cuotas_candidatas_pre_update = @($candidates).Count
  cuotas_actualizadas = @($updated).Count
  cuotas_restantes_desalineadas = @($remaining).Count
  archivo_pre = $prePath
  archivo_updated = $postPath
  archivo_remaining = $remPath
} | ConvertTo-Json -Depth 5
