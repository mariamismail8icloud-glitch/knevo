import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '../context/AuthContext';
import LoginPage from '../pages/LoginPage';

vi.mock('../api/authApi', () => ({
  login: vi.fn(),
}));

import { login } from '../api/authApi';

function renderWithProviders(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <AuthProvider>
        <MemoryRouter>{ui}</MemoryRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}

describe('LoginPage', () => {
  beforeEach(() => vi.clearAllMocks());

  it('renders sign in heading', () => {
    renderWithProviders(<LoginPage />);
    expect(screen.getByText('Welcome back')).toBeInTheDocument();
  });

  it('shows error on failed login', async () => {
    (login as ReturnType<typeof vi.fn>).mockRejectedValueOnce({
      response: { data: { message: 'Invalid credentials' } },
    });
    renderWithProviders(<LoginPage />);
    fireEvent.change(screen.getByPlaceholderText('doctor@clinic.com'), { target: { value: 'bad@test.com' } });
    fireEvent.change(screen.getByPlaceholderText('••••••••'), { target: { value: 'wrongpass' } });
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));
    await waitFor(() => expect(screen.getByText('Invalid credentials')).toBeInTheDocument());
  });
});
