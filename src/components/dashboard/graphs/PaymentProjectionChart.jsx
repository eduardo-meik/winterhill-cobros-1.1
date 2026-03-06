import React, { useMemo } from 'react';
import { Card, CardHeader, CardContent } from '../../ui/Card';
import { ChartSkeleton } from '../../ui/Skeleton';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useFeesQuery } from '../../../hooks/queries/useFeesQuery';
import { format, parseISO, startOfMonth, addMonths } from 'date-fns';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-dark-card p-3 border border-gray-100 dark:border-gray-800 rounded-lg shadow-lg">
        <p className="text-sm font-medium text-gray-900 dark:text-white">{label}</p>
        <div className="mt-1 space-y-1">
          <p className="text-sm">
            <span className="inline-block w-3 h-3 rounded-sm bg-primary mr-2"></span>
            Proyectado: ${payload[0].value.toLocaleString()}
          </p>
          {payload[1] && (
            <p className="text-sm">
              <span className="inline-block w-3 h-3 rounded-sm bg-emerald-500 mr-2"></span>
              Real: ${payload[1].value.toLocaleString()}
            </p>
          )}
        </div>
      </div>
    );
  }
  return null;
};

export function PaymentProjectionChart({ academicYear }) {
  const { data: fees = [], isLoading: loading } = useFeesQuery();

  const data = useMemo(() => {
    const now = new Date();
    const monthlyData = {};

    for (let i = 0; i < 6; i++) {
      const monthDate = addMonths(now, i);
      const monthKey = startOfMonth(monthDate).toISOString();
      monthlyData[monthKey] = {
        month: format(monthDate, 'MMM yyyy'),
        projected: 0,
        actual: 0
      };
    }

    fees.forEach(fee => {
      const dueDate = parseISO(fee.due_date);
      const monthKey = startOfMonth(dueDate).toISOString();
      if (monthlyData[monthKey]) {
        const amount = parseFloat(fee.amount);
        monthlyData[monthKey].projected += amount;
        if (fee.status === 'paid') {
          monthlyData[monthKey].actual += amount;
        }
      }
    });

    return Object.values(monthlyData);
  }, [fees]);

  if (loading) {
    return <ChartSkeleton title="Proyección de Pagos" />;
  }

  return (
    <Card>
      <CardHeader>
        <h2 className="text-gray-900 dark:text-white text-lg font-semibold">
          Proyección de Pagos
        </h2>
      </CardHeader>
      <CardContent>
        <div className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-gray-200 dark:stroke-gray-700" />
              <XAxis
                dataKey="month"
                axisLine={false}
                tickLine={false}
                className="text-gray-600 dark:text-gray-400"
              />
              <YAxis
                axisLine={false}
                tickLine={false}
                tickFormatter={(value) => `$${value.toLocaleString()}`}
                className="text-gray-600 dark:text-gray-400"
              />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="projected" fill="#4f46e5" radius={[4, 4, 0, 0]} />
              <Bar dataKey="actual" fill="#10b981" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}