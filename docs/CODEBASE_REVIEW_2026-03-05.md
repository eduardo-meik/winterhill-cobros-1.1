# Codebase Review — Winterhill Cobros 1.1

**Date:** 2026-03-05  
**Scope:** Full codebase audit — trash code, maintainability, efficiency, UI/UX

---

## Legend

| Column | Meaning |
|--------|---------|
| **Impact** | How much this issue affects users or developers (🔴 Critical · 🟠 High · 🟡 Medium · 🟢 Low) |
| **Complexity** | Effort & risk to fix (⬛ Hard · 🔷 Medium · 🔹 Easy) |

---

## 1. Trash / Dead Code

Files and artifacts that serve no runtime purpose and pollute the repository.

| # | Issue | Location | Impact | Complexity |
|---|-------|----------|--------|------------|
| T-01 | **8 one-time Python scripts at project root.** `analyze_csv.py`, `analyze_json_enrollments.py`, `analyze_sige_2026.py`, `backup_y_ajustes_matriculas.py`, `cruce_csv_bd.py`, `cruce_sige_matriculas.py`, `detalle_discrepancias.py`, `explore_schema.py` — data migration / debug utilities that should not be committed. | Root `/` | 🟡 Medium | 🔹 Easy |
| T-02 | **`temp-script.js`** — trivial Supabase RPC test, clearly temporary. | Root `/` | 🟡 Medium | 🔹 Easy |
| T-03 | **`fix_heroicons.ipynb`** — Jupyter notebook for a one-time icon fix. | Root `/` | 🟢 Low | 🔹 Easy |
| T-04 | **4 CSV data files committed** (`cuotas_importacion.csv`, `sige_2026.csv`, `backup_matriculas_2026.csv`, `ajustes_propuestos.csv`). Contain real student/financial data — **possible data leak risk.** | Root `/` | 🟠 High | 🔹 Easy |
| T-05 | **2 PowerShell one-time scripts** (`generate_fee_import_sql.ps1`, `apply-libro-matricula-migrations.ps1`) — DB migration helpers. | Root `/` | 🟢 Low | 🔹 Easy |
| T-06 | **98 SQL files in `/sql`** — almost all are one-time diagnostic (`DIAGNOSE_*.sql` ×5), fix (`FIX_*.sql` ×15), delete (`DELETE_*.sql` ×8), and analysis scripts. None are referenced by runtime code. | `sql/` | 🟡 Medium | 🔹 Easy |
| T-07 | **88 markdown files in `/docs`** — unmaintainable sprawl. Many are duplicative (e.g., 5+ Guardian-related fix docs, 3+ performance fix docs, 2+ "FINAL" docs). Historical decision logs mixed with current requirements. | `docs/` | 🟡 Medium | 🔷 Medium |
| T-08 | **4 debug components ship in production**: `EnvTest.tsx`, `GoogleAuthDebug.tsx`, `ProductionEnvCheck.tsx`, `VercelEnvDiagnostic.tsx`. Expose environment details to end users. | `src/components/debug/` | 🔴 Critical | 🔹 Easy |
| T-09 | **`DiagnosticPage.tsx`** — full diagnostic page accessible via router, exposes system info. | `src/pages/` | 🔴 Critical | 🔹 Easy |
| T-10 | **`src/contracts/`** directory — check if duplicate of root `contratos/`. | `src/contracts/` | 🟢 Low | 🔹 Easy |

**Recommended action:** Move scripts to `/scripts/.archive/`, add CSVs to `.gitignore`, gate debug components behind `import.meta.env.DEV`, consolidate docs to 4-5 core files.

---

## 2. Unmaintainable Code

Patterns that make the codebase hard to understand, modify, or extend.

