import React, { useState } from 'react';
import { Dialog } from '@headlessui/react';
import { format } from 'date-fns';
import { Card } from '../ui/Card';
import { useEffect } from 'react';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

const DetailItem = ({ label, value }) => (
  <div className="space-y-1">
    <dt className="text-sm text-gray-500 dark:text-gray-400">{label}</dt>
    <dd className="text-sm font-medium text-gray-900 dark:text-white">{value}</dd>
  </div>
);

export function PaymentDetailsModal({ payment, onClose, onSuccess }) {
  if (!payment) return null;

  const [guardianInfo, setGuardianInfo] = useState(null);
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({
    student_id: payment.student.id,
    amount: payment.amount,
    payment_date: payment.payment_date,
    payment_method: payment.payment_method || '',
    status: payment.status,
    num_boleta: payment.num_boleta || '',
    mov_bancario: payment.mov_bancario || '',
    notes: payment.notes || ''
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchGuardianInfo();
  }, [payment.student.id]);

  const fetchGuardianInfo = async () => {
    try {
      const { data, error } = await supabase
        .from('student_guardian')
        .select(`
          guardian:guardians (
            id,
            first_name,
            last_name,
            email,
            phone,
            relationship_type
          )
        `)
        .eq('student_id', payment.student.id)
        .single();

      if (error) throw error;
      setGuardianInfo(data.guardian);
    } catch (error) {
      console.error('Error fetching guardian info:', error);
      toast.error('Error al cargar la información del apoderado');
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSave = async () => {
    try {
      // Validate payment_method before sending to database
      const validPaymentMethods = ["CHEQUE", "TRANSFERENCIA", "TARJETA", "DESCUENTO PLANILLA", "EFECTIVO"];
      
      if (formData.payment_method && !validPaymentMethods.includes(formData.payment_method)) {
        toast.error('Método de pago inválido');
        return;
      }
      
      setLoading(true);
      
      const { error } = await supabase
        .from('fee')
        .update({
          // student_id is not updated to prevent data conflicts
          amount: parseFloat(formData.amount),
          payment_date: formData.payment_date,
          payment_method: formData.payment_method || null, // Ensure null if empty
          status: formData.status,
          num_boleta: formData.num_boleta,
          mov_bancario: formData.mov_bancario,
          notes: formData.notes,
          updated_at: new Date().toISOString()
        })
        .eq('id', payment.id);

      if (error) throw error;

      toast.success('Pago actualizado exitosamente');
      onSuccess?.();
      onClose();
    } catch (error) {
      console.error('Error:', error);
      toast.error('Error al actualizar el pago');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    const confirmed = window.confirm('¿Estás seguro de que deseas eliminar este pago? Esta acción no se puede deshacer.');
    if (!confirmed) return;

    try {
      setLoading(true);
      
      const { error } = await supabase
        .from('fee')
        .delete()
        .eq('id', payment.id);

      if (error) throw error;

      toast.success('Pago eliminado exitosamente');
      onSuccess?.();
      onClose();
    } catch (error) {
      console.error('Error:', error);
      toast.error('Error al eliminar el pago');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog
      open={true}
      onClose={onClose}
      className="relative z-50"
    >
      <div className="fixed inset-0 bg-black/20 dark:bg-black/40" aria-hidden="true" />

      <div className="fixed inset-0 flex items-center justify-center p-4">
        {/* Apply flex column layout and max height to the panel */}
        <Dialog.Panel className="w-full max-w-2xl flex flex-col max-h-[90vh]">
          <Card className="flex flex-col flex-1 overflow-hidden"> {/* Ensure Card also flexes */}
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100 dark:border-gray-800 shrink-0">
              <div>
                <Dialog.Title className="text-lg font-semibold text-gray-900 dark:text-white">
                  Detalles del Pago
                </Dialog.Title>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {payment.student.first_name} {payment.student.last_name}
                </p>
              </div>
              <button
                onClick={onClose}
                className="p-2 text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Content - Make this part scrollable */}
            <div className="flex-1 overflow-y-auto p-6"> {/* Changed classes */}
              {isEditing ? (
                <div className="space-y-6"> {/* Form container */}
                  <div className="grid grid-cols-2 gap-6">
                    <div className="col-span-2">
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Estudiante
                      </label>
                      {/* Display current student info instead of searchable dropdown to avoid conflicts */}
                      <div className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white">
                        <div className="flex items-center gap-3">
                          <div>
                            <p className="text-sm font-medium">
                              {payment.student?.whole_name || `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`}
                            </p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">
                              {payment.student?.run} - {payment.student?.cursos?.nom_curso || 'Sin curso asignado'}
                            </p>
                          </div>
                        </div>
                      </div>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        El estudiante no puede ser cambiado durante la edición para evitar conflictos de datos
                      </p>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Monto
                      </label>
                      <input
                        type="number"
                        name="amount"
                        value={formData.amount}
                        onChange={handleChange}
                        step="0.01"
                        min="0"
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Estado
                      </label>
                      <select
                        name="status"
                        value={formData.status}
                        onChange={handleChange}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      >
                        <option value="paid">Pagado</option>
                        <option value="pending">Pendiente</option>
                        <option value="overdue">Vencido</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Fecha de Pago
                      </label>
                      <input
                        type="date"
                        name="payment_date"
                        value={formData.payment_date || ''}
                        onChange={handleChange}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Método de Pago
                      </label>
                      <select
                        name="payment_method"
                        value={formData.payment_method}
                        onChange={handleChange}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      >
                        <option value="">Seleccionar...</option>
                        <option value="CHEQUE">Cheque</option>
                        <option value="TRANSFERENCIA">Transferencia</option>
                        <option value="TARJETA">Tarjeta</option>
                        <option value="DESCUENTO PLANILLA">Descuento Planilla</option>
                        <option value="EFECTIVO">Efectivo</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Folio Boleta
                      </label>
                      <input
                        type="text"
                        name="num_boleta"
                        value={formData.num_boleta}
                        onChange={handleChange}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Movimiento Bancario
                      </label>
                      <input
                        type="text"
                        name="mov_bancario"
                        value={formData.mov_bancario}
                        onChange={handleChange}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                    </div>

                    <div className="col-span-2">
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Notas
                      </label>
                      <textarea
                        name="notes"
                        value={formData.notes}
                        onChange={handleChange}
                        rows={3}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                    </div>
                  </div>
                </div>
              ) : (
                <div className="space-y-6"> {/* Details container */}
                   {/* Student Info */}
                   <div className="col-span-2 p-4 bg-gray-50 dark:bg-dark-hover rounded-lg">
                     <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-3">
                       Información del Estudiante
                     </h3>
                     <div className="grid grid-cols-2 gap-4">
                       <DetailItem 
                         label="Nombre Completo" 
                         value={`${payment.student.first_name} ${payment.student.last_name}`}
                       />
                       <DetailItem 
                         label="Curso" 
                         value={payment.student?.cursos?.nom_curso || 'No asignado'}
                       />
                     </div>
                   </div>
                   {/* Guardian Info */}
                   {guardianInfo && (
                     <div className="col-span-2 p-4 bg-gray-50 dark:bg-dark-hover rounded-lg">
                       <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-3">
                         Información del Apoderado
                       </h3>
                       <div className="grid grid-cols-2 gap-4">
                         <DetailItem 
                           label="Nombre Completo" 
                           value={`${guardianInfo.first_name} ${guardianInfo.last_name}`}
                         />
                         <DetailItem 
                           label="Tipo de Relación" 
                           value={guardianInfo.relationship_type}
                         />
                         <DetailItem 
                           label="Email" 
                           value={guardianInfo.email || 'No especificado'}
                         />
                         <DetailItem 
                           label="Teléfono" 
                           value={guardianInfo.phone || 'No especificado'}
                         />
                       </div>
                     </div>
                   )}

                   {/* Payment Info */}
                   <div className="col-span-2 p-4 bg-gray-50 dark:bg-dark-hover rounded-lg">
                     <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-3">
                       Información del Pago
                     </h3>
                     <div className="grid grid-cols-2 gap-4">
                   <DetailItem 
                     label="Monto" 
                     value={`$${payment.amount.toLocaleString()}`}
                   />
                   <DetailItem 
                     label="Cuota número" 
                     value={payment.numero_cuota || 'No especificado'}
                   />
                   <DetailItem 
                     label="Porcentaje de Beca" 
                     value={payment.porcentaje_beca ? `${payment.porcentaje_beca}%` : 'No especificado'}
                   />
                   <DetailItem 
                     label="Institución Financiera" 
                     value={payment.inst_financiera || 'No especificado'}
                   />
                   <DetailItem 
                     label="Estado" 
                     value={payment.status === 'paid' ? 'Pagado' : payment.status === 'pending' ? 'Pendiente' : 'Vencido'}
                   />
                   <DetailItem 
                     label="Fecha de Vencimiento" 
                     value={format(new Date(payment.due_date), 'dd/MM/yyyy')}
                   />
                   <DetailItem 
                     label="Método de Pago" 
                     value={payment.payment_method || 'No especificado'}
                   />
                   <DetailItem 
                     label="Folio Boleta" 
                     value={payment.num_boleta || 'No especificado'}
                   />
                   <DetailItem 
                     label="Movimiento Bancario" 
                     value={payment.mov_bancario || 'No especificado'}
                   />
                   <DetailItem 
                     label="Curso del Estudiante" 
                     value={payment.student?.cursos?.nom_curso || 'No asignado'}
                   />
                   {payment.payment_date && (
                     <DetailItem 
                       label="Fecha de Pago" 
                       value={format(new Date(payment.payment_date), 'dd/MM/yyyy')}
                     />
                   )}
                   {payment.notes && (
                     <DetailItem 
                       label="Notas" 
                       value={payment.notes}
                     />
                   )}
                     </div>
                   </div>
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-100 dark:border-gray-800 shrink-0">
              {isEditing ? (
                <>
                  <button
                    type="button"
                    onClick={() => setIsEditing(false)}
                    disabled={loading}
                    className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-lg transition-colors"
                  >
                    Cancelar
                  </button>
                  <button
                    type="button"
                    onClick={handleSave}
                    disabled={loading}
                    className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-light rounded-lg transition-colors disabled:opacity-50"
                  >
                    {loading ? 'Guardando...' : 'Guardar Cambios'}
                  </button>
                </>
              ) : (
                <>
                  <button
                    onClick={handleDelete}
                    className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
                  >
                    Eliminar
                  </button>
                  <button
                    onClick={onClose}
                    className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-lg transition-colors"
                  >
                    Cerrar
                  </button>
                  <button
                    onClick={() => setIsEditing(true)}
                    className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-light rounded-lg transition-colors"
                  >
                    Editar Pago
                  </button>
                </>
              )}
            </div>
          </Card>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}