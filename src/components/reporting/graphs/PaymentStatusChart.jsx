import React, { useState, useEffect } from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';
import { supabase } from '../../../services/supabase';
import toast from 'react-hot-toast';

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

export function PaymentStatusChart({ dateRange, filters = {} }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchData();
  }, [dateRange, filters]); // Now depends on filters

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Start with base query
      let query = supabase
        .from('fee')
        .select('amount, status');

      // Apply filters from props
      if (filters.status && filters.status !== 'all') {
        query = query.eq('status', filters.status);
      }
      
      if (filters.startDate) {
        query = query.gte('due_date', filters.startDate);
      }
      
      if (filters.endDate) {
        query = query.lte('due_date', filters.endDate);
      }

      // Execute the query
      const { data: payments, error } = await query;

      if (error) throw error;

      const statusTotals = payments.reduce((acc, payment) => {
        const status = payment.status;
        const amount = parseFloat(payment.amount);
        acc[status] = (acc[status] || 0) + amount;
        return acc;
      }, {});

      const total = Object.values(statusTotals).reduce((a, b) => a + b, 0);

      const chartData = [
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
      ];

      setData(chartData);
    } catch (err) {
      console.error('Error fetching payment status data:', err);
      setError('Error al cargar los datos');
      toast.error('Error al cargar los datos');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="h-[300px] flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="h-[300px]">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={80}
            paddingAngle={5}
            dataKey="value"
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={COLORS[index]} />
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
}