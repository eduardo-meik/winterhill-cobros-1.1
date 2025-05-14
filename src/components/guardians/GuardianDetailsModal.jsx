import React, { useEffect, useState, useCallback } from 'react';
import { Dialog } from '@headlessui/react';
import { Card } from '../ui/Card';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';
import { StudentMultiSelect } from './StudentMultiSelect';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { StudentDetailsModal } from '../students/StudentDetailsModal'; // Add this import at the top

const DetailItem = ({ label, value }) => (
  <div className="space-y-1">
    <dt className="text-sm text-gray-500 dark:text-gray-400">{label}</dt>
    <dd className="text-sm font-medium text-gray-900 dark:text-white">{value}</dd>
  </div>
);

export function GuardianDetailsModal({ guardian, onClose, onSuccess }) {
  const [associatedStudents, setAssociatedStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [selectedStudentIds, setSelectedStudentIds] = useState([]);
  const [isDeleting, setIsDeleting] = useState(false);
  const [viewingStudent, setViewingStudent] = useState(null); // Add state for viewing student
  const navigate = useNavigate();

  const { register, handleSubmit, formState: { errors }, reset } = useForm({
    defaultValues: guardian
  });

  useEffect(() => {
    if (guardian?.id) { // Ensure guardian.id exists before fetching
      fetchAssociatedStudents();
    }
  }, [guardian?.id]); // Add guardian.id as a dependency

  const handleCancel = () => {
    setIsEditing(false);
    reset(guardian);
  };

  const onSubmit = async (data) => {
    try {
      setIsSaving(true);
      const { error } = await supabase
        .from('guardians')
        .update({
          first_name: data.first_name,
          last_name: data.last_name,
          run: data.run, // Add this line to update the RUT
          email: data.email,
          phone: data.phone,
          address: data.address,
          comuna: data.comuna,
          relationship_type: data.relationship_type,
          updated_at: new Date().toISOString()
        })
        .eq('id', guardian.id);

      if (error) throw error;

      // Update student associations - first check current associations
      const { data: existingAssociations, error: fetchError } = await supabase
        .from('student_guardian')
        .select('student_id')
        .eq('guardian_id', guardian.id);
        
      if (fetchError) throw fetchError;
      
      const existingStudentIds = existingAssociations.map(a => a.student_id);
      const studentIdsToRemove = existingStudentIds.filter(id => !selectedStudentIds.includes(id));
      const studentIdsToAdd = selectedStudentIds.filter(id => !existingStudentIds.includes(id));
      
      // Remove associations that are no longer needed
      if (studentIdsToRemove.length > 0) {
        const { error: deleteError } = await supabase
          .from('student_guardian')
          .delete()
          .eq('guardian_id', guardian.id)
          .in('student_id', studentIdsToRemove);

        if (deleteError) {
          console.error('Error removing student associations:', deleteError);
          toast.error('Error al actualizar algunas asociaciones de estudiantes');
        }
      }
      
      // Add new associations
      if (studentIdsToAdd.length > 0) {
        const { error: insertError } = await supabase
          .from('student_guardian')
          .insert(
            studentIdsToAdd.map(studentId => ({
              student_id: studentId,
              guardian_id: guardian.id
            }))
          );

        if (insertError) {
          console.error('Error adding student associations:', insertError);
          toast.error('Error al añadir algunas asociaciones de estudiantes');
          // Continue with the update process even if this fails
        }
      }

      toast.success('Apoderado actualizado exitosamente');
      setIsEditing(false);
      fetchAssociatedStudents(); // Refresh the student list
      onSuccess?.(); // Notify parent component of the update
    } catch (error) {
      console.error('Error:', error);
      toast.error('Error al actualizar el apoderado');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    const confirmed = window.confirm(`¿Estás seguro de que deseas eliminar al apoderado ${guardian.first_name} ${guardian.last_name}?`);
    if (!confirmed) return;

    try {
      setIsDeleting(true);
      const { error } = await supabase
        .from('guardians')
        .delete()
        .eq('id', guardian.id);

      if (error) throw error;

      toast.success('Apoderado eliminado exitosamente');
      onSuccess?.();
      onClose();
    } catch (error) {
      console.error('Error:', error);
      toast.error('Error al eliminar el apoderado');
    } finally {
      setIsDeleting(false);
    }
  };

  const fetchAssociatedStudents = async () => {
    if (!guardian?.id) return;

    try {
      setLoading(true);
      
      // First, get the student IDs
      const { data: associations, error: associationsError } = await supabase
        .from('student_guardian')
        .select('student_id')
        .eq('guardian_id', guardian.id);

      if (associationsError) throw associationsError;
      
      if (!associations || associations.length === 0) {
        setAssociatedStudents([]);
        setSelectedStudentIds([]);
        setLoading(false);
        return;
      }

      const studentIds = associations.map(a => a.student_id);
      
      // Then get the students data
      const { data: students, error: studentsError } = await supabase
        .from('students')
        .select('id, whole_name, first_name, apellido_paterno, apellido_materno, curso')
        .in('id', studentIds);
        
      if (studentsError) throw studentsError;
      
      // Get curso data in a separate query
      const cursoIds = Array.from(new Set(students.filter(s => s.curso).map(s => s.curso)));
      
      let cursosMap = {};
      if (cursoIds.length > 0) {
        const { data: cursos, error: cursosError } = await supabase
          .from('cursos')
          .select('id, nom_curso')
          .in('id', cursoIds);
          
        if (cursosError) throw cursosError;
        
        // Create a map for easier lookup
        cursosMap = (cursos || []).reduce((map, curso) => {
          map[curso.id] = curso;
          return map;
        }, {});
      }
      
      // Join the data manually
      const processedStudents = students.map(student => {
        const curso = student.curso ? cursosMap[student.curso] : null;
        return {
          id: student.id,
          whole_name: student.whole_name || `${student.first_name || ''} ${student.apellido_paterno || ''} ${student.apellido_materno || ''}`.trim(),
          nom_curso: curso ? curso.nom_curso : 'Sin curso asignado'
        };
      });
      
      setAssociatedStudents(processedStudents);
      setSelectedStudentIds(studentIds);
    } catch (error) {
      console.error('Error fetching associated students:', error);
      toast.error('Error al cargar los estudiantes asociados');
    } finally {
      setLoading(false);
    }
  };

  if (!guardian) return null;

  return (
    <Dialog
      open={true}
      onClose={onClose}
      className="relative z-50"
    >
      <div className="fixed inset-0 bg-black/20 dark:bg-black/40" aria-hidden="true" />

      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="w-full max-w-2xl flex flex-col max-h-[90vh]">
          <Card className="flex flex-col flex-1 overflow-hidden">
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100 dark:border-gray-800 shrink-0">
              <div>
                <Dialog.Title className="text-lg font-semibold text-gray-900 dark:text-white">
                  {guardian.first_name} {guardian.last_name}
                </Dialog.Title>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {guardian.relationship_type} • RUT: {guardian.run || 'No especificado'}
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

            {/* Content */}
            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              {isEditing ? (
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
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
                        Estudiantes Asociados
                      </label>
                      <StudentMultiSelect
                        selectedIds={selectedStudentIds}
                        onChange={setSelectedStudentIds}
                      />
                    </div>
                  </div>
                </form>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-6">
                    <DetailItem 
                      label="RUT" 
                      value={guardian.run || 'No especificado'}
                    />
                    <DetailItem 
                      label="Email" 
                      value={guardian.email || 'No especificado'}
                    />
                    <DetailItem 
                      label="Teléfono" 
                      value={guardian.phone || 'No especificado'}
                    />
                    <DetailItem 
                      label="Dirección" 
                      value={guardian.address || 'No especificada'}
                    />
                    <DetailItem 
                      label="Comuna" 
                      value={guardian.comuna || 'No especificada'}
                    />
                    <DetailItem 
                      label="Tipo de Relación" 
                      value={guardian.relationship_type || 'No especificado'}
                    />
                  </div>
                  {/* Associated Students Section */}
                  <div className="mt-8">
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-4">
                      Estudiantes Asociados
                    </h3>
                    {loading ? (
                      <div className="flex items-center justify-center py-4">
                        <div className="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
                      </div>
                    ) : associatedStudents.length > 0 ? (
                      <div className="space-y-3">
                        {associatedStudents.map((student) => (
                          <div
                            key={student.id}
                            className="flex items-center justify-between p-4 rounded-lg bg-gray-50 dark:bg-dark-hover"
                          >
                            <div>
                              <p className="text-sm font-medium text-gray-900 dark:text-white">
                                {student.whole_name}
                              </p>
                              <p className="text-sm text-gray-500 dark:text-gray-400">
                                {student.nom_curso}
                              </p>
                            </div>
                            <button
                              onClick={() => setViewingStudent(student)} // Open student details modal
                              className="p-2 text-primary hover:text-primary-dark dark:hover:text-primary-light transition-colors rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
                              aria-label="Ver detalles del estudiante"
                            >
                              <svg 
                                xmlns="http://www.w3.org/2000/svg" 
                                width="20" 
                                height="20" 
                                viewBox="0 0 24 24" 
                                fill="none" 
                                stroke="currentColor" 
                                strokeWidth="2" 
                                strokeLinecap="round" 
                                strokeLinejoin="round"
                              >
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                <circle cx="12" cy="12" r="3"></circle>
                              </svg>
                            </button>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="text-sm text-gray-500 dark:text-gray-400">No hay estudiantes asociados.</p>
                    )}
                  </div>
                </>
              )}
            </div>

            {/* Footer */}
            <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-100 dark:border-gray-800 shrink-0">
              {isEditing ? (
                <>
                  <button
                    type="button"
                    onClick={handleCancel}
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
                    {isSaving ? 'Guardando...' : 'Guardar Cambios'}
                  </button>
                </>
              ) : (
                <>
                  <button
                    onClick={handleDelete} 
                    disabled={isDeleting}
                    className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
                  >
                    {isDeleting ? 'Eliminando...' : 'Eliminar'}
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
                    Editar Apoderado
                  </button>
                </>
              )}
            </div>
          </Card>
        </Dialog.Panel>
      </div>

      {/* Student Details Modal */}
      {viewingStudent && (
        <StudentDetailsModal 
          student={viewingStudent}
          onClose={() => setViewingStudent(null)}
          onSuccess={() => {
            setViewingStudent(null);
            fetchAssociatedStudents(); // Refresh students list after editing
          }}
        />
      )}
    </Dialog>
  );
}