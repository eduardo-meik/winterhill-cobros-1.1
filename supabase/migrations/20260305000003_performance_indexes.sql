-- ============================================================================
-- Migration: Performance Indexes (QP-03, QP-04, QP-05)
-- Source: pg_stat_statements analysis — March 5, 2026
-- ============================================================================

-- QP-05: Fee queries with triple join (student+cursos) — 44 calls, avg 518ms
CREATE INDEX IF NOT EXISTS idx_fee_year_academico ON public.fee(year_academico);
CREATE INDEX IF NOT EXISTS idx_fee_student_year ON public.fee(student_id, year_academico);

-- QP-03: Enrollment queries with lateral joins — 532 calls, avg 186ms, 20.4% total
CREATE INDEX IF NOT EXISTS idx_enrollments_created_at ON public.enrollments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_enrollment_students_enrollment ON public.enrollment_students(enrollment_id);

-- QP-04: ILIKE search on students — 168 calls, avg 190ms
-- Trigram indexes for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_guardians_name_trgm ON public.guardians USING gin (first_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_guardians_lastname_trgm ON public.guardians USING gin (last_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_students_wholename_trgm ON public.students USING gin (whole_name gin_trgm_ops);
