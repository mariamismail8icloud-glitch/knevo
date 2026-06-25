import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import EditConfigModal from '../pages/doctor/EditConfigModal';
import type { TherapyConfig } from '../api/doctorApi';

vi.mock('../api/doctorApi', () => ({
  updateTherapyConfig: vi.fn().mockResolvedValue({}),
  getTherapyDefaults: vi.fn().mockResolvedValue({
    maxSpeed: { defaultValue: 5, min: 1, max: 12 },
    maxExtensionAngleDeg: { defaultValue: 5, min: 1, max: 5 },
    maxFlexionAngleDeg: { defaultValue: 60, min: 30, max: 65 },
  }),
}));

import * as doctorApi from '../api/doctorApi';

const mockConfig: TherapyConfig = {
  id: 'config-1', patientId: 'p-1', sessionsPerWeek: 3, schedule: 'MON,WED',
  totalSessionsNum: 12, maxFlexionAngleDeg: 60, maxExtensionAngleDeg: 5,
  maxSpeed: 5, status: 'INPROGRESS', sets: [],
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

  it('rejects an out-of-range flexion and does not submit', async () => {
    wrap(<EditConfigModal config={mockConfig} patientId="p-1" onClose={vi.fn()} />);
    // Wait for defaults to load (ranges drive the labels).
    await screen.findByText(/Max flexion angle/);
    const flexionInput = screen.getByDisplayValue('60');
    await userEvent.clear(flexionInput);
    await userEvent.type(flexionInput, '100'); // > 65
    await userEvent.click(screen.getByText('Save Changes'));

    expect(await screen.findByText(/Max flexion must be between 30 and 65/)).toBeInTheDocument();
    expect(doctorApi.updateTherapyConfig).not.toHaveBeenCalled();
  });

  it('submits when values are in range', async () => {
    const onClose = vi.fn();
    wrap(<EditConfigModal config={mockConfig} patientId="p-1" onClose={onClose} />);
    await screen.findByText(/Max flexion angle/);
    await userEvent.click(screen.getByText('Save Changes'));
    await waitFor(() => expect(doctorApi.updateTherapyConfig).toHaveBeenCalled());
  });
});
