import { Request, Response, NextFunction } from 'express';
import { requirePermission, ACTIONS, USER_PROFILES, UserProfile, getPermissionErrorMessage } from './permissions';

/**
 * Validaciones específicas para el registro de pagos según el perfil del usuario
 */

export interface PaymentRequest {
  student_id: string;
  amount: number;
  payment_method: 'transferencia' | 'cheque' | 'efectivo' | 'tarjeta';
  cuota_id?: string; // ID de la cuota específica
  is_free_payment?: boolean; // Si es pago libre (no asociado a cuota)
  notes?: string;
}

/**
 * Middleware para validar pagos según el perfil del usuario
 */
export const validatePaymentRequest = (req: Request, res: Response, next: NextFunction) => {
  const userProfile = req.user?.profile as UserProfile;
  const paymentData: PaymentRequest = req.body;

  // Validaciones básicas
  if (!paymentData.student_id || !paymentData.amount || !paymentData.payment_method) {
    return res.status(400).json({
      error: 'Datos incompletos',
      message: 'Se requieren: student_id, amount, payment_method',
      code: 'INVALID_PAYMENT_DATA'
    });
  }

  // Validaciones específicas para perfil ASIST
  if (userProfile === USER_PROFILES.ASIST) {
    
    // 1. NO puede hacer pagos libres
    if (paymentData.is_free_payment || !paymentData.cuota_id) {
      return res.status(403).json({
        error: 'Acción no permitida',
        message: 'El perfil ASIST debe asociar todos los pagos a una cuota específica',
        code: 'FREE_PAYMENT_NOT_ALLOWED',
        userProfile
      });
    }

    // 2. El monto debe coincidir exactamente con el de la cuota
    // (Esta validación requiere consultar la DB para obtener el monto de la cuota)
    req.body._requireExactAmount = true;
  }

  // Para READONLY - no puede crear pagos en absoluto
  if (userProfile === USER_PROFILES.READONLY) {
    return res.status(403).json({
      error: 'Acceso denegado',
      message: 'El perfil READONLY no puede registrar pagos',
      code: 'READONLY_NO_PAYMENTS',
      userProfile
    });
  }

  next();
};

/**
 * Validación del monto exacto para cuotas (se ejecuta después de consultar la DB)
 */
export const validateExactAmount = async (
  paymentAmount: number, 
  cuotaId: string, 
  userProfile: UserProfile,
  supabaseClient: any
): Promise<{ valid: boolean; error?: string; expectedAmount?: number }> => {
  
  // Solo aplicar para perfil ASIST
  if (userProfile !== USER_PROFILES.ASIST) {
    return { valid: true };
  }

  try {
    // Consultar el monto esperado de la cuota
    const { data: cuotaData, error } = await supabaseClient
      .from('cuotas') // Asumo que existe una tabla de cuotas
      .select('amount, description')
      .eq('id', cuotaId)
      .single();

    if (error) {
      console.error('Error fetching cuota data:', error);
      return { 
        valid: false, 
        error: 'No se pudo verificar el monto de la cuota' 
      };
    }

    const expectedAmount = cuotaData.amount;
    
    if (paymentAmount !== expectedAmount) {
      return {
        valid: false,
        error: `El monto debe ser exactamente $${expectedAmount.toLocaleString('es-CL')} para esta cuota`,
        expectedAmount
      };
    }

    return { valid: true };

  } catch (err: any) {
    console.error('Exception validating exact amount:', err);
    return { 
      valid: false, 
      error: 'Error interno al validar el monto' 
    };
  }
};

/**
 * Middleware completo para endpoints de pagos
 */
export const paymentPermissionMiddleware = [
  requirePermission(ACTIONS.CREATE_SPECIFIC_PAYMENT),
  validatePaymentRequest
];

/**
 * Middleware para edición de pagos
 */
export const editPaymentMiddleware = [
  requirePermission(ACTIONS.EDIT_PAYMENT)
];

/**
 * Middleware para eliminación de pagos
 */
export const deletePaymentMiddleware = [
  requirePermission(ACTIONS.DELETE_PAYMENT)
];

/**
 * Función helper para aplicar en controladores
 */
export const handlePaymentValidation = async (
  req: Request, 
  res: Response, 
  supabaseClient: any
) => {
  const userProfile = req.user?.profile as UserProfile;
  const paymentData: PaymentRequest = req.body;

  // Validación de monto exacto si es requerida
  if (req.body._requireExactAmount && paymentData.cuota_id) {
    const validation = await validateExactAmount(
      paymentData.amount, 
      paymentData.cuota_id, 
      userProfile, 
      supabaseClient
    );

    if (!validation.valid) {
      return res.status(400).json({
        error: 'Monto incorrecto',
        message: validation.error,
        expectedAmount: validation.expectedAmount,
        providedAmount: paymentData.amount,
        code: 'INVALID_AMOUNT'
      });
    }
  }

  return null; // No error, continuar
};

/**
 * Ejemplo de uso en un controlador de Express
 */
export const examplePaymentController = async (req: Request, res: Response) => {
  try {
    const userProfile = req.user?.profile as UserProfile;
    const paymentData: PaymentRequest = req.body;

    // Aplicar validaciones adicionales
    const validationError = await handlePaymentValidation(req, res, /* supabaseClient */);
    if (validationError) return; // Response ya enviado

    // Log de la acción para auditoría
    console.log(`💰 Registrando pago - Perfil: ${userProfile}`, {
      userId: req.user?.id,
      userEmail: req.user?.email,
      studentId: paymentData.student_id,
      amount: paymentData.amount,
      cuotaId: paymentData.cuota_id,
      isFreePayment: paymentData.is_free_payment,
      timestamp: new Date().toISOString()
    });

    // Aquí iría la lógica para guardar el pago en la DB
    // const result = await savePayment(paymentData);

    res.json({
      success: true,
      message: 'Pago registrado correctamente',
      // payment: result
    });

  } catch (error: any) {
    console.error('Error in payment controller:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
};

/**
 * Tipos de respuesta para el frontend
 */
export interface PaymentValidationResponse {
  success: boolean;
  error?: string;
  message?: string;
  code?: string;
  expectedAmount?: number;
  providedAmount?: number;
  userProfile?: UserProfile;
}