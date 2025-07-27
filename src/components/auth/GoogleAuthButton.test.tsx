import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { GoogleAuthButton } from './GoogleAuthButton';
import * as supabase from '../../services/supabase';

jest.mock('../../services/supabase', () => ({
  signInWithGoogle: jest.fn(),
}));

describe('GoogleAuthButton', () => {
  it('calls signInWithGoogle when clicked', () => {
    render(<GoogleAuthButton />);
    const button = screen.getByRole('button', { name: /google/i });
    fireEvent.click(button);
    expect(supabase.signInWithGoogle).toHaveBeenCalledTimes(1);
  });
});
