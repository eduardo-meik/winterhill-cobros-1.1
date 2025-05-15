import React, { useState, useEffect, forwardRef } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-dark-card p-3 border border-gray-100 dark:border-gray-800 rounded-lg shadow-lg">
        <p className="text-sm font-medium text-gray-900 dark:text-white">{label}</p>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          ${payload[0].value.toLocaleString()}
        </p>
      </div>
    );
  }
  return null;
};

export const PaymentMethodsChart = forwardRef(({ data, loading }, ref) => {
  const [chartData, setChartData] = useState([]);

  useEffect(() => {
    if (!loading && data && data.length > 0) {
      const processedData = processPaymentMethods(data);
      setChartData(processedData);
    } else {
      setChartData([]);
    }
  }, [data, loading]);

  const processPaymentMethods = (payments) => {
    // Filter only paid payments with a payment method
    const paidPayments = payments.filter(payment => 
      payment.status === 'paid' && payment.payment_method
    );
    
    if (paidPayments.length === 0) return [];

    const methodTotals = paidPayments.reduce((acc, payment) => {
      const method = payment.payment_method || 'No especificado';
      const amount = parseFloat(payment.amount || 0);
      acc[method] = (acc[method] || 0) + amount;
      return acc;
    }, {});

    return Object.entries(methodTotals)
      .map(([method, total]) => ({
        method: method.charAt(0).toUpperCase() + method.slice(1).toLowerCase(),
        total
      }))
      .sort((a, b) => b.total - a.total);
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
        No hay datos de métodos de pago disponibles.
      </div>
    );
  }

  return (
    <div className="h-[300px]" ref={ref}>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={chartData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" className="stroke-gray-200 dark:stroke-gray-700" />
          <XAxis
            dataKey="method"
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
          <Bar
            dataKey="total"
            fill="#4f46e5"
            radius={[4, 4, 0, 0]}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
});

PaymentMethodsChart.displayName = 'PaymentMethodsChart';