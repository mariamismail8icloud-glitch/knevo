import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '../context/AuthContext';
import DoctorSignupPage from '../pages/DoctorSignupPage';

vi.mock('../api/authApi', () => ({ signupDoctor: vi.fn(), login: vi.fn() }));

function wrap(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={qc}><AuthProvider><MemoryRouter>{ui}</MemoryRouter></AuthProvider></QueryClientProvider>);
}

describe('DoctorSignupPage', () => {
  it('renders signup heading', () => {
    wrap(<DoctorSignupPage />);
    expect(screen.getByText('Create your account')).toBeInTheDocument();
  });

  it('renders all required fields', () => {
    wrap(<DoctorSignupPage />);
    expect(screen.getByText('Full name')).toBeInTheDocument();
    expect(screen.getByText('Email')).toBeInTheDocument();
    expect(screen.getByText('Clinic / Hospital name')).toBeInTheDocument();
    expect(screen.getByText('Specialization')).toBeInTheDocument();
  });
});
