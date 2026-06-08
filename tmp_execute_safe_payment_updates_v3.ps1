$ErrorActionPreference = 'Stop'

$targets = Import-Csv .\tmp_fee_2026_ajustes_ejecutables_sin_paid.csv

$envMap=@{}
Get-Content .\.env | ForEach-Object {
  if ($_ -match '^[^#][^=]*=') {
    $parts=$_ -split '=',2
    $envMap[$parts[0].Trim()]=$parts[1]
  }
}
$baseUrl=$envMap['VITE_SUPABASE_URL']
$serviceKey=$envMap['SUPABASE_SERVICE_ROLE_KEY']
$headers=@{apikey=$serviceKey; Authorization="Bearer $serviceKey"; Accept='application/json'}
if(-not $baseUrl -or -not $serviceKey){ throw 'Faltan variables .env' }

function Normalize-Rut([string]$rut){
  if([string]::IsNullOrWhiteSpace($rut)){ return $null }
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

# target rut -> desired method
$desiredByRut = @{}
foreach($t in $targets){
  $rut = Normalize-Rut $t.rut
  $m = Map-DbMethod $t.sige_pago
  if($rut -and $m){ $desiredByRut[$rut] = $m }
}

# fetch fee 2026 + run
$fees=@(); $offset=0; $limit=1000

do {
  $url = "$baseUrl/rest/v1/fee?select=id,student_id,status,payment_method,numero_cuota,year_academico,students!inner(run,whole_name)&year_academico=eq.2026&limit=$limit&offset=$offset"
  $page = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
  if($page){ $fees += $page }
  $count = @($page).Count
  $offset += $limit
} while($count -eq $limit)

# map student_id -> desired method via run from joined rows
$desiredByStudentId = @{}
foreach($f in $fees){
  $rut = Normalize-Rut $f.students.run
  if(-not $rut -or -not $desiredByRut.ContainsKey($rut)){ continue }
  $sid = [string]$f.student_id
  $desiredByStudentId[$sid] = [string]$desiredByRut[$rut]
}

$preCandidates = foreach($f in $fees){
  $sid = [string]$f.student_id
  if(-not $desiredByStudentId.ContainsKey($sid)){ continue }
  $status = ([string]$f.status).Trim().ToLower()
  if($status -eq 'paid'){ continue }
  $desired = [string]$desiredByStudentId[$sid]
  $current = [string]$f.payment_method
  if([string]::IsNullOrWhiteSpace($current) -or $current.Trim().ToUpper() -ne $desired.ToUpper()){
    [pscustomobject]@{
      fee_id=$f.id; student_id=$sid; rut=(Normalize-Rut $f.students.run); nombre_fee=$f.students.whole_name; numero_cuota=$f.numero_cuota; status=$f.status; payment_method_old=$f.payment_method; payment_method_new=$desired
    }
  }
}

$prePath = '.\tmp_fee_2026_payment_method_pre_candidates.csv'
$preCandidates | Export-Csv -Path $prePath -NoTypeInformation -Encoding UTF8

# apply once per student (all non-paid 2026)
$updatedStudents = @()
foreach($sid in $desiredByStudentId.Keys){
  $desired = $desiredByStudentId[$sid]
  $uri = "$baseUrl/rest/v1/fee?student_id=eq.$sid&year_academico=eq.2026&status=neq.paid"
  $body = @{ payment_method = $desired } | ConvertTo-Json -Compress
  Invoke-RestMethod -Uri $uri -Headers $headers -Method Patch -ContentType 'application/json' -Body $body | Out-Null
  $updatedStudents += [pscustomobject]@{ student_id=$sid; payment_method_new=$desired }
}

$updStudentsPath = '.\tmp_fee_2026_payment_method_updated_students.csv'
$updatedStudents | Export-Csv -Path $updStudentsPath -NoTypeInformation -Encoding UTF8

# post validate
$feesPost=@(); $offset=0

do {
  $url = "$baseUrl/rest/v1/fee?select=id,student_id,status,payment_method,numero_cuota,year_academico,students!inner(run,whole_name)&year_academico=eq.2026&limit=$limit&offset=$offset"
  $page = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
  if($page){ $feesPost += $page }
  $count = @($page).Count
  $offset += $limit
} while($count -eq $limit)

$remaining = foreach($f in $feesPost){
  $sid = [string]$f.student_id
  if(-not $desiredByStudentId.ContainsKey($sid)){ continue }
  $status = ([string]$f.status).Trim().ToLower()
  if($status -eq 'paid'){ continue }
  $desired = [string]$desiredByStudentId[$sid]
  $current = [string]$f.payment_method
  if([string]::IsNullOrWhiteSpace($current) -or $current.Trim().ToUpper() -ne $desired.ToUpper()){
    [pscustomobject]@{
      fee_id=$f.id; student_id=$sid; rut=(Normalize-Rut $f.students.run); nombre_fee=$f.students.whole_name; numero_cuota=$f.numero_cuota; status=$f.status; payment_method_current=$f.payment_method; payment_method_expected=$desired
    }
  }
}
$remPath = '.\tmp_fee_2026_payment_method_remaining_mismatches.csv'
$remaining | Export-Csv -Path $remPath -NoTypeInformation -Encoding UTF8

[pscustomobject]@{
  alumnos_objetivo_lote_seguro = $targets.Count
  alumnos_a_actualizar_detectados = $desiredByStudentId.Count
  cuotas_candidatas_pre_update = @($preCandidates).Count
  estudiantes_actualizados = @($updatedStudents).Count
  cuotas_restantes_desalineadas = @($remaining).Count
  archivo_pre = $prePath
  archivo_updated_students = $updStudentsPath
  archivo_remaining = $remPath
} | ConvertTo-Json -Depth 5
