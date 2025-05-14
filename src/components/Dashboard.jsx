import React, { useState, useEffect } from 'react';
import { StatCard } from './dashboard/StatCard';
import { DebtTrendChart } from './dashboard/graphs/DebtTrendChart';
import { DebtDistributionChart } from './dashboard/graphs/DebtDistributionChart';
import { PaymentProjectionChart } from './dashboard/graphs/PaymentProjectionChart';
import { DebtorsTable } from './dashboard/DebtorsTable';
import { supabase } from '../services/supabase';
import toast from 'react-hot-toast';
import { format, subMonths } from 'date-fns';

export default function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [metrics, setMetrics] = useState({
    activeDebtors: 0,
    totalDebt: 0,
    projectedIncome: 0,
    delinquencyRate: 0,
    previousDelinquencyRate: 0
  });

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      
      // Fetch all fees
      const { data: fees, error } = await supabase
        .from('fee')
        .select(`
          *,
          student:students!inner (
            id,
            first_name, 
            apellido_paterno,
            curso:cursos!students_curso_fkey(
              nom_curso
            )
          )
        `);

      if (error) throw error;

      // Calculate metrics
      const now = new Date();
      const lastMonth = subMonths(now, 1);
      
      const activeDebtors = new Set(
        fees.filter(f => f.status !== 'paid').map(f => f.student_id)
      ).size;

      const totalDebt = fees
        .filter(f => f.status !== 'paid')
        .reduce((sum, fee) => sum + parseFloat(fee.amount), 0);

      const projectedIncome = fees
        .filter(f => f.status === 'pending')
        .reduce((sum, fee) => sum + parseFloat(fee.amount), 0);

      const currentOverdue = fees.filter(f => f.status === 'overdue').length;
      const previousOverdue = fees.filter(f => 
        f.status === 'overdue' && 
        new Date(f.due_date) <= lastMonth
      ).length;

      const delinquencyRate = (currentOverdue / fees.length) * 100;
      const previousDelinquencyRate = (previousOverdue / fees.length) * 100;

      setMetrics({
        activeDebtors,
        totalDebt,
        projectedIncome,
        delinquencyRate,
        previousDelinquencyRate
      });

    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      toast.error('Error al cargar los datos del dashboard');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        <div className="flex flex-wrap justify-between gap-3 p-4">
          <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Dashboard</h1>
        </div>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 p-4">
          <StatCard 
            title="Deudores Activos" 
            value={loading ? '...' : metrics.activeDebtors} 
            icon="users"
          />
          <StatCard 
            title="Deuda Total" 
            value={loading ? '...' : `$${Math.round(metrics.totalDebt).toLocaleString()}`}
            icon="money"
          />
          <StatCard 
            title="Ingresos Proyectados" 
            value={loading ? '...' : `$${Math.round(metrics.projectedIncome).toLocaleString()}`}
            icon="chart"
          />
          <StatCard 
            title="Tasa de Morosidad" 
            value={loading ? '...' : `${metrics.delinquencyRate.toFixed(1)}%`}
            change={`${(metrics.delinquencyRate - metrics.previousDelinquencyRate).toFixed(1)}%`}
            changeType={metrics.delinquencyRate < metrics.previousDelinquencyRate ? 'decrease' : 'increase'}
            icon="alert"
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 p-4">
          <div className="lg:col-span-2 space-y-4">
            <DebtTrendChart />
            <PaymentProjectionChart />
          </div>
          
          <div className="space-y-4">
            <DebtDistributionChart />
            <DebtorsTable />
          </div>
        </div>
      </div>
    </main>
  );
}