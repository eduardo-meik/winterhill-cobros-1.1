/*
  # Create Fee Table and Fix Auth Logs

  1. Creates fee table for payment tracking
    - Adds proper relationships with students and guardians
    - Sets up RLS policies and indexes
    - Handles payment status tracking

  2. Updates auth_logs to handle text user IDs
    - Modifies user_id column type
    - Updates policies for text comparison
*/

-- Create fees table if it doesn't exist
DO $$ 
BEGIN
  -- Create the table
  CREATE TABLE IF NOT EXISTS fee (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    student_id uuid REFERENCES students(id) ON DELETE CASCADE,
    guardian_id uuid REFERENCES guardians(id) ON DELETE SET NULL,
    amount decimal(10,2) NOT NULL,
    due_date date NOT NULL,
    payment_date date,
    status text CHECK (status IN ('paid', 'pending', 'overdue')) DEFAULT 'pending',
    payment_method text,
    owner_id uuid REFERENCES auth.users(id) NOT NULL,
    notes text
  );

  -- Enable RLS
  ALTER TABLE fee ENABLE ROW LEVEL SECURITY;

  -- Create policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'fee' 
    AND policyname = 'Users can view all fees'
  ) THEN
    CREATE POLICY "Users can view all fees"
      ON fee FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'fee' 
    AND policyname = 'Users can insert their own fees'
  ) THEN
    CREATE POLICY "Users can insert their own fees"
      ON fee FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = owner_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'fee' 
    AND policyname = 'Users can update their own fees'
  ) THEN
    CREATE POLICY "Users can update their own fees"
      ON fee FOR UPDATE
      TO authenticated
      USING (auth.uid() = owner_id)
      WITH CHECK (auth.uid() = owner_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'fee' 
    AND policyname = 'Users can delete their own fees'
  ) THEN
    CREATE POLICY "Users can delete their own fees"
      ON fee FOR DELETE
      TO authenticated
      USING (auth.uid() = owner_id);
  END IF;

  -- Create indexes
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_fee_student_id'
  ) THEN
    CREATE INDEX idx_fee_student_id ON fee(student_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_fee_guardian_id'
  ) THEN
    CREATE INDEX idx_fee_guardian_id ON fee(guardian_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_fee_due_date'
  ) THEN
    CREATE INDEX idx_fee_due_date ON fee(due_date);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_fee_status'
  ) THEN
    CREATE INDEX idx_fee_status ON fee(status);
  END IF;

EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'Error creating fee table or indexes: %', SQLERRM;
END $$;

-- Fix auth_logs user_id handling
DO $$ 
BEGIN
  -- Drop existing user_id foreign key if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'auth_logs' 
    AND constraint_type = 'FOREIGN KEY'
  ) THEN
    ALTER TABLE auth_logs DROP CONSTRAINT auth_logs_user_id_fkey;
  END IF;

  -- Modify user_id to accept text instead of uuid
  ALTER TABLE auth_logs ALTER COLUMN user_id TYPE text USING user_id::text;

EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'Error modifying auth_logs: %', SQLERRM;
END $$;

-- Update auth_logs policies to handle text user_id
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'auth_logs' 
    AND policyname = 'Users can view their own logs'
  ) THEN
    DROP POLICY "Users can view their own logs" ON auth_logs;
  END IF;

  CREATE POLICY "Users can view their own logs"
    ON auth_logs
    FOR SELECT
    TO authenticated
    USING (user_id::text = auth.uid()::text OR user_id IS NULL);

EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'Error updating auth_logs policies: %', SQLERRM;
END $$;