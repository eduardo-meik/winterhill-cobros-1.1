/*
  # Fix auth logs table structure

  1. Changes
    - Drop and recreate auth_logs table with text user_id
    - Add proper indexes and policies
    - Grant necessary permissions

  2. Security
    - Enable RLS
    - Add policy for users to view their own logs
    - Add policy for inserting logs
*/

-- Drop existing auth_logs table if it exists
DROP TABLE IF EXISTS auth_logs;

-- Create auth_logs table with correct structure
CREATE TABLE auth_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  code text,
  user_id text,
  message text,
  action text,
  metadata jsonb
);

-- Enable RLS
ALTER TABLE auth_logs ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own logs"
  ON auth_logs
  FOR SELECT
  TO authenticated
  USING (user_id::text = auth.uid()::text OR user_id IS NULL);

CREATE POLICY "Users can insert logs"
  ON auth_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Grant permissions
GRANT SELECT, INSERT ON auth_logs TO authenticated;

-- Create indexes
CREATE INDEX idx_auth_logs_user_id ON auth_logs(user_id);
CREATE INDEX idx_auth_logs_created_at ON auth_logs(created_at DESC);