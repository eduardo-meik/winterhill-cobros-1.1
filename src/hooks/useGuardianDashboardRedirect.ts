import { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export function useGuardianDashboardRedirect(target: string = '/apoderado/bienvenido') {
  const { user } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [redirected, setRedirected] = useState(false);

  useEffect(() => {
  if (user?.role && user.role.toLowerCase() === 'guardian' && location.pathname === '/dashboard') {
      navigate(target, { replace: true });
      setRedirected(true);
    }
  }, [user?.role, location.pathname, navigate, target]);

  return redirected;
}
