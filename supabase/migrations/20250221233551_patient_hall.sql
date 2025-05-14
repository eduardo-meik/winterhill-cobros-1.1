/*
  # Fix auth_logs RLS policies

  1. Changes
    - Drop existing RLS policies
    - Create new policies that allow:
      - Authenticated users to insert logs
      - Authenticated users to view their own logs
      - System to view all logs
  
  2. Security
    - Enable RLS
    - Restrict access based on user_id
    - Allow system-wide access for monitoring
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own logs" ON auth_logs;
DROP POLICY IF EXISTS "Users can insert logs" ON auth_logs;

-- Create new policies
CREATE POLICY "Enable insert access for authenticated users"
  ON auth_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Enable read access for authenticated users"
  ON auth_logs
  FOR SELECT
  TO authenticated
  USING (
    -- Allow users to view their own logs
    (user_id::text = auth.uid()::text)
    OR
    -- Allow viewing logs without a specific user (system logs)
    (user_id IS NULL)
    OR
    -- Allow service role to view all logs
    (auth.role() = 'service_role')
  );

-- Ensure RLS is enabled
ALTER TABLE auth_logs ENABLE ROW LEVEL SECURITY;