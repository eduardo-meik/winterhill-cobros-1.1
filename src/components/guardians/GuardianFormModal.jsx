import React, { useEffect, useState, useCallback } from 'react';
import { Dialog } from '@headlessui/react';
import { Card } from '../ui/Card';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';
import { StudentMultiSelect } from './StudentMultiSelect';
import { useForm } from 'react-hook-form';

// Default values for a new guardian
const initialDefaultValues = {
  first_name: '',
  last_name: '',
  run: '',
  email: '',
  phone: '',
  address: '',
  comuna: '',
  relationship_type: '',
};

export function GuardianFormModal({ isOpen, onClose, onSuccess }) {
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [selectedStudentIds, setSelectedStudentIds] = useState([]);

  const { register, handleSubmit, formState: { errors }, reset } = useForm({
    defaultValues: initialDefaultValues
  });

  const onSubmit = async (data) => {
    try {
      setIsSaving(true);
      
      // Check if RUN already exists using maybeSingle() instead of single()
      const { data: existingGuardian, error: checkError } = await supabase
        .from('guardians')
        .select('*')
        .eq('run', data.run)
        .maybeSingle();

      if (checkError) {
        console.error('Error checking for existing guardian:', checkError);
        toast.error('Error al verificar el RUN');
        return;
      }

      if (existingGuardian) {
        toast.error('Ya existe un apoderado con este RUN');
        return;
      }

      // Create new guardian
      const { data: newGuardian, error: insertError } = await supabase
        .from('guardians')
        .insert([{
          ...data,
          owner_id: (await supabase.auth.getUser()).data.user.id,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }])
        .select()
        .single();

      if (insertError) {
        console.error('Error creating guardian:', insertError);
        throw insertError;
      }

      // If there are selected students, create the associations
      if (selectedStudentIds.length > 0) {
        const { error: associationError } = await supabase
          .from('student_guardian')
          .insert(
            selectedStudentIds.map(studentId => ({
              student_id: studentId,
              guardian_id: newGuardian.id
            }))
          );

        if (associationError) {
          console.error('Error creating student associations:', associationError);
          toast.error('Apoderado creado pero hubo un error al asociar estudiantes');
          onSuccess?.();
          reset();
          onClose();
          return;
        }
      }

      toast.success('Apoderado registrado exitosamente');
      onSuccess?.();
      reset();
      onClose();
    } catch (error) {
      console.error('Error:', error);
      toast.error('Error al registrar el apoderado');
    } finally {
      setIsSaving(false);
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
            <div className="flex items-center justify-between p-6 border-b border-gray-100 dark:border-gray-800 shrink-0">
              <Dialog.Title className="text-lg font-semibold text-gray-900 dark:text-white">
                Registrar Apoderado
              </Dialog.Title>
              <button
                onClick={onClose}
                className="p-2 text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Content */}
            <form onSubmit={handleSubmit(onSubmit)} className="flex-1 overflow-y-auto p-6">
                  <div className="grid grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Nombres *
                      </label>
                      <input
                        type="text"
                        {...register('first_name', { 
                          required: 'Este campo es requerido',
                          pattern: {
                            value: /^[A-Za-zÀ-ÿ\s]+$/,
                            message: 'Solo se permiten letras'
                          }
                        })}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                      {errors.first_name && (
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.first_name.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Apellidos *
                      </label>
                      <input
                        type="text"
                        {...register('last_name', { 
                          required: 'Este campo es requerido',
                          pattern: {
                            value: /^[A-Za-zÀ-ÿ\s]+$/,
                            message: 'Solo se permiten letras'
                          }
                        })}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                      {errors.last_name && (
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.last_name.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        RUT *
                      </label>
                      <input
                        type="text"
                        {...register('run', { 
                          required: 'Este campo es requerido',
                          pattern: {
                            value: /^(\d{1,3}(?:\.\d{3})*)\-?([\dkK])$/,
                            message: 'Formato de RUT inválido'
                          }
                        })}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                      {errors.run && (
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.run.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Teléfono *
                      </label>
                      <input
                        type="tel"
                        {...register('phone', { 
                          required: 'Este campo es requerido',
                          pattern: {
                            value: /^[0-9+\-\s()]+$/,
                            message: 'Formato de teléfono inválido'
                          }
                        })}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                      {errors.phone && (
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.phone.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Email *
                      </label>
                      <input
                        type="email"
                        {...register('email', {
                          required: 'Este campo es requerido',
                          pattern: {
                            value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                            message: 'Email inválido'
                          }
                        })}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                      {errors.email && (
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.email.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Dirección
                      </label>
                      <input
                        type="text"
                        {...register('address')}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Comuna
                      </label>
                      <input
                        type="text"
                        {...register('comuna')}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Tipo de Relación *
                      </label>
                      <select
                        {...register('relationship_type', { required: 'Este campo es requerido' })}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      >
                        <option value="">Seleccionar tipo</option>
                        <option value="PADRE">PADRE</option>
                        <option value="MADRE">MADRE</option>
                        <option value="TUTOR">TUTOR</option>
                      </select>
                      {errors.relationship_type && (
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.relationship_type.message}</p>
                      )}
                    </div>

                    <div className="col-span-2">
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Estudiantes Asociados (Opcional)
                      </label>
                      <StudentMultiSelect
                        selectedIds={selectedStudentIds}
                        onChange={setSelectedStudentIds}
                      />
                    </div>
                  </div>
            </form>

            {/* Footer */}
            <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-100 dark:border-gray-800 shrink-0">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-lg transition-colors"
              >
                Cancelar
              </button>
              <button
                type="submit"
                onClick={handleSubmit(onSubmit)}
                disabled={isSaving}
                className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-light rounded-lg transition-colors disabled:opacity-50"
              >
                {isSaving ? 'Guardando...' : 'Registrar Apoderado'}
              </button>
            </div>
          </Card>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}