import React, { useState, useEffect, forwardRef } from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';

const COLORS = ['#4CAF50', '#FFC107', '#FF5252'];

const CustomTooltip = ({ active, payload }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-dark-card p-3 border border-gray-100 dark:border-gray-800 rounded-lg shadow-lg">
        <p className="text-sm font-medium text-gray-900 dark:text-white">
          {payload[0].name}
        </p>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          ${payload[0].value.toLocaleString()} ({payload[0].payload.percentage}%)
        </p>
      </div>
    );
  }
  return null;
};

export const PaymentStatusChart = forwardRef(({ data, loading }, ref) => {
  const [chartData, setChartData] = useState([]);

  useEffect(() => {
    if (!loading && data && data.length > 0) {
      const processedData = processPaymentStatus(data);
      setChartData(processedData);
    } else {
      setChartData([]);
    }
  }, [data, loading]);

  const processPaymentStatus = (payments) => {
    const statusTotals = payments.reduce((acc, payment) => {
      const status = payment.status || 'unknown';
      const amount = parseFloat(payment.amount || 0);
      acc[status] = (acc[status] || 0) + amount;
      return acc;
    }, {});

    const total = Object.values(statusTotals).reduce((a, b) => a + b, 0);
    
    if (total === 0) return [];

    return [
      {
        name: 'Pagado',
        value: statusTotals.paid || 0,
        percentage: ((statusTotals.paid || 0) / total * 100).toFixed(1)
      },
      {
        name: 'Pendiente',
        value: statusTotals.pending || 0,
        percentage: ((statusTotals.pending || 0) / total * 100).toFixed(1)
      },
      {
        name: 'Vencido',
        value: statusTotals.overdue || 0,
        percentage: ((statusTotals.overdue || 0) / total * 100).toFixed(1)
      }
    ].filter(item => item.value > 0);
  };

  if (loading) {
    return (
      <div className="h-[300px] flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (chartData.length === 0) {
    return (
      <div className="h-[300px] flex items-center justify-center text-gray-500 dark:text-gray-400">
        No hay datos disponibles para mostrar.
      </div>
    );
  }

  return (
    <div className="h-[300px]" ref={ref}>
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={80}
            paddingAngle={5}
            dataKey="value"
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip content={<CustomTooltip />} />
          <Legend
            verticalAlign="bottom"
            height={36}
            formatter={(value, entry) => (
              <span className="text-sm text-gray-700 dark:text-gray-300">
                {value} ({entry.payload.percentage}%)
              </span>
            )}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
});

PaymentStatusChart.displayName = 'PaymentStatusChart';