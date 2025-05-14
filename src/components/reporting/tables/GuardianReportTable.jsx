import React from 'react';
import { TableContainer } from '../../ui/TableContainer';
import { TableHeader } from '../../ui/TableHeader';

export function GuardianReportTable({ data, loading }) {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return <p className="text-center text-gray-500 dark:text-gray-400 py-4">No hay apoderados para mostrar.</p>;
  }

  return (
    <div className="overflow-x-auto">
      <TableContainer>
        <TableHeader>
          <tr className="border-b border-gray-100 dark:border-gray-800">
            <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Nombre</th>
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
            </tr>
          ))}
        </tbody>
      </TableContainer>
    </div>
  );
}