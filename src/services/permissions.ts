/**
 * Sistema de permisos por perfil de usuario
 * Controla qué acciones puede realizar cada tipo de usuario
 */

export const USER_PROFILES = {
  ADMIN: 'ADMIN',
  ASIST: 'ASIST', 
  READONLY: 'READONLY'
} as const;

export type UserProfile = typeof USER_PROFILES[keyof typeof USER_PROFILES];

/**
 * Acciones que pueden ser restringidas según el perfil
 */
export const ACTIONS = {
  // Pagos
  CREATE_FREE_PAYMENT: 'CREATE_FREE_PAYMENT',
  EDIT_PAYMENT: 'EDIT_PAYMENT',
  DELETE_PAYMENT: 'DELETE_PAYMENT',
  CREATE_SPECIFIC_PAYMENT: 'CREATE_SPECIFIC_PAYMENT',
  VIEW_PAYMENTS: 'VIEW_PAYMENTS',
  
  // Estudiantes y Apoderados
  EDIT_STUDENT: 'EDIT_STUDENT',
  DELETE_STUDENT: 'DELETE_STUDENT',
  EDIT_GUARDIAN: 'EDIT_GUARDIAN',
  DELETE_GUARDIAN: 'DELETE_GUARDIAN',
  
  // Reportes
  GENERATE_REPORTS: 'GENERATE_REPORTS',
  EXPORT_DATA: 'EXPORT_DATA',
  
  // Sistema
  MANAGE_USERS: 'MANAGE_USERS',
  VIEW_LOGS: 'VIEW_LOGS'
} as const;

export type Action = typeof ACTIONS[keyof typeof ACTIONS];

/**
 * Matriz de permisos: qué puede hacer cada perfil
 */
export const PERMISSIONS: Record<UserProfile, Record<Action, boolean>> = {
  [USER_PROFILES.ADMIN]: {
    // ADMIN puede hacer todo
    [ACTIONS.CREATE_FREE_PAYMENT]: true,
    [ACTIONS.EDIT_PAYMENT]: true,
    [ACTIONS.DELETE_PAYMENT]: true,
    [ACTIONS.CREATE_SPECIFIC_PAYMENT]: true,
    [ACTIONS.VIEW_PAYMENTS]: true,
    [ACTIONS.EDIT_STUDENT]: true,
    [ACTIONS.DELETE_STUDENT]: true,
    [ACTIONS.EDIT_GUARDIAN]: true,
    [ACTIONS.DELETE_GUARDIAN]: true,
    [ACTIONS.GENERATE_REPORTS]: true,
    [ACTIONS.EXPORT_DATA]: true,
    [ACTIONS.MANAGE_USERS]: true,
    [ACTIONS.VIEW_LOGS]: true
  },
  
  [USER_PROFILES.ASIST]: {
    // ASIST tiene acceso limitado - NO puede pagos libres ni editar/eliminar
    [ACTIONS.CREATE_FREE_PAYMENT]: false,  // ❌ NO puede hacer pagos libres
    [ACTIONS.EDIT_PAYMENT]: false,         // ❌ NO puede editar pagos
    [ACTIONS.DELETE_PAYMENT]: false,       // ❌ NO puede eliminar pagos
    [ACTIONS.CREATE_SPECIFIC_PAYMENT]: true, // ✅ SÍ puede pagos a cuotas específicas
    [ACTIONS.VIEW_PAYMENTS]: true,
    [ACTIONS.EDIT_STUDENT]: false,
    [ACTIONS.DELETE_STUDENT]: false,
    [ACTIONS.EDIT_GUARDIAN]: false,
    [ACTIONS.DELETE_GUARDIAN]: false,
    [ACTIONS.GENERATE_REPORTS]: true,
    [ACTIONS.EXPORT_DATA]: false,
    [ACTIONS.MANAGE_USERS]: false,
    [ACTIONS.VIEW_LOGS]: false
  },
  
  [USER_PROFILES.READONLY]: {
    // READONLY solo puede ver información
    [ACTIONS.CREATE_FREE_PAYMENT]: false,
    [ACTIONS.EDIT_PAYMENT]: false,
    [ACTIONS.DELETE_PAYMENT]: false,
    [ACTIONS.CREATE_SPECIFIC_PAYMENT]: false,
    [ACTIONS.VIEW_PAYMENTS]: true,
    [ACTIONS.EDIT_STUDENT]: false,
    [ACTIONS.DELETE_STUDENT]: false,
    [ACTIONS.EDIT_GUARDIAN]: false,
    [ACTIONS.DELETE_GUARDIAN]: false,
    [ACTIONS.GENERATE_REPORTS]: true,
    [ACTIONS.EXPORT_DATA]: false,
    [ACTIONS.MANAGE_USERS]: false,
    [ACTIONS.VIEW_LOGS]: false
  }
};

/**
 * Verifica si un usuario tiene permiso para realizar una acción
 */
