-- Fix security issues reported by Supabase Linter
-- 1. Remove SECURITY DEFINER from views
-- 2. Enable RLS on public tables

-- 1. Fix database_metadata view
DROP VIEW IF EXISTS public.database_metadata CASCADE;

CREATE VIEW public.database_metadata WITH (security_invoker = true) AS
SELECT 
    t.table_schema,
    t.table_name,
    jsonb_agg(
        jsonb_build_object(
            'column_name', c.column_name,
            'data_type', c.data_type,
            'is_nullable', c.is_nullable,
            'column_default', c.column_default,
            'character_maximum_length', c.character_maximum_length
        ) ORDER BY c.ordinal_position
    ) AS metadata
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
GROUP BY t.table_schema, t.table_name
ORDER BY t.table_name;

GRANT SELECT ON public.database_metadata TO authenticated;


-- 2. Fix v_student_academic_history view
DROP VIEW IF EXISTS public.v_student_academic_history CASCADE;

CREATE VIEW public.v_student_academic_history WITH (security_invoker = true) AS
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

COMMENT ON VIEW public.v_student_academic_history IS 
'Complete academic history: shows all courses a student has been enrolled in across years.';

GRANT SELECT ON public.v_student_academic_history TO authenticated;


-- 3. Fix v_current_student_courses view
DROP VIEW IF EXISTS public.v_current_student_courses CASCADE;

CREATE VIEW public.v_current_student_courses WITH (security_invoker = true) AS
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

COMMENT ON VIEW public.v_current_student_courses IS 
'Helper view: Shows all active students with their current year course assignment. Uses case-insensitive comparison for estado_std.';

GRANT SELECT ON public.v_current_student_courses TO authenticated;


-- 4. Enable RLS on guardian_claim_logs
ALTER TABLE public.guardian_claim_logs ENABLE ROW LEVEL SECURITY;

-- 5. Enable RLS on rate_limit_counters
ALTER TABLE public.rate_limit_counters ENABLE ROW LEVEL SECURITY;
