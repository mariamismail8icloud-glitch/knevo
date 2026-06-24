import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '../context/AuthContext';
import PatientListPage from '../pages/doctor/PatientListPage';

vi.mock('../api/doctorApi', () => ({
  getMyPatients: vi.fn().mockResolvedValue([]),
  enrollPatient: vi.fn(),
}));

function wrap(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={qc}><AuthProvider><MemoryRouter>{ui}</MemoryRouter></AuthProvider></QueryClientProvider>);
}

describe('PatientListPage', () => {
  it('renders empty state', async () => {
    wrap(<PatientListPage />);
    expect(await screen.findByText('No patients yet.')).toBeInTheDocument();
  });

  it('shows enroll button', () => {
    wrap(<PatientListPage />);
    expect(screen.getByText('+ Enroll patient')).toBeInTheDocument();
  });
});
