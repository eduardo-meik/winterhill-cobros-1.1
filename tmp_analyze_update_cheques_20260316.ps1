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
  param(
    [string]$Endpoint,
    [string]$Select = '*',
    [hashtable]$Filters = @{}
  )

  $all = @()
  $limit = 1000
  $offset = 0

  while ($true) {
    $query = @{
      select = $Select
      limit = $limit
      offset = $offset
    }
    foreach ($key in $Filters.Keys) {
      $query[$key] = $Filters[$key]
    }

    $pairs = foreach ($key in $query.Keys) {
      "{0}={1}" -f [uri]::EscapeDataString([string]$key), [uri]::EscapeDataString([string]$query[$key])
    }
    $uri = "{0}/rest/v1/{1}?{2}" -f $baseUrl, $Endpoint, ($pairs -join '&')

    try {
      $rows = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    }
    catch {
      Write-Host "GET ERROR uri=$uri" -ForegroundColor Red
      Write-Host $_.Exception.Message -ForegroundColor Red
      if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host ($reader.ReadToEnd()) -ForegroundColor Red
      }
      Write-Error "Fallo GET $Endpoint offset=$offset"
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
  return (($sb.ToString().ToUpperInvariant() -replace '[^A-Z0-9 ]', ' ' -replace '\s+', ' ').Trim())
}

function Normalize-NoSpace([object]$Value) {
  return (Normalize-Text $Value).Replace(' ', '')
}

function Normalize-Run([object]$Value) {
  $text = Normalize-Text $Value
  if (-not $text) { return '' }
  if ($text -match '([0-9]+)\s*([0-9K])$') {
    $num = ($Matches[1] -replace '^0+', '')
    $dv = $Matches[2]
    if (-not $num) { $num = '0' }
    return "$num-$dv"
  }
  $digits = ($text -replace '[^0-9K]', '').Trim()
  if (-not $digits) { return '' }
  if ($digits.Length -ge 2) {
    $num = ($digits.Substring(0, $digits.Length - 1) -replace '^0+', '')
    $dv = $digits.Substring($digits.Length - 1)
    if (-not $num) { $num = '0' }
    return "$num-$dv"
  }
  return $digits
}

function Normalize-Course([object]$Value) {
  $text = Normalize-Text $Value
  $text = $text.Replace(' BASICO', ' BASICO').Replace(' MEDIO', ' MEDIO')
  return $text.Trim()
}

function Normalize-CourseBase([object]$Value) {
  $text = Normalize-Course $Value
  if (-not $text) { return '' }
  return ($text -replace '\s+[A-Z]$', '').Trim()
}

function Get-NameTokens([object]$Value) {
  $key = Normalize-Text $Value
  if (-not $key) { return @() }
  return @($key -split ' ' | Where-Object { $_ -and $_.Length -ge 2 })
}

function Get-NameSimilarity {
  param(
    [string]$Left,
    [string]$Right
  )

  $leftTokens = Get-NameTokens $Left
  $rightTokens = Get-NameTokens $Right
  if ($leftTokens.Count -eq 0 -or $rightTokens.Count -eq 0) { return 0 }

  $shared = @($leftTokens | Where-Object { $rightTokens -contains $_ })
  $score = [int][math]::Round((100.0 * $shared.Count) / $leftTokens.Count)

  if ($leftTokens.Count -gt 0 -and $rightTokens.Count -gt 0 -and $leftTokens[0] -eq $rightTokens[0]) {
    $score += 10
  }
  if ($score -gt 100) { $score = 100 }
  return $score
}

function Parse-Money([object]$Value) {
  if ($null -eq $Value) { return $null }
  $text = ([string]$Value).Trim()
  if (-not $text) { return $null }
  $digits = $text -replace '[^0-9-]', ''
  if (-not $digits) { return $null }
  return [int]$digits
}

function Parse-Count([object]$Value) {
  if ($null -eq $Value) { return $null }
  $text = Normalize-Text $Value
  if ($text -match '(\d+)') {
    return [int]$Matches[1]
  }
  return $null
}

