-- =====================================================
-- LIMPIEZA COMPLETA AMPLIADA: Eliminar TODAS las duplicaciones
-- Ejecutar en Supabase Dashboard → SQL Editor
-- =====================================================

BEGIN;

-- =============================================================================
-- PASO 1: VERIFICAR ESTADO ACTUAL
-- =============================================================================

-- Evitar columnas inexistentes y tablas opcionales
SELECT 'PROFILES TABLE' as table_name, COUNT(*) as total_records FROM profiles;
SELECT 'USER_ROLES EXISTS' as info,
       EXISTS (
         SELECT 1 FROM information_schema.tables
         WHERE table_schema = 'public' AND table_name = 'user_roles'
       ) as exists;
SELECT 'FEE TABLE (COUNT)' as table_name, COUNT(*) as total_records FROM fee;
SELECT 'PAYMENTS EXISTS' as info,
       EXISTS (
         SELECT 1 FROM information_schema.tables
         WHERE table_schema = 'public' AND table_name = 'payments'
       ) as exists;

-- =============================================================================
-- PASO 2: MIGRAR Y CONSOLIDAR DATOS
-- =============================================================================

-- Actualizar profiles.role basado en user_roles donde sea necesario
DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL THEN
    UPDATE profiles 
    SET role = ur.role 
    FROM user_roles ur 
    WHERE profiles.id = ur.user_id 
      AND (profiles.role IS NULL OR profiles.role != ur.role);
  END IF;
END $$;

-- No necesitamos migrar payments a fee porque fee ya tiene todos los datos

-- =============================================================================
-- PASO 3: ELIMINAR POLÍTICAS DUPLICADAS/OBSOLETAS
-- =============================================================================

-- 3.1 Eliminar TODAS las políticas de user_roles
DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL THEN
    DROP POLICY IF EXISTS "user_roles_read_policy" ON public.user_roles;
    DROP POLICY IF EXISTS "user_roles_insert_policy" ON public.user_roles;
    DROP POLICY IF EXISTS "user_roles_update_policy" ON public.user_roles;
    DROP POLICY IF EXISTS "user_roles_delete_policy" ON public.user_roles;
  END IF;
END $$;

-- 3.2 Eliminar TODAS las políticas de payments (tabla innecesaria)
DO $$
BEGIN
  IF to_regclass('public.payments') IS NOT NULL THEN
    DROP POLICY IF EXISTS "All authenticated users can read payments" ON public.payments;
    DROP POLICY IF EXISTS "Payments – Admin/Finance full access" ON public.payments;
    DROP POLICY IF EXISTS "payments_authenticated_policy" ON public.payments;
  END IF;
END $$;

-- 3.3 Limpiar políticas redundantes/obsoletas de fee
DROP POLICY IF EXISTS "Fee - FINANCE_MANAGER CRUD Access" ON public.fee;
DROP POLICY IF EXISTS "Fee - GUARDIAN Read Access to Own Students Fees" ON public.fee;
DROP POLICY IF EXISTS "Users can only view their own fees" ON public.fee;
DROP POLICY IF EXISTS "fee_owner_policy" ON public.fee;
DROP POLICY IF EXISTS "fee_admin_full_access" ON public.fee;
DROP POLICY IF EXISTS "fee_asist_full_access" ON public.fee;
DROP POLICY IF EXISTS "Fee - ADMIN Full Access" ON public.fee;

-- 3.4 Eliminar TODAS las políticas que dependen de get_current_user_role()
DROP POLICY IF EXISTS "Admin can manage student_guardian" ON public.student_guardian;
DROP POLICY IF EXISTS "Auth logs read access" ON public.auth_logs;
DROP POLICY IF EXISTS "Guardians - ADMIN Full Access" ON public.guardians;
DROP POLICY IF EXISTS "Guardians - FINANCE_MANAGER Read Access" ON public.guardians;
DROP POLICY IF EXISTS "Invoices – Admin/Finance full access" ON public.invoices;
DROP POLICY IF EXISTS "Student guardian delete access" ON public.student_guardian;
DROP POLICY IF EXISTS "Student guardian insert access" ON public.student_guardian;
DROP POLICY IF EXISTS "Student guardian read access" ON public.student_guardian;
DROP POLICY IF EXISTS "Students - ACADEMICO CRUD Access" ON public.students;
DROP POLICY IF EXISTS "Students - ADMIN Full Access" ON public.students;
DROP POLICY IF EXISTS "Students - FINANCE_MANAGER Read Access" ON public.students;
DROP POLICY IF EXISTS "Students - GUARDIAN Read Access" ON public.students;
DROP POLICY IF EXISTS "Students - GUARDIAN Update Access" ON public.students;

