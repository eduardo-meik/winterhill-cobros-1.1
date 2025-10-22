import React, { useState } from 'react';
import {
  ChevronDownIcon,
  ChevronUpIcon,
  UserCircleIcon,
  AcademicCapIcon,
  IdentificationIcon,
  CalendarIcon,
} from '@heroicons/react/24/outline';
import { CheckCircleIcon, ClockIcon, ExclamationTriangleIcon } from '@heroicons/react/24/solid';
import { Fee, formatCurrency, getFeesByStatus } from '../../services/feeService';

interface Student {
  id: string;
  first_name: string;
  apellido_paterno: string;
  apellido_materno: string | null;
  whole_name: string | null;
  run: string;
  curso: string;
  fecha_nacimiento?: string;
  direccion?: string;
  comuna?: string;
  telefono?: string;
  email?: string;
}

interface StudentCardProps {
  student: Student;
  fees: Fee[];
  defaultExpanded?: boolean;
  className?: string;
}

export const StudentCard: React.FC<StudentCardProps> = ({
  student,
  fees,
  defaultExpanded = false,
  className = '',
}) => {
  const [isExpanded, setIsExpanded] = useState(defaultExpanded);

  // Calculate fee statistics
  const paidFees = getFeesByStatus(fees, 'paid');
  const pendingFees = getFeesByStatus(fees, 'pending');
  const overdueFees = getFeesByStatus(fees, 'overdue');

  const totalPaid = paidFees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);
  const totalPending = pendingFees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);
  const totalOverdue = overdueFees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);
  const grandTotal = totalPaid + totalPending + totalOverdue;

  const displayName = student.whole_name || `${student.first_name} ${student.apellido_paterno}`;

  // Determine overall status
  const getOverallStatus = () => {
    if (overdueFees.length > 0) return 'overdue';
    if (pendingFees.length > 0) return 'pending';
    return 'paid';
  };

  const status = getOverallStatus();

  const getStatusIcon = () => {
    switch (status) {
      case 'paid':
        return <CheckCircleIcon className="h-5 w-5 text-green-600 dark:text-green-400" />;
      case 'pending':
        return <ClockIcon className="h-5 w-5 text-yellow-600 dark:text-yellow-400" />;
      case 'overdue':
        return <ExclamationTriangleIcon className="h-5 w-5 text-red-600 dark:text-red-400" />;
      default:
        return null;
    }
  };

  const getStatusText = () => {
    switch (status) {
      case 'paid':
        return 'Al día';
      case 'pending':
        return 'Cuotas pendientes';
      case 'overdue':
        return 'Cuotas atrasadas';
      default:
        return '-';
    }
  };

  const getStatusColor = () => {
    switch (status) {
      case 'paid':
        return 'border-green-200 dark:border-green-800 bg-green-50/50 dark:bg-green-900/10';
      case 'pending':
        return 'border-yellow-200 dark:border-yellow-800 bg-yellow-50/50 dark:bg-yellow-900/10';
      case 'overdue':
        return 'border-red-200 dark:border-red-800 bg-red-50/50 dark:bg-red-900/10';
      default:
        return 'border-gray-200 dark:border-gray-700';
    }
  };

  return (
    <div
      className={`bg-white dark:bg-gray-800 border ${getStatusColor()} rounded-lg overflow-hidden transition-all ${className}`}
    >
      {/* Header - Always visible */}
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
      >
        <div className="flex items-center gap-4">
          {/* Avatar placeholder */}
          <div className="flex-shrink-0">
            <UserCircleIcon className="h-12 w-12 text-gray-400 dark:text-gray-500" />
          </div>

          {/* Student info */}
          <div className="text-left">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              {displayName}
            </h3>
            <div className="flex items-center gap-3 mt-1">
              <div className="flex items-center gap-1 text-sm text-gray-600 dark:text-gray-400">
                <AcademicCapIcon className="h-4 w-4" />
                {student.curso}
              </div>
              <div className="flex items-center gap-1 text-sm text-gray-600 dark:text-gray-400">
                <IdentificationIcon className="h-4 w-4" />
                {student.run}
              </div>
            </div>
          </div>
        </div>

        {/* Status and expand icon */}
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            {getStatusIcon()}
            <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
              {getStatusText()}
            </span>
          </div>
          {isExpanded ? (
            <ChevronUpIcon className="h-5 w-5 text-gray-500 dark:text-gray-400" />
          ) : (
            <ChevronDownIcon className="h-5 w-5 text-gray-500 dark:text-gray-400" />
          )}
        </div>
      </button>

      {/* Expandable content */}
      {isExpanded && (
        <div className="px-6 pb-4 border-t border-gray-200 dark:border-gray-700">
          {/* Fee Summary Section */}
          <div className="pt-4 pb-4 border-b border-gray-200 dark:border-gray-700">
            <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">
              Resumen de Aranceles
            </h4>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              <div className="bg-gray-50 dark:bg-gray-900/50 rounded-lg p-3">
                <div className="text-xs text-gray-600 dark:text-gray-400 mb-1">Total</div>
                <div className="text-lg font-bold text-gray-900 dark:text-white">
                  {formatCurrency(grandTotal)}
                </div>
                <div className="text-xs text-gray-500 dark:text-gray-500 mt-1">
                  {fees.length} cuota{fees.length !== 1 ? 's' : ''}
                </div>
              </div>
              <div className="bg-green-50 dark:bg-green-900/20 rounded-lg p-3">
                <div className="text-xs text-green-700 dark:text-green-400 mb-1">Pagadas</div>
                <div className="text-lg font-bold text-green-700 dark:text-green-300">
                  {formatCurrency(totalPaid)}
                </div>
                <div className="text-xs text-green-600 dark:text-green-500 mt-1">
                  {paidFees.length} cuota{paidFees.length !== 1 ? 's' : ''}
                </div>
              </div>
              <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-3">
                <div className="text-xs text-yellow-700 dark:text-yellow-400 mb-1">Pendientes</div>
                <div className="text-lg font-bold text-yellow-700 dark:text-yellow-300">
                  {formatCurrency(totalPending)}
                </div>
                <div className="text-xs text-yellow-600 dark:text-yellow-500 mt-1">
                  {pendingFees.length} cuota{pendingFees.length !== 1 ? 's' : ''}
                </div>
              </div>
              <div className="bg-red-50 dark:bg-red-900/20 rounded-lg p-3">
                <div className="text-xs text-red-700 dark:text-red-400 mb-1">Atrasadas</div>
                <div className="text-lg font-bold text-red-700 dark:text-red-300">
                  {formatCurrency(totalOverdue)}
                </div>
                <div className="text-xs text-red-600 dark:text-red-500 mt-1">
                  {overdueFees.length} cuota{overdueFees.length !== 1 ? 's' : ''}
                </div>
              </div>
            </div>
          </div>

          {/* Student Details Section */}
          <div className="pt-4">
            <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">
              Información del Estudiante
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {student.fecha_nacimiento && (
                <div className="flex items-start gap-2">
                  <CalendarIcon className="h-5 w-5 text-gray-400 dark:text-gray-500 mt-0.5" />
                  <div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">
                      Fecha de Nacimiento
                    </div>
                    <div className="text-sm text-gray-900 dark:text-white">
                      {new Date(student.fecha_nacimiento).toLocaleDateString('es-CL')}
                    </div>
                  </div>
                </div>
              )}
              {student.direccion && (
                <div className="flex items-start gap-2">
                  <div className="h-5 w-5 text-gray-400 dark:text-gray-500 mt-0.5">📍</div>
                  <div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">Dirección</div>
                    <div className="text-sm text-gray-900 dark:text-white">
                      {student.direccion}
                      {student.comuna && `, ${student.comuna}`}
                    </div>
                  </div>
                </div>
              )}
              {student.telefono && (
                <div className="flex items-start gap-2">
                  <div className="h-5 w-5 text-gray-400 dark:text-gray-500 mt-0.5">📞</div>
                  <div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">Teléfono</div>
                    <div className="text-sm text-gray-900 dark:text-white">
                      {student.telefono}
                    </div>
                  </div>
                </div>
              )}
              {student.email && (
                <div className="flex items-start gap-2">
                  <div className="h-5 w-5 text-gray-400 dark:text-gray-500 mt-0.5">✉️</div>
                  <div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">Email</div>
                    <div className="text-sm text-gray-900 dark:text-white">
                      {student.email}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default StudentCard;
