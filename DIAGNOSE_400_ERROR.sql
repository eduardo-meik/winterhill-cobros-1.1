-- STEP 1: First, run this query to get your enrollment IDs:
-- SELECT id, year_academico, status, created_at 
-- FROM public.enrollments 
-- ORDER BY created_at DESC 
-- LIMIT 10;

-- STEP 2: Copy one of the IDs and paste it below replacing the placeholder

-- DIAGNOSTIC QUERY FOR 400 ERROR IN finalize_enrollment
DO $$
DECLARE
  v_enrollment_id uuid := 'YOUR_ENROLLMENT_ID'::uuid; -- PASTE YOUR ENROLLMENT ID HERE (example: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')
  v_enrollment record;
  v_student_count int;
  v_guardian_count int;
  v_plan_exists boolean;
BEGIN
  -- Check enrollment exists and status
  SELECT * INTO v_enrollment FROM public.enrollments WHERE id = v_enrollment_id;
  
  IF NOT FOUND THEN
    RAISE NOTICE '❌ ERROR: Enrollment not found: %', v_enrollment_id;
    RETURN;
  END IF;
  
  RAISE NOTICE '✅ Enrollment found: % (status: %)', v_enrollment_id, v_enrollment.status;
  RAISE NOTICE '   Year: %, Created: %', v_enrollment.year_academico, v_enrollment.created_at;
  
  -- Check enrollment_students
  SELECT COUNT(*) INTO v_student_count 
  FROM public.enrollment_students 
  WHERE enrollment_id = v_enrollment_id;
  
  RAISE NOTICE '   Students: %', v_student_count;
  
  IF v_student_count = 0 THEN
    RAISE NOTICE '❌ ERROR: No students in this enrollment';
    RETURN;
  END IF;
  
  -- Check guardians
  SELECT COUNT(DISTINCT sg.guardian_id) INTO v_guardian_count
  FROM public.enrollment_students es
  JOIN public.student_guardians sg ON sg.student_id = es.student_id
  WHERE es.enrollment_id = v_enrollment_id;
  
  RAISE NOTICE '   Guardians linked: %', v_guardian_count;
  
  IF v_guardian_count = 0 THEN
    RAISE NOTICE '⚠️  WARNING: No guardians linked to students';
  END IF;
  
  -- Check payment plan in meta
  v_plan_exists := (v_enrollment.meta ? 'payment_plan');
  RAISE NOTICE '   Payment plan in meta: %', v_plan_exists;
  
  IF NOT v_plan_exists THEN
    RAISE NOTICE '⚠️  WARNING: No payment_plan in enrollment.meta';
    RAISE NOTICE '   Meta content: %', v_enrollment.meta;
  END IF;
  
  -- Check for existing fees that might conflict
  RAISE NOTICE '';
  RAISE NOTICE '--- Checking for existing fees that might cause conflicts ---';
  
  FOR v_enrollment IN
    SELECT 
      s.run,
      s.whole_name,
      g.run as guardian_run,
      g.nombre_completo as guardian_name,
      COUNT(f.id) as fee_count,
      array_agg(f.numero_cuota ORDER BY f.numero_cuota) as cuotas
    FROM public.enrollment_students es
    JOIN public.students s ON s.id = es.student_id
    JOIN public.student_guardians sg ON sg.student_id = s.id
    JOIN public.guardians g ON g.id = sg.guardian_id
    LEFT JOIN public.fee f ON f.student_id = s.id 
      AND f.guardian_id = g.id 
      AND f.year_academico = (SELECT year_academico FROM enrollments WHERE id = v_enrollment_id)
    WHERE es.enrollment_id = v_enrollment_id
    GROUP BY s.id, s.run, s.whole_name, g.id, g.run, g.nombre_completo
  LOOP
    IF v_enrollment.fee_count > 0 THEN
      RAISE NOTICE '⚠️  Student: % (%) has % existing fees with guardian % (%)',
        v_enrollment.whole_name, v_enrollment.run, 
        v_enrollment.fee_count,
        v_enrollment.guardian_name, v_enrollment.guardian_run;
      RAISE NOTICE '    Existing cuotas: %', v_enrollment.cuotas;
    ELSE
      RAISE NOTICE '✅ Student: % (%) - No existing fees', v_enrollment.whole_name, v_enrollment.run;
    END IF;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '--- Summary ---';
  RAISE NOTICE 'If you see existing fees above, the finalize_enrollment function will fail';
  RAISE NOTICE 'with a 409 conflict unless the ON CONFLICT clause is corrected.';
  RAISE NOTICE '';
  RAISE NOTICE 'Next step: Apply the corrected finalize_enrollment function.';
  
END $$;
