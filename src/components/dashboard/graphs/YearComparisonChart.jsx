import React, { useMemo } from 'react';
import { Card, CardHeader, CardContent } from '../../ui/Card';
import { ChartSkeleton } from '../../ui/Skeleton';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { useFeesQuery } from '../../../hooks/queries/useFeesQuery';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-dark-card p-3 border border-gray-100 dark:border-gray-800 rounded-lg shadow-lg">
        <p className="text-sm font-medium text-gray-900 dark:text-white">{label}</p>
        <div className="mt-1 space-y-1">
          {payload.map((entry, index) => (
            <p key={index} className="text-sm">
              <span className="inline-block w-3 h-3 rounded-sm mr-2" style={{ backgroundColor: entry.color }}></span>
              {entry.name}: ${entry.value.toLocaleString()}
            </p>
          ))}
        </div>
      </div>
    );
  }
  return null;
};

export function YearComparisonChart({ academicYear }) {
  const previousYear = academicYear - 1;

  const { data: currentFees = [], isLoading: loadingCurrent } = useFeesQuery(academicYear);
  const { data: prevFees = [], isLoading: loadingPrev } = useFeesQuery(previousYear);

  const loading = loadingCurrent || loadingPrev;

  const data = useMemo(() => {
    const summarize = (fees) => {
      const paid = fees.filter(f => f.status === 'paid').reduce((s, f) => s + parseFloat(f.amount), 0);
      const pending = fees.filter(f => f.status === 'pending').reduce((s, f) => s + parseFloat(f.amount), 0);
      const overdue = fees.filter(f => f.status === 'overdue').reduce((s, f) => s + parseFloat(f.amount), 0);
      return { paid, pending, overdue };
    };

    const current = summarize(currentFees);
    const prev = summarize(prevFees);

    return [
      { category: 'Pagado', [academicYear]: current.paid, [previousYear]: prev.paid },
      { category: 'Pendiente', [academicYear]: current.pending, [previousYear]: prev.pending },
      { category: 'Vencido', [academicYear]: current.overdue, [previousYear]: prev.overdue },
    ];
  }, [currentFees, prevFees, academicYear, previousYear]);

  if (loading) {
    return <ChartSkeleton title={`Comparativa ${previousYear} vs ${academicYear}`} />;
  }

  return (
    <Card>
      <CardHeader>
        <h2 className="text-gray-900 dark:text-white text-lg font-semibold">
          Comparativa {previousYear} vs {academicYear}
        </h2>
      </CardHeader>
      <CardContent>
        <div className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-gray-200 dark:stroke-gray-700" />
              <XAxis dataKey="category" tick={{ fontSize: 12 }} className="text-gray-600 dark:text-gray-400" />
              <YAxis tickFormatter={(v) => `$${(v / 1000).toFixed(0)}k`} tick={{ fontSize: 12 }} className="text-gray-600 dark:text-gray-400" />
              <Tooltip content={<CustomTooltip />} />
              <Legend />
              <Bar dataKey={previousYear} name={String(previousYear)} fill="#94a3b8" radius={[4, 4, 0, 0]} />
              <Bar dataKey={academicYear} name={String(academicYear)} fill="#6366f1" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
