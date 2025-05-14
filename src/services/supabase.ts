import { createClient } from '@supabase/supabase-js';
import toast from 'react-hot-toast';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  toast.error('Error de configuración: Variables de entorno de Supabase no encontradas');
  console.error('Missing Supabase environment variables');
}

export const supabase = createClient(
  supabaseUrl || '',
  supabaseAnonKey || '',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true
    }
  }
);

// Add error handler
supabase.handleError = (error) => {
  if (error.message === 'Failed to fetch') {
    toast.error('Error de conexión: Verifica tu conexión a internet');
    return;
  }
  
  if (error.message?.includes('JWT')) {
    toast.error('Sesión expirada. Por favor, inicia sesión nuevamente');
    return;
  }

  console.error('Supabase error:', error);
  toast.error('Error del servidor. Por favor, intenta nuevamente');
};