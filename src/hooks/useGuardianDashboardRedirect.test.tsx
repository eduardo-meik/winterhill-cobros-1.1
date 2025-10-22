import { renderHook } from '@testing-library/react';

const mockNavigate = jest.fn();
let path = '/dashboard';
const authRef: { user?: any } = {};

jest.mock('react-router-dom', () => ({
  useNavigate: () => mockNavigate,
  useLocation: () => ({ pathname: path })
}));

jest.mock('../contexts/AuthContext', () => ({
  useAuth: () => authRef.user || { user: null }
}));

import { useGuardianDashboardRedirect } from './useGuardianDashboardRedirect';

describe('useGuardianDashboardRedirect', () => {
  beforeEach(() => {
    mockNavigate.mockReset();
    path = '/dashboard';
    authRef.user = undefined;
  });

  it('redirects guardian from /dashboard', () => {
    authRef.user = { user: { role: 'guardian' } };
    renderHook(() => useGuardianDashboardRedirect());
    expect(mockNavigate).toHaveBeenCalledWith('/apoderado/bienvenido', { replace: true });
  });

  it('does not redirect admin', () => {
    authRef.user = { user: { role: 'admin' } };
    renderHook(() => useGuardianDashboardRedirect());
    expect(mockNavigate).not.toHaveBeenCalled();
  });

  it('does not redirect guardian on other path', () => {
    authRef.user = { user: { role: 'guardian' } };
    path = '/payments';
    renderHook(() => useGuardianDashboardRedirect());
    expect(mockNavigate).not.toHaveBeenCalled();
  });
});
