import { useQuery } from '@tanstack/react-query';
import { supabase } from '../../services/supabase';

/**
 * Shared React Query hook for students.
 * "Wide" select covers all consumers (StudentSelect, StudentsPage,
 * GuardianDetailsModal, PromotionTool, etc.).
 *
 * @param {object} [options] - extra useQuery options (enabled, select, etc.)
 */
export function useStudentsQuery(options = {}) {
  return useQuery({
    queryKey: ['students'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('students')
        .select(`
          id, first_name, apellido_paterno, apellido_materno,
          whole_name, run, estado_std, curso,
          cursos:curso (
            id, nom_curso, nivel, year_academico
          )
        `)
        .order('apellido_paterno', { ascending: true });

      if (error) throw error;
      return data ?? [];
    },
    ...options,
  });
}
