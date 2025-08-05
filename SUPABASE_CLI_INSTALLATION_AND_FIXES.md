# Supabase CLI Installation and Security Fixes Application

## 1. Install Supabase CLI

### For Windows (PowerShell as Administrator):

#### Option A: Using Scoop (Recommended)
```powershell
# Install Scoop if not already installed
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install Supabase CLI
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

#### Option B: Manual Download
1. Go to https://github.com/supabase/cli/releases
2. Download the latest Windows release (supabase_windows_amd64.zip)
3. Extract to a folder (e.g., C:\supabase)
4. Add the folder to your PATH environment variable

#### Option C: Using npm
```bash
npm install -g supabase
```

### Verify Installation
```bash
supabase --version
```

## 2. Link Your Project (After CLI Installation)

```bash
# Navigate to your project directory
cd "d:\Proyectos\WINTERHILL\versiones\winterhill-cobros-1.1\winterhill-cobros-1.1"

# Link to your Supabase project (you'll need your project reference)
supabase link --project-ref YOUR_PROJECT_REF

# Or initialize if not linked
supabase init
```

## 3. Apply Security Fixes

### Option A: Using Supabase CLI (Preferred)
```bash
# Push the migration
supabase db push

# Or apply specific migration
supabase migration up
```

### Option B: Direct SQL Application (If CLI doesn't work)

**Steps:**
1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Copy the entire content from `function_search_path_security_fix.sql`
4. Paste and execute

**The SQL content to execute:**
```sql
-- Copy the entire content from function_search_path_security_fix.sql
-- (Content is ready in the file)
```

## 4. Manual Dashboard Configuration

After applying the SQL fixes, configure these settings in your Supabase Dashboard:

### Auth OTP Expiry:
1. Go to Authentication → Settings
2. Set "OTP expiry" to 3600 seconds (1 hour) or less
3. Save

### Leaked Password Protection:
1. Go to Authentication → Settings → Security
2. Enable "Leaked Password Protection"
3. Save

## 5. Verification

### Check Functions (SQL Editor):
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

### Run Security Advisor:
1. Go to Database → Security Advisor
2. Click "Run Security Advisor"
3. Verify all warnings are resolved

## 6. Quick Fix Application (Without CLI)

If you want to apply the fixes immediately without waiting for CLI setup:

1. **Open Supabase Dashboard**
2. **Go to SQL Editor**
3. **Copy and paste this complete SQL script:**

```sql
-- Function Search Path Security Fix
-- This script fixes all functions flagged by Supabase Security Advisor for mutable search_path

-- Function: actualizar_estado_std
CREATE OR REPLACE FUNCTION public.actualizar_estado_std(
    p_student_id uuid,
    p_new_status text
)
RETURNS void
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    UPDATE students 
    SET status = p_new_status, 
        updated_at = now()
    WHERE id = p_student_id;
END;
$$;

