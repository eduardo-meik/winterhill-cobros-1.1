import React from 'react';
import { TableContainer } from '../../ui/TableContainer';
import { TableHeader } from '../../ui/TableHeader';

export function GuardianReportTable({ data, loading, filteredByStudents, studentsSelected }) {
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
        {filteredByStudents ? (
          <div className="text-center">
            <p className="text-gray-500 dark:text-gray-400">No hay apoderados relacionados con los estudiantes seleccionados.</p>
            <p className="text-sm text-gray-400 dark:text-gray-500 mt-1">
              Estudiantes seleccionados: {studentsSelected}
            </p>
          </div>
        ) : (
          <p className="text-center text-gray-500 dark:text-gray-400">No hay apoderados para mostrar.</p>
        )}
      </div>
    );
  }
  
  // Display a message if filtering by students
  const filterMessage = filteredByStudents ? (
    <div className="mb-4 p-2 bg-blue-50 dark:bg-blue-900/20 rounded text-sm border border-blue-100 dark:border-blue-800">
      <p className="text-blue-700 dark:text-blue-300">
        Mostrando apoderados relacionados con: <span className="font-medium">{studentsSelected}</span>
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
            </tr>
          </TableHeader>
          <tbody>
            {data.map((guardian) => (
              <tr
                key={guardian.id}
                className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-hover transition-colors"
              >
                <td className="py-3 px-4">
                  <p className="text-sm font-medium text-gray-900 dark:text-white">
                    {guardian.name}
                  </p>
                </td>
                <td className="py-3 px-4">
                  <p className="text-sm text-gray-700 dark:text-gray-300">
                    {guardian.run || "-"}
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