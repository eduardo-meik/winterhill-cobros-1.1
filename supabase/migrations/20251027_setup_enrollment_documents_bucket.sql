-- =====================================================
-- MIGRATION: Setup Storage Bucket for Enrollment Documents
-- Date: 2025-10-27
-- Description: Creates bucket and RLS policies for storing
--              generated PDF documents (Pagaré, etc.)
-- =====================================================

-- 1. CREATE STORAGE BUCKET
-- Note: This must be executed in Supabase Dashboard > Storage
-- or via Supabase CLI, not via standard SQL migration
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES (
--   'enrollment-documents',
--   'enrollment-documents',
--   false, -- private bucket
--   10485760, -- 10MB limit
--   ARRAY['application/pdf']
-- );

-- Alternative: Use Supabase Dashboard to create bucket with these settings:
-- Name: enrollment-documents
-- Public: No (private)
-- File size limit: 10 MB
-- Allowed MIME types: application/pdf

-- =====================================================
-- 2. RLS POLICIES FOR STORAGE
-- =====================================================

-- Policy: Allow authenticated users to upload documents
CREATE POLICY "Users can upload enrollment documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'enrollment-documents' 
  AND auth.uid() IS NOT NULL
);

-- Policy: Users can view their own documents (guardians see their enrollments)
CREATE POLICY "Guardians can view their enrollment documents"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND (
    -- Admin role can see all
    auth.jwt()->>'role' = 'admin'
    OR
    -- Guardian can see documents from their enrollments
    EXISTS (
      SELECT 1 
      FROM enrollment_documents ed
      JOIN enrollments e ON e.id = ed.enrollment_id
      WHERE ed.storage_path = storage.objects.name
        AND e.guardian_id::text = auth.uid()::text
    )
  )
);

-- Policy: Allow users to update their own documents (regenerate)
CREATE POLICY "Users can update their enrollment documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND (
    auth.jwt()->>'role' = 'admin'
    OR
    EXISTS (
      SELECT 1 
      FROM enrollment_documents ed
      JOIN enrollments e ON e.id = ed.enrollment_id
      WHERE ed.storage_path = storage.objects.name
        AND e.guardian_id::text = auth.uid()::text
    )
  )
);

-- Policy: Only admins can delete documents
CREATE POLICY "Only admins can delete enrollment documents"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND auth.jwt()->>'role' = 'admin'
);

-- =====================================================
-- 3. HELPER FUNCTIONS
-- =====================================================

-- Function: Get signed URL for document (valid for 1 hour)
CREATE OR REPLACE FUNCTION get_enrollment_document_url(document_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  storage_path_val TEXT;
  signed_url TEXT;
BEGIN
  -- Get storage path
  SELECT storage_path INTO storage_path_val
  FROM enrollment_documents
  WHERE id = document_id;
  
  IF storage_path_val IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Generate signed URL (valid for 1 hour)
  -- Note: This requires Supabase Storage API
  -- In practice, this is handled by the frontend using supabase.storage.from().createSignedUrl()
  RETURN storage_path_val;
END;
$$;

-- =====================================================
-- 4. VERIFICATION QUERIES
-- =====================================================

-- Verify bucket exists
-- SELECT * FROM storage.buckets WHERE id = 'enrollment-documents';

-- Verify policies
-- SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%enrollment%';

-- Test document count
-- SELECT COUNT(*) FROM enrollment_documents WHERE pdf_url IS NOT NULL;

-- =====================================================
-- MANUAL STEPS REQUIRED:
-- =====================================================
-- 1. Go to Supabase Dashboard > Storage
-- 2. Click "Create new bucket"
-- 3. Name: enrollment-documents
-- 4. Public: OFF (private bucket)
-- 5. File size limit: 10 MB
-- 6. Allowed MIME types: application/pdf
-- 7. Click "Create bucket"
-- 8. Run this migration to set up RLS policies
-- =====================================================
