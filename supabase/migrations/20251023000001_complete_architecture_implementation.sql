-- ============================================================================
-- WINTERHILL SCHOOL MANAGEMENT: ARCHITECTURE IMPLEMENTATION
-- ============================================================================
-- Date: October 23, 2025
-- Purpose: Add academic records tracking and fix fee year column
-- Status: PRODUCTION READY - Execute manually in Supabase SQL Editor
-- 
-- INSTRUCTIONS:
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Copy-paste this ENTIRE file
-- 3. Click "RUN" (executes as transaction, rolls back on error)
-- 4. Verify success message at bottom
-- 5. Test queries provided at end
-- ============================================================================

BEGIN;

-- ============================================================================
-- PHASE 1: EXTEND FEE TABLE WITH YEAR_ACADEMICO
-- ============================================================================
-- Purpose: Allow direct year queries on fees without date extraction
-- Fixes: 400 Bad Request error on GuardianWelcomePage

DO $$
BEGIN
  -- Add column if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'fee' 
    AND column_name = 'year_academico'
  ) THEN
    ALTER TABLE public.fee ADD COLUMN year_academico integer;
    RAISE NOTICE 'Column year_academico added to fee table';
  ELSE
    RAISE NOTICE 'Column year_academico already exists in fee table';
  END IF;
END $$;

-- Populate year_academico from existing data
-- Strategy 1: Try to extract from fee_curso → cursos.year_academico
UPDATE public.fee f
SET year_academico = c.year_academico
FROM public.cursos c
WHERE f.fee_curso = c.id
  AND f.year_academico IS NULL;

-- Strategy 2: For fees without fee_curso, use due_date year
UPDATE public.fee
SET year_academico = EXTRACT(YEAR FROM due_date)
WHERE year_academico IS NULL
  AND due_date IS NOT NULL;

-- Strategy 3: For remaining nulls, use current year (safeguard)
UPDATE public.fee
SET year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE year_academico IS NULL;

-- Make NOT NULL after population
ALTER TABLE public.fee 
ALTER COLUMN year_academico SET NOT NULL;

-- Add check constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fee_year_valid'
  ) THEN
    ALTER TABLE public.fee 
    ADD CONSTRAINT fee_year_valid CHECK (year_academico >= 2020 AND year_academico <= 2100);
    RAISE NOTICE 'Constraint fee_year_valid added';
  END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_fee_year_academico 
ON public.fee(year_academico);

CREATE INDEX IF NOT EXISTS idx_fee_student_year 
ON public.fee(student_id, year_academico);

COMMENT ON COLUMN public.fee.year_academico IS 
'Academic year for the fee. Allows efficient filtering without date extraction. Populated from curso.year_academico or extracted from due_date.';

-- ============================================================================
-- PHASE 2: CREATE STUDENT_ACADEMIC_RECORDS TABLE
-- ============================================================================
-- Purpose: Track which course each student was enrolled in each year
-- Preserves academic history without overwriting students.curso

CREATE TABLE IF NOT EXISTS public.student_academic_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Core relationship
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  curso_id uuid NOT NULL REFERENCES public.cursos(id) ON DELETE RESTRICT,
  year_academico integer NOT NULL CHECK (year_academico BETWEEN 2020 AND 2100),
  
  -- Academic period tracking
  fecha_inicio date, -- Will be set by trigger or application code
  fecha_termino date, -- Will be set by trigger or application code
  estado text NOT NULL CHECK (estado IN ('activo','completado','retirado','repitio','trasladado')) DEFAULT 'activo',
  
  -- Academic performance (optional, populated at year end)
  promedio_anual numeric(3,2) CHECK (promedio_anual IS NULL OR promedio_anual BETWEEN 1.0 AND 7.0),
  asistencia_porcentaje numeric(5,2) CHECK (asistencia_porcentaje IS NULL OR asistencia_porcentaje BETWEEN 0 AND 100),
  observaciones text,
  
  -- Link to administrative enrollment process (optional)
  enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL,
  
  -- Audit fields
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  updated_by uuid REFERENCES auth.users(id),
  
  -- Business rules
  UNIQUE(student_id, year_academico) -- One course per student per year
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sar_student 
ON public.student_academic_records(student_id);

CREATE INDEX IF NOT EXISTS idx_sar_year 
ON public.student_academic_records(year_academico);

