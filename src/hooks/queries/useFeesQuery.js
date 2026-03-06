import { useQuery } from '@tanstack/react-query';
import { supabase } from '../../services/supabase';

/**
 * Shared React Query hook for fees by academic year.
 * Uses a single "wide" select that covers all dashboard components,
 * so React Query can deduplicate 6+ parallel requests into 1.
 *
 * @param {number} academicYear
 * @param {object} [options] - extra useQuery options (enabled, select, etc.)
 */
export function useFeesQuery(academicYear, options = {}) {
  return useQuery({
    queryKey: ['fees', academicYear],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('fee')
        .select(`
          *,
          student:students (
            id,
            first_name,
            last_name,
            apellido_paterno,
            whole_name,
            run,
            curso,
            cursos:curso (
              id,
              nom_curso
            )
          )
        `)
        .eq('year_academico', academicYear);

      if (error) throw error;
      return data ?? [];
    },
    ...options,
  });
}