| # | Issue | Location | Impact | Complexity |
|---|-------|----------|--------|------------|
| U-01 | **325 `console.log/warn/error` statements** across `src/`. A `Logger` service exists (`src/services/logger.ts`) but is barely used. Debug emoji logging (`🔍`, `💰`, `🚫`) with user IDs and action names leaks to browser console. | `src/services/*.ts`, many components | 🟠 High | 🔷 Medium |
| U-02 | **Mixed file extensions** — 81 `.jsx`, 33 `.tsx`, 38 `.ts`, 14 `.js`. No convention enforced. Components, services, and hooks all use both JS and TS. | `src/` (project-wide) | 🟡 Medium | ⬛ Hard |
| U-03 | **`RepactacionWizard.jsx`** contains minified single-line logic (~300+ chars per line). 5 `useEffect`, 10+ `useState`, all compressed. Impossible to debug or code-review. | `src/components/repactacion/RepactacionWizard.jsx` | 🟠 High | 🔷 Medium |
| U-04 | **`ReportingPage.jsx`** — 500+ line monolith mixing report generation, export, charting, and filtering in one file. | `src/components/reporting/ReportingPage.jsx` | 🟡 Medium | ⬛ Hard |
| U-05 | **`DebtGatingBanner.jsx`** receives 14 props — extreme prop drilling. Contains 3 visual states, 2 inline forms, and business logic mixed with UI. | `src/components/matricula/steps/DebtGatingBanner.jsx` | 🟡 Medium | 🔷 Medium |
| U-06 | **Confusing directory names**: `src/components/guardian/` (11 portal UI files) vs `src/components/guardians/` (6 admin CRUD files). Nearly identical names, very different purposes. | `src/components/guardian*` | 🟡 Medium | 🔹 Easy |
| U-07 | **Duplicated guardian-fetch logic** in `matricula.ts` (`fetchCurrentGuardian`, ~40 lines) and `guardianBootstrap.ts` (~similar logic). Both query guardians → email lookup → auto-create. | `src/services/matricula.ts`, `src/services/guardianBootstrap.ts` | 🟡 Medium | 🔷 Medium |
| U-08 | **Date parsing try-catch duplicated 3×** in `PaymentDetailsModal.jsx` — identical format/fallback logic at lines ~130, ~276, ~310. | `src/components/payments/PaymentDetailsModal.jsx` | 🟢 Low | 🔹 Easy |
| U-09 | **No Error Boundaries** — if any route-level component throws, the entire app crashes to a blank screen. | `src/App.jsx` | 🟠 High | 🔷 Medium |
| U-10 | **Magic strings** for user roles scattered in code (`'ADMIN'`, `'ASIST'`, `'guardian'`) instead of single constant source. `statusLabels.ts` exists but only covers statuses, not roles everywhere. | Multiple files | 🟡 Medium | 🔷 Medium |
| U-11 | **State explosion in MatriculaWizard** — 15+ `useState` hooks across closures. Already decomposed into custom hooks (good), but each hook manages many independent states. | `src/hooks/matricula/` | 🟡 Medium | ⬛ Hard |
| U-12 | **Only 5 test files** for 100+ components/services/hooks. Near-zero coverage on critical payment, enrollment, and reporting flows. | `src/__tests__/`, `src/**/*.test.*` | 🟠 High | ⬛ Hard |

---

## 3. Inefficient Code

Performance, query, and rendering inefficiencies.

| # | Issue | Location | Impact | Complexity |
|---|-------|----------|--------|------------|
| E-01 | **No query caching / deduplication** — every page mount re-fetches data from Supabase. No SWR/React Query. Tab switches or navigation triggers full refetch. | Project-wide | 🟠 High | ⬛ Hard |
| E-02 | **3 parallel Supabase queries** in `ReportingPage` (`cursos`, `students`, `student_guardian`) that could be a single DB view or RPC. | `src/components/reporting/ReportingPage.jsx` ~L300 | 🟡 Medium | 🔷 Medium |
| E-03 | **String interpolation in `.or()` filter** — guardian search constructs filter string via template literal. PostgREST sanitizes, but pattern bypasses Supabase client type safety. | `src/components/repactacion/RepactacionWizard.jsx` ~L74 | 🟡 Medium | 🔹 Easy |
| E-04 | **No pessimistic → optimistic update** — all mutations wait for server response before UI update. Causes perceived slowness on payment registration, student edits. | Payment modals, student forms | 🟡 Medium | ⬛ Hard |
| E-05 | **Loading spinner inline code duplicated 8+ times** — identical `animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary` markup. No shared `<Spinner />` component. | Dashboard, DebtorsTable, PaymentsTable, modals | 🟢 Low | 🔹 Easy |
| E-06 | **`select('*')` used in service queries** — fetches all columns when only a subset is needed, increasing payload size. | `src/services/feeService.ts` ~L73, others | 🟢 Low | 🔹 Easy |
| E-07 | **No pagination on `ReportingPage` data fetches** — loads all students, fees, and payments at once. On large datasets this will degrade. | `src/components/reporting/ReportingPage.jsx` | 🟡 Medium | 🔷 Medium |

