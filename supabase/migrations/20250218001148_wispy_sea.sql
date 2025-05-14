/*
  # Set up auth_logs table and permissions

  1. Table Creation
    - Creates auth_logs table if it doesn't exist
    - Adds necessary columns for logging auth events

  2. Security
    - Enables RLS
    - Adds policies for authenticated users
    - Grants necessary permissions
*/

-- Create auth_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS auth_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  code text,
  user_id uuid REFERENCES auth.users,
  message text,
  action text,
  metadata jsonb
);

-- Enable RLS if not already enabled
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'auth_logs' 
    AND rowsecurity = true
  ) THEN
    ALTER TABLE auth_logs ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Create policies if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'auth_logs' 
    AND policyname = 'Users can view their own logs'
  ) THEN
    CREATE POLICY "Users can view their own logs"
      ON auth_logs
      FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id OR user_id IS NULL);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'auth_logs' 
    AND policyname = 'Users can insert logs'
  ) THEN
    CREATE POLICY "Users can insert logs"
      ON auth_logs
      FOR INSERT
      TO authenticated
      WITH CHECK (true);
  END IF;
END $$;

-- Grant permissions to authenticated users
GRANT SELECT, INSERT ON auth_logs TO authenticated;

-- Create indexes if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_auth_logs_user_id'
  ) THEN
    CREATE INDEX idx_auth_logs_user_id ON auth_logs(user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_auth_logs_created_at'
  ) THEN
    CREATE INDEX idx_auth_logs_created_at ON auth_logs(created_at DESC);
  END IF;
END $$;