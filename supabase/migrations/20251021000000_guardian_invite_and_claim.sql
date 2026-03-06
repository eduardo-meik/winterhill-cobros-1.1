-- Guardian Invite & Claim Flow
-- Date: 2025-10-21
-- Purpose: Allow sending a link to guardians so they can create an account, automatically
--          get the guardian role, and be linked to their existing guardian record (owner_id).
-- Safety: idempotent column adds; functions use SECURITY DEFINER and constrained search_path.

BEGIN;

-- 1) Columns on guardians (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='claim_token'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN claim_token text;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='claim_expires_at'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN claim_expires_at timestamptz;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='claimed_at'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN claimed_at timestamptz;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='guardians' AND column_name='needs_update'
  ) THEN
    ALTER TABLE public.guardians ADD COLUMN needs_update boolean DEFAULT true;
  END IF;
END$$;

-- 1.1) Unique index for claim_token (nullable)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='guardians_claim_token_unique'
  ) THEN
    CREATE UNIQUE INDEX guardians_claim_token_unique ON public.guardians (claim_token) WHERE claim_token IS NOT NULL;
  END IF;
END$$;

-- 2) Ensure pgcrypto for randomness
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 3) Function: create_guardian_invite(guardian_id, expires_in_minutes)
CREATE OR REPLACE FUNCTION public.create_guardian_invite(p_guardian_id uuid, p_expires_in_minutes int DEFAULT 10080)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_token text;
BEGIN
  -- Generate opaque token
  v_token := encode(gen_random_bytes(24), 'hex');

  UPDATE public.guardians
  SET claim_token = v_token,
      claim_expires_at = now() + make_interval(mins => COALESCE(p_expires_in_minutes, 10080)),
      updated_at = now()
  WHERE id = p_guardian_id;

  RETURN v_token;
END;
$$;

COMMENT ON FUNCTION public.create_guardian_invite(uuid, int) IS 'Generates a one-time claim token for a guardian; default expiry 7 days.';

-- 4) Function: accept_guardian_invite(token)
CREATE OR REPLACE FUNCTION public.accept_guardian_invite(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_row guardians%ROWTYPE;
  v_role text;
BEGIN
  IF v_user IS NULL THEN
    RETURN jsonb_build_object('status','not_authenticated');
  END IF;

  SELECT * INTO v_row FROM public.guardians WHERE claim_token = p_token LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','invalid_token');
  END IF;

  IF v_row.claim_expires_at IS NOT NULL AND v_row.claim_expires_at < now() THEN
    RETURN jsonb_build_object('status','expired');
  END IF;

  IF v_row.owner_id IS NOT NULL THEN
    IF v_row.owner_id = v_user THEN
      RETURN jsonb_build_object('status','already_linked','guardian_id', v_row.id);
    ELSE
      RETURN jsonb_build_object('status','claimed_by_other');
    END IF;
  END IF;

  -- Assign ownership and finalize claim
  UPDATE public.guardians
    SET owner_id = v_user,
        claimed_at = now(),
        claim_token = NULL,
        claim_expires_at = NULL,
        updated_at = now()
  WHERE id = v_row.id;

  -- Set profile role if empty
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='profiles') THEN
    SELECT role INTO v_role FROM public.profiles WHERE id = v_user;
    IF v_role IS NULL OR v_role = '' THEN
      UPDATE public.profiles SET role = 'guardian', updated_at = now() WHERE id = v_user;
    END IF;
  END IF;

  RETURN jsonb_build_object('status','linked','guardian_id', v_row.id);
END;
$$;

COMMENT ON FUNCTION public.accept_guardian_invite(text) IS 'Links the current user to a guardian record using a one-time token and sets profile role if empty.';

COMMIT;
