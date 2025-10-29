// @jest-environment jsdom
import { renderHook, act, waitFor } from '@testing-library/react';
import { useGuardianIntakeGate } from './useGuardianIntakeGate';
import type { PropsWithChildren } from 'react';
import { MemoryRouter } from 'react-router-dom';

// Mocks
jest.mock('../services/guardianIntake', () => ({
  needsIntakeCheck: jest.fn(),
}));

jest.mock('../contexts/AuthContext', () => ({
  useAuth: () => ({ user: { id: 'u1', role: 'guardian' }, profile: { first_name: 'Test' } }),
}));

// Mock navigation
const navigateMock = jest.fn();
jest.mock('react-router-dom', () => {
  const actual = jest.requireActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => navigateMock,
    useLocation: () => ({ pathname: '/dashboard' }),
  };
});

import { needsIntakeCheck } from '../services/guardianIntake';

describe.skip('useGuardianIntakeGate', () => {
  jest.setTimeout(15000);
  beforeEach(() => {
    navigateMock.mockReset();
    (needsIntakeCheck as jest.Mock).mockReset();
  });

  it('redirects guardian to intake when needed', async () => {
    (needsIntakeCheck as jest.Mock).mockResolvedValue(true);
    const wrapper = ({ children }: PropsWithChildren) => <MemoryRouter>{children}</MemoryRouter>;
    await act(async () => {
      renderHook(() => useGuardianIntakeGate(), { wrapper });
    });
    await waitFor(() => expect(navigateMock).toHaveBeenCalled());
  });

  it('does not redirect when intake not needed', async () => {
    (needsIntakeCheck as jest.Mock).mockResolvedValue(false);
  const wrapper = ({ children }: PropsWithChildren) => <MemoryRouter>{children}</MemoryRouter>;
    await act(async () => {
      renderHook(() => useGuardianIntakeGate(), { wrapper });
    });
    await waitFor(() => expect(navigateMock).not.toHaveBeenCalled());
  });
});
