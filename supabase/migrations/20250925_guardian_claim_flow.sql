-- Guardian Claim Flow Migration (Option E)
-- Creates utilities to sanitize and validate RUN, logging table, and claim_guardian_by_run function.

-- 1. Helper function: sanitize_run
CREATE OR REPLACE FUNCTION public.sanitize_run(input text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  cleaned text;
BEGIN
  IF input IS NULL THEN RETURN NULL; END IF;
  cleaned := upper(regexp_replace(input, '[^0-9kK]', '', 'g'));
  RETURN cleaned;
END;
$$;

-- 2. Helper function: validate_run (Chile RUT DV algorithm)
CREATE OR REPLACE FUNCTION public.validate_run(input text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  run text := sanitize_run(input);
  body text;
  dv_input text;
  sum_val int := 0;
  multiplier int := 2;
  digit char;
  computed_dv text;
  remainder int;
BEGIN
  IF run IS NULL OR length(run) < 2 THEN RETURN FALSE; END IF;
  body := substring(run from 1 for length(run)-1);
  dv_input := substring(run from length(run));
  -- Compute DV
  FOR digit IN SELECT reverse_chars FROM regexp_split_to_table(reverse(body), '') AS reverse_chars LOOP
    IF digit ~ '[0-9]' THEN
      sum_val := sum_val + (cast(digit as int) * multiplier);
      multiplier := multiplier + 1;
      IF multiplier > 7 THEN multiplier := 2; END IF;
    END IF;
  END LOOP;
  remainder := 11 - (sum_val % 11);
  IF remainder = 11 THEN
    computed_dv := '0';
  ELSIF remainder = 10 THEN
    computed_dv := 'K';
  ELSE
    computed_dv := remainder::text;
  END IF;
  RETURN upper(dv_input) = upper(computed_dv);
END;
$$;

-- 3. Logging table
CREATE TABLE IF NOT EXISTS public.guardian_claim_logs (
  id bigserial PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  input_run text,
  normalized_run text,
  status text NOT NULL,
  message text,
  guardian_id uuid REFERENCES public.guardians(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- 4. Functional unique index for normalized RUN on guardians (if not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='guardians_normalized_run_unique'
  ) THEN
    CREATE UNIQUE INDEX guardians_normalized_run_unique ON public.guardians ( upper(regexp_replace(coalesce(run,''),'[^0-9kK]','','g')) );
  END IF;
END;
$$;

-- 5. Claim function
CREATE OR REPLACE FUNCTION public.claim_guardian_by_run(input_run text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  normalized text := sanitize_run(input_run);
  current_user_id uuid := auth.uid();
  existing_guardian record;
  claim_status text;
  result jsonb;
  role_current text;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Validate RUN format & DV
  IF NOT validate_run(normalized) THEN
    claim_status := 'INVALID_RUN';
    INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message)
    VALUES (current_user_id, input_run, normalized, claim_status, 'Invalid RUN / DV');
    RETURN jsonb_build_object('status', claim_status, 'message', 'RUN inválido');
  END IF;

  -- Check if a guardian with this RUN already exists
  SELECT g.* INTO existing_guardian
  FROM public.guardians g
  WHERE upper(regexp_replace(coalesce(g.run,''),'[^0-9K]','','g')) = upper(normalized)
  LIMIT 1;

  -- Get current profile role
  SELECT role INTO role_current FROM public.profiles WHERE id = current_user_id;

  IF existing_guardian IS NOT NULL THEN
    IF existing_guardian.owner_id = current_user_id THEN
      claim_status := 'ALREADY_LINKED';
      INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message, guardian_id)
      VALUES (current_user_id, input_run, normalized, claim_status, 'Already linked to this guardian', existing_guardian.id);
      RETURN jsonb_build_object('status', claim_status, 'guardian_id', existing_guardian.id, 'message', 'Ya estabas vinculado.');
    ELSIF existing_guardian.owner_id IS NOT NULL AND existing_guardian.owner_id <> current_user_id THEN
      claim_status := 'ALREADY_CLAIMED';
      INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message, guardian_id)
      VALUES (current_user_id, input_run, normalized, claim_status, 'RUN already claimed by another user', existing_guardian.id);
      RETURN jsonb_build_object('status', claim_status, 'message', 'RUN ya reclamado por otro usuario');
    ELSE
      -- Guardian exists but unowned -> claim it
      UPDATE public.guardians
        SET owner_id = current_user_id, updated_at = now()
      WHERE id = existing_guardian.id;
      claim_status := 'CLAIMED_EXISTING';
      -- Assign guardian role if profile has no role or different (basic rule: prefer admin if already admin)
      IF role_current IS NULL OR role_current = '' THEN
        UPDATE public.profiles SET role = 'guardian', updated_at = now() WHERE id = current_user_id;
      END IF;
      INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message, guardian_id)
      VALUES (current_user_id, input_run, normalized, claim_status, 'Claimed existing unowned guardian', existing_guardian.id);
      RETURN jsonb_build_object('status', claim_status, 'guardian_id', existing_guardian.id, 'message', 'Reclamado con éxito');
    END IF;
  ELSE
    -- Create new guardian record
    INSERT INTO public.guardians (id, owner_id, run, needs_update, created_at, updated_at)
    VALUES (gen_random_uuid(), current_user_id, normalized, true, now(), now())
    RETURNING * INTO existing_guardian;
    claim_status := 'CREATED_NEW';
    IF role_current IS NULL OR role_current = '' THEN
      UPDATE public.profiles SET role = 'guardian', updated_at = now() WHERE id = current_user_id;
    END IF;
    INSERT INTO guardian_claim_logs(user_id, input_run, normalized_run, status, message, guardian_id)
    VALUES (current_user_id, input_run, normalized, claim_status, 'Created new guardian');
    RETURN jsonb_build_object('status', claim_status, 'guardian_id', existing_guardian.id, 'created', true, 'message', 'Nuevo apoderado creado');
  END IF;
END;
$$;

-- 6. RLS considerations (assuming guardians table already protected by RLS). Ensure function runs with SECURITY DEFINER and limited search_path.

COMMENT ON FUNCTION public.claim_guardian_by_run(text) IS 'Claims or creates a guardian record by RUN, validates DV, logs the attempt, and assigns guardian role.';
