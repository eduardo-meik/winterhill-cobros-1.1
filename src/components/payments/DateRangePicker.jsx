import React, { useState, useEffect } from 'react';
import { format, isAfter, isBefore, differenceInDays } from 'date-fns';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Tooltip } from '../ui/Tooltip';

const StatusIndicator = ({ status, daysOverdue }) => {
  const getStatusColor = () => {
    switch (status) {
      case 'paid':
        return 'bg-green-500';
      case 'pending':
        return 'bg-yellow-500';
      case 'overdue':
        return 'bg-red-500';
      default:
        return 'bg-gray-500';
    }
  };

  return (
    <Tooltip
      content={
        status === 'overdue'
          ? `Vencido por ${daysOverdue} días`
          : status === 'paid'
          ? 'Pagado'
          : 'Pendiente'
      }
    >
      <div className={`w-3 h-3 rounded-full ${getStatusColor()}`} />
    </Tooltip>
  );
};

export function DateRangePicker({ onDateRangeChange, onStatusFilterChange }) {
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [payments, setPayments] = useState([]);
  const [sortConfig, setSortConfig] = useState({ key: 'dueDate', direction: 'asc' });

  useEffect(() => {
    if (startDate && endDate) {
      onDateRangeChange?.(startDate, endDate);
    }
  }, [startDate, endDate]);

  const handleStatusChange = (e) => {
    const status = e.target.value;
    setSelectedStatus(status);
    onStatusFilterChange?.(status);
  };

  const handleSort = (key) => {
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  const getSortedPayments = () => {
    const sortedPayments = [...payments];
    return sortedPayments.sort((a, b) => {
      if (sortConfig.key === 'dueDate') {
        return sortConfig.direction === 'asc'
          ? new Date(a.dueDate) - new Date(b.dueDate)
          : new Date(b.dueDate) - new Date(a.dueDate);
      }
      if (sortConfig.key === 'status') {
        return sortConfig.direction === 'asc'
          ? a.status.localeCompare(b.status)
          : b.status.localeCompare(a.status);
      }
      return 0;
    });
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex flex-wrap items-center gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Fecha Inicial
            </label>
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Fecha Final
            </label>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              min={startDate}
              className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Estado
            </label>
            <select
              value={selectedStatus}
              onChange={handleStatusChange}
              className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
            >
              <option value="all">Todos</option>
              <option value="paid">Pagados</option>
              <option value="pending">Pendientes</option>
              <option value="overdue">Vencidos</option>
            </select>
          </div>
        </div>
      </CardHeader>

      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-100 dark:border-gray-800">
                <th
                  className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
                  onClick={() => handleSort('student')}
                >
                  Estudiante
                </th>
                <th className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400">
                  Monto
                </th>
                <th
                  className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
                  onClick={() => handleSort('dueDate')}
                >
                  Fecha Vencimiento
                </th>
                <th
                  className="text-left py-3 px-4 text-sm font-medium text-gray-500 dark:text-gray-400 cursor-pointer"
                  onClick={() => handleSort('status')}
                >
                  Estado
                </th>
              </tr>
            </thead>
            <tbody>
              {getSortedPayments().map((payment) => {
                const daysOverdue = payment.status === 'overdue'
                  ? differenceInDays(new Date(), new Date(payment.dueDate))
                  : 0;

                return (
                  <tr
                    key={payment.id}
                    className="border-b border-gray-100 dark:border-gray-800"
                  >
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-3">
                        <p className="text-sm font-medium text-gray-900 dark:text-white">
                          {payment.student.first_name} {payment.student.last_name}
                        </p>
                      </div>
                    </td>
                    <td className="py-3 px-4">
                      <p className="text-sm text-gray-900 dark:text-white">
                        ${payment.amount.toLocaleString()}
                      </p>
                    </td>
                    <td className="py-3 px-4">
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        {format(new Date(payment.dueDate), 'dd/MM/yyyy')}
                      </p>
                    </td>
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-2">
                        <StatusIndicator
                          status={payment.status}
                          daysOverdue={daysOverdue}
                        />
                        <span className="text-sm text-gray-700 dark:text-gray-300">
                          {payment.status === 'paid'
                            ? 'Pagado'
                            : payment.status === 'pending'
                            ? 'Pendiente'
                            : `Vencido (${daysOverdue} días)`}
                        </span>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>
  );
}