$ErrorActionPreference = 'Stop'

$envMap = @{}
Get-Content .env | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $parts = $_ -split '=', 2
  if ($parts.Length -eq 2) {
    $envMap[$parts[0].Trim()] = $parts[1].Trim().Trim('"')
  }
}

$baseUrl = $envMap['VITE_SUPABASE_URL']
$serviceKey = $envMap['SUPABASE_SERVICE_ROLE_KEY']
if (-not $baseUrl -or -not $serviceKey) {
  throw 'Faltan VITE_SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en .env'
}

$headers = @{
  apikey = $serviceKey
  Authorization = "Bearer $serviceKey"
  Accept = 'application/json'
}

function Get-AllRows {
  param([string]$Endpoint, [string]$Select='*')

  $all = @()
  $limit = 1000
  $offset = 0

  while ($true) {
    $uri = "$baseUrl/rest/v1/${Endpoint}?select=$([uri]::EscapeDataString($Select))&limit=$limit&offset=$offset"
    $rows = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    if ($null -eq $rows) { break }
    if ($rows -isnot [System.Array]) { $rows = @($rows) }
    $all += $rows
    if ($rows.Count -lt $limit) { break }
    $offset += $limit
  }

  return $all
}

function Normalize-Text([object]$Value) {
  if ($null -eq $Value) { return '' }
  $text = [string]$Value
  $norm = $text.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $norm.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$sb.Append($ch)
    }
  }
  return (($sb.ToString().ToUpperInvariant() -replace '\s+', ' ').Trim())
}

function Normalize-Run([object]$Num, [object]$Dv) {
  $base = ([string]$Num) -replace '[^0-9]', ''
  $base = $base.TrimStart('0')
  $dvText = Normalize-Text $Dv
  if ($base -and $dvText) { return "$base-$dvText" }
  return $base
}

function Parse-Money([object]$Value) {
  if ($null -eq $Value) { return $null }
  $text = ([string]$Value).Trim()
  if (-not $text) { return $null }
  $text = $text.Replace('$','').Replace(' ','').Replace('.','').Replace(',','')
  if (-not $text -or $text -eq '-') { return $null }
  if ($text -notmatch '^-?\d+(\.\d+)?$') { return $null }
  return [int][math]::Round([double]$text)
}

function Normalize-Method([object]$Value) {
  $text = Normalize-Text $Value
  switch ($text) {
    'PAGARE' { 'PAGARE' }
    'PREFERENTE' { 'PAGARE' }
    'CHEQUE' { 'CHEQUES' }
    'CHEQUES' { 'CHEQUES' }
    'TC' { 'TC' }
    'TARJETA' { 'TC' }
    'TRANSFERENCIA' { 'TRANSFERENCIA' }
    'TRANFERENCIA' { 'TRANSFERENCIA' }
    'BECA' { 'TRANSFERENCIA' }
    'SIN CHEQUE' { 'SIN CHEQUE' }
    'DESCUENTO PLANILLA' { 'DESCUENTO PLANILLA' }
    'PRIORITARIO' { 'PRIORITARIO' }
    default { $text }
  }
}

function Resolve-ComparableMethod([object]$Value) {
  $text = Normalize-Method $Value
  switch ($text) {
    'DESCUENTO' { 'DESCUENTO PLANILLA' }
    'PRIORITARIO' { '' }
    'SIN CHEQUE' { 'TRANSFERENCIA' }
    'CHEQUE GARANTIA' { 'CHEQUES' }
    default { $text }
  }
}

function Resolve-DbPaymentMethod([string]$NormalizedMethod) {
  switch ($NormalizedMethod) {
    'CHEQUES' { 'CHEQUE' }
    'TC' { 'TARJETA' }
    'PAGARE' { 'PAGARE' }
    'TRANSFERENCIA' { 'TRANSFERENCIA' }
    'SIN CHEQUE' { 'TRANSFERENCIA' }
    'BECA' { 'TRANSFERENCIA' }
    'DESCUENTO' { 'DESCUENTO PLANILLA' }
    'DESCUENTO PLANILLA' { 'DESCUENTO PLANILLA' }
    'CHEQUE GARANTIA' { 'CHEQUE' }
    'PREFERENTE' { 'PAGARE' }
    default { $null }
  }
}

