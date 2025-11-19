-- Enrollment document receipts + signed_at plumbing + finalized RPC refresh
-- Safe to run multiple times.

-- 1) Ensure signatures.signed_at exists and is indexed
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'signatures' AND column_name = 'signed_at'
  ) THEN
    ALTER TABLE public.signatures
      ADD COLUMN signed_at timestamptz NOT NULL DEFAULT timezone('utc', now());
    UPDATE public.signatures
       SET signed_at = COALESCE(signed_at, created_at, timezone('utc', now()));
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_signatures_document_signed_at
  ON public.signatures(enrollment_document_id, signer_type, signed_at);

-- 2) Enrollment document receipts table (physical paperwork tracking)
CREATE TABLE IF NOT EXISTS public.enrollment_document_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_document_id uuid NOT NULL REFERENCES public.enrollment_documents(id) ON DELETE CASCADE,
  received_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  received_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  method text NOT NULL DEFAULT 'PAPER',
  evidence_url text,
  notes text,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'ux_enrollment_document_receipts_document'
       AND conrelid = 'public.enrollment_document_receipts'::regclass
  ) THEN
    ALTER TABLE public.enrollment_document_receipts
      ADD CONSTRAINT ux_enrollment_document_receipts_document UNIQUE (enrollment_document_id);
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_receipts_document ON public.enrollment_document_receipts(enrollment_document_id);
CREATE INDEX IF NOT EXISTS idx_receipts_received_by ON public.enrollment_document_receipts(received_by);

ALTER TABLE public.enrollment_document_receipts ENABLE ROW LEVEL SECURITY;

-- Allow ADMIN/ASIST full control
DROP POLICY IF EXISTS enrollment_document_receipts_staff_policy ON public.enrollment_document_receipts;
CREATE POLICY enrollment_document_receipts_staff_policy ON public.enrollment_document_receipts
  FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- Keep updated_at in sync
DROP TRIGGER IF EXISTS tr_receipts_updated_at ON public.enrollment_document_receipts;
CREATE TRIGGER tr_receipts_updated_at
  BEFORE UPDATE ON public.enrollment_document_receipts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3) Trigger helpers to mirror signatures/receipts onto enrollment_documents.signed_at
CREATE OR REPLACE FUNCTION public.trg_mark_document_signed_from_signature()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.signed_at IS NULL THEN
    RETURN NEW;
  END IF;
  UPDATE public.enrollment_documents
     SET signed_at = COALESCE(signed_at, NEW.signed_at)
   WHERE id = NEW.enrollment_document_id
     AND signed_at IS NULL;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_mark_document_signed_from_receipt()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.enrollment_documents
     SET signed_at = COALESCE(signed_at, NEW.received_at)
   WHERE id = NEW.enrollment_document_id
     AND signed_at IS NULL;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_signatures_mark_doc_signed ON public.signatures;
CREATE TRIGGER tr_signatures_mark_doc_signed
  AFTER INSERT OR UPDATE OF signed_at ON public.signatures
  FOR EACH ROW EXECUTE FUNCTION public.trg_mark_document_signed_from_signature();

DROP TRIGGER IF EXISTS tr_receipts_mark_doc_signed ON public.enrollment_document_receipts;
CREATE TRIGGER tr_receipts_mark_doc_signed
  AFTER INSERT OR UPDATE ON public.enrollment_document_receipts
  FOR EACH ROW EXECUTE FUNCTION public.trg_mark_document_signed_from_receipt();

