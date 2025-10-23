# Testing Guide: Guardian Welcome Page Fix

## Quick Test Checklist

### ✅ Prerequisites
- [ ] Dev server running: http://localhost:5174/
- [ ] Guardian user account available
- [ ] Database has test student data

### Test Case 1: New Guardian First Login
**Scenario**: Guardian logs in for the first time

1. **Login** as guardian user
2. **Expected**: Auto-redirect to `/apoderado/encuesta`
3. **Action**: Fill out intake form with:
   - Guardian name, RUT, contact info
   - Student name and RUN
   - Educational/financial preferences
4. **Action**: Click "Enviar Encuesta"
5. **Expected**: 
   - ✅ Redirect to `/apoderado/bienvenida`
   - ✅ Summary dashboard visible (4 metric cards)
   - ✅ NO "Encuesta pendiente" message
   - ✅ Guardian info displays correctly
   - ✅ Students list shows associated students

### Test Case 2: Returning Guardian
**Scenario**: Guardian who already submitted intake

1. **Login** as guardian with submitted intake
2. **Expected**: Direct access to `/apoderado/bienvenida`
3. **Verify**:
   - ✅ Dashboard visible immediately
   - ✅ No redirect to intake form
   - ✅ All data displays correctly

### Test Case 3: Cache Invalidation
**Scenario**: Verify cache clears after submission

1. **Open DevTools** → Network tab
2. **Navigate** to `/apoderado/encuesta`
3. **Submit** the form
4. **Check**: Welcome page loads without additional intake check
5. **Verify**: No stale "pending" state

### Test Case 4: Student Association
**Scenario**: Verify students display correctly

1. **Login** as guardian
2. **Navigate** to welcome page
3. **Check "Estudiantes Asociados" section**:
   - ✅ Student names display
   - ✅ RUNs show correctly
   - ✅ Course/grade chips visible
   - ✅ Count matches actual linked students

### Test Case 5: Fee Totals
**Scenario**: Verify financial summary calculates

1. **Ensure** test data has fees for linked students
2. **Check dashboard cards**:
   - ✅ "Total Pagado" shows sum of paid fees
   - ✅ "Pendiente" shows pending amounts
   - ✅ "Atrasado" shows overdue amounts
   - ✅ All formatted as currency (CLP)

### Test Case 6: Data Merging Priority
**Scenario**: Verify intake data overrides guardian table data

**Setup**:
- Guardian table has: `first_name = "Juan"`
- Intake survey has: `guardian_first_name = "María"`

**Expected**: Welcome page displays "María" (intake priority)

### Test Case 7: Error Handling
**Scenario**: Guardian record creation delay

1. **Clear browser cache**
2. **Login** immediately after signup
3. **Expected**: 
   - ✅ Loading spinner shows
   - ✅ Retries up to 3 times (500ms intervals)
   - ✅ Either succeeds or shows "Apoderado no disponible" message
   - ✅ "Reintentar" button works

## Manual Verification Points

### Database Checks

```sql
-- 1. Verify guardian created
SELECT * FROM guardians WHERE owner_id = '<user_id>';

-- 2. Verify intake submitted
SELECT * FROM guardian_intake_surveys 
WHERE guardian_id = '<guardian_id>' 
AND status = 'submitted';

-- 3. Verify student linkage
SELECT sg.*, s.whole_name 
FROM student_guardian sg
JOIN students s ON s.id = sg.student_id
WHERE sg.guardian_id = '<guardian_id>';

-- 4. Verify fees exist
SELECT * FROM fee 
WHERE student_id IN (
  SELECT student_id FROM student_guardian 
  WHERE guardian_id = '<guardian_id>'
);
```

### Browser Console Checks

**Should NOT see**:
- ❌ `fetchGuardianStudents link error`
- ❌ `No draft survey found`
- ❌ `Failed to obtain guardian record`

**Expected behavior**:
- ✅ Clean console (no red errors)
- ✅ Network requests succeed (200/201 status)
- ✅ RPC calls return valid data

## Edge Cases to Test

### Edge Case 1: No Students Yet
- Guardian submitted intake but no students linked
- **Expected**: "Aún no hay estudiantes vinculados" message

### Edge Case 2: Student Without Course
- Student exists but `curso` field is null
- **Expected**: Chip shows "Sin curso"

### Edge Case 3: Multiple Students
- Guardian has 3+ linked students
- **Expected**: All display in scrollable list

### Edge Case 4: Network Delay
- Simulate slow 3G network
- **Expected**: Loading states show, no crashes

### Edge Case 5: Partial Data
- Guardian has minimal info (only RUT)
- **Expected**: Shows "—" for missing fields, no breaks

## Performance Checks

1. **Time to Interactive**: Welcome page should load < 2s
2. **Student Query**: Should use single JOIN query (check Network tab)
3. **No N+1**: Verify only 1 query per data type (not per student)

## Regression Tests

Ensure these still work:

- [ ] Navigation to `/matricula` from welcome page
- [ ] "Actualizar datos" link opens intake form
- [ ] "Ver estado de pagos" link works
- [ ] Mobile responsive layout
- [ ] Dark mode displays correctly

## Automated Test Commands

```bash
# Run build (should pass)
npm run build

# Run linter (our files should have no errors)
npm run lint src/services/guardianIntake.ts
npm run lint src/pages/guardian/GuardianWelcomePage.jsx

# Type check
npx tsc --noEmit
```

## Known Limitations

1. **Cache is in-memory**: Resets on page reload (acceptable for MVP)
2. **Student associations**: Require manual `student_guardian` records
3. **RLS policies**: Must be configured correctly for guardian access
4. **Auto-creation**: Depends on `ensure_guardian_for_user()` RPC function

## Troubleshooting

### Issue: "Encuesta pendiente" still showing
**Check**:
1. Intake status in DB is lowercase 'submitted'
2. Cache cleared after submission
3. Browser cache cleared
4. No console errors

### Issue: No students showing
**Check**:
1. `student_guardian` records exist
2. Guardian ID matches between tables
3. RLS policies allow SELECT
4. `fetchGuardianStudents()` query succeeds

### Issue: Guardian not created
**Check**:
1. RPC `ensure_guardian_for_user()` exists
2. Function has SECURITY DEFINER
3. `auth.uid()` returns valid user ID
4. No database constraints violated

## Success Criteria

All tests pass when:
- ✅ No build errors
- ✅ No console errors
- ✅ All 7 test cases pass
- ✅ Edge cases handled gracefully
- ✅ Performance within limits
- ✅ No regressions

---

**Last Updated**: October 23, 2025
**Tested By**: _____________
**Status**: ⏳ Pending User Testing
