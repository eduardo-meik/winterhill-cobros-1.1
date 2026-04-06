import React, { useMemo } from 'react';
import { Dialog } from '@headlessui/react';
import { format } from 'date-fns';
import clsx from 'clsx';

/**
 * Modal that shows all fees for a specific student in the selected academic year,
 * sorted by due_date descending (newest first).
 */
export function StudentFeesModal({ studentId, studentName, allFees, academicYear, onClose, onViewDetails }) {
  const selectedYear = Number.isFinite(Number(academicYear))
    ? Number(academicYear)
    : new Date().getFullYear();

  const studentFees = useMemo(() => {
    if (!allFees || !studentId) return [];
    return allFees
      .filter(f => f.student_id === studentId && Number(f.year_academico) === selectedYear)
      .sort((a, b) => {
        const da = a.due_date ? new Date(a.due_date).getTime() : 0;
        const db = b.due_date ? new Date(b.due_date).getTime() : 0;
        return db - da; // newest first
      });
  }, [allFees, studentId, selectedYear]);

  const totals = useMemo(() => {
    let total = 0, paid = 0, pending = 0;
    studentFees.forEach(f => {
      const amt = Number(f.amount) || 0;
      total += amt;
      if (f.status === 'paid') paid += amt;
      else pending += amt;
    });
    return { total, paid, pending };
  }, [studentFees]);

  return (
    <Dialog open={!!studentId} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="w-full max-w-2xl rounded-xl bg-white dark:bg-dark-card shadow-xl max-h-[85vh] flex flex-col">
          {/* Header */}
          <div className="flex items-center justify-between p-5 border-b border-gray-200 dark:border-gray-700">
            <div>
              <Dialog.Title className="text-lg font-semibold text-gray-900 dark:text-white">
                Cuotas de {studentName}
              </Dialog.Title>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">
                Año académico {selectedYear} &middot; {studentFees.length} cuota{studentFees.length !== 1 ? 's' : ''}
              </p>
            </div>
            <button
              onClick={onClose}
              className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
              </svg>
            </button>
          </div>

          {/* Summary bar */}
          <div className="grid grid-cols-3 gap-4 px-5 py-3 bg-gray-50 dark:bg-dark-hover text-sm border-b border-gray-200 dark:border-gray-700">
            <div>
              <span className="text-gray-500 dark:text-gray-400">Total</span>
              <p className="font-semibold text-gray-900 dark:text-white">${Math.round(totals.total).toLocaleString()}</p>
            </div>
            <div>
              <span className="text-green-600 dark:text-green-400">Pagado</span>
              <p className="font-semibold text-green-700 dark:text-green-300">${Math.round(totals.paid).toLocaleString()}</p>
            </div>
            <div>
              <span className="text-red-600 dark:text-red-400">Pendiente</span>
              <p className="font-semibold text-red-700 dark:text-red-300">${Math.round(totals.pending).toLocaleString()}</p>
            </div>
          </div>

          {/* Fee list */}
          <div className="flex-1 overflow-y-auto">
            {studentFees.length === 0 ? (
              <p className="text-center text-gray-500 dark:text-gray-400 py-8">
                No hay cuotas registradas para el año {selectedYear}.
              </p>
            ) : (
              <table className="w-full text-sm">
                <thead className="sticky top-0 bg-white dark:bg-dark-card">
                  <tr className="border-b border-gray-200 dark:border-gray-700">
                    <th className="text-left py-2 px-5 font-medium text-gray-500 dark:text-gray-400">Cuota #</th>
                    <th className="text-left py-2 px-3 font-medium text-gray-500 dark:text-gray-400">Monto</th>
                    <th className="text-left py-2 px-3 font-medium text-gray-500 dark:text-gray-400">Estado</th>
                    <th className="text-left py-2 px-3 font-medium text-gray-500 dark:text-gray-400">Vencimiento</th>
                    <th className="text-right py-2 px-5 font-medium text-gray-500 dark:text-gray-400">Acción</th>
                  </tr>
                </thead>
                <tbody>
                  {studentFees.map(fee => (
                    <tr
                      key={fee.id}
                      className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-hover transition-colors"
                    >
                      <td className="py-2.5 px-5 font-medium text-gray-900 dark:text-white">
                        {fee.numero_cuota ?? 'N/A'}
                      </td>
                      <td className="py-2.5 px-3 text-gray-900 dark:text-white">
                        ${fee.amount ? Math.round(fee.amount).toLocaleString() : '0'}
                      </td>
                      <td className="py-2.5 px-3">
                        <span className={clsx(
                          'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                          fee.status === 'paid' && 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
                          fee.status === 'pending' && 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
                          fee.status === 'overdue' && 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
                          fee.status === 'cancelled' && 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
                        )}>
                          {fee.status === 'paid' ? 'Pagado' :
                           fee.status === 'pending' ? 'Pendiente' :
                           fee.status === 'overdue' ? 'Vencido' : 'Anulado'}
                        </span>
                      </td>
                      <td className="py-2.5 px-3 text-gray-500 dark:text-gray-400">
                        {fee.due_date ? format(new Date(fee.due_date), 'dd/MM/yyyy') : '—'}
                      </td>
                      <td className="py-2.5 px-5 text-right">
                        <button
                          onClick={() => onViewDetails(fee)}
                          className="inline-flex items-center gap-1 text-primary hover:text-primary-light text-xs font-medium"
                          title="Registrar pago / Ver detalle"
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                            <path d="M4 4a2 2 0 00-2 2v1h16V6a2 2 0 00-2-2H4z" />
                            <path fillRule="evenodd" d="M18 9H2v5a2 2 0 002 2h12a2 2 0 002-2V9zM4 13a1 1 0 011-1h1a1 1 0 110 2H5a1 1 0 01-1-1zm5-1a1 1 0 100 2h1a1 1 0 100-2H9z" clipRule="evenodd" />
                          </svg>
                          Registrar Pago
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* Footer */}
          <div className="flex justify-end p-4 border-t border-gray-200 dark:border-gray-700">
            <button
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600"
            >
              Cerrar
            </button>
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}
