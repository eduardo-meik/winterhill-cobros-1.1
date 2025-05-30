import React, { createContext, useContext, useEffect, useState } from 'react';
import { Session as SupabaseSession, User as SupabaseUser } from '@supabase/supabase-js'; // Renamed Session to SupabaseSession
import { supabase } from '../services/supabase';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';
// Assuming named exports for logger utilities. If logger is default, adjust import.
import { logger, LogLevel, LogArea, LogCode } from '../services/logger'; 
import { AuthContextType, AuthState, User as LocalUser } from '../types/auth'; // Renamed User to LocalUser

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const initialAuthState: AuthState = {
  session: null,
  user: null,
  loading: true,
};

// Placeholder: Define what LogCode.AUTH_LOGOUT_SUCCESS etc. should be if they don't exist
// This is just to make the code runnable. Replace with your actual LogCode values.
if (LogCode && !(LogCode as any).AUTH_LOGOUT_SUCCESS) {
  (LogCode as any).AUTH_LOGOUT_SUCCESS = 'AUTH_LOGOUT_SUCCESS'; // Example
}
if (LogCode && !(LogCode as any).AUTH_PASSWORD_RESET_FAILED) {
  (LogCode as any).AUTH_PASSWORD_RESET_FAILED = 'AUTH_PASSWORD_RESET_FAILED'; // Example
}
if (LogCode && !(LogCode as any).AUTH_PASSWORD_RESET_SUCCESS) {
  (LogCode as any).AUTH_PASSWORD_RESET_SUCCESS = 'AUTH_PASSWORD_RESET_SUCCESS'; // Example
}
if (LogCode && !(LogCode as any).AUTH_PASSWORD_UPDATE_FAILED) {
  (LogCode as any).AUTH_PASSWORD_UPDATE_FAILED = 'AUTH_PASSWORD_UPDATE_FAILED'; // Example
}
if (LogCode && !(LogCode as any).AUTH_PASSWORD_UPDATE_SUCCESS) {
  (LogCode as any).AUTH_PASSWORD_UPDATE_SUCCESS = 'AUTH_PASSWORD_UPDATE_SUCCESS'; // Example
}
// Add other missing LogCodes as needed based on previous errors


