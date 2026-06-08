$ErrorActionPreference = 'Stop'

$targets = Import-Csv .\tmp_fee_2026_ajustes_ejecutables_sin_paid.csv

$envMap=@{}
Get-Content .\.env | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $parts = $_ -split '=',2
  if ($parts.Length -eq 2) { $envMap[$parts[0].Trim()] = $parts[1].Trim().Trim('"') }
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

function Get-AllRows {
  param([string]$endpoint, [string]$select='*', [string]$filter='')
  $all=@(); $limit=1000; $offset=0
  do {
    $uri = "$baseUrl/rest/v1/$endpoint?select=$([uri]::EscapeDataString($select))&limit=$limit&offset=$offset"
    if ($filter) { $uri = "$uri&$filter" }
    $page = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    if ($page) { $all += $page }
    $count = @($page).Count
    $offset += $limit
  } while ($count -eq $limit)
  return $all
}

# students map
$students = Get-AllRows -endpoint 'students' -select 'id,run'
$studentIdByRut = @{}
foreach($s in $students){
  $r = Normalize-Rut $s.run
  if($r){ $studentIdByRut[$r] = $s.id }
}

# target map student_id -> desired method
$desiredByStudentId = @{}
$unresolved = @()
foreach($t in $targets){
  $rut = Normalize-Rut $t.rut
  $method = Map-DbMethod $t.sige_pago
  if(-not $rut -or -not $method){ continue }
  if(-not $studentIdByRut.ContainsKey($rut)) {
    $unresolved += [pscustomobject]@{rut=$rut; sige_pago=$t.sige_pago}
    continue
  }
  $sid = [string]$studentIdByRut[$rut]
  $desiredByStudentId[$sid] = $method
}

# fee 2026
$fees = Get-AllRows -endpoint 'fee' -select 'id,student_id,status,payment_method,year_academico,numero_cuota' -filter 'year_academico=eq.2026'

$candidates = @()
foreach($f in $fees){
  $sid = [string]$f.student_id
  if(-not $desiredByStudentId.ContainsKey($sid)){ continue }
  $status = ([string]$f.status).Trim().ToLower()
  if($status -eq 'paid'){ continue }
  $desired = [string]$desiredByStudentId[$sid]
  $current = [string]$f.payment_method
  if([string]::IsNullOrWhiteSpace($current) -or $current.Trim().ToUpper() -ne $desired.ToUpper()){
    $candidates += [pscustomobject]@{
      fee_id = $f.id
      student_id = $sid
      status = $f.status
      numero_cuota = $f.numero_cuota
      payment_method_old = $f.payment_method
      payment_method_new = $desired
    }
  }
}

$prePath = '.\tmp_fee_2026_payment_method_pre_candidates.csv'
$candidates | Export-Csv -Path $prePath -NoTypeInformation -Encoding UTF8

# apply updates
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

# post validation
$feesPost = Get-AllRows -endpoint 'fee' -select 'id,student_id,status,payment_method,year_academico,numero_cuota' -filter 'year_academico=eq.2026'
$remaining = @()
foreach($f in $feesPost){
  $sid = [string]$f.student_id
  if(-not $desiredByStudentId.ContainsKey($sid)){ continue }
  $status = ([string]$f.status).Trim().ToLower()
  if($status -eq 'paid'){ continue }
  $desired = [string]$desiredByStudentId[$sid]
  $current = [string]$f.payment_method
  if([string]::IsNullOrWhiteSpace($current) -or $current.Trim().ToUpper() -ne $desired.ToUpper()){
    $remaining += [pscustomobject]@{
      fee_id = $f.id
      student_id = $sid
      status = $f.status
      numero_cuota = $f.numero_cuota
      payment_method_current = $f.payment_method
      payment_method_expected = $desired
    }
  }
}
$remPath = '.\tmp_fee_2026_payment_method_remaining_mismatches.csv'
$remaining | Export-Csv -Path $remPath -NoTypeInformation -Encoding UTF8

$summary = [pscustomobject]@{
  alumnos_objetivo_lote_seguro = $targets.Count
  alumnos_no_resueltos_por_run = @($unresolved).Count
  cuotas_candidatas_pre_update = @($candidates).Count
  cuotas_actualizadas = @($updated).Count
  cuotas_restantes_desalineadas = @($remaining).Count
  archivo_pre = $prePath
  archivo_updated = $postPath
  archivo_remaining = $remPath
}
$summary | ConvertTo-Json -Depth 6
