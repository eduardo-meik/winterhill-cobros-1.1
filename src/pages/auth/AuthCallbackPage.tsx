import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';
import Logger from '../../services/logger';
import { LogCode } from '../../types/logging';

export function AuthCallbackPage() {
  const navigate = useNavigate();

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        // Check if there's a session
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (error) {
          Logger.getInstance().log(
            LogCode.AUTH_LOGIN_FAILED, 
            `OAuth callback error: ${error.message}`, 
            undefined, 
            'authCallback', 
            { level: 'ERROR', area: 'AUTH', error }
          );
          toast.error('Error al procesar la autenticación');
          navigate('/login');
          return;
        }

        if (session) {
          Logger.getInstance().log(
            LogCode.AUTH_LOGIN_SUCCESS, 
            'OAuth login successful', 
            session.user.id, 
            'authCallback', 
            { level: 'INFO', area: 'AUTH', provider: 'google' }
          );
          toast.success('Inicio de sesión exitoso');
          navigate('/dashboard');
        } else {
          Logger.getInstance().log(
            LogCode.AUTH_LOGIN_FAILED, 
            'OAuth callback: No session found', 
            undefined, 
            'authCallback', 
            { level: 'WARN', area: 'AUTH' }
          );
          toast.error('No se pudo completar la autenticación');
          navigate('/login');
        }
      } catch (error: any) {
        Logger.getInstance().log(
          LogCode.AUTH_LOGIN_FAILED, 
          `OAuth callback unexpected error: ${error.message}`, 
          undefined, 
          'authCallbackCatch', 
          { level: 'ERROR', area: 'AUTH', error }
        );
        toast.error('Error inesperado durante la autenticación');
        navigate('/login');
      }
    };

    handleAuthCallback();
  }, [navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-dark-bg">
      <div className="max-w-md w-full space-y-8 text-center">
        <div>
          <div className="mx-auto h-12 w-12 text-primary">
            <svg className="animate-spin h-12 w-12" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"/>
            </svg>
          </div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900 dark:text-white">
            Procesando autenticación...
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600 dark:text-gray-400">
            Espera mientras completamos tu inicio de sesión
          </p>
        </div>
      </div>
    </div>
  );
}
