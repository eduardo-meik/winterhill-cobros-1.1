//src/components/payments/RegisterPaymentModal.jsx
import React from 'react';
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
  notes: ''
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

  const onSubmit = async (data) => {
    try {
      const { error } = await supabase
        .from('fee')
        .insert([{
          amount: parseFloat(data.amount),
          payment_date: data.payment_date,
          payment_method: data.payment_method,
          status: 'paid',
          student_id: data.student_id,
          notes: data.notes,
          num_boleta: data.num_boleta,
          mov_bancario: data.mov_bancario,
          owner_id: (await supabase.auth.getUser()).data.user.id
        }]);

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

                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Monto *
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
                      className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    />
                    {/* This part correctly displays the error message */}
                    {errors.amount && (
                      <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.amount.message}</p>
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