import React from 'react';
import { format } from 'date-fns';
import clsx from 'clsx';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

export function StudentsTable({ students, onViewDetails, onSuccess }) {
  const handleDelete = async (student) => {
    const confirmed = window.confirm(`¿Estás seguro de que deseas eliminar al estudiante ${student.first_name} ${student.last_name}?`);
    if (!confirmed) return;

    try {
      const { error } = await supabase
        .from('students')
        .delete()
        .eq('id', student.id);

      if (error) throw error;

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
    <div className="overflow-x-auto">
      <table className="w-full min-w-[800px]">
        <thead>
          <tr className="border-b border-gray-100 dark:border-gray-800">
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Estudiante</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Convenio</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Curso</th>
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
                <span className={clsx(
                  'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium',
                  {
                    'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400': !student.fecha_retiro,
                    'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400': student.fecha_retiro
                  }
                )}>
                  {student.fecha_retiro ? 'Retirado' : 'Activo'}
                </span>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {formatDate(student.fecha_matricula)}
                </p>
              </td>
              <td className="py-3 px-4 text-right">
                <button 
                  onClick={() => handleDelete(student)}
                  className="text-red-600 hover:text-red-700 text-sm font-medium mr-4"
                >
                  Eliminar
                </button>
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
  );
}