import React from 'react';
import { TableContainer } from '../../ui/TableContainer';
import { TableHeader } from '../../ui/TableHeader';

export function StudentReportTable({ data, loading, filteredByGuardians, guardiansSelected }) {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="py-4">
        {filteredByGuardians ? (
          <div className="text-center">
            <p className="text-gray-500 dark:text-gray-400">No hay estudiantes relacionados con los apoderados seleccionados.</p>
            <p className="text-sm text-gray-400 dark:text-gray-500 mt-1">
              Apoderados seleccionados: {guardiansSelected}
            </p>
          </div>
        ) : (
          <p className="text-center text-gray-500 dark:text-gray-400">No hay estudiantes para mostrar.</p>
        )}
      </div>
    );
  }
  
  // Display a message if filtering by guardians
  const filterMessage = filteredByGuardians ? (
    <div className="mb-4 p-2 bg-blue-50 dark:bg-blue-900/20 rounded text-sm border border-blue-100 dark:border-blue-800">
      <p className="text-blue-700 dark:text-blue-300">
        Mostrando estudiantes relacionados con los apoderados: <span className="font-medium">{guardiansSelected}</span>
      </p>
    </div>
  ) : null;

  return (
    <div>
      {filterMessage}
      <div className="overflow-x-auto">
        <TableContainer>
        <TableHeader>
          <tr className="border-b border-gray-100 dark:border-gray-800">
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Nombre</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">RUN</th>
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Curso</th>
          </tr>
        </TableHeader>
        <tbody>
          {data.map((student) => (
            <tr
              key={student.id}
              className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-hover transition-colors"
            >
              <td className="py-3 px-4">
                <p className="text-sm font-medium text-gray-900 dark:text-white">
                  {student.whole_name || `${student.first_name} ${student.apellido_paterno}`}
                </p>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white">
                  {student.run || 'N/A'}
                </p>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white">
                  {student.cursos?.nom_curso || 'No asignado'}
                </p>
              </td>
            </tr>
          ))}
        </tbody>
      </TableContainer>
      </div>
    </div>
  );
}