function Expand-Series([object]$Value) {
  $result = [ordered]@{
    raw = [string]$Value
    serials = @()
    issues = @()
  }

  if ($null -eq $Value) { return [pscustomobject]$result }
  $text = ([string]$Value).Trim()
  if (-not $text) { return [pscustomobject]$result }

  $tokens = @()
  foreach ($part in ($text -split '-')) {
    $digits = ($part -replace '[^0-9]', '')
    if ($digits) { $tokens += $digits }
  }

  if ($tokens.Count -eq 0) {
    $result.issues += 'sin_digitos'
    return [pscustomobject]$result
  }

  $first = $tokens[0]
  $serials = New-Object System.Collections.ArrayList
  [void]$serials.Add($first)

  for ($i = 1; $i -lt $tokens.Count; $i++) {
    $token = $tokens[$i]
    if ($token.Length -lt $first.Length) {
      $prefix = $first.Substring(0, $first.Length - $token.Length)
      [void]$serials.Add($prefix + $token)
      continue
    }

    [void]$serials.Add($token)
    if ($token.Length -gt $first.Length) {
      $result.issues += "token_largo:$token"
    }
  }

  $result.serials = @($serials)
  return [pscustomobject]$result
}

function Add-Sample {
  param(
    [System.Collections.ArrayList]$Array,
    [object]$Item,
    [int]$Limit = 25
  )

  if ($Array.Count -lt $Limit) {
    [void]$Array.Add($Item)
  }
}

function Get-RowValue {
  param(
    $Row,
    [string[]]$Names
  )

  foreach ($name in $Names) {
    $prop = $Row.PSObject.Properties[$name]
    if ($null -ne $prop) {
      return [string]$prop.Value
    }
  }

  return ''
}

function Get-EnrollmentScore {
  param(
    $Enrollment,
    $Row,
    [string]$StudentRunKey,
    [string]$GuardianRunKey,
    [string]$NameKey,
    [string]$NameNoSpace,
    [string]$CourseKey,
    [string]$CourseBase
  )

  $score = 0
  $reasons = New-Object System.Collections.ArrayList

  if ($Enrollment.year -eq 2026) {
    $score += 20
    [void]$reasons.Add('year_2026')
  }
  if ((Normalize-Text $Enrollment.status) -eq 'COMPLETED') {
    $score += 10
    [void]$reasons.Add('status_completed')
  }
  if ($GuardianRunKey -and $Enrollment.guardian_run_key -eq $GuardianRunKey) {
    $score += 40
    [void]$reasons.Add('guardian_run')
  }

  foreach ($student in $Enrollment.students) {
    if ($StudentRunKey -and $student.run_key -eq $StudentRunKey) {
      $score += 60
      [void]$reasons.Add("student_run:$($student.whole_name)")
    }
    if ($NameKey -and $student.name_key -eq $NameKey) {
      $score += 40
      [void]$reasons.Add("name_exact:$($student.whole_name)")
    }
    elseif ($NameNoSpace -and $student.name_no_space -eq $NameNoSpace) {
      $score += 35
      [void]$reasons.Add("name_nospace:$($student.whole_name)")
    }
    elseif ($NameKey -and $student.name_key -like "*$NameKey*") {
      $score += 12
      [void]$reasons.Add("name_contains:$($student.whole_name)")
    }

    $nameSimilarity = Get-NameSimilarity $NameKey $student.name_key
    if ($nameSimilarity -ge 85) {
      $score += 28
      [void]$reasons.Add(("name_sim:{0}:{1}" -f $nameSimilarity, $student.whole_name))
    }
    elseif ($nameSimilarity -ge 65) {
      $score += 16
      [void]$reasons.Add(("name_sim:{0}:{1}" -f $nameSimilarity, $student.whole_name))
    }

    if ($CourseKey -and $student.course_key -eq $CourseKey) {
      $score += 18
      [void]$reasons.Add("course_exact:$($student.course_name)")
    }
    elseif ($CourseBase -and $student.course_base -eq $CourseBase) {
      $score += 10
      [void]$reasons.Add("course_base:$($student.course_name)")
    }
  }

  return [pscustomobject]@{
    score = $score
    reasons = @($reasons)
  }
}

$csvRows = Import-Csv -Path .\update_cheques.csv

