import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardContent } from '../../ui/Card';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';
import { supabase } from '../../../services/supabase';
import toast from 'react-hot-toast';

const COLORS = ['#ef4444', '#eab308', '#3b82f6'];
const RANGES = [
  { min: 0, max: 100000, label: '< $100.000' },
  { min: 100000, max: 500000, label: '$100.000 - $500.000' },
  { min: 500000, max: Infinity, label: '> $500.000' }
];

const CustomTooltip = ({ active, payload }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-dark-card p-3 border border-gray-100 dark:border-gray-800 rounded-lg shadow-lg">
        <p className="text-sm font-medium text-gray-900 dark:text-white">
          {payload[0].name}
        </p>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          {payload[0].value} deudores ({payload[0].payload.percentage}%)
        </p>
      </div>
    );
  }
  return null;
};

export function DebtDistributionChart() {
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
        .select(`
          amount,
          status,
          student:students (
            id
          )
        `)
        .in('status', ['pending', 'overdue']);

      if (error) throw error;

      // Calculate total debt per student
      const debtByStudent = fees.reduce((acc, fee) => {
        const studentId = fee.student.id;
        acc[studentId] = (acc[studentId] || 0) + parseFloat(fee.amount);
        return acc;
      }, {});

      // Group students by debt range
      const distribution = RANGES.map(range => ({
        name: range.label,
        value: Object.values(debtByStudent).filter(
          debt => debt >= range.min && debt < range.max
        ).length
      }));

      // Calculate percentages
      const total = distribution.reduce((sum, item) => sum + item.value, 0);
      distribution.forEach(item => {
        item.percentage = ((item.value / total) * 100).toFixed(1);
      });

      setData(distribution);
    } catch (err) {
      console.error('Error fetching debt distribution data:', err);
      toast.error('Error al cargar la distribución de deuda');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <h2 className="text-gray-900 dark:text-white text-lg font-semibold">
            Distribución de Deuda
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
          Distribución de Deuda
        </h2>
      </CardHeader>
      <CardContent>
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
      </CardContent>
    </Card>
  );
}