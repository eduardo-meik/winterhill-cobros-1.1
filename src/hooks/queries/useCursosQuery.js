import { useQuery } from '@tanstack/react-query';
import { supabase } from '../../services/supabase';

/**
 * Shared React Query hook for cursos.
 * "Wide" select covers all consumers (StudentFormModal, ReportingPage,
 * StudentDetailsModal, GuardianDetailsModal, PromotionTool, etc.).
 *
 * @param {object} [options] - extra useQuery options (enabled, select, etc.)
 */
export function useCursosQuery(options = {}) {
  return useQuery({
    queryKey: ['cursos'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('cursos')
        .select('id, nom_curso, nivel, letra_curso, year_academico')
        .order('nom_curso', { ascending: true });

      if (error) {
        console.error('API Error in useCursosQuery:', error);
        throw error;
      }
      return data ?? [];
    },
    
    staleTime: 5 * 60 * 1000, // cursos rarely change — 5 min stale
    ...options,
  });
}
