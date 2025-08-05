//src/components/payments/RegisterPaymentModal.jsx
import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import { useForm } from 'react-hook-form';
import { Card } from '../ui/Card';
import { StudentSelect } from './StudentSelect';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

const defaultValues = {
  student_id: '',
  amount: '',
  payment_date: '',
  payment_method: '',
  num_boleta: '',
  mov_bancario: '',
  notes: '',
  numero_cuota: '',
  is_free_payment: false
};

export function RegisterPaymentModal({ isOpen, onClose, onSuccess }) {
  const { 
    register, 
    handleSubmit, 
    formState: { errors, isSubmitting }, 
    reset,
    setValue,
    watch,
    control 
  } = useForm({
    defaultValues
  });

  const selectedStudentId = watch('student_id');
  const selectedAmount = watch('amount');
  const selectedNumeroCuota = watch('numero_cuota');
  const isFreePayment = watch('is_free_payment');

  // State for cuota management
  const [availableCuotas, setAvailableCuotas] = useState([]);
  const [selectedCuotaInfo, setSelectedCuotaInfo] = useState(null);
  const [validationMessage, setValidationMessage] = useState('');
  const [isLoadingCuotas, setIsLoadingCuotas] = useState(false);

  // Fetch available cuotas when student changes
  useEffect(() => {
    if (selectedStudentId) {
      fetchAvailableCuotas();
    } else {
      setAvailableCuotas([]);
      setSelectedCuotaInfo(null);
      setValidationMessage('');
    }
  }, [selectedStudentId]);

  // Validate cuota selection and amount
  useEffect(() => {
    if (selectedNumeroCuota && !isFreePayment) {
      validateCuotaSelection();
    } else {
      setValidationMessage('');
      setSelectedCuotaInfo(null);
    }
  }, [selectedNumeroCuota, selectedAmount, isFreePayment]);

  const fetchAvailableCuotas = async () => {
    try {
      setIsLoadingCuotas(true);
      
      // Fetch existing fee records for this student to identify cuotas
      const { data: fees, error } = await supabase
        .from('fee')
        .select('numero_cuota, amount, status, due_date, payment_date')
        .eq('student_id', selectedStudentId)
        .order('numero_cuota', { ascending: true });

      if (error) throw error;

      // Process fees to identify available, paid, and pending cuotas
      const cuotaMap = new Map();
      fees?.forEach(fee => {
        if (fee.numero_cuota) {
          const existing = cuotaMap.get(fee.numero_cuota);
          if (!existing || (fee.status === 'paid' && existing.status !== 'paid')) {
            cuotaMap.set(fee.numero_cuota, fee);
          }
        }
      });

      const processedCuotas = Array.from(cuotaMap.values()).map(fee => ({
        numero: fee.numero_cuota,
        amount: fee.amount,
        status: fee.status,
        due_date: fee.due_date,
        payment_date: fee.payment_date,
        isPaid: fee.status === 'paid',
        isPending: fee.status === 'pending' || fee.status === 'overdue'
      }));

      setAvailableCuotas(processedCuotas);
    } catch (error) {
      console.error('Error fetching cuotas:', error);
      toast.error('Error al cargar información de cuotas');
    } finally {
      setIsLoadingCuotas(false);
    }
  };

  // Auto-fill amount when cuota is selected
  useEffect(() => {
    if (selectedNumeroCuota && !isFreePayment && selectedCuotaInfo) {
      setValue('amount', selectedCuotaInfo.amount);
    }
  }, [selectedNumeroCuota, selectedCuotaInfo, isFreePayment, setValue]);

  const validateCuotaSelection = () => {
    if (!selectedNumeroCuota || isFreePayment) {
      setValidationMessage('');
      setSelectedCuotaInfo(null);
      return;
    }

    const cuotaNumber = parseInt(selectedNumeroCuota);
    const selectedCuota = availableCuotas.find(c => c.numero === cuotaNumber);

    if (!selectedCuota) {
      setValidationMessage('⚠️ Esta cuota no existe en el sistema para este estudiante');
      setSelectedCuotaInfo(null);
      return;
    }

    setSelectedCuotaInfo(selectedCuota);

    if (selectedCuota.isPaid) {
      setValidationMessage('❌ Esta cuota ya está pagada');
      return;
    }

    if (selectedAmount && parseFloat(selectedAmount) !== selectedCuota.amount) {
      setValidationMessage(`⚠️ El monto no coincide con la cuota (esperado: $${selectedCuota.amount.toLocaleString()})`);
      return;
    }

    if (selectedAmount && parseFloat(selectedAmount) === selectedCuota.amount) {
      setValidationMessage('✅ Cuota válida - monto correcto');
      return;
    }

    setValidationMessage('ℹ️ Cuota disponible para pago');
  };

  const onSubmit = async (data) => {
    try {
      // Validation before submission
      if (!isFreePayment) {
        if (!data.numero_cuota) {
          toast.error('Debe seleccionar una cuota o marcar como pago libre');
          return;
        }

        const cuotaNumber = parseInt(data.numero_cuota);
        const selectedCuota = availableCuotas.find(c => c.numero === cuotaNumber);

        if (!selectedCuota) {
          toast.error('La cuota seleccionada no es válida');
          return;
        }

        if (selectedCuota.isPaid) {
          toast.error('Esta cuota ya está pagada');
          return;
        }

        if (parseFloat(data.amount) !== selectedCuota.amount) {
          const proceed = window.confirm(
            `El monto ingresado ($${parseFloat(data.amount).toLocaleString()}) no coincide con el monto esperado de la cuota ($${selectedCuota.amount.toLocaleString()}). ¿Desea continuar?`
          );
          if (!proceed) return;
        }
      }

      const paymentData = {
        amount: parseFloat(data.amount),
        payment_date: data.payment_date,
        payment_method: data.payment_method,
        status: 'paid',
        student_id: data.student_id,
        notes: data.notes,
        num_boleta: data.num_boleta,
        mov_bancario: data.mov_bancario,
        owner_id: (await supabase.auth.getUser()).data.user.id
      };

      // Add numero_cuota if not a free payment
      if (!isFreePayment && data.numero_cuota) {
        paymentData.numero_cuota = parseInt(data.numero_cuota);
      }

      // Add free payment indicator in notes if applicable
      if (isFreePayment) {
        paymentData.notes = `[PAGO LIBRE] ${data.notes || ''}`.trim();
      }

      const { error } = await supabase
        .from('fee')
        .insert([paymentData]);

      if (error) throw error;

      toast.success('Pago registrado exitosamente');
      reset();
      onSuccess();
      onClose();
    } catch (error) {
      console.error('Error:', error);
      toast.error('Error al registrar el pago');
    }
  };

  const handleConfirm = async (data) => {
    const confirmed = window.confirm('¿Estás seguro de que deseas registrar este pago?');
    if (confirmed) {
      await onSubmit(data);
    }
  };

  return (
    <Dialog
      open={isOpen}
      onClose={onClose}
      className="relative z-50"
    >
      <div className="fixed inset-0 bg-black/20 dark:bg-black/40" aria-hidden="true" />

      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="w-full max-w-2xl flex flex-col max-h-[90vh]">
          <Card className="flex flex-col flex-1 overflow-hidden">
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100 dark:border-gray-800 shrink-0">
              <Dialog.Title className="text-lg font-semibold text-gray-900 dark:text-white">
                Registrar Pago
              </Dialog.Title>
              <button
                onClick={onClose}
                className="p-2 text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
                aria-label="Cerrar"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Form - Now wraps the content AND the footer */}
            <form onSubmit={handleSubmit(handleConfirm)} className="flex flex-col flex-1 overflow-hidden"> {/* Added flex flex-col flex-1 overflow-hidden */}
              {/* Scrollable Content Area */}
              <div className="flex-1 overflow-y-auto p-6 space-y-6">
                <div className="grid grid-cols-2 gap-6">
                  {/* --- form fields (StudentSelect, Monto, Fecha, etc.) --- */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Estudiante *
                    </label>
                    <StudentSelect
                      value={selectedStudentId}
                      onChange={(value) => {
                        // --- Add validation registration ---
                        setValue('student_id', value, { shouldValidate: true });
                        // --- End validation registration ---
                      }}
                      error={errors.student_id?.message}
                    />
                    {/* --- Add error display --- */}
                    {errors.student_id && (
                       <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.student_id.message}</p>
                    )}
                    {/* --- End error display --- */}
                  </div>

                  {/* Free Payment Checkbox */}
                  <div className="col-span-2">
                    <label className="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        {...register('is_free_payment')}
                        className="w-4 h-4 text-primary bg-gray-100 border-gray-300 rounded focus:ring-primary focus:ring-2"
                      />
                      <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                        Pago libre (no asociado a cuota específica)
                      </span>
                    </label>
                    <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                      Marque esta opción para pagos de años anteriores o abonos sin cuota específica
                    </p>
                  </div>

                  {/* Cuota Selection - Only show if not free payment and student is selected */}
                  {!isFreePayment && selectedStudentId && (
                    <div className="col-span-2">
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Cuota *
                      </label>
                      {isLoadingCuotas ? (
                        <div className="flex items-center justify-center py-4">
                          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary"></div>
                          <span className="ml-2 text-sm text-gray-500">Cargando cuotas...</span>
                        </div>
                      ) : availableCuotas.length > 0 ? (
                        <>
                          <select
                            {...register('numero_cuota', { 
                              required: !isFreePayment ? 'Debe seleccionar una cuota o marcar como pago libre' : false
                            })}
                            className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                          >
                            <option value="">Seleccionar cuota...</option>
                            {availableCuotas.map((cuota) => (
                              <option 
                                key={cuota.numero} 
                                value={cuota.numero}
                                disabled={cuota.isPaid}
                              >
                                Cuota {cuota.numero} - ${cuota.amount.toLocaleString()} 
                                {cuota.isPaid ? ' (PAGADA)' : ''} 
                                {cuota.isPending ? ' (PENDIENTE)' : ''}
                              </option>
                            ))}
                          </select>
                          
                          {/* Cuota Information Display */}
                          {selectedCuotaInfo && (
                            <div className="mt-2 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                              <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                Información de la Cuota {selectedCuotaInfo.numero}
                              </h4>
                              <div className="text-sm text-gray-600 dark:text-gray-400">
                                <p>Monto: ${selectedCuotaInfo.amount.toLocaleString()}</p>
                                <p>Estado: {selectedCuotaInfo.isPaid ? 'Pagada' : 'Pendiente'}</p>
                                {selectedCuotaInfo.due_date && (
                                  <p>Vencimiento: {new Date(selectedCuotaInfo.due_date).toLocaleDateString()}</p>
                                )}
                                {selectedCuotaInfo.payment_date && (
                                  <p>Fecha de pago: {new Date(selectedCuotaInfo.payment_date).toLocaleDateString()}</p>
                                )}
                              </div>
                            </div>
                          )}
                          
                          {/* Validation Message */}
                          {validationMessage && (
                            <div className={`mt-2 p-2 rounded-lg text-sm ${
                              validationMessage.includes('✅') 
                                ? 'bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-300'
                                : validationMessage.includes('❌')
                                ? 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-300'
                                : 'bg-yellow-50 dark:bg-yellow-900/20 text-yellow-700 dark:text-yellow-300'
                            }`}>
                              {validationMessage}
                            </div>
                          )}
                        </>
                      ) : (
                        <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
                          <p className="text-sm text-yellow-700 dark:text-yellow-300">
                            No se encontraron cuotas para este estudiante. Puede marcar como "pago libre" para registrar el pago.
                          </p>
                        </div>
                      )}
                      
                      {errors.numero_cuota && (
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.numero_cuota.message}</p>
                      )}
                    </div>
                  )}

                  {/* Manual Cuota Number Input for Free Payments */}
                  {isFreePayment && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Número de Cuota (Opcional)
                      </label>
                      <input
                        type="number"
                        min="1"
                        {...register('numero_cuota')}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                        placeholder="Ej: 1, 2, 3..."
                      />
                      <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Solo si desea asociar el pago a un número de cuota específico
                      </p>
                    </div>
                  )}

                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Monto *
                      {selectedCuotaInfo && !isFreePayment && (
                        <span className="text-xs text-green-600 dark:text-green-400 ml-2">
                          (Auto-completado desde cuota)
                        </span>
                      )}
                    </label>
                    <input
                      type="number"
                      step="0.01"
                      {...register('amount', { 
                        required: 'Este campo es requerido',
                        valueAsNumber: true, // Ensure value is treated as number
                        min: { value: 0.01, message: 'El monto debe ser mayor a 0' },
                        // --- Add max validation ---
                        max: { value: 5000000, message: 'El monto máximo es 99,999,999.99' }
                        // --- End max validation ---
                      })}
                      className={`w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary ${
                        selectedCuotaInfo && !isFreePayment ? 'bg-green-50 dark:bg-green-900/20' : ''
                      }`}
                      placeholder={selectedCuotaInfo && !isFreePayment ? `Monto sugerido: $${selectedCuotaInfo.amount.toLocaleString()}` : 'Ingrese el monto'}
                    />
                    {/* This part correctly displays the error message */}
                    {errors.amount && (
                      <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.amount.message}</p>
                    )}
                    {selectedCuotaInfo && !isFreePayment && (
                      <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Puede modificar el monto si es necesario
                      </p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Fecha de Pago *
                    </label>
                    <input
                      type="date"
                      {...register('payment_date', { required: 'Este campo es requerido' })}
                      className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    />
                    {errors.payment_date && (
                      <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.payment_date.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Método de Pago *
                    </label>
                    <select
                      {...register('payment_method', { 
                        required: 'Este campo es requerido' 
                      })}
                      className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    >
                      <option value="">Seleccionar...</option>
                      <option value="CHEQUE">Cheque</option>
                      <option value="TRANSFERENCIA">Transferencia</option>
                      <option value="TARJETA">Tarjeta</option>
                      <option value="DESCUENTO PLANILLA">Descuento Planilla</option>
                      <option value="EFECTIVO">Efectivo</option>
                    </select>
                    {errors.payment_method && (
                      <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.payment_method.message}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Folio Boleta
                    </label>
                    <input
                      type="text"
                      {...register('num_boleta')}
                      className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Movimiento Bancario
                    </label>
                    <input
                      type="text"
                      {...register('mov_bancario')}
                      className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    />
                  </div>

                  <div className="col-span-2">
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Notas
                    </label>
                    <textarea
                      {...register('notes')}
                      rows={3}
                      className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    />
                  </div>
                </div>
              </div>
              {/* End Scrollable Content Area */}

              {/* Footer - Moved inside the form */}
              <div className="flex justify-end gap-3 p-6 border-t border-gray-100 dark:border-gray-800 shrink-0">
                <button
                  type="button" // Keep as button
                  onClick={onClose}
                  className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-lg transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit" // This will now trigger the form's onSubmit
                  disabled={isSubmitting}
                  className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-light rounded-lg transition-colors flex items-center gap-2 disabled:opacity-50"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 256 256">
                    <path d="M224,48H32A16,16,0,0,0,16,64V192a16,16,0,0,0,16,16H224a16,16,0,0,0,16-16V64A16,16,0,0,0,224,48Zm0,144H32V64H224V192ZM64,104a8,8,0,0,1,8-8H96a8,8,0,0,1,0,16H72A8,8,0,0,1,64,104Zm128,48a8,8,0,0,1-8,8H72a8,8,0,0,1,0-16H184A8,8,0,0,1,192,152Z" />
                  </svg>
                  {isSubmitting ? 'Registrando...' : 'Registrar Pago'}
                </button>
              </div>
              {/* End Footer */}
            </form>
            {/* End Form */}

          </Card>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}