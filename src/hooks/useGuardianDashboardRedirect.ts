import { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export function useGuardianDashboardRedirect(target: string = '/apoderado/bienvenido') {
  const { user } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [redirecting, setRedirecting] = useState(false);

  useEffect(() => {
    const isGuardian = user?.role && user.role.toLowerCase() === 'guardian';
    const onDashboard = location.pathname === '/dashboard';

    if (isGuardian && onDashboard) {
      setRedirecting(true);
      navigate(target, { replace: true });
      return;
    }

    if (redirecting && (!isGuardian || !onDashboard)) {
      setRedirecting(false);
    }
  }, [user?.role, location.pathname, navigate, target, redirecting]);

  return redirecting;
}
