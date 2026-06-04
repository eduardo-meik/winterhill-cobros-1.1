-- =====================================================
-- FIX: Make RUN column nullable or add default value
-- =====================================================
-- The guardians.run column has a NOT NULL constraint but 
-- auto-creation logic doesn't provide a value
-- Choose ONE of these solutions:

-- =====================================================
-- OPTION 1: Make RUN nullable (RECOMMENDED)
-- =====================================================
-- This allows creating guardians without RUN initially
-- User can update it later through their profile

ALTER TABLE guardians 
ALTER COLUMN run DROP NOT NULL;

-- =====================================================
-- OPTION 2: Add a default temporary RUN value
-- =====================================================
-- This keeps NOT NULL but provides a default

ALTER TABLE guardians 
ALTER COLUMN run SET DEFAULT '00000000-0';

-- You may still want to make it nullable for flexibility:
ALTER TABLE guardians 
ALTER COLUMN run DROP NOT NULL;

-- =====================================================
-- OPTION 3: Create guardian with temporary RUN
-- =====================================================
-- If you keep NOT NULL, always provide a temp RUN when inserting

-- Fixed insert query:
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
  '11111111-1',  -- Temporary RUN
  (SELECT email FROM auth.users WHERE id = auth.uid()),
  'TITULAR',
  'PADRE_MADRE'
WHERE NOT EXISTS (
  SELECT 1 FROM guardians WHERE owner_id = auth.uid()
);

-- =====================================================
-- RECOMMENDED APPROACH
-- =====================================================
-- 1. Make RUN nullable (run OPTION 1)
-- 2. Update ensure_guardian_for_user function to NOT require RUN
-- 3. Add UI for guardians to complete their profile
-- 4. Make RUN optional in forms until guardian completes onboarding

-- Execute this:
ALTER TABLE guardians ALTER COLUMN run DROP NOT NULL;

-- Then create guardian without RUN:
INSERT INTO guardians (
  owner_id,
  first_name,
  last_name,
  email,
  tipo_apoderado,
  relationship_type
)
SELECT 
  auth.uid(),
  'Apoderado',
  'De Prueba',
  (SELECT email FROM auth.users WHERE id = auth.uid()),
  'TITULAR',
  'PADRE_MADRE'
WHERE NOT EXISTS (
  SELECT 1 FROM guardians WHERE owner_id = auth.uid()
);

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check if RUN is still NOT NULL:
SELECT 
  column_name, 
  is_nullable, 
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'guardians' 
  AND column_name = 'run';

-- Expected result after OPTION 1:
-- column_name | is_nullable | data_type     | column_default
-- run         | YES         | character varying | null

-- Check existing guardians:
SELECT id, owner_id, first_name, last_name, run, email
FROM guardians
ORDER BY created_at DESC
LIMIT 5;
