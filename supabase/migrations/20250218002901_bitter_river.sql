/*
  # Fix fee table date columns

  1. Changes
    - Rename payment_date to due_date to match the expected column name
    - Add indexes for improved query performance

  2. Security
    - No security changes needed
*/

-- Rename payment_date to due_date if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'fee' AND column_name = 'payment_date'
  ) THEN
    ALTER TABLE fee RENAME COLUMN payment_date TO due_date;
  END IF;
END $$;

-- Create or replace indexes
DO $$ 
BEGIN
  -- Drop existing indexes if they exist
  DROP INDEX IF EXISTS idx_fee_payment_date;
  DROP INDEX IF EXISTS idx_fee_due_date;
  
  -- Create new index for due_date
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_fee_due_date'
  ) THEN
    CREATE INDEX idx_fee_due_date ON fee(due_date);
  END IF;
END $$;