export const hasPermission = (userProfile: UserProfile, action: Action): boolean => {
  return PERMISSIONS[userProfile]?.[action] ?? false;
};

/**
 * Obtiene todas las acciones permitidas para un perfil
 */
export const getAllowedActions = (userProfile: UserProfile): Action[] => {
  return Object.entries(PERMISSIONS[userProfile])
    .filter(([_, allowed]) => allowed)
    .map(([action]) => action as Action);
};

/**
 * Obtiene todas las acciones denegadas para un perfil
 */
export const getDeniedActions = (userProfile: UserProfile): Action[] => {
  return Object.entries(PERMISSIONS[userProfile])
    .filter(([_, allowed]) => !allowed)
    .map(([action]) => action as Action);
};

/**
 * Middleware para verificar permisos en el backend
 */
export const requirePermission = (action: Action) => {
  return (req: any, res: any, next: any) => {
    const userProfile = req.user?.profile as UserProfile;
    
    if (!userProfile) {
      return res.status(401).json({ 
        error: 'Usuario no autenticado',
        code: 'UNAUTHORIZED'
      });
    }
    
    if (!hasPermission(userProfile, action)) {
      // Log del intento de acción no permitida
      console.warn(`🚫 Acción denegada: ${action} para perfil ${userProfile}`, {
        userId: req.user?.id,
        userEmail: req.user?.email,
        action,
        userProfile,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        timestamp: new Date().toISOString()
      });
      
      return res.status(403).json({ 
        error: `Acción no permitida para perfil ${userProfile}`,
        action,
        userProfile,
        code: 'FORBIDDEN'
      });
    }
    
    // Log de acción permitida (opcional, para auditoría)
    console.log(`✅ Acción permitida: ${action} para perfil ${userProfile}`, {
      userId: req.user?.id,
      action,
      userProfile
    });
    
    next();
  };
};

/**
 * Helper para verificar permisos en el frontend
 */
export class PermissionChecker {
  constructor(private userProfile: UserProfile) {}
  
  can(action: Action): boolean {
    return hasPermission(this.userProfile, action);
  }
  
  cannot(action: Action): boolean {
    return !this.can(action);
  }
  
  canCreateFreePayment(): boolean {
    return this.can(ACTIONS.CREATE_FREE_PAYMENT);
  }
  
  canEditPayment(): boolean {
    return this.can(ACTIONS.EDIT_PAYMENT);
  }
  
  canDeletePayment(): boolean {
    return this.can(ACTIONS.DELETE_PAYMENT);
  }
  
  canCreateSpecificPayment(): boolean {
    return this.can(ACTIONS.CREATE_SPECIFIC_PAYMENT);
  }
  
  isAdmin(): boolean {
    return this.userProfile === USER_PROFILES.ADMIN;
  }
  
  isAssistant(): boolean {
    return this.userProfile === USER_PROFILES.ASIST;
  }
  
  isReadOnly(): boolean {
    return this.userProfile === USER_PROFILES.READONLY;
  }
}

/**
 * Hook para usar en React components
 */
export const usePermissions = (userProfile: UserProfile) => {
  return new PermissionChecker(userProfile);
};

/**
 * Mensajes de error personalizados según la acción
 */
export const getPermissionErrorMessage = (action: Action, userProfile: UserProfile): string => {
  const messages: Record<Action, string> = {
    [ACTIONS.CREATE_FREE_PAYMENT]: 'Solo administradores pueden registrar pagos libres. Debe asociar el pago a una cuota específica.',
    [ACTIONS.EDIT_PAYMENT]: 'No tiene permisos para editar pagos existentes. Contacte a un administrador.',
    [ACTIONS.DELETE_PAYMENT]: 'No tiene permisos para eliminar pagos. Contacte a un administrador.',
    [ACTIONS.CREATE_SPECIFIC_PAYMENT]: 'No tiene permisos para registrar pagos.',
    [ACTIONS.VIEW_PAYMENTS]: 'No tiene permisos para ver información de pagos.',
    [ACTIONS.EDIT_STUDENT]: 'No tiene permisos para editar información de estudiantes.',
    [ACTIONS.DELETE_STUDENT]: 'No tiene permisos para eliminar estudiantes.',
    [ACTIONS.EDIT_GUARDIAN]: 'No tiene permisos para editar información de apoderados.',
    [ACTIONS.DELETE_GUARDIAN]: 'No tiene permisos para eliminar apoderados.',
    [ACTIONS.GENERATE_REPORTS]: 'No tiene permisos para generar reportes.',
    [ACTIONS.EXPORT_DATA]: 'No tiene permisos para exportar datos.',
    [ACTIONS.MANAGE_USERS]: 'Solo administradores pueden gestionar usuarios.',
    [ACTIONS.VIEW_LOGS]: 'No tiene permisos para ver logs del sistema.'
  };
  
  return messages[action] || `Acción no permitida para perfil ${userProfile}`;
};