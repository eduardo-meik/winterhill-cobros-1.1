import { createClient } from '@supabase/supabase-js';
import toast from 'react-hot-toast';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string;
const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID as string;
const siteUrl = import.meta.env.VITE_SITE_URL as string;

// Debug environment variables in development
if (import.meta.env.DEV) {
  console.log('🔧 Environment Variables Check:');
  console.log('VITE_SUPABASE_URL:', supabaseUrl ? '✅ Set' : '❌ Missing');
  console.log('VITE_SUPABASE_ANON_KEY:', supabaseAnonKey ? '✅ Set' : '❌ Missing');
  console.log('VITE_GOOGLE_CLIENT_ID:', googleClientId ? '✅ Set' : '❌ Missing');
  console.log('VITE_SITE_URL:', siteUrl ? `✅ ${siteUrl}` : '❌ Missing');
  console.log('Window Origin:', window.location.origin);
}

if (!supabaseUrl || !supabaseAnonKey) {
  const errorMsg = 'Error de configuración: Variables de entorno de Supabase no encontradas';
  console.error('Missing Supabase environment variables:', {
    VITE_SUPABASE_URL: !!supabaseUrl,
    VITE_SUPABASE_ANON_KEY: !!supabaseAnonKey,
    VITE_GOOGLE_CLIENT_ID: !!googleClientId,
    VITE_SITE_URL: !!siteUrl
  });
  toast.error(errorMsg);
}

if (!googleClientId) {
  console.warn('⚠️ Google Client ID not found - Google OAuth will not work');
}

export const supabase = createClient(
  supabaseUrl || '',
  supabaseAnonKey || '',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      flowType: 'pkce',
      storage: window.localStorage,
      storageKey: 'supabase.auth.token'
    }
  }
);

// Add Google Auth helper functions
export const signInWithGoogle = async () => {
  if (!googleClientId) {
    const errorMsg = 'Google OAuth no está configurado. Verifique las variables de entorno.';
    console.error('Google OAuth configuration missing');
    toast.error(errorMsg);
    throw new Error(errorMsg);
  }

  try {
    // Use the configured site URL or fallback to window.location.origin
    const redirectUrl = siteUrl || window.location.origin;
    const callbackUrl = `${redirectUrl}/auth/callback`;
    
    console.log('🔄 Initiating Google OAuth with:', {
      provider: 'google',
      redirectTo: callbackUrl,
      clientId: googleClientId ? 'Present' : 'Missing'
    });

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: callbackUrl,
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

    console.log('✅ Google OAuth initiated successfully');
    return data;
  } catch (error) {
    console.error('An unexpected error occurred during Google sign-in:', error);
    toast.error('Ocurrió un error inesperado. Por favor, intenta nuevamente.');
    throw error;
  }
};

// Clear invalid sessions
export const clearInvalidSession = async () => {
  try {
    await supabase.auth.signOut();
    // Clear local storage
    localStorage.removeItem('supabase.auth.token');
    window.location.reload();
  } catch (error) {
    console.error('Error clearing session:', error);
  }
};

// Add error handler function
export const handleSupabaseError = (error: any) => {
  if (error.message === 'Failed to fetch') {
    toast.error('Error de conexión: Verifica tu conexión a internet');
    return;
  }
  
  if (error.message?.includes('JWT') || error.message?.includes('Invalid Refresh Token')) {
    toast.error('Sesión expirada. Reiniciando...');
    clearInvalidSession();
    return;
  }

  console.error('Supabase error:', error);
  toast.error('Error del servidor. Por favor, intenta nuevamente');
};