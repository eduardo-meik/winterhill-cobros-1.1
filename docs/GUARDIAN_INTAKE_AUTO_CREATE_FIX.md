# Fix: Guardian Intake 400 Error on Page Load

## Problem
When accessing the guardian intake page for the first time, you get a **400 Bad Request** error:
```
POST https://yeotpplgerfpxviqazrn.supabase.co/rest/v1/rpc/upsert_guardian_intake_survey 400 (Bad Request)
```

## Root Cause
The SQL function `upsert_guardian_intake_survey` was using the OLD version that:
1. Manually looks for a guardian record: `SELECT id FROM guardians WHERE owner_id = v_user`
2. Throws an exception if not found: `RAISE EXCEPTION 'Guardian record not found for user'`
3. Fails during auto-create attempt when no intake record exists

## Solution
Updated the SQL function to use `ensure_guardian_for_user()` which **automatically creates** a guardian record if one doesn't exist.

## Files Changed
- ✅ `supabase/migrations/20251022_fix_guardian_intake_auto_create.sql` - New migration with fixed functions

## How to Apply the Fix

### Option 1: Using Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the file: `supabase/migrations/20251022_fix_guardian_intake_auto_create.sql`
4. Copy the entire contents
5. Paste into the SQL Editor
6. Click **Run** to execute

### Option 2: Using Supabase CLI
```powershell
# Make sure you're in the project directory
cd d:\Proyectos\WINTERHILL\versiones\winterhill-cobros-1.1\winterhill-cobros-1.1

# Push the migration to your remote database
supabase db push

# Or manually apply the specific migration
supabase db remote commit 20251022_fix_guardian_intake_auto_create
```

## What This Fixes
- ✅ **Auto-creation works**: When a user first accesses the intake page, a guardian record is automatically created if missing
- ✅ **No more 400 errors**: The page loads successfully even for brand new users
- ✅ **Seamless onboarding**: Users can start filling the intake form immediately without manual setup

## Verification Steps
1. Create a new test user account in Supabase Auth
2. Log in with that account
3. Navigate to the guardian intake page (`/apoderado/encuesta`)
4. **Expected**: Page loads successfully without 400 errors
5. **Expected**: A guardian record is automatically created in the `guardians` table
6. **Expected**: A draft intake survey is created in `guardian_intake_surveys` table

## Technical Details

### Before (Old Version)
```sql
SELECT id INTO v_guardian_id FROM public.guardians WHERE owner_id = v_user LIMIT 1;
IF v_guardian_id IS NULL THEN
  RAISE EXCEPTION 'Guardian record not found for user';  -- ❌ FAILS HERE
END IF;
```

### After (Fixed Version)
```sql
-- Obtener o crear guardian_id usando ensure_guardian_for_user
v_guardian_id := ensure_guardian_for_user();  -- ✅ AUTO-CREATES IF MISSING

IF v_guardian_id IS NULL THEN
  RAISE EXCEPTION 'Failed to obtain guardian record';
END IF;
```

The `ensure_guardian_for_user()` function (from `GUARDIAN_FIX_SIMPLE.sql`) automatically creates a minimal guardian record with:
- `owner_id` = current auth user
- `first_name` = 'Por completar'
- `last_name` = 'Por completar'  
- `run` = temporary generated RUN
- `email` = user's auth email
- `relationship_type` = 'Tutor'

## Related Files
- `GUARDIAN_FIX_SIMPLE.sql` - Contains `ensure_guardian_for_user()` function
- `FIX_GUARDIAN_INTAKE_COMPLETE.sql` - Reference implementation
- `src/services/guardianIntake.ts` - Frontend auto-create logic
