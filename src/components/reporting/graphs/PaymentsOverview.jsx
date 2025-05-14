import React, { useState, useEffect } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { supabase } from '../../../services/supabase';
import { format, parseISO, startOfMonth, endOfMonth } from 'date-fns';
import toast from 'react-hot-toast';

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

export function PaymentsOverview({ filters = {} }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchData();
  }, [filters]);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      let query = supabase
        .from('fee')
        .select('amount, status, due_date');

      if (filters.status && filters.status !== 'all') {
        query = query.eq('status', filters.status);
      }
      
      if (filters.startDate) {
        query = query.gte('due_date', filters.startDate);
      }
      
      if (filters.endDate) {
        query = query.lte('due_date', filters.endDate);
      }

      const { data: payments, error } = await query;

      if (error) throw error;

      const aggregatedData = aggregatePaymentsByMonth(payments);
      setData(aggregatedData);
    } catch (err) {
      console.error('Error fetching payment data:', err);
      setError('Error al cargar los datos');
      toast.error('Error al cargar los datos');
    } finally {
      setLoading(false);
    }
  };

  const aggregatePaymentsByMonth = (payments) => {
    const monthlyData = {};

    payments.forEach(payment => {
      const monthKey = startOfMonth(parseISO(payment.due_date)).toISOString();
      
      if (!monthlyData[monthKey]) {
        monthlyData[monthKey] = {
          month: format(parseISO(payment.due_date), 'MMM yyyy'),
          paid: 0,
          pending: 0,
          overdue: 0
        };
      }

      const amount = parseFloat(payment.amount);
      
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
      }
    });

    return Object.values(monthlyData);
  };

  if (loading) {
    return (
      <div className="h-[400px] flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="h-[400px] flex items-center justify-center text-red-600 dark:text-red-400">
        {error}
      </div>
    );
  }

  return (
    <div className="h-[400px]">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
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
}