-- =====================================================================
-- FIX: Convert secondary-only guardians to primary guardians
-- =====================================================================
-- ISSUE: 331 students have ONLY secondary guardians (is_primary = false)
--        but NO primary guardian. This is invalid because:
--        1. MatriculaWizard requires all students to have primary guardian
--        2. Application only creates is_primary = true relationships
--        3. These records appear backwards in Libro de Matrícula
--
-- ROOT CAUSE: Legacy data migration or manual database edits
--
-- SOLUTION: Update student_guardian relationships where student has
--           ONLY secondary guardian to make that guardian primary
-- =====================================================================

-- STEP 1: Identify students with ONLY secondary guardians (no primary)
-- This query finds the exact records that need fixing
WITH students_with_only_secondary AS (
  SELECT 
    sg.student_id,
    s.first_name || ' ' || s.apellido_paterno as estudiante,
    COUNT(CASE WHEN sg.is_primary = true OR sg.guardian_role = 'titular' THEN 1 END) as has_primary,
    COUNT(CASE WHEN sg.is_primary = false THEN 1 END) as has_secondary,
    COUNT(*) as total_guardians
  FROM student_guardian sg
  JOIN students s ON sg.student_id = s.id
  GROUP BY sg.student_id, s.first_name, s.apellido_paterno
  HAVING 
    COUNT(CASE WHEN sg.is_primary = true OR sg.guardian_role = 'titular' THEN 1 END) = 0
    AND COUNT(CASE WHEN sg.is_primary = false THEN 1 END) >= 1
)
SELECT 
  student_id,
  estudiante,
  has_primary,
  has_secondary,
  total_guardians
FROM students_with_only_secondary
ORDER BY estudiante;

-- Expected result: ~331 rows matching your provided data


-- STEP 2: BACKUP - Save current state before making changes
-- CRITICAL: Run this BEFORE executing the UPDATE
CREATE TABLE IF NOT EXISTS student_guardian_backup_20241222 AS
SELECT 
  sg.*,
  NOW() as backup_timestamp
FROM student_guardian sg
WHERE sg.student_id IN (
  SELECT student_id
  FROM student_guardian
  GROUP BY student_id
  HAVING 
    COUNT(CASE WHEN is_primary = true OR guardian_role = 'titular' THEN 1 END) = 0
    AND COUNT(CASE WHEN is_primary = false THEN 1 END) >= 1
);

-- Verify backup created
SELECT COUNT(*) as backed_up_relationships 
FROM student_guardian_backup_20241222;


-- STEP 3: FIX - Update is_primary = false to is_primary = true
-- For students who have ONLY secondary guardians (no primary)
-- IMPORTANT: This only affects students with NO primary guardian
UPDATE student_guardian
SET 
  is_primary = true,
  guardian_role = CASE 
    -- If guardian_role was 'suplente', change to 'titular' (primary)
    WHEN guardian_role = 'suplente' THEN 'titular'
    -- Otherwise keep existing value (NULL or other)
    ELSE guardian_role
  END
WHERE student_id IN (
  -- Only students with NO primary guardian
  SELECT student_id
  FROM student_guardian
  GROUP BY student_id
  HAVING 
    COUNT(CASE WHEN is_primary = true OR guardian_role = 'titular' THEN 1 END) = 0
    AND COUNT(CASE WHEN is_primary = false THEN 1 END) >= 1
)
AND is_primary = false;  -- Only update the false records

-- Expected: ~331 rows updated (one per student, assuming single guardian each)


-- STEP 4: VERIFICATION - Confirm fix worked
-- Query 1: Students should now have ZERO cases of only-secondary
SELECT 
  sg.student_id,
  s.first_name || ' ' || s.apellido_paterno as estudiante,
  COUNT(CASE WHEN sg.is_primary = true OR sg.guardian_role = 'titular' THEN 1 END) as has_primary,
  COUNT(CASE WHEN sg.is_primary = false THEN 1 END) as has_secondary
FROM student_guardian sg
JOIN students s ON sg.student_id = s.id
GROUP BY sg.student_id, s.first_name, s.apellido_paterno
HAVING 
  COUNT(CASE WHEN sg.is_primary = true OR sg.guardian_role = 'titular' THEN 1 END) = 0
  AND COUNT(CASE WHEN sg.is_primary = false THEN 1 END) >= 1
ORDER BY estudiante;

-- Expected: 0 rows (all fixed)


-- Query 2: Distribution after fix
SELECT 
  is_primary,
  guardian_role,
  COUNT(*) as total
FROM student_guardian
GROUP BY is_primary, guardian_role
ORDER BY is_primary DESC NULLS LAST, guardian_role NULLS LAST;


-- Query 3: Sample of fixed students
SELECT 
  s.first_name || ' ' || s.apellido_paterno as estudiante,
  g.first_name || ' ' || g.last_name as apoderado,
  sg.is_primary,
  sg.guardian_role,
  sg.created_at
FROM student_guardian sg
JOIN students s ON sg.student_id = s.id
JOIN guardians g ON sg.guardian_id = g.id
WHERE sg.student_id IN (
  SELECT student_id 
  FROM student_guardian_backup_20241222 
  LIMIT 10
)
ORDER BY s.first_name, s.apellido_paterno;

-- Expected: All should show is_primary = true


-- =====================================================================
-- ROLLBACK PROCEDURE (if needed)
-- =====================================================================
-- If something goes wrong, restore from backup:
/*
UPDATE student_guardian sg
SET 
  is_primary = backup.is_primary,
  guardian_role = backup.guardian_role
FROM student_guardian_backup_20241222 backup
WHERE sg.id = backup.id;

-- Verify rollback
SELECT COUNT(*) FROM student_guardian WHERE is_primary = false;
*/


-- =====================================================================
-- EXECUTION INSTRUCTIONS
-- =====================================================================
-- 1. Run STEP 1 to see the 331 problematic students
-- 2. Run STEP 2 to create backup (MANDATORY before UPDATE)
-- 3. Run STEP 3 to fix the data (UPDATE statement)
-- 4. Run STEP 4 to verify the fix worked
-- 5. Test Libro de Matrícula Excel download
-- 6. If all works correctly, drop backup table after 1 week:
--    DROP TABLE student_guardian_backup_20241222;
-- =====================================================================