CREATE INDEX IF NOT EXISTS idx_sar_curso 
ON public.student_academic_records(curso_id);

CREATE INDEX IF NOT EXISTS idx_sar_student_year 
ON public.student_academic_records(student_id, year_academico);

CREATE INDEX IF NOT EXISTS idx_sar_estado 
ON public.student_academic_records(estado) 
WHERE estado = 'activo'; -- Partial index for active students only

-- Comments for documentation
COMMENT ON TABLE public.student_academic_records IS 
'Academic history: tracks which course each student was enrolled in each year. Preserves historical data when student advances to next grade.';

COMMENT ON COLUMN public.student_academic_records.estado IS 
'Academic status: activo (current), completado (finished year), retirado (withdrawn), repitio (repeated year), trasladado (transferred)';

COMMENT ON COLUMN public.student_academic_records.enrollment_id IS 
'Optional link to administrative enrollment process (enrollments table). Links academic record with document signing, fee generation, etc.';

-- ============================================================================
-- PHASE 3: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.student_academic_records ENABLE ROW LEVEL SECURITY;

-- Policy 1: Guardians can read academic records of their students
DROP POLICY IF EXISTS sar_guardian_read ON public.student_academic_records;
CREATE POLICY sar_guardian_read ON public.student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.student_guardian sg
      JOIN public.guardians g ON g.id = sg.guardian_id
      WHERE sg.student_id = student_academic_records.student_id
        AND g.owner_id = auth.uid()
    )
  );

-- Policy 2: Students can read their own academic records (if student portal exists)
DROP POLICY IF EXISTS sar_student_read ON public.student_academic_records;
CREATE POLICY sar_student_read ON public.student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.students s
      WHERE s.id = student_academic_records.student_id
        AND s.owner_id = auth.uid()
    )
  );

-- Policy 3: Admins and teachers can read all records
DROP POLICY IF EXISTS sar_staff_read ON public.student_academic_records;
CREATE POLICY sar_staff_read ON public.student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.role IN ('admin', 'teacher', 'director', 'secretary')
    )
  );

-- Policy 4: Only admins and teachers can insert/update/delete
DROP POLICY IF EXISTS sar_staff_write ON public.student_academic_records;
CREATE POLICY sar_staff_write ON public.student_academic_records
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.role IN ('admin', 'teacher', 'director')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM public.user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.role IN ('admin', 'teacher', 'director')
    )
  );

-- ============================================================================
-- PHASE 4: TRIGGERS FOR AUTO-MAINTENANCE
-- ============================================================================

-- Trigger 1: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_student_academic_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_sar_updated_at ON public.student_academic_records;
CREATE TRIGGER trigger_sar_updated_at
  BEFORE UPDATE ON public.student_academic_records
  FOR EACH ROW
  EXECUTE FUNCTION update_student_academic_records_updated_at();

-- Trigger 1.5: Auto-set academic year dates
CREATE OR REPLACE FUNCTION set_academic_year_dates()
RETURNS TRIGGER AS $$
BEGIN
  -- Set fecha_inicio if NULL (March 1st of academic year)
  IF NEW.fecha_inicio IS NULL THEN
    NEW.fecha_inicio = make_date(NEW.year_academico, 3, 1);
  END IF;
  
  -- Set fecha_termino if NULL (December 31st of academic year)
  IF NEW.fecha_termino IS NULL THEN
    NEW.fecha_termino = make_date(NEW.year_academico, 12, 31);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_academic_dates ON public.student_academic_records;
CREATE TRIGGER trigger_set_academic_dates
  BEFORE INSERT OR UPDATE ON public.student_academic_records
  FOR EACH ROW
  EXECUTE FUNCTION set_academic_year_dates();

-- Trigger 2: Auto-sync students.curso with current year active record
-- This keeps students.curso as a "current curso" helper field
CREATE OR REPLACE FUNCTION sync_student_current_curso()
RETURNS TRIGGER AS $$
DECLARE
  current_year integer := EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
  -- Only sync if this is current year and active
  IF NEW.year_academico = current_year AND NEW.estado = 'activo' THEN
    UPDATE public.students 
    SET curso = NEW.curso_id,
        updated_at = now()
    WHERE id = NEW.student_id;
    
    RAISE NOTICE 'Synced students.curso for student_id % to curso_id %', NEW.student_id, NEW.curso_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_sync_student_curso ON public.student_academic_records;
