/**
 * Custom React hooks for fee management in guardian portal
 */

import { useState, useEffect, useCallback } from 'react';
import {
  Fee,
  FeeStats,
  fetchGuardianFees,
  fetchStudentFees,
  fetchGuardianFeesAllYears,
  calculateFeeStats,
} from '../services/feeService';

interface UseFeeResult {
  fees: Fee[];
  loading: boolean;
  error: Error | null;
  refresh: () => Promise<void>;
}

interface UseFeeStatsResult {
  stats: FeeStats | null;
  loading: boolean;
  error: Error | null;
  refresh: () => Promise<void>;
}

/**
 * Hook to fetch and manage guardian fees
 * @param guardianId - Guardian UUID
 * @param year - Academic year (optional)
 */
export function useGuardianFees(guardianId: string | null, year?: number): UseFeeResult {
  const [fees, setFees] = useState<Fee[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchData = useCallback(async () => {
    if (!guardianId) {
      setFees([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const data = await fetchGuardianFees(guardianId, year);
      setFees(data);
    } catch (err) {
      console.error('useGuardianFees error:', err);
      setError(err as Error);
      setFees([]);
    } finally {
      setLoading(false);
    }
  }, [guardianId, year]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return {
    fees,
    loading,
    error,
    refresh: fetchData,
  };
}

/**
 * Hook to fetch all fees across all years for a guardian
 * @param guardianId - Guardian UUID
 */
export function useGuardianFeesAllYears(guardianId: string | null): UseFeeResult {
  const [fees, setFees] = useState<Fee[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchData = useCallback(async () => {
    if (!guardianId) {
      setFees([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const data = await fetchGuardianFeesAllYears(guardianId);
      setFees(data);
    } catch (err) {
      console.error('useGuardianFeesAllYears error:', err);
      setError(err as Error);
      setFees([]);
    } finally {
      setLoading(false);
    }
  }, [guardianId]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return {
    fees,
    loading,
    error,
    refresh: fetchData,
  };
}

/**
 * Hook to fetch fees for a specific student
 * @param studentId - Student UUID
 * @param year - Academic year (optional)
 */
export function useStudentFees(studentId: string | null, year?: number): UseFeeResult {
  const [fees, setFees] = useState<Fee[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchData = useCallback(async () => {
    if (!studentId) {
      setFees([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const data = await fetchStudentFees(studentId, year);
      setFees(data);
    } catch (err) {
      console.error('useStudentFees error:', err);
      setError(err as Error);
      setFees([]);
    } finally {
      setLoading(false);
    }
  }, [studentId, year]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return {
    fees,
    loading,
    error,
    refresh: fetchData,
  };
}

/**
 * Hook to calculate fee statistics for a guardian
 * @param guardianId - Guardian UUID
 * @param year - Academic year (optional)
 */
export function useFeeStats(guardianId: string | null, year?: number): UseFeeStatsResult {
  const { fees, loading, error, refresh } = useGuardianFees(guardianId, year);
  const [stats, setStats] = useState<FeeStats | null>(null);

  useEffect(() => {
    if (fees.length > 0) {
      const computed = calculateFeeStats(fees);
      setStats(computed);
    } else {
      setStats(null);
    }
  }, [fees]);

  return {
    stats,
    loading,
    error,
    refresh,
  };
}
