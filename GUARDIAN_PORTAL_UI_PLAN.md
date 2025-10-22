# Guardian Portal UI Enhancement Plan

## Current State Analysis
✅ **Working Features:**
- Guardian intake form (save/submit working)
- Basic welcome page with:
  - Guardian data display
  - Student list (via student_guardian links)
  - Fee totals (paid/pending/overdue aggregates)
  - Enrollment status
  - Quick actions menu

❌ **Missing/Needs Improvement:**
- No visual status indicators for intake completion
- Limited payment details (only aggregates)
- No detailed fee breakdown by student
- No payment history
- No messaging system for pending tasks
- No student detail pages

---

## Enhancement Plan

### Phase 1: Status & Messaging System 🎯 **HIGH PRIORITY**

#### 1.1 Alert Banner Component
**Location:** `src/components/guardian/AlertBanner.jsx`

**Features:**
- ✅ Intake form status (pending/completed)
- ✅ Overdue payments alert
- ✅ Pending payments reminder
- ✅ Enrollment status messages

**Variants:**
```jsx
- success: "Encuesta completada ✓"
- warning: "Encuesta pendiente - Complete antes del [fecha]"
- error: "Pagos atrasados - [cantidad] cuotas vencidas"
- info: "Tienes [cantidad] pagos pendientes"
```

**Priority:** 🔴 Critical (improves UX immediately)

---

#### 1.2 Dashboard Status Cards
**Location:** Enhance `GuardianWelcomePage.jsx`

**Add Status Indicators:**
```jsx
Status Card Components:
├── Intake Status Card
│   ├── Icon (✓ or ⚠)
│   ├── Status text
│   └── Action button (if pending)
├── Payment Status Card
│   ├── Visual progress bar
│   ├── Paid vs Total ratio
│   └── Next payment due date
└── Enrollment Status Card
    ├── Current step indicator
    ├── Completion percentage
    └── Next action required
```

**Priority:** 🔴 Critical

---

### Phase 2: Student Information Module 📚 **HIGH PRIORITY**

#### 2.1 Student Detail Component
**Location:** `src/components/guardian/StudentCard.jsx`

**Display for each student:**
- Full name + photo placeholder
- RUN
- Course/Grade
- Current year fees summary
- Quick actions (view fees, download reports)

**Expandable sections:**
- Personal info (from intake survey)
- Academic info (enrollment date, previous school)
- Contact info (address, commune, lives with)

**Priority:** 🟠 High

---

#### 2.2 Student Detail Page (Optional)
**Location:** `src/pages/guardian/StudentDetailPage.jsx`
**Route:** `/apoderado/estudiante/:studentId`

**Sections:**
- Personal Information
- Academic History
- Fee History (all years)
- Documents (if applicable)

**Priority:** 🟡 Medium (Phase 3 if time permits)

---

### Phase 3: Payment & Fee Management 💰 **HIGH PRIORITY**

#### 3.1 Fee Summary Component
**Location:** `src/components/guardian/FeeSummary.jsx`

**Features:**
- Visual breakdown by status:
  - 🟢 Paid (with dates)
  - 🟡 Pending (with due dates)
  - 🔴 Overdue (with days late)
- Filtering:
  - By student
  - By year
  - By status
- Sorting:
  - By due date
  - By amount
  - By student

**Priority:** 🔴 Critical

---

#### 3.2 Fee Detail Table
**Location:** `src/components/guardian/FeeTable.jsx`

**Columns:**
| Cuota # | Estudiante | Monto | Vencimiento | Estado | Fecha Pago | Acciones |
|---------|------------|-------|-------------|--------|------------|----------|
| 1       | María      | $50k  | 15/03/2025  | ✓Pagado| 10/03/2025 | Ver      |
| 2       | María      | $50k  | 15/04/2025  | Pendiente| - | Pagar  |
| 3       | Juan       | $50k  | 15/03/2025  | ⚠Atrasado| - | Pagar |

**Features:**
- Color coding by status
- Expandable rows (show payment details)
- Download receipt button
- Quick pay button (if integrated)

**Priority:** 🔴 Critical

---

