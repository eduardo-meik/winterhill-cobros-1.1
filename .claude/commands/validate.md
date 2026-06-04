# Winterhill Cobros – Ultimate Validation Command

> Run everything from the repository root in **PowerShell 7+** on Windows. The command below is intentionally verbose so every failure is obvious. Stop immediately on any error and investigate before proceeding to the next phase.

```powershell
#requires -Version 7.3
$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════" -ForegroundColor Cyan
Write-Host " PHASE 0 – ENVIRONMENT BOOTSTRAP" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════" -ForegroundColor Cyan

# 0.1 Install dependencies with a clean node_modules folder
if (Test-Path node_modules) { Remove-Item node_modules -Recurse -Force }
npm ci

# 0.2 Prepare an isolated env file pointing to the local Supabase stack
Copy-Item .env.example .env.validation -Force

(Get-Content .env.validation) |
  ForEach-Object {
    $_ -replace 'VITE_SUPABASE_URL=your-project-url', 'VITE_SUPABASE_URL=http://127.0.0.1:54321' |
        -replace 'VITE_SUPABASE_ANON_KEY=your-anon-key', 'VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.local-dev-anon-key' |
        -replace 'VITE_GOOGLE_CLIENT_ID=your-google-client-id', 'VITE_GOOGLE_CLIENT_ID=test-google-client-id' |
        -replace 'VITE_SITE_URL=http://localhost:5173', 'VITE_SITE_URL=http://localhost:4173'
  } |
  Set-Content .env.validation

$env:VITE_SUPABASE_URL = 'http://127.0.0.1:54321'
$env:VITE_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.local-dev-anon-key'
$env:VITE_GOOGLE_CLIENT_ID = 'test-google-client-id'
$env:VITE_SITE_URL = 'http://localhost:4173'
$env:VITE_PDF_ENGINE = 'browser'

# 0.3 Ensure Supabase CLI is available
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
  throw 'Supabase CLI is required. Install it via scoop, npm, or the official installer before continuing.'
}

# 0.4 Start the local Supabase stack (Postgres + REST + Auth)
Write-Host "Starting Supabase containers (this can take ~1 minute)..." -ForegroundColor Yellow
supabase stop --force | Out-Null
supabase start --debug | Out-String | Write-Verbose

# 0.5 Reset DB to a pristine state (applies all migrations under supabase/migrations)
supabase db reset --force

# 0.6 Output connection hints for later manual SQL verification
$sbStatus = supabase status --json | ConvertFrom-Json
$env:SUPABASE_DB_URL = $sbStatus.services.db.connectionString
Write-Host "Supabase DB URL: $($env:SUPABASE_DB_URL)" -ForegroundColor DarkCyan

Write-Host "═══════════════════════════════════" -ForegroundColor Green
Write-Host " PHASE 1 – TYPE CHECKING" -ForegroundColor Green
Write-Host "═══════════════════════════════════" -ForegroundColor Green
npx tsc --noEmit --pretty

Write-Host "═══════════════════════════════════" -ForegroundColor Green
Write-Host " PHASE 2 – UNIT TESTS" -ForegroundColor Green
Write-Host "═══════════════════════════════════" -ForegroundColor Green
npm test -- --runInBand --detectOpenHandles

Write-Host "═══════════════════════════════════" -ForegroundColor Magenta
Write-Host " PHASE 3 – USER WORKFLOWS (E2E DRILLS)" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════" -ForegroundColor Magenta

Write-Host "Launching Vite dev server on port 4173..." -ForegroundColor Yellow
$DevServer = Start-Job -ScriptBlock { npm run dev -- --host 127.0.0.1 --port 4173 }
Start-Sleep -Seconds 8

Write-Host "Open a Chromium browser (Edge/Chrome) with the .env.validation context and perform the workflows below." -ForegroundColor Yellow
Write-Host "Use the seeded credentials stored in supabase auth (email: admin@winterhill.test / pass: Winterhill!123)." -ForegroundColor Yellow

Write-Host "--- Workflow A: Admin + Asistente Onboarding & Payment Reconciliation ---" -ForegroundColor White
Write-Host "1. Sign in as admin@winterhill.test -> verify dashboard KPIs render (morosidad, vencidos)." -ForegroundColor Gray
Write-Host "2. Navigate to Estudiantes > Nuevo, create a student per ADMIN_STUDENT_REGISTRATION_CHECKLIST.md." -ForegroundColor Gray
Write-Host "3. Navigate to Apoderados > Nuevo, link the student and complete intake per MANUAL_USUARIO_PLATAFORMA §4." -ForegroundColor Gray
Write-Host "4. Go to Pagos > Registrar Pago, log an installment payment. Confirm FeeTable + PaymentDetailsModal update instantly." -ForegroundColor Gray
Write-Host "5. Run SQL sanity checks:" -ForegroundColor Gray
Write-Host "   psql $env:SUPABASE_DB_URL -c 'select whole_name, status from students order by updated_at desc limit 3;'" -ForegroundColor DarkGray
Write-Host "   psql $env:SUPABASE_DB_URL -c 'select guardian_id, student_id from student_guardian order by created_at desc limit 3;'" -ForegroundColor DarkGray
Write-Host "   psql $env:SUPABASE_DB_URL -c 'select student_id, amount, status from fee order by updated_at desc limit 3;'" -ForegroundColor DarkGray

Write-Host "--- Workflow B: Matricula Wizard + Pagare PDF ---" -ForegroundColor White
Write-Host "1. From the same session open Matricula > Wizard." -ForegroundColor Gray
Write-Host "2. Execute the three-step flow described in WORKFLOW_UPDATE_SUMMARY.md: select students, define economic data, generate preview." -ForegroundColor Gray
Write-Host "3. Download the PDF and verify the rules from MEJORAS_PDF_PAGARE_V2.md (logo, folio, margins, tables not split)." -ForegroundColor Gray
Write-Host "4. Validate html2canvas fallback by forcing VITE_PDF_ENGINE=browser, regenerating the PDF, and ensuring no errors surface in the devtools console." -ForegroundColor Gray

Write-Host "--- Workflow C: Guardian Portal Data Surfaces ---" -ForegroundColor White
Write-Host "1. Sign out admin, sign in as guardian_test@winterhill.test." -ForegroundColor Gray
Write-Host "2. The Guardian Welcome page must show AlertBanner + StatusDashboard with intake status and FeeSummary bars." -ForegroundColor Gray
Write-Host "3. Navigate to /apoderado/portal and verify:" -ForegroundColor Gray
Write-Host "   • Students tab lists all linked students (names, RUN, course)." -ForegroundColor DarkGray
Write-Host "   • Aranceles tab shows FeeTable with correct overdue color coding." -ForegroundColor DarkGray
Write-Host "   • Documentos tab exposes generated pagarés when storage is enabled." -ForegroundColor DarkGray
Write-Host "4. Force-refresh guardian data via DevTools localStorage clear, confirm GuardianContext re-fetches bootstrap data without errors." -ForegroundColor Gray

Write-Host "Once the three workflows succeed, stop the dev server job and Supabase stack." -ForegroundColor Yellow
Stop-Job $DevServer | Out-Null
supabase stop --force | Out-Null
Write-Host "Validation complete ✅" -ForegroundColor Green
```

## Notes & Rationale
- **Supabase auth seeding**: `supabase db reset` runs every SQL migration which already seeds the `admin@winterhill.test` and `guardian_test@winterhill.test` fixtures used by QA. If additional fixtures are needed, append them to `supabase/migrations/<timestamp>_qa_seed.sql`.
- **Manual verifications** are required because critical flows span UI + Supabase RLS; screenshots of each screen plus the SQL sanity queries above serve as artefacts.
- **PDF fallback** is validated manually by forcing `VITE_PDF_ENGINE=browser`, regenerating the pagaré, and confirming the browser console remains clean.

Run this file end-to-end before shipping any feature or hotfix. If any phase fails, the release is blocked until the underlying issue is resolved.

## Related References

- Security hardening and post-remediation checklist: `../../docs/SECURITY_FIXES_APPLICATION_GUIDE.md`
- Historical frontend QA audit and fixes: `../../docs/AUDIT_REPORT.md`
- Broader codebase review and cleanup findings: `../../docs/CODEBASE_REVIEW_2026-03-05.md`

Keep this file focused on executable validation. Static guidance, remediation plans, and historical audit details belong in the docs above.
