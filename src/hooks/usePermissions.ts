import { useContext } from 'react';
import { AuthContext } from '../contexts/AuthContext';
import { PermissionChecker, USER_PROFILES, UserProfile } from '../services/permissions';

type PermissionMethods = Pick<
  PermissionChecker,
  | 'can'
  | 'cannot'
  | 'canCreateFreePayment'
  | 'canEditPayment'
  | 'canDeletePayment'
  | 'canCreateSpecificPayment'
  | 'isAdmin'
  | 'isAssistant'
  | 'isReadOnly'
>;

type PermissionHookReturn = PermissionMethods & {
  userProfile: UserProfile;
  user: any;
  showFreePaymentOption: boolean;
  showEditPaymentButton: boolean;
  showDeletePaymentButton: boolean;
  showAdminFeatures: boolean;
  isLimitedUser: boolean;
};

/**
 * Hook para usar permisos en React components
 * Combina el contexto de autenticación con el sistema de permisos
 */
export const usePermissions = (): PermissionHookReturn => {
  const authContext = useContext(AuthContext);
  
  if (!authContext) {
    throw new Error('usePermissions must be used within an AuthProvider');
  }
  
  const { user } = authContext;
  const userProfile = (user?.profile || USER_PROFILES.ADMIN) as UserProfile;
  
  const permissions = new PermissionChecker(userProfile);
  
  // Importante: conservar el prototipo del PermissionChecker para que los métodos (isAssistant, isAdmin, etc.)
  // sigan siendo funciones. No usar spread sobre la instancia, ya que no copia métodos del prototipo.
  const enhanced = Object.assign(permissions as any, {
    userProfile,
    user,
    // Shortcuts adicionales para facilitar el uso
    showFreePaymentOption: permissions.canCreateFreePayment(),
    showEditPaymentButton: permissions.canEditPayment(),
    showDeletePaymentButton: permissions.canDeletePayment(),
    showAdminFeatures: permissions.isAdmin(),
    isLimitedUser: permissions.isAssistant() || permissions.isReadOnly(),
  }) as PermissionHookReturn;
  return enhanced;
};

/**
 * Hook simplificado para verificar una acción específica
 */
export const useHasPermission = (action: string) => {
  const permissions = usePermissions();
  return permissions.can(action as any);
};

/**
 * Hook para obtener solo el perfil del usuario actual
 */
export const useUserProfile = (): UserProfile => {
  const authContext = useContext(AuthContext);
  
  if (!authContext) {
    throw new Error('useUserProfile must be used within an AuthProvider');
  }
  
  return (authContext.user?.profile || USER_PROFILES.ADMIN) as UserProfile;
};