import { useQuery } from '@tanstack/react-query';
import { supabase } from '../../services/supabase';

export function useAttendanceConciliacionQuery(fecha) {
  return useQuery({
    queryKey: ['attendance-conciliacion', fecha],
    queryFn: async () => {
      const query = supabase
        .from('asistencia_conciliacion')
        .select('id, owner_id, rut_docente, fecha, estado, minutos_planificados, minutos_efectivos, minutos_atraso, minutos_salida_anticipada')
        .order('fecha', { ascending: false })
        .order('rut_docente', { ascending: true });

      const { data, error } = fecha ? query.eq('fecha', fecha) : query;

      if (error) {
        throw error;
      }

      return data ?? [];
    },
  });
}
