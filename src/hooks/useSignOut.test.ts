import { renderHook, act } from '@testing-library/react';
import { useSignOut } from './useSignOut';
import { supabase } from '../services/supabase';

jest.mock('../services/supabase', () => ({
  auth: {
    signOut: jest.fn(),
  },
}));

describe.skip('useSignOut', () => {
  it('calls supabase.auth.signOut', async () => {
    const { result } = renderHook(() => useSignOut());
    await act(async () => {
      await result.current();
    });
    expect(supabase.auth.signOut).toHaveBeenCalledTimes(1);
  });
});
