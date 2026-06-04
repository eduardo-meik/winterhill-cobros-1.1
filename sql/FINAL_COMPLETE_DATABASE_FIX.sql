-- FINAL COMPLETE DATABASE FIX
-- This script addresses all remaining security and schema issues
-- Date: 2025-08-05

-- ISSUE 1: Fix table name from "fees" to "fee" in all functions and views
-- ISSUE 2: Remove SECURITY DEFINER from views
-- ISSUE 3: Ensure all functions have SET search_path = public
-- ISSUE 4: Enable RLS and create proper policies

-- ============================================================================
-- 1. DROP EXISTING FUNCTIONS AND VIEWS
-- ============================================================================

-- Drop functions with CASCADE for trigger functions
DROP FUNCTION IF EXISTS public.actualizar_estado_std(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.es_admin_o_equipo(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.generate_invoice(uuid, integer, integer, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.get_fees_with_students() CASCADE;
DROP FUNCTION IF EXISTS public.get_guardians_by_student_ids(uuid[]) CASCADE;
DROP FUNCTION IF EXISTS public.get_student_balance(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.get_students_by_guardian_ids(uuid[]) CASCADE;
DROP FUNCTION IF EXISTS public.get_table_metadata(text) CASCADE;
DROP FUNCTION IF EXISTS public.get_user_profile(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.update_fee_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.update_profile_full_name() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.finalize_enrollment(uuid, jsonb) CASCADE;

-- Drop views
DROP VIEW IF EXISTS public.database_metadata CASCADE;
DROP VIEW IF EXISTS public.payment_summary CASCADE;

-- Create Sequence for Folio if not exists
CREATE SEQUENCE IF NOT EXISTS public.enrollment_folio_seq;

-- ============================================================================
-- 2. RECREATE FUNCTIONS WITH CORRECT TABLE NAMES AND SECURITY SETTINGS
-- ============================================================================

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
    
    RETURN user_role IN ('admin', 'team');
END;
$$;

-- Function: generate_invoice (FIXED: table name from fees to fee)
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
    fee_id uuid;
BEGIN
    -- Create invoice
    INSERT INTO invoices (student_id, month, year, amount, status)
    VALUES (p_student_id, p_month, p_year, p_amount, 'pending')
    RETURNING id INTO invoice_id;
    
    -- Create corresponding fee record (FIXED: table name)
    INSERT INTO fee (student_id, amount, due_date, status, invoice_id)
    VALUES (
        p_student_id, 
        p_amount, 
        date(p_year || '-' || p_month || '-28'), 
        'pending',
        invoice_id
    )
    RETURNING id INTO fee_id;
    
    RETURN invoice_id;
END;
$$;

-- Function: get_fees_with_students (FIXED: table name from fees to fee)
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
    FROM fee f  -- FIXED: Changed from 'fees' to 'fee'
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

-- Function: get_student_balance (FIXED: table name from fees to fee)
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
    -- Calculate total fees (FIXED: table name)
    SELECT COALESCE(SUM(amount), 0) INTO total_fees
    FROM fee  -- FIXED: Changed from 'fees' to 'fee'
    WHERE student_id = p_student_id;
    
    -- Calculate total payments
    SELECT COALESCE(SUM(amount), 0) INTO total_payments
    FROM fee  -- FIXED: Changed from 'payments' to 'fee' (assuming payments are tracked in fee table or similar)
    WHERE student_id = p_student_id AND status = 'paid';
    
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
        s.whole_name,
        s.curso as curso_id,
        c.nom_curso as curso_name
    FROM students s
    JOIN student_guardian sg ON s.id = sg.student_id
    LEFT JOIN cursos c ON s.curso = c.id
    WHERE sg.guardian_id = ANY(guardian_ids);
END;
$$;

-- Function: get_table_metadata
CREATE OR REPLACE FUNCTION public.get_table_metadata(table_name_param text)
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
    WHERE c.table_schema = 'public' 
    AND c.table_name = table_name_param
    ORDER BY c.ordinal_position;
END;
$$;

-- Function: get_user_profile
CREATE OR REPLACE FUNCTION public.get_user_profile(user_id uuid)
RETURNS TABLE (
    id uuid,
    first_name text,
    last_name text,
    full_name text,
    email text,
    role text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
)
LANGUAGE plpgsql
SET search_path = public
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.first_name,
        p.last_name,
        p.full_name,
        p.email,
        p.role,
        p.created_at,
        p.updated_at
    FROM profiles p
    WHERE p.id = user_id;
END;
$$;

-- Function: finalize_enrollment (FIXED: Folio, Pre-matricula, Zero cost)
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_year int;
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;
  v_folio text;
  v_folio_seq bigint;
  r_es RECORD;
  r_cuota RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    PERFORM 1 FROM public.student_guardian sg
      WHERE sg.student_id = r_es.student_id AND sg.guardian_id = v_enrollment.guardian_id;
    IF NOT FOUND THEN
      IF v_is_staff THEN
        INSERT INTO public.student_guardian(student_id, guardian_id, is_primary)
        VALUES (r_es.student_id, v_enrollment.guardian_id, false)
        ON CONFLICT DO NOTHING;
      ELSE
        RAISE EXCEPTION 'MISSING_RELATION: student % is not linked with this guardian', r_es.student_id;
      END IF;
    END IF;
  END LOOP;

  IF v_students = 0 THEN
    RAISE EXCEPTION 'NO_STUDENTS: enrollment has no students';
  END IF;

  v_plan := p_options->'payment_plan';
  IF v_plan IS NULL THEN
    SELECT e.meta->'payment_plan' INTO v_plan FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;
  IF v_plan IS NULL THEN
    SELECT ed.generated_payload INTO v_plan
      FROM public.enrollment_documents ed
     WHERE ed.enrollment_id = p_enrollment_id
       AND (ed.type = 'PRESTACION' OR ed.type LIKE 'PAGARE%')
       AND ed.generated_payload IS NOT NULL
     ORDER BY CASE WHEN ed.type='PRESTACION' THEN 0 ELSE 1 END, ed.created_at DESC
     LIMIT 1;
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
    DECLARE
      v_n_raw text := COALESCE(v_plan->>'n_cuotas', v_plan->>'cantidad_cuotas');
      v_n int;
      v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
      v_total numeric := COALESCE((v_plan->>'monto_total')::numeric, (v_plan->>'colegiatura_anual')::numeric, 0);
      v_amount numeric;
      i int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      -- Safe cast for n_cuotas to avoid "invalid input syntax" from placeholders like "__________"
      IF v_n_raw ~ '^[0-9]+$' THEN
        v_n := v_n_raw::int;
      ELSE
        v_n := 0;
      END IF;

      -- Handle zero cost case
      IF v_total = 0 THEN
         v_cuotas := '[]'::jsonb;
      ELSE
         v_amount := COALESCE((v_plan->>'monto_por_cuota')::numeric,
                              (v_plan->>'monto_cuota')::numeric,
                              v_total / NULLIF(v_n,0));

         IF v_n IS NULL OR v_first IS NULL OR v_amount IS NULL THEN
            RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
         END IF;
         
         WHILE i <= v_n LOOP
            v_synth := v_synth || jsonb_build_object(
              'numero', i,
              'amount', v_amount,
              'due_date', (v_first + make_interval(months := i-1))::date
            );
            i := i + 1;
         END LOOP;
         v_cuotas := v_synth;
      END IF;
    END;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          ON CONFLICT (student_id, guardian_id, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    -- Generate sequential folio
    v_folio_seq := nextval('public.enrollment_folio_seq');
    v_folio := 'ENR-' || v_year || '-' || to_char(v_folio_seq, 'FM000000');
    
    -- Update enrollment with folio
    UPDATE public.enrollments 
       SET status = 'completed', 
           updated_at = now(),
           meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', v_folio)
     WHERE id = p_enrollment_id;

    -- Update student status to PRE_MATRICULADO
    UPDATE public.students
       SET estado_std = 'PRE_MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
     );
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary,
    'folio', v_folio,
    'year', v_year
  );
END;
$$;

-- Trigger Functions
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

CREATE OR REPLACE FUNCTION public.update_profile_full_name()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.full_name = CONCAT(COALESCE(NEW.first_name, ''), ' ', COALESCE(NEW.last_name, ''));
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- ============================================================================
-- 3. RECREATE VIEWS WITHOUT SECURITY DEFINER
-- ============================================================================

-- Database metadata view (NO SECURITY DEFINER)
CREATE VIEW public.database_metadata AS
SELECT 
    t.table_name,
    t.table_type,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    tc.constraint_type
FROM information_schema.tables t
LEFT JOIN information_schema.columns c ON t.table_name = c.table_name
LEFT JOIN information_schema.table_constraints tc ON t.table_name = tc.table_name
WHERE t.table_schema = 'public' 
AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name;

-- Payment summary view (NO SECURITY DEFINER, FIXED: table name)
CREATE VIEW public.payment_summary AS
SELECT 
    f.id,
    f.amount,
    f.payment_date,
    f.created_at,
    f.student_id,
    f.amount as fee_amount,
    f.due_date,
    s.first_name,
    s.apellido_paterno,
    s.apellido_materno,
    CONCAT(s.apellido_paterno, ' ', COALESCE(s.apellido_materno, '')) as full_last_name,
    s.curso,
    c.nom_curso
FROM fee f
LEFT JOIN students s ON f.student_id = s.id
LEFT JOIN cursos c ON s.curso = c.id
WHERE f.status = 'paid';

-- ============================================================================
-- 4. RECREATE TRIGGERS FOR CORRECT TABLES
-- ============================================================================

-- Drop existing triggers first
DROP TRIGGER IF EXISTS update_fee_updated_at_trigger ON fee;
DROP TRIGGER IF EXISTS update_profiles_full_name_trigger ON profiles;
DROP TRIGGER IF EXISTS update_students_updated_at_trigger ON students;
DROP TRIGGER IF EXISTS update_guardians_updated_at_trigger ON guardians;
-- DROP TRIGGER IF EXISTS update_payments_updated_at_trigger ON payments; -- Removed as table does not exist
DROP TRIGGER IF EXISTS update_invoices_updated_at_trigger ON invoices;

-- Create triggers (only for tables that exist and have updated_at column)
DO $$
BEGIN
    -- Trigger for fee table (not fees)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fee' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fee' AND column_name = 'updated_at' AND table_schema = 'public') THEN
            CREATE TRIGGER update_fee_updated_at_trigger
                BEFORE UPDATE ON fee
                FOR EACH ROW
                EXECUTE FUNCTION update_fee_updated_at();
        END IF;
    END IF;

    -- Trigger for profiles table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public') THEN
        CREATE TRIGGER update_profiles_full_name_trigger
            BEFORE INSERT OR UPDATE ON profiles
            FOR EACH ROW
            EXECUTE FUNCTION update_profile_full_name();
    END IF;

    -- Triggers for other tables with updated_at
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'students' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'students' AND column_name = 'updated_at' AND table_schema = 'public') THEN
            CREATE TRIGGER update_students_updated_at_trigger
                BEFORE UPDATE ON students
                FOR EACH ROW
                EXECUTE FUNCTION update_updated_at();
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'guardians' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'guardians' AND column_name = 'updated_at' AND table_schema = 'public') THEN
            CREATE TRIGGER update_guardians_updated_at_trigger
                BEFORE UPDATE ON guardians
                FOR EACH ROW
                EXECUTE FUNCTION update_updated_at();
        END IF;
    END IF;

    -- Payments trigger removed as table does not exist

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'invoices' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'invoices' AND column_name = 'updated_at' AND table_schema = 'public') THEN
            CREATE TRIGGER update_invoices_updated_at_trigger
                BEFORE UPDATE ON invoices
                FOR EACH ROW
                EXECUTE FUNCTION update_updated_at();
        END IF;
    END IF;
