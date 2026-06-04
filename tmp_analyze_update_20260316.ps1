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
    try {
      $rows = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    }
    catch {
      Write-Error "Fallo GET $Endpoint offset=$offset uri=$uri"
      throw
    }
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

function Normalize-CourseBase([object]$Value) {
  $text = Normalize-Text $Value
  if (-not $text) { return '' }
  $text = $text.Replace('°', '').Replace('º', '')
  return ($text -replace '\s+[A-Z]$', '').Trim()
}

function Add-Sample($arr, $obj) {
  if ($arr.Count -lt 20) {
    $arr.Add($obj) | Out-Null
  }
}

function Test-ExplicitNoFee($item) {
  return (
    $null -ne $item.installments_csv -and [int]$item.installments_csv -eq 0 -and
    (($null -eq $item.annual_csv) -or [int]$item.annual_csv -eq 0) -and
    (($null -eq $item.monthly_csv) -or [int]$item.monthly_csv -eq 0)
  )
}

$csvRows = Import-Csv -Path .\update_20260316.csv
$csvStudents = foreach ($row in $csvRows) {
  $installments = $null
  if (($row.'NUMERO DE CUOTAS' + '').Trim()) {
    $installments = [int](($row.'NUMERO DE CUOTAS' + '').Trim())
  }

  [pscustomobject]@{
    run_key = Normalize-Run $row.run_numero $row.run_verificador
    curso_csv = Normalize-Text $row.CURSO
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

$students = Get-AllRows 'students' 'id,run,run_numero,run_verificador,whole_name,curso,estado_std'
$cursos = Get-AllRows 'cursos' 'id,nom_curso,year_academico'
$enrollments = Get-AllRows 'enrollments' 'id,year,status,created_at,updated_at,meta'
$enrollmentStudents = Get-AllRows 'enrollment_students' 'enrollment_id,student_id'
$fees = Get-AllRows 'fee' 'id,student_id,enrollment_id,amount,status,payment_method,numero_cuota,year,year_academico,due_date'

$cursoById = @{}
foreach ($c in $cursos) { $cursoById[$c.id] = $c }

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

$enrollmentById = @{}
foreach ($e in $enrollments) { $enrollmentById[$e.id] = $e }

$enrollmentByStudent = @{}
foreach ($rel in $enrollmentStudents) {
  if (-not $enrollmentByStudent.ContainsKey($rel.student_id)) {
    $enrollmentByStudent[$rel.student_id] = New-Object System.Collections.ArrayList
  }
  if ($enrollmentById.ContainsKey($rel.enrollment_id)) {
    [void]$enrollmentByStudent[$rel.student_id].Add($enrollmentById[$rel.enrollment_id])
  }
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

$summary = [ordered]@{
  csv_rows = $csvRows.Count
  csv_students = $csvStudents.Count
  matched_students = 0
  missing_students = 0
  course_mismatches = 0
  course_mismatches_section_only = 0
  course_mismatches_major = 0
  status_mismatches = 0
  enrollment_2026_missing = 0
  enrollment_2026_not_completed = 0
  fee_2026_missing = 0
  fee_payment_method_mismatches = 0
  fee_monthly_mismatches = 0
  fee_installments_mismatches = 0
  fee_annual_mismatches = 0
  ok_full_match = 0
}

$aggregates = [ordered]@{
  fee_2026_missing_by_method = @{}
  enrollment_2026_missing_by_method = @{}
  unexpected_fee_2026_missing = 0
  unexpected_fee_2026_missing_by_method = @{}
}

$samples = [ordered]@{
  missing_students = (New-Object System.Collections.ArrayList)
  course_mismatches = (New-Object System.Collections.ArrayList)
  course_mismatches_section_only = (New-Object System.Collections.ArrayList)
  course_mismatches_major = (New-Object System.Collections.ArrayList)
  status_mismatches = (New-Object System.Collections.ArrayList)
  enrollment_2026_missing = (New-Object System.Collections.ArrayList)
  enrollment_2026_not_completed = (New-Object System.Collections.ArrayList)
  fee_2026_missing = (New-Object System.Collections.ArrayList)
  fee_payment_method_mismatches = (New-Object System.Collections.ArrayList)
  fee_monthly_mismatches = (New-Object System.Collections.ArrayList)
  fee_installments_mismatches = (New-Object System.Collections.ArrayList)
  fee_annual_mismatches = (New-Object System.Collections.ArrayList)
  ok_full_match = (New-Object System.Collections.ArrayList)
}

$methodCsv = @{}
$methodFee = @{}

foreach ($item in $csvStudents) {
  if (-not $methodCsv.ContainsKey($item.payment_method_csv)) {
    $methodCsv[$item.payment_method_csv] = 0
  }
  $methodCsv[$item.payment_method_csv]++

  $student = $studentByRun[$item.run_key]
  if (-not $student) {
    $summary.missing_students++
    Add-Sample $samples.missing_students ([pscustomobject]@{
      run = $item.run_key
      nombre = $item.whole_name_csv_raw
      curso_csv = $item.curso_csv_raw
      metodo_csv = $item.payment_method_csv_raw
    })
    continue
  }

  $summary.matched_students++
  $flags = @{}
  $studentId = $student.id

  $cursoDbName = ''
  if ($student.curso -and $cursoById.ContainsKey($student.curso)) {
    $cursoDbName = $cursoById[$student.curso].nom_curso
  }
  if ($item.curso_csv -and (Normalize-Text $cursoDbName) -and $item.curso_csv -ne (Normalize-Text $cursoDbName)) {
    $summary.course_mismatches++
    $flags.course = $true
    if ((Normalize-CourseBase $item.curso_csv) -eq (Normalize-CourseBase $cursoDbName)) {
      $summary.course_mismatches_section_only++
      Add-Sample $samples.course_mismatches_section_only ([pscustomobject]@{
        run = $item.run_key
        nombre = $item.whole_name_csv_raw
        curso_csv = $item.curso_csv_raw
        curso_bd = $cursoDbName
      })
    }
    else {
      $summary.course_mismatches_major++
      Add-Sample $samples.course_mismatches_major ([pscustomobject]@{
        run = $item.run_key
        nombre = $item.whole_name_csv_raw
        curso_csv = $item.curso_csv_raw
        curso_bd = $cursoDbName
      })
    }
    Add-Sample $samples.course_mismatches ([pscustomobject]@{
      run = $item.run_key
      nombre = $item.whole_name_csv_raw
      curso_csv = $item.curso_csv_raw
      curso_bd = $cursoDbName
    })
  }

  $estadoDb = Normalize-Text $student.estado_std
  if ($item.estado_csv -and $estadoDb -and $item.estado_csv -ne $estadoDb) {
    $summary.status_mismatches++
    $flags.status = $true
    Add-Sample $samples.status_mismatches ([pscustomobject]@{
      run = $item.run_key
      nombre = $item.whole_name_csv_raw
      estado_csv = $item.estado_csv
      estado_bd = $estadoDb
    })
  }

  $studentEnrollments = @()
  if ($enrollmentByStudent.ContainsKey($studentId)) {
    $studentEnrollments = @($enrollmentByStudent[$studentId])
  }
  $enroll2026 = @($studentEnrollments | Where-Object { [string]$_.year -eq '2026' })
  if ($enroll2026.Count -eq 0) {
    $summary.enrollment_2026_missing++
    $flags.enrollmentMissing = $true
    if (-not $aggregates.enrollment_2026_missing_by_method.Contains($item.payment_method_csv)) {
      $aggregates.enrollment_2026_missing_by_method[$item.payment_method_csv] = 0
    }
    $aggregates.enrollment_2026_missing_by_method[$item.payment_method_csv]++
    Add-Sample $samples.enrollment_2026_missing ([pscustomobject]@{
      run = $item.run_key
      nombre = $item.whole_name_csv_raw
      curso_csv = $item.curso_csv_raw
      metodo_csv = $item.payment_method_csv_raw
    })
    continue
  }

  $completed = @($enroll2026 | Where-Object { (Normalize-Text $_.status) -eq 'COMPLETED' })
  $selectedEnrollment = @($enroll2026 | Sort-Object updated_at, created_at)[-1]
  if ($completed.Count -eq 0) {
    $summary.enrollment_2026_not_completed++
    $flags.enrollmentNotCompleted = $true
    $statuses = @($enroll2026 | ForEach-Object { $_.status } | Sort-Object -Unique)
    Add-Sample $samples.enrollment_2026_not_completed ([pscustomobject]@{
      run = $item.run_key
      nombre = $item.whole_name_csv_raw
      estados = ($statuses -join ', ')
    })
  }

  $studentFees = @()
  if ($fees2026ByStudent.ContainsKey($studentId)) {
    $studentFees = @($fees2026ByStudent[$studentId])
  }
  if ($studentFees.Count -eq 0) {
    if (Test-ExplicitNoFee $item) {
      if ($flags.Count -eq 0) {
        $summary.ok_full_match++
        Add-Sample $samples.ok_full_match ([pscustomobject]@{
          run = $item.run_key
          nombre = $item.whole_name_csv_raw
        })
      }
      continue
    }
    $summary.fee_2026_missing++
    $flags.feeMissing = $true
    if (-not $aggregates.fee_2026_missing_by_method.Contains($item.payment_method_csv)) {
      $aggregates.fee_2026_missing_by_method[$item.payment_method_csv] = 0
    }
    $aggregates.fee_2026_missing_by_method[$item.payment_method_csv]++
    if ($item.payment_method_csv -and $item.payment_method_csv -notin @('PRIORITARIO')) {
      $aggregates.unexpected_fee_2026_missing++
      if (-not $aggregates.unexpected_fee_2026_missing_by_method.Contains($item.payment_method_csv)) {
        $aggregates.unexpected_fee_2026_missing_by_method[$item.payment_method_csv] = 0
      }
      $aggregates.unexpected_fee_2026_missing_by_method[$item.payment_method_csv]++
    }
    Add-Sample $samples.fee_2026_missing ([pscustomobject]@{
      run = $item.run_key
      nombre = $item.whole_name_csv_raw
      metodo_csv = $item.payment_method_csv_raw
      enrollment_status = $selectedEnrollment.status
    })
    continue
  }

  $feeMethods = @($studentFees | ForEach-Object { Normalize-Method $_.payment_method } | Where-Object { $_ } | Sort-Object -Unique)
  foreach ($m in $feeMethods) {
    if (-not $methodFee.ContainsKey($m)) { $methodFee[$m] = 0 }
    $methodFee[$m]++
  }

  $feeAmounts = @($studentFees | ForEach-Object { [int][math]::Round([double]($_.amount)) } | Sort-Object -Unique)
  $feeInstallments = @($studentFees | Where-Object { $null -ne $_.numero_cuota -and $_.numero_cuota -ne '' } | ForEach-Object { [int]$_.numero_cuota } | Sort-Object -Unique)
  $annualFee = [int][math]::Round([double](($studentFees | Measure-Object -Property amount -Sum).Sum))

  if ($item.payment_method_csv_compare) {
    if ($feeMethods -notcontains $item.payment_method_csv_compare) {
      $summary.fee_payment_method_mismatches++
      $flags.feeMethod = $true
      Add-Sample $samples.fee_payment_method_mismatches ([pscustomobject]@{
        run = $item.run_key
        nombre = $item.whole_name_csv_raw
        metodo_csv = $item.payment_method_csv_raw
        metodos_fee = ($feeMethods -join ', ')
        motivo = 'Método no coincide'
      })
    }
  }

  if ($null -ne $item.monthly_csv) {
    if ($feeAmounts.Count -ne 1 -or $feeAmounts[0] -ne $item.monthly_csv) {
      $summary.fee_monthly_mismatches++
      $flags.feeMonthly = $true
      Add-Sample $samples.fee_monthly_mismatches ([pscustomobject]@{
        run = $item.run_key
        nombre = $item.whole_name_csv_raw
        cuota_csv = $item.monthly_csv
        cuotas_fee = ($feeAmounts -join ', ')
      })
    }
  }

  if ($null -ne $item.installments_csv) {
    if ($feeInstallments.Count -ne $item.installments_csv) {
      $summary.fee_installments_mismatches++
      $flags.feeInstallments = $true
      Add-Sample $samples.fee_installments_mismatches ([pscustomobject]@{
        run = $item.run_key
        nombre = $item.whole_name_csv_raw
        cuotas_csv = $item.installments_csv
        cuotas_fee = $feeInstallments.Count
        numeros_fee = ($feeInstallments -join ', ')
      })
    }
  }

  if ($null -ne $item.annual_csv) {
    if ($annualFee -ne $item.annual_csv) {
      $summary.fee_annual_mismatches++
      $flags.feeAnnual = $true
      Add-Sample $samples.fee_annual_mismatches ([pscustomobject]@{
        run = $item.run_key
        nombre = $item.whole_name_csv_raw
        anual_csv = $item.annual_csv
        anual_fee = $annualFee
      })
    }
  }

  if ($flags.Count -eq 0) {
    $summary.ok_full_match++
    Add-Sample $samples.ok_full_match ([pscustomobject]@{
      run = $item.run_key
      nombre = $item.whole_name_csv_raw
    })
  }
}

$report = [ordered]@{
  summary = $summary
  aggregates = $aggregates
  method_distribution = [ordered]@{
    csv = $methodCsv
    fee_2026 = $methodFee
  }
  samples = $samples
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 .\tmp_update_20260316_report.json
Write-Output 'report_file=tmp_update_20260316_report.json'
Write-Output ("csv_students=" + $summary.csv_students)
Write-Output ("matched_students=" + $summary.matched_students)
Write-Output ("ok_full_match=" + $summary.ok_full_match)
