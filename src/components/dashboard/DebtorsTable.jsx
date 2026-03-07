import React, { useMemo } from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { TableSkeleton } from '../ui/Skeleton';
import { useFeesQuery } from '../../hooks/queries/useFeesQuery';
import { format } from 'date-fns';

export function DebtorsTable({ academicYear }) {
  const { data: fees = [], isLoading: loading } = useFeesQuery();

  const debtors = useMemo(() => {
    const pendingFees = fees.filter(f => (f.status === 'pending' || f.status === 'overdue') && f.student);

    const debtByStudent = pendingFees.reduce((acc, fee) => {
      const studentId = fee.student.id;
      if (!acc[studentId]) {
        acc[studentId] = {
          student: fee.student,
          totalDebt: 0,
          overdueCount: 0,
          lastDueDate: null
        };
      }
      acc[studentId].totalDebt += parseFloat(fee.amount);
      if (fee.status === 'overdue') acc[studentId].overdueCount++;
      if (!acc[studentId].lastDueDate || new Date(fee.due_date) > new Date(acc[studentId].lastDueDate)) {
        acc[studentId].lastDueDate = fee.due_date;
      }
      return acc;
    }, {});

    return Object.values(debtByStudent)
      .sort((a, b) => b.totalDebt - a.totalDebt)
      .slice(0, 5);
  }, [fees]);

  return (
    <Card>
      <CardHeader>
        <h2 className="text-gray-900 dark:text-white text-lg font-semibold">
          Top Deudores
        </h2>
      </CardHeader>
      <CardContent>
        {loading ? (
          <TableSkeleton rows={5} cols={2} />
        ) : (
          <div className="space-y-4">
            {debtors.map((debtor) => (
              <div
                key={debtor.student.id}
                className="flex items-center justify-between p-4 rounded-lg bg-gray-50 dark:bg-dark-hover"
              >
                <div>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">
                    {debtor.student.whole_name || `${debtor.student.first_name} ${debtor.student.apellido_paterno}`}
                  </p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {debtor.student.curso?.nom_curso || 'Sin curso'} • {debtor.overdueCount} cuota{debtor.overdueCount !== 1 ? 's' : ''} vencida{debtor.overdueCount !== 1 ? 's' : ''}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-gray-900 dark:text-white">
                    ${Math.round(debtor.totalDebt).toLocaleString()}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">
                    Último vencimiento: {debtor.lastDueDate ? format(new Date(debtor.lastDueDate), 'dd/MM/yyyy') : 'Sin fecha'}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}