---

## 4. UI/UX Improvements

| # | Issue | Location | Impact | Complexity |
|---|-------|----------|--------|------------|
| X-01 | **`Button` component only handles 2 variants** (`primary`, `secondary`) but codebase uses `variant="outline"` (18+ times), `variant="destructive"` (2 times), `size="sm"`, `size="xs"` (10+ times). These props are **silently ignored** — buttons render with wrong/missing styles. | `src/components/ui/Button.jsx` | 🔴 Critical | 🔹 Easy |
| X-02 | **No empty-state component** — when tables have no data, users see a blank area or raw "No data" text. No illustration, no call-to-action. | All table components | 🟡 Medium | 🔹 Easy |
| X-03 | **No skeleton loaders** — pages show a spinner while loading, then snap to full content. No progressive/skeleton loading. | Dashboard, tables, modals | 🟡 Medium | 🔷 Medium |
| X-04 | **`DebtorsTable` has no mobile card view** — renders a fixed-width table on small screens. All other tables (`PaymentsTable`, `StudentsTable`) have responsive card layouts. | `src/components/payments/DebtorsTable.jsx` | 🟡 Medium | 🔷 Medium |
| X-05 | **Minimal accessibility** — only 1 `aria-label` found (Breadcrumbs). 50+ interactive components lack `aria-label`, `role`, or `aria-describedby`. No keyboard navigation patterns for modals/wizards. | Project-wide | 🟠 High | ⬛ Hard |
| X-06 | **Inconsistent form validation feedback** — some forms use `react-hook-form` validation, others use bare `<input>` with no error display or `required` indicators. | Payment forms, intake forms | 🟡 Medium | 🔷 Medium |
| X-07 | **Hardcoded status colors scattered** across 10+ files (`bg-green-100`, `bg-red-100`, `bg-yellow-100`). No centralized color token map. Inconsistent color usage for same statuses. | GlobalEnrollmentsTable, StatCard, PaymentsTable, etc. | 🟢 Low | 🔹 Easy |
| X-08 | **No toast/notification for background operations** — long operations (report generation, PDF creation) don't communicate progress beyond a spinner. | Reporting, contract generation | 🟡 Medium | 🔷 Medium |
| X-09 | **Error messages shown as raw technical strings** in some toasts — Supabase errors surface as-is to users (e.g., constraint violations, RLS errors). | Various service catch blocks | 🟡 Medium | 🔷 Medium |
| X-10 | **No confirmation dialogs for destructive actions** — payment deletion, student removal lack "Are you sure?" modals. | Payment actions, student management | 🟠 High | 🔷 Medium |

---

## 5. Security Concerns

| # | Issue | Location | Impact | Complexity |
|---|-------|----------|--------|------------|
| S-01 | **Debug components in production** (see T-08, T-09) — expose env vars, auth flow, deployment details. | `src/components/debug/`, `src/pages/DiagnosticPage.tsx` | 🔴 Critical | 🔹 Easy |
| S-02 | **CSV files with real student data committed to git** — `sige_2026.csv`, `backup_matriculas_2026.csv` may contain PII (names, RUTs). | Root `/` | 🔴 Critical | 🔹 Easy |
| S-03 | **Console logs expose user IDs and actions** — `permissions.ts` logs `user_id` and denied actions. `supabase.ts` logs OAuth redirect details. | `src/services/permissions.ts`, `src/services/supabase.ts` | 🟠 High | 🔹 Easy |
| S-04 | **String-interpolated query filters** — user input inserted into `.or()` filter string. PostgREST should sanitize but it's a risky pattern. | `src/components/repactacion/RepactacionWizard.jsx` ~L74 | 🟡 Medium | 🔹 Easy |

