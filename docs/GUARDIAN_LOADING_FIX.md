# 🔧 TROUBLESHOOTING - Infinite Loading / No Guardian Found

## 🎯 PROBLEM IDENTIFIED

**Issue**: Infinite loading or "No se encontró registro de apoderado" error  
**Cause**: Guardian record doesn't exist for the logged-in user  
**Impact**: Cannot access Matrícula wizard

---

## ✅ QUICK FIX - Create Guardian Record

### **Option 1: Auto-Create for Current User (RECOMMENDED)**

1. **Open Supabase SQL Editor**
2. **Make sure you're logged in** to your app first (so auth.uid() works)
3. **Run this SQL**:

```sql
-- Create guardian for currently logged-in user
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  run,
  email,
  tipo_apoderado,
  relationship_type
)
SELECT 
  auth.uid(),
  'Apoderado',
  'De Prueba',
  '11111111-1',  -- Temporary RUN - UPDATE THIS LATER!
  (SELECT email FROM auth.users WHERE id = auth.uid()),
  'TITULAR',
  'PADRE_MADRE'
WHERE NOT EXISTS (
  SELECT 1 FROM guardians WHERE owner_id = auth.uid()
);
```

4. **Verify it was created**:

```sql
SELECT * FROM guardians WHERE owner_id = auth.uid();
```

5. **Refresh your browser** and try again

---

### **Option 2: Create RPC Function for Auto-Creation**

This function auto-creates guardians when they login:

1. **Run in Supabase SQL Editor**:

```sql
CREATE OR REPLACE FUNCTION ensure_guardian_for_user()
RETURNS guardians
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id UUID;
  guardian_rec guardians;
  user_email TEXT;
BEGIN
  user_id := auth.uid();
  
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  SELECT * INTO guardian_rec
  FROM guardians
  WHERE owner_id = user_id
  LIMIT 1;
  
  IF FOUND THEN
    RETURN guardian_rec;
  END IF;
  
  SELECT email INTO user_email
  FROM auth.users
  WHERE id = user_id;
  
  INSERT INTO guardians (
    owner_id,
    first_name,
    last_name,
    run,
    email,
    tipo_apoderado
  )
  VALUES (
    user_id,
    'Apoderado',
    'Sin Configurar',
    '11111111-1',  -- Temporary RUN
    user_email,
    'TITULAR'
  )
  RETURNING * INTO guardian_rec;
  
  RETURN guardian_rec;
END;
$$;
```

2. **Test the function**:

```sql
SELECT * FROM ensure_guardian_for_user();
```

3. **Refresh browser** - should work now

---

### **Option 3: Manual Creation with Specific User ID**

If you know the user ID:

```sql
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  run,
  email,
  tipo_apoderado
)
VALUES (
  'paste-user-id-here',  -- Get from auth.users or browser console
  'Juan',
  'Pérez',
  '12345678-9',
  'juan@example.com',
  'TITULAR'
);
```

To get user ID:
```sql
SELECT id, email FROM auth.users;
```

---

## 🔍 VERIFICATION STEPS

### 1. Check if Guardian Exists
```sql
-- See all guardians
SELECT * FROM guardians;

-- See guardian for current user
SELECT * FROM guardians WHERE owner_id = auth.uid();
```

### 2. Check Auth User
```sql
-- See your current auth ID
SELECT auth.uid() as my_user_id;

-- See all auth users
SELECT id, email, created_at FROM auth.users;
```

### 3. Check Enrollments
```sql
-- See all enrollments
SELECT * FROM enrollments;

-- See enrollments for current guardian
SELECT e.* 
FROM enrollments e
JOIN guardians g ON g.id = e.guardian_id
WHERE g.owner_id = auth.uid();
```

---

## 🛠️ COMMON ISSUES & SOLUTIONS

### Issue: "RLS policy violation" or "permission denied"

**Cause**: Row Level Security blocking access

**Solution 1** - Check RLS policies:
```sql
SELECT * FROM pg_policies WHERE tablename = 'guardians';
```

**Solution 2** - Temporarily disable RLS (TESTING ONLY):
```sql
ALTER TABLE guardians DISABLE ROW LEVEL SECURITY;
-- Remember to re-enable later:
-- ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
```

**Solution 3** - Add RLS policy:
```sql
CREATE POLICY "Users can view their own guardian record"
ON guardians
FOR SELECT
TO authenticated
USING (owner_id::text = auth.uid()::text);

CREATE POLICY "Users can create their own guardian record"
ON guardians
FOR INSERT
TO authenticated
WITH CHECK (owner_id::text = auth.uid()::text);
```

---

### Issue: "auth.uid() returns null"

**Cause**: Not properly authenticated in SQL Editor

**Solution**:
1. Make sure you're logged in to the app
2. Use Supabase Dashboard's SQL Editor (not CLI)
3. Or use service_role key to bypass auth

---

### Issue: Guardian created but still shows error

**Solution**:
1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard refresh (Ctrl+F5)
3. Logout and login again
4. Check browser console for other errors

---

## 📋 IMPROVED APP BEHAVIOR

I've updated the MatriculaWizard component to:

✅ Show clear error message when guardian doesn't exist  
✅ Display loading spinner with text  
✅ Provide actionable troubleshooting steps  
✅ Prevent infinite loading state  

**New Error UI**:
- Red warning box with error details
- Suggested solutions
- Contact admin message

---

## 🚀 TESTING AFTER FIX

1. **Create guardian** (use Option 1 above)
2. **Refresh browser** (Ctrl+F5)
3. **Login again** if needed
4. **Go to Matrícula** page
5. Should see wizard steps (not error)

---

## 📝 PRODUCTION RECOMMENDATIONS

For production deployment:

1. **Automatic Guardian Creation**:
   - Create `ensure_guardian_for_user()` RPC function
   - Call it on first login via trigger or signup flow

2. **Admin Guardian Management**:
   - Build admin UI to create/edit guardians
   - Import guardians from Excel/CSV

3. **Better Onboarding**:
   - Show profile completion wizard on first login
   - Collect guardian data before allowing matrícula access

4. **RLS Policies**:
   - Ensure proper policies for guardians table
   - Test with multiple user accounts

---

## 🆘 STILL NOT WORKING?

1. **Check browser console** (F12 → Console tab)
   - Look for errors in red
   - Share screenshot for help

2. **Check Supabase logs** (Dashboard → Logs)
   - Filter by error level
   - Look for auth or database errors

3. **Verify environment variables** (.env file)
   - VITE_SUPABASE_URL correct?
   - VITE_SUPABASE_ANON_KEY correct?

4. **Database connection**
   - Can you query other tables?
   - Is Supabase project active?

---

**File**: CREATE_GUARDIAN_QUICK_FIX.sql (contains all SQL queries)  
**Updated**: MatriculaWizard.jsx (better error handling)  
**Status**: Ready to test after creating guardian
