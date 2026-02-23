import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { User as SupabaseUser } from '@supabase/supabase-js';
import { supabase, signInWithGoogle, handleSupabaseError } from '../services/supabase';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';
import Logger from '../services/logger'; 
import { LogCode } from '../types/logging'; 
import { AuthContextType, AuthState, User as LocalUser } from '../types/auth';
import { useIdleSessionTimeout } from '../hooks/useIdleSessionTimeout';
import { clearGuardianCaches } from '../services/matricula';

const ENABLE_IDLE_TIMEOUT = import.meta.env.PROD;

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

const initialAuthState: AuthState = {
  session: null,
  user: null,
  loading: true,
};

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [state, setState] = useState<AuthState>(initialAuthState);
  const navigate = useNavigate();
  // Idle session timeout (30 min) implementation
  const IDLE_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutos

  const mapSupabaseUserToLocalUser = (supabaseUser: SupabaseUser | null | undefined, role?: string, profile?: string): LocalUser | null => {
    if (!supabaseUser) return null;
    // Normalize role to lowercase to avoid casing mismatches (e.g. 'GUARDIAN' vs 'guardian').
  const normalizedRole = role ? String(role).toLowerCase() : undefined;
  const recognizedRole = normalizedRole && ['admin', 'asist', 'guardian'].includes(normalizedRole) ? normalizedRole : undefined;
  const finalRole = recognizedRole ?? 'guardian';
    // Derive profile from role if not explicitly provided (profile column no longer exists)
    const derivedProfile = (profile || (() => {
      const r = (normalizedRole ?? finalRole).toUpperCase();
      if (r === 'ADMIN') return 'ADMIN';
      if (r === 'ASIST') return 'ASIST';
      return 'READONLY';
    })()) as 'ADMIN' | 'ASIST' | 'READONLY';
    return {
      id: supabaseUser.id,
      email: supabaseUser.email || '',
      created_at: supabaseUser.created_at,
      updated_at: supabaseUser.updated_at || supabaseUser.created_at,
      role: finalRole,
      profile: derivedProfile,
    };
  };

  const fetchProfileRole = async (userId: string | undefined): Promise<{ role?: string; profile?: string }> => {
    if (!userId) return {};
    try {
      // Fetch both role and profile from profiles table (this is accessible via REST API)
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
      
      if (profileError && profileError.code !== 'PGRST116') { // PGRST116 = no rows found
        Logger.getInstance().log(LogCode.AUTH_SESSION_FETCH_FAILED, `Error fetching profile data: ${profileError.message}`, userId, 'fetchProfileRole', { level: 'WARN', area: 'AUTH', error: profileError });
      }

      if (!profileData?.role) {
        return {
          role: 'guardian',
          profile: 'READONLY',
        };
      }

      const roleLowerRaw = profileData?.role ? String(profileData.role).toLowerCase() : undefined;
      const roleLower = roleLowerRaw && ['admin', 'asist', 'guardian'].includes(roleLowerRaw) ? roleLowerRaw : 'guardian';
      const roleUpper = roleLower.toUpperCase();
      const derivedProfile = roleUpper === 'ADMIN' || roleUpper === 'ASIST' ? roleUpper : 'READONLY';
      return {
        role: roleLower,
        profile: derivedProfile
      };
    } catch (err: any) {
      Logger.getInstance().log(LogCode.AUTH_SESSION_FETCH_FAILED, `Exception fetching profile data: ${err.message}`, userId, 'fetchProfileRoleCatch', { level: 'ERROR', area: 'AUTH', errorMessage: err.message });
      return { profile: 'READONLY' }; // Safe default
    }
  };

  useEffect(() => {
    const getSession = async () => {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();
        if (error) {
          Logger.getInstance().log(LogCode.AUTH_SESSION_FETCH_FAILED, `Error fetching session initial: ${error.message}`, undefined, 'getSession', { level: 'ERROR', area: 'AUTH', error });
          throw error;
        }
        const { role, profile } = await fetchProfileRole(session?.user?.id);
        setState({ session, user: mapSupabaseUserToLocalUser(session?.user, role, profile), loading: false });
      } catch (error: any) {
        Logger.getInstance().log(LogCode.AUTH_SESSION_FETCH_FAILED, `Catch getSession: ${error.message}`, undefined, 'getSessionCatch', { level: 'ERROR', area: 'AUTH', errorMessage: error.message });
        setState(prev => ({ ...prev, loading: false }));
      }
    };
    getSession();

    const { data: authListener } = supabase.auth.onAuthStateChange((event, session) => {
      Logger.getInstance().log(LogCode.AUTH_STATE_CHANGED, `Auth event: ${event}`, session?.user?.id, 'onAuthStateChange', { level: 'INFO', area: 'AUTH', session });
      (async () => {
        const { role, profile } = await fetchProfileRole(session?.user?.id);
        setState({ session, user: mapSupabaseUserToLocalUser(session?.user, role, profile), loading: false });
      })();
      
      if (event === 'PASSWORD_RECOVERY') {
        toast.success('Puedes establecer tu nueva contraseña ahora.');
        // if (window.location.pathname !== '/reset-password') { 
        //   navigate('/reset-password');
        // }
      } else if (event === 'SIGNED_OUT') {
        clearGuardianCaches(); // Prevent leaking cached data across sessions
        navigate('/login');
      }
    });

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [navigate]);

  const signIn = async (email: string, password: string /*, remember = false */) => {
    setState(prev => ({ ...prev, loading: true }));
    let userIdOnError: string | undefined = undefined;
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) {
        Logger.getInstance().log(LogCode.AUTH_LOGIN_FAILED, `Error signing in for ${email}: ${error.message}`, undefined, 'signIn', { level: 'ERROR', area: 'AUTH', email, error });
        toast.error(error.message || 'Error al iniciar sesión.');
        throw error;
      }
      if (!data.session || !data.user) {
        Logger.getInstance().log(LogCode.AUTH_LOGIN_FAILED, `No session or user data after sign in for ${email}`, undefined, 'signIn', { level: 'ERROR', area: 'AUTH', email });
        toast.error('Error al iniciar sesión: No se recibió la sesión.');
        throw new Error('No session or user data after sign in');
      }
      userIdOnError = data.user.id; 
      Logger.getInstance().log(LogCode.AUTH_LOGIN_SUCCESS, `User signed in successfully: ${email}`, data.user.id, 'signIn', { level: 'INFO', area: 'AUTH', email });
      toast.success('Inicio de sesión exitoso');
    } catch (error: any) {
      setState(prev => ({ ...prev, loading: false }));
      if (!error.message?.includes('Error signing in') && !error.message?.includes('No session or user data')) {
        Logger.getInstance().log(LogCode.AUTH_LOGIN_FAILED, `SignIn catch block for ${email}: ${error.message}`, userIdOnError, 'signInCatch', { level: 'ERROR', area: 'AUTH', email, error });
      }
      toast.error(error.message || 'Error al iniciar sesión.');
      throw error; 
    }
  };

  const signUp = async (email: string, password: string) => {
    setState(prev => ({ ...prev, loading: true }));
    let userIdForLog: string | undefined = undefined;
    try {
      const { data, error } = await supabase.auth.signUp({ 
        email, 
        password,
        options: {
          // emailRedirectTo: `${window.location.origin}/confirm-email` 
        }
      });
      if (error) {
        Logger.getInstance().log(LogCode.AUTH_SIGNUP_FAILED, `Error signing up for ${email}: ${error.message}`, undefined, 'signUp', { level: 'ERROR', area: 'AUTH', email, error });
        toast.error(error.message || 'Error al registrar la cuenta.');
        throw error;
      }
      userIdForLog = data.user?.id;
      if (data.user && data.user.identities && data.user.identities.length === 0) { 
         Logger.getInstance().log(LogCode.AUTH_SIGNUP_SUCCESS, `Signup successful, confirmation email sent for: ${email}`, userIdForLog, 'signUp', { level: 'INFO', area: 'AUTH', email, confirmationNeeded: true });
         toast.success('Registro exitoso. Revisa tu correo para confirmar la cuenta.');
         setState(prev => ({ ...prev, loading: false, user: null, session: null })); 
         return;
      }
      Logger.getInstance().log(LogCode.AUTH_SIGNUP_SUCCESS, `User signed up and logged in successfully: ${email}`, userIdForLog, 'signUp', { level: 'INFO', area: 'AUTH', email, confirmationNeeded: false });
      toast.success('Cuenta registrada exitosamente.');
    } catch (error: any) {
      setState(prev => ({ ...prev, loading: false }));
      if (!error.message?.includes('Error signing up')) {
         Logger.getInstance().log(LogCode.AUTH_SIGNUP_FAILED, `SignUp catch block for ${email}: ${error.message}`, userIdForLog, 'signUpCatch', { level: 'ERROR', area: 'AUTH', email, error });
      }
      toast.error(error.message || 'Error al registrar la cuenta.');
      throw error;
    }
  };

  const signOut = useCallback(async () => {
    setState(prev => ({ ...prev, loading: true }));
    const userIdForLog = state.user?.id;
    try {
      const { error } = await supabase.auth.signOut();
      if (error) {
        Logger.getInstance().log(LogCode.AUTH_LOGOUT_FAILED, `Error signing out: ${error.message}`, userIdForLog, 'signOut', { level: 'ERROR', area: 'AUTH', error });
        toast.error(error.message || 'Error al cerrar sesión.');
        throw error;
      }
      Logger.getInstance().log(LogCode.AUTH_LOGOUT_SUCCESS, 'User signed out successfully', userIdForLog, 'signOut', { level: 'INFO', area: 'AUTH' });
      toast.success('Sesión cerrada exitosamente.');
    } catch (error: any) {
      setState(prev => ({ ...prev, loading: false }));
      if (!error.message?.includes('Error signing out')) {
        Logger.getInstance().log(LogCode.AUTH_LOGOUT_FAILED, `SignOut catch block: ${error.message}`, userIdForLog, 'signOutCatch', { level: 'ERROR', area: 'AUTH', error });
      }
      toast.error(error.message || 'Error al cerrar sesión.');
      throw error; 
    }
  }, [state.user?.id]);

  const resetPassword = async (email: string) => {
    setState(prev => ({ ...prev, loading: true }));
    try {
      const functionUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/password-recovery`;
      const response = await fetch(functionUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      const result = await response.json();

      if (!response.ok) {
        const errorMessage = result.error || `Error HTTP ${response.status}: ${response.statusText}` || 'Error al enviar el correo de recuperación.';
        Logger.getInstance().log(LogCode.AUTH_PASSWORD_RESET_FAILED, `Error calling password-recovery function for ${email}: ${errorMessage}`, undefined, 'resetPassword', { level: 'ERROR', area: 'AUTH', email, responseStatus: response.status, errorDetails: result.error });
        toast.error(errorMessage);
        throw new Error(errorMessage);
      }
      
      Logger.getInstance().log(LogCode.AUTH_PASSWORD_RESET_SUCCESS, `Password reset email initiated successfully for: ${email}`, undefined, 'resetPassword', { level: 'INFO', area: 'AUTH', email });
      toast.success(result.message || 'Si el correo existe, recibirás un enlace para restablecer tu contraseña.');

    } catch (error: any) { 
      const errorMessage = error.message || 'Ocurrió un error inesperado al solicitar el restablecimiento de contraseña.';
      if (!errorMessage.includes('Error HTTP') && !errorMessage.includes( 'Error al enviar el correo de recuperación.')) {
        Logger.getInstance().log(LogCode.AUTH_PASSWORD_RESET_FAILED, `AuthContext resetPassword catch block for ${email}: ${errorMessage}`, undefined, 'resetPasswordCatch', { level: 'ERROR', area: 'AUTH', email, errorDetails: error.message });
      }
      toast.error(errorMessage);
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };
  
  const signInWithGoogleProvider = async () => {
    setState(prev => ({ ...prev, loading: true }));
    try {
      Logger.getInstance().log(LogCode.AUTH_LOGIN_SUCCESS, 'Google OAuth login initiated', undefined, 'signInWithGoogle', { level: 'INFO', area: 'AUTH', provider: 'google' });
      await signInWithGoogle();
      // The actual sign-in will be handled by the auth state change listener
      Logger.getInstance().log(LogCode.AUTH_LOGIN_SUCCESS, 'Google OAuth redirect initiated successfully', undefined, 'signInWithGoogle', { level: 'INFO', area: 'AUTH', provider: 'google' });
    } catch (error: any) {
      setState(prev => ({ ...prev, loading: false }));
      Logger.getInstance().log(LogCode.AUTH_LOGIN_FAILED, `Google OAuth login failed: ${error.message}`, undefined, 'signInWithGoogleCatch', { level: 'ERROR', area: 'AUTH', provider: 'google', error });
      handleSupabaseError(error);
      throw error;
    }
  };

  const updatePassword = async (newPassword: string) => {
    setState(prev => ({ ...prev, loading: true }));
    const userIdForLog = state.user?.id;
    try {
      const { error } = await supabase.auth.updateUser({ password: newPassword });
      if (error) {
        Logger.getInstance().log(LogCode.AUTH_PASSWORD_UPDATE_FAILED, `Error updating password: ${error.message}`, userIdForLog, 'updatePassword', { level: 'ERROR', area: 'AUTH', error });
        toast.error(error.message || 'Error al actualizar la contraseña.');
        throw error;
      }
      Logger.getInstance().log(LogCode.AUTH_PASSWORD_UPDATE_SUCCESS, 'Password updated successfully', userIdForLog, 'updatePassword', { level: 'INFO', area: 'AUTH' });
      toast.success('Contraseña actualizada exitosamente. Serás redirigido al inicio de sesión.');
      navigate('/login'); 
    } catch (error: any) {
      const errorMessage = error.message || 'Error al actualizar la contraseña.';
      if (!errorMessage.includes('Error updating password')) {
         Logger.getInstance().log(LogCode.AUTH_PASSWORD_UPDATE_FAILED, `AuthContext updatePassword catch block: ${errorMessage}`, userIdForLog, 'updatePasswordCatch', { level: 'ERROR', area: 'AUTH', errorDetails: error.message });
      }
      toast.error(errorMessage);
    } finally {
      setState(prev => ({ ...prev, loading: false }));
    }
  };

  const refreshProfileRole = async () => {
    const userId = state.user?.id;
    if (!userId) return;
    const { role, profile } = await fetchProfileRole(userId);
    setState(prev => ({ 
      ...prev, 
      user: prev.user ? { 
        ...prev.user, 
        role: role,
        profile: profile as 'ADMIN' | 'ASIST' | 'READONLY'
      } : prev.user 
    }));
  };

  useIdleSessionTimeout({
    enabled: ENABLE_IDLE_TIMEOUT,
    isActive: Boolean(state.session && state.user),
    timeoutMs: IDLE_TIMEOUT_MS,
    onTimeout: async () => {
      toast('Sesión terminada por inactividad (30 min).', { icon: '⏱️' });
      try {
        await signOut();
      } catch {
        /* errores ya reportados por signOut */
      }
    }
  });

  const contextValue = useMemo(() => ({
    ...state,
    signIn,
    signUp,
    signOut,
    resetPassword,
    updatePassword,
    signInWithGoogle: signInWithGoogleProvider,
    refreshProfileRole,
  }), [state, signIn, signUp, signOut, resetPassword, updatePassword, signInWithGoogleProvider, refreshProfileRole]);

  return (
    <AuthContext.Provider value={contextValue}>
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