-- =====================================================
-- QUICK FIX: Create Guardian for Testing
-- =====================================================
-- This script creates a guardian record for the currently logged-in user
-- Run this in Supabase SQL Editor if you're getting "No guardian found" error

-- OPTION 1: Create guardian for specific user (replace with your user ID)
-- Get your user ID from: auth.users table or from browser console after login

INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  run,
  email,
  phone,
  address,
  tipo_apoderado,
  relationship_type
)
VALUES (
  'YOUR_USER_ID_HERE',  -- Replace with actual auth.uid()
  'Test',
  'Guardian',
  '12345678-9',
  'test@example.com',
  '+56912345678',
  'Test Address 123',
  'TITULAR',
  'PADRE_MADRE'
)
ON CONFLICT (owner_id) DO NOTHING;

-- =====================================================
-- OPTION 2: Auto-create guardian for current logged-in user
-- This uses a function that you may need to create first
-- =====================================================

-- First, create the function if it doesn't exist:
CREATE OR REPLACE FUNCTION ensure_guardian_for_user()
RETURNS guardians
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id UUID;
  guardian_rec guardians;
  user_email TEXT;
BEGIN
  -- Get current user
  user_id := auth.uid();
  
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Check if guardian already exists
  SELECT * INTO guardian_rec
  FROM guardians
  WHERE owner_id = user_id
  LIMIT 1;
  
  IF FOUND THEN
    RETURN guardian_rec;
  END IF;
  
  -- Get user email
  SELECT email INTO user_email
  FROM auth.users
  WHERE id = user_id;
  
  -- Create new guardian
  INSERT INTO guardians (
    owner_id,
    first_name,
    last_name,
    run,
    email,
    tipo_apoderado
  )
  VALUES (
    user_id,
    'Apoderado',  -- Default name
    'Sin Configurar',  -- Default last name
    '11111111-1',  -- Temporary RUN - user must update
    user_email,
    'TITULAR'
  )
  RETURNING * INTO guardian_rec;
  
  RETURN guardian_rec;
END;
$$;

-- Now call it to create guardian for current user:
SELECT * FROM ensure_guardian_for_user();

-- =====================================================
-- OPTION 3: Quick manual insert for current session
-- Run this to create guardian for whoever is logged in
-- =====================================================

INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  run,
  email,
  tipo_apoderado,
  relationship_type
)
SELECT 
  auth.uid(),
  'Apoderado',
  'De Prueba',
  '11111111-1',  -- Temporary RUN - UPDATE THIS LATER!
  (SELECT email FROM auth.users WHERE id = auth.uid()),
  'TITULAR',
  'PADRE_MADRE'
WHERE NOT EXISTS (
  SELECT 1 FROM guardians WHERE owner_id = auth.uid()
);

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check if guardian was created:
SELECT * FROM guardians WHERE owner_id = auth.uid();

-- Check your user ID:
SELECT auth.uid() as my_user_id;

-- =====================================================
-- TROUBLESHOOTING
-- =====================================================

-- If you get "permission denied" error:
-- 1. Make sure you're logged in to Supabase Dashboard
-- 2. Run queries as service_role or postgres user
-- 3. Check RLS policies on guardians table

-- To disable RLS temporarily for testing (NOT recommended for production):
-- ALTER TABLE guardians DISABLE ROW LEVEL SECURITY;

-- To re-enable RLS:
-- ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