---

## 6. Summary by Priority

### 🔴 Immediate (do first)

| ID | Summary | Est. Effort |
|----|---------|-------------|
| T-08/T-09/S-01 | Remove or gate debug components & diagnostic page behind `import.meta.env.DEV` | 30 min |
| S-02/T-04 | Remove CSV data files, add to `.gitignore`, scrub from git history | 30 min |
| X-01 | Extend `Button.jsx` to support `outline`, `destructive` variants and `sm`/`xs` sizes | 30 min |
| S-03 | Remove console.log of user IDs / sensitive data in `permissions.ts`, `supabase.ts` | 20 min |

### 🟠 High Priority (next sprint)

| ID | Summary | Est. Effort |
|----|---------|-------------|
| U-01 | Replace 325 console statements with Logger service or remove | 2-3 hours |
| U-09 | Add React Error Boundary at route level | 1 hour |
| X-05 | Add aria-labels to buttons, modals, form inputs (start with critical paths) | 3-4 hours |
| X-10 | Add confirmation dialogs for destructive actions | 1-2 hours |
| E-01 | Introduce React Query / SWR for data fetching + caching | 1-2 days |

### 🟡 Medium Priority (next month)

| ID | Summary | Est. Effort |
|----|---------|-------------|
| T-01/T-02/T-05/T-06 | Move root scripts and `/sql` one-time files to `/scripts/.archive/` | 1 hour |
| T-07 | Consolidate `/docs` — keep 4-5 core files, archive the rest | 2-3 hours |
| U-03 | Reformat/unminify `RepactacionWizard.jsx` | 1-2 hours |
| U-05 | Reduce DebtGatingBanner prop count via context or state object | 1-2 hours |
| U-06 | Rename `guardian/` → `guardian-portal/` for clarity | 20 min |
| U-07 | Extract shared `useGuardianFetch()` hook from duplicated logic | 1 hour |
| X-02 | Create shared `<EmptyState />` component, apply to all tables | 1 hour |
| X-03 | Add skeleton loaders for dashboard and key tables | 2-3 hours |
| X-04 | Add mobile card view to `DebtorsTable` | 1 hour |
| X-06 | Standardize form validation with `react-hook-form` everywhere | 3-4 hours |
| X-07 | Create centralized `STATUS_COLORS` constant, replace hardcoded values | 1 hour |

### 🟢 Backlog

| ID | Summary | Est. Effort |
|----|---------|-------------|
| U-02 | Standardize all files to `.tsx`/`.ts` | Multi-day migration |
| U-04 | Decompose `ReportingPage.jsx` using composition hooks | 3-4 hours |
| U-10 | Centralize all magic strings to typed constants | 2-3 hours |
| U-11 | Reduce MatriculaWizard state via state machine (XState or useReducer) | 1-2 days |
| U-12 | Add test coverage to critical paths (target 80%) | Multi-sprint |
| E-04 | Implement optimistic updates for key mutations | 2-3 days |
| E-05 | Extract shared `<Spinner />` component | 30 min |

---

## What's Already Good

- **Lazy-loaded routes** with `React.lazy()` + `Suspense` — proper code splitting
- **MatriculaWizard decomposition** — excellently split into 5 custom hooks + step components
- **Memoized context values** in `AuthContext`, `GuardianContext` — prevents unnecessary re-renders
- **Least-privilege default** — `AuthContext` defaults to `READONLY` profile
- **Dark mode support** with Tailwind `dark:` classes
- **Paginated tables** with reusable `usePagination` hook
- **Search debouncing** across multiple pages
- **Well-structured wiki** (7 organized pages)
- **Supabase migrations** properly versioned in `/supabase/migrations/`

---

## Changes Applied

### Session 1 — Easy Fixes (2026-03-05)