-- 3.5 Eliminar políticas de enrollment duplicadas
DROP POLICY IF EXISTS "enrollment_students_policy" ON public.enrollment_students;
DROP POLICY IF EXISTS "enrollment_documents_policy" ON public.enrollment_documents;

-- 3.6 Eliminar POLÍTICAS ADICIONALES obsoletas/duplicadas detectadas en inspección
-- AUTH_LOGS (mantendremos solo: auth_logs_admin_read, auth_logs_insert_all)
DROP POLICY IF EXISTS "Auth logs insert access" ON public.auth_logs;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.auth_logs;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.auth_logs;
DROP POLICY IF EXISTS "Enable service role full access to auth_logs" ON public.auth_logs;
DROP POLICY IF EXISTS "auth_logs_asist_read" ON public.auth_logs;

-- GUARDIANS (mantendremos solo: guardians_admin_access, guardians_asist_access)
DROP POLICY IF EXISTS "Users can delete their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Users can insert their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Users can update their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "Users can view their own guardians" ON public.guardians;
DROP POLICY IF EXISTS "guardians_admin_full_access" ON public.guardians;
DROP POLICY IF EXISTS "guardians_asist_full_access" ON public.guardians;
DROP POLICY IF EXISTS "guardians_delete_policy" ON public.guardians;
DROP POLICY IF EXISTS "guardians_insert_policy" ON public.guardians;
DROP POLICY IF EXISTS "guardians_owner_policy" ON public.guardians;
DROP POLICY IF EXISTS "guardians_read_policy" ON public.guardians;
DROP POLICY IF EXISTS "guardians_update_policy" ON public.guardians;

-- PROFILES (mantendremos: profiles_own_record, profiles_admin_access)
DROP POLICY IF EXISTS "profiles_admin_full_access" ON public.profiles;
DROP POLICY IF EXISTS "profiles_asist_full_access" ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete_admin" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
DROP POLICY IF EXISTS "profiles_own_access" ON public.profiles;

-- STUDENT_GUARDIAN (mantendremos: student_guardian_admin_access, student_guardian_asist_access)
DROP POLICY IF EXISTS "Enable read for all authenticated users" ON public.student_guardian;
DROP POLICY IF EXISTS "Guardian can view own associations" ON public.student_guardian;
DROP POLICY IF EXISTS "student_guardian_admin_full_access" ON public.student_guardian;
DROP POLICY IF EXISTS "student_guardian_asist_full_access" ON public.student_guardian;
DROP POLICY IF EXISTS "student_guardian_authenticated_policy" ON public.student_guardian;

-- STUDENTS (mantendremos: students_admin_access, students_asist_access)
DROP POLICY IF EXISTS "students_admin_full_access" ON public.students;
DROP POLICY IF EXISTS "students_asist_full_access" ON public.students;
DROP POLICY IF EXISTS "students_owner_policy" ON public.students;

-- =============================================================================
-- PASO 4: ELIMINAR FUNCIONES OBSOLETAS
-- =============================================================================

-- Esta función usa user_roles, la reemplazaremos
-- Usamos CASCADE para eliminar en cadena las políticas que dependan de esta función
-- (serán recreadas más adelante en el PASO 7)
DROP FUNCTION IF EXISTS get_current_user_role() CASCADE;

-- =============================================================================
-- PASO 5: CREAR FUNCIÓN SIMPLIFICADA QUE USA SOLO profiles
-- =============================================================================

CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role 
  FROM public.profiles 
  WHERE id = auth.uid()
  LIMIT 1;
$$;

-- =============================================================================
-- PASO 6: ELIMINAR TABLAS REDUNDANTES
-- =============================================================================

-- 6.1 Eliminar tabla user_roles completamente
DROP TABLE IF EXISTS user_roles CASCADE;

-- 6.2 Eliminar tabla payments (no usada por frontend)
DROP TABLE IF EXISTS payments CASCADE;

-- 6.3 Eliminar vista payment_summary (innecesaria sin payments)
DROP VIEW IF EXISTS payment_summary CASCADE;

-- 6.4 Eliminar columna redundante profiles.profile
ALTER TABLE profiles DROP COLUMN IF EXISTS profile;

-- 6.5 Agregar tracking de propietario en fee (quién registró el pago)
-- Nota: Usamos DEFAULT auth.uid() para que cada inserción guarde el usuario autenticado.
-- Para filas existentes, dejaremos NULL (no forzamos actualización para evitar usar auth.uid() fuera de contexto).
ALTER TABLE public.fee
  ADD COLUMN IF NOT EXISTS owner_id uuid DEFAULT auth.uid();

