-- Script manual para promover estudiantes PRE_MATRICULADOS a MATRICULADOS
-- Ejecutar en MARZO del año escolar correspondiente
-- Date: 2025-12-19

-- Ejemplo: Promover estudiantes pre-matriculados para año escolar 2026 (marzo 2026)

BEGIN;

-- Step 1: Verificar estudiantes PRE_MATRICULADOS actuales
SELECT 
  s.id,
  s.first_name,
  s.apellido_paterno,
  s.apellido_materno,
  s.run,
  s.estado_std,
  s.created_at,
  c.nom_curso,
  c.year_academico
FROM public.students s
LEFT JOIN public.cursos c ON s.curso = c.id
WHERE s.estado_std = 'PRE_MATRICULADO'
ORDER BY c.nom_curso, s.apellido_paterno, s.apellido_materno;

-- Step 2: Promover a MATRICULADO (ejecutar en MARZO)
-- IMPORTANTE: Descomentar y ajustar el año académico antes de ejecutar

/*
UPDATE public.students s
SET estado_std = 'MATRICULADO'
FROM public.cursos c
WHERE s.curso = c.id
  AND s.estado_std = 'PRE_MATRICULADO'
  AND c.year_academico = 2026;  -- AJUSTAR AÑO

-- Verificar actualización
SELECT estado_std, COUNT(*) as cantidad
FROM public.students s
JOIN public.cursos c ON s.curso = c.id
WHERE c.year_academico = 2026
GROUP BY estado_std;
*/

ROLLBACK;  -- Cambiar a COMMIT cuando estés listo para aplicar cambios
