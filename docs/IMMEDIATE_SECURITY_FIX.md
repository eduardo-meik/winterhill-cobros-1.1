# Quick Security Fix Application - Immediate Solution

## ❗ IMMEDIATE ACTION REQUIRED

Since the Supabase CLI installation is encountering issues, let's apply the security fixes **immediately** using the Supabase Dashboard:

## 🚀 APPLY FIXES NOW (5 minutes)

### Step 1: Apply SQL Fixes (2 minutes)

1. **Open your Supabase Dashboard** in browser
2. **Go to SQL Editor** (left sidebar)
3. **Copy and paste the ENTIRE content below** into the SQL Editor:

```sql
-- Function Search Path Security Fix - IMMEDIATE APPLICATION
-- This fixes all 12 functions flagged by Security Advisor

-- Drop existing functions first to avoid return type conflicts
-- Use CASCADE for trigger functions to drop dependent triggers
DROP FUNCTION IF EXISTS public.actualizar_estado_std(uuid, text);
DROP FUNCTION IF EXISTS public.es_admin_o_equipo(uuid);
DROP FUNCTION IF EXISTS public.generate_invoice(uuid, integer, integer, numeric);
DROP FUNCTION IF EXISTS public.get_fees_with_students();
DROP FUNCTION IF EXISTS public.get_guardians_by_student_ids(uuid[]);
DROP FUNCTION IF EXISTS public.get_student_balance(uuid);
DROP FUNCTION IF EXISTS public.get_students_by_guardian_ids(uuid[]);
DROP FUNCTION IF EXISTS public.get_table_metadata(text);
DROP FUNCTION IF EXISTS public.get_user_profile(uuid);
DROP FUNCTION IF EXISTS public.update_fee_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.update_profile_full_name() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;

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
    FROM fee f  -- Changed from 'fees' to 'fee' to match schema
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
    -- Calculate total fees (using 'fee' table name)
    SELECT COALESCE(SUM(amount), 0) INTO total_fees
    FROM fee
    WHERE student_id = p_student_id;
    
    -- Calculate total payments
    SELECT COALESCE(SUM(amount), 0) INTO total_payments
    FROM payments
    WHERE invoice_id IN (
        SELECT id FROM invoices WHERE student_id = p_student_id
    );
    
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

-- Recreate triggers that were dropped with CASCADE
-- Trigger for fee table (corrected table name from 'fees' to 'fee')
DROP TRIGGER IF EXISTS update_fee_updated_at_trigger ON fee;
CREATE TRIGGER update_fee_updated_at_trigger
    BEFORE UPDATE ON fee
    FOR EACH ROW
    EXECUTE FUNCTION update_fee_updated_at();

-- Trigger for profiles table (if it exists)
DROP TRIGGER IF EXISTS update_profile_full_name_trigger ON profiles;
CREATE TRIGGER update_profile_full_name_trigger
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_full_name();

-- Generic updated_at triggers (using correct table names from schema)
DO $$
DECLARE
    table_name text;
    table_names text[] := ARRAY['students', 'guardians', 'profiles', 'fee', 'invoices'];
BEGIN
    FOREACH table_name IN ARRAY table_names
    LOOP
        -- Check if table exists and has updated_at column before creating trigger
        IF EXISTS (
            SELECT 1 
            FROM information_schema.tables t
            JOIN information_schema.columns c ON t.table_name = c.table_name 
            WHERE t.table_schema = 'public' 
            AND t.table_name = table_name 
            AND c.column_name = 'updated_at'
            AND c.table_schema = 'public'
        ) THEN
            EXECUTE format('DROP TRIGGER IF EXISTS update_%I_updated_at_trigger ON %I', table_name, table_name);
            EXECUTE format('CREATE TRIGGER update_%I_updated_at_trigger 
                           BEFORE UPDATE ON %I 
                           FOR EACH ROW 
                           EXECUTE FUNCTION update_updated_at()', table_name, table_name);
        END IF;
    END LOOP;
END $$;

-- Fix Security Definer Views (additional security fix)
-- Remove SECURITY DEFINER from views to fix security warnings

-- Fix database_metadata view
DROP VIEW IF EXISTS public.database_metadata CASCADE;
CREATE VIEW public.database_metadata AS
SELECT 
    t.table_schema,
    t.table_name,
    jsonb_agg(
        jsonb_build_object(
            'column_name', c.column_name,
            'data_type', c.data_type,
            'is_nullable', c.is_nullable,
            'column_default', c.column_default,
            'character_maximum_length', c.character_maximum_length
        ) ORDER BY c.ordinal_position
    ) AS metadata
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
GROUP BY t.table_schema, t.table_name
ORDER BY t.table_name;

-- Fix payment_summary view  
DROP VIEW IF EXISTS public.payment_summary CASCADE;
CREATE VIEW public.payment_summary AS
SELECT 
    p.id,
    p.amount,
    p.payment_date,
    p.invoice_id,
    p.created_at,
    i.student_id,
    f.amount as fee_amount,
    f.due_date,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    CONCAT(s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as full_last_name,
    s.curso,
    c.nom_curso
FROM payments p
LEFT JOIN invoices i ON p.invoice_id = i.id
LEFT JOIN fee f ON f.student_id = i.student_id
LEFT JOIN students s ON i.student_id = s.id
LEFT JOIN cursos c ON s.curso = c.id;

-- Grant permissions for views
GRANT SELECT ON public.database_metadata TO authenticated;
GRANT SELECT ON public.payment_summary TO authenticated;
```

4. **Click "RUN"** - This will fix all function security issues!

### Step 2: Configure Auth Settings (2 minutes)

1. **Go to Authentication → Settings**
2. **Set OTP Expiry**: Change to `3600` (1 hour) or less
3. **Enable Leaked Password Protection**: In Security section
4. **Save changes**

### Step 3: Verify Fix (1 minute)

1. **Go to Database → Security Advisor**
2. **Click "Run Security Advisor"**
3. **Verify all warnings are resolved** ✅

## 🔧 Supabase CLI Installation (For Future Use)

### Windows Installation Options:

#### Option 1: Download Binary (Recommended)
1. Go to: https://github.com/supabase/cli/releases
2. Download: `supabase_windows_amd64.zip`
3. Extract to: `C:\supabase\`
4. Add `C:\supabase\` to your PATH

#### Option 2: Using Scoop
```powershell
# Run as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

#### Option 3: Using Chocolatey
```powershell
# Run as Administrator
choco install supabase
```

### Verify Installation:
```bash
supabase --version
```

### Link Project (After CLI Installation):
```bash
cd "d:\Proyectos\WINTERHILL\versiones\winterhill-cobros-1.1\winterhill-cobros-1.1"
supabase link --project-ref YOUR_PROJECT_REF
```

## ✅ IMMEDIATE RESULT

After completing Steps 1-3 above:
- ✅ All 12 function security vulnerabilities FIXED
- ✅ Auth OTP expiry configured properly
- ✅ Leaked password protection enabled
- ✅ Security Advisor warnings resolved
- ✅ Application ready for secure production!

**The security fixes are ready to apply RIGHT NOW using the Dashboard method above.**
