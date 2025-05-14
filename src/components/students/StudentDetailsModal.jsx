import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import { format } from 'date-fns';
import { Card } from '../ui/Card';
import { StudentFormModal } from './StudentFormModal';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

const DetailItem = ({ label, value }) => (
  <div className="space-y-1">
    <dt className="text-sm text-gray-500 dark:text-gray-400">{label}</dt>
    <dd className="text-sm font-medium text-gray-900 dark:text-white">{value}</dd>
  </div>
);

const formatDate = (dateString) => {
  if (!dateString) return 'No especificada';
  
  const date = new Date(dateString);
  if (isNaN(date.getTime())) return 'Fecha inválida';
  
  return format(date, 'dd/MM/yyyy');
};

export function StudentDetailsModal({ student, onClose, onSuccess }) { 
  if (!student) return null;

  const [isEditing, setIsEditing] = useState(false);
  const [guardians, setGuardians] = useState([]);
  const [loadingGuardians, setLoadingGuardians] = useState(true);

  // Fetch guardian data when component mounts
  useEffect(() => {
    fetchGuardians();
  }, [student.id]);

  const fetchGuardians = async () => {
    if (!student?.id) return;
    
    try {
      setLoadingGuardians(true);
      
      // First, get the guardian IDs
      const { data: associations, error: associationsError } = await supabase
        .from('student_guardian')
        .select('guardian_id')
        .eq('student_id', student.id);

      if (associationsError) throw associationsError;
      
      if (!associations || associations.length === 0) {
        setGuardians([]);
        return;
      }

      const guardianIds = associations.map(a => a.guardian_id);
      
      // Then get the guardians data
      const { data: guardiansData, error: guardiansError } = await supabase
        .from('guardians')
        .select('*')
        .in('id', guardianIds);
        
      if (guardiansError) throw guardiansError;
      
      setGuardians(guardiansData || []);
    } catch (error) {
      console.error('Error fetching guardians:', error);
      toast.error('Error al cargar los apoderados asociados');
    } finally {
      setLoadingGuardians(false);
    }
  };

  const handleEditSuccess = () => {
    setIsEditing(false);
    onSuccess?.();
  };

  if (isEditing) {
    return (
      <StudentFormModal
        isOpen={true}
        // When closing the *edit form*, just set isEditing back to false
        onClose={() => setIsEditing(false)}
        student={student}
        // Pass the internal handler to the form modal
        onSuccess={handleEditSuccess}
      />
    );
  }

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
            <div className="flex items-center justify-between p-6 border-b border-gray-100 dark:border-gray-800 shrink-0">
              <div>
                <Dialog.Title 
                  className="text-lg font-semibold text-gray-900 dark:text-white"
                  role="heading" 
                  aria-level="1"
                >
                  <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                    {student.whole_name || `${student.first_name} ${student.apellido_paterno} ${student.apellido_materno || ''}`}
                  </h2>
                </Dialog.Title>
                <p className="text-sm text-gray-500 dark:text-gray-400">RUN: {student.run}</p>
              </div>
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

            <div className="flex-1 overflow-y-auto p-6">
              {/* Student details */}
              <div className="grid grid-cols-2 gap-6">
                <DetailItem
                  label="Curso"
                  value={student.cursos?.nom_curso || 'Sin asignar'}
                />
                <DetailItem 
                  label="Nombre Social" 
                  value={student.nombre_social || 'No especificado'}
                />
                <DetailItem 
                  label="Estado" 
                  value={student.fecha_retiro ? 'Retirado' : 'Activo'}
                />
                <DetailItem 
                  label="Fecha de Matrícula" 
                  value={formatDate(student.fecha_matricula)}
                />
                <DetailItem 
                  label="Fecha de Incorporación" 
                  value={formatDate(student.fecha_incorporacion)}
                />
                {student.fecha_retiro && (
                  <DetailItem 
                    label="Fecha de Retiro" 
                    value={formatDate(student.fecha_retiro)}
                  />
                )}
                <DetailItem 
                  label="Género" 
                  value={student.genero || 'No especificado'}
                />
                <DetailItem 
                  label="Nacionalidad" 
                  value={student.nacionalidad || 'No especificada'}
                />
                <DetailItem 
                  label="Institución de Procedencia" 
                  value={student.institucion_procedencia || 'No especificada'}
                />
                <DetailItem 
                  label="Dirección" 
                  value={student.direccion || 'No especificada'}
                />
                <DetailItem 
                  label="Comuna" 
                  value={student.comuna || 'No especificada'}
                />
                <DetailItem 
                  label="Con quién vive" 
                  value={student.con_quien_vive || 'No especificado'}
                />
                {student.motivo_retiro && (
                  <DetailItem 
                    label="Motivo de Retiro" 
                    value={student.motivo_retiro}
                  />
                )}
              </div>

              {/* Guardians section */}
              <div className="mt-8">
                <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-4">
                  Apoderados Asociados
                </h3>
                {loadingGuardians ? (
                  <div className="flex items-center justify-center py-4">
                    <div className="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
                  </div>
                ) : guardians.length > 0 ? (
                  <div className="space-y-3">
                    {guardians.map((guardian) => (
                      <div
                        key={guardian.id}
                        className="flex items-center justify-between p-4 rounded-lg bg-gray-50 dark:bg-dark-hover"
                      >
                        <div className="flex-1">
                          <p className="text-sm font-medium text-gray-900 dark:text-white">
                            {guardian.first_name} {guardian.last_name} • {guardian.relationship_type}
                          </p>
                          <div className="flex flex-col sm:flex-row sm:gap-4">
                            <p className="text-sm text-gray-500 dark:text-gray-400">
                              RUT: {guardian.run || 'No especificado'}
                            </p>
                            <p className="text-sm text-gray-500 dark:text-gray-400">
                              Teléfono: {guardian.phone || 'No especificado'}
                            </p>
                          </div>
                          <p className="text-sm text-gray-500 dark:text-gray-400">
                            Email: {guardian.email || 'No especificado'}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-gray-500 dark:text-gray-400">No hay apoderados asociados.</p>
                )}
              </div>
            </div>

            {/* Footer */}
            <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-100 dark:border-gray-800 shrink-0">
              <button
                onClick={onClose}
                aria-label="Cerrar detalles"
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-lg transition-colors"
              >
                Cerrar
              </button>
              <button
                onClick={() => setIsEditing(true)}
                aria-label="Editar estudiante"
                className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-light rounded-lg transition-colors"
              >
                Editar Estudiante
              </button>
            </div>
          </Card>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}