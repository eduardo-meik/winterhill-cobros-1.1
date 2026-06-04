# 🔧 GUARDIAN RUN CONSTRAINT - ISSUE & FIX

## ❌ PROBLEM IDENTIFIED

**Error Message**:
```
ERROR: 23502: null value in column "run" of relation "guardians" violates not-null constraint
```

**Root Cause**:
- The `guardians.run` column has a `NOT NULL` constraint
- Auto-creation SQL doesn't provide a RUN value
- PostgreSQL rejects the INSERT operation

---

## ✅ SOLUTIONS (Choose ONE)

### **OPTION 1: Make RUN Nullable (RECOMMENDED) ⭐**

**Why**: Most flexible - allows creating guardians immediately, they complete profile later

**SQL**:
```sql
ALTER TABLE guardians ALTER COLUMN run DROP NOT NULL;
```

**Then create guardian**:
```sql
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  email,
  tipo_apoderado,
  relationship_type
)
SELECT 
  auth.uid(),
  'Apoderado',
  'De Prueba',
  (SELECT email FROM auth.users WHERE id = auth.uid()),
  'TITULAR',
  'PADRE_MADRE'
WHERE NOT EXISTS (
  SELECT 1 FROM guardians WHERE owner_id = auth.uid()
);
```

**Pros**:
- ✅ Clean separation: authentication vs profile completion
- ✅ Better UX - user can access system immediately
- ✅ Can add "Complete Profile" wizard later

**Cons**:
- ⚠️ Need validation in forms where RUN is required
- ⚠️ Need to handle null RUN in PDF generation

---

### **OPTION 2: Use Temporary RUN Value**

**Why**: Keeps NOT NULL constraint, uses placeholder

**SQL**:
```sql
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
  '11111111-1',  -- Temporary placeholder
  (SELECT email FROM auth.users WHERE id = auth.uid()),
  'TITULAR',
  'PADRE_MADRE'
WHERE NOT EXISTS (
  SELECT 1 FROM guardians WHERE owner_id = auth.uid()
);
```

**Pros**:
- ✅ No schema change needed
- ✅ RUN always has a value

**Cons**:
- ⚠️ Fake data in database
- ⚠️ Need to track which RUNs are real vs temporary
- ⚠️ Potential duplicate RUN issues

---

### **OPTION 3: Require RUN at Signup**

**Why**: Ensure all guardians have valid RUN from the start

**Implementation**:
1. Add RUN field to signup form
2. Validate RUN format (XX.XXX.XXX-X)
3. Create guardian with real RUN

**Pros**:
- ✅ Clean data from the start
- ✅ No null handling needed

**Cons**:
- ⚠️ More complex signup flow
- ⚠️ Requires frontend changes

---

## 🎯 RECOMMENDED IMPLEMENTATION

**Step 1**: Make RUN nullable
```sql
ALTER TABLE guardians ALTER COLUMN run DROP NOT NULL;
```

**Step 2**: Create guardian without RUN
```sql
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  email,
  tipo_apoderado
)
SELECT 
  auth.uid(),
  'Apoderado',
  'De Prueba',
  (SELECT email FROM auth.users WHERE id = auth.uid()),
  'TITULAR'
WHERE NOT EXISTS (
  SELECT 1 FROM guardians WHERE owner_id = auth.uid()
);
```

**Step 3**: Verify
```sql
SELECT * FROM guardians WHERE owner_id = auth.uid();
```

**Step 4**: (Optional) Add profile completion prompt in UI

---

## 🔍 VERIFICATION QUERIES

### Check RUN constraint status:
```sql
SELECT 
  column_name, 
  is_nullable, 
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'guardians' 
  AND column_name = 'run';
```

**Expected after fix**:
```
column_name | is_nullable | data_type
run         | YES         | character varying
```

### Check existing guardians:
```sql
SELECT id, owner_id, first_name, last_name, run, email
FROM guardians
ORDER BY created_at DESC;
```

---

## 🛠️ UPDATE EXISTING CODE

### Update `ensure_guardian_for_user()` function:

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
  
  -- Create guardian WITHOUT requiring RUN
  INSERT INTO guardians (
    owner_id,
    first_name,
    last_name,
    email,
    tipo_apoderado
  )
  VALUES (
    user_id,
    'Apoderado',
    'Sin Configurar',
    user_email,
    'TITULAR'
  )
  RETURNING * INTO guardian_rec;
  
  RETURN guardian_rec;
END;
$$;
```

---

## 📝 FRONTEND CONSIDERATIONS

### Handle null RUN in PDF generation:

Update `pdfGenerator.ts` to handle missing RUN:

```typescript
function addSignatureSection(
  pdf: jsPDF, 
  pageWidth: number, 
  pageHeight: number,
  guardianRun?: string
) {
  // ... existing code ...
  
  pdf.text('APODERADO/A', col1X, sigY + 5);
  if (guardianRun) {
    pdf.text(`RUN: ${guardianRun}`, col1X, sigY + 10);
  } else {
    pdf.text(`RUN: _______________`, col1X, sigY + 10); // Blank line to fill in
  }
  
  // ... rest of code ...
}
```

### Add profile completion UI:

Show banner when RUN is missing:
```jsx
{guardian && !guardian.run && (
  <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4">
    <div className="flex">
      <div className="flex-shrink-0">⚠️</div>
      <div className="ml-3">
        <p className="text-sm text-yellow-700">
          Tu perfil está incompleto. 
          <a href="/perfil" className="font-medium underline">
            Completa tu RUT y otros datos
          </a>
        </p>
      </div>
    </div>
  </div>
)}
```

---

## ✅ QUICK FIX CHECKLIST

- [ ] **Step 1**: Run `ALTER TABLE guardians ALTER COLUMN run DROP NOT NULL;`
- [ ] **Step 2**: Verify with column info query
- [ ] **Step 3**: Create guardian using corrected INSERT
- [ ] **Step 4**: Verify guardian created: `SELECT * FROM guardians WHERE owner_id = auth.uid();`
- [ ] **Step 5**: Refresh browser (Ctrl+F5)
- [ ] **Step 6**: Test Matrícula wizard
- [ ] **Step 7**: (Optional) Add profile completion UI

---

## 🎉 EXPECTED RESULT

After fix:
- ✅ Guardian created successfully
- ✅ No error about null RUN
- ✅ User can access Matrícula wizard
- ✅ Can generate Pagaré (RUN field shows blank or "Sin RUN")
- ✅ User can update RUN later through profile page

---

**File Created**: `FIX_GUARDIANS_RUN_CONSTRAINT.sql`  
**Documentation**: This file  
**Status**: Ready to apply fix
