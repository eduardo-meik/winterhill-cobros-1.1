-- Database Performance Optimization for Winterhill Cobros
-- Apply these optimizations to improve query performance

-- CRITICAL: These indexes address the specific slow queries identified
-- The following queries were taking 8-10 seconds due to complex LATERAL JOINs:
-- 1. Fee queries with student and curso data (5,200ms+)
-- 2. Complex nested relationships with multiple joins
-- 3. Large result sets without proper indexing

-- 1. Primary indexes for the most expensive query patterns
-- These directly address the slow LATERAL JOIN queries

-- Critical index for main fee query ordering and status filtering
CREATE INDEX IF NOT EXISTS idx_fee_created_at_desc ON public.fee (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fee_created_at_status ON public.fee (created_at DESC, status);

-- Essential for student-fee joins (eliminates LATERAL JOIN performance issues)
CREATE INDEX IF NOT EXISTS idx_fee_student_id ON public.fee (student_id);
CREATE INDEX IF NOT EXISTS idx_fee_student_id_status ON public.fee (student_id, status);

-- Date-based queries optimization
CREATE INDEX IF NOT EXISTS idx_fee_due_date_status ON public.fee (due_date ASC, status);
CREATE INDEX IF NOT EXISTS idx_fee_due_date_desc ON public.fee (due_date DESC);

-- Filter-specific indexes
CREATE INDEX IF NOT EXISTS idx_fee_status ON public.fee (status);
CREATE INDEX IF NOT EXISTS idx_fee_numero_cuota ON public.fee (numero_cuota);
CREATE INDEX IF NOT EXISTS idx_fee_payment_method ON public.fee (payment_method);

-- Student table optimization for joins
CREATE INDEX IF NOT EXISTS idx_students_curso ON public.students (curso);
CREATE INDEX IF NOT EXISTS idx_students_apellido_paterno ON public.students (apellido_paterno);
CREATE INDEX IF NOT EXISTS idx_students_run ON public.students (run);

-- Curso table optimization
CREATE INDEX IF NOT EXISTS idx_cursos_nom_curso ON public.cursos (nom_curso);

-- 2. Composite indexes for complex query patterns
-- These target the specific query patterns causing slowdowns
CREATE INDEX IF NOT EXISTS idx_fee_student_due_date ON public.fee (student_id, due_date DESC);
CREATE INDEX IF NOT EXISTS idx_fee_status_created_at ON public.fee (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fee_status_due_date_created ON public.fee (status, due_date, created_at DESC);

-- 3. Advanced optimization: Materialized view for pre-joined data
-- This eliminates the need for complex runtime joins
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_payments_with_student AS
SELECT 
    f.id,
    f.student_id,
    f.amount,
    f.status,
    f.due_date,
    f.payment_date,
    f.payment_method,
    f.numero_cuota,
    f.num_boleta,
    f.mov_bancario,
    f.notes,
    f.created_at,
    s.first_name,
    s.apellido_paterno,
    s.whole_name,
    s.run,
    s.curso,
    c.nom_curso,
    c.id as curso_id
FROM public.fee f
INNER JOIN public.students s ON f.student_id = s.id
INNER JOIN public.cursos c ON s.curso = c.id;

-- Indexes for the materialized view
CREATE INDEX IF NOT EXISTS idx_mv_payments_created_at ON mv_payments_with_student (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mv_payments_status ON mv_payments_with_student (status);
CREATE INDEX IF NOT EXISTS idx_mv_payments_student_id ON mv_payments_with_student (student_id);
CREATE INDEX IF NOT EXISTS idx_mv_payments_nom_curso ON mv_payments_with_student (nom_curso);
CREATE INDEX IF NOT EXISTS idx_mv_payments_numero_cuota ON mv_payments_with_student (numero_cuota);

-- Full-text search optimization
CREATE INDEX IF NOT EXISTS idx_mv_payments_search ON mv_payments_with_student 
  USING gin(to_tsvector('spanish', 
    coalesce(whole_name, '') || ' ' || 
    coalesce(run, '') || ' ' || 
    coalesce(numero_cuota::text, '')
  ));

-- 4. Function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_payments_view()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_payments_with_student;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Optimized query functions to replace slow LATERAL JOINs
-- Function for paginated payments (replaces slow frontend queries)
CREATE OR REPLACE FUNCTION get_payments_optimized(
    limit_val INTEGER DEFAULT 500,
    offset_val INTEGER DEFAULT 0,
    status_filter TEXT DEFAULT NULL,
    curso_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    id INTEGER,
    student_id INTEGER,
    amount DECIMAL,
    status TEXT,
    due_date DATE,
    payment_date DATE,
    payment_method TEXT,
    numero_cuota INTEGER,
    num_boleta TEXT,
    mov_bancario TEXT,
    notes TEXT,
    created_at TIMESTAMP,
    first_name TEXT,
    apellido_paterno TEXT,
    whole_name TEXT,
    run TEXT,
    nom_curso TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mv.id, mv.student_id, mv.amount, mv.status, mv.due_date,
        mv.payment_date, mv.payment_method, mv.numero_cuota,
        mv.num_boleta, mv.mov_bancario, mv.notes, mv.created_at,
        mv.first_name, mv.apellido_paterno, mv.whole_name, mv.run, mv.nom_curso
    FROM mv_payments_with_student mv
    WHERE 
        (status_filter IS NULL OR mv.status = status_filter)
        AND (curso_filter IS NULL OR mv.nom_curso = curso_filter)
    ORDER BY mv.created_at DESC
    LIMIT limit_val OFFSET offset_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Statistics update for query planner optimization
ANALYZE public.fee;
ANALYZE public.students;
ANALYZE public.cursos;

-- 7. Dashboard summary view (replaces complex aggregation queries)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_fee_summary AS
SELECT 
    f.status,
    COUNT(*) as count,
    SUM(f.amount) as total_amount,
    DATE_TRUNC('month', f.due_date) as month_year
FROM public.fee f
GROUP BY f.status, DATE_TRUNC('month', f.due_date);

-- Create index on the materialized view
CREATE INDEX IF NOT EXISTS idx_mv_fee_summary_status_month ON mv_fee_summary (status, month_year);

-- 8. Function to refresh the materialized view (call this periodically)
CREATE OR REPLACE FUNCTION refresh_fee_summary()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_fee_summary;
END;
$$ LANGUAGE plpgsql;

-- 9. Analyze tables to update statistics
ANALYZE public.fee;
ANALYZE public.students;
ANALYZE public.cursos;

-- 10. Vacuum tables to reclaim space and update visibility maps
VACUUM ANALYZE public.fee;
VACUUM ANALYZE public.students;
VACUUM ANALYZE public.cursos;

-- 11. Optional: Create a function to get paginated fees with better performance
CREATE OR REPLACE FUNCTION get_paginated_fees(
    p_limit INTEGER DEFAULT 500,
    p_offset INTEGER DEFAULT 0,
    p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    student_id UUID,
    amount NUMERIC,
    status TEXT,
    due_date DATE,
    payment_date DATE,
    payment_method TEXT,
    numero_cuota TEXT,
    num_boleta TEXT,
    mov_bancario TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ,
    student_name TEXT,
    student_run TEXT,
    curso_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.student_id,
        f.amount,
        f.status,
        f.due_date,
        f.payment_date,
        f.payment_method,
        f.numero_cuota,
        f.num_boleta,
        f.mov_bancario,
        f.notes,
        f.created_at,
        COALESCE(s.whole_name, CONCAT(s.first_name, ' ', s.apellido_paterno)) as student_name,
        s.run as student_run,
        c.nom_curso as curso_name
    FROM public.fee f
    JOIN public.students s ON f.student_id = s.id
    LEFT JOIN public.cursos c ON s.curso = c.id
    WHERE (p_status IS NULL OR f.status = p_status)
    ORDER BY f.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- 12. Set up automatic statistics collection
-- This helps PostgreSQL make better query plans
ALTER TABLE public.fee SET (autovacuum_analyze_scale_factor = 0.05);
ALTER TABLE public.students SET (autovacuum_analyze_scale_factor = 0.05);
ALTER TABLE public.cursos SET (autovacuum_analyze_scale_factor = 0.05);

-- 13. Create a scheduled job to refresh the materialized view (if using pg_cron extension)
-- SELECT cron.schedule('refresh-fee-summary', '0 */6 * * *', 'SELECT refresh_fee_summary();');

-- 14. Add constraints to help with query optimization
-- Ensure foreign key constraints exist for better join performance
ALTER TABLE public.fee 
ADD CONSTRAINT IF NOT EXISTS fk_fee_student 
FOREIGN KEY (student_id) REFERENCES public.students(id);

ALTER TABLE public.students 
ADD CONSTRAINT IF NOT EXISTS fk_students_curso 
FOREIGN KEY (curso) REFERENCES public.cursos(id);

-- Performance monitoring queries
-- Use these to monitor the impact of optimizations

-- Check index usage
/*
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
*/

-- Check table statistics
/*
SELECT 
    schemaname,
    tablename,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_live_tup,
    n_dead_tup,
    last_analyze
FROM pg_stat_user_tables 
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;
*/

-- Check slow queries (requires pg_stat_statements extension)
/*
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
WHERE query LIKE '%fee%' 
ORDER BY total_time DESC 
LIMIT 10;
*/
