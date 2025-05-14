import React from 'react';
import clsx from 'clsx';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

export function GuardiansTable({ guardians, onViewDetails, onSuccess }) {
  const handleDelete = async (guardian) => {
    const confirmed = window.confirm(`¿Estás seguro de que deseas eliminar al apoderado ${guardian.first_name} ${guardian.last_name}?`);
    if (!confirmed) return;

    try {
      const { error } = await supabase
        .from('guardians')
        .delete()
        .eq('id', guardian.id);

      if (error) throw error;

      toast.success('Apoderado eliminado exitosamente');
      onSuccess?.();
    } catch (error) {
      console.error('Error:', error);
      toast.error('Error al eliminar el apoderado');
    }
  };

  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[800px]">
        <thead>
          <tr className="border-b border-gray-100 dark:border-gray-800">
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Apoderado</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Teléfono</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Email</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Tipo</th>
            <th className="text-right py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Acciones</th>
          </tr>
        </thead>
        <tbody>
          {guardians.map((guardian) => (
            <tr 
              key={guardian.id}
              className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-hover transition-colors"
            >
              <td className="py-3 px-4">
                <div className="flex items-center gap-3">
                  <div>
                    <p className="text-sm font-medium text-gray-900 dark:text-white">
                      {guardian.first_name} {guardian.last_name}
                    </p>
                  </div>
                </div>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white">{guardian.phone}</p>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white">{guardian.email}</p>
              </td>
              <td className="py-3 px-4">
                <span className={clsx(
                  'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium',
                  'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
                )}>
                  {guardian.relationship_type}
                </span>
              </td>
              <td className="py-3 px-4 text-right">
                <button 
                  onClick={() => handleDelete(guardian)}
                  className="text-red-600 hover:text-red-700 text-sm font-medium mr-4"
                >
                  Eliminar
                </button>
                <button 
                  onClick={() => onViewDetails(guardian)}
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