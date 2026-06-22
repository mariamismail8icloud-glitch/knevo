import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import ExerciseLibraryPage from '../pages/doctor/ExerciseLibraryPage';

vi.mock('../api/doctorApi', () => ({
  getExercises: vi.fn().mockResolvedValue([
    { id: '1', name: 'Test Exercise', category: 'Strength exercises', mode: 'MOBILE_ONLY',
      difficulty: 'BEGINNER', description: 'A test exercise', targetJoint: 'KNEE',
      patientInstructions: '', doctorInstructions: '', safetyNotes: null,
      defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60,
      defaultMinRomDeg: null, defaultMaxRomDeg: null, defaultMaxAngularVelocityDegS: null,
      defaultPainStopThreshold: 5, videoUrl: null, imageUrl: null,
      activityType: 'STANDING' },
  ]),
}));

function wrap(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}><MemoryRouter>{ui}</MemoryRouter></QueryClientProvider>);
}

describe('ExerciseLibraryPage', () => {
  it('renders heading', () => {
    wrap(<ExerciseLibraryPage />);
    expect(screen.getByText('Exercise Library')).toBeInTheDocument();
  });

  it('shows exercise card when loaded', async () => {
    wrap(<ExerciseLibraryPage />);
    expect(await screen.findByText('Test Exercise')).toBeInTheDocument();
  });
});
