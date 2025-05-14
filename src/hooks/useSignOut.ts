import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { LogCode } from '../types/logging';
import Logger from '../services/logger';

const logger = Logger.getInstance();

export function useSignOut() {
  const { signOut, user } = useAuth();
  const navigate = useNavigate();

  const handleSignOut = async () => {
    try {
      // Log the sign-out attempt
      await logger.log(
        LogCode.AUTH_LOGOUT,
        'Iniciando proceso de cierre de sesión',
        user?.id
      );

      // Perform sign-out
      await signOut();

      // Clear any local storage items (except theme preference)
      Object.keys(localStorage).forEach(key => {
        if (key !== 'theme') {
          localStorage.removeItem(key);
        }
      });

      // Clear session storage
      sessionStorage.clear();

      // Redirect to login page
      navigate('/login', { replace: true });

    } catch (error) {
      // Log the error but don't expose it to the user
      await logger.log(
        LogCode.AUTH_LOGOUT_FAILED,
        'Error durante el cierre de sesión',
        user?.id,
        error.message
      );
      throw error;
    }
  };

  return handleSignOut;
}