-- Índice para consultas por propietario
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_fee_owner_id' AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_fee_owner_id ON public.fee(owner_id);
  END IF;
END $$;

-- Trigger para asegurar owner_id siempre se complete con el usuario autenticado
CREATE OR REPLACE FUNCTION public.set_fee_owner_default()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.owner_id IS NULL THEN
    NEW.owner_id := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_fee_set_owner'
  ) THEN
    CREATE TRIGGER trg_fee_set_owner
    BEFORE INSERT ON public.fee
    FOR EACH ROW
    EXECUTE FUNCTION public.set_fee_owner_default();
  END IF;
END $$;

-- 6.6 Evitar duplicados de pagos: un pago "paid" por estudiante/cuota/año
-- Índice único parcial: permite múltiples estados pendientes, pero sólo un registro con status='paid'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'uniq_fee_paid_student_cuota_year' AND n.nspname = 'public'
  ) THEN
    CREATE UNIQUE INDEX uniq_fee_paid_student_cuota_year
      ON public.fee (student_id, numero_cuota, year_academico)
      WHERE status = 'paid';
  END IF;
END $$;

-- =============================================================================
-- PASO 7: CREAR POLÍTICAS RLS LIMPIAS Y CONSISTENTES
-- =============================================================================

-- 7.1 Política simple para profiles (sin recursión)
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_own_record" ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_access" ON public.profiles;
DROP POLICY IF EXISTS "profiles_asist_access" ON public.profiles;

CREATE POLICY "profiles_own_record" ON public.profiles
  FOR ALL TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_admin_access" ON public.profiles
  FOR ALL TO authenticated
  USING (get_current_user_role() = 'ADMIN')
  WITH CHECK (get_current_user_role() = 'ADMIN');

CREATE POLICY "profiles_asist_access" ON public.profiles
  FOR ALL TO authenticated
  USING (get_current_user_role() = 'ASIST')
  WITH CHECK (get_current_user_role() = 'ASIST');

-- 7.2 Políticas limpias para fee (tabla principal de pagos)
DROP POLICY IF EXISTS "fee_admin_access" ON public.fee;
DROP POLICY IF EXISTS "fee_asist_access" ON public.fee;
DROP POLICY IF EXISTS "fee_asist_select" ON public.fee;
DROP POLICY IF EXISTS "fee_asist_insert_specific" ON public.fee;
DROP POLICY IF EXISTS "fee_asist_update_mark_paid" ON public.fee;
DROP POLICY IF EXISTS "fee_guardian_read" ON public.fee;

CREATE POLICY "fee_admin_access" ON public.fee
  FOR ALL TO authenticated
  USING (get_current_user_role() = 'ADMIN')
  WITH CHECK (get_current_user_role() = 'ADMIN');

-- ASIST: lectura total y creación de pagos SOLO asociados a una cuota específica
CREATE POLICY "fee_asist_select" ON public.fee
  FOR SELECT TO authenticated
  USING (get_current_user_role() = 'ASIST');

CREATE POLICY "fee_asist_insert_specific" ON public.fee
  FOR INSERT TO authenticated
  WITH CHECK (
    get_current_user_role() = 'ASIST'
    AND numero_cuota IS NOT NULL
    AND student_id IS NOT NULL
    AND (owner_id IS NULL OR owner_id = auth.uid())
  );

-- ASIST: puede actualizar una cuota existente (no pagada) para marcarla como pagada
-- Restringimos a filas con numero_cuota y student_id, y el resultado debe quedar en 'paid'
CREATE POLICY "fee_asist_update_mark_paid" ON public.fee
  FOR UPDATE TO authenticated
  USING (
    get_current_user_role() = 'ASIST'
    AND numero_cuota IS NOT NULL
    AND student_id IS NOT NULL
    AND status IS DISTINCT FROM 'paid'
  )
  WITH CHECK (
    get_current_user_role() = 'ASIST'
    AND numero_cuota IS NOT NULL
    AND student_id IS NOT NULL
    AND status = 'paid'
    AND payment_date IS NOT NULL
    AND amount IS NOT NULL
  );

CREATE POLICY "fee_guardian_read" ON public.fee
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM student_guardian sg 
      WHERE sg.guardian_id = auth.uid() 
      AND sg.student_id = fee.student_id
    )
  );

-- 7.3 Políticas esenciales para students
DROP POLICY IF EXISTS "students_admin_access" ON public.students;
DROP POLICY IF EXISTS "students_asist_access" ON public.students;

