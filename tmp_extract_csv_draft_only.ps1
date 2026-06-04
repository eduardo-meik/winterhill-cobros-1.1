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

$csvRuns = @{}
Import-Csv -Path .\update_20260316.csv | ForEach-Object {
  $key = Normalize-Run $_.run_numero $_.run_verificador
  if ($key) { $csvRuns[$key] = $true }
}

$students = Get-AllRows 'students' 'id,run,run_numero,run_verificador,whole_name'
$enrollments = Get-AllRows 'enrollments' 'id,year,status,guardian_id,created_at'
$enrollmentStudents = Get-AllRows 'enrollment_students' 'enrollment_id,student_id'

$studentByRun = @{}
foreach ($s in $students) {
  $key = Normalize-Run $s.run_numero $s.run_verificador
  if (-not $key) {
    $runText = [string]$s.run
    if ($runText -match '^\s*([0-9\.]+)-([0-9Kk])\s*$') {
      $key = Normalize-Run $Matches[1] $Matches[2]
    }
  }
  if ($key) { $studentByRun[$key] = $s }
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

$results = New-Object System.Collections.ArrayList
foreach ($runKey in $csvRuns.Keys) {
  $student = $studentByRun[$runKey]
  if (-not $student) { continue }
  $rels = @($enrollmentByStudent[$student.id])
  $enroll2026 = @($rels | Where-Object { $_.year -eq 2026 })
  if ($enroll2026.Count -eq 0) { continue }
  $hasCompleted = @($enroll2026 | Where-Object { $_.status -eq 'completed' }).Count -gt 0
  if (-not $hasCompleted) {
    foreach ($e in ($enroll2026 | Where-Object { $_.status -eq 'draft' })) {
      [void]$results.Add([pscustomobject]@{
        run = $runKey
        nombre = $student.whole_name
        enrollment_id = $e.id
        guardian_id = $e.guardian_id
        status = $e.status
        created_at = $e.created_at
      })
    }
  }
}

$results | Sort-Object run, created_at | ConvertTo-Json -Depth 4