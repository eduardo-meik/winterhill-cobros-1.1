# 🔧 GUARDIAN CREATION - AUTH CONTEXT FIX

## ❌ PROBLEM

**Error**: `null value in column "owner_id" violates not-null constraint`

**Cause**: `auth.uid()` returns NULL in Supabase SQL Editor because:
- SQL Editor runs as service role (not as authenticated user)
- No auth context available
- Need to provide user ID explicitly

---

## ✅ SOLUTION - 3 Options

### **OPTION 1: Get User ID First, Then Insert (RECOMMENDED)** ⭐

#### Step 1: Find Your User ID

```sql
-- Get all users and their IDs
SELECT id, email, created_at 
FROM auth.users 
ORDER BY created_at DESC;
```

Copy the `id` of the user you want to create a guardian for.

#### Step 2: Create Guardian with Explicit User ID

```sql
-- Replace 'YOUR_USER_ID_HERE' with the actual UUID from Step 1
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  email,
  tipo_apoderado,
  relationship_type
)
VALUES (
  'YOUR_USER_ID_HERE',  -- Paste the UUID from auth.users
  'Apoderado',
  'De Prueba',
  'test@example.com',   -- Update with actual email
  'TITULAR',
  'PADRE_MADRE'
);
```

**Example**:
```sql
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  email,
  tipo_apoderado,
  relationship_type
)
VALUES (
  'a984cf7a-1c5c-4c4b-b8e0-66a5b6819d7a',  -- Real user ID
  'Juan',
  'Pérez',
  'juan@example.com',
  'TITULAR',
  'PADRE_MADRE'
);
```

---

### **OPTION 2: Create for Most Recent User**

```sql
-- Creates guardian for the most recently created user
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  email,
  tipo_apoderado,
  relationship_type
)
SELECT 
  id,
  'Apoderado',
  'De Prueba',
  email,
  'TITULAR',
  'PADRE_MADRE'
FROM auth.users
ORDER BY created_at DESC
LIMIT 1;
```

---

### **OPTION 3: Create for Specific Email**

```sql
-- Replace 'your-email@example.com' with actual email
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  email,
  tipo_apoderado,
  relationship_type
)
SELECT 
  id,
  'Apoderado',
  'De Prueba',
  email,
  'TITULAR',
  'PADRE_MADRE'
FROM auth.users
WHERE email = 'your-email@example.com';
```

---

## 📋 STEP-BY-STEP GUIDE

### **Step 1: Make RUN Nullable**

```sql
ALTER TABLE guardians ALTER COLUMN run DROP NOT NULL;
```

### **Step 2: Find Your User ID**

```sql
SELECT id, email FROM auth.users ORDER BY created_at DESC;
```

**Copy the ID** that corresponds to your test user.

### **Step 3: Create Guardian**

```sql
-- Paste your user ID below (replace the example)
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  email,
  tipo_apoderado,
  relationship_type
)
VALUES (
  'PASTE-YOUR-USER-ID-HERE',
  'Apoderado',
  'De Prueba',
  'your-email@example.com',
  'TITULAR',
  'PADRE_MADRE'
);
```

### **Step 4: Verify Creation**

```sql
-- Check if guardian was created
SELECT * FROM guardians ORDER BY created_at DESC LIMIT 1;
```

Expected result: 1 row with your user ID in `owner_id`

### **Step 5: Verify Link**

```sql
-- Verify guardian is linked to correct user
SELECT 
  g.id as guardian_id,
  g.first_name,
  g.last_name,
  g.email as guardian_email,
  u.email as user_email,
  g.owner_id
FROM guardians g
JOIN auth.users u ON u.id = g.owner_id
ORDER BY g.created_at DESC
LIMIT 1;
```

---

## 🔍 TROUBLESHOOTING

### Issue: "No users found"

**Cause**: No users in auth.users table

**Solution**: 
1. Go to your app
2. Sign up / create account
3. Then run the guardian creation SQL

### Issue: "Duplicate key violation"

**Cause**: Guardian already exists for this user

**Solution**: Delete and recreate or update existing:

```sql
-- Check existing guardian
SELECT * FROM guardians WHERE owner_id = 'your-user-id';

-- Option A: Delete and recreate
DELETE FROM guardians WHERE owner_id = 'your-user-id';
-- Then run INSERT again

-- Option B: Update existing
UPDATE guardians 
SET 
  first_name = 'Apoderado',
  last_name = 'De Prueba',
  tipo_apoderado = 'TITULAR'
WHERE owner_id = 'your-user-id';
```

---

## 📝 COMPLETE WORKING EXAMPLE

Here's a complete script that does everything:

```sql
-- 1. Make RUN nullable
ALTER TABLE guardians ALTER COLUMN run DROP NOT NULL;

-- 2. Show available users (copy the ID you want)
SELECT 
  id, 
  email, 
  created_at,
  '👆 Copy this ID' as instruction
FROM auth.users 
ORDER BY created_at DESC;

-- 3. Create guardian (REPLACE THE ID BELOW!)
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  email,
  tipo_apoderado,
  relationship_type
)
VALUES (
  'REPLACE-WITH-ID-FROM-STEP-2',
  'Apoderado',
  'De Prueba',
  'test@example.com',
  'TITULAR',
  'PADRE_MADRE'
)
ON CONFLICT (owner_id) DO UPDATE
SET 
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  updated_at = NOW();

-- 4. Verify
SELECT 
  g.*,
  u.email as user_email
FROM guardians g
JOIN auth.users u ON u.id = g.owner_id
ORDER BY g.created_at DESC
LIMIT 1;
```

---

## 🎯 QUICK COPY-PASTE

**If you know your user ID**, just replace and run:

```sql
-- Replace XXXXX with your actual user ID
DO $$
DECLARE
  user_id UUID := 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX';
BEGIN
  -- Make RUN nullable if not already
  BEGIN
    ALTER TABLE guardians ALTER COLUMN run DROP NOT NULL;
  EXCEPTION WHEN others THEN
    NULL; -- Ignore if already nullable
  END;
  
  -- Create or update guardian
  INSERT INTO guardians (
    owner_id,
    first_name,
    last_name,
    email,
    tipo_apoderado,
    relationship_type
  )
  VALUES (
    user_id,
    'Apoderado',
    'De Prueba',
    (SELECT email FROM auth.users WHERE id = user_id),
    'TITULAR',
    'PADRE_MADRE'
  )
  ON CONFLICT (owner_id) DO UPDATE
  SET updated_at = NOW();
  
  RAISE NOTICE 'Guardian created/updated successfully';
END $$;
```

---

## ✅ SUCCESS CHECKLIST

After running the SQL:

- [ ] RUN column is nullable
- [ ] Found user ID from auth.users
- [ ] Created guardian with correct owner_id
- [ ] Verified guardian exists
- [ ] Verified link between guardian and user
- [ ] Refreshed browser
- [ ] Tested Matrícula page

---

**Next**: Once guardian is created, refresh your browser and test the Matrícula wizard!