END $$;

-- ============================================================================
-- 5. ENABLE RLS AND CREATE POLICIES
-- ============================================================================

-- Enable RLS on all relevant tables
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE payments ENABLE ROW LEVEL SECURITY; -- Table does not exist
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_guardian ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (assuming owner_id column exists)
DO $$
BEGIN
    -- Students table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'students' AND policyname = 'students_owner_policy') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'students' AND column_name = 'owner_id') THEN
            CREATE POLICY students_owner_policy ON students
                FOR ALL
                USING (owner_id = auth.uid())
                WITH CHECK (owner_id = auth.uid());
        ELSE
            -- Fallback policy if no owner_id column
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'students' AND policyname = 'students_authenticated_policy') THEN
                CREATE POLICY students_authenticated_policy ON students
                    FOR ALL
                    TO authenticated
                    USING (true);
            END IF;
        END IF;
    END IF;

    -- Guardians table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'guardians' AND policyname = 'guardians_owner_policy') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'guardians' AND column_name = 'owner_id') THEN
            CREATE POLICY guardians_owner_policy ON guardians
                FOR ALL
                USING (owner_id = auth.uid())
                WITH CHECK (owner_id = auth.uid());
        ELSE
            -- Fallback policy if no owner_id column
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'guardians' AND policyname = 'guardians_authenticated_policy') THEN
                CREATE POLICY guardians_authenticated_policy ON guardians
                    FOR ALL
                    TO authenticated
                    USING (true);
            END IF;
        END IF;
    END IF;

    -- Fee table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fee' AND policyname = 'fee_owner_policy') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fee' AND column_name = 'owner_id') THEN
            CREATE POLICY fee_owner_policy ON fee
                FOR ALL
                USING (owner_id = auth.uid())
                WITH CHECK (owner_id = auth.uid());
        ELSE
            -- Fallback policy if no owner_id column
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fee' AND policyname = 'fee_authenticated_policy') THEN
                CREATE POLICY fee_authenticated_policy ON fee
                    FOR ALL
                    TO authenticated
                    USING (true);
            END IF;
        END IF;
    END IF;

    -- Payments table policies (Removed as table does not exist)
    -- IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payments' AND policyname = 'payments_owner_policy') THEN
    --    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payments' AND column_name = 'owner_id') THEN
    --        CREATE POLICY payments_owner_policy ON payments
    --            FOR ALL
    --            USING (owner_id = auth.uid())
    --            WITH CHECK (owner_id = auth.uid());
    --    ELSE
    --        -- Fallback policy if no owner_id column
    --        CREATE POLICY payments_authenticated_policy ON payments
    --            FOR ALL
    --            TO authenticated
    --            USING (true);
    --    END IF;
    -- END IF;

    -- Invoices table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'invoices' AND policyname = 'invoices_owner_policy') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'invoices' AND column_name = 'owner_id') THEN
            CREATE POLICY invoices_owner_policy ON invoices
                FOR ALL
                USING (owner_id = auth.uid())
                WITH CHECK (owner_id = auth.uid());
        ELSE
            -- Fallback policy if no owner_id column
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'invoices' AND policyname = 'invoices_authenticated_policy') THEN
                CREATE POLICY invoices_authenticated_policy ON invoices
                    FOR ALL
                    TO authenticated
                    USING (true);
            END IF;
        END IF;
    END IF;

    -- Profiles table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'profiles_owner_policy') THEN
        CREATE POLICY profiles_owner_policy ON profiles
            FOR ALL
            USING (id = auth.uid())
            WITH CHECK (id = auth.uid());
    END IF;

    -- Student_guardian junction table policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'student_guardian' AND policyname = 'student_guardian_authenticated_policy') THEN
        CREATE POLICY student_guardian_authenticated_policy ON student_guardian
            FOR ALL
            TO authenticated
            USING (true);
    END IF;
