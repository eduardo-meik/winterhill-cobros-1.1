/*
  # Guardian Update API Migration

  1. New Functions
    - `update_guardian`: Function to update guardian information with validation
      - Validates input data
      - Updates guardian record
      - Returns updated guardian data
      - Handles errors appropriately

  2. Security
    - Function is only accessible to authenticated users
    - Users can only update guardians they own
    - Input validation prevents invalid data

  3. Validation Rules
    - Required fields cannot be null/empty
    - RUN must match Chilean format
    - Email must be valid format
    - Relationship type must be valid option
*/

-- Create custom types for better error handling
DO $$ BEGIN
    CREATE TYPE guardian_update_result AS (
        success boolean,
        data json,
        error text
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create function to update guardian
CREATE OR REPLACE FUNCTION update_guardian(
    p_guardian_id uuid,
    p_data json
) RETURNS guardian_update_result
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_guardian guardians;
    v_result guardian_update_result;
    v_user_id uuid;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    -- Check if guardian exists and belongs to user
    SELECT * INTO v_guardian
    FROM guardians
    WHERE id = p_guardian_id AND owner_id = v_user_id;
    
    IF v_guardian IS NULL THEN
        v_result := (FALSE, NULL::json, 'Guardian not found or access denied')::guardian_update_result;
        RETURN v_result;
    END IF;

    -- Validate required fields if they're being updated
    IF (p_data->>'first_name') IS NOT NULL AND (p_data->>'first_name') = '' THEN
        v_result := (FALSE, NULL::json, 'First name cannot be empty')::guardian_update_result;
        RETURN v_result;
    END IF;

    IF (p_data->>'last_name') IS NOT NULL AND (p_data->>'last_name') = '' THEN
        v_result := (FALSE, NULL::json, 'Last name cannot be empty')::guardian_update_result;
        RETURN v_result;
    END IF;

    -- Validate RUN format if provided
    IF (p_data->>'run') IS NOT NULL THEN
        IF NOT (p_data->>'run' ~ '^\d{7,8}-[\dkK]$') THEN
            v_result := (FALSE, NULL::json, 'Invalid RUN format')::guardian_update_result;
            RETURN v_result;
        END IF;
        
        -- Check if RUN is already in use by another guardian
        IF EXISTS (
            SELECT 1 FROM guardians 
            WHERE run = (p_data->>'run')::text 
            AND id != p_guardian_id
        ) THEN
            v_result := (FALSE, NULL::json, 'RUN already in use')::guardian_update_result;
            RETURN v_result;
        END IF;
    END IF;

    -- Validate email format if provided
    IF (p_data->>'email') IS NOT NULL AND (p_data->>'email') != '' THEN
        IF NOT (p_data->>'email' ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            v_result := (FALSE, NULL::json, 'Invalid email format')::guardian_update_result;
            RETURN v_result;
        END IF;
    END IF;

    -- Validate relationship type if provided
    IF (p_data->>'relationship_type') IS NOT NULL THEN
        IF (p_data->>'relationship_type') NOT IN ('Padre', 'Madre', 'Tutor') THEN
            v_result := (FALSE, NULL::json, 'Invalid relationship type')::guardian_update_result;
            RETURN v_result;
        END IF;
    END IF;

    -- Update guardian
    UPDATE guardians
    SET
        first_name = COALESCE((p_data->>'first_name')::text, first_name),
        last_name = COALESCE((p_data->>'last_name')::text, last_name),
        run = COALESCE((p_data->>'run')::text, run),
        email = COALESCE((p_data->>'email')::text, email),
        phone = COALESCE((p_data->>'phone')::text, phone),
        address = COALESCE((p_data->>'address')::text, address),
        relationship_type = COALESCE((p_data->>'relationship_type')::text, relationship_type),
        updated_at = now()
    WHERE id = p_guardian_id
    RETURNING * INTO v_guardian;

    -- Return success result with updated data
    v_result := (
        TRUE,
        row_to_json(v_guardian),
        NULL
    )::guardian_update_result;
    
    RETURN v_result;

EXCEPTION WHEN others THEN
    -- Handle unexpected errors
    v_result := (FALSE, NULL::json, SQLERRM)::guardian_update_result;
    RETURN v_result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_guardian TO authenticated;

-- Create API endpoint for guardian updates
CREATE OR REPLACE FUNCTION api_update_guardian(
    guardian_id uuid,
    data json
) RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result guardian_update_result;
BEGIN
    -- Call update function
    v_result := update_guardian(guardian_id, data);
    
    -- Return appropriate response
    IF v_result.success THEN
        RETURN json_build_object(
            'status', 'success',
            'data', v_result.data,
            'message', 'Guardian updated successfully'
        );
    ELSE
        RETURN json_build_object(
            'status', 'error',
            'message', v_result.error
        );
    END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION api_update_guardian TO authenticated;

COMMENT ON FUNCTION update_guardian IS 'Internal function to update guardian information with validation';
COMMENT ON FUNCTION api_update_guardian IS 'API endpoint to update guardian information';