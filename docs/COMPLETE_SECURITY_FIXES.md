# Complete Security Fixes for Supabase Security Advisor

## Overview
This document outlines all security fixes needed to address Supabase Security Advisor warnings in the Winterhill Cobros application.

## 1. Function Search Path Security (COMPLETED)

### Issue
12 functions were flagged for having mutable search_path, which can be exploited for privilege escalation attacks.

### Solution Applied
- Created `function_search_path_security_fix.sql` script
- Created migration `20250805000002_fix_function_search_path.sql`
- Added `SET search_path = public` to all affected functions:
  - `actualizar_estado_std`
  - `es_admin_o_equipo`
  - `generate_invoice`
  - `get_fees_with_students`
  - `get_guardians_by_student_ids`
  - `get_student_balance`
  - `get_students_by_guardian_ids`
  - `get_table_metadata`
  - `get_user_profile`
  - `update_fee_updated_at`
  - `update_profile_full_name`
  - `update_updated_at`

### How to Apply
```bash
# Apply via Supabase CLI
supabase db push

# Or execute the SQL script directly in Supabase SQL Editor:
# Copy and paste content from function_search_path_security_fix.sql
```

### Verification
```sql
-- Verify functions have search_path set
SELECT 
    p.proname as function_name,
    p.proconfig as config_settings
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN (
    'actualizar_estado_std',
    'es_admin_o_equipo', 
    'generate_invoice',
    'get_fees_with_students',
    'get_guardians_by_student_ids',
    'get_student_balance',
    'get_students_by_guardian_ids',
    'get_table_metadata',
    'get_user_profile',
    'update_fee_updated_at',
    'update_profile_full_name',
    'update_updated_at'
)
ORDER BY p.proname;
```

## 2. Auth OTP Long Expiry (REQUIRES DASHBOARD ACTION)

### Issue
OTP (One-Time Password) expiry is set above the recommended 1 hour limit.

### Solution Required
Navigate to Supabase Dashboard → Authentication → Settings → Auth Configuration:

1. Go to your Supabase project dashboard
2. Click on "Authentication" in the left sidebar
3. Go to "Settings" tab
4. Find "OTP expiry" setting
5. Set it to **3600 seconds (1 hour)** or less
6. Click "Save"

### Recommended Setting
- **OTP Expiry**: 3600 seconds (1 hour)

## 3. Leaked Password Protection (REQUIRES DASHBOARD ACTION)

### Issue
Leaked password protection is currently disabled, making the application vulnerable to credential stuffing attacks.

### Solution Required
Navigate to Supabase Dashboard → Authentication → Settings → Security:

1. Go to your Supabase project dashboard
2. Click on "Authentication" in the left sidebar
3. Go to "Settings" tab
4. Find "Security" section
5. Enable "Leaked Password Protection"
6. Click "Save"

### What This Does
- Checks user passwords against known leaked password databases
- Prevents users from using commonly compromised passwords
- Adds an extra layer of security against credential stuffing attacks

## 4. Additional Security Recommendations

### Email Security
1. **Email Confirmations**: Ensure email confirmation is enabled for new signups
2. **Email Change Confirmations**: Require confirmation for email changes

### Session Security
1. **Session Timeout**: Consider setting appropriate session timeout values
2. **Refresh Token Rotation**: Enable refresh token rotation if available

### Rate Limiting
1. **Authentication Rate Limiting**: Ensure rate limiting is enabled for auth endpoints
2. **API Rate Limiting**: Consider implementing rate limiting for API calls

## 5. Verification Steps

After applying all fixes:

1. **Run Security Advisor Again**:
   - Go to Supabase Dashboard → Database → Security Advisor
   - Click "Run Security Advisor"
   - Verify all warnings are resolved

2. **Test Application**:
   - Test login/logout functionality
   - Test password reset functionality
   - Verify all database operations work correctly

3. **Monitor Logs**:
   - Check authentication logs for any errors
   - Monitor database logs for function execution

## 6. Files Modified/Created

### SQL Scripts
- `function_search_path_security_fix.sql` - Standalone fix script
- `supabase/migrations/20250805000002_fix_function_search_path.sql` - Migration file

### Documentation
- `COMPLETE_SECURITY_FIXES.md` - This file

## 7. Timeline

1. **Immediate (SQL fixes)**: Apply function search_path fixes via SQL script or migration
2. **Manual (Dashboard)**: Configure OTP expiry and leaked password protection via dashboard
3. **Verification**: Run Security Advisor to confirm all issues resolved

## 8. Status

- ✅ **Function Search Path Security**: Fixed via SQL scripts
- ⏳ **Auth OTP Long Expiry**: Requires manual dashboard configuration
- ⏳ **Leaked Password Protection**: Requires manual dashboard configuration
- ⏳ **Final Verification**: Run Security Advisor after all fixes applied

## 9. Emergency Rollback

If any issues occur after applying these fixes:

```sql
-- Rollback function changes (if needed)
-- This would remove the search_path setting from functions
-- Only use if there are critical issues

-- Example for one function:
CREATE OR REPLACE FUNCTION public.actualizar_estado_std(
    p_student_id uuid,
    p_new_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE students 
    SET status = p_new_status, 
        updated_at = now()
    WHERE id = p_student_id;
END;
$$;
```

**Note**: The search_path fixes are critical security improvements and should not be rolled back unless absolutely necessary.
