import React, { useState, useEffect, forwardRef } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { format, parseISO, startOfMonth } from 'date-fns';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-dark-card p-3 border border-gray-100 dark:border-gray-800 rounded-lg shadow-lg">
        <p className="text-sm font-medium text-gray-900 dark:text-white">{label}</p>
        <div className="mt-1 space-y-1">
          <p className="text-sm">
            <span className="inline-block w-3 h-3 rounded-sm bg-[#4CAF50] mr-2"></span>
            Pagado: ${payload[0].value.toLocaleString()}
          </p>
          <p className="text-sm">
            <span className="inline-block w-3 h-3 rounded-sm bg-[#FFC107] mr-2"></span>
            Pendiente: ${payload[1].value.toLocaleString()}
          </p>
          <p className="text-sm">
            <span className="inline-block w-3 h-3 rounded-sm bg-[#FF5252] mr-2"></span>
            Vencido: ${payload[2].value.toLocaleString()}
          </p>
        </div>
      </div>
    );
  }
  return null;
};

export const PaymentsOverview = forwardRef(({ data, loading }, ref) => {
  const [chartData, setChartData] = useState([]);

  useEffect(() => {
    if (!loading && data && data.length > 0) {
      const aggregatedData = aggregatePaymentsByMonth(data);
      setChartData(aggregatedData);
    } else {
      setChartData([]);
    }
  }, [data, loading]);

  const aggregatePaymentsByMonth = (payments) => {
    const monthlyData = {};

    payments.forEach(payment => {
      if (!payment.due_date) return;
      
      try {
        const dueDate = new Date(payment.due_date);
        const monthKey = startOfMonth(dueDate).toISOString();
        
        if (!monthlyData[monthKey]) {
          monthlyData[monthKey] = {
            month: format(dueDate, 'MMM yyyy'),
            paid: 0,
            pending: 0,
            overdue: 0
          };
        }

        const amount = parseFloat(payment.amount || 0);
        
        switch (payment.status) {
          case 'paid':
            monthlyData[monthKey].paid += amount;
            break;
          case 'pending':
            monthlyData[monthKey].pending += amount;
            break;
          case 'overdue':
            monthlyData[monthKey].overdue += amount;
            break;
          default:
            break;
        }
      } catch (err) {
        console.error("Error processing date", err, payment.due_date);
      }
    });

    // Convert to array and sort by date
    return Object.values(monthlyData)
      .sort((a, b) => {
        const monthA = new Date(a.month).getTime();
        const monthB = new Date(b.month).getTime();
        return monthA - monthB;
      });
  };

  if (loading) {
    return (
      <div className="h-[400px] flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (chartData.length === 0) {
    return (
      <div className="h-[400px] flex items-center justify-center text-gray-500 dark:text-gray-400">
        No hay datos disponibles para mostrar.
      </div>
    );
  }

  return (
    <div className="h-[400px]" ref={ref}>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={chartData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
          <defs>
            <linearGradient id="paidGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#4CAF50" stopOpacity={0.2}/>
              <stop offset="95%" stopColor="#4CAF50" stopOpacity={0}/>
            </linearGradient>
            <linearGradient id="pendingGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#FFC107" stopOpacity={0.2}/>
              <stop offset="95%" stopColor="#FFC107" stopOpacity={0}/>
            </linearGradient>
            <linearGradient id="overdueGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#FF5252" stopOpacity={0.2}/>
              <stop offset="95%" stopColor="#FF5252" stopOpacity={0}/>
            </linearGradient>
          </defs>
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
          <Area
            type="monotone"
            dataKey="paid"
            name="Pagado"
            stroke="#4CAF50"
            fillOpacity={1}
            fill="url(#paidGradient)"
            stackId="1"
          />
          <Area
            type="monotone"
            dataKey="pending"
            name="Pendiente"
            stroke="#FFC107"
            fillOpacity={1}
            fill="url(#pendingGradient)"
            stackId="1"
          />
          <Area
            type="monotone"
            dataKey="overdue"
            name="Vencido"
            stroke="#FF5252"
            fillOpacity={1}
            fill="url(#overdueGradient)"
            stackId="1"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
});

PaymentsOverview.displayName = 'PaymentsOverview';