function Test-ExplicitNoFee($item) {
  return (
    $null -ne $item.installments_csv -and [int]$item.installments_csv -eq 0 -and
    (($null -eq $item.annual_csv) -or [int]$item.annual_csv -eq 0) -and
    (($null -eq $item.monthly_csv) -or [int]$item.monthly_csv -eq 0)
  )
}

function Resolve-Installments([object]$Installments, [object]$Monthly, [object]$Annual) {
  if ($Installments -and [int]$Installments -gt 0) { return [int]$Installments }
  $monthlyValue = if ($Monthly) { [int]$Monthly } else { 0 }
  $annualValue = if ($Annual) { [int]$Annual } else { 0 }
  if ($monthlyValue -gt 0 -and $annualValue -gt 0) {
    return [int][math]::Round($annualValue / $monthlyValue)
  }
  if ($annualValue -gt 0) { return 1 }
  return 0
}

function Resolve-Monthly([object]$Monthly, [int]$Installments, [object]$Annual) {
  if ($Monthly) { return [int]$Monthly }
  $annualValue = if ($Annual) { [int]$Annual } else { 0 }
  if ($Installments -gt 0 -and $annualValue -gt 0) {
    return [int][math]::Round($annualValue / $Installments)
  }
  return 0
}

$csvRows = Import-Csv -Path .\update_20260316.csv
$csvStudents = foreach ($row in $csvRows) {
  $installments = $null
  if (($row.'NUMERO DE CUOTAS' + '').Trim()) {
    $installments = [int](($row.'NUMERO DE CUOTAS' + '').Trim())
  }

  [pscustomobject]@{
    run_key = Normalize-Run $row.run_numero $row.run_verificador
    curso_csv_raw = $row.CURSO
    whole_name_csv_raw = $row.'students.whole_name'
    payment_method_csv = Normalize-Method $row.'fee.payment_method'
    payment_method_csv_compare = Resolve-ComparableMethod $row.'fee.payment_method'
    payment_method_csv_raw = $row.'fee.payment_method'
    monthly_csv = Parse-Money $row.' CUOTA MENSUAL '
    installments_csv = $installments
    annual_csv = Parse-Money $row.' ARANCEL ANUAL '
    estado_csv = Normalize-Text $row.estado_std
  }
}

$students = Get-AllRows 'students' 'id,owner_id,run,run_numero,run_verificador,whole_name,curso,estado_std'
$enrollments = Get-AllRows 'enrollments' 'id,guardian_id,year,status'
$enrollmentStudents = Get-AllRows 'enrollment_students' 'enrollment_id,student_id'
$fees = Get-AllRows 'fee' 'id,student_id,enrollment_id,amount,status,payment_method,numero_cuota,year,year_academico,due_date'
$studentGuardians = Get-AllRows 'student_guardian' 'student_id,guardian_id'

$studentByRun = @{}
foreach ($s in $students) {
  $key = Normalize-Run $s.run_numero $s.run_verificador
  if (-not $key) {
    $runText = [string]$s.run
    if ($runText -match '^\s*([0-9\.]+)-([0-9Kk])\s*$') {
      $key = Normalize-Run $Matches[1] $Matches[2]
    }
  }
  if ($key) {
    $studentByRun[$key] = $s
  }
}

$guardianByStudent = @{}
foreach ($link in $studentGuardians) {
  if (-not $guardianByStudent.ContainsKey($link.student_id)) {
    $guardianByStudent[$link.student_id] = $link.guardian_id
  }
}

$enrollmentById = @{}
foreach ($e in $enrollments) { $enrollmentById[$e.id] = $e }

$completed2026ByStudent = @{}
foreach ($rel in $enrollmentStudents) {
  $enrollment = $enrollmentById[$rel.enrollment_id]
  if ($null -eq $enrollment) { continue }
  if ([string]$enrollment.year -ne '2026') { continue }
  if ($enrollment.status -ne 'completed') { continue }
  if (-not $completed2026ByStudent.ContainsKey($rel.student_id)) {
    $completed2026ByStudent[$rel.student_id] = New-Object System.Collections.ArrayList
  }
  [void]$completed2026ByStudent[$rel.student_id].Add($enrollment)
}

