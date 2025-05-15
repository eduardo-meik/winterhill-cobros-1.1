import React from 'react';
import { format } from 'date-fns';
import clsx from 'clsx';
import { TableContainer } from '../ui/TableContainer';
import { TableHeader } from '../ui/TableHeader';

export function PaymentsTable({
  payments,
  onViewDetails,
  onMarkAsPaid,
  onMarkAsUnpaid,
  onAddNote,
  onEditPayment,
  onDeletePayment,
  loading
}) {
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

  return (
    <div className="overflow-x-auto">
      <TableContainer>
        <TableHeader>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Estudiante</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Cuota número</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Monto</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Porcentaje Beca</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Inst. Financiera</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Estado</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Fecha Vencimiento</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Método de Pago</th>
              <th className="text-right py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">Acciones</th>
            </tr>
        </TableHeader>
          <tbody>
            {payments.map((payment) => (
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
                      </div>
                    </div>
                  </div>
                </td>
                <td className="py-3 px-4">
                  <p className="text-sm text-gray-900 dark:text-white">
                    {payment.numero_cuota || 'N/A'}
                  </p>
                </td>
                <td className="py-3 px-4">
                  <p className="text-sm font-medium text-gray-900 dark:text-white">
                    ${Math.round(payment.amount)?.toLocaleString() ?? '0'}
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
                    payment.status === 'paid' && 'bg-green-100 text-[#008000] dark:bg-green-900/30 dark:text-green-400',
                    payment.status === 'pending' && 'bg-yellow-100 text-[#008000] dark:bg-yellow-900/30 dark:text-yellow-400',
                    payment.status === 'overdue' && 'bg-red-100 text-[#FF0000] dark:bg-red-900/30 dark:text-red-400'
                  )}>
                    {payment.status === 'paid' ? 'Pagado' : payment.status === 'pending' ? 'Pendiente' : 'Vencido'}
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
  );
}