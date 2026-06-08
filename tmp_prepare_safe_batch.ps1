$ErrorActionPreference='Stop'

$ajustes = Import-Csv .\tmp_fee_2026_ajustes_no_prioritario.csv
$paid = Import-Csv .\tmp_fee_2026_ajustes_no_prioritario_con_paid.csv
$paidSet = @{}
foreach($p in $paid){ if($p.rut){ $paidSet[$p.rut]=$p } }

$ejecutables = @($ajustes | Where-Object { -not $paidSet.ContainsKey($_.rut) })
$bloqueados = @($ajustes | Where-Object { $paidSet.ContainsKey($_.rut) })

$ejPath = '.\tmp_fee_2026_ajustes_ejecutables_sin_paid.csv'
$blPath = '.\tmp_fee_2026_ajustes_bloqueados_por_paid.csv'
$ejecutables | Export-Csv -Path $ejPath -NoTypeInformation -Encoding UTF8
$bloqueados | Export-Csv -Path $blPath -NoTypeInformation -Encoding UTF8

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

$sqlPath = '.\tmp_apply_fee_2026_payment_method_safe.sql'
$lines = New-Object System.Collections.Generic.List[string]
[void]$lines.Add('-- SAFE UPDATE: excluye alumnos con cuotas paid y no toca status=paid')
[void]$lines.Add('with src as (')
[void]$lines.Add('  select * from (values')

$vals = @()
foreach($r in $ejecutables){
  $dbm = Map-DbMethod $r.sige_pago
  if(-not $dbm){ continue }
  $rut = $r.rut.Replace("'","''")
  $vals += "    ('$rut', '$dbm')"
}

for($i=0; $i -lt $vals.Count; $i++){
  $suffix = if($i -lt $vals.Count-1){','} else {''}
  [void]$lines.Add($vals[$i] + $suffix)
}

[void]$lines.Add('  ) as t(rut_norm, new_payment_method)')
[void]$lines.Add('), st as (')
[void]$lines.Add('  select id, upper(regexp_replace(run, ''[^0-9Kk]'', '''', ''g'')) as rut_norm from students')
[void]$lines.Add(')')
[void]$lines.Add('update fee f')
[void]$lines.Add('set payment_method = src.new_payment_method')
[void]$lines.Add('from src')
[void]$lines.Add('join st on st.rut_norm = src.rut_norm')
[void]$lines.Add('where f.student_id = st.id')
[void]$lines.Add('  and f.year_academico = 2026')
[void]$lines.Add('  and coalesce(lower(f.status),'''') <> ''paid''')
[void]$lines.Add('  and coalesce(f.payment_method, '''''') <> src.new_payment_method;')

Set-Content -Path $sqlPath -Value $lines -Encoding UTF8

[pscustomobject]@{
  ajustes_originales = $ajustes.Count
  ajustes_ejecutables_sin_paid = $ejecutables.Count
  ajustes_bloqueados_por_paid = $bloqueados.Count
  archivo_ejecutables = $ejPath
  archivo_bloqueados = $blPath
  sql_seguro_generado = $sqlPath
} | ConvertTo-Json -Depth 4
