# 📦 MANUAL SUPABASE STORAGE BUCKET CREATION GUIDE

## 🎯 STEP-BY-STEP INSTRUCTIONS

### **Part 1: Create the Storage Bucket** (3 minutes)

#### Step 1: Open Supabase Dashboard
1. Go to: **https://supabase.com/dashboard**
2. Login with your account
3. Select your **Winterhill** project from the list

#### Step 2: Navigate to Storage
1. In the left sidebar, click on **"Storage"** (icon: 🗂️)
2. You'll see the Storage page with existing buckets (if any)

#### Step 3: Create New Bucket
1. Click the **"New bucket"** button (top right, green button)
2. A modal/form will appear

#### Step 4: Configure Bucket Settings
Fill in the form with these **EXACT** values:

```
┌─────────────────────────────────────────────────┐
│ Create a new bucket                              │
├─────────────────────────────────────────────────┤
│                                                  │
│ Name: *                                          │
│ ┌─────────────────────────────────────────────┐ │
│ │ enrollment-documents                         │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ ☐ Public bucket                                  │
│   ⚠️ LEAVE UNCHECKED - Must be private!        │
│                                                  │
│ File size limit (bytes)                          │
│ ┌─────────────────────────────────────────────┐ │
│ │ 10485760                                     │ │ (10 MB)
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ Allowed MIME types (comma separated)             │
│ ┌─────────────────────────────────────────────┐ │
│ │ application/pdf                              │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│         [Cancel]  [Create bucket]                │
└─────────────────────────────────────────────────┘
```

**CRITICAL SETTINGS**:
- ✅ Name: `enrollment-documents` (exact name, no spaces)
- ❌ Public bucket: **UNCHECKED** (must be private!)
- ✅ File size limit: `10485760` (10 MB in bytes)
- ✅ Allowed MIME types: `application/pdf`

#### Step 5: Create Bucket
1. Click **"Create bucket"** button
2. Wait for confirmation message
3. You should see the new bucket in the list

---

### **Part 2: Apply RLS Policies** (2 minutes)

#### Step 6: Open SQL Editor
1. In the left sidebar, click on **"SQL Editor"** (icon: </> )
2. Click **"New query"** button

#### Step 7: Copy the Migration SQL
1. Open the file: `supabase/migrations/20251027_setup_enrollment_documents_bucket.sql`
2. Copy **ALL** the content (Ctrl+A, Ctrl+C)

#### Step 8: Paste and Run SQL
1. Paste the SQL into the SQL Editor
2. Click **"Run"** button (or press Ctrl+Enter)
3. Wait for execution (should take ~1 second)

#### Step 9: Verify Success
You should see a success message like:
```
Success. No rows returned
```

---

### **Part 3: Verify Everything Works** (2 minutes)

#### Step 10: Check Storage Bucket
1. Go back to **Storage** in sidebar
2. Click on **"enrollment-documents"** bucket
3. You should see:
   - ✅ Empty bucket (no files yet)
   - ✅ Bucket name: enrollment-documents
   - ✅ Public: No (lock icon 🔒)

#### Step 11: Verify RLS Policies
1. Go to **"Database"** in sidebar
2. Click **"Policies"** tab
3. Filter by table: `storage.objects`
4. You should see **4 new policies**:

```
✅ "Users can upload enrollment documents"
   - Operation: INSERT
   - Table: storage.objects

✅ "Guardians can view their enrollment documents"
   - Operation: SELECT
   - Table: storage.objects

✅ "Users can update their enrollment documents"
   - Operation: UPDATE
   - Table: storage.objects

✅ "Only admins can delete enrollment documents"
   - Operation: DELETE
   - Table: storage.objects
```

#### Step 12: Test with SQL Query
1. Go to **SQL Editor**
2. Run this verification query:

```sql
-- Verify bucket exists
SELECT * FROM storage.buckets WHERE id = 'enrollment-documents';
```

Expected result:
```
id                    | name                  | public | file_size_limit | allowed_mime_types
enrollment-documents  | enrollment-documents  | false  | 10485760        | {application/pdf}
```

3. Run this to verify policies:

```sql
-- Verify policies exist
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%enrollment%'
ORDER BY policyname;
```

Expected result: **4 rows** showing the policy names

---

## ✅ VERIFICATION CHECKLIST

After completing all steps, verify:

- [x] **Bucket Created**
  - Name: `enrollment-documents` ✓
  - Public: No (private) ✓
  - Size limit: 10 MB ✓
  - MIME: application/pdf ✓

- [x] **SQL Migration Executed**
  - No errors when running SQL ✓
  - Success message appeared ✓

- [x] **Policies Created**
  - INSERT policy exists ✓
  - SELECT policy exists ✓
  - UPDATE policy exists ✓
  - DELETE policy exists ✓

- [x] **Verification Queries Pass**
  - Bucket query returns 1 row ✓
  - Policies query returns 4 rows ✓

---

## 🎯 WHAT TO DO IF SOMETHING GOES WRONG

### Problem: "Bucket name already exists"
**Solution**: 
- The bucket was already created
- Skip to Part 2 (Apply RLS Policies)
- Or delete the existing bucket and recreate

### Problem: "SQL error when running migration"
**Solution**:
1. Check that you copied the ENTIRE SQL file
2. Make sure bucket was created first
3. Try running the SQL in smaller chunks (one policy at a time)

### Problem: "Can't find storage.objects table"
**Solution**:
- This is normal if you haven't used Storage before
- The table exists, it's just not visible in Table Editor
- The policies will still work

### Problem: "Policies not showing up"
**Solution**:
1. Refresh the Policies page
2. Make sure you filtered by `storage.objects` table
3. Try this SQL to list them:
```sql
SELECT * FROM pg_policies WHERE tablename = 'objects';
```

---

## 📋 QUICK COPY-PASTE VALUES

For easy copying when creating the bucket:

**Bucket Name**:
```
enrollment-documents
```

**File Size Limit (bytes)**:
```
10485760
```

**Allowed MIME Types**:
```
application/pdf
```

---

## 🚀 NEXT STEPS AFTER BUCKET CREATION

1. ✅ Bucket created and policies applied
2. 🎨 **[OPTIONAL]** Add logo: `public/logo-winterhill.png`
3. 🧪 **Test the system**:
   ```bash
   npm run dev
   ```
4. 📝 Go to Matrícula wizard
5. ✨ Generate a Pagaré document
6. 📥 Download and verify PDF

---

## 💡 TIPS

- **Keep this tab open** while creating the bucket for reference
- **Copy the exact values** - especially the bucket name
- **Don't skip the RLS policies** - they're critical for security
- **Test immediately** after setup to catch any issues early

---

## 📞 NEED HELP?

If you encounter issues:

1. **Check Supabase logs**: Dashboard → Logs
2. **Browser console**: F12 → Console tab (when testing)
3. **Verify environment variables**: `.env` file has correct values
4. **Re-run the SQL**: Sometimes policies need to be reapplied

---

**Created**: October 27, 2025  
**Version**: 1.0  
**Status**: Ready to use

Good luck! 🚀
