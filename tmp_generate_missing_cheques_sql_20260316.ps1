$ErrorActionPreference = 'Stop'

function Get-EnvMap {
  $map = @{}
  Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
    $parts = $_ -split '=', 2
    if ($parts.Length -eq 2) {
      $map[$parts[0].Trim()] = $parts[1].Trim().Trim('"')
    }
  }
  return $map
}

function Get-AllRows {
  param(
    [string]$BaseUrl,
    [hashtable]$Headers,
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
      '{0}={1}' -f [uri]::EscapeDataString([string]$key), [uri]::EscapeDataString([string]$query[$key])
    }

    $uri = '{0}/rest/v1/{1}?{2}' -f $BaseUrl, $Endpoint, ($pairs -join '&')
    $rows = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Get

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
  $builder = New-Object System.Text.StringBuilder

  foreach ($ch in $norm.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$builder.Append($ch)
    }
  }

  return (($builder.ToString().ToUpperInvariant() -replace '[^A-Z0-9 ]', ' ' -replace '\s+', ' ').Trim())
}

function Parse-Count([object]$Value) {
  if ($null -eq $Value) { return $null }
  $text = Normalize-Text $Value
  if ($text -match '(\d+)') {
    return [int]$Matches[1]
  }
  return $null
}

function Parse-Money([object]$Value) {
  if ($null -eq $Value) { return $null }
  $text = ([string]$Value).Trim()
  if (-not $text) { return $null }
  $digits = $text -replace '[^0-9-]', ''
  if (-not $digits) { return $null }
  return [int]$digits
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

function Convert-BankName([string]$Value) {
  $key = Normalize-Text $Value
  switch ($key) {
    'CHILE' { return 'Banco de Chile' }
    'BANCO DE CHILE' { return 'Banco de Chile' }
    'ESTADO' { return 'BancoEstado' }
    'BANCOESTADO' { return 'BancoEstado' }
    'SANTANDER' { return 'Santander' }
    'SCOTIABANK' { return 'Scotiabank' }
    'SECURITY' { return 'Security' }
    'BCI' { return 'BCI' }
    'FALABELLA' { return 'Falabella' }
    'ITAU' { return 'Itaú' }
    default {
      if (-not $Value) { return '' }
      return ([string]$Value).Trim()
    }
  }
}

function Escape-Sql([string]$Value) {
  if ($null -eq $Value) { return 'NULL' }
  return '''{0}''' -f ($Value -replace '''', '''''')
}

function Escape-SqlUuid([string]$Value) {
  if (-not $Value) { return 'NULL' }
  return '''{0}''::uuid' -f $Value
}

function Expand-BasicSeriesParts([string[]]$Tokens) {
  if ($Tokens.Count -eq 0) { return @() }

  $first = $Tokens[0]
  $parts = @($first)

  for ($index = 1; $index -lt $Tokens.Count; $index++) {
    $token = $Tokens[$index]
    if ($token.Length -lt $first.Length) {
      $prefix = $first.Substring(0, $first.Length - $token.Length)
      $parts += ($prefix + $token)
    }
    else {
      $parts += $token
    }
  }

  return $parts
}

function Expand-EvenChunks([string]$Token) {
  $chunks = @()
  for ($index = 0; $index -lt $Token.Length; $index += 2) {
    $chunks += $Token.Substring($index, 2)
  }
  return $chunks
}

function Resolve-Series {
  param(
    [string]$RawSeries,
    [int]$ExpectedCount,
    [string]$Folio
  )

  $result = [ordered]@{
    serials = @()
    mode = 'unresolved'
    issues = @()
    raw = $RawSeries
  }

  if ($ExpectedCount -le 0) {
    $result.issues += 'expected_count_invalid'
    return [pscustomobject]$result
  }

  $tokens = @()
  if ($RawSeries) {
    foreach ($part in ($RawSeries -split '-')) {
      $digits = ($part -replace '[^0-9]', '')
      if ($digits) {
        $tokens += $digits
      }
    }
  }

  if ($tokens.Count -gt 0) {
    $basic = Expand-BasicSeriesParts $tokens
    if ($basic.Count -eq $ExpectedCount) {
      $result.serials = $basic
      $result.mode = 'parsed_basic'
      return [pscustomobject]$result
    }

    $evenSplitTokens = @($tokens[0])
    for ($index = 1; $index -lt $tokens.Count; $index++) {
      $token = $tokens[$index]
      if ($token.Length -gt 3 -and ($token.Length % 2) -eq 0) {
        $evenSplitTokens += Expand-EvenChunks $token
      }
      else {
        $evenSplitTokens += $token
      }
    }

    $evenSplit = Expand-BasicSeriesParts $evenSplitTokens
    if ($evenSplit.Count -eq $ExpectedCount) {
      $result.serials = $evenSplit
      $result.mode = 'parsed_even_chunks'
      $result.issues += 'raw_series_required_chunk_split'
      return [pscustomobject]$result
    }

    $result.issues += ('series_count_mismatch:{0}->{1}' -f $basic.Count, $ExpectedCount)
  }
  else {
    $result.issues += 'series_without_digits'
  }

  $folioKey = $Folio
  if (-not $folioKey) { $folioKey = 'SIN-FOLIO' }
  $folioKey = $folioKey -replace '[^A-Za-z0-9]', ''
  if (-not $folioKey) { $folioKey = 'SIN_FOLIO' }

  $placeholders = @()
  for ($cuota = 1; $cuota -le $ExpectedCount; $cuota++) {
    $placeholders += ('PEND-{0}-{1}' -f $folioKey, $cuota.ToString('00'))
  }

  $result.serials = $placeholders
  $result.mode = 'placeholder'
  $result.issues += 'placeholder_serials_generated'
  return [pscustomobject]$result
}

function Get-CuotasFromMeta {
  param(
    $EnrollmentMeta,
    [int]$ExpectedCount
  )

  $rows = @()
  $paymentPlan = $null
  if ($EnrollmentMeta -and $EnrollmentMeta.payment_plan) {
    $paymentPlan = $EnrollmentMeta.payment_plan
  }

  if ($paymentPlan -and $paymentPlan.cuotas) {
    $ordered = @($paymentPlan.cuotas | Sort-Object numero)
    foreach ($cuota in ($ordered | Select-Object -First $ExpectedCount)) {
      $rows += [pscustomobject]@{
        numero = [int]$cuota.numero
        due_date = ([datetime]$cuota.due_date).ToString('yyyy-MM-dd')
      }
    }
  }

  if ($rows.Count -eq $ExpectedCount) {
    return $rows
  }

  $fallback = @()
  $baseDate = Get-Date '2026-03-05'
  for ($index = 0; $index -lt $ExpectedCount; $index++) {
    $fallback += [pscustomobject]@{
      numero = $index + 1
      due_date = $baseDate.AddMonths($index).ToString('yyyy-MM-dd')
    }
  }

  return $fallback
}

$envMap = Get-EnvMap
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

$csvRows = Import-Csv -Path .\update_cheques.csv
$report = Get-Content .\tmp_update_cheques_report_20260316.json -Raw | ConvertFrom-Json
$missingDetails = @($report.details | Where-Object { $_.enrollment_id -and $_.cheques_db -eq 0 })

if ($missingDetails.Count -eq 0) {
  throw 'No hay enrollments faltantes en tmp_update_cheques_report_20260316.json'
}

$enrollments = Get-AllRows -BaseUrl $baseUrl -Headers $headers -Endpoint 'enrollments' -Select 'id,meta,year,status' -Filters @{ year = 'eq.2026' }
$enrollmentById = @{}
foreach ($enrollment in $enrollments) {
  $enrollmentById[$enrollment.id] = $enrollment
}

$groups = $missingDetails | Group-Object enrollment_id | Sort-Object Name

$sqlLines = New-Object System.Collections.Generic.List[string]
$summary = New-Object System.Collections.ArrayList
$placeholderGroups = New-Object System.Collections.ArrayList
$conflictGroups = New-Object System.Collections.ArrayList

[void]$sqlLines.Add('-- SQL generado automaticamente desde update_cheques.csv y tmp_update_cheques_report_20260316.json')
[void]$sqlLines.Add('-- Inserta cheques faltantes para enrollments 2026 con pago en cheque y sin registros en public.cheques')
[void]$sqlLines.Add('begin;')
[void]$sqlLines.Add('')

foreach ($group in $groups) {
  $enrollmentId = $group.Name
  if (-not $enrollmentById.ContainsKey($enrollmentId)) {
    [void]$conflictGroups.Add([pscustomobject]@{
      enrollment_id = $enrollmentId
      issue = 'enrollment_not_found'
    })
    continue
  }

  $details = @($group.Group | Sort-Object row)
  $rowNumbers = @($details | ForEach-Object { [int]$_.row })
  $matchedStudents = @($details | ForEach-Object { [string]$_.matched_student } | Where-Object { $_ } | Sort-Object -Unique)
  $sourceRows = @()
  foreach ($detail in $details) {
    $csvIndex = [int]$detail.row - 2
    if ($csvIndex -lt 0 -or $csvIndex -ge $csvRows.Count) {
      continue
    }
    $sourceRows += $csvRows[$csvIndex]
  }

  if ($sourceRows.Count -eq 0) {
    [void]$conflictGroups.Add([pscustomobject]@{
      enrollment_id = $enrollmentId
      issue = 'csv_rows_not_found'
      rows = ($rowNumbers -join ', ')
    })
    continue
  }

  $bankKeys = @($sourceRows | ForEach-Object { Normalize-Text (Get-RowValue $_ @('BANCO')) } | Where-Object { $_ } | Sort-Object -Unique)
  $countKeys = @($sourceRows | ForEach-Object { Parse-Count (Get-RowValue $_ @('CHEQUES')) } | Where-Object { $null -ne $_ } | Sort-Object -Unique)
  $amountKeys = @($sourceRows | ForEach-Object { Parse-Money (Get-RowValue $_ @('VALOR')) } | Where-Object { $null -ne $_ } | Sort-Object -Unique)
  $seriesKeys = @($sourceRows | ForEach-Object { ((Get-RowValue $_ @('NUMERO DE SERIE')).Trim()) } | Where-Object { $_ } | Sort-Object -Unique)

  if ($bankKeys.Count -gt 1 -or $countKeys.Count -gt 1 -or $amountKeys.Count -gt 1 -or $seriesKeys.Count -gt 1) {
    [void]$conflictGroups.Add([pscustomobject]@{
      enrollment_id = $enrollmentId
      issue = 'conflicting_csv_values'
      rows = ($rowNumbers -join ', ')
      banks = ($bankKeys -join ' | ')
      counts = ($countKeys -join ' | ')
      amounts = ($amountKeys -join ' | ')
      series = ($seriesKeys -join ' | ')
    })
    continue
  }

  $csvRow = $sourceRows[0]
  $csvCount = Parse-Count (Get-RowValue $csvRow @('CHEQUES'))
  $csvAmount = Parse-Money (Get-RowValue $csvRow @('VALOR'))
  $bankValue = Convert-BankName (Get-RowValue $csvRow @('BANCO'))
  $seriesRaw = (Get-RowValue $csvRow @('NUMERO DE SERIE')).Trim()
  $enrollment = $enrollmentById[$enrollmentId]
  $folio = ''
  $createdBy = $null

  if ($enrollment.meta) {
    if ($enrollment.meta.folio) {
      $folio = [string]$enrollment.meta.folio
    }
    if ($enrollment.meta.assisted_by_user_id) {
      $createdBy = [string]$enrollment.meta.assisted_by_user_id
    }
  }

  if (-not $csvCount) {
    $csvCount = [int]$details[0].cheques_csv
  }

  if (-not $csvAmount) {
    $csvAmount = [int]$details[0].valor_csv
  }

  $seriesInfo = Resolve-Series -RawSeries $seriesRaw -ExpectedCount $csvCount -Folio $folio
  $cuotas = Get-CuotasFromMeta -EnrollmentMeta $enrollment.meta -ExpectedCount $csvCount
  $studentsLabel = $matchedStudents -join ' | '
  $folioLabel = if ($folio) { $folio } else { 'SIN_FOLIO' }
  $notes = 'Carga inicial desde update_cheques.csv fila(s) {0}; alumnos: {1}; series_csv: {2}; parse_mode: {3}' -f ($rowNumbers -join ', '), $studentsLabel, $seriesRaw, $seriesInfo.mode
  if ($seriesInfo.issues.Count -gt 0) {
    $notes = '{0}; issues: {1}' -f $notes, ($seriesInfo.issues -join ', ')
  }

  $headerLine = '-- enrollment_id: {0} | folio: {1} | filas CSV: {2}' -f $enrollmentId, $folioLabel, ($rowNumbers -join ', ')
  $studentsLine = '-- alumnos: {0}' -f $studentsLabel
  [void]$sqlLines.Add($headerLine)
  [void]$sqlLines.Add($studentsLine)

  for ($index = 0; $index -lt $csvCount; $index++) {
    $cuota = $cuotas[$index]
    $serial = [string]$seriesInfo.serials[$index]
    $date = [string]$cuota.due_date
    $numeroCuota = [int]$cuota.numero
    $insertLine = 'select {0}, {1}, {2}, {3}::date, {4}, ''pendiente'', {5}, {6}, {7}, {8}' -f (Escape-SqlUuid $enrollmentId), (Escape-Sql $serial), (Escape-Sql $bankValue), (Escape-Sql $date), $csvAmount, (Escape-Sql $notes), (Escape-SqlUuid $createdBy), $numeroCuota, (Escape-Sql $folio)
    $enrollmentMatchLine = '  where c.enrollment_id = {0}' -f (Escape-SqlUuid $enrollmentId)
    $cuotaMatchLine = '    and c.numero_cuota = {0}' -f $numeroCuota

    [void]$sqlLines.Add('insert into public.cheques (enrollment_id, numero_serie, banco, fecha_emision, monto, estado, notas, created_by, numero_cuota, folio_number)')
    [void]$sqlLines.Add($insertLine)
    [void]$sqlLines.Add('where not exists (')
    [void]$sqlLines.Add('  select 1')
    [void]$sqlLines.Add('  from public.cheques c')
    [void]$sqlLines.Add($enrollmentMatchLine)
    [void]$sqlLines.Add($cuotaMatchLine)
    [void]$sqlLines.Add(');')
    [void]$sqlLines.Add('')
  }

  if ($seriesInfo.mode -eq 'placeholder') {
    [void]$placeholderGroups.Add([pscustomobject]@{
      enrollment_id = $enrollmentId
      folio = $folio
      rows = ($rowNumbers -join ', ')
      students = $studentsLabel
      series_csv = $seriesRaw
      issues = ($seriesInfo.issues -join ', ')
    })
  }

  [void]$summary.Add([pscustomobject]@{
    enrollment_id = $enrollmentId
    folio = $folio
    rows = $rowNumbers
    students = $matchedStudents
    cheques = $csvCount
    amount = $csvAmount
    bank = $bankValue
    parse_mode = $seriesInfo.mode
    created_by = $createdBy
  })
}

[void]$sqlLines.Add('commit;')

$sqlPath = '.\tmp_insert_missing_cheques_20260316.sql'
$summaryPath = '.\tmp_insert_missing_cheques_20260316_summary.json'
$reviewPath = '.\tmp_insert_missing_cheques_20260316_review.md'

$sqlLines | Set-Content -Path $sqlPath -Encoding utf8

$summaryPayload = [ordered]@{
  generated_at = (Get-Date).ToString('s')
  source_csv = 'update_cheques.csv'
  source_report = 'tmp_update_cheques_report_20260316.json'
  unique_missing_enrollments = $groups.Count
  generated_enrollments = $summary.Count
  generated_cheques = ($summary | Measure-Object cheques -Sum).Sum
  placeholder_enrollments = $placeholderGroups.Count
  skipped_enrollments = $conflictGroups.Count
  generated = $summary
  placeholders = $placeholderGroups
  skipped = $conflictGroups
}

$summaryPayload | ConvertTo-Json -Depth 8 | Set-Content -Path $summaryPath -Encoding utf8

$reviewLines = New-Object System.Collections.Generic.List[string]
[void]$reviewLines.Add('# Carga propuesta de cheques faltantes 2026')
[void]$reviewLines.Add('')
[void]$reviewLines.Add(('- Enrollments faltantes detectados: {0}' -f $groups.Count))
[void]$reviewLines.Add(('- Enrollments con SQL generado: {0}' -f $summary.Count))
[void]$reviewLines.Add(('- Cheques a insertar: {0}' -f (($summary | Measure-Object cheques -Sum).Sum)))
[void]$reviewLines.Add(('- Enrollments con series placeholder: {0}' -f $placeholderGroups.Count))
[void]$reviewLines.Add(('- Enrollments omitidos por conflicto: {0}' -f $conflictGroups.Count))
[void]$reviewLines.Add('')

if ($placeholderGroups.Count -gt 0) {
  [void]$reviewLines.Add('## Placeholders requeridos')
  [void]$reviewLines.Add('')
  foreach ($item in $placeholderGroups) {
    [void]$reviewLines.Add(('- {0} | {1} | filas {2} | {3}' -f $item.enrollment_id, $(if ($item.folio) { $item.folio } else { 'SIN_FOLIO' }), $item.rows, $item.students))
    [void]$reviewLines.Add(('  - series_csv: {0}' -f $item.series_csv))
    [void]$reviewLines.Add(('  - issues: {0}' -f $item.issues))
  }
  [void]$reviewLines.Add('')
}

if ($conflictGroups.Count -gt 0) {
  [void]$reviewLines.Add('## Enrollments omitidos')
  [void]$reviewLines.Add('')
  foreach ($item in $conflictGroups) {
    [void]$reviewLines.Add(('- {0} | issue: {1} | filas {2}' -f $item.enrollment_id, $item.issue, $item.rows))
  }
  [void]$reviewLines.Add('')
}

[void]$reviewLines.Add('## Archivos')
[void]$reviewLines.Add('')
[void]$reviewLines.Add('- tmp_insert_missing_cheques_20260316.sql')
[void]$reviewLines.Add('- tmp_insert_missing_cheques_20260316_summary.json')

$reviewLines | Set-Content -Path $reviewPath -Encoding utf8

Write-Host ('Enrollments faltantes: {0}' -f $groups.Count)
Write-Host ('Enrollments con SQL generado: {0}' -f $summary.Count)
Write-Host ('Cheques a insertar: {0}' -f (($summary | Measure-Object cheques -Sum).Sum))
Write-Host ('Enrollments con placeholder: {0}' -f $placeholderGroups.Count)
Write-Host ('Enrollments omitidos: {0}' -f $conflictGroups.Count)
Write-Host ('SQL: {0}' -f $sqlPath)
Write-Host ('Resumen: {0}' -f $summaryPath)
Write-Host ('Revision: {0}' -f $reviewPath)