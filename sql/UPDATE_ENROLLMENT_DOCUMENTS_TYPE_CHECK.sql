-- Update enrollment_documents type check constraint to include new document types
-- This script safely drops the existing check constraint on the 'type' column and adds a new one with expanded values.

DO $$
DECLARE
    con_name text;
BEGIN
    -- Find the constraint name for the 'type' column on 'enrollment_documents' table
    -- We look for a check constraint on this table that involves the 'type' column definition
    SELECT con.conname INTO con_name
    FROM pg_catalog.pg_constraint con
    INNER JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid
    INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'enrollment_documents'
      AND con.contype = 'c'
      AND pg_get_constraintdef(con.oid) LIKE '%type%';

    IF con_name IS NOT NULL THEN
        RAISE NOTICE 'Dropping constraint: %', con_name;
        EXECUTE 'ALTER TABLE public.enrollment_documents DROP CONSTRAINT ' || quote_ident(con_name);
    ELSE
        RAISE NOTICE 'No existing constraint found for type column';
    END IF;
END $$;

-- Add the new constraint with expanded types
ALTER TABLE public.enrollment_documents
ADD CONSTRAINT enrollment_documents_type_check
CHECK (type IN ('PAGARE', 'DECLARACION', 'OTRO', 'PAGARE_DEUDA', 'PAGARE_REPACTACION', 'PRESTACION', 'PRIORITARIO'));

COMMENT ON COLUMN public.enrollment_documents.type IS 'Type of document: PAGARE, DECLARACION, OTRO, PAGARE_DEUDA, PAGARE_REPACTACION, PRESTACION, PRIORITARIO';
