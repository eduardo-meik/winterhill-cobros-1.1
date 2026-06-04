import { useQuery } from '@tanstack/react-query';
import { supabase } from '../../services/supabase';

export function useSchedulingQuery(fecha) {
  return useQuery({
    queryKey: ['scheduling', fecha],
    queryFn: async () => {
      const query = supabase
        .from('docentes_horarios')
        .select('id, owner_id, rut_docente, bloque_fecha, hora_inicio, hora_fin, asignatura, sala:sala_id(id,codigo,nombre), curso:curso_id(id,nom_curso)')
        .order('bloque_fecha', { ascending: true })
        .order('hora_inicio', { ascending: true });

      const { data, error } = fecha ? query.eq('bloque_fecha', fecha) : query;

      if (error) {
        throw error;
      }

      return data ?? [];
    },
  });
}