$students = Get-AllRows 'students' 'id,run,run_numero,run_verificador,whole_name,first_name,apellido_paterno,apellido_materno,curso,estado_std'
$cursos = Get-AllRows 'cursos' 'id,nom_curso,year_academico'
$guardians = Get-AllRows 'guardians' 'id,run,first_name,last_name'
$studentGuardians = Get-AllRows 'student_guardian' 'student_id,guardian_id'
$enrollments = Get-AllRows 'enrollments' 'id,guardian_id,year,status,created_at,updated_at,meta' @{ year = 'eq.2026' }
$enrollmentStudents = Get-AllRows 'enrollment_students' 'enrollment_id,student_id'
$cheques = Get-AllRows 'cheques' 'id,enrollment_id,numero_serie,banco,monto,estado,numero_cuota,folio_number,created_at'

$cursoById = @{}
foreach ($curso in $cursos) {
  $cursoById[$curso.id] = $curso
}

$guardianById = @{}
$guardiansByRun = @{}
foreach ($guardian in $guardians) {
  $guardianById[$guardian.id] = $guardian
  $runKey = Normalize-Run $guardian.run
  if ($runKey) {
    if (-not $guardiansByRun.ContainsKey($runKey)) {
      $guardiansByRun[$runKey] = New-Object System.Collections.ArrayList
    }
    [void]$guardiansByRun[$runKey].Add([pscustomobject]@{
      id = $guardian.id
      run_key = $runKey
      name = (@($guardian.first_name, $guardian.last_name) -join ' ').Trim()
    })
  }
}

$studentById = @{}
$studentsByName = @{}
$studentsByNoSpace = @{}
$studentsByRun = @{}
foreach ($student in $students) {
  $runKey = ''
  if ($student.run) {
    $runKey = Normalize-Run $student.run
  }
  if (-not $runKey -and $student.run_numero -and $student.run_verificador) {
    $runKey = Normalize-Run "$($student.run_numero)-$($student.run_verificador)"
  }

  $wholeName = $student.whole_name
  if (-not $wholeName) {
    $wholeName = @($student.first_name, $student.apellido_paterno, $student.apellido_materno) -join ' '
  }

  $courseName = ''
  if ($student.curso -and $cursoById.ContainsKey($student.curso)) {
    $courseName = $cursoById[$student.curso].nom_curso
  }

  $item = [pscustomobject]@{
    id = $student.id
    whole_name = $wholeName.Trim()
    run_key = $runKey
    course_name = $courseName
    course_key = Normalize-Course $courseName
    course_base = Normalize-CourseBase $courseName
    estado_std = $student.estado_std
    name_key = Normalize-Text $wholeName
    name_no_space = Normalize-NoSpace $wholeName
    tokens = Get-NameTokens $wholeName
  }

  $studentById[$item.id] = $item

  if ($item.name_key) {
    if (-not $studentsByName.ContainsKey($item.name_key)) {
      $studentsByName[$item.name_key] = New-Object System.Collections.ArrayList
    }
    [void]$studentsByName[$item.name_key].Add($item)
  }

  if ($item.name_no_space) {
    if (-not $studentsByNoSpace.ContainsKey($item.name_no_space)) {
      $studentsByNoSpace[$item.name_no_space] = New-Object System.Collections.ArrayList
    }
    [void]$studentsByNoSpace[$item.name_no_space].Add($item)
  }

  if ($item.run_key) {
    if (-not $studentsByRun.ContainsKey($item.run_key)) {
      $studentsByRun[$item.run_key] = New-Object System.Collections.ArrayList
    }
    [void]$studentsByRun[$item.run_key].Add($item)
  }
}

$guardianStudentsByGuardianId = @{}
foreach ($rel in $studentGuardians) {
  if (-not $guardianStudentsByGuardianId.ContainsKey($rel.guardian_id)) {
    $guardianStudentsByGuardianId[$rel.guardian_id] = New-Object System.Collections.ArrayList
  }
  if ($studentById.ContainsKey($rel.student_id)) {
    [void]$guardianStudentsByGuardianId[$rel.guardian_id].Add($studentById[$rel.student_id])
  }
}

