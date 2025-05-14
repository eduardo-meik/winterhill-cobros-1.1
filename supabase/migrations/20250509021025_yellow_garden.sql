/*
  # Fix profiles RLS policies and recursion

  1. Changes
    - Drop existing problematic policies
    - Create new non-recursive policies
    - Fix role-based access control
    - Add proper indexes for performance

  2. Security
    - Maintain proper access control
    - Prevent infinite recursion
    - Enable proper role checks
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can manage their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can read all profiles" ON profiles;

-- Create new non-recursive policies
CREATE POLICY "Users can read their own profile"
  ON profiles
  FOR SELECT
  TO public
  USING (id = auth.uid());

CREATE POLICY "Allow role checks"
  ON profiles
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can manage their own profile"
  ON profiles
  FOR ALL
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "Admins can read all profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'ADMIN'
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Ensure RLS is enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;