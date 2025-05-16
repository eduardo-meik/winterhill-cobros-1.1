import React, { useState } from 'react';
import { format } from 'date-fns';
import clsx from 'clsx';
import { TableContainer } from '../../ui/TableContainer';
import { TableHeader } from '../../ui/TableHeader';

export function PaymentsTable({ data, loading, onViewDetails, filteredCount, totalCount, isFiltered }) {
  const [sortField, setSortField] = useState('due_date');
  const [sortDirection, setSortDirection] = useState('asc');
  
  const handleSort = (field) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };
  
  // Helper function to get sortable value
  const getSortValue = (payment, field) => {
    if (field === 'student_name') {
      return payment.student?.whole_name || 
        `${payment.student?.apellido_paterno || ''} ${payment.student?.first_name || ''}`;
    }
    
    if (field === 'curso') {
      return payment.student?.cursos?.nom_curso || '';
    }
    
    if (field === 'due_date' && payment.due_date) {
      return new Date(payment.due_date).getTime();
    }
    
    if (field === 'payment_date' && payment.payment_date) {
      return new Date(payment.payment_date).getTime();
    }
    
    if (field === 'numero_cuota') {
      return parseInt(payment[field] || '0', 10);
    }
    
    return payment[field];
  };
  
  // Sort payments
  const sortedPayments = [...data].sort((a, b) => {
    const aValue = getSortValue(a, sortField);
    const bValue = getSortValue(b, sortField);
    
    // Handle null/undefined values
    if (aValue === undefined || aValue === null) return sortDirection === 'asc' ? -1 : 1;
    if (bValue === undefined || bValue === null) return sortDirection === 'asc' ? 1 : -1;
    
    // Compare values
    if (aValue < bValue) {
      return sortDirection === 'asc' ? -1 : 1;
    }
    if (aValue > bValue) {
      return sortDirection === 'asc' ? 1 : -1;
    }
    return 0;
  });
    if (loading) {
    return (      <div className="flex items-center justify-center py-8">
        <div className="flex flex-col items-center">
          <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
          <p className="text-gray-500 dark:text-gray-400 mt-3">Cargando datos...</p>
        </div>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-center">
        <svg xmlns="http://www.w3.org/2000/svg" className="h-12 w-12 text-gray-400 dark:text-gray-600 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.75 9.75l4.5 4.5m0-4.5l-4.5 4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p className="text-gray-500 dark:text-gray-400 font-medium">
          {isFiltered 
            ? "No hay resultados con los filtros aplicados" 
            : "No hay pagos para mostrar"}
        </p>
        <p className="text-gray-400 dark:text-gray-500 text-sm mt-1">
          {isFiltered 
            ? "Prueba con otros criterios de filtrado" 
            : "Intenta con diferentes filtros"}
        </p>
        {isFiltered && totalCount > 0 && (
          <div className="mt-3 bg-blue-50 dark:bg-blue-900/20 px-3 py-2 rounded-md">
            <p className="text-blue-700 dark:text-blue-300 text-sm">
              Se han filtrado {totalCount - filteredCount} de {totalCount} registros
            </p>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <TableContainer>
        <TableHeader>
          <tr className="border-b border-gray-100 dark:border-gray-800">
            <th 
              className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
              onClick={() => handleSort('student_name')}
            >
              Estudiante {sortField === 'student_name' && (sortDirection === 'asc' ? '↑' : '↓')}
            </th>
            <th 
              className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
              onClick={() => handleSort('numero_cuota')}
            >
              Cuota N° {sortField === 'numero_cuota' && (sortDirection === 'asc' ? '↑' : '↓')}
            </th>
            <th 
              className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
              onClick={() => handleSort('amount')}
            >
              Monto {sortField === 'amount' && (sortDirection === 'asc' ? '↑' : '↓')}
            </th>
            <th 
              className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400"
            >
              Porcentaje Beca
            </th>
            <th 
              className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400"
            >
              Inst. Financiera
            </th>
            <th 
              className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
              onClick={() => handleSort('status')}
            >
              Estado {sortField === 'status' && (sortDirection === 'asc' ? '↑' : '↓')}
            </th>
            <th 
              className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
              onClick={() => handleSort('due_date')}
            >
              Fecha Vencimiento {sortField === 'due_date' && (sortDirection === 'asc' ? '↑' : '↓')}
            </th>
            <th 
              className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
              onClick={() => handleSort('payment_method')}
            >
              Método de Pago {sortField === 'payment_method' && (sortDirection === 'asc' ? '↑' : '↓')}
            </th>
            {onViewDetails && (
              <th className="text-right py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Acciones</th>
            )}
          </tr>
        </TableHeader>
        <tbody>
          {sortedPayments.map((payment) => (
            <tr
              key={payment.id}
              className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-hover transition-colors"
            >
              <td className="py-3 px-4">
                <div className="flex items-center gap-3">
                  <div>
                    <div className="flex flex-col">
                      <p className="text-sm font-medium text-gray-900 dark:text-white">
                        {payment.student?.whole_name || `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                        {payment.student?.cursos?.nom_curso || 'Curso no asignado'}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {payment.student?.run || 'Sin RUN'}
                      </p>
                    </div>
                  </div>
                </div>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white font-medium">
                  {payment.numero_cuota || 'N/A'}
                </p>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm font-medium text-gray-900 dark:text-white">
                  ${payment.amount ? Math.round(payment.amount).toLocaleString() : '0'}
                </p>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white">
                  {payment.porcentaje_beca ? `${payment.porcentaje_beca}%` : 'N/A'}
                </p>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white">
                  {payment.inst_financiera || 'N/A'}
                </p>
              </td>
              <td className="py-3 px-4">
                <span className={clsx(
                  'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium',
                  payment.status === 'paid' && 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
                  payment.status === 'pending' && 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
                  payment.status === 'overdue' && 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
                  payment.status === 'cancelled' && 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
                )}>
                  {payment.status === 'paid' ? 'Pagado' : 
                   payment.status === 'pending' ? 'Pendiente' : 
                   payment.status === 'overdue' ? 'Vencido' : 
                   'Anulado'}
                </span>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {payment.due_date 
                    ? format(new Date(payment.due_date), 'dd/MM/yyyy')
                    : 'No especificada'
                  }
                </p>
              </td>
              <td className="py-3 px-4">
                <p className="text-sm text-gray-900 dark:text-white capitalize">
                  {payment.payment_method || 'No especificado'}
                </p>
              </td>
              {onViewDetails && (
                <td className="py-3 px-4 text-right">
                  <button 
                    onClick={() => onViewDetails(payment)}
                    className="text-primary hover:text-primary-light text-sm font-medium"
                  >
                    Ver Detalles
                  </button>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </TableContainer>
    </div>
  );
}