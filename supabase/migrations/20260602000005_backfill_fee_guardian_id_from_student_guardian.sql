BEGIN;

-- Keep fee.guardian_id populated from student_guardian when missing.
CREATE OR REPLACE FUNCTION public.sync_fee_guardian_id_from_student_guardian()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.guardian_id IS NULL AND NEW.student_id IS NOT NULL THEN
    SELECT sg.guardian_id
    INTO NEW.guardian_id
    FROM public.student_guardian sg
    WHERE sg.student_id = NEW.student_id
      AND sg.guardian_id IS NOT NULL
    ORDER BY COALESCE(sg.is_primary, false) DESC, sg.created_at ASC, sg.id ASC
    LIMIT 1;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_fee_guardian_id ON public.fee;

CREATE TRIGGER trg_sync_fee_guardian_id
BEFORE INSERT OR UPDATE OF student_id, guardian_id
ON public.fee
FOR EACH ROW
EXECUTE FUNCTION public.sync_fee_guardian_id_from_student_guardian();

WITH ranked_guardian AS (
  SELECT
    sg.student_id,
    sg.guardian_id,
    ROW_NUMBER() OVER (
      PARTITION BY sg.student_id
      ORDER BY COALESCE(sg.is_primary, false) DESC, sg.created_at ASC, sg.id ASC
    ) AS rn
  FROM public.student_guardian sg
  WHERE sg.guardian_id IS NOT NULL
)
UPDATE public.fee f
SET
  guardian_id = rg.guardian_id,
  updated_at = now()
FROM ranked_guardian rg
WHERE rg.rn = 1
  AND f.student_id = rg.student_id
  AND f.guardian_id IS NULL;

COMMIT;
