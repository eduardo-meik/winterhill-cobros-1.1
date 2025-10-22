import React, { useMemo } from 'react';
import {
  CalendarIcon,
  BanknotesIcon,
  ReceiptRefundIcon,
  DocumentTextIcon,
  UserCircleIcon,
} from '@heroicons/react/24/outline';
import { CheckCircleIcon } from '@heroicons/react/24/solid';
import { Fee, formatCurrency, formatDate } from '../../services/feeService';

interface PaymentHistoryProps {
  fees: Fee[];
  title?: string;
  limit?: number;
  showStudentName?: boolean;
  className?: string;
}

export const PaymentHistory: React.FC<PaymentHistoryProps> = ({
  fees,
  title = 'Historial de Pagos',
  limit,
  showStudentName = true,
  className = '',
}) => {
  // Filter and sort paid fees by payment date (most recent first)
  const paymentHistory = useMemo(() => {
    const paidFees = fees
      .filter((fee) => fee.status === 'paid' && fee.payment_date)
      .sort((a, b) => {
        const dateA = new Date(a.payment_date!).getTime();
        const dateB = new Date(b.payment_date!).getTime();
        return dateB - dateA; // Most recent first
      });

    return limit ? paidFees.slice(0, limit) : paidFees;
  }, [fees, limit]);

  const getPaymentMethodLabel = (method: string | null) => {
    if (!method) return 'No especificado';
    switch (method.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia';
      case 'cheque':
        return 'Cheque';
      case 'tarjeta':
        return 'Tarjeta';
      default:
        return method;
    }
  };

  if (paymentHistory.length === 0) {
    return (
      <div className={`bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6 ${className}`}>
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          {title}
        </h3>
        <div className="text-center py-8">
          <ReceiptRefundIcon className="h-12 w-12 text-gray-400 dark:text-gray-500 mx-auto mb-3" />
          <p className="text-sm text-gray-500 dark:text-gray-400">
            No hay pagos registrados todavía.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className={`bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden ${className}`}>
      <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
          {title}
        </h3>
        {limit && paymentHistory.length >= limit && (
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Mostrando los {limit} pagos más recientes
          </p>
        )}
      </div>

      <div className="divide-y divide-gray-200 dark:divide-gray-700">
        {paymentHistory.map((fee) => (
          <div
            key={fee.id}
            className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
          >
            <div className="flex items-start gap-4">
              {/* Success Icon */}
              <div className="flex-shrink-0 mt-1">
                <div className="h-10 w-10 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
                  <CheckCircleIcon className="h-6 w-6 text-green-600 dark:text-green-400" />
                </div>
              </div>

              {/* Payment Details */}
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-4 mb-2">
                  <div>
                    <h4 className="text-sm font-semibold text-gray-900 dark:text-white">
                      Cuota #{fee.numero_cuota || '-'}
                      {showStudentName && fee.student?.whole_name && (
                        <span className="text-gray-500 dark:text-gray-400 font-normal ml-2">
                          - {fee.student.whole_name}
                        </span>
                      )}
                    </h4>
                    <div className="flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400 mt-1">
                      <CalendarIcon className="h-3.5 w-3.5" />
                      Pagado el {formatDate(fee.payment_date!)}
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <div className="text-lg font-bold text-green-700 dark:text-green-400">
                      {formatCurrency(Number(fee.amount || 0))}
                    </div>
                  </div>
                </div>

                {/* Payment Information Grid */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mt-3">
                  {/* Payment Method */}
                  <div className="flex items-start gap-2">
                    <BanknotesIcon className="h-4 w-4 text-gray-400 dark:text-gray-500 mt-0.5 flex-shrink-0" />
                    <div className="min-w-0">
                      <div className="text-xs text-gray-500 dark:text-gray-400">Método</div>
                      <div className="text-sm text-gray-900 dark:text-white truncate">
                        {getPaymentMethodLabel(fee.payment_method)}
                      </div>
                    </div>
                  </div>

                  {/* Boleta Number */}
                  {fee.num_boleta && (
                    <div className="flex items-start gap-2">
                      <ReceiptRefundIcon className="h-4 w-4 text-gray-400 dark:text-gray-500 mt-0.5 flex-shrink-0" />
                      <div className="min-w-0">
                        <div className="text-xs text-gray-500 dark:text-gray-400">N° Boleta</div>
                        <div className="text-sm text-gray-900 dark:text-white truncate">
                          {fee.num_boleta}
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Bank Transaction */}
                  {fee.mov_bancario && (
                    <div className="flex items-start gap-2">
                      <DocumentTextIcon className="h-4 w-4 text-gray-400 dark:text-gray-500 mt-0.5 flex-shrink-0" />
                      <div className="min-w-0">
                        <div className="text-xs text-gray-500 dark:text-gray-400">
                          Mov. Bancario
                        </div>
                        <div className="text-sm text-gray-900 dark:text-white truncate">
                          {fee.mov_bancario}
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Financial Institution */}
                  {fee.institucion_financiera && (
                    <div className="flex items-start gap-2">
                      <UserCircleIcon className="h-4 w-4 text-gray-400 dark:text-gray-500 mt-0.5 flex-shrink-0" />
                      <div className="min-w-0">
                        <div className="text-xs text-gray-500 dark:text-gray-400">
                          Institución
                        </div>
                        <div className="text-sm text-gray-900 dark:text-white truncate">
                          {fee.institucion_financiera}
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                {/* Notes */}
                {fee.notes && (
                  <div className="mt-3 p-2 bg-gray-50 dark:bg-gray-900/50 rounded border border-gray-200 dark:border-gray-700">
                    <div className="text-xs text-gray-500 dark:text-gray-400 mb-1">
                      Notas:
                    </div>
                    <div className="text-sm text-gray-700 dark:text-gray-300">
                      {fee.notes}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Summary footer */}
      <div className="px-6 py-4 bg-gray-50 dark:bg-gray-900/50 border-t border-gray-200 dark:border-gray-700">
        <div className="flex items-center justify-between">
          <span className="text-sm text-gray-600 dark:text-gray-400">
            Total de pagos mostrados
          </span>
          <span className="text-lg font-bold text-gray-900 dark:text-white">
            {formatCurrency(
              paymentHistory.reduce((sum, fee) => sum + Number(fee.amount || 0), 0)
            )}
          </span>
        </div>
        <div className="text-xs text-gray-500 dark:text-gray-400 mt-1 text-right">
          {paymentHistory.length} pago{paymentHistory.length !== 1 ? 's' : ''}
        </div>
      </div>
    </div>
  );
};

export default PaymentHistory;
