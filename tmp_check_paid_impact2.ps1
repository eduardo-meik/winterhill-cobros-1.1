$ErrorActionPreference = 'Stop'

$target = Import-Csv .\tmp_fee_2026_ajustes_no_prioritario.csv
$targetRuts=@{}
foreach($t in $target){ if($t.rut){ $targetRuts[$t.rut]=$true } }

$envMap=@{}
Get-Content .\.env | ForEach-Object {
  if ($_ -match '^[^#][^=]*=') {
    $parts=$_ -split '=',2
    $envMap[$parts[0].Trim()]=$parts[1].Trim().Trim('"')
  }
}
$baseUrl=$envMap['VITE_SUPABASE_URL']
$serviceKey=$envMap['SUPABASE_SERVICE_ROLE_KEY']
$headers=@{apikey=$serviceKey; Authorization="Bearer $serviceKey"}

function Normalize-Rut([string]$rut){
  if([string]::IsNullOrWhiteSpace($rut)){return $null}
  return (($rut -replace '[^0-9Kk]','').ToUpper())
}

$fees=@(); $offset=0; $limit=1000

do {
  $url = "$baseUrl/rest/v1/fee?select=id,status,payment_method,numero_cuota,year_academico,students!inner(run,whole_name)&year_academico=eq.2026&limit=$limit&offset=$offset"
  $page = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
  if($page){ $fees += $page }
  $count = @($page).Count
  $offset += $limit
} while($count -eq $limit)

$affected = foreach($f in $fees){
  $rut = Normalize-Rut $f.students.run
  if(-not $rut -or -not $targetRuts.ContainsKey($rut)){ continue }
  $status = ([string]$f.status).Trim()
  if($status -match '^(?i)paid|pagad'){
    [pscustomobject]@{
      rut=$rut
      nombre_fee=$f.students.whole_name
      fee_id=$f.id
      status=$f.status
      payment_method=$f.payment_method
      numero_cuota=$f.numero_cuota
    }
  }
}

$byStudent = $affected | Group-Object rut | ForEach-Object {
  $g=$_.Group
  $first=$g|Select-Object -First 1
  [pscustomobject]@{
    rut=$_.Name
    nombre_fee=$first.nombre_fee
    cuotas_paid=$g.Count
    cuotas_numeros=($g|ForEach-Object{[string]$_.numero_cuota}|Sort-Object -Unique) -join ','
    metodos=($g|ForEach-Object{[string]$_.payment_method}|Where-Object{$_ -and $_.Trim() -ne ''}|Sort-Object -Unique) -join '|'
  }
} | Sort-Object rut

$out = '.\tmp_fee_2026_ajustes_no_prioritario_con_paid.csv'
$byStudent | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8

[pscustomobject]@{
  alumnos_objetivo_ajuste = $target.Count
  alumnos_con_al_menos_una_cuota_paid = @($byStudent).Count
  total_registros_paid_en_esos_alumnos = @($affected).Count
  archivo_detalle = $out
} | ConvertTo-Json -Depth 4
