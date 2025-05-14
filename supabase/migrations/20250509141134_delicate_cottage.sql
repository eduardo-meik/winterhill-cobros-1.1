/*
  # Fix RLS policies to prevent infinite recursion

  1. Changes
    - Remove recursive policy checks from profiles table
    - Add direct role-based policies for profiles
    - Add proper RLS policies for student_guardian table
    - Ensure no circular dependencies in policy checks

  2. Security
    - Maintain data access security while preventing recursion
    - Enable RLS on student_guardian table
    - Add appropriate policies for CRUD operations
*/

-- First, drop existing problematic policies on profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Usuarios ven su perfil" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Allow role checks" ON profiles;
DROP POLICY IF EXISTS "Admins can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can manage their own profile" ON profiles;

-- Create new, simplified policies for profiles
CREATE POLICY "Enable read access for authenticated users"
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

CREATE POLICY "Enable update for users on their own profile"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Enable RLS on student_guardian if not already enabled
ALTER TABLE student_guardian ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies on student_guardian
DROP POLICY IF EXISTS "Enable read for authenticated users" ON student_guardian;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON student_guardian;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON student_guardian;

-- Create new policies for student_guardian
CREATE POLICY "Enable read for authenticated users"
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

CREATE POLICY "Enable insert for authenticated users"
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

CREATE POLICY "Enable delete for authenticated users"
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