$enrollmentsById = @{}
$enrollmentsByGuardianId = @{}
foreach ($enrollment in $enrollments) {
  $guardianRunKey = ''
  if ($guardianById.ContainsKey($enrollment.guardian_id)) {
    $guardianRunKey = Normalize-Run $guardianById[$enrollment.guardian_id].run
  }

  $item = [pscustomobject]@{
    id = $enrollment.id
    guardian_id = $enrollment.guardian_id
    guardian_run_key = $guardianRunKey
    year = [int]$enrollment.year
    status = $enrollment.status
    students = New-Object System.Collections.ArrayList
    cheques = New-Object System.Collections.ArrayList
    meta = $enrollment.meta
  }

  $enrollmentsById[$item.id] = $item
  if (-not $enrollmentsByGuardianId.ContainsKey($item.guardian_id)) {
    $enrollmentsByGuardianId[$item.guardian_id] = New-Object System.Collections.ArrayList
  }
  [void]$enrollmentsByGuardianId[$item.guardian_id].Add($item)
}

$enrollmentsByStudentId = @{}
foreach ($rel in $enrollmentStudents) {
  if ($enrollmentsById.ContainsKey($rel.enrollment_id) -and $studentById.ContainsKey($rel.student_id)) {
    $enrollment = $enrollmentsById[$rel.enrollment_id]
    [void]$enrollment.students.Add($studentById[$rel.student_id])
    if (-not $enrollmentsByStudentId.ContainsKey($rel.student_id)) {
      $enrollmentsByStudentId[$rel.student_id] = New-Object System.Collections.ArrayList
    }
    [void]$enrollmentsByStudentId[$rel.student_id].Add($enrollment)
  }
}

foreach ($cheque in $cheques) {
  if ($enrollmentsById.ContainsKey($cheque.enrollment_id)) {
    [void]$enrollmentsById[$cheque.enrollment_id].cheques.Add([pscustomobject]@{
      id = $cheque.id
      serial = ([string]$cheque.numero_serie).Trim()
      serial_key = Normalize-NoSpace $cheque.numero_serie
      banco = ([string]$cheque.banco).Trim()
      banco_key = Normalize-Text $cheque.banco
      monto = [decimal]$cheque.monto
      estado = $cheque.estado
      numero_cuota = $cheque.numero_cuota
      folio_number = $cheque.folio_number
    })
  }
}

$analysis = New-Object System.Collections.ArrayList
$summary = [ordered]@{
  csv_rows = $csvRows.Count
  matched_rows = 0
  unmatched_rows = 0
  matched_unique_enrollments = 0
  duplicate_rows_same_enrollment = 0
  rows_without_db_cheques = 0
  rows_full_match = 0
  rows_with_differences = 0
  bank_mismatches = 0
  count_mismatches = 0
  amount_mismatches = 0
  serial_mismatches = 0
  course_mismatches = 0
  ambiguous_matches = 0
  db_enrollments_2026_with_cheques = 0
  db_enrollments_2026_with_cheques_not_in_csv = 0
}

$samples = [ordered]@{
  unmatched = (New-Object System.Collections.ArrayList)
  differences = (New-Object System.Collections.ArrayList)
  ambiguous = (New-Object System.Collections.ArrayList)
  duplicate_enrollment_rows = (New-Object System.Collections.ArrayList)
  db_only = (New-Object System.Collections.ArrayList)
}

$matchedEnrollmentIds = New-Object System.Collections.ArrayList

