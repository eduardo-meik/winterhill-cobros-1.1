/*
  # Fix profiles RLS policies to prevent infinite recursion

  1. Changes
    - Remove recursive policies from profiles table
    - Simplify read access policy to avoid infinite loops
    - Add proper admin access policy
    - Add proper user access policy for own profile

  2. Security
    - Maintain RLS enabled on profiles table
    - Ensure users can only access their own profile
    - Ensure admins can access all profiles
    - Remove policies causing recursion
*/

-- First, drop the problematic policies
DROP POLICY IF EXISTS "Enable update for users on their own profile" ON profiles;
DROP POLICY IF EXISTS "Profiles read access" ON profiles;
DROP POLICY IF EXISTS "Profiles update access" ON profiles;
DROP POLICY IF EXISTS "Users can read their own profile" ON profiles;

-- Create new, simplified policies
-- Admin full access policy
CREATE POLICY "admin_full_access"
ON profiles
FOR ALL
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'ADMIN'
  )
)
WITH CHECK (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'ADMIN'
  )
);

-- Users can read their own profile
CREATE POLICY "users_read_own_profile"
ON profiles
FOR SELECT
TO authenticated
USING (
  auth.uid() = id
);

-- Users can update their own profile
CREATE POLICY "users_update_own_profile"
ON profiles
FOR UPDATE
TO authenticated
USING (
  auth.uid() = id
)
WITH CHECK (
  auth.uid() = id
);

-- Users can insert their own profile
CREATE POLICY "users_insert_own_profile"
ON profiles
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = id
);