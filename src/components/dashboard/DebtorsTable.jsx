import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { supabase } from '../../services/supabase';
import { format } from 'date-fns';
import toast from 'react-hot-toast';

export function DebtorsTable() {
  const [debtors, setDebtors] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchTopDebtors();
  }, []);

  const fetchTopDebtors = async () => {
    try {
      setLoading(true);

      const { data: fees, error } = await supabase
        .from('fee')
        .select(`
          amount,
          status,
          due_date,
          student:students (
            id,
            first_name,
            apellido_paterno,
            curso:cursos!students_curso_fkey(
              nom_curso
            )
          )
        `)
        .in('status', ['pending', 'overdue']);

      if (error) throw error;

      // Aggregate debt by student
      const debtByStudent = fees.reduce((acc, fee) => {
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

      // Convert to array and sort by total debt
      const sortedDebtors = Object.values(debtByStudent)
        .sort((a, b) => b.totalDebt - a.totalDebt)
        .slice(0, 5);

      setDebtors(sortedDebtors);
    } catch (err) {
      console.error('Error fetching top debtors:', err);
      toast.error('Error al cargar los deudores principales');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <h2 className="text-gray-900 dark:text-white text-lg font-semibold">
          Top Deudores
        </h2>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="flex items-center justify-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
          </div>
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
                    Último vencimiento: {format(new Date(debtor.lastDueDate), 'dd/MM/yyyy')}
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