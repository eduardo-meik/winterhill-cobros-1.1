import { useQuery } from '@tanstack/react-query';
import { supabase } from '../../services/supabase';

/**
 * Hook específico para la pantalla de Aranceles.
 * Carga la tabla fee completa en lotes para evitar truncamiento por límite de filas.
 */
export function usePaymentsFeesQuery(options = {}) {
  return useQuery({
    queryKey: ['payments-fees'],
    queryFn: async () => {
      const pageSize = 1000;
      const allFees = [];
      let start = 0;

      while (true) {
        const { data, error } = await supabase
          .from('fee')
          .select(`
            *,
            student:students (
              id,
              first_name,
              apellido_paterno,
              apellido_materno,
              whole_name,
              run,
              curso:cursos (
                id,
                nom_curso
              )
            )
          `)
          .order('created_at', { ascending: true })
          .range(start, start + pageSize - 1);

        if (error) {
          throw error;
        }

        const batch = data ?? [];
        allFees.push(...batch);

        if (batch.length < pageSize) {
          break;
        }

        start += pageSize;
      }

      return allFees;
    },
    ...options,
  });
}