$fees2026ByStudent = @{}
foreach ($fee in $fees) {
  $year = $fee.year_academico
  if ($null -eq $year -or $year -eq '') { $year = $fee.year }
  if ([string]$year -eq '2026') {
    if (-not $fees2026ByStudent.ContainsKey($fee.student_id)) {
      $fees2026ByStudent[$fee.student_id] = New-Object System.Collections.ArrayList
    }
    [void]$fees2026ByStudent[$fee.student_id].Add($fee)
  }
}

$unexpectedMissing = New-Object System.Collections.ArrayList
$methodMismatches = New-Object System.Collections.ArrayList
$monthlyMismatches = New-Object System.Collections.ArrayList
$installmentMismatches = New-Object System.Collections.ArrayList
$annualMismatches = New-Object System.Collections.ArrayList

foreach ($item in $csvStudents) {
  if (-not $studentByRun.ContainsKey($item.run_key)) { continue }
  $student = $studentByRun[$item.run_key]
  $studentId = $student.id
  $completedEnrollments = @()
  if ($completed2026ByStudent.ContainsKey($studentId)) {
    $completedEnrollments = @($completed2026ByStudent[$studentId])
  }
  if ($completedEnrollments.Count -eq 0) { continue }

  $selectedEnrollment = $completedEnrollments | Select-Object -First 1
  $studentFees = @()
  if ($fees2026ByStudent.ContainsKey($studentId)) {
    $studentFees = @($fees2026ByStudent[$studentId])
  }

  if ($studentFees.Count -eq 0) {
    if (Test-ExplicitNoFee $item) {
      continue
    }
    if ($item.payment_method_csv -and $item.payment_method_csv -notin @('PRIORITARIO')) {
      $resolvedInstallments = Resolve-Installments $item.installments_csv $item.monthly_csv $item.annual_csv
      $resolvedMonthly = Resolve-Monthly $item.monthly_csv $resolvedInstallments $item.annual_csv
      if ($resolvedInstallments -gt 0 -and $resolvedMonthly -ge 0) {
        $dbMethod = Resolve-DbPaymentMethod $item.payment_method_csv
        [void]$unexpectedMissing.Add([pscustomobject]@{
          run = $item.run_key
          nombre = $student.whole_name
          student_id = $studentId
          owner_id = $student.owner_id
          guardian_id = $selectedEnrollment.guardian_id
          enrollment_id = $selectedEnrollment.id
          metodo_csv = $item.payment_method_csv_raw
          metodo_normalizado = $item.payment_method_csv
          metodo_db = $dbMethod
          monto_mensual = $resolvedMonthly
          numero_cuotas = $resolvedInstallments
          arancel_anual = if ($item.annual_csv) { [int]$item.annual_csv } else { [int]($resolvedMonthly * $resolvedInstallments) }
        })
      }
    }
    continue
  }

  $feeMethods = @($studentFees | ForEach-Object { Normalize-Method $_.payment_method } | Where-Object { $_ } | Sort-Object -Unique)
  $monthlyAmounts = @($studentFees | ForEach-Object { if ($_.amount -ne $null) { [int][math]::Round([double]$_.amount) } } | Sort-Object -Unique)
  $installmentCount = @($studentFees | Where-Object { $_.numero_cuota -ne $null } | ForEach-Object { [int]$_.numero_cuota } | Sort-Object -Unique).Count
  $annualSum = ($studentFees | Measure-Object -Property amount -Sum).Sum
  if ($null -eq $annualSum) { $annualSum = 0 }
  $annualSum = [int][math]::Round([double]$annualSum)

  if ($item.payment_method_csv_compare) {
    if ($feeMethods -notcontains $item.payment_method_csv_compare) {
      [void]$methodMismatches.Add([pscustomobject]@{
        run = $item.run_key
        nombre = $student.whole_name
        metodo_csv = $item.payment_method_csv_raw
        metodo_fee = ($feeMethods -join ', ')
      })
    }
  }

  if ($null -ne $item.monthly_csv -and ($monthlyAmounts -notcontains [int]$item.monthly_csv)) {
    [void]$monthlyMismatches.Add([pscustomobject]@{
      run = $item.run_key
      nombre = $student.whole_name
      monto_mensual_csv = [int]$item.monthly_csv
      monto_mensual_fee = ($monthlyAmounts -join ', ')
    })
  }

  if ($null -ne $item.installments_csv -and $installmentCount -ne [int]$item.installments_csv) {
    [void]$installmentMismatches.Add([pscustomobject]@{
      run = $item.run_key
      nombre = $student.whole_name
      cuotas_csv = [int]$item.installments_csv
      cuotas_fee = $installmentCount
    })
  }

  if ($null -ne $item.annual_csv -and $annualSum -ne [int]$item.annual_csv) {
    [void]$annualMismatches.Add([pscustomobject]@{
      run = $item.run_key
      nombre = $student.whole_name
      arancel_anual_csv = [int]$item.annual_csv
      arancel_anual_fee = $annualSum
    })
  }
}

