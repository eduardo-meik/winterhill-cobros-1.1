/*
  # Fix due_date constraints in fee table

  1. Changes
    - Set default value for due_date to current date
    - Ensure existing records have a valid due_date
  
  2. Security
    - Maintains existing RLS policies
*/

DO $$ 
BEGIN
  -- Set default value for due_date to current date
  ALTER TABLE fee 
    ALTER COLUMN due_date SET DEFAULT CURRENT_DATE;

  -- Update any existing NULL due_dates to current date
  UPDATE fee 
  SET due_date = CURRENT_DATE 
  WHERE due_date IS NULL;

  -- Ensure due_date is not null for future records
  ALTER TABLE fee 
    ALTER COLUMN due_date SET NOT NULL;

END $$;