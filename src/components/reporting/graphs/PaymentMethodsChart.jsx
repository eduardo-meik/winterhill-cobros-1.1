import React, { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { supabase } from '../../../services/supabase';
import toast from 'react-hot-toast';

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

export function PaymentMethodsChart({ dateRange, filters = {} }) {
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
        .select('amount, payment_method')
        .not('payment_method', 'is', null);

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

      const methodTotals = payments.reduce((acc, payment) => {
        const method = payment.payment_method || 'No especificado';
        const amount = parseFloat(payment.amount);
        acc[method] = (acc[method] || 0) + amount;
        return acc;
      }, {});

      const chartData = Object.entries(methodTotals).map(([method, total]) => ({
        method: method.charAt(0).toUpperCase() + method.slice(1),
        total
      }));

      setData(chartData.sort((a, b) => b.total - a.total));
    } catch (err) {
      console.error('Error fetching payment methods data:', err);
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
        <BarChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
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
}