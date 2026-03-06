# Security Fixes Application Guide

## Quick Summary
The following security fixes have been prepared for the Winterhill Cobros application to address all Supabase Security Advisor warnings:

## 1. Function Search Path Security (READY TO APPLY)

### Files Created:
- ✅ `function_search_path_security_fix.sql` - Standalone SQL script
- ✅ `supabase/migrations/20250805000002_fix_function_search_path.sql` - Migration file

### How to Apply (Choose ONE method):

#### Method A: Via Supabase SQL Editor (RECOMMENDED)
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the entire content from `function_search_path_security_fix.sql`
4. Click "Run" to execute

#### Method B: Via Supabase CLI (if installed)
```bash
supabase db push
```

#### Method C: Manual Execution
Execute the SQL script directly in your database management tool.

### What This Fixes:
- Adds `SET search_path = public` to 12 functions
- Prevents privilege escalation attacks
- Maintains SECURITY DEFINER where needed for proper RLS bypass

## 2. Auth Configuration (MANUAL DASHBOARD ACTIONS REQUIRED)

### OTP Expiry Fix:
1. Go to Supabase Dashboard → Authentication → Settings
2. Find "OTP expiry" setting
3. Change to **3600 seconds (1 hour)** or less
4. Save changes

### Leaked Password Protection:
1. Go to Supabase Dashboard → Authentication → Settings → Security
2. Enable "Leaked Password Protection"
3. Save changes

## 3. Verification Steps

After applying all fixes:

1. **Run Security Advisor**:
   - Dashboard → Database → Security Advisor → "Run Security Advisor"
   - Verify all warnings are resolved

2. **Test Functions**:
```sql
-- Test a function to ensure it still works
SELECT es_admin_o_equipo('your-user-id-here');
```

3. **Verify Search Path Settings**:
```sql
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

## 4. Expected Results

After all fixes are applied, you should see:
- ✅ Function search_path warnings resolved
- ✅ Auth OTP expiry warning resolved  
- ✅ Leaked password protection warning resolved
- ✅ Clean Security Advisor report

## 5. Emergency Contacts

If you encounter any issues:
1. Check application functionality first
2. Review Supabase logs for errors
3. Test authentication flows
4. Verify database operations work

## 6. Files Ready for Deployment

All necessary files have been created and are ready for application:

- `function_search_path_security_fix.sql` - Complete SQL fix
- `supabase/migrations/20250805000002_fix_function_search_path.sql` - Migration version
- `COMPLETE_SECURITY_FIXES.md` - Detailed documentation
- `SECURITY_FIXES_APPLICATION_GUIDE.md` - This guide

## Next Steps

1. ⏳ Apply the SQL fixes via Supabase SQL Editor
2. ⏳ Configure Auth settings via Dashboard
3. ⏳ Run Security Advisor verification
4. ✅ Security hardening complete!

The application is now ready for secure production deployment once these final steps are completed.