CREATE TRIGGER trigger_sync_student_curso
  AFTER INSERT OR UPDATE ON public.student_academic_records
  FOR EACH ROW
  EXECUTE FUNCTION sync_student_current_curso();

-- ============================================================================
-- PHASE 5: EXTEND ENROLLMENT_STUDENTS (OPTIONAL LINK)
-- ============================================================================
-- Adds optional reference from enrollment_students to academic_records
-- This links administrative enrollment process ↔ academic history

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'enrollment_students' 
    AND column_name = 'academic_record_id'
  ) THEN
    ALTER TABLE public.enrollment_students 
    ADD COLUMN academic_record_id uuid REFERENCES public.student_academic_records(id) ON DELETE SET NULL;
    
    RAISE NOTICE 'Column academic_record_id added to enrollment_students';
  ELSE
    RAISE NOTICE 'Column academic_record_id already exists in enrollment_students';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_enrollment_students_academic 
ON public.enrollment_students(academic_record_id);

COMMENT ON COLUMN public.enrollment_students.academic_record_id IS 
'Optional link to student_academic_records. Connects administrative enrollment process with academic course assignment.';

-- ============================================================================
-- PHASE 6: DATA MIGRATION - POPULATE CURRENT YEAR RECORDS
-- ============================================================================
-- Migrates existing students.curso → student_academic_records for current year
-- Only runs if student doesn't already have a record for current year

DO $$
DECLARE
  current_year integer := EXTRACT(YEAR FROM CURRENT_DATE);
  migrated_count integer := 0;
BEGIN
  -- Insert records for students who don't have one for current year
  INSERT INTO public.student_academic_records (
    student_id, 
    curso_id, 
    year_academico, 
    estado,
    fecha_inicio,
    created_by
  )
  SELECT 
    s.id,
    s.curso,
    current_year,
    CASE 
      WHEN UPPER(s.estado_std) = 'ACTIVO' THEN 'activo'
      WHEN s.fecha_retiro IS NOT NULL THEN 'retirado'
      ELSE 'activo' -- Default to active if unclear
    END,
    COALESCE(s.fecha_matricula, make_date(current_year, 3, 1)),
    NULL -- created_by will be NULL for migration
  FROM public.students s
  WHERE s.curso IS NOT NULL
    AND NOT EXISTS (
      -- Don't insert if already has record for current year
      SELECT 1 FROM public.student_academic_records sar
      WHERE sar.student_id = s.id 
        AND sar.year_academico = current_year
    );
  
  GET DIAGNOSTICS migrated_count = ROW_COUNT;
  RAISE NOTICE 'Migrated % student records to student_academic_records for year %', migrated_count, current_year;
END $$;

-- ============================================================================
-- PHASE 7: HELPER VIEWS (OPTIONAL)
-- ============================================================================

-- View 1: Current Active Students with Course
CREATE OR REPLACE VIEW v_current_student_courses AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  s.first_name,
  s.apellido_paterno,
  s.apellido_materno,
  sar.curso_id,
  c.nom_curso,
  c.nivel,
  c.letra_curso,
  c.year_academico,
  sar.estado as enrollment_status,
  sar.promedio_anual,
  sar.asistencia_porcentaje
FROM public.students s
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN public.cursos c ON c.id = sar.curso_id
WHERE UPPER(s.estado_std) = 'ACTIVO' OR s.estado_std IS NULL;

COMMENT ON VIEW v_current_student_courses IS 
'Helper view: Shows all active students with their current year course assignment.';

-- View 2: Student Academic History
CREATE OR REPLACE VIEW v_student_academic_history AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  sar.year_academico,
  c.nom_curso,
  c.nivel,
  sar.estado,
  sar.promedio_anual,
  sar.asistencia_porcentaje,
  sar.observaciones,
  sar.fecha_inicio,
  sar.fecha_termino
FROM public.students s
JOIN public.student_academic_records sar ON sar.student_id = s.id
JOIN public.cursos c ON c.id = sar.curso_id
ORDER BY s.id, sar.year_academico DESC;

COMMENT ON VIEW v_student_academic_history IS 
'Complete academic history: shows all courses a student has been enrolled in across years.';

-- ============================================================================
-- PHASE 8: UTILITY FUNCTIONS
-- ============================================================================

