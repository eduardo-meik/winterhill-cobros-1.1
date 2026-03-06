import React from 'react';
import { format } from 'date-fns';
import clsx from 'clsx';
import toast from 'react-hot-toast';
import { useStudentMutations } from '../../hooks/mutations/useStudentMutations';
import {
  deriveStudentStatusFromRecord,
  getStudentStatusBadgeClass,
  getStudentStatusLabel
} from '../../utils/studentStatus';

export function StudentsTable({ students, onViewDetails, onSuccess, isReadOnly = false }) {
  const { deleteStudent } = useStudentMutations();
  const handleDelete = async (student) => {
    const confirmed = window.confirm(`¿Estás seguro de que deseas eliminar al estudiante ${student.first_name} ${student.last_name}?`);
    if (!confirmed) return;

    try {
      await deleteStudent.mutateAsync(student.id);
      toast.success('Estudiante eliminado exitosamente');
      onSuccess?.();
    } catch (error) {
      console.error('Error:', error);
      toast.error('Error al eliminar el estudiante');
    }
  };

  const formatDate = (date) => {
    if (!date) return 'No especificada';
    try {
      return format(new Date(date), 'dd/MM/yyyy');
    } catch (error) {
      console.error('Error formatting date:', error);
      return 'Fecha inválida';
    }
  };

  return (
    <>
      {/* Mobile card view */}
      <div className="md:hidden space-y-3">
        {students.map((student) => {
          const canonicalStatus = deriveStudentStatusFromRecord(student);
          const badgeClass = getStudentStatusBadgeClass(canonicalStatus);
          const label = getStudentStatusLabel(canonicalStatus);
          return (
            <div key={student.id} className="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover">
              <div className="flex items-start justify-between mb-2">
                <div>
                  <p className="text-sm font-semibold text-gray-900 dark:text-white">
                    {student.whole_name || `${student.first_name} ${student.apellido_paterno}`}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">{student.run}</p>
                </div>
                <span className={clsx('px-2 py-0.5 rounded-full text-xs font-medium', badgeClass)}>{label}</span>
              </div>
              <div className="grid grid-cols-2 gap-1 text-xs text-gray-600 dark:text-gray-300 mb-3">
                <span>Curso: {student.cursos?.nom_curso || 'Sin asignar'}</span>
                <span>Año: {student.cursos?.year_academico || '—'}</span>
                <span>Convenio: {student.categoria_social || 'Sin convenio'}</span>
                <span>Matrícula: {formatDate(student.fecha_matricula)}</span>
              </div>
              <div className="flex gap-2 justify-end">
                {!isReadOnly && (
                  <button onClick={() => handleDelete(student)} className="text-red-600 text-xs font-medium">Eliminar</button>
                )}
                <button onClick={() => onViewDetails(student)} className="text-primary text-xs font-medium">Ver Detalles</button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Desktop table view */}
      <div className="hidden md:block overflow-x-auto">
      <table className="w-full min-w-[800px]">
        <thead>
          <tr className="border-b border-gray-100 dark:border-gray-800">
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Estudiante</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Convenio</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Curso</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Año</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Estado</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Fecha Matrícula</th>
            <th className="text-right py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Acciones</th>
          </tr>
        </thead>
        <tbody>
          {students.map((student) => (
            <tr 
              key={student.id}
              className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-hover transition-colors"
            >
              <td className="py-3 px-4">
                <div className="flex items-center">
                  <div>
                    <p className="text-sm font-medium text-gray-900 dark:text-white">
                      {student.whole_name || `${student.first_name} ${student.apellido_paterno}`}
                    </p>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      {student.run}
                    </p>
                  </div>
                </div>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white">
                  {student.categoria_social || 'Sin convenio'}
                </p>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white">
                  {student.cursos?.nom_curso || 'Sin asignar'}
                </p>
              </td>
              <td className="py-3 px-4">
                <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300">
                  {student.cursos?.year_academico || '—'}
                </span>
              </td>
              <td className="py-3 px-4">
                {(() => {
                  const canonicalStatus = deriveStudentStatusFromRecord(student);
                  const badgeClass = getStudentStatusBadgeClass(canonicalStatus);
                  const label = getStudentStatusLabel(canonicalStatus);
                  return (
                    <span className={clsx('inline-flex items-center px-2 py-1 rounded-full text-xs font-medium', badgeClass)}>
                      {label}
                    </span>
                  );
                })()}
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {formatDate(student.fecha_matricula)}
                </p>
              </td>
              <td className="py-3 px-4 text-right">
                {!isReadOnly && (
                  <button 
                    onClick={() => handleDelete(student)}
                    className="text-red-600 hover:text-red-700 text-sm font-medium mr-4"
                  >
                    Eliminar
                  </button>
                )}
                <button 
                  onClick={() => onViewDetails(student)}
                  className="text-primary hover:text-primary-light text-sm font-medium"
                >
                  Ver Detalles
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      </div>
    </>
  );
}