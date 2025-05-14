/*
  # Fix guardian_id constraint in fee table

  1. Changes
    - Make guardian_id column nullable in fee table
    - Update existing records to handle null guardian_id
  
  2. Security
    - Maintains existing RLS policies
*/

-- Make guardian_id nullable
DO $$ 
BEGIN
  -- Drop the existing foreign key constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'fee' 
    AND constraint_type = 'FOREIGN KEY'
    AND constraint_name = 'fee_guardian_id_fkey'
  ) THEN
    ALTER TABLE fee DROP CONSTRAINT fee_guardian_id_fkey;
  END IF;

  -- Recreate the foreign key constraint allowing null values
  ALTER TABLE fee 
    ADD CONSTRAINT fee_guardian_id_fkey 
    FOREIGN KEY (guardian_id) 
    REFERENCES guardians(id) 
    ON DELETE SET NULL;

  -- Drop the not null constraint if it exists
  ALTER TABLE fee ALTER COLUMN guardian_id DROP NOT NULL;

END $$;