/**
 * Fee Service
 * Handles all fee-related data fetching and calculations for the guardian portal
 * Read-only service (no payment mutations)
 */

import { supabase } from './supabase';

export interface Fee {
  id: string;
  created_at: string;
  updated_at: string;
  student_id: string;
  guardian_id: string | null;
  amount: number;
  due_date: string;
  payment_date: string | null;
  status: 'paid' | 'pending' | 'overdue';
  payment_method: string | null;
  num_boleta: string | null;
  mov_bancario: string | null;
  notes: string | null;
  owner_id: string;
  fee_curso: string | null;
  numero_cuota: number | null;
  institucion_financiera: string | null;
  year: number | null;
  year_academico: number | null;
  
  // Joined fields
  student?: {
    id: string;
    first_name: string;
    apellido_paterno: string;
    apellido_materno: string | null;
    whole_name: string | null;
    run: string;
    curso: string;
  };
  curso?: {
    nom_curso: string;
  };
}

export interface FeeStats {
  totalFees: number;
  totalPaid: number;
  totalPending: number;
  totalOverdue: number;
  totalAmount: number;
  nextDueDate: string | null;
  overdueCount: number;
  pendingCount: number;
  paidCount: number;
}

/**
 * Fetch all fees for a guardian's students
 * @param guardianId - Guardian UUID
 * @param year - Academic year (optional, defaults to current year)
 */
export async function fetchGuardianFees(
  guardianId: string,
  year?: number
): Promise<Fee[]> {
  if (!guardianId) {
    throw new Error('Guardian ID is required');
  }

  const currentYear = year || new Date().getFullYear();

  const { data, error } = await supabase
    .from('fee')
    .select(`
      id, student_id, guardian_id, amount, due_date, payment_date,
      status, payment_method, num_boleta, mov_bancario, notes,
      fee_curso, numero_cuota, institucion_financiera, year, year_academico,
      students:student_id (
        id,
        first_name,
        apellido_paterno,
        apellido_materno,
        whole_name,
        run,
        curso,
        cursos:curso(nom_curso)
      )
    `)
    .eq('guardian_id', guardianId)
    .eq('year_academico', currentYear)
    .order('due_date', { ascending: true })
    .order('numero_cuota', { ascending: true });

  if (error) {

    throw error;
  }

  return processFeesWithStatus(data || []);
}

/**
 * Fetch fees for a specific student
 * @param studentId - Student UUID
 * @param year - Academic year (optional, defaults to current year)
 */
export async function fetchStudentFees(
  studentId: string,
  year?: number
): Promise<Fee[]> {
  if (!studentId) {
    throw new Error('Student ID is required');
  }

  const currentYear = year || new Date().getFullYear();

  const { data, error } = await supabase
    .from('fee')
    .select(`
      id, student_id, guardian_id, amount, due_date, payment_date,
      status, payment_method, num_boleta, mov_bancario, notes,
      fee_curso, numero_cuota, institucion_financiera, year, year_academico,
      students:student_id (
        id,
        first_name,
        apellido_paterno,
        apellido_materno,
        whole_name,
        run,
        curso,
        cursos:curso(nom_curso)
      )
    `)
    .eq('student_id', studentId)
    .eq('year_academico', currentYear)
    .order('due_date', { ascending: true })
    .order('numero_cuota', { ascending: true });

  if (error) {

    throw error;
  }

  return processFeesWithStatus(data || []);
}

/**
 * Fetch fees across all years for a guardian (for history view)
 * @param guardianId - Guardian UUID
 */
export async function fetchGuardianFeesAllYears(guardianId: string): Promise<Fee[]> {
  if (!guardianId) {
    throw new Error('Guardian ID is required');
  }

  const { data, error } = await supabase
    .from('fee')
    .select(`
      id, student_id, guardian_id, amount, due_date, payment_date,
      status, payment_method, num_boleta, mov_bancario, notes,
      fee_curso, numero_cuota, institucion_financiera, year, year_academico,
      students:student_id (
        id,
        first_name,
        apellido_paterno,
        apellido_materno,
        whole_name,
        run,
        curso,
        cursos:curso(nom_curso)
      )
    `)
    .eq('guardian_id', guardianId)
    .order('year_academico', { ascending: false })
    .order('due_date', { ascending: true });

  if (error) {
    throw error;
  }

  return processFeesWithStatus(data || []);
}

/**
 * Process fees and compute real-time status based on due_date
 */
