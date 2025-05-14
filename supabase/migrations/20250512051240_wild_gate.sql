/*
  # Fix RLS policies and prevent duplicates
  
  1. Changes
    - Drop and recreate policies safely using IF EXISTS checks
    - Add proper RLS policies for profiles, student_guardian, and auth_logs
    - Prevent policy name conflicts
  
  2. Security
    - Maintain proper access control
    - Enable RLS on all tables
    - Add appropriate policies for CRUD operations
*/

-- First, safely drop existing policies on profiles
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own profile' AND tablename = 'profiles') THEN
    DROP POLICY "Users can view own profile" ON profiles;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Usuarios ven su perfil' AND tablename = 'profiles') THEN
    DROP POLICY "Usuarios ven su perfil" ON profiles;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own profile' AND tablename = 'profiles') THEN
    DROP POLICY "Users can view their own profile" ON profiles;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow role checks' AND tablename = 'profiles') THEN
    DROP POLICY "Allow role checks" ON profiles;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins can read all profiles' AND tablename = 'profiles') THEN
    DROP POLICY "Admins can read all profiles" ON profiles;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage their own profile' AND tablename = 'profiles') THEN
    DROP POLICY "Users can manage their own profile" ON profiles;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Enable read access for authenticated users' AND tablename = 'profiles') THEN
    DROP POLICY "Enable read access for authenticated users" ON profiles;
  END IF;
END $$;

-- Create new policies for profiles
CREATE POLICY "Profiles read access"
ON profiles FOR SELECT
TO authenticated
USING (
  -- Allow users to read their own profile
  id = auth.uid() OR
  -- Allow admins to read all profiles
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'ADMIN'
  )
);

CREATE POLICY "Profiles update access"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Enable RLS on student_guardian
ALTER TABLE student_guardian ENABLE ROW LEVEL SECURITY;

-- Drop existing policies on student_guardian
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Enable read for authenticated users' AND tablename = 'student_guardian') THEN
    DROP POLICY "Enable read for authenticated users" ON student_guardian;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Enable insert for authenticated users' AND tablename = 'student_guardian') THEN
    DROP POLICY "Enable insert for authenticated users" ON student_guardian;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Enable delete for authenticated users' AND tablename = 'student_guardian') THEN
    DROP POLICY "Enable delete for authenticated users" ON student_guardian;
  END IF;
END $$;

-- Create new policies for student_guardian
CREATE POLICY "Student guardian read access"
ON student_guardian FOR SELECT
TO authenticated
USING (
  -- Allow access if user is admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'ADMIN'
  ) OR
  -- Allow access if user is the guardian
  EXISTS (
    SELECT 1 FROM guardians
    WHERE id = student_guardian.guardian_id AND owner_id = auth.uid()
  ) OR
  -- Allow access if user owns the student
  EXISTS (
    SELECT 1 FROM students
    WHERE id = student_guardian.student_id AND owner_id = auth.uid()
  )
);

CREATE POLICY "Student guardian insert access"
ON student_guardian FOR INSERT
TO authenticated
WITH CHECK (
  -- Allow insert if user is admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'ADMIN'
  ) OR
  -- Allow insert if user owns the guardian
  EXISTS (
    SELECT 1 FROM guardians
    WHERE id = guardian_id AND owner_id = auth.uid()
  )
);

CREATE POLICY "Student guardian delete access"
ON student_guardian FOR DELETE
TO authenticated
USING (
  -- Allow delete if user is admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'ADMIN'
  ) OR
  -- Allow delete if user owns the guardian
  EXISTS (
    SELECT 1 FROM guardians
    WHERE id = guardian_id AND owner_id = auth.uid()
  )
);

-- Enable RLS on auth_logs
ALTER TABLE auth_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies on auth_logs
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Enable read for authenticated users' AND tablename = 'auth_logs') THEN
    DROP POLICY "Enable read for authenticated users" ON auth_logs;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Enable insert for authenticated users' AND tablename = 'auth_logs') THEN
    DROP POLICY "Enable insert for authenticated users" ON auth_logs;
  END IF;
END $$;

-- Create new policies for auth_logs
CREATE POLICY "Auth logs insert access"
ON auth_logs FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Auth logs read access"
ON auth_logs FOR SELECT
TO authenticated
USING (
  -- Allow access if user is admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'ADMIN'
  ) OR
  -- Allow access to logs with a matching user_id
  user_id = auth.uid()::text OR
  -- Allow access to logs with a null user_id (system logs)
  user_id IS NULL
);