| ID | Fix | Files |
|----|-----|-------|
| T-08/T-09/S-01 | Gated all debug components & DiagnosticPage behind `import.meta.env.DEV` | `src/components/debug/EnvTest.tsx`, `GoogleAuthDebug.tsx`, `ProductionEnvCheck.tsx`, `VercelEnvDiagnostic.tsx`, `src/pages/DiagnosticPage.tsx` |
| S-02/T-04 | Added `*.csv`, `temp-script.js`, `fix_heroicons.ipynb`, Python scripts to `.gitignore` | `.gitignore` |
| X-01 | Extended `Button.jsx` with `outline`, `destructive`, `ghost` variants and `sm`/`xs` sizes | `src/components/ui/Button.jsx` |
| S-03 | Removed console.log/warn that leaked userId, email, and OAuth config | `src/services/permissions.ts`, `src/services/supabase.ts` |
| U-01 (partial) | Cleaned ~35 debug console statements from core services | `src/services/matricula.ts` |
| E-05 | Created shared `<Spinner />` and `<PageSpinner />` components, integrated in App.jsx | `src/components/ui/Spinner.jsx`, `src/App.jsx` |
| X-07 | Created centralized `STATUS_COLORS` constant with `getStatusColor()` helper | `src/constants/statusColors.ts` |
| U-08 | Extracted `safeYearFromDate()` helper, replaced 3 duplicated inline try-catch blocks | `src/components/payments/PaymentDetailsModal.jsx` |
| X-02 | Created reusable `<EmptyState />` component | `src/components/ui/EmptyState.jsx` |

### Session 2 — Medium Fixes (2026-03-05)

