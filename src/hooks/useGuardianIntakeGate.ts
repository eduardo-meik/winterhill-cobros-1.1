import { useEffect, useMemo, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useGuardianData } from '../contexts/GuardianContext';

// Routes allowed without completed intake
const ALLOWED_ROUTES = new Set([
  '/apoderado/encuesta',
  '/apoderado/bienvenido',
  '/apoderado/aceptar',
  '/registro-apoderado',
  '/registro-apoderado/nuevo',
  '/login', '/forgot-password', '/reset-password', '/auth/callback'
]);

export function useGuardianIntakeGate() {
  const { user } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const { data, loading, refresh } = useGuardianData();
  const [checking, setChecking] = useState(false);
  const [intakeNeeded, setIntakeNeeded] = useState<boolean | null>(null);
  const [requestedBootstrap, setRequestedBootstrap] = useState(false);

  const shouldEnforce = useMemo(() => {
    if (!user || user.role !== 'guardian') return false;
    return !ALLOWED_ROUTES.has(location.pathname);
  }, [user, location.pathname]);

  const computedNeed = useMemo(() => {
    if (!data) return null;
    return Boolean(data.needsIntake);
  }, [data]);

  useEffect(() => {
    if (!shouldEnforce) {
      setChecking(false);
      setIntakeNeeded(null);
      setRequestedBootstrap(false);
      return;
    }

    if (!data && !loading && !requestedBootstrap) {
      setRequestedBootstrap(true);
      refresh({ force: true });
      setChecking(true);
      return;
    }

    if (computedNeed === true) {
      navigate('/apoderado/encuesta', { replace: true });
    }

    setIntakeNeeded(computedNeed);
    setChecking(loading || computedNeed === null);
  }, [shouldEnforce, computedNeed, data, loading, refresh, navigate, requestedBootstrap]);

  return { checking, intakeNeeded };
}
