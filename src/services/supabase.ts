import { createClient } from '@supabase/supabase-js';
import toast from 'react-hot-toast';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

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
      detectSessionInUrl: true,
      flowType: 'pkce'
    }
  }
);

// Add Google Auth helper functions
export const signInWithGoogle = async () => {
  try {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
        queryParams: {
          access_type: 'offline',
          prompt: 'consent',
        },
      }
    });

    if (error) {
      console.error('Google Auth error:', error);
      toast.error(`Error al iniciar sesión con Google: ${error.message}`);
      throw error;
    }

    return data;
  } catch (error) {
    console.error('An unexpected error occurred during Google sign-in:', error);
    toast.error('Ocurrió un error inesperado. Por favor, intenta nuevamente.');
    throw error;
  }
};

// Add error handler function
export const handleSupabaseError = (error: any) => {
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