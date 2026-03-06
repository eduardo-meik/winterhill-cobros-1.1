import React, { useEffect, useState } from 'react';
import { Dialog } from '@headlessui/react';
import { Card } from '../ui/Card';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';
import { StudentMultiSelect } from './StudentMultiSelect';
import { useForm } from 'react-hook-form';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { adminUpsertGuardianIntake, adminSubmitGuardianIntake } from '../../services/guardianIntake';
import { isRutFormatValid, formatRut } from '../../utils/rut';

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

export function GuardianFormModal({ isOpen, onClose, onSuccess, guardian = null }) { // Add guardian prop
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [selectedStudentIds, setSelectedStudentIds] = useState([]);
  const { user } = useAuth();
  const isStaff = user?.profile === 'ADMIN' || user?.profile === 'ASIST';
  const [extendToIntake, setExtendToIntake] = useState(isStaff);
  const [autoLaunchWizard, setAutoLaunchWizard] = useState(isStaff);
  const [autoOpenIntakeEditor, setAutoOpenIntakeEditor] = useState(isStaff);
  const navigate = useNavigate();

  const { register, handleSubmit, formState: { errors }, reset } = useForm({
    defaultValues: guardian ? guardian : initialDefaultValues // Use guardian data if editing
  });

  useEffect(() => { // Reset form when guardian data changes (e.g., when opening modal for different guardians)
    if (guardian) {
      reset(guardian);
    } else {
      reset(initialDefaultValues);
    }
  }, [guardian, reset]);

  useEffect(() => {
    if (!guardian && isStaff) {
      setExtendToIntake(true);
      setAutoLaunchWizard(true);
      setAutoOpenIntakeEditor(true);
    } else {
      setExtendToIntake(false);
      setAutoLaunchWizard(false);
      setAutoOpenIntakeEditor(false);
    }
  }, [isStaff, guardian]);

  const buildIntakePayload = (formValues) => {
    const lastNameRaw = formValues.last_name?.trim() || '';
    const lastParts = lastNameRaw.split(/\s+/).filter(Boolean);
    const paterno = lastParts[0] || lastNameRaw || null;
    const materno = lastParts.slice(1).join(' ') || null;

    // Guardian ↔ intake column mapping for staff-created surveys
    return {
      guardian_first_name: formValues.first_name,
      guardian_last_name_paterno: paterno,
      guardian_last_name_materno: materno,
      guardian_relationship: formValues.relationship_type,
      guardian_rut: formValues.run,
      guardian_address: formValues.address || null,
      guardian_commune: formValues.comuna || null,
      guardian_email: formValues.email || null,
      guardian_phone: formValues.phone || null,
      // Student placeholders to keep the survey in draft until MatriculaWizard completes it
      student_first_names: 'Pendiente',
      student_last_name_paterno: null,
      student_last_name_materno: null,
      student_run: 'PENDIENTE',
      student_course: null,
      status: 'draft'
    };
  };

  const handleOpenIntakeEditor = () => {
    if (!guardian?.id) {
      toast.error('Guarda el apoderado antes de abrir la encuesta completa.');
      return;
    }
    onClose?.();
    navigate(`/apoderado/encuesta?guardianId=${guardian.id}`);
  };

  const onSubmit = async (data) => {
    try {
      setIsSaving(true);
      
      // Check if RUN already exists only if it's a new guardian or if the RUN has changed
      if (!guardian || (guardian && guardian.run !== data.run)) {
        const { data: existingGuardian, error: checkError } = await supabase
          .from('guardians')
          .select('id') // Only select id, no need for full data
          .eq('run', data.run)
          .maybeSingle();

        if (checkError) {
          toast.error('Error al verificar el RUN');
          setIsSaving(false); // Ensure saving state is reset
          return;
        }

        if (existingGuardian) {
          toast.error('Ya existe un apoderado con este RUN');
          setIsSaving(false); // Ensure saving state is reset
          return;
        }
      }

      if (guardian) { // If guardian exists, update it
        const { error: updateError } = await supabase
          .from('guardians')
          .update({
            ...data,
            updated_at: new Date().toISOString()
          })
          .eq('id', guardian.id);
        
        if (updateError) {
          throw updateError;
        }
        toast.success('Apoderado actualizado exitosamente');

      } else { // Otherwise, create a new guardian
        const { data: authUser, error: authError } = await supabase.auth.getUser();
        if (authError) {
          throw authError;
        }
        const ownerId = authUser?.user?.id || user?.id || null;
        if (!ownerId) {
          throw new Error('No se pudo determinar el usuario autenticado para guardar al apoderado.');
        }
        const { data: newGuardian, error: insertError } = await supabase
          .from('guardians')
          .insert([{
            ...data,
            owner_id: ownerId,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }])
          .select()
          .single();

        if (insertError) {
          throw insertError;
        }

        // If there are selected students, create the associations
        if (selectedStudentIds.length > 0 && newGuardian) {
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
            // Do not return early, allow success callback and modal close
          }
        }

        if (isStaff && extendToIntake && newGuardian) {
          const intakePayload = buildIntakePayload(data);
          try {
            await adminUpsertGuardianIntake(newGuardian.id, intakePayload);
            try {
              await adminSubmitGuardianIntake(newGuardian.id);
              await adminUpsertGuardianIntake(newGuardian.id, intakePayload);
              toast.success('Encuesta de matrícula preparada');
            } catch (submitError) {
              console.warn('No se pudo finalizar la encuesta de matrícula', submitError);
              toast('Encuesta creada, pero deberás completarla manualmente.', { icon: '⚠️' });
            }
          } catch (intakeError) {
            console.warn('No se pudo preparar la encuesta de matrícula', intakeError);
            toast('Apoderado creado, pero no se pudo preparar la encuesta de matrícula.', { icon: '⚠️' });
          }
        }
        toast.success('Apoderado registrado exitosamente');

        if (isStaff && autoOpenIntakeEditor && !guardian && newGuardian) {
          navigate(`/apoderado/encuesta?guardianId=${newGuardian.id}`, {
            state: { from: 'guardian-form', staffMode: true }
          });
        } else if (autoLaunchWizard && isStaff && !guardian && newGuardian) {
          const snapshot = {
            id: newGuardian.id,
            first_name: newGuardian.first_name,
            last_name: newGuardian.last_name,
            run: newGuardian.run,
            email: newGuardian.email,
            phone: newGuardian.phone,
            address: newGuardian.address,
            comuna: newGuardian.comuna
          };
          navigate('/matricula', {
            state: {
              guardianId: newGuardian.id,
              guardianSnapshot: snapshot,
              from: 'guardian-form'
            }
          });
        }
      }

      onSuccess?.();
      reset(); // Reset form after successful submission
      setSelectedStudentIds([]);
      onClose();
    } catch (error) {
      console.error('Error:', error);
      toast.error(guardian ? 'Error al actualizar el apoderado' : 'Error al registrar el apoderado');
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
                {guardian ? 'Editar Apoderado' : 'Registrar Apoderado'} {/* Change title based on mode*/}
              </Dialog.Title>
              <button
                onClick={onClose}
                aria-label="Cerrar"
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
                      {(() => {
                        const { onChange, ...rest } = register('run', { 
                          required: !guardian ? 'Este campo es requerido' : false,
                          validate: !guardian ? (value) => isRutFormatValid(value) || 'Formato de RUT inválido' : undefined
                        });
                        return (
                          <input
                            type="text"
                            {...rest}
                            onChange={(e) => {
                              e.target.value = formatRut(e.target.value);
                              onChange(e);
                            }}
                            className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                            disabled={!!guardian} // Disable RUN field if editing an existing guardian
                          />
                        );
                      })()}
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

                  {isStaff && (
                    <div className="col-span-2 space-y-2 p-3 border rounded-lg bg-gray-50 dark:bg-dark-hover">
                      <label className="flex items-center gap-2 text-sm">
                        <input
                          type="checkbox"
                          className="w-4 h-4"
                          checked={extendToIntake}
                          onChange={(e) => setExtendToIntake(e.target.checked)}
                        />
                        Completar encuesta de matrícula al guardar
                      </label>
                      <p className="text-xs text-gray-500">
                        Crea un borrador en <strong>guardian_intake_surveys</strong> usando los datos ingresados. La encuesta permanece en estado MATRICULADO hasta que el equipo termine el proceso.
                      </p>
                      <label className="flex items-center gap-2 text-sm">
                        <input
                          type="checkbox"
                          className="w-4 h-4"
                          checked={autoLaunchWizard}
                          onChange={(e) => setAutoLaunchWizard(e.target.checked)}
                        />
                        Abrir asistente de matrícula al cerrar
                      </label>
                      <p className="text-xs text-gray-500">Redirige al MatriculaWizard en modo asistido con este apoderado preseleccionado.</p>
                      <label className="flex items-center gap-2 text-sm">
                        <input
                          type="checkbox"
                          className="w-4 h-4"
                          checked={autoOpenIntakeEditor}
                          onChange={(e) => setAutoOpenIntakeEditor(e.target.checked)}
                        />
                        Abrir encuesta completa al guardar
                      </label>
                      <p className="text-xs text-gray-500">Lleva al formulario integral para completar todos los campos inmediatamente.</p>
                      <div className="pt-1">
                        <button
                          type="button"
                          onClick={handleOpenIntakeEditor}
                          disabled={!guardian?.id}
                          className="text-sm font-medium text-primary hover:underline disabled:text-gray-400"
                        >
                          Abrir encuesta completa ahora
                        </button>
                        {!guardian?.id && (
                          <p className="text-xs text-gray-500">Guarda el apoderado para habilitar esta acción.</p>
                        )}
                      </div>
                    </div>
                  )}
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
                {isSaving ? 'Guardando...' : guardian ? 'Guardar Cambios' : 'Registrar Apoderado'} {/* Change button text based on mode*/}
              </button>
            </div>
          </Card>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}