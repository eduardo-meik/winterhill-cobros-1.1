import { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { needsIntakeCheck } from '../services/guardianIntake';

// Routes allowed without completed intake
const ALLOWED_ROUTES = new Set([
  '/apoderado/encuesta',
  '/apoderado/bienvenido',
  '/apoderado/aceptar',
  '/registro-apoderado',
  '/registro-apoderado/nuevo',
  '/login', '/forgot-password', '/reset-password', '/auth/callback'
]);

// Simple module-level cache so multiple components don't trigger extra network calls
let _intakeNeededCached: boolean | null = null;
let _intakeCheckInFlight: Promise<boolean> | null = null;

export function useGuardianIntakeGate() {
  const { user } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [checking, setChecking] = useState(false);
  const [intakeNeeded, setIntakeNeeded] = useState<boolean | null>(_intakeNeededCached);
  useEffect(() => {
    let active = true;
    const run = async () => {
      if (!user || user.role !== 'guardian') return; // only guardians
      if (ALLOWED_ROUTES.has(location.pathname)) return; // allowed free navigation
      // If we already know and it's not needed, skip.
      if (_intakeNeededCached === false) return;
      setChecking(true);
      try {
        let needed: boolean;
        if (_intakeCheckInFlight) {
          needed = await _intakeCheckInFlight;
        } else if (_intakeNeededCached !== null) {
          needed = _intakeNeededCached;
        } else {
          _intakeCheckInFlight = needsIntakeCheck();
          needed = await _intakeCheckInFlight;
          _intakeCheckInFlight = null;
          _intakeNeededCached = needed;
        }
        if (active) setIntakeNeeded(needed);
        if (!active) return;
        if (needed) {
          navigate('/apoderado/encuesta', { replace: true });
        }
      } finally {
        if (active) setChecking(false);
      }
    };
    run();
    return () => { active = false; };
  }, [user, location.pathname, navigate]);
  return { checking, intakeNeeded };
}
