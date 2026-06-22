import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import MessagesPage from '../pages/doctor/MessagesPage';

vi.mock('../api/doctorApi', () => ({
  getMyPatients: vi.fn().mockResolvedValue([
    { id: 'patient-1', name: 'Alice Patient', email: 'alice@test.com', phone: null, enrollmentCode: null },
    { id: 'patient-2', name: 'Bob Patient', email: 'bob@test.com', phone: null, enrollmentCode: null },
  ]),
  getMessageThread: vi.fn().mockResolvedValue([]),
  sendMessage: vi.fn(),
  markMessageRead: vi.fn(),
}));

function wrap(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <MemoryRouter>{ui}</MemoryRouter>
    </QueryClientProvider>
  );
}

describe('MessagesPage', () => {
  it('renders Messages heading', () => {
    wrap(<MessagesPage />);
    expect(screen.getByText('Messages')).toBeInTheDocument();
  });

  it('shows "Select a patient" when no patient is selected', () => {
    wrap(<MessagesPage />);
    expect(screen.getByText('Select a patient to view messages.')).toBeInTheDocument();
  });

  it('renders patient list items when patients are returned', async () => {
    wrap(<MessagesPage />);
    expect(await screen.findByText('Alice Patient')).toBeInTheDocument();
    expect(await screen.findByText('Bob Patient')).toBeInTheDocument();
  });
});