#### 3.3 Payment History Component
**Location:** `src/components/guardian/PaymentHistory.jsx`

**Display:**
- Chronological list of all payments
- Payment method used
- Receipt/boleta number
- Bank transaction ID
- Notes

**Priority:** 🟠 High

---

### Phase 4: Layout & Navigation Improvements 🎨 **MEDIUM PRIORITY**

#### 4.1 Tabbed Navigation
**Location:** Update `GuardianWelcomePage.jsx`

**Tabs:**
```jsx
├── Resumen (Overview) - default
├── Estudiantes (Students)
├── Aranceles (Fees)
└── Documentos (Documents) - future
```

**Priority:** 🟡 Medium

---

#### 4.2 Responsive Cards Grid
**Mobile-first design:**
- Stack vertically on mobile
- 2 columns on tablet
- 3-4 columns on desktop

**Priority:** 🟡 Medium

---

### Phase 5: Data Services & Hooks 🔧 **FOUNDATION**

#### 5.1 Fee Service
**Location:** `src/services/feeService.ts`

**Functions:**
```typescript
- fetchGuardianFees(guardianId, year?) → Fee[]
- fetchStudentFees(studentId, year?) → Fee[]
- getFeesByStatus(fees, status) → Fee[]
- getUpcomingPayments(fees, days=30) → Fee[]
- calculateFeeStats(fees) → { paid, pending, overdue, total }
```

**Priority:** 🔴 Critical (needed for all payment features)

---

#### 5.2 Custom Hooks
**Location:** `src/hooks/`

```typescript
- useGuardianFees(guardianId) → { fees, loading, error, refresh }
- useStudentData(studentId) → { student, intake, enrollment }
- useFeeStats(guardianId) → { stats, loading }
```

**Priority:** 🟠 High

---

## Implementation Sequence (Recommended Order)

### Week 1: Foundation + Critical Features
1. **Day 1-2:** Fee Service + Hooks (`feeService.ts`, custom hooks)
2. **Day 3-4:** Alert Banner + Status Cards (messaging system)
3. **Day 5:** Fee Summary Component (basic version)

### Week 2: Core Features
4. **Day 6-7:** Fee Detail Table with sorting/filtering
5. **Day 8-9:** Student Cards with expandable details
6. **Day 10:** Payment History Component

### Week 3: Polish & Enhancement
7. **Day 11-12:** Tabbed navigation + layout improvements
8. **Day 13-14:** Mobile responsive refinements
9. **Day 15:** Testing, bug fixes, documentation

---

## Component Hierarchy (Proposed)

```
GuardianWelcomePage
├── AlertBanner (intake/payment alerts)
├── StatusDashboard
│   ├── IntakeStatusCard
│   ├── PaymentStatusCard
│   └── EnrollmentStatusCard
├── TabNavigation
│   ├── Tab: Resumen
│   │   ├── GuardianInfoCard
│   │   ├── QuickStatsGrid
│   │   └── QuickActionsMenu
│   ├── Tab: Estudiantes
│   │   └── StudentCard[] (expandable)
│   │       ├── StudentPersonalInfo
│   │       ├── StudentAcademicInfo
│   │       └── StudentFeeSummary
│   └── Tab: Aranceles
│       ├── FeeFilterBar
│       ├── FeeSummary
│       ├── FeeTable
│       └── PaymentHistory
└── FloatingActionButton (quick actions)
```

---

## Database Queries Needed

### For Fee Module:
```sql
-- Get guardian's student fees with details
SELECT 
  f.*,
  s.first_name,
  s.apellido_paterno,
  s.apellido_materno,
  s.whole_name,
  s.curso,
  c.nom_curso,
  CASE 
    WHEN f.status = 'paid' THEN 'paid'
    WHEN f.due_date < CURRENT_DATE THEN 'overdue'
    ELSE 'pending'
  END as computed_status
FROM fee f
JOIN students s ON f.student_id = s.id
LEFT JOIN cursos c ON s.curso = c.id
WHERE f.guardian_id = :guardian_id
  AND f.year = :year
ORDER BY f.due_date ASC, f.numero_cuota ASC;
```

