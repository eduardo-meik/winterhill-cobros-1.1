-- =====================================================
-- FIX: Storage RLS Policies for enrollment-documents
-- Date: 2025-10-27
-- Issue: SELECT policy fails because it compares guardian_id with auth.uid()
--        but guardian_id is not the same as owner_id (user ID)
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Guardians can view their enrollment documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their enrollment documents" ON storage.objects;

-- Recreated SELECT policy with correct logic
-- Now checks: guardian.owner_id = auth.uid() instead of guardian_id = auth.uid()
CREATE POLICY "Guardians can view their enrollment documents"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND (
    -- Admin role can see all
    (auth.jwt()->>'role' = 'admin')
    OR
    -- Guardian can see documents from their enrollments
    EXISTS (
      SELECT 1 
      FROM enrollment_documents ed
      JOIN enrollments e ON e.id = ed.enrollment_id
      JOIN guardians g ON g.id = e.guardian_id
      WHERE ed.storage_path = storage.objects.name
        AND g.owner_id = auth.uid()
    )
  )
);

-- Recreated UPDATE policy with correct logic
CREATE POLICY "Users can update their enrollment documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND (
    (auth.jwt()->>'role' = 'admin')
    OR
    EXISTS (
      SELECT 1 
      FROM enrollment_documents ed
      JOIN enrollments e ON e.id = ed.enrollment_id
      JOIN guardians g ON g.id = e.guardian_id
      WHERE ed.storage_path = storage.objects.name
        AND g.owner_id = auth.uid()
    )
  )
);

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check policies are updated
SELECT 
  policyname, 
  tablename,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'objects' 
  AND policyname LIKE '%enrollment%'
ORDER BY policyname;

-- Test: Try to list objects in bucket (should work after document is created)
-- SELECT name, created_at, metadata 
-- FROM storage.objects 
-- WHERE bucket_id = 'enrollment-documents'
-- LIMIT 10;