CREATE POLICY "students_admin_access" ON public.students
  FOR ALL TO authenticated
  USING (get_current_user_role() = 'ADMIN')
  WITH CHECK (get_current_user_role() = 'ADMIN');

CREATE POLICY "students_asist_access" ON public.students
  FOR ALL TO authenticated
  USING (get_current_user_role() = 'ASIST')
  WITH CHECK (get_current_user_role() = 'ASIST');

-- 7.4 Políticas esenciales para guardians
DROP POLICY IF EXISTS "guardians_admin_access" ON public.guardians;
DROP POLICY IF EXISTS "guardians_asist_access" ON public.guardians;

CREATE POLICY "guardians_admin_access" ON public.guardians
  FOR ALL TO authenticated
  USING (get_current_user_role() = 'ADMIN')
  WITH CHECK (get_current_user_role() = 'ADMIN');

CREATE POLICY "guardians_asist_access" ON public.guardians
  FOR ALL TO authenticated
  USING (get_current_user_role() = 'ASIST')
  WITH CHECK (get_current_user_role() = 'ASIST');

-- 7.5 Políticas esenciales para student_guardian
DROP POLICY IF EXISTS "student_guardian_admin_access" ON public.student_guardian;
DROP POLICY IF EXISTS "student_guardian_asist_access" ON public.student_guardian;

CREATE POLICY "student_guardian_admin_access" ON public.student_guardian
  FOR ALL TO authenticated
  USING (get_current_user_role() = 'ADMIN')
  WITH CHECK (get_current_user_role() = 'ADMIN');

CREATE POLICY "student_guardian_asist_access" ON public.student_guardian
  FOR ALL TO authenticated
  USING (get_current_user_role() = 'ASIST')
  WITH CHECK (get_current_user_role() = 'ASIST');

-- 7.6 Políticas esenciales para auth_logs
DROP POLICY IF EXISTS "auth_logs_admin_read" ON public.auth_logs;
DROP POLICY IF EXISTS "auth_logs_insert_all" ON public.auth_logs;
DROP POLICY IF EXISTS "auth_logs_asist_read" ON public.auth_logs;

CREATE POLICY "auth_logs_admin_read" ON public.auth_logs
  FOR SELECT TO authenticated
  USING (get_current_user_role() = 'ADMIN');

CREATE POLICY "auth_logs_insert_all" ON public.auth_logs
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "auth_logs_asist_read" ON public.auth_logs
  FOR SELECT TO authenticated
  USING (get_current_user_role() = 'ASIST');

-- =============================================================================
-- PASO 8: NORMALIZAR VALORES DE ROLES (MAYÚSCULAS)
-- =============================================================================

-- Asegurar que todos los roles estén en mayúsculas para consistencia
UPDATE profiles SET role = UPPER(role) WHERE role IS NOT NULL;

-- =============================================================================
-- PASO 9: VERIFICAR RESULTADO FINAL
-- =============================================================================

-- Ver estructura final limpia
SELECT 
    'PROFILES FINAL' as status,
    id, 
    email, 
    role,
    first_name,
    last_name
FROM profiles 
ORDER BY role, email;

-- Ver políticas limpias
SELECT 
    tablename, 
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'fee', 'students', 'guardians', 'student_guardian', 'auth_logs')
ORDER BY tablename, policyname;

-- Verificar que las tablas duplicadas fueron eliminadas
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_roles', 'payments', 'payment_summary')
ORDER BY table_name;

COMMIT;

-- =============================================================================
-- RESULTADO ESPERADO:
-- =============================================================================
/*
DESPUÉS DE ESTE SCRIPT AMPLIADO:

✅ ELIMINADO: Tabla user_roles (duplicada con profiles)
✅ ELIMINADO: Tabla payments (no usada por frontend)
✅ ELIMINADO: Vista payment_summary (innecesaria)
✅ ELIMINADO: Columna profiles.profile (redundante)
✅ ELIMINADO: Políticas RLS duplicadas y obsoletas

✅ CONSERVADO: Tabla fee (principal sistema de pagos)
✅ CONSERVADO: Tabla profiles con solo profiles.role
✅ CONSERVADO: Funcionalidad completa del sistema

✅ SIMPLIFICADO: Una función get_current_user_role()
✅ SIMPLIFICADO: Políticas RLS limpias y consistentes
✅ SIMPLIFICADO: Roles normalizados en mayúsculas

SISTEMA FINAL LIMPIO:
- Tabla profiles (con role únicamente)
- Tabla fee (sistema principal de pagos)
- Políticas RLS simples y consistentes
- Sin duplicaciones ni redundancias
- Frontend sin cambios (usa fee)
*/