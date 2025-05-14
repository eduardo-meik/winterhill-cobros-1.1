/*
  # Add full_name column to profiles table

  1. Changes
    - Add full_name column to profiles table
    - Update existing profiles to set full_name from first_name and last_name
    - Add trigger to keep full_name in sync with first_name and last_name

  2. Notes
    - Uses COALESCE to handle NULL values in first_name and last_name
    - Trigger ensures full_name stays synchronized with name changes
*/

-- Add full_name column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'full_name'
  ) THEN
    ALTER TABLE profiles ADD COLUMN full_name text;
  END IF;
END $$;

-- Update existing profiles to set full_name
UPDATE profiles 
SET full_name = TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, ''))
WHERE full_name IS NULL;

-- Create function to update full_name
CREATE OR REPLACE FUNCTION update_profile_full_name()
RETURNS TRIGGER AS $$
BEGIN
  NEW.full_name := TRIM(COALESCE(NEW.first_name, '') || ' ' || COALESCE(NEW.last_name, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to keep full_name in sync
DROP TRIGGER IF EXISTS update_profile_full_name_trigger ON profiles;
CREATE TRIGGER update_profile_full_name_trigger
  BEFORE INSERT OR UPDATE OF first_name, last_name
  ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_profile_full_name();