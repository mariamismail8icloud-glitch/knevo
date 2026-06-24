import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import PatientProgressTab from '../pages/doctor/PatientProgressTab';

vi.mock('../api/doctorApi', () => ({
  getPatientProgress: vi.fn().mockResolvedValue({
    sessionsPerWeek: [{ weekLabel: '2025-W20', count: 3 }],
    painTrend: [{ sessionDate: '2025-05-19', avgPainBefore: 2.5 }],
    adherenceRate: 0.75,
    missedSessionsCount: 1,
    totalSessionsCompleted: 3,
    totalSessionsPrescribed: 4,
  }),
}));

function wrap(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <MemoryRouter>{ui}</MemoryRouter>
    </QueryClientProvider>
  );
}

describe('PatientProgressTab', () => {
  it('renders metric cards with correct values', async () => {
    wrap(<PatientProgressTab patientId="p-1" />);
    expect(await screen.findByText('75%')).toBeInTheDocument();
    expect(screen.getByText('3')).toBeInTheDocument();
  });

  it('renders Prescribed metric', async () => {
    wrap(<PatientProgressTab patientId="p-1" />);
    expect(await screen.findByText('4')).toBeInTheDocument();
    expect(screen.getByText('Prescribed')).toBeInTheDocument();
  });

  it('shows Missed count', async () => {
    wrap(<PatientProgressTab patientId="p-1" />);
    expect(await screen.findByText('1')).toBeInTheDocument();
    expect(screen.getByText('Missed')).toBeInTheDocument();
  });
});
