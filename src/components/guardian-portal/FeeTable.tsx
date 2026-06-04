import React, { useMemo, useState } from 'react';
import {
  ChevronUpIcon,
  ChevronDownIcon,
  FunnelIcon,
  CheckCircleIcon,
  ClockIcon,
  ExclamationTriangleIcon,
} from '@heroicons/react/24/outline';
import { Fee, formatCurrency, formatDate } from '../../services/feeService';

type SortField = 'numero_cuota' | 'student_name' | 'amount' | 'due_date' | 'status' | 'payment_date';
type SortDirection = 'asc' | 'desc';
type StatusFilter = 'all' | 'paid' | 'pending' | 'overdue';

interface FeeTableProps {
  fees: Fee[];
  className?: string;
  showStudentColumn?: boolean;
  onRowClick?: (fee: Fee) => void;
}

export const FeeTable: React.FC<FeeTableProps> = ({
  fees,
  className = '',
  showStudentColumn = true,
  onRowClick,
}) => {
  const [sortField, setSortField] = useState<SortField>('numero_cuota');
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');

  // Sort and filter fees
  const processedFees = useMemo(() => {
    let filtered = [...fees];

    // Apply status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter((fee) => fee.status === statusFilter);
    }

    // Apply sorting
    filtered.sort((a, b) => {
      let aValue: any;
      let bValue: any;

      switch (sortField) {
        case 'numero_cuota':
          aValue = Number(a.numero_cuota || 0);
          bValue = Number(b.numero_cuota || 0);
          break;
        case 'student_name':
          aValue = a.student?.whole_name || a.student?.first_name || '';
          bValue = b.student?.whole_name || b.student?.first_name || '';
          break;
        case 'amount':
          aValue = Number(a.amount || 0);
          bValue = Number(b.amount || 0);
          break;
        case 'due_date':
          aValue = new Date(a.due_date || 0).getTime();
          bValue = new Date(b.due_date || 0).getTime();
          break;
        case 'payment_date':
          aValue = a.payment_date ? new Date(a.payment_date).getTime() : 0;
          bValue = b.payment_date ? new Date(b.payment_date).getTime() : 0;
          break;
        case 'status':
          aValue = a.status || '';
          bValue = b.status || '';
          break;
        default:
          return 0;
      }

      if (aValue < bValue) return sortDirection === 'asc' ? -1 : 1;
      if (aValue > bValue) return sortDirection === 'asc' ? 1 : -1;
      return 0;
    });

    return filtered;
  }, [fees, sortField, sortDirection, statusFilter]);

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };

  const SortIcon = ({ field }: { field: SortField }) => {
    if (sortField !== field) return null;
    return sortDirection === 'asc' ? (
      <ChevronUpIcon className="h-4 w-4" />
    ) : (
      <ChevronDownIcon className="h-4 w-4" />
    );
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'paid':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">
            <CheckCircleIcon className="h-3.5 w-3.5" />
            Pagada
          </span>
        );
      case 'pending':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400">
            <ClockIcon className="h-3.5 w-3.5" />
            Pendiente
          </span>
        );
      case 'overdue':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400">
            <ExclamationTriangleIcon className="h-3.5 w-3.5" />
            Atrasada
          </span>
        );
      default:
        return <span className="text-xs text-gray-500 dark:text-gray-400">-</span>;
    }
  };

  const getRowClassName = (status: string) => {
    const base = onRowClick
      ? 'cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700/50'
      : '';
    switch (status) {
      case 'paid':
        return `${base} bg-green-50/50 dark:bg-green-900/10`;
      case 'overdue':
        return `${base} bg-red-50/50 dark:bg-red-900/10`;
      default:
        return base;
    }
  };

  if (fees.length === 0) {
    return (
      <div className={`bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6 ${className}`}>
        <p className="text-sm text-gray-500 dark:text-gray-400 text-center">
          No hay aranceles para mostrar.
        </p>
      </div>
    );
  }

  return (
    <div className={`bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden ${className}`}>
      {/* Filter Bar */}
      <div className="px-4 py-3 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/50">
        <div className="flex items-center gap-2">
          <FunnelIcon className="h-4 w-4 text-gray-500 dark:text-gray-400" />
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
            Filtrar:
          </span>
          <div className="flex gap-2">
            <button
              onClick={() => setStatusFilter('all')}
              className={`px-3 py-1 text-xs font-medium rounded-full transition-colors ${
                statusFilter === 'all'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'
              }`}
            >
              Todas ({fees.length})
            </button>
            <button
              onClick={() => setStatusFilter('paid')}
              className={`px-3 py-1 text-xs font-medium rounded-full transition-colors ${
                statusFilter === 'paid'
                  ? 'bg-green-600 text-white'
                  : 'bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'
              }`}
            >
              Pagadas ({fees.filter((f) => f.status === 'paid').length})
            </button>
            <button
              onClick={() => setStatusFilter('pending')}
              className={`px-3 py-1 text-xs font-medium rounded-full transition-colors ${
                statusFilter === 'pending'
                  ? 'bg-yellow-600 text-white'
                  : 'bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'
              }`}
            >
              Pendientes ({fees.filter((f) => f.status === 'pending').length})
            </button>
            <button
              onClick={() => setStatusFilter('overdue')}
              className={`px-3 py-1 text-xs font-medium rounded-full transition-colors ${
                statusFilter === 'overdue'
                  ? 'bg-red-600 text-white'
                  : 'bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'
              }`}
            >
              Atrasadas ({fees.filter((f) => f.status === 'overdue').length})
            </button>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 dark:bg-gray-900/50 border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th
                className="px-4 py-3 text-left cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                onClick={() => handleSort('numero_cuota')}
              >
                <div className="flex items-center gap-1 text-xs font-medium text-gray-700 dark:text-gray-300 uppercase tracking-wider">
                  Cuota #
                  <SortIcon field="numero_cuota" />
                </div>
              </th>
              {showStudentColumn && (
                <th
                  className="px-4 py-3 text-left cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                  onClick={() => handleSort('student_name')}
                >
                  <div className="flex items-center gap-1 text-xs font-medium text-gray-700 dark:text-gray-300 uppercase tracking-wider">
                    Estudiante
                    <SortIcon field="student_name" />
                  </div>
                </th>
              )}
              <th
                className="px-4 py-3 text-left cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                onClick={() => handleSort('amount')}
              >
                <div className="flex items-center gap-1 text-xs font-medium text-gray-700 dark:text-gray-300 uppercase tracking-wider">
                  Monto
                  <SortIcon field="amount" />
                </div>
              </th>
              <th
                className="px-4 py-3 text-left cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                onClick={() => handleSort('due_date')}
              >
                <div className="flex items-center gap-1 text-xs font-medium text-gray-700 dark:text-gray-300 uppercase tracking-wider">
                  Vencimiento
                  <SortIcon field="due_date" />
                </div>
              </th>
              <th
                className="px-4 py-3 text-left cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                onClick={() => handleSort('status')}
              >
                <div className="flex items-center gap-1 text-xs font-medium text-gray-700 dark:text-gray-300 uppercase tracking-wider">
                  Estado
                  <SortIcon field="status" />
                </div>
              </th>
              <th
                className="px-4 py-3 text-left cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                onClick={() => handleSort('payment_date')}
              >
                <div className="flex items-center gap-1 text-xs font-medium text-gray-700 dark:text-gray-300 uppercase tracking-wider">
                  Fecha Pago
                  <SortIcon field="payment_date" />
                </div>
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
            {processedFees.map((fee) => (
              <tr
                key={fee.id}
                className={`transition-colors ${getRowClassName(fee.status || '')}`}
                onClick={() => onRowClick?.(fee)}
              >
                <td className="px-4 py-3 whitespace-nowrap">
                  <span className="text-sm font-medium text-gray-900 dark:text-white">
                    {fee.numero_cuota || '-'}
                  </span>
                </td>
                {showStudentColumn && (
                  <td className="px-4 py-3 whitespace-nowrap">
                    <div className="flex flex-col">
                      <span className="text-sm font-medium text-gray-900 dark:text-white">
                        {fee.student?.whole_name || fee.student?.first_name || 'Sin nombre'}
                      </span>
                      {fee.student?.curso && (
                        <span className="text-xs text-gray-500 dark:text-gray-400">
                          {fee.student.curso}
                        </span>
                      )}
                    </div>
                  </td>
                )}
                <td className="px-4 py-3 whitespace-nowrap">
                  <span className="text-sm font-semibold text-gray-900 dark:text-white">
                    {formatCurrency(Number(fee.amount || 0))}
                  </span>
                </td>
                <td className="px-4 py-3 whitespace-nowrap">
                  <span className="text-sm text-gray-700 dark:text-gray-300">
                    {formatDate(fee.due_date)}
                  </span>
                </td>
                <td className="px-4 py-3 whitespace-nowrap">
                  {getStatusBadge(fee.status || '')}
                </td>
                <td className="px-4 py-3 whitespace-nowrap">
                  <span className="text-sm text-gray-700 dark:text-gray-300">
                    {fee.payment_date ? formatDate(fee.payment_date) : '-'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Results count */}
      {processedFees.length === 0 && statusFilter !== 'all' && (
        <div className="px-4 py-6 text-center">
          <p className="text-sm text-gray-500 dark:text-gray-400">
            No hay cuotas con el filtro seleccionado.
          </p>
        </div>
      )}

      {processedFees.length > 0 && (
        <div className="px-4 py-3 border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/50">
          <p className="text-xs text-gray-600 dark:text-gray-400">
            Mostrando {processedFees.length} de {fees.length} cuotas
          </p>
        </div>
      )}
    </div>
  );
};

export default FeeTable;