-- 4) Helper to summarize required doc readiness (digital or physical)
CREATE OR REPLACE FUNCTION public.required_enrollment_documents_state(p_enrollment_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  WITH docs AS (
    SELECT d.type,
           EXISTS (
             SELECT 1 FROM public.signatures s
             WHERE s.enrollment_document_id = d.id
               AND s.signer_type IN ('GUARDIAN','APODERADO')
               AND s.signed_at IS NOT NULL
           ) AS has_digital,
           EXISTS (
             SELECT 1 FROM public.enrollment_document_receipts r
             WHERE r.enrollment_document_id = d.id
           ) AS has_receipt
      FROM public.enrollment_documents d
     WHERE d.enrollment_id = p_enrollment_id
  ), agg AS (
    SELECT
      bool_or(type = 'PRESTACION' AND (has_digital OR has_receipt)) AS prestacion_ready,
      bool_or(type LIKE 'PAGARE%' AND (has_digital OR has_receipt)) AS pagare_ready,
      bool_or(type = 'PRESTACION' AND has_digital) AS prestacion_digital,
      bool_or(type LIKE 'PAGARE%' AND has_digital) AS pagare_digital,
      bool_or(type = 'PRESTACION' AND has_receipt) AS prestacion_receipt,
      bool_or(type LIKE 'PAGARE%' AND has_receipt) AS pagare_receipt
    FROM docs
  )
  SELECT jsonb_build_object(
    'prestacion_ready', COALESCE(prestacion_ready, false),
    'pagare_ready', COALESCE(pagare_ready, false),
    'prestacion_digital', COALESCE(prestacion_digital, false),
    'pagare_digital', COALESCE(pagare_digital, false),
    'prestacion_receipt', COALESCE(prestacion_receipt, false),
    'pagare_receipt', COALESCE(pagare_receipt, false)
  )
  FROM agg;
$$;

COMMENT ON FUNCTION public.required_enrollment_documents_state(uuid) IS 'Returns JSON summarizing PRESTACION/PAGARE readiness (digital signatures or physical receipts).';

-- 5) RPC to record physical receipt evidence
DROP FUNCTION IF EXISTS public.record_document_receipt(uuid, jsonb);
CREATE OR REPLACE FUNCTION public.record_document_receipt(p_document_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_doc RECORD;
  v_receipt RECORD;
  v_method text := COALESCE(p_options->>'method', 'PAPER');
  v_notes text := NULLIF(p_options->>'notes', '');
  v_evidence text := NULLIF(p_options->>'evidence_url', '');
  v_meta jsonb := COALESCE(p_options->'meta', '{}'::jsonb);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'RLS_DENIED: sólo el equipo puede registrar recepción física';
  END IF;

  SELECT * INTO v_doc FROM public.enrollment_documents WHERE id = p_document_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Document % not found', p_document_id;
  END IF;

  INSERT INTO public.enrollment_document_receipts(
    enrollment_document_id, received_by, method, evidence_url, notes, meta
  ) VALUES (
    p_document_id, v_uid, v_method, v_evidence, v_notes, v_meta
  )
  ON CONFLICT (enrollment_document_id) DO UPDATE SET
    received_at = timezone('utc', now()),
    received_by = EXCLUDED.received_by,
    method = EXCLUDED.method,
    evidence_url = EXCLUDED.evidence_url,
    notes = EXCLUDED.notes,
    meta = EXCLUDED.meta,
    updated_at = timezone('utc', now())
  RETURNING * INTO v_receipt;

  INSERT INTO public.audit_logs(action, table_name, record_pk, actor_uid, reason, extra)
  VALUES (
    'DOCUMENT_RECEIPT_RECORDED',
    'enrollment_documents',
    p_document_id::text,
    v_uid,
    'physical_document_received',
    jsonb_build_object(
      'method', v_method,
      'notes', v_notes,
      'evidence_url', v_evidence,
      'meta', v_meta,
      'receipt_id', v_receipt.id,
      'enrollment_id', v_doc.enrollment_id
    )
  );

  RETURN jsonb_build_object(
    'receipt_id', v_receipt.id,
    'received_at', v_receipt.received_at,
    'method', v_receipt.method,
    'enrollment_document_id', v_receipt.enrollment_document_id
  );
END;
$$;

COMMENT ON FUNCTION public.record_document_receipt(uuid, jsonb) IS 'Staff helper to record physical paperwork reception for an enrollment document.';

REVOKE ALL ON FUNCTION public.record_document_receipt(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.record_document_receipt(uuid, jsonb) TO authenticated;

-- 6) Refresh finalize_enrollment RPC to honor receipts + stricter overrides
DROP FUNCTION IF EXISTS public.finalize_enrollment(uuid, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.finalize_enrollment(p_enrollment_id uuid, p_options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_staff boolean := public.is_staff();
  v_enrollment RECORD;
  v_year int;
  v_dry_run boolean := COALESCE((p_options->>'dry_run')::boolean, false);
  v_plan jsonb;
  v_cuotas jsonb;
  v_created int := 0;
  v_skipped int := 0;
  v_students int := 0;
  v_summary jsonb := '[]'::jsonb;
  r_es RECORD;
  r_cuota RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT e.*, g.owner_id AS guardian_owner
    INTO v_enrollment
    FROM public.enrollments e
    JOIN public.guardians g ON g.id = e.guardian_id
   WHERE e.id = p_enrollment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment % not found', p_enrollment_id;
  END IF;
  v_year := v_enrollment.year;

  IF NOT (v_is_staff OR v_enrollment.guardian_owner = v_uid) THEN
    RAISE EXCEPTION 'RLS_DENIED: you are not allowed to finalize this enrollment';
  END IF;

  -- Staff can always confirm; guardians still rely on planner safeguards above

  -- Ensure guardian-student links exist / staff fallback
  FOR r_es IN
    SELECT es.student_id
      FROM public.enrollment_students es
     WHERE es.enrollment_id = p_enrollment_id
  LOOP
    v_students := v_students + 1;
    PERFORM 1 FROM public.student_guardian sg
      WHERE sg.student_id = r_es.student_id AND sg.guardian_id = v_enrollment.guardian_id;
    IF NOT FOUND THEN
      IF v_is_staff THEN
        INSERT INTO public.student_guardian(student_id, guardian_id, is_primary)
        VALUES (r_es.student_id, v_enrollment.guardian_id, false)
        ON CONFLICT DO NOTHING;
      ELSE
        RAISE EXCEPTION 'MISSING_RELATION: student % is not linked with this guardian', r_es.student_id;
      END IF;
    END IF;
  END LOOP;

  IF v_students = 0 THEN
    RAISE EXCEPTION 'NO_STUDENTS: enrollment has no students';
  END IF;

  v_plan := p_options->'payment_plan';
  IF v_plan IS NULL THEN
    SELECT e.meta->'payment_plan' INTO v_plan FROM public.enrollments e WHERE e.id = p_enrollment_id;
  END IF;
  IF v_plan IS NULL THEN
    SELECT ed.generated_payload INTO v_plan
      FROM public.enrollment_documents ed
     WHERE ed.enrollment_id = p_enrollment_id
       AND (ed.type = 'PRESTACION' OR ed.type LIKE 'PAGARE%')
       AND ed.generated_payload IS NOT NULL
     ORDER BY CASE WHEN ed.type='PRESTACION' THEN 0 ELSE 1 END, ed.created_at DESC
     LIMIT 1;
  END IF;
  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'PLAN_MISSING: no payment plan found in options, enrollment.meta or documents';
  END IF;

  v_cuotas := v_plan->'cuotas';
  IF v_cuotas IS NULL OR jsonb_typeof(v_cuotas) <> 'array' THEN
    DECLARE
      v_n int := COALESCE((v_plan->>'n_cuotas')::int, NULL);
      v_first date := COALESCE((v_plan->>'primer_vencimiento')::date, NULL);
      v_amount numeric := COALESCE((v_plan->>'monto_por_cuota')::numeric,
                                   NULLIF((v_plan->>'monto_total')::numeric, NULL) / NULLIF(v_n,0));
      i int := 1;
      v_synth jsonb := '[]'::jsonb;
    BEGIN
      IF v_n IS NULL OR v_first IS NULL OR v_amount IS NULL THEN
        RAISE EXCEPTION 'PLAN_INVALID: unable to compute cuotas from plan';
      END IF;
      WHILE i <= v_n LOOP
        v_synth := v_synth || jsonb_build_object(
          'numero', i,
          'amount', v_amount,
          'due_date', (v_first + make_interval(months := i-1))::date
        );
        i := i + 1;
      END LOOP;
      v_cuotas := v_synth;
    END;
  END IF;

  v_summary := '[]'::jsonb;

  FOR r_es IN SELECT es.student_id FROM public.enrollment_students es WHERE es.enrollment_id = p_enrollment_id LOOP
    DECLARE
      v_items jsonb := '[]'::jsonb;
      v_guardian_id uuid := v_enrollment.guardian_id;
      v_owner uuid := v_enrollment.guardian_owner;
      v_method text := COALESCE(v_plan->>'payment_method', NULL);
    BEGIN
      FOR r_cuota IN
        SELECT (c->>'numero')::int AS numero,
               (c->>'amount')::numeric AS amount,
               (c->>'due_date')::date AS due_date
          FROM jsonb_array_elements(v_cuotas) AS c
          ORDER BY (c->>'numero')::int
      LOOP
        IF v_dry_run THEN
          v_items := v_items || jsonb_build_object(
            'numero_cuota', r_cuota.numero,
            'due_date', r_cuota.due_date,
            'amount', r_cuota.amount,
            'existed', false
          );
        ELSE
          INSERT INTO public.fee(
            student_id, guardian_id, amount, due_date, status, payment_method,
            owner_id, year_academico, numero_cuota, enrollment_id, meta
          ) VALUES (
            r_es.student_id, v_guardian_id, r_cuota.amount, r_cuota.due_date, 'pending', v_method,
            v_owner, v_year, r_cuota.numero, p_enrollment_id, jsonb_build_object('source','finalize_enrollment')
          )
          ON CONFLICT (student_id, year_academico, numero_cuota) DO NOTHING;

          IF FOUND THEN
            v_created := v_created + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', false);
          ELSE
            v_skipped := v_skipped + 1;
            v_items := v_items || jsonb_build_object('numero_cuota', r_cuota.numero, 'due_date', r_cuota.due_date, 'amount', r_cuota.amount, 'existed', true);
          END IF;
        END IF;
      END LOOP;

      v_summary := v_summary || jsonb_build_object('student_id', r_es.student_id, 'items', v_items);
    END;
  END LOOP;

  IF NOT v_dry_run THEN
    UPDATE public.enrollments SET status = 'completed', updated_at = now()
     WHERE id = p_enrollment_id;

    UPDATE public.students
       SET estado_std = 'MATRICULADO'
     WHERE id IN (
       SELECT es.student_id
         FROM public.enrollment_students es
        WHERE es.enrollment_id = p_enrollment_id
     )
       AND COALESCE(estado_std, '') <> 'MATRICULADO';
  END IF;

  RETURN jsonb_build_object(
    'confirmed', NOT v_dry_run,
    'created_charges', v_created,
    'skipped_duplicates', v_skipped,
    'students_count', v_students,
    'details', v_summary
  );
END;
$$;

COMMENT ON FUNCTION public.finalize_enrollment(uuid, jsonb) IS 'Finalize an enrollment once PRESTACION + PAGARE docs are ready (digital or physical receipts), generating tuition charges safely.';

REVOKE ALL ON FUNCTION public.finalize_enrollment(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.finalize_enrollment(uuid, jsonb) TO authenticated;
