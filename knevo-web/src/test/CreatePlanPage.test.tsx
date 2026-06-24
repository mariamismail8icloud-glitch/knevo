import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import CreatePlanPage from '../pages/doctor/CreatePlanPage';

vi.mock('../api/doctorApi', () => ({
  getExercises: vi.fn().mockResolvedValue([]),
  createPlan: vi.fn(),
}));

function wrap(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}><MemoryRouter>{ui}</MemoryRouter></QueryClientProvider>);
}

describe('CreatePlanPage', () => {
  it('renders step 1', () => {
    wrap(<CreatePlanPage />);
    expect(screen.getByText('Plan details')).toBeInTheDocument();
  });
});
