# Guardian Intake 400 Error Fix

## Problem
The guardian intake form was returning 400 Bad Request errors when trying to save drafts or submit the form.

## Root Cause
**Data Type Mismatch**: The frontend was sending `student_lives_with` as a JSON array `["Madre", "Padre"]`, but the PostgreSQL function `upsert_guardian_intake_survey` expected it as a pipe-delimited string `"Madre|Padre"`.

The SQL function in `supabase/migrations/20250925_guardian_intake_survey.sql` uses:
```sql
string_to_array(COALESCE(payload->>'student_lives_with',''), '|')::text[]
```

This expects the incoming value to be a string with `|` separators, not a JSON array.

## Solution

### 1. Modified `src/services/guardianIntake.ts` - `saveIntakeDraft` function
**Before:**
```typescript
export async function saveIntakeDraft(payload: Record<string, any>) {
  const full = { ...payload, year: CURRENT_YEAR, status: 'draft' };
  const { data, error } = await supabase.rpc('upsert_guardian_intake_survey', { payload: full });
  if (error) throw error;
  return data as GuardianIntakeRecord;
}
```

**After:**
```typescript
export async function saveIntakeDraft(payload: Record<string, any>) {
  // Convert student_lives_with array to pipe-delimited string for SQL function
  const processedPayload = { ...payload };
  if (Array.isArray(processedPayload.student_lives_with)) {
    processedPayload.student_lives_with = processedPayload.student_lives_with.join('|');
  }
  
  const full = { ...processedPayload, year: CURRENT_YEAR, status: 'draft' };
  const { data, error } = await supabase.rpc('upsert_guardian_intake_survey', { payload: full });
  if (error) throw error;
  return data as GuardianIntakeRecord;
}
```

### 2. Modified `src/services/guardianIntake.ts` - `fetchCurrentIntake` function
Added reverse conversion when loading data from database:

```typescript
// Convert student_lives_with from pipe-delimited string to array
if (record && typeof record.student_lives_with === 'string') {
  record = {
    ...record,
    student_lives_with: record.student_lives_with
      ? record.student_lives_with.split('|').filter((s: string) => s.trim())
      : []
  };
}
```

## Impact
- ✅ Draft auto-save now works without 400 errors
- ✅ Manual save ("Guardar Borrador") works correctly
- ✅ Form submission works without errors
- ✅ Multi-select checkbox "¿Con quién vive el estudiante?" data persists correctly

## Testing
1. Navigate to guardian intake form
2. Select multiple options in "¿Con quién vive el estudiante?"
3. Fill in other form fields
4. Click "Guardar Borrador" - should succeed without 400 error
5. Refresh page - selected options should persist
6. Complete required fields and click "Enviar Encuesta" - should submit without errors

## Files Changed
- `src/services/guardianIntake.ts`
