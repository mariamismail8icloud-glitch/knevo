import { render, screen, act } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { AuthProvider, useAuth } from '../context/AuthContext';

function TestConsumer() {
  const { isAuthenticated, setAuth, userId } = useAuth();
  return (
    <div>
      <span data-testid="auth">{isAuthenticated ? 'yes' : 'no'}</span>
      <button onClick={() => setAuth({ accessToken: 'tok', userId: 'u1', role: 'DOCTOR', name: 'Dr. Test' })}>login</button>
      <span data-testid="uid">{userId ?? 'none'}</span>
    </div>
  );
}

describe('AuthContext', () => {
  it('starts unauthenticated', () => {
    render(<AuthProvider><TestConsumer /></AuthProvider>);
    expect(screen.getByTestId('auth').textContent).toBe('no');
  });

  it('becomes authenticated after setAuth', async () => {
    render(<AuthProvider><TestConsumer /></AuthProvider>);
    await act(async () => {
      screen.getByRole('button', { name: 'login' }).click();
    });
    expect(screen.getByTestId('auth').textContent).toBe('yes');
    expect(screen.getByTestId('uid').textContent).toBe('u1');
  });
});