for ($index = 0; $index -lt $csvRows.Count; $index++) {
  $row = $csvRows[$index]
  $rowNumber = $index + 2
  $nameRaw = (Get-RowValue $row @('ALUMNO', 'ESTUDIANTE')).Trim()
  $courseRaw = (Get-RowValue $row @('CURSO')).Trim()
  $runRaw = (Get-RowValue $row @('RUT')).Trim()
  $bankRaw = (Get-RowValue $row @('BANCO')).Trim()
  $countRaw = (Get-RowValue $row @('CHEQUES')).Trim()
  $valueRaw = (Get-RowValue $row @('VALOR')).Trim()
  $seriesRaw = (Get-RowValue $row @('NUMERO DE SERIE')).Trim()
  $notesRaw = (Get-RowValue $row @('NOTAS')).Trim()

  $nameKey = Normalize-Text $nameRaw
  $nameNoSpace = Normalize-NoSpace $nameRaw
  $courseKey = Normalize-Course $courseRaw
  $courseBase = Normalize-CourseBase $courseRaw
  $runKey = Normalize-Run $runRaw
  $csvCount = Parse-Count $countRaw
  $csvValue = Parse-Money $valueRaw
  $seriesInfo = Expand-Series $seriesRaw
  $csvSerialKeys = @($seriesInfo.serials | ForEach-Object { Normalize-NoSpace $_ })
  if (-not $csvCount -and $csvSerialKeys.Count -gt 0) {
    $csvCount = $csvSerialKeys.Count
  }

  $candidateEnrollments = New-Object System.Collections.ArrayList

  if ($runKey -and $guardiansByRun.ContainsKey($runKey)) {
    foreach ($guardian in $guardiansByRun[$runKey]) {
      if ($enrollmentsByGuardianId.ContainsKey($guardian.id)) {
        foreach ($enrollment in $enrollmentsByGuardianId[$guardian.id]) {
          if (-not ($candidateEnrollments | Where-Object { $_.id -eq $enrollment.id })) {
            [void]$candidateEnrollments.Add($enrollment)
          }
        }
      }
    }
  }

  if ($runKey -and $studentsByRun.ContainsKey($runKey)) {
    foreach ($student in $studentsByRun[$runKey]) {
      if ($enrollmentsByStudentId.ContainsKey($student.id)) {
        foreach ($enrollment in $enrollmentsByStudentId[$student.id]) {
          if (-not ($candidateEnrollments | Where-Object { $_.id -eq $enrollment.id })) {
            [void]$candidateEnrollments.Add($enrollment)
          }
        }
      }
    }
  }

  if ($studentsByName.ContainsKey($nameKey)) {
    foreach ($student in $studentsByName[$nameKey]) {
      if ($enrollmentsByStudentId.ContainsKey($student.id)) {
        foreach ($enrollment in $enrollmentsByStudentId[$student.id]) {
          if (-not ($candidateEnrollments | Where-Object { $_.id -eq $enrollment.id })) {
            [void]$candidateEnrollments.Add($enrollment)
          }
        }
      }
    }
  }

  if ($candidateEnrollments.Count -eq 0 -and $studentsByNoSpace.ContainsKey($nameNoSpace)) {
    foreach ($student in $studentsByNoSpace[$nameNoSpace]) {
      if ($enrollmentsByStudentId.ContainsKey($student.id)) {
        foreach ($enrollment in $enrollmentsByStudentId[$student.id]) {
          if (-not ($candidateEnrollments | Where-Object { $_.id -eq $enrollment.id })) {
            [void]$candidateEnrollments.Add($enrollment)
          }
        }
      }
    }
  }

  if ($candidateEnrollments.Count -eq 0) {
    foreach ($student in $studentById.Values) {
      $nameSimilarity = Get-NameSimilarity $nameKey $student.name_key
      $courseAligns = ($courseKey -and $student.course_key -eq $courseKey) -or ($courseBase -and $student.course_base -eq $courseBase)
      if ($nameSimilarity -ge 85 -or ($nameSimilarity -ge 65 -and $courseAligns) -or ($nameSimilarity -ge 75 -and $runKey)) {
        if ($enrollmentsByStudentId.ContainsKey($student.id)) {
          foreach ($enrollment in $enrollmentsByStudentId[$student.id]) {
            if (-not ($candidateEnrollments | Where-Object { $_.id -eq $enrollment.id })) {
              [void]$candidateEnrollments.Add($enrollment)
            }
          }
        }
      }
    }
  }

  $scored = @()
  foreach ($candidate in $candidateEnrollments) {
    $scoreInfo = Get-EnrollmentScore -Enrollment $candidate -Row $row -StudentRunKey $runKey -GuardianRunKey $runKey -NameKey $nameKey -NameNoSpace $nameNoSpace -CourseKey $courseKey -CourseBase $courseBase
    $scored += [pscustomobject]@{
      enrollment = $candidate
      score = $scoreInfo.score
      reasons = $scoreInfo.reasons
    }
  }

  $best = $scored | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = { $_.enrollment.students.Count }; Descending = $false } | Select-Object -First 1
  $second = $scored | Sort-Object @{ Expression = 'score'; Descending = $true } | Select-Object -Skip 1 -First 1

  if (-not $best -or $best.score -lt 25) {
    $summary.unmatched_rows++
    Add-Sample $samples.unmatched ([pscustomobject]@{
      row = $rowNumber
      alumno = $nameRaw
      curso_csv = $courseRaw
      rut_csv = $runRaw
      banco_csv = $bankRaw
      cheques_csv = $countRaw
      serie_csv = $seriesRaw
    })
    [void]$analysis.Add([pscustomobject]@{
      row = $rowNumber
      alumno = $nameRaw
      curso_csv = $courseRaw
      rut_csv = $runRaw
      status = 'unmatched'
      reason = 'sin_match_confiable'
      candidate_count = $candidateEnrollments.Count
    })
    continue
  }

  $summary.matched_rows++
  if (-not ($matchedEnrollmentIds -contains $best.enrollment.id)) {
    [void]$matchedEnrollmentIds.Add($best.enrollment.id)
  }
  else {
    $summary.duplicate_rows_same_enrollment++
    Add-Sample $samples.duplicate_enrollment_rows ([pscustomobject]@{
      row = $rowNumber
      alumno = $nameRaw
      enrollment_id = $best.enrollment.id
      students_db = ($best.enrollment.students | ForEach-Object { $_.whole_name }) -join ' | '
    })
  }

  $isAmbiguous = $false
  if ($second -and $best.score - $second.score -lt 15) {
    $summary.ambiguous_matches++
    $isAmbiguous = $true
    Add-Sample $samples.ambiguous ([pscustomobject]@{
      row = $rowNumber
      alumno = $nameRaw
      chosen_enrollment = $best.enrollment.id
      chosen_score = $best.score
      alt_enrollment = $second.enrollment.id
      alt_score = $second.score
      chosen_reasons = ($best.reasons -join ', ')
    })
  }

  $dbCheques = @($best.enrollment.cheques)
  $dbCount = $dbCheques.Count
  $dbBanks = @($dbCheques | ForEach-Object { $_.banco_key } | Sort-Object -Unique)
  $dbAmounts = @($dbCheques | ForEach-Object { [int][math]::Round([decimal]$_.monto) } | Sort-Object -Unique)
  $dbSerialKeys = @($dbCheques | ForEach-Object { $_.serial_key } | Sort-Object -Unique)

  $matchedStudent = $best.enrollment.students |
    Sort-Object @{ Expression = {
      if ($_.name_key -eq $nameKey) { 0 }
      elseif ($_.name_no_space -eq $nameNoSpace) { 1 }
      elseif ($_.course_key -eq $courseKey) { 2 }
      elseif ($_.course_base -eq $courseBase) { 3 }
      else { 9 }
    } } |
    Select-Object -First 1

  $diffs = New-Object System.Collections.ArrayList

  if ($matchedStudent -and $courseKey -and $matchedStudent.course_key -ne $courseKey -and $matchedStudent.course_base -ne $courseBase) {
    $summary.course_mismatches++
    [void]$diffs.Add('curso')
  }

  if ($dbCount -eq 0) {
    $summary.rows_without_db_cheques++
    [void]$diffs.Add('sin_cheques_bd')
  }

  if ($csvCount -and $dbCount -ne $csvCount) {
    $summary.count_mismatches++
    [void]$diffs.Add('cantidad')
  }

  if ($bankRaw) {
    $bankKey = Normalize-Text $bankRaw
    if ($dbBanks.Count -gt 0 -and -not ($dbBanks -contains $bankKey)) {
      $summary.bank_mismatches++
      [void]$diffs.Add('banco')
    }
  }

  if ($csvValue -and $dbAmounts.Count -gt 0 -and -not ($dbAmounts -contains $csvValue)) {
    $summary.amount_mismatches++
    [void]$diffs.Add('monto')
  }

  if ($csvSerialKeys.Count -gt 0) {
    $missingInDb = @($csvSerialKeys | Where-Object { $_ -and -not ($dbSerialKeys -contains $_) })
    $extraInDb = @($dbSerialKeys | Where-Object { $_ -and -not ($csvSerialKeys -contains $_) })
    if ($missingInDb.Count -gt 0 -or $extraInDb.Count -gt 0) {
      $summary.serial_mismatches++
      [void]$diffs.Add('series')
    }
  }

  $status = 'match'
  if ($diffs.Count -gt 0) {
    $summary.rows_with_differences++
    $status = if ($isAmbiguous) { 'match_ambiguous_with_diff' } else { 'match_with_diff' }
    Add-Sample $samples.differences ([pscustomobject]@{
      row = $rowNumber
      alumno = $nameRaw
      enrollment_id = $best.enrollment.id
      diffs = ($diffs -join ', ')
      curso_csv = $courseRaw
      curso_db = $matchedStudent.course_name
      banco_csv = $bankRaw
      bancos_db = ($dbBanks -join ' | ')
      valor_csv = $csvValue
      montos_db = ($dbAmounts -join ' | ')
      cheques_csv = $csvCount
      cheques_db = $dbCount
    })
  }
  else {
    $summary.rows_full_match++
    if ($isAmbiguous) {
      $status = 'match_ambiguous'
    }
  }

  [void]$analysis.Add([pscustomobject]@{
    row = $rowNumber
    alumno = $nameRaw
    curso_csv = $courseRaw
    rut_csv = $runRaw
    enrollment_id = $best.enrollment.id
    guardian_run_match = ($best.enrollment.guardian_run_key -eq $runKey)
    matched_student = if ($matchedStudent) { $matchedStudent.whole_name } else { $null }
    curso_db = if ($matchedStudent) { $matchedStudent.course_name } else { $null }
    cheques_csv = $csvCount
    cheques_db = $dbCount
    valor_csv = $csvValue
    montos_db = $dbAmounts
    banco_csv = $bankRaw
    bancos_db = $dbBanks
    seriales_csv = $seriesInfo.serials
    seriales_db = @($dbCheques | ForEach-Object { $_.serial })
    parse_issues_csv = $seriesInfo.issues
    diffs = @($diffs)
    status = $status
    score = $best.score
    score_reasons = $best.reasons
    notas_csv = $notesRaw
  })
}