function processFeesWithStatus(fees: any[]): Fee[] {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  return fees.map(fee => {
    let computedStatus = fee.status;
    
    // If already paid, keep paid status
    if (fee.status === 'paid' || fee.payment_date) {
      computedStatus = 'paid';
    } else {
      // Otherwise check if overdue
      const dueDate = new Date(fee.due_date);
      dueDate.setHours(0, 0, 0, 0);
      
      if (dueDate < today) {
        computedStatus = 'overdue';
      } else {
        computedStatus = 'pending';
      }
    }

    // Flatten student data
    const student = fee.students ? {
      id: fee.students.id,
      first_name: fee.students.first_name,
      apellido_paterno: fee.students.apellido_paterno,
      apellido_materno: fee.students.apellido_materno,
      whole_name: fee.students.whole_name,
      run: fee.students.run,
      curso: fee.students.curso,
    } : undefined;

    const curso = fee.students?.cursos ? {
      nom_curso: fee.students.cursos.nom_curso
    } : undefined;

    const normalizedYear = fee.year ?? fee.year_academico ?? (fee.due_date ? new Date(fee.due_date).getFullYear() : null);
    const normalizedYearAcademico = fee.year_academico ?? fee.year ?? normalizedYear;

    return {
      ...fee,
      status: computedStatus,
      year: normalizedYear,
      year_academico: normalizedYearAcademico,
      student,
      curso,
    };
  });
}

/**
 * Filter fees by status
 */
export function getFeesByStatus(fees: Fee[], status: 'paid' | 'pending' | 'overdue'): Fee[] {
  return fees.filter(fee => fee.status === status);
}

/**
 * Get upcoming payments within N days
 * @param fees - Array of fees
 * @param days - Number of days to look ahead (default 30)
 */
export function getUpcomingPayments(fees: Fee[], days: number = 30): Fee[] {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const futureDate = new Date(today);
  futureDate.setDate(futureDate.getDate() + days);

  return fees.filter(fee => {
    if (fee.status === 'paid') return false;
    
    const dueDate = new Date(fee.due_date);
    dueDate.setHours(0, 0, 0, 0);
    
    return dueDate >= today && dueDate <= futureDate;
  }).sort((a, b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime());
}

/**
 * Calculate comprehensive fee statistics
 */
export function calculateFeeStats(fees: Fee[]): FeeStats {
  const paidFees = getFeesByStatus(fees, 'paid');
  const pendingFees = getFeesByStatus(fees, 'pending');
  const overdueFees = getFeesByStatus(fees, 'overdue');

  const totalPaid = paidFees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);
  const totalPending = pendingFees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);
  const totalOverdue = overdueFees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);
  const totalAmount = fees.reduce((sum, fee) => sum + Number(fee.amount || 0), 0);

  // Find next due date from pending fees
  const upcomingPayments = [...pendingFees].sort(
    (a, b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime()
  );
  const nextDueDate = upcomingPayments.length > 0 ? upcomingPayments[0].due_date : null;

  return {
    totalFees: fees.length,
    totalPaid,
    totalPending,
    totalOverdue,
    totalAmount,
    nextDueDate,
    overdueCount: overdueFees.length,
    pendingCount: pendingFees.length,
    paidCount: paidFees.length,
  };
}

/**
 * Group fees by student
 */
export function groupFeesByStudent(fees: Fee[]): Map<string, Fee[]> {
  const grouped = new Map<string, Fee[]>();
  
  fees.forEach(fee => {
    if (!fee.student_id) return;
    
    if (!grouped.has(fee.student_id)) {
      grouped.set(fee.student_id, []);
    }
    grouped.get(fee.student_id)!.push(fee);
  });

  return grouped;
}

/**
 * Group fees by year
 */
export function groupFeesByYear(fees: Fee[]): Map<number, Fee[]> {
  const grouped = new Map<number, Fee[]>();
  
  fees.forEach(fee => {
    const key = fee.year ?? fee.year_academico ?? (fee.due_date ? new Date(fee.due_date).getFullYear() : undefined);
    if (key === undefined || key === null) return;
    if (!grouped.has(key)) {
      grouped.set(key, []);
    }
    grouped.get(key)!.push(fee);
  });

  return grouped;
}

/**
 * Get payment history (only paid fees with payment details)
 */
export function getPaymentHistory(fees: Fee[]): Fee[] {
  return fees
    .filter(fee => fee.status === 'paid' && fee.payment_date)
    .sort((a, b) => {
      const dateA = new Date(a.payment_date!);
      const dateB = new Date(b.payment_date!);
      return dateB.getTime() - dateA.getTime(); // Most recent first
    });
}

/**
 * Format currency for Chilean pesos
 */
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('es-CL', {
    style: 'currency',
    currency: 'CLP',
    minimumFractionDigits: 0,
  }).format(amount);
}

/**
 * Format date for display
 */
export function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return new Intl.DateTimeFormat('es-CL', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(date);
}

/**
 * Get days until due date
 */
export function getDaysUntilDue(dueDate: string): number {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const due = new Date(dueDate);
  due.setHours(0, 0, 0, 0);
  
  const diff = due.getTime() - today.getTime();
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
}

/**
 * Get days overdue (negative number means not overdue)
 */
export function getDaysOverdue(dueDate: string): number {
  return -getDaysUntilDue(dueDate);
}
