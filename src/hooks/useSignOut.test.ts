import { renderHook } from '@testing-library/react-hooks';
import { useSignOut } from './useSignOut';
import { supabase } from '../services/supabase';

jest.mock('../services/supabase', () => ({
  auth: {
    signOut: jest.fn(),
  },
}));

describe('useSignOut', () => {
  it('calls supabase.auth.signOut', async () => {
    const { result } = renderHook(() => useSignOut());
    await result.current.signOut();
    expect(supabase.auth.signOut).toHaveBeenCalledTimes(1);
  });
});