### For Statistics:
```sql
-- Fee stats by guardian
SELECT 
  COUNT(*) as total_fees,
  SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as total_paid,
  SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) as total_pending,
  SUM(CASE WHEN due_date < CURRENT_DATE AND status != 'paid' THEN amount ELSE 0 END) as total_overdue,
  MIN(CASE WHEN status != 'paid' THEN due_date END) as next_due_date
FROM fee
WHERE guardian_id = :guardian_id
  AND year = :year;
```

---

## UI/UX Design Guidelines

### Color Coding:
- 🟢 **Green** (paid): `bg-green-100 text-green-800 border-green-300`
- 🟡 **Yellow** (pending): `bg-yellow-100 text-yellow-800 border-yellow-300`
- 🔴 **Red** (overdue): `bg-red-100 text-red-800 border-red-300`
- 🔵 **Blue** (info): `bg-blue-100 text-blue-800 border-blue-300`

### Typography:
- Page titles: `text-2xl font-semibold`
- Section headers: `text-lg font-medium`
- Card titles: `text-sm font-medium uppercase tracking-wide text-gray-500`
- Body text: `text-sm`
- Labels: `text-xs text-gray-500`

### Spacing:
- Page padding: `p-6`
- Card padding: `p-4`
- Section gaps: `space-y-6` or `gap-6`
- Element gaps: `space-y-4` or `gap-4`

---

## Files to Create

### New Components:
1. `src/components/guardian/AlertBanner.jsx`
2. `src/components/guardian/StatusCard.jsx`
3. `src/components/guardian/StudentCard.jsx`
4. `src/components/guardian/FeeSummary.jsx`
5. `src/components/guardian/FeeTable.jsx`
6. `src/components/guardian/PaymentHistory.jsx`
7. `src/components/guardian/TabNavigation.jsx`

### New Services:
8. `src/services/feeService.ts`

### New Hooks:
9. `src/hooks/useGuardianFees.ts`
10. `src/hooks/useStudentData.ts`
11. `src/hooks/useFeeStats.ts`

### Updates:
12. `src/pages/guardian/GuardianWelcomePage.jsx` (major refactor)

---

## Success Metrics

### Phase 1 Success:
✅ Users see clear status messages for:
- Intake completion status
- Payment alerts (overdue/pending)
- Next action required

### Phase 2 Success:
✅ Users can view detailed student information
✅ Student cards show quick fee summaries

### Phase 3 Success:
✅ Users can see detailed fee breakdown by student
✅ Users can filter/sort payments
✅ Users can view payment history

### Overall Success:
✅ Guardian can answer: "¿Tengo pagos atrasados?"
✅ Guardian can answer: "¿Cuánto debo pagar este mes?"
✅ Guardian can answer: "¿Qué cuotas ha pagado cada hijo?"
✅ Guardian can answer: "¿Completé la encuesta?"

---

## Risk & Mitigation

### Risk 1: Performance with many fees
**Mitigation:** 
- Paginate fee table (10-20 per page)
- Use React.memo for cards
- Implement virtual scrolling if needed

### Risk 2: Complex data aggregations
**Mitigation:**
- Create database views for common queries
- Cache results in frontend
- Use React Query for smart caching

### Risk 3: Mobile UX
**Mitigation:**
- Mobile-first design approach
- Test on actual devices
- Responsive tables (card view on mobile)

---

## Next Steps

**If you approve this plan:**
1. I'll start with **Phase 1 Foundation**: Fee Service + Hooks
2. Then implement **Alert Banner + Status Cards**
3. Progressively add features based on priority

**Or you can:**
- Request modifications to the plan
- Prioritize specific features differently
- Ask for mockups/wireframes before coding
- Start with a specific phase

---

## Questions for You

1. **Payment Integration:** Do you plan to integrate online payment (Webpay, etc) or is this read-only for now?
2. **Document Management:** Should we add document upload/download (contratos, certificates)?
3. **Notifications:** Email/SMS notifications for payment reminders?
4. **Multi-year:** Should guardians see fees from previous years?
5. **Admin Override:** Can admins edit fees from this portal or admin-only?

---

**Ready to proceed? Let me know which phase/components you want me to build first!** 🚀
