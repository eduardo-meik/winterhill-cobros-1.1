import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useAcademicYear } from '../contexts/AcademicYearContext';
import { useNavigate } from 'react-router-dom';
import { Button } from './ui/Button';
import { isStaffRole } from '../constants/roles';
import { StatCard } from './dashboard/StatCard';
import { DebtTrendChart } from './dashboard/graphs/DebtTrendChart';
import { DebtDistributionChart } from './dashboard/graphs/DebtDistributionChart';
import { PaymentProjectionChart } from './dashboard/graphs/PaymentProjectionChart';
import { DebtorsTable } from './dashboard/DebtorsTable';
import { YearComparisonChart } from './dashboard/graphs/YearComparisonChart';
import { StatCardSkeleton } from './ui/Skeleton';
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
  const { academicYear } = useAcademicYear();

  useEffect(() => {
    fetchDashboardData();
  }, [academicYear]);

  // MJ-04: Auto-refresh when tab becomes visible (e.g., user returns from payments page)
  useEffect(() => {
    const handleVisibility = () => {
      if (document.visibilityState === 'visible') fetchDashboardData();
    };
    document.addEventListener('visibilitychange', handleVisibility);
    return () => document.removeEventListener('visibilitychange', handleVisibility);
  }, [academicYear]);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      
      // Fetch fees filtered by academic year
      const { data: fees, error } = await supabase
        .from('fee')
        .select(`
          *,
          student:students (
            id,
            first_name, 
            apellido_paterno,
            curso:cursos!students_curso_fkey(
              nom_curso
            )
          )
        `)
        .eq('year_academico', academicYear);

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
          <div className="flex items-center gap-3">
            <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Dashboard</h1>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-primary/10 text-primary">
              {academicYear}
            </span>
          </div>
          <DashboardActions />
        </div>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 p-4">
          {loading ? (
            <>
              <StatCardSkeleton />
              <StatCardSkeleton />
              <StatCardSkeleton />
              <StatCardSkeleton />
            </>
          ) : (
            <>
              <StatCard 
                title="Deudores Activos" 
                value={metrics.activeDebtors} 
                icon="users"
              />
              <StatCard 
                title="Deuda Total" 
                value={`$${Math.round(metrics.totalDebt).toLocaleString()}`}
                icon="money"
              />
              <StatCard 
                title="Ingresos Proyectados" 
                value={`$${Math.round(metrics.projectedIncome).toLocaleString()}`}
                icon="chart"
              />
              <StatCard 
                title="Tasa de Morosidad" 
                value={`${metrics.delinquencyRate.toFixed(1)}%`}
                change={`${(metrics.delinquencyRate - metrics.previousDelinquencyRate).toFixed(1)}%`}
                changeType={metrics.delinquencyRate < metrics.previousDelinquencyRate ? 'decrease' : 'increase'}
                icon="alert"
              />
            </>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 p-4">
          <div className="lg:col-span-2 space-y-4">
            <DebtTrendChart academicYear={academicYear} />
            <PaymentProjectionChart academicYear={academicYear} />
            <YearComparisonChart academicYear={academicYear} />
          </div>
          
          <div className="space-y-4">
            <DebtDistributionChart academicYear={academicYear} />
            <DebtorsTable academicYear={academicYear} />
          </div>
        </div>
      </div>
    </main>
  );
}

function DashboardActions() {
  const { user } = useAuth();
  const navigate = useNavigate();
  if (!isStaffRole(user?.role)) return null;
  return (
    <div className="flex items-center gap-2">
      <Button
        variant="primary"
        onClick={() => navigate('/matricula')}
        className="shadow-sm"
        title="Ir al asistente de matrícula"
      >
        📝 Ir a Matrícula
      </Button>
    </div>
  );
}