$summary.matched_unique_enrollments = $matchedEnrollmentIds.Count

$dbEnrollmentsWithCheques = @($enrollmentsById.Values | Where-Object { $_.year -eq 2026 -and $_.cheques.Count -gt 0 })
$summary.db_enrollments_2026_with_cheques = $dbEnrollmentsWithCheques.Count

$dbOnly = @($dbEnrollmentsWithCheques | Where-Object { -not ($matchedEnrollmentIds -contains $_.id) })
$summary.db_enrollments_2026_with_cheques_not_in_csv = $dbOnly.Count

foreach ($enrollment in ($dbOnly | Select-Object -First 25)) {
  Add-Sample $samples.db_only ([pscustomobject]@{
    enrollment_id = $enrollment.id
    guardian_run = $enrollment.guardian_run_key
    students = ($enrollment.students | ForEach-Object { $_.whole_name }) -join ' | '
    cheques_db = $enrollment.cheques.Count
    bancos_db = (($enrollment.cheques | ForEach-Object { $_.banco } | Sort-Object -Unique) -join ' | ')
  })
}

$statusBreakdown = $analysis | Group-Object status | Sort-Object Count -Descending | ForEach-Object {
  [pscustomobject]@{
    status = $_.Name
    count = $_.Count
  }
}

$report = [ordered]@{
  generated_at = (Get-Date).ToString('s')
  source_file = 'update_cheques.csv'
  summary = $summary
  status_breakdown = $statusBreakdown
  samples = $samples
  details = $analysis
}

$reportPath = '.\tmp_update_cheques_report_20260316.json'
$report | ConvertTo-Json -Depth 8 | Out-File -FilePath $reportPath -Encoding utf8

Write-Host '=== REPORTE UPDATE_CHEQUES VS BD ==='
$summary.GetEnumerator() | ForEach-Object {
  Write-Host ("{0}: {1}" -f $_.Key, $_.Value)
}
Write-Host ''
Write-Host 'status_breakdown:'
$statusBreakdown | ForEach-Object {
  Write-Host ("- {0}: {1}" -f $_.status, $_.count)
}
Write-Host ''
Write-Host ("reporte_json: {0}" -f $reportPath)