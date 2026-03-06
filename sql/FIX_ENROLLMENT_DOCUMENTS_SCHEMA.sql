-- =====================================================
-- FIX: Add missing final_content column to enrollment_documents
-- Date: 2025-10-27
-- Issue: PGRST204 - Could not find the 'final_content' column
-- =====================================================

-- Check current table structure
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns 
WHERE table_name = 'enrollment_documents'
ORDER BY ordinal_position;

-- Add final_content column if it doesn't exist
ALTER TABLE enrollment_documents 
ADD COLUMN IF NOT EXISTS final_content TEXT;

-- Verify the column was added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'enrollment_documents'
  AND column_name = 'final_content';

-- Optional: Add comment to explain the column
COMMENT ON COLUMN enrollment_documents.final_content IS 'Rendered HTML content of the document (after template placeholders replacement)';