$detail = [ordered]@{
  unexpected_fee_2026_missing = @($unexpectedMissing)
  fee_payment_method_mismatches = @($methodMismatches)
  fee_monthly_mismatches = @($monthlyMismatches)
  fee_installments_mismatches = @($installmentMismatches)
  fee_annual_mismatches = @($annualMismatches)
}

$detail | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 .\tmp_fee_gap_details_2026.json

$jsonPayload = if (@($unexpectedMissing).Count -gt 0) {
  @($unexpectedMissing) | ConvertTo-Json -Compress -Depth 4
}
else {
  '[]'
}
$escapedPayload = $jsonPayload.Replace("'", "''")

$sql = @"
with source_rows as (
  select *
  from jsonb_to_recordset('$escapedPayload'::jsonb) as r(
    run text,
    nombre text,
    student_id uuid,
    owner_id uuid,
    guardian_id uuid,
    enrollment_id uuid,
    metodo_csv text,
    metodo_normalizado text,
    metodo_db text,
    monto_mensual numeric,
    numero_cuotas integer,
    arancel_anual numeric
  )
), fee_rows as (
  select
    student_id,
    owner_id,
    guardian_id,
    enrollment_id,
    metodo_db as payment_method,
    metodo_csv,
    metodo_normalizado,
    monto_mensual as amount,
    cuota_num as numero_cuota,
    (date '2026-03-05' + make_interval(months => cuota_num - 1))::date as due_date
  from source_rows s
  join lateral generate_series(1, s.numero_cuotas) as cuota_num on true
)
insert into public.fee (
  student_id,
  guardian_id,
  amount,
  due_date,
  status,
  payment_method,
  owner_id,
  year_academico,
  numero_cuota,
  enrollment_id,
  meta,
  year
)
select
  student_id,
  guardian_id,
  amount,
  due_date,
  'pending',
  payment_method,
  owner_id,
  2026,
  numero_cuota,
  enrollment_id,
  jsonb_build_object(
    'source', 'update_20260316.csv',
    'sync_reason', 'unexpected_fee_2026_missing_repair',
    'csv_payment_method', metodo_csv,
    'normalized_payment_method', metodo_normalizado
  ),
  2026
from fee_rows
on conflict (student_id, year_academico, numero_cuota) do nothing
returning student_id, numero_cuota;
"@

$sql | Set-Content -Encoding UTF8 .\tmp_fix_unexpected_fee_2026_missing.sql

Write-Output "detail_file=tmp_fee_gap_details_2026.json"
Write-Output "sql_file=tmp_fix_unexpected_fee_2026_missing.sql"
Write-Output "unexpected_fee_2026_missing=$($unexpectedMissing.Count)"
Write-Output "fee_payment_method_mismatches=$($methodMismatches.Count)"
Write-Output "fee_monthly_mismatches=$($monthlyMismatches.Count)"
Write-Output "fee_installments_mismatches=$($installmentMismatches.Count)"
Write-Output "fee_annual_mismatches=$($annualMismatches.Count)"