-- Function: Get current academic year (handles Jan-Feb as previous year)
CREATE OR REPLACE FUNCTION current_academic_year()
RETURNS integer AS $$
BEGIN
  -- In Chile, school year starts in March
  -- So January-February still belong to previous academic year
  IF EXTRACT(MONTH FROM CURRENT_DATE) <= 2 THEN
    RETURN EXTRACT(YEAR FROM CURRENT_DATE)::integer - 1;
  ELSE
    RETURN EXTRACT(YEAR FROM CURRENT_DATE)::integer;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION current_academic_year() IS 
'Returns current academic year. Considers Jan-Feb as previous year since school starts in March.';

-- Function: Get student's course for specific year
CREATE OR REPLACE FUNCTION get_student_course(p_student_id uuid, p_year integer)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'student_id', sar.student_id,
    'year', sar.year_academico,
    'curso_id', sar.curso_id,
    'curso_nombre', c.nom_curso,
    'nivel', c.nivel,
    'estado', sar.estado,
    'promedio', sar.promedio_anual,
    'asistencia', sar.asistencia_porcentaje
  ) INTO result
  FROM public.student_academic_records sar
  JOIN public.cursos c ON c.id = sar.curso_id
  WHERE sar.student_id = p_student_id
    AND sar.year_academico = p_year;
  
  RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION get_student_course(uuid, integer) IS 
'Returns course information for a student in a specific year as JSON.';

-- ============================================================================
-- COMMIT TRANSACTION
-- ============================================================================

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES (Run separately to verify success)
-- ============================================================================

-- Check 1: Verify fee.year_academico exists and is populated
SELECT 
  COUNT(*) as total_fees,
  COUNT(year_academico) as with_year,
  MIN(year_academico) as oldest_year,
  MAX(year_academico) as newest_year
FROM public.fee;

-- Check 2: Verify student_academic_records table exists
SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT student_id) as unique_students,
  MIN(year_academico) as oldest_year,
  MAX(year_academico) as newest_year
FROM public.student_academic_records;

-- Check 3: Verify current year students have records
SELECT 
  s.id,
  s.whole_name,
  c.nom_curso as curso_actual,
  sar.year_academico,
  sar.estado
FROM public.students s
LEFT JOIN public.cursos c ON c.id = s.curso
LEFT JOIN public.student_academic_records sar 
  ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE s.estado_std = 'activo'
LIMIT 10;

-- Check 4: Verify RLS policies exist
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename IN ('student_academic_records', 'fee')
ORDER BY tablename, policyname;

-- Check 5: Test current_academic_year function
SELECT current_academic_year() as current_year;

-- ============================================================================
-- ROLLBACK SCRIPT (In case of emergency - run separately)
-- ============================================================================
/*
BEGIN;

-- Drop views
DROP VIEW IF EXISTS v_student_academic_history CASCADE;
DROP VIEW IF EXISTS v_current_student_courses CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS get_student_course(uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS current_academic_year() CASCADE;
DROP FUNCTION IF EXISTS sync_student_current_curso() CASCADE;
DROP FUNCTION IF EXISTS set_academic_year_dates() CASCADE;
DROP FUNCTION IF EXISTS update_student_academic_records_updated_at() CASCADE;

-- Drop table
DROP TABLE IF EXISTS public.student_academic_records CASCADE;

-- Remove fee.year_academico
ALTER TABLE public.fee DROP COLUMN IF EXISTS year_academico CASCADE;

-- Remove enrollment_students.academic_record_id
ALTER TABLE public.enrollment_students DROP COLUMN IF EXISTS academic_record_id CASCADE;

COMMIT;

SELECT 'Rollback completed successfully' as status;
*/

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '
  ============================================================================
  ✅ ARCHITECTURE IMPLEMENTATION COMPLETED SUCCESSFULLY
  ============================================================================
  
  Changes Applied:
  ✅ fee.year_academico column added and populated
  ✅ student_academic_records table created
  ✅ RLS policies configured
  ✅ Triggers for auto-sync and audit created
  ✅ Helper views and utility functions created
  ✅ Current year data migrated
  
  Next Steps:
  1. Run VERIFICATION QUERIES above to confirm success
  2. Update frontend code to use new year_academico column
  3. Test Guardian dashboard (should show fee totals correctly)
  4. Begin using student_academic_records for 2026 enrollments
  
  Documentation: See FINAL_ARCHITECTURE_RECOMMENDATION.md
  ============================================================================
  ';
END $$;
