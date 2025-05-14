import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardContent } from '../../ui/Card';
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
            <span className="inline-block w-3 h-3 rounded-sm bg-red-500 mr-2"></span>
            Vencido: ${payload[0].value.toLocaleString()}
          </p>
          <p className="text-sm">
            <span className="inline-block w-3 h-3 rounded-sm bg-yellow-500 mr-2"></span>
            Pendiente: ${payload[1].value.toLocaleString()}
          </p>
        </div>
      </div>
    );
  }
  return null;
};

export function DebtTrendChart() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);

      const { data: fees, error } = await supabase
        .from('fee')
        .select('amount, status, due_date')
        .in('status', ['pending', 'overdue'])
        .order('due_date', { ascending: true });

      if (error) throw error;

      const monthlyData = fees.reduce((acc, fee) => {
        const monthKey = startOfMonth(parseISO(fee.due_date)).toISOString();
        if (!acc[monthKey]) {
          acc[monthKey] = {
            month: format(parseISO(fee.due_date), 'MMM yyyy'),
            overdue: 0,
            pending: 0
          };
        }
        
        const amount = parseFloat(fee.amount);
        if (fee.status === 'overdue') {
          acc[monthKey].overdue += amount;
        } else {
          acc[monthKey].pending += amount;
        }
        
        return acc;
      }, {});

      setData(Object.values(monthlyData));
    } catch (err) {
      console.error('Error fetching debt trend data:', err);
      toast.error('Error al cargar los datos de tendencia de deuda');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <h2 className="text-gray-900 dark:text-white text-lg font-semibold">
            Tendencia de Deuda
          </h2>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <h2 className="text-gray-900 dark:text-white text-lg font-semibold">
          Tendencia de Deuda
        </h2>
      </CardHeader>
      <CardContent>
        <div className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="overdueGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#ef4444" stopOpacity={0.2}/>
                  <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                </linearGradient>
                <linearGradient id="pendingGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#eab308" stopOpacity={0.2}/>
                  <stop offset="95%" stopColor="#eab308" stopOpacity={0}/>
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
                dataKey="overdue"
                stackId="1"
                stroke="#ef4444"
                fill="url(#overdueGradient)"
              />
              <Area
                type="monotone"
                dataKey="pending"
                stackId="1"
                stroke="#eab308"
                fill="url(#pendingGradient)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}