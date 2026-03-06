--- ============================================================
-- FILL MISSING FOLIO MATRICULA FOR 2026 ENROLLMENTS
-- Format: ENR-2026-NNNNNN (e.g., ENR-2026-000058)
-- Only fills enrollments with NULL or empty folio in meta
-- Avoids duplicating existing folios
-- Run in Supabase SQL Editor
-- ============================================================

-- Step 1: Check current state (diagnostic)
DO $$
DECLARE
  v_total int;
  v_with_folio int;
  v_without_folio int;
  v_max_existing int;
BEGIN
  SELECT count(*) INTO v_total
    FROM public.enrollments WHERE year = 2026;

  SELECT count(*) INTO v_with_folio
    FROM public.enrollments
   WHERE year = 2026
     AND meta->>'folio' IS NOT NULL
     AND meta->>'folio' != '';

  v_without_folio := v_total - v_with_folio;

  SELECT COALESCE(MAX(
    CASE
      WHEN meta->>'folio' ~ '^ENR-2026-\d+$'
      THEN (regexp_replace(meta->>'folio', '^ENR-2026-', ''))::int
      ELSE 0
    END
  ), 0) INTO v_max_existing
    FROM public.enrollments
   WHERE year = 2026
     AND meta->>'folio' IS NOT NULL;

  RAISE NOTICE '=== DIAGNÓSTICO FOLIOS 2026 ===';
  RAISE NOTICE 'Total matrículas 2026: %', v_total;
  RAISE NOTICE 'Con folio: %', v_with_folio;
  RAISE NOTICE 'Sin folio (se rellenarán): %', v_without_folio;
  RAISE NOTICE 'Folio máximo existente: ENR-2026-%', to_char(v_max_existing, 'FM000000');
END $$;

-- Step 2: Fill missing folios (ordered by created_at, sequential after max existing)
DO $$
DECLARE
  v_next_seq bigint;
  v_count int := 0;
  r record;
BEGIN
  -- Get current max folio number across all years to avoid any collision
  SELECT COALESCE(MAX(
    CASE
      WHEN meta->>'folio' ~ '^ENR-\d{4}-\d+$'
      THEN (regexp_replace(meta->>'folio', '^ENR-\d{4}-', ''))::int
      ELSE 0
    END
  ), 0) INTO v_next_seq
    FROM public.enrollments
   WHERE meta->>'folio' IS NOT NULL;

  RAISE NOTICE 'Starting after folio number: %', v_next_seq;

  -- Loop through enrollments without folio, ordered by created_at
  FOR r IN
    SELECT id
      FROM public.enrollments
     WHERE year = 2026
       AND (meta->>'folio' IS NULL OR meta->>'folio' = '')
     ORDER BY created_at ASC
  LOOP
    v_next_seq := v_next_seq + 1;

    UPDATE public.enrollments
       SET meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('folio', 'ENR-2026-' || to_char(v_next_seq, 'FM000000')),
           updated_at = now()
     WHERE id = r.id;

    v_count := v_count + 1;
  END LOOP;

  -- Sync the sequence for future use by finalize_enrollment
  IF v_next_seq > 0 THEN
    PERFORM setval('public.enrollment_folio_seq', v_next_seq, true);
  END IF;

  RAISE NOTICE '=== RESULTADO ===';
  RAISE NOTICE 'Folios asignados: %', v_count;
  RAISE NOTICE 'Sequence actualizada a: %', v_next_seq;
END $$;

-- Step 3: Verify results
SELECT 
  meta->>'folio' AS folio,
  id,
  year,
  status,
  created_at
FROM public.enrollments
WHERE year = 2026
ORDER BY meta->>'folio' ASC;

-- ============================================================
-- Step 4: BACKFILL — Update cheques.folio_number to match
-- the real enrollment folio (FO-04)
-- Previously cheques had a UUID substring; now they should
-- have ENR-2026-NNNNNN matching their enrollment.
-- Only updates cheques whose enrollment has a folio assigned.
-- ============================================================

-- 4a: Diagnostic — show current vs expected
SELECT 
  c.id AS cheque_id,
  c.folio_number AS current_folio,
  e.meta->>'folio' AS enrollment_folio,
  c.enrollment_id,
  CASE WHEN c.folio_number = e.meta->>'folio' THEN '✅ OK' ELSE '❌ MISMATCH' END AS status
FROM public.cheques c
JOIN public.enrollments e ON e.id = c.enrollment_id
WHERE e.meta->>'folio' IS NOT NULL
ORDER BY e.meta->>'folio', c.numero_cuota;

-- 4b: Update cheques to use real enrollment folio
UPDATE public.cheques c
   SET folio_number = e.meta->>'folio'
  FROM public.enrollments e
 WHERE c.enrollment_id = e.id
   AND e.meta->>'folio' IS NOT NULL
   AND e.meta->>'folio' <> ''
   AND (c.folio_number IS NULL OR c.folio_number <> e.meta->>'folio');

-- 4c: Verify — all cheques should now match their enrollment folio
SELECT 
  c.id AS cheque_id,
  c.folio_number,
  e.meta->>'folio' AS enrollment_folio,
  CASE WHEN c.folio_number = e.meta->>'folio' THEN '✅ OK' ELSE '❌ MISMATCH' END AS status
FROM public.cheques c
JOIN public.enrollments e ON e.id = c.enrollment_id
WHERE e.meta->>'folio' IS NOT NULL
ORDER BY e.meta->>'folio', c.numero_cuota;