-- Function: es_admin_o_equipo
CREATE OR REPLACE FUNCTION public.es_admin_o_equipo(user_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
DECLARE
    user_role text;
BEGIN
    SELECT role INTO user_role
    FROM profiles
    WHERE id = user_uuid;
    
    RETURN user_role IN ('ADMIN', 'EQUIPO');
END;
$$;

-- Function: generate_invoice
CREATE OR REPLACE FUNCTION public.generate_invoice(
    p_student_id uuid,
    p_month integer,
    p_year integer,
    p_amount numeric
)
RETURNS uuid
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
DECLARE
    invoice_id uuid;
BEGIN
    INSERT INTO invoices (student_id, month, year, amount, status, created_at)
    VALUES (p_student_id, p_month, p_year, p_amount, 'PENDING', now())
    RETURNING id INTO invoice_id;
    
    RETURN invoice_id;
END;
$$;

-- Function: get_fees_with_students
CREATE OR REPLACE FUNCTION public.get_fees_with_students()
RETURNS TABLE (
    fee_id uuid,
    student_id uuid,
    student_name text,
    amount numeric,
    due_date date,
    status text
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id as fee_id,
        s.id as student_id,
        COALESCE(s.whole_name, CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', s.apellido_materno)) as student_name,
        f.amount,
        f.due_date,
        f.status
    FROM fees f
    JOIN students s ON f.student_id = s.id
    ORDER BY f.due_date DESC;
END;
$$;

-- Function: get_guardians_by_student_ids
CREATE OR REPLACE FUNCTION public.get_guardians_by_student_ids(student_ids uuid[])
RETURNS TABLE (
    guardian_id uuid,
    student_id uuid,
    first_name text,
    last_name text,
    email text,
    phone text,
    relationship_type text,
    tipo_apoderado text
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.id as guardian_id,
        sg.student_id,
        g.first_name,
        g.last_name,
        g.email,
        g.phone,
        g.relationship_type,
        g.tipo_apoderado
    FROM guardians g
    JOIN student_guardian sg ON g.id = sg.guardian_id
    WHERE sg.student_id = ANY(student_ids);
END;
$$;

-- Function: get_student_balance
CREATE OR REPLACE FUNCTION public.get_student_balance(p_student_id uuid)
RETURNS numeric
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
DECLARE
    total_fees numeric := 0;
    total_payments numeric := 0;
    balance numeric := 0;
BEGIN
    -- Calculate total fees
    SELECT COALESCE(SUM(amount), 0) INTO total_fees
    FROM fees
    WHERE student_id = p_student_id;
    
    -- Calculate total payments
    SELECT COALESCE(SUM(amount), 0) INTO total_payments
    FROM payments
    WHERE student_id = p_student_id;
    
    balance := total_fees - total_payments;
    
    RETURN balance;
END;
$$;

-- Function: get_students_by_guardian_ids
CREATE OR REPLACE FUNCTION public.get_students_by_guardian_ids(guardian_ids uuid[])
RETURNS TABLE (
    student_id uuid,
    guardian_id uuid,
    first_name text,
    apellido_paterno text,
    apellido_materno text,
    whole_name text,
    curso_id uuid,
    curso_name text
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id as student_id,
        sg.guardian_id,
        s.first_name,
        s.apellido_paterno,
        s.apellido_materno,
        COALESCE(s.whole_name, CONCAT(s.first_name, ' ', s.apellido_paterno, ' ', s.apellido_materno)) as whole_name,
        s.curso as curso_id,
        c.nom_curso as curso_name
    FROM students s
    JOIN student_guardian sg ON s.id = sg.student_id
    LEFT JOIN cursos c ON s.curso = c.id
    WHERE sg.guardian_id = ANY(guardian_ids);
END;
$$;

-- Function: get_table_metadata
CREATE OR REPLACE FUNCTION public.get_table_metadata(table_name text)
RETURNS TABLE (
    column_name text,
    data_type text,
    is_nullable text,
    column_default text
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.column_name::text,
        c.data_type::text,
        c.is_nullable::text,
        c.column_default::text
    FROM information_schema.columns c
    WHERE c.table_name = get_table_metadata.table_name
    AND c.table_schema = 'public'
    ORDER BY c.ordinal_position;
END;
$$;

-- Function: get_user_profile
CREATE OR REPLACE FUNCTION public.get_user_profile(user_id uuid)
RETURNS TABLE (
    id uuid,
    email text,
    full_name text,
    role text,
    created_at timestamptz,
    updated_at timestamptz
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.email,
        p.full_name,
        p.role,
        p.created_at,
        p.updated_at
    FROM profiles p
    WHERE p.id = user_id;
END;
$$;

-- Function: update_fee_updated_at
CREATE OR REPLACE FUNCTION public.update_fee_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Function: update_profile_full_name
CREATE OR REPLACE FUNCTION public.update_profile_full_name()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    -- Update full_name based on first_name and last_name if they exist
    IF NEW.first_name IS NOT NULL OR NEW.last_name IS NOT NULL THEN
        NEW.full_name = CONCAT(COALESCE(NEW.first_name, ''), ' ', COALESCE(NEW.last_name, ''));
        NEW.full_name = TRIM(NEW.full_name);
    END IF;
    
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Function: update_updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.actualizar_estado_std(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.es_admin_o_equipo(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_invoice(uuid, integer, integer, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_fees_with_students() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_guardians_by_student_ids(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_student_balance(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_students_by_guardian_ids(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_table_metadata(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_profile(uuid) TO authenticated;
```

4. **Click "Run" to execute the script**
5. **Configure Auth settings manually in Dashboard**
6. **Run Security Advisor to verify**

This will immediately fix all the function search_path security issues!
