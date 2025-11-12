import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import { useAuth } from './AuthContext';
import { fetchGuardianBootstrap, GuardianBootstrapData } from '../services/guardianBootstrap';

export interface GuardianContextValue {
  loading: boolean;
  refreshing: boolean;
  error: string | null;
  data: GuardianBootstrapData | null;
  refresh: (options?: { force?: boolean }) => Promise<GuardianBootstrapData | null>;
}

const defaultContext: GuardianContextValue = {
  loading: false,
  refreshing: false,
  error: null,
  data: null,
  refresh: async () => null,
};

const GuardianContext = createContext<GuardianContextValue>(defaultContext);

interface GuardianProviderProps {
  children: ReactNode;
}

export function GuardianProvider({ children }: GuardianProviderProps) {
  const { user } = useAuth();
  const [data, setData] = useState<GuardianBootstrapData | null>(null);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const initializedRef = useRef(false);
  const inFlightRef = useRef<Promise<GuardianBootstrapData | null> | null>(null);

  const runFetch = useCallback(async (options?: { force?: boolean }) => {
    const force = options?.force ?? false;
    const role = user?.role?.toLowerCase();
    if (!user || role !== 'guardian') {
      setData(null);
      setError(null);
      setLoading(false);
      setRefreshing(false);
      initializedRef.current = true;
      return null;
    }
    if (inFlightRef.current && !force) {
      return inFlightRef.current;
    }

    const firstLoad = !initializedRef.current;
    if (firstLoad) {
      setLoading(true);
    } else {
      setRefreshing(true);
    }
    setError(null);

    const request = fetchGuardianBootstrap(user.id)
      .then((result) => {
        setData(result);
        initializedRef.current = true;
        return result;
      })
      .catch((err) => {
        const message = err?.message || 'No se pudo cargar la información del apoderado.';
        setError(message);
        toast.error(message);
        return null;
      })
      .finally(() => {
        setLoading(false);
        setRefreshing(false);
        inFlightRef.current = null;
      });

    inFlightRef.current = request;
    return request;
  }, [user?.id, user?.role]);

  useEffect(() => {
    initializedRef.current = false;
    inFlightRef.current = null;
    setData(null);
    setError(null);
    setLoading(false);
    setRefreshing(false);
    runFetch();
  }, [runFetch]);

  const value = useMemo<GuardianContextValue>(() => ({
    loading,
    refreshing,
    error,
    data,
    refresh: runFetch,
  }), [loading, refreshing, error, data, runFetch]);

  return (
    <GuardianContext.Provider value={value}>
      {children}
    </GuardianContext.Provider>
  );
}

export function useGuardianData() {
  return useContext(GuardianContext);
}
