import React, { useMemo } from 'react';
import {
  CheckCircleIcon,
  ClockIcon,
  ExclamationTriangleIcon,
} from '@heroicons/react/24/solid';
import { Fee, formatCurrency, getFeesByStatus } from '../../services/feeService';

interface FeeSummaryProps {
  fees: Fee[];
  title?: string;
  showPercentages?: boolean;
  className?: string;
}

export const FeeSummary: React.FC<FeeSummaryProps> = ({
  fees,
  title = 'Resumen de Aranceles',
  showPercentages = true,
  className = '',
}) => {
  const summary = useMemo(() => {
    const paidFees = getFeesByStatus(fees, 'paid');
    const pendingFees = getFeesByStatus(fees, 'pending');
    const overdueFees = getFeesByStatus(fees, 'overdue');

    const totalPaid = paidFees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);
    const totalPending = pendingFees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);
    const totalOverdue = overdueFees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);
    const grandTotal = totalPaid + totalPending + totalOverdue;

    return {
      paid: {
        count: paidFees.length,
        amount: totalPaid,
        percentage: grandTotal > 0 ? (totalPaid / grandTotal) * 100 : 0,
      },
      pending: {
        count: pendingFees.length,
        amount: totalPending,
        percentage: grandTotal > 0 ? (totalPending / grandTotal) * 100 : 0,
      },
      overdue: {
        count: overdueFees.length,
        amount: totalOverdue,
        percentage: grandTotal > 0 ? (totalOverdue / grandTotal) * 100 : 0,
      },
      total: {
        count: fees.length,
        amount: grandTotal,
      },
    };
  }, [fees]);

  if (fees.length === 0) {
    return (
      <div className={`bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6 ${className}`}>
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          {title}
        </h3>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          No hay aranceles registrados para el período actual.
        </p>
      </div>
    );
  }

  return (
    <div className={`bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6 ${className}`}>
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
        {title}
      </h3>

      {/* Summary Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        {/* Paid */}
        <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-2">
            <CheckCircleIcon className="h-5 w-5 text-green-600 dark:text-green-400" />
            <span className="text-sm font-medium text-green-900 dark:text-green-100">
              Pagadas
            </span>
          </div>
          <div className="text-2xl font-bold text-green-700 dark:text-green-300">
            {formatCurrency(summary.paid.amount)}
          </div>
          <div className="text-xs text-green-600 dark:text-green-400 mt-1">
            {summary.paid.count} cuota{summary.paid.count !== 1 ? 's' : ''}
            {showPercentages && ` (${Math.round(summary.paid.percentage)}%)`}
          </div>
        </div>

        {/* Pending */}
        <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-2">
            <ClockIcon className="h-5 w-5 text-yellow-600 dark:text-yellow-400" />
            <span className="text-sm font-medium text-yellow-900 dark:text-yellow-100">
              Pendientes
            </span>
          </div>
          <div className="text-2xl font-bold text-yellow-700 dark:text-yellow-300">
            {formatCurrency(summary.pending.amount)}
          </div>
          <div className="text-xs text-yellow-600 dark:text-yellow-400 mt-1">
            {summary.pending.count} cuota{summary.pending.count !== 1 ? 's' : ''}
            {showPercentages && ` (${Math.round(summary.pending.percentage)}%)`}
          </div>
        </div>

        {/* Overdue */}
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-2">
            <ExclamationTriangleIcon className="h-5 w-5 text-red-600 dark:text-red-400" />
            <span className="text-sm font-medium text-red-900 dark:text-red-100">
              Atrasadas
            </span>
          </div>
          <div className="text-2xl font-bold text-red-700 dark:text-red-300">
            {formatCurrency(summary.overdue.amount)}
          </div>
          <div className="text-xs text-red-600 dark:text-red-400 mt-1">
            {summary.overdue.count} cuota{summary.overdue.count !== 1 ? 's' : ''}
            {showPercentages && ` (${Math.round(summary.overdue.percentage)}%)`}
          </div>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
            Progreso de Pagos
          </span>
          <span className="text-sm text-gray-600 dark:text-gray-400">
            {Math.round(summary.paid.percentage)}% pagado
          </span>
        </div>
        <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-4 overflow-hidden">
          <div className="h-full flex">
            {/* Paid Section */}
            {summary.paid.percentage > 0 && (
              <div
                className="bg-green-600 dark:bg-green-500 transition-all duration-300"
                style={{ width: `${summary.paid.percentage}%` }}
                title={`Pagado: ${formatCurrency(summary.paid.amount)}`}
              />
            )}
            {/* Pending Section */}
            {summary.pending.percentage > 0 && (
              <div
                className="bg-yellow-500 dark:bg-yellow-400 transition-all duration-300"
                style={{ width: `${summary.pending.percentage}%` }}
                title={`Pendiente: ${formatCurrency(summary.pending.amount)}`}
              />
            )}
            {/* Overdue Section */}
            {summary.overdue.percentage > 0 && (
              <div
                className="bg-red-600 dark:bg-red-500 transition-all duration-300"
                style={{ width: `${summary.overdue.percentage}%` }}
                title={`Atrasado: ${formatCurrency(summary.overdue.amount)}`}
              />
            )}
          </div>
        </div>
      </div>

      {/* Total */}
      <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
            Total del año
          </span>
          <span className="text-xl font-bold text-gray-900 dark:text-white">
            {formatCurrency(summary.total.amount)}
          </span>
        </div>
        <div className="text-xs text-gray-500 dark:text-gray-400 mt-1 text-right">
          {summary.total.count} cuota{summary.total.count !== 1 ? 's' : ''} en total
        </div>
      </div>
    </div>
  );
};

export default FeeSummary;
