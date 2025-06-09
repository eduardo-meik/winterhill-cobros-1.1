import React, { useState, useEffect } from 'react';
import { Dialog } from '@headlessui/react';
import { format } from 'date-fns';
import { Card } from '../ui/Card';
import { StudentFormModal } from './StudentFormModal';
import { GuardianDetailsModal } from '../guardians/GuardianDetailsModal';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

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
  const [viewingGuardian, setViewingGuardian] = useState(null); // NEW
  const [editingFieldKey, setEditingFieldKey] = useState(null); // null | 'run' | 'email' | etc.
  const [fieldEditValue, setFieldEditValue] = useState('');
  const [isSavingField, setIsSavingField] = useState(false);

  // Fetch guardian data when component mounts
  useEffect(() => {
    fetchGuardians();
  }, [student.id]);

  const fetchGuardians = async () => {
    if (!student?.id) return;
    
    try {
      setLoadingGuardians(true);
      
      // First, get the guardian IDs and their roles for this student
      const { data: associations, error: associationsError } = await supabase
        .from('student_guardian')
        .select('guardian_id, guardian_role') // Fetch guardian_role
        .eq('student_id', student.id);

      if (associationsError) throw associationsError;
      
      if (!associations || associations.length === 0) {
        setGuardians([]);
        setLoadingGuardians(false); // Ensure loading is stopped
        return;
      }

      const guardianIds = associations.map(a => a.guardian_id);
      
      // Then get the full guardians data
      const { data: guardiansData, error: guardiansError } = await supabase
        .from('guardians')
        .select('*') // Fetches all columns from guardians table (including tipo_apoderado)
        .in('id', guardianIds);
        
      if (guardiansError) throw guardiansError;
      
      // Combine guardian data with their specific roles for this student
      const combinedGuardians = guardiansData.map(g => {
        const association = associations.find(assoc => assoc.guardian_id === g.id);
        return {
          ...g,
          guardian_role: association ? (association.guardian_role || 'No asignado') : 'No asignado'
        };
      }).filter(Boolean); // Ensure no null/undefined entries if guardiansData is sparse
      
      setGuardians(combinedGuardians || []);
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

  const handleFieldEditClick = (fieldKey, currentValue) => {
    setEditingFieldKey(fieldKey);
    setFieldEditValue(currentValue || '');
    if (isEditing) {
      setIsEditing(false); // Cancel full edit mode if starting inline edit
    }
  };

  const handleFieldCancel = () => {
    setEditingFieldKey(null);
    setFieldEditValue('');
  };

  const handleFieldSave = async (fieldKey, label) => {
    // Basic validation for empty required fields during inline edit
    const requiredFields = ['run', 'genero', 'nacionalidad', 'fecha_matricula', 'fecha_incorporacion'];
    if (requiredFields.includes(fieldKey) && !fieldEditValue.trim()) {
      toast.error(`El campo ${label.toLowerCase()} es requerido.`);
      return;
    }
    if (fieldKey === 'run' && !/^(\\d{1,3}(?:\\.\\d{3})*)-?([\\dkK])$/.test(fieldEditValue)) {
      toast.error('Formato de RUT inválido');
      return;
    }
    // Add more specific validations if needed for other fields like dates
    if ((fieldKey === 'fecha_matricula' || fieldKey === 'fecha_incorporacion' || fieldKey === 'fecha_retiro') && fieldEditValue && isNaN(new Date(fieldEditValue).getTime())) {
      toast.error(`Fecha de ${label.toLowerCase()} inválida.`);
      return;
    }

    // Prevent saving if value hasn't changed
    let originalValue = student[fieldKey];
    if (fieldKey.startsWith('fecha_') && originalValue) {
      // Dates from DB might be full ISO strings, compare with formatted or re-parsed input
      originalValue = format(new Date(originalValue), 'yyyy-MM-dd');
    }
    if (fieldEditValue === (originalValue || '')) {
      handleFieldCancel();
      return;
    }

    setIsSavingField(true);
    try {
      const updateData = { [fieldKey]: fieldEditValue };
      
      const { error } = await supabase
        .from('students')
        .update(updateData)
        .eq('id', student.id);

      if (error) throw error;

      toast.success(`${label} actualizado exitosamente.`);
      onSuccess?.(); 
      handleFieldCancel();
    } catch (error) {
      console.error(`Error updating ${label}:`, error);
      toast.error(`Error al actualizar ${label.toLowerCase()}`);
    } finally {
      setIsSavingField(false);
    }
  };

  const renderDetailItem = (label, fieldKey, value, inputType = 'text', options = []) => {
    const isCurrentlyEditingThisField = editingFieldKey === fieldKey;
    let displayValue = value;
    if (fieldKey.startsWith('fecha_') && value) {
      displayValue = formatDate(value); // Use existing formatDate for display
    }

    if (isCurrentlyEditingThisField) {
      let currentEditValue = fieldEditValue;
      if (inputType === 'date' && fieldEditValue) {
        // Ensure date input gets yyyy-MM-dd
        try {
          currentEditValue = format(new Date(fieldEditValue), 'yyyy-MM-dd');
        } catch (e) { /* ignore if date is not valid yet */ }
      }

      return (
        <div className="space-y-1 col-span-2 sm:col-span-1">
          <label htmlFor={fieldKey} className="text-sm text-gray-500 dark:text-gray-400 block mb-1">{label}</label>
          <div className="flex items-center gap-2">
            {inputType === 'select' ? (
              <select
                id={fieldKey}
                value={currentEditValue}
                onChange={(e) => setFieldEditValue(e.target.value)}
                className="w-full px-3 py-1.5 rounded-md border border-primary dark:border-primary bg-white dark:bg-dark-input text-gray-900 dark:text-white focus:ring-1 focus:ring-primary"
              >
                {options.map(opt => <option key={opt.value} value={opt.value}>{opt.label}</option>)}
              </select>
            ) : (
              <input
                id={fieldKey}
                type={inputType}
                value={currentEditValue}
                onChange={(e) => setFieldEditValue(e.target.value)}
                className="w-full px-3 py-1.5 rounded-md border border-primary dark:border-primary bg-white dark:bg-dark-input text-gray-900 dark:text-white focus:ring-1 focus:ring-primary"
                autoFocus
              />
            )}
            <button onClick={() => handleFieldSave(fieldKey, label)} disabled={isSavingField} className="p-1 text-green-500 hover:text-green-700 disabled:opacity-50">
              {isSavingField ? 
                <svg className="animate-spin h-5 w-5 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                :
                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg> // Checkmark
              }
            </button>
            <button onClick={handleFieldCancel} disabled={isSavingField} className="p-1 text-red-500 hover:text-red-700 disabled:opacity-50">
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg> 
            </button>
          </div>
        </div>
      );
    }

    return (
      <div className="space-y-1 col-span-2 sm:col-span-1 group">
        <dt className="text-sm text-gray-500 dark:text-gray-400">{label}</dt>
        <dd className="text-sm font-medium text-gray-900 dark:text-white flex items-center justify-between">
          <span>{displayValue || 'No especificado'}</span>
          {!isEditing && (
            <button
              onClick={() => handleFieldEditClick(fieldKey, student[fieldKey])}
              disabled={editingFieldKey !== null && editingFieldKey !== fieldKey}
              className="p-1 text-gray-400 hover:text-primary opacity-0 group-hover:opacity-100 focus:opacity-100 transition-opacity disabled:opacity-30 disabled:cursor-not-allowed"
              aria-label={`Editar ${label}`}
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg>
            </button>
          )}
        </dd>
      </div>
    );
  };

  const enhancedOnClose = () => {
    handleFieldCancel();
    onClose();
  };

  const handleMainEditClick = () => {
    handleFieldCancel();
    setIsEditing(true);
  };

  const handleMainCancelFromEditForm = () => {
    handleFieldCancel();
    setIsEditing(false); 
    // onSuccess will be called by StudentFormModal if changes were saved there
  };

  if (isEditing) {
    return (
      <StudentFormModal
        isOpen={true}
        onClose={handleMainCancelFromEditForm} // Use new handler
        student={student}
        onSuccess={() => {
          setIsEditing(false);
          onSuccess?.();
        }}
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
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                {renderDetailItem('Curso', 'curso', student.cursos?.nom_curso, 'text')} {/* Assuming curso is an object, might need specific handling if ID is stored */}
                {renderDetailItem('Nombre Social', 'nombre_social', student.nombre_social, 'text')}
                {renderDetailItem('Estado', 'estado_std', student.estado_std, 'select', [
                  { value: '', label: 'Seleccionar estado' },
                  { value: 'Activo', label: 'Activo' },
                  { value: 'Retirado', label: 'Retirado' },
                  { value: 'Suspendido', label: 'Suspendido' }
                ])}
                {renderDetailItem('Fecha de Matrícula', 'fecha_matricula', student.fecha_matricula, 'date')}
                {renderDetailItem('Fecha de Incorporación', 'fecha_incorporacion', student.fecha_incorporacion, 'date')}
                {student.fecha_retiro && renderDetailItem('Fecha de Retiro', 'fecha_retiro', student.fecha_retiro, 'date')}
                {renderDetailItem('Género', 'genero', student.genero, 'select', [
                  {value: '', label: 'Seleccionar'},
                  {value: 'MASCULINO', label: 'MASCULINO'},
                  {value: 'FEMENINO', label: 'FEMENINO'},
                  {value: 'OTRO', label: 'OTRO'},
                ])}
                {renderDetailItem('Nacionalidad', 'nacionalidad', student.nacionalidad, 'text')}
                {renderDetailItem('Institución de Procedencia', 'institucion_procedencia', student.institucion_procedencia, 'text')}
                {renderDetailItem('Dirección', 'direccion', student.direccion, 'text')}
                {renderDetailItem('Comuna', 'comuna', student.comuna, 'text')}
                {renderDetailItem('Con quién vive', 'con_quien_vive', student.con_quien_vive, 'text')}
                {student.motivo_retiro && renderDetailItem('Motivo de Retiro', 'motivo_retiro', student.motivo_retiro, 'text')}
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
                          {/* Display guardian_role specific to this student-guardian relationship */}
                          {guardian.guardian_role && guardian.guardian_role !== 'No asignado' && (
                            <p className="text-sm text-gray-500 dark:text-gray-400">
                              Rol para este estudiante: <span className="font-semibold">{guardian.guardian_role}</span>
                            </p>
                          )}
                        </div>
                        <button
                          onClick={() => setViewingGuardian(guardian)}
                          className="p-2 text-primary hover:text-primary-dark dark:hover:text-primary-light transition-colors rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
                          aria-label="Ver detalles del apoderado"
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
                  <p className="text-sm text-gray-500 dark:text-gray-400">No hay apoderados asociados.</p>
                )}
              </div>
            </div>

            {/* Footer */}
            <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-100 dark:border-gray-800 shrink-0">
              <button
                onClick={enhancedOnClose} // Use new handler
                aria-label="Cerrar detalles"
                disabled={editingFieldKey !== null} // Disable if inline editing
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Cerrar
              </button>
              <button
                onClick={handleMainEditClick} // Use new handler
                aria-label="Editar estudiante"
                disabled={editingFieldKey !== null} // Disable if inline editing
                className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-light rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Editar Estudiante
              </button>
            </div>
          </Card>
        </Dialog.Panel>
      </div>
      {viewingGuardian && (
        <GuardianDetailsModal
          guardian={viewingGuardian}
          onClose={() => {
            handleFieldCancel(); // Cancel inline edit if user opens another modal
            setViewingGuardian(null);
          }}
          onSuccess={() => {
            setViewingGuardian(null);
            fetchGuardians(); // Refresh guardian list
            onSuccess(); // Propagate success to refresh student if guardian change affects it
          }}
        />
      )}
    </Dialog>
  );
}