export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [state, setState] = useState<AuthState>(initialAuthState);
  const navigate = useNavigate();

  // Helper function to map SupabaseUser to your local User type
  // *** YOU MUST ADJUST THIS TO MATCH YOUR src/types/auth.ts User DEFINITION ***
  const mapSupabaseUserToLocalUser = (supabaseUser: SupabaseUser | null | undefined): LocalUser | null => {
    if (!supabaseUser) return null;
    return {
      id: supabaseUser.id,
      email: supabaseUser.email || '', // Ensure email is always a string
      // Example: if your LocalUser has created_at and updated_at
      created_at: supabaseUser.created_at || new Date().toISOString(), 
      updated_at: supabaseUser.updated_at || new Date().toISOString(),
      // Add other fields from your LocalUser type, mapping from supabaseUser as needed
      // e.g., app_metadata: supabaseUser.app_metadata,
      // user_metadata: supabaseUser.user_metadata,
    };
  };

  useEffect(() => {
    const getSession = async () => {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();
        if (error) {
          logger.log(LogLevel.ERROR, LogArea.AUTH, LogCode.AUTH_SESSION_FETCH_FAILED, 'Error fetching session initial:', error);
          throw error;
        }
        setState({ session, user: mapSupabaseUserToLocalUser(session?.user), loading: false });
      } catch (error: any) {
        logger.log(LogLevel.ERROR, LogArea.AUTH, LogCode.AUTH_SESSION_FETCH_FAILED, 'Catch getSession:', error.message);
        setState(prev => ({ ...prev, loading: false }));
      }
    };
    getSession();

    const { data: authListener } = supabase.auth.onAuthStateChange((event, session) => {
      logger.log(LogLevel.INFO, LogArea.AUTH, LogCode.AUTH_STATE_CHANGED, `Auth event: ${event}`, { session });
      setState({ session, user: mapSupabaseUserToLocalUser(session?.user), loading: false });
      
      if (event === 'PASSWORD_RECOVERY') {
        // Using toast.success as toast.info might not be available by default
        toast.success('Puedes establecer tu nueva contraseña ahora.');
        // Optionally navigate if not already on the reset page, e.g.
        // if (window.location.pathname !== '/reset-password') {
        //   navigate('/reset-password');
        // }
      } else if (event === 'SIGNED_OUT') {
        navigate('/login');
      }
    });

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [navigate]);


  const signIn = async (email: string, password: string /*, remember = false */) => {
    setState(prev => ({ ...prev, loading: true }));
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) {
        logger.log(LogLevel.ERROR, LogArea.AUTH, LogCode.AUTH_LOGIN_FAILED, 'Error signing in:', { email, error });
        toast.error(error.message || 'Error al iniciar sesión.');
        throw error;
      }
      if (!data.session || !data.user) {
        logger.log(LogLevel.ERROR, LogArea.AUTH, LogCode.AUTH_LOGIN_FAILED, 'No session or user data after sign in', { email });
        toast.error('Error al iniciar sesión: No se recibió la sesión.');
        throw new Error('No session or user data after sign in');
      }
      logger.log(LogLevel.INFO, LogArea.AUTH, LogCode.AUTH_LOGIN_SUCCESS, 'User signed in successfully', { email });
      toast.success('Inicio de sesión exitoso');
      // State will be updated by onAuthStateChange
    } catch (error: any) {
      setState(prev => ({ ...prev, loading: false }));
      toast.error(error.message || 'Error al iniciar sesión.');
      throw error; 
    }
  };

  const signUp = async (email: string, password: string) => {
    setState(prev => ({ ...prev, loading: true }));
    try {
      const { data, error } = await supabase.auth.signUp({ 
        email, 
        password,
        options: {
          // emailRedirectTo: `${window.location.origin}/confirm-email` // Optional
        }
      });
      if (error) {
        logger.log(LogLevel.ERROR, LogArea.AUTH, LogCode.AUTH_SIGNUP_FAILED, 'Error signing up:', { email, error });
        toast.error(error.message || 'Error al registrar la cuenta.');
        throw error;
      }
      // Check if email confirmation is required
      if (data.user && data.user.identities && data.user.identities.length === 0) {
         logger.log(LogLevel.INFO, LogArea.AUTH, LogCode.AUTH_SIGNUP_SUCCESS, 'Signup successful, confirmation email sent.', { email });
         toast.success('Registro exitoso. Revisa tu correo para confirmar la cuenta.');
         setState(prev => ({ ...prev, loading: false, user: null, session: null }));
         return;
      }
      logger.log(LogLevel.INFO, LogArea.AUTH, LogCode.AUTH_SIGNUP_SUCCESS, 'User signed up and logged in successfully', { email });
      toast.success('Cuenta registrada exitosamente.');
      // State will be updated by onAuthStateChange
    } catch (error: any) {
      setState(prev => ({ ...prev, loading: false }));
      toast.error(error.message || 'Error al registrar la cuenta.');
      throw error;
    }
  };

  const signOut = async () => {
    setState(prev => ({ ...prev, loading: true }));
    try {
      const { error } = await supabase.auth.signOut();
      if (error) {
        // Assuming LogCode.AUTH_LOGOUT_FAILED exists or use a generic one
        const logoutFailedCode = (LogCode as any).AUTH_LOGOUT_FAILED || 'AUTH_LOGOUT_FAILED_GENERIC';
        logger.log(LogLevel.ERROR, LogArea.AUTH, logoutFailedCode, 'Error signing out:', error);
        toast.error(error.message || 'Error al cerrar sesión.');
        throw error;
      }
      logger.log(LogLevel.INFO, LogArea.AUTH, (LogCode as any).AUTH_LOGOUT_SUCCESS || 'AUTH_LOGOUT_SUCCESS_GENERIC', 'User signed out successfully');
      toast.success('Sesión cerrada exitosamente.');
      // State will be updated by onAuthStateChange, which also navigates
    } catch (error: any) {
      setState(prev => ({ ...prev, loading: false }));
      toast.error(error.message || 'Error al cerrar sesión.');
      throw error; 
    }
  };

  const resetPassword = async (email: string) => {
    setState(prev => ({ ...prev, loading: true }));
    try {
      // Use the new function URL provided by the user
      const functionUrl = 'https://yeotpplgerfpxviqazrn.supabase.co/functions/v1/password-recovery';

      const response = await fetch(functionUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // 'apikey': import.meta.env.VITE_SUPABASE_ANON_KEY, // Usually not needed for anon functions
        },
        body: JSON.stringify({ email }),
      });

      const result = await response.json();

      if (!response.ok) {
        const errorMessage = result.error || `Error HTTP ${response.status}: ${response.statusText}` || 'Error al enviar el correo de recuperación.';
        logger.log(LogLevel.ERROR, LogArea.AUTH, (LogCode as any).AUTH_PASSWORD_RESET_FAILED || 'AUTH_PASSWORD_RESET_FAILED_GENERIC', `Error calling password-recovery function: ${errorMessage}`, { email, responseStatus: response.status });
        toast.error(errorMessage);
        throw new Error(errorMessage);
      }
      
      logger.log(LogLevel.INFO, LogArea.AUTH, (LogCode as any).AUTH_PASSWORD_RESET_SUCCESS || 'AUTH_PASSWORD_RESET_SUCCESS_GENERIC', 'Password reset email initiated successfully', { email });
      toast.success(result.message || 'Si el correo existe, recibirás un enlace para restablecer tu contraseña.');

    } catch (error: any) { 
      const errorMessage = error.message || 'Ocurrió un error inesperado al solicitar el restablecimiento de contraseña.';
      logger.log(LogLevel.ERROR, LogArea.AUTH, (LogCode as any).AUTH_PASSWORD_RESET_FAILED || 'AUTH_PASSWORD_RESET_FAILED_GENERIC', `AuthContext resetPassword catch block: ${errorMessage}`, { email });
      if (!errorMessage.toLowerCase().includes('error al enviar el correo')) { // Avoid double toast
         toast.error(errorMessage);
      }
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };
  
  const updatePassword = async (newPassword: string) => {
    setState(prev => ({ ...prev, loading: true }));
    try {
      const { error } = await supabase.auth.updateUser({ password: newPassword });
      if (error) {
        logger.log(LogLevel.ERROR, LogArea.AUTH, (LogCode as any).AUTH_PASSWORD_UPDATE_FAILED || 'AUTH_PASSWORD_UPDATE_FAILED_GENERIC', 'Error updating password:', error);
        toast.error(error.message || 'Error al actualizar la contraseña.');
        throw error;
      }
      logger.log(LogLevel.INFO, LogArea.AUTH, (LogCode as any).AUTH_PASSWORD_UPDATE_SUCCESS || 'AUTH_PASSWORD_UPDATE_SUCCESS_GENERIC', 'Password updated successfully');
      toast.success('Contraseña actualizada exitosamente. Serás redirigido al inicio de sesión.');
      navigate('/login'); 
    } catch (error: any) {
      const errorMessage = error.message || 'Error al actualizar la contraseña.';
      logger.log(LogLevel.ERROR, LogArea.AUTH, (LogCode as any).AUTH_PASSWORD_UPDATE_FAILED || 'AUTH_PASSWORD_UPDATE_FAILED_GENERIC', `AuthContext updatePassword catch block: ${errorMessage}`);
      toast.error(errorMessage);
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };

  return (
    <AuthContext.Provider value={{ ...state, signIn, signUp, signOut, resetPassword, updatePassword }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const contextValue = useContext(AuthContext);
  if (contextValue === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return contextValue;
};