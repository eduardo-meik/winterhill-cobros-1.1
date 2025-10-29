import React from 'react';
import { usePermissions } from '../hooks/usePermissions';

/**
 * Componente que muestra diferentes botones según los permisos del usuario
 * Ejemplo de implementación de restricciones de UI
 */
export const PaymentActionsComponent: React.FC<{
  paymentId?: string;
  onCreateFreePayment?: () => void;
  onCreateSpecificPayment?: () => void;
  onEditPayment?: (id: string) => void;
  onDeletePayment?: (id: string) => void;
}> = ({
  paymentId,
  onCreateFreePayment,
  onCreateSpecificPayment,
  onEditPayment,
  onDeletePayment
}) => {
  const permissions = usePermissions();

  return (
    <div className="payment-actions space-y-2">
      {/* Información del perfil actual (solo para debugging) */}
      {process.env.NODE_ENV === 'development' && (
        <div className="bg-gray-100 p-2 rounded text-xs">
          <strong>Perfil:</strong> {permissions.userProfile} | 
          <strong> Email:</strong> {permissions.user?.email}
        </div>
      )}

      {/* Botones de creación de pagos */}
      <div className="payment-creation-buttons space-x-2">
        {/* Pago a cuota específica - TODOS los perfiles pueden hacer esto */}
        {permissions.canCreateSpecificPayment() && (
          <button
            onClick={onCreateSpecificPayment}
            className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          >
            📋 Registrar Pago a Cuota
          </button>
        )}

        {/* Pago libre - SOLO ADMIN puede hacer esto */}
        {permissions.showFreePaymentOption && (
          <button
            onClick={onCreateFreePayment}
            className="bg-orange-500 text-white px-4 py-2 rounded hover:bg-orange-600"
          >
            💰 Pago Libre
          </button>
        )}
      </div>

      {/* Botones de gestión de pagos (solo si hay un pago seleccionado) */}
      {paymentId && (
        <div className="payment-management-buttons space-x-2">
          {/* Botón Editar - SOLO ADMIN */}
          {permissions.showEditPaymentButton && (
            <button
              onClick={() => onEditPayment?.(paymentId)}
              className="bg-yellow-500 text-white px-3 py-1 rounded hover:bg-yellow-600"
            >
              ✏️ Editar
            </button>
          )}

          {/* Botón Eliminar - SOLO ADMIN */}
          {permissions.showDeletePaymentButton && (
            <button
              onClick={() => onDeletePayment?.(paymentId)}
              className="bg-red-500 text-white px-3 py-1 rounded hover:bg-red-600"
            >
              🗑️ Eliminar
            </button>
          )}

          {/* Mensaje para usuarios limitados */}
          {permissions.isLimitedUser && (
            <span className="text-sm text-gray-500 italic">
              Contacte al administrador para editar o eliminar pagos
            </span>
          )}
        </div>
      )}

      {/* Indicador visual del nivel de acceso */}
      <div className="access-level-indicator">
        {permissions.isAdmin() && (
          <span className="bg-green-100 text-green-800 px-2 py-1 rounded text-xs">
            🔓 Acceso Completo
          </span>
        )}
        {permissions.isAssistant() && (
          <span className="bg-yellow-100 text-yellow-800 px-2 py-1 rounded text-xs">
            🔒 Acceso Limitado (Asistente)
          </span>
        )}
        {permissions.isReadOnly() && (
          <span className="bg-gray-100 text-gray-800 px-2 py-1 rounded text-xs">
            👁️ Solo Lectura
          </span>
        )}
      </div>
    </div>
  );
};

/**
 * Componente para mostrar/ocultar contenido según permisos
 */
export const PermissionGuard: React.FC<{
  action: string;
  fallback?: React.ReactNode;
  children: React.ReactNode;
}> = ({ action, fallback = null, children }) => {
  const permissions = usePermissions();
  
  if (!permissions.can(action as any)) {
    return <>{fallback}</>;
  }
  
  return <>{children}</>;
};

/**
 * Componente de ejemplo para el modal de "Registrar Pago"
 */
export const PaymentRegistrationModal: React.FC<{
  isOpen: boolean;
  onClose: () => void;
}> = ({ isOpen, onClose }) => {
  const permissions = usePermissions();

  if (!isOpen) return null;

  return (
    <div className="modal-overlay fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
      <div className="bg-white p-6 rounded-lg max-w-md w-full">
        <h2 className="text-xl font-bold mb-4">Registrar Pago</h2>
        
        {/* Formulario adaptado según permisos */}
        <form className="space-y-4">
          {/* Campo Estudiante - Todos */}
          <div>
            <label className="block text-sm font-medium mb-1">Estudiante</label>
            <select className="w-full border rounded px-3 py-2">
              <option>Seleccionar estudiante...</option>
            </select>
          </div>

          {/* Campo Cuota - OBLIGATORIO para ASIST */}
          <div>
            <label className="block text-sm font-medium mb-1">
              Cuota {permissions.isAssistant() && <span className="text-red-500">*</span>}
            </label>
            <select className="w-full border rounded px-3 py-2">
              <option value="">Seleccionar cuota...</option>
              <option value="matricula">Matrícula 2025</option>
              <option value="marzo">Marzo 2025</option>
              <option value="abril">Abril 2025</option>
            </select>
            {permissions.isAssistant() && (
              <p className="text-xs text-red-500 mt-1">
                Debe seleccionar una cuota específica
              </p>
            )}
          </div>

          {/* Opción "Pago Libre" - SOLO ADMIN */}
          {permissions.showFreePaymentOption && (
            <div>
              <label className="flex items-center">
                <input type="checkbox" className="mr-2" />
                <span className="text-sm">Pago libre (no asociado a cuota)</span>
              </label>
            </div>
          )}

          {/* Campo Monto */}
          <div>
            <label className="block text-sm font-medium mb-1">Monto</label>
            <input
              type="number"
              className="w-full border rounded px-3 py-2"
              placeholder="Ej: 350000"
              {...(permissions.isAssistant() && { readOnly: true })} // Auto-llenado para ASIST
            />
            {permissions.isAssistant() && (
              <p className="text-xs text-gray-500 mt-1">
                Monto automático según la cuota seleccionada
              </p>
            )}
          </div>

          {/* Método de Pago */}
          <div>
            <label className="block text-sm font-medium mb-1">Método de Pago</label>
            <select className="w-full border rounded px-3 py-2">
              <option>Transferencia</option>
              <option>Cheque</option>
              <option>Efectivo</option>
              <option>Tarjeta</option>
            </select>
          </div>

          {/* Botones */}
          <div className="flex space-x-2 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 bg-gray-300 text-gray-700 py-2 rounded hover:bg-gray-400"
            >
              Cancelar
            </button>
            <button
              type="submit"
              className="flex-1 bg-blue-500 text-white py-2 rounded hover:bg-blue-600"
            >
              Registrar Pago
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default PaymentActionsComponent;