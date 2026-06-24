import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import EditConfigModal from '../pages/doctor/EditConfigModal';
import type { TherapyConfig } from '../api/doctorApi';

vi.mock('../api/doctorApi', () => ({
  updateTherapyConfig: vi.fn(),
}));

const mockConfig: TherapyConfig = {
  id: 'config-1', patientId: 'p-1', sessionsPerWeek: 3, schedule: 'MON,WED',
  totalSessionsNum: 12, maxFlexionAngleDeg: 90, maxExtensionAngleDeg: 0,
  maxSpeed: null, status: 'INPROGRESS', sets: [],
  issuedById: 'd-1', rehabPlanId: null, comment: null, createdAt: '', deliveredAt: null,
};

function wrap(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}><MemoryRouter>{ui}</MemoryRouter></QueryClientProvider>);
}

describe('EditConfigModal', () => {
  it('renders modal with form fields', () => {
    wrap(<EditConfigModal config={mockConfig} patientId="p-1" onClose={vi.fn()} />);
    expect(screen.getByText('Edit Therapy Config')).toBeInTheDocument();
    expect(screen.getByText('Save Changes')).toBeInTheDocument();
  });
});
