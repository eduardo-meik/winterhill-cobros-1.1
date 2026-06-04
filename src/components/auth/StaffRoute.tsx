import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { isStaffRole } from '../../constants/roles';

export function StaffRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary" />
      </div>
    );
  }

  if (!isStaffRole(user?.role)) {
    return <Navigate to="/apoderado/bienvenido" state={{ from: location }} replace />;
  }

  return <>{children}</>;
}