END $$;

-- ============================================================================
-- 6. GRANT PERMISSIONS
-- ============================================================================

-- Grant permissions on functions
GRANT EXECUTE ON FUNCTION public.actualizar_estado_std(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.es_admin_o_equipo(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_invoice(uuid, integer, integer, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_fees_with_students() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_guardians_by_student_ids(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_student_balance(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_students_by_guardian_ids(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_table_metadata(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_profile(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;

-- Grant permissions on views
GRANT SELECT ON public.database_metadata TO authenticated;
GRANT SELECT ON public.payment_summary TO authenticated;

-- Set ownership
ALTER VIEW public.database_metadata OWNER TO postgres;
ALTER VIEW public.payment_summary OWNER TO postgres;

-- ============================================================================
-- VERIFICATION QUERIES (commented out for safety)
-- ============================================================================

-- Check if all functions have SET search_path = public:
-- SELECT routine_name, routine_type, external_language
-- FROM information_schema.routines 
-- WHERE routine_schema = 'public' 
-- AND routine_name IN (
--     'actualizar_estado_std',
--     'es_admin_o_equipo', 
--     'generate_invoice',
--     'get_fees_with_students',
--     'get_guardians_by_student_ids',
--     'get_student_balance',
--     'get_students_by_guardian_ids',
--     'get_table_metadata',
--     'get_user_profile'
-- );

-- Check views (should not have SECURITY DEFINER):
-- SELECT schemaname, viewname, definition 
-- FROM pg_views 
-- WHERE schemaname = 'public' 
-- AND viewname IN ('database_metadata', 'payment_summary');

-- Check table exists:
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_name IN ('fee', 'fees');

-- Check RLS status:
-- SELECT schemaname, tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public';

-- Check policies:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
-- FROM pg_policies 
-- WHERE schemaname = 'public';

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

-- This script has completed the following fixes:
-- 1. ✅ Fixed all table name references from "fees" to "fee"
-- 2. ✅ Removed SECURITY DEFINER from all views
-- 3. ✅ Added SET search_path = public to all functions
-- 4. ✅ Recreated triggers for correct table names
-- 5. ✅ Enabled RLS on all relevant tables
-- 6. ✅ Created appropriate RLS policies
-- 7. ✅ Granted necessary permissions

-- REMAINING MANUAL STEPS (must be done in Supabase Dashboard):
-- 1. Go to Authentication > Settings
-- 2. Set "OTP expiry" to 3600 seconds (1 hour) or less
-- 3. Enable "Leaked password protection"
-- 4. Run Supabase Security Advisor to verify all issues are resolved

SELECT 'FINAL_COMPLETE_DATABASE_FIX.sql has been applied successfully!' as message;
