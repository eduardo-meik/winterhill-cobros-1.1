import React, { useState, useMemo } from 'react';
import { format } from 'date-fns';
import clsx from 'clsx';
import { TableContainer } from '../ui/TableContainer';
import { TableHeader } from '../ui/TableHeader';

export const PaymentsTable = React.memo(function PaymentsTable({
  payments,
  onViewDetails,
  onStudentClick,
  loading
}) {
  const [sortField, setSortField] = useState('numero_cuota');
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
      return payment.student?.curso?.nom_curso || '';
    }
    
    if (field === 'due_date' && payment.due_date) {
      return new Date(payment.due_date).getTime();
    }
    
    if (field === 'payment_date' && payment.payment_date) {
      return new Date(payment.payment_date).getTime();
    }
    
    if (field === 'numero_cuota') {
      return parseInt(payment[field] || '0');
    }
    
    return payment[field];
  };
  
  // Sort payments
  const sortedPayments = [...payments].sort((a, b) => {
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
    return (
      <div className="flex items-center justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!payments || payments.length === 0) {
    return <p className="text-center text-gray-500 dark:text-gray-400 py-4">No hay pagos para mostrar.</p>;
  }

  // Log cuotas for debugging - handle numeric type correctly
  const cuotaNumbers = [...new Set(sortedPayments
    .map(p => p.numero_cuota)
    .filter(c => c !== null && c !== undefined)
  )].sort((a, b) => Number(a) - Number(b));
  console.log('Cuota numbers in display:', cuotaNumbers);

  return (
    <>
      {/* Mobile card view */}
      <div className="md:hidden space-y-3">
        {sortedPayments.map((payment) => (
          <div key={payment.id} className="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover" onClick={() => onViewDetails(payment)}>
            <div className="flex items-start justify-between mb-2">
              <div>
                <button
                  type="button"
                  className="text-sm font-semibold text-primary hover:text-primary-light hover:underline text-left cursor-pointer"
                  onClick={(e) => { e.stopPropagation(); onStudentClick?.(payment.student_id, payment.student?.whole_name || `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`); }}
                >
                  {payment.student?.whole_name || `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`}
                </button>
                <p className="text-xs text-gray-500 dark:text-gray-400">{payment.student?.curso?.nom_curso || 'Curso no asignado'}</p>
              </div>
              <span className={clsx(
                'px-2 py-0.5 rounded-full text-xs font-medium',
                payment.status === 'paid' && 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
                payment.status === 'pending' && 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
                payment.status === 'overdue' && 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
                payment.status === 'cancelled' && 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
              )}>
                {payment.status === 'paid' ? 'Pagado' : payment.status === 'pending' ? 'Pendiente' : payment.status === 'overdue' ? 'Vencido' : 'Anulado'}
              </span>
            </div>
            <div className="flex items-center justify-between text-xs text-gray-600 dark:text-gray-300">
              <span>Cuota {payment.numero_cuota || 'N/A'}</span>
              <span className="font-semibold text-sm text-gray-900 dark:text-white">${payment.amount ? Math.round(payment.amount).toLocaleString() : '0'}</span>
            </div>
            <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
              <span>Vence: {payment.due_date ? format(new Date(payment.due_date), 'dd/MM/yyyy') : 'N/A'}</span>
              <span className="capitalize">{payment.payment_method || ''}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Desktop table view */}
      <div className="hidden md:block overflow-x-auto">
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
              Cuota número {sortField === 'numero_cuota' && (sortDirection === 'asc' ? '↑' : '↓')}
            </th>
            <th 
              className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
              onClick={() => handleSort('amount')}
            >
              Monto {sortField === 'amount' && (sortDirection === 'asc' ? '↑' : '↓')}
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
            <th className="text-right py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Acciones</th>
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
                      <button
                        type="button"
                        className="text-sm font-medium text-primary hover:text-primary-light hover:underline text-left cursor-pointer"
                        onClick={() => onStudentClick?.(payment.student_id, payment.student?.whole_name || `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`)}
                      >
                        {payment.student?.whole_name || `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`}
                      </button>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                        {payment.student?.curso?.nom_curso || 'Curso no asignado'}
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
              <td className="py-3 px-4 text-right">
                <button 
                  onClick={() => onViewDetails(payment)}
                  className="text-primary hover:text-primary-light text-sm font-medium"
                >
                  Ver Detalles
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </TableContainer>
      </div>
    </>
  );
});