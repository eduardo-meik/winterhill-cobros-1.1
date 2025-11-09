-- Migration: Rate limiting primitives (fixed window)
-- Date: 2025-11-08

-- 1) Counter table (fixed window)
CREATE TABLE IF NOT EXISTS public.rate_limit_counters (
  key text NOT NULL,
  window_start timestamptz NOT NULL,
  count integer NOT NULL DEFAULT 0,
  CONSTRAINT rate_limit_counters_pkey PRIMARY KEY (key, window_start)
);

CREATE INDEX IF NOT EXISTS rate_limit_counters_window_idx ON public.rate_limit_counters(window_start);

-- 2) Function: check and increment atomically
-- Returns: allowed, remaining, reset_at, current_count
CREATE OR REPLACE FUNCTION public.check_and_increment_rate_limit(
  p_key text,
  p_limit integer,
  p_window_seconds integer,
  p_now timestamptz DEFAULT now()
) RETURNS TABLE (
  allowed boolean,
  remaining integer,
  reset_at timestamptz,
  current_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp AS
$$
DECLARE
  v_window_start timestamptz;
  v_count integer;
  v_reset_at timestamptz;
BEGIN
  -- Compute fixed window start aligned to p_window_seconds
  v_window_start := to_timestamp(floor(extract(epoch from p_now) / p_window_seconds) * p_window_seconds);

  -- Upsert increment
  INSERT INTO public.rate_limit_counters(key, window_start, count)
  VALUES (p_key, v_window_start, 1)
  ON CONFLICT (key, window_start)
  DO UPDATE SET count = public.rate_limit_counters.count + 1
  RETURNING count INTO v_count;

  v_reset_at := v_window_start + make_interval(secs => p_window_seconds);

  allowed := (v_count <= p_limit);
  remaining := GREATEST(p_limit - v_count, 0);
  reset_at := v_reset_at;
  current_count := v_count;
  RETURN;
END;
$$;

COMMENT ON FUNCTION public.check_and_increment_rate_limit IS 'Fixed-window rate limit: increments counter and indicates if within limit.';

-- Permissions: callable by service role; block anon/authenticated if desired
REVOKE ALL ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) TO postgres;
GRANT EXECUTE ON FUNCTION public.check_and_increment_rate_limit(text, integer, integer, timestamptz) TO service_role;
