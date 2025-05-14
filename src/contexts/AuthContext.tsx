import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../services/supabase';
import { AuthContextType, AuthState, User } from '../types/auth';
import { LogCode } from '../types/logging';
import Logger from '../services/logger';
import toast from 'react-hot-toast';

const AuthContext = createContext<AuthContextType | undefined>(undefined);
const logger = Logger.getInstance();

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({
    user: null,
    session: null,
    loading: true,
  });

  useEffect(() => {
    // Check active sessions and subscribe to auth changes
    supabase.auth.getSession().then(({ data: { session } }) => {
      setState(prev => ({ ...prev, session, user: session?.user ?? null }));
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setState(prev => ({ ...prev, session, user: session?.user ?? null }));
    });

    setState(prev => ({ ...prev, loading: false }));

    return () => subscription.unsubscribe();
  }, []);

  const signUp = async (email: string, password: string) => {
    try {
      const { error } = await supabase.auth.signUp({
        email,
        password,
      });

      if (error) {
        await logger.log(
          LogCode.AUTH_SIGNUP_FAILED,
          error.message,
          undefined,
          logger.getActionableStep(LogCode.AUTH_SIGNUP_FAILED)
        );
        throw error;
      }

      await logger.log(
        LogCode.AUTH_SIGNUP_SUCCESS,
        'Usuario registrado exitosamente',
        email
      );
      toast.success('Revisa tu email para confirmar tu cuenta');
    } catch (error) {
      toast.error(error.message);
      throw error;
    }
  };

  const signIn = async (email: string, password: string, remember = false) => {
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        await logger.log(
          LogCode.AUTH_LOGIN_FAILED,
          error.message,
          email,
          logger.getActionableStep(LogCode.AUTH_LOGIN_FAILED)
        );
        throw error;
      }

      await logger.log(
        LogCode.AUTH_LOGIN_SUCCESS,
        'Inicio de sesión exitoso',
        email
      );
      toast.success('Inicio de sesión exitoso');
    } catch (error) {
      toast.error(error.message);
      throw error;
    }
  };

  const signOut = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      
      if (error) {
        await logger.log(
          LogCode.AUTH_LOGOUT_FAILED,
          error.message,
          state.user?.id,
          logger.getActionableStep(LogCode.AUTH_LOGOUT_FAILED)
        );
        throw error;
      }

      // Clear auth state
      setState({
        user: null,
        session: null,
        loading: false
      });

      await logger.log(
        LogCode.AUTH_LOGOUT,
        'Sesión cerrada exitosamente',
        state.user?.id
      );

      toast.success('Has cerrado sesión exitosamente');
    } catch (error) {
      toast.error(error.message);
      throw error;
    }
  };

  const resetPassword = async (email: string) => {
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email);
      if (error) {
        await logger.log(
          LogCode.AUTH_PASSWORD_RESET_FAILED,
          error.message,
          undefined,
          logger.getActionableStep(LogCode.AUTH_PASSWORD_RESET_FAILED)
        );
        throw error;
      }

      await logger.log(
        LogCode.AUTH_PASSWORD_RESET_REQUEST,
        'Solicitud de restablecimiento de contraseña enviada',
        email
      );
      toast.success('Revisa tu email para restablecer tu contraseña');
    } catch (error) {
      toast.error(error.message);
      throw error;
    }
  };

  const updatePassword = async (password: string) => {
    try {
      const { error } = await supabase.auth.updateUser({
        password,
      });
      if (error) {
        await logger.log(
          LogCode.AUTH_PASSWORD_RESET_FAILED,
          error.message,
          state.user?.id,
          logger.getActionableStep(LogCode.AUTH_PASSWORD_RESET_FAILED)
        );
        throw error;
      }

      await logger.log(
        LogCode.AUTH_PASSWORD_RESET_SUCCESS,
        'Contraseña actualizada exitosamente',
        state.user?.id
      );
      toast.success('Contraseña actualizada exitosamente');
    } catch (error) {
      toast.error(error.message);
      throw error;
    }
  };

  const value = {
    ...state,
    signUp,
    signIn,
    signOut,
    resetPassword,
    updatePassword,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}