| ID | Fix | Files |
|----|-----|-------|
| U-09 | Added `<ErrorBoundary />` class component, wrapped all lazy-loaded routes | `src/components/ui/ErrorBoundary.jsx`, `src/App.jsx` |
| X-10 | Created `<ConfirmDialog />` with Headless UI transitions, destructive/primary variants | `src/components/ui/ConfirmDialog.jsx` |
| S-04/E-03 | Sanitized user input in `.or()` filter — strips `%`, `_`, `\` before interpolation | `src/components/repactacion/RepactacionWizard.jsx` |
| U-03 | Fully reformatted RepactacionWizard.jsx — expanded compressed logic, extracted helpers | `src/components/repactacion/RepactacionWizard.jsx` |
| U-06 | Renamed `components/guardian/` → `components/guardian-portal/`, updated imports | `src/components/guardian-portal/`, `src/pages/guardian/GuardianWelcomePage.jsx`, `GuardianEnrollmentPage.jsx` |
| E-06 | Replaced `select('*')` with explicit column lists in all 3 feeService queries | `src/services/feeService.ts` |
| X-04 | Verified: `DebtorsTable` already uses a responsive card layout — no fix needed | `src/components/dashboard/DebtorsTable.jsx` |

### Session 3 — Medium-High Fixes (2026-03-06)

| ID | Fix | Files |
|----|-----|-------|
| U-10 | Created `src/constants/roles.ts` centralizing `ROLE_ADMIN`, `ROLE_ASIST`, `ROLE_GUARDIAN`, profile constants, and `isStaffRole()`/`isGuardianRole()`/`isStaffProfile()` helpers. Replaced 60+ magic string occurrences across 7 consumer files. | `src/constants/roles.ts` (new), `StaffRoute.tsx`, `App.jsx`, `RepactacionWizard.jsx`, `Dashboard.jsx`, `Sidebar.jsx`, `MainLayout.tsx`, `GuardianIntakePage.jsx` |
| U-07 | Confirmed **false positive** — `guardianBootstrap.ts` already imports `fetchCurrentGuardian` from `matricula.ts`. No actual duplication. | — |
| X-03 | Created `<Skeleton />` base + `<StatCardSkeleton />`, `<ChartSkeleton />`, `<TableSkeleton />` components. Applied to Dashboard (4 stat cards), 4 chart components, DebtorsTable. Replaces generic spinners with content-shaped loading placeholders. | `src/components/ui/Skeleton.jsx` (new), `Dashboard.jsx`, `DebtTrendChart.jsx`, `DebtDistributionChart.jsx`, `PaymentProjectionChart.jsx`, `YearComparisonChart.jsx`, `DebtorsTable.jsx` |
| U-05 | Reduced DebtGatingBanner from 14 → 11 props by consolidating 3 setter callbacks (`setDebtDoc`, `setHasRegularized`, `setRegularizationSigned`) into a single `onDebtRegularized(doc)` callback. Removed redundant `debtDoc` prop. | `src/components/matricula/steps/DebtGatingBanner.jsx`, `src/components/matricula/MatriculaWizard.jsx` |
| X-09 | Created `friendlyError()` utility with 17 regex patterns translating raw Supabase/JS errors to Spanish. Applied across 8 files covering auth, guardian, payment, and sign-in flows. | `src/utils/friendlyError.ts` (new), `AuthContext.tsx`, `GuardianContext.tsx`, `RegisterPaymentModal.jsx`, `PaymentDetailsModal.jsx`, `GuardianAcceptInvitePage.jsx`, `GuardianRegisterPage.tsx`, `GuardianClaimPage.jsx`, `supabase.ts` |
| U-01 | Console cleanup pass — removed ~30 redundant/debug/PII-leaking statements from services and components. DEV-gated 8 bootstrap warnings and 1 config warning. Files already properly DEV-gated were left as-is. | `reporting.js`, `feeService.ts`, `paymentValidation.ts`, `guardianBootstrap.ts`, `supabase.ts`, `email.ts`, `ReportingPage.jsx`, `GuardianFormModal.jsx`, `GoogleAuthButton.tsx` |

### Session 4 — Final Polish (2026-03-07)

| ID | Fix | Files |
|----|-----|-------|
| X-08 | Added `toast.loading()` with stable IDs to 10 long-running operations (export Excel/PDF, print/email receipt, finalize enrollment, promotion preview/confirm, completion email). Fixed race-condition bugs in `DebtGatingBanner` and `RepactacionWizard` where `toast.dismiss()` in `finally` blocks hid success toasts. | `ReportingPage.jsx`, `PaymentsPage.jsx`, `StudentsPage.jsx`, `PaymentDetailsModal.jsx`, `useDocumentGeneration.js`, `PromotionTool.jsx`, `DebtGatingBanner.jsx`, `RepactacionWizard.jsx`, `GuardianWelcomePage.jsx`, `GuardianEnrollmentPage.jsx` |
| X-06 | Standardized form validation: added `required` rules + asterisks to `ProfilePage` name fields, fixed wrong max validation message in `RegisterPaymentModal`, aligned error styling to `mt-1 text-sm text-red-600 dark:text-red-400` across 3 form modals. Created `FieldError.jsx` reference component. | `ProfilePage.jsx`, `RegisterPaymentModal.jsx`, `ChequeDataModal.jsx`, `ChequesDataModal.jsx`, `GuardianIntakePage.jsx`, `src/components/ui/FieldError.jsx` (new) |
| E-02 | Merged separate guardians query into existing `Promise.all` — now 4 queries run in parallel instead of 1 sequential + 3 parallel. | `ReportingPage.jsx` |
| E-07 | Investigated — `PaymentsTable` already uses `usePagination(sortedPayments, 25)`. Server-side pagination would break summary/chart/export calculations. Proper fix requires DB-level aggregation (RPC/views) — deferred. | — (no fix needed) |
| X-05 | Added `aria-label` to 15 icon-only buttons (hamburger, modal close, inline save/cancel, filter clear/remove). Added `<Dialog.Title className="sr-only">` to `MobileMenu`. Added `aria-label` to 2 standalone search inputs. | `Header.jsx`, `MobileMenu.jsx`, `GuardianFormModal.jsx`, `GuardianDetailsModal.jsx`, `PaymentDetailsModal.jsx`, `ChequeDataModal.jsx`, `ChequesDataModal.jsx`, `FinalizeEnrollmentModal.jsx`, `ReportFilters.jsx`, `PaymentsFilters.jsx`, `MatriculaWizard.jsx` |

### Session 5 — Decompose ReportingPage + MatriculaWizard State + React Query (2026-03-07)

| ID | Fix | Files |
|----|-----|-------|
| U-04 | Decomposed ~1 100-line `ReportingPage.jsx` monolith into a thin ~250-line composition shell + two custom hooks. `useReportData` (~290 lines) owns all state, Supabase fetching, `filteredData`/`guardianDebtMap` memos, and filter handlers. `useReportExport` (~240 lines) owns all export logic (Excel/PDF/Libro/FICON/Cheques) with shared `triggerDownload` helper and consolidated chart-capture loop. Original JSX preserved intact. | `src/hooks/reporting/useReportData.js` (new), `src/hooks/reporting/useReportExport.js` (new), `ReportingPage.jsx` (rewritten) |
| U-11 | Reduced MatriculaWizard state overhead: (1) converted `paymentPlan` from `useState+useEffect` → `useMemo` (eliminates extra render cycle — plan now derived synchronously from `aggregatedEconomicTotals + paymentMethod`); (2) converted `hydratedMetaForEnrollmentId` from `useState` → `useRef` (guard flag never rendered, avoids unnecessary re-render on hydration); (3) removed dead no-op `useEffect` in MatriculaWizard.jsx. Net: −2 `useState`, −2 `useEffect`, +1 `useMemo`, +1 `useRef`. | `useEconomicData.js`, `MatriculaWizard.jsx` |
| E-01 | Introduced `@tanstack/react-query` for data caching & deduplication. Created `QueryClientProvider` in `App.jsx` (staleTime 2 min, gcTime 10 min, retry 1). Created shared `useFeesQuery(academicYear)` hook with query key `['fees', year]` and a "wide" select that covers all dashboard consumers. Converted 6 components (`Dashboard`, `DebtorsTable`, `YearComparisonChart`, `DebtTrendChart`, `DebtDistributionChart`, `PaymentProjectionChart`) from direct `supabase.from('fee')` calls to the shared hook — reducing 7 parallel network requests (6 current-year + 1 prev-year in YearComparison) to at most 2 (current + previous year), fully cache-deduplicated. Removed manual `useState`/`useEffect` fetch cycles, replaced with `useMemo` derivations from cached data. Dashboard's MJ-04 visibility auto-refresh now uses `refetchOnWindowFocus: 'always'` instead of manual `visibilitychange` listener. | `App.jsx`, `src/hooks/queries/useFeesQuery.js` (new), `Dashboard.jsx`, `DebtorsTable.jsx`, `YearComparisonChart.jsx`, `DebtTrendChart.jsx`, `DebtDistributionChart.jsx`, `PaymentProjectionChart.jsx` |

### Session 6 — React Query Expansion + Cache Invalidation (2026-03-06)

| ID | Fix | Files |
|----|-----|-------|
| E-01 (ext.) | Created `useStudentsQuery` and `useCursosQuery` shared React Query hooks (wide select, auto-cached). Converted `StudentSelect` (payment form dropdown) to `useStudentsQuery` — eliminates manual `useState`/`useEffect` fetch. Converted `StudentFormModal` curso dropdown to `useCursosQuery` — eliminates manual `useState`/`useEffect` fetch. Students and cursos data now cache-shared across all consumers using these hooks. | `src/hooks/queries/useStudentsQuery.js` (new), `src/hooks/queries/useCursosQuery.js` (new), `StudentSelect.jsx`, `StudentFormModal.jsx` |
| E-04 (partial) | Added fee cache invalidation (`queryClient.invalidateQueries(['fees'])`) to all 5 fee mutation sites across `RegisterPaymentModal` (2 paths: update existing + insert new) and `PaymentDetailsModal` (3: save, delete, registerPay). Dashboard/charts now auto-refresh when payments are registered, edited, or deleted on the PaymentsPage — eliminates stale data across page navigations. | `RegisterPaymentModal.jsx`, `PaymentDetailsModal.jsx` |

### Remaining Items

Fixes **not yet applied** — still in the backlog:

- **U-02**: Mixed .jsx/.tsx file extensions — requires multi-day migration
- **U-12**: Test coverage for critical paths
- **E-04** (remaining): Full optimistic updates with `useMutation` + rollback (requires converting PaymentsPage to React Query first)
