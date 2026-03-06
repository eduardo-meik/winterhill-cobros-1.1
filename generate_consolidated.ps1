#!/usr/bin/env pwsh
# Script to generate a consolidated SQL migration file
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$baseDir = 'C:\Meik_Apps\winterhill-cobros-1.1'
$migrationsDir = Join-Path $baseDir 'supabase\migrations'
$outputFile = Join-Path $baseDir 'sql\consolidated_migrations.sql'

# Ensure output directory exists
$outputDir = Split-Path $outputFile
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

# Get pending migration files in order
$files = Get-ChildItem "$migrationsDir\*.sql" |
    Where-Object { $_.Name -match '^(20250515|20250529|20250726|20250805|2025092[45]|202510|202511|202512|20260)' } |
    Sort-Object Name

Write-Host "Found $($files.Count) migration files"

# Build consolidated content
$sb = [System.Text.StringBuilder]::new()

[void]$sb.AppendLine("-- ============================================================================")
[void]$sb.AppendLine("-- CONSOLIDATED MIGRATION FILE")
[void]$sb.AppendLine("-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("-- Project: winterhill-cobros (yeotpplgerfpxviqazrn)")
[void]$sb.AppendLine("-- Contains: $($files.Count) pending local-only migrations")
[void]$sb.AppendLine("-- ")
[void]$sb.AppendLine("-- WARNING: This file is very large. For Supabase SQL Editor,")
[void]$sb.AppendLine("-- you may need to execute migrations in batches.")
[void]$sb.AppendLine("-- See the batch markers below.")
[void]$sb.AppendLine("-- ============================================================================")
[void]$sb.AppendLine("")

$batchNum = 1
$batchSize = 10
$fileIndex = 0

foreach ($f in $files) {
    $fileIndex++
    if (($fileIndex - 1) % $batchSize -eq 0) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("-- ######################################################################")
        [void]$sb.AppendLine("-- BATCH $batchNum (migrations $fileIndex to $([Math]::Min($fileIndex + $batchSize - 1, $files.Count)))")
        [void]$sb.AppendLine("-- ######################################################################")
        [void]$sb.AppendLine("")
        $batchNum++
    }

    $name = $f.Name -replace '\.sql$', ''
    $content = [System.IO.File]::ReadAllText($f.FullName)

    [void]$sb.AppendLine("-- ████████████████████████████████████████████████████████████████████████████")
    [void]$sb.AppendLine("-- [$fileIndex/49] MIGRATION: $name")
    [void]$sb.AppendLine("-- ████████████████████████████████████████████████████████████████████████████")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine($content)
    [void]$sb.AppendLine("")
}

# Add migration history inserts
[void]$sb.AppendLine("")
[void]$sb.AppendLine("-- ████████████████████████████████████████████████████████████████████████████")
[void]$sb.AppendLine("-- REGISTER MIGRATIONS IN HISTORY TABLE")
[void]$sb.AppendLine("-- Run this AFTER all migrations above succeed.")
[void]$sb.AppendLine("-- This keeps supabase_migrations.schema_migrations in sync with CLI.")
[void]$sb.AppendLine("-- ████████████████████████████████████████████████████████████████████████████")
[void]$sb.AppendLine("")

foreach ($f in $files) {
    $ts = $f.Name -replace '_.*$', ''
    $name = $f.Name -replace '\.sql$', ''
    [void]$sb.AppendLine("INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('$ts', '$name', '{}') ON CONFLICT DO NOTHING;")
}

# Write output
[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)

$info = Get-Item $outputFile
Write-Host "SUCCESS: $outputFile"
Write-Host "Size: $([Math]::Round($info.Length / 1024)) KB"
Write-Host "Lines: $($sb.ToString().Split("`n").Count)"
