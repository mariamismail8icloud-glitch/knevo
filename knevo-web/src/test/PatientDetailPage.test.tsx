import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import PatientDetailPage from '../pages/doctor/PatientDetailPage';

// Mock the API module — factories must not reference top-level variables
vi.mock('../api/doctorApi', () => ({
  getPatientPlans: vi.fn(),
  getTherapyConfig: vi.fn(),
  getPatientSessions: vi.fn(),
  getSessionDetail: vi.fn(),
}));

// Import mocked module after vi.mock so we can set return values
import * as doctorApi from '../api/doctorApi';

const mockPlans = [
  {
    planId: 'plan-1',
    title: 'Knee Recovery',
    status: 'ACTIVE',
    therapyConfigId: 'config-1',
    createdAt: '2026-06-01T10:00:00Z',
    startDate: null,
    endDate: null,
  },
];

const mockConfig = {
  id: 'config-1',
  patientId: 'patient-1',
  issuedById: 'doctor-1',
  rehabPlanId: null,
  comment: null,
  createdAt: '2025-01-01T00:00:00Z',
  deliveredAt: null,
  sessionsPerWeek: 3,
  schedule: 'Mon/Wed/Fri',
  totalSessionsNum: 12,
  maxFlexionAngleDeg: 90,
  maxExtensionAngleDeg: null,
  maxSpeed: null,
  status: 'ACTIVE',
  sets: [
    {
      id: 'set-1',
      exercise: {
        id: 'ex-1',
        name: 'Quad Stretch',
        category: 'STRETCHING',
        activityType: 'ACTIVE',
        mode: 'MOBILE_ONLY',
        difficulty: 'EASY',
        description: '',
        patientInstructions: '',
        doctorInstructions: '',
        defaultSets: null,
        defaultReps: null,
        defaultRestSeconds: null,
        defaultMinRomDeg: null,
        defaultMaxRomDeg: null,
        defaultMaxAngularVelocityDegS: null,
        defaultPainStopThreshold: null,
        safetyNotes: null,
        targetJoint: 'KNEE',
        videoUrl: null,
        imageUrl: null,
      },
      deviceAssisted: false,
      durationMin: 10,
      restDurationMin: 2,
      setOrder: 0,
    },
  ],
};

const mockSessions = [
  {
    id: 'session-1',
    status: 'COMPLETED',
    startedAt: '2026-06-10T09:00:00Z',
    endedAt: '2026-06-10T09:30:00Z',
    painBefore: 3,
    painDuring: null,
    painAfter: 2,
    setRecords: null,
  },
  {
    id: 'session-2',
    status: 'STOPPED_DUE_TO_PAIN',
    startedAt: '2026-06-12T10:00:00Z',
    endedAt: '2026-06-12T10:15:00Z',
    painBefore: 5,
    painDuring: 8,
    painAfter: null,
    setRecords: null,
  },
];

const mockSessionDetail = {
  id: 'session-1',
  status: 'COMPLETED',
  startedAt: '2026-06-10T09:00:00Z',
  endedAt: '2026-06-10T09:30:00Z',
  painBefore: 3,
  painDuring: null,
  painAfter: 2,
  setRecords: [
    {
      id: 'rec-1',
      therapySetConfigId: 'set-1',
      exerciseName: 'Quad Stretch',
      startDatetime: '2026-06-10T09:02:00Z',
      stopDatetime: '2026-06-10T09:12:00Z',
      painLevel: 2,
      feedback: 'Felt good',
      status: 'COMPLETED',
    },
  ],
};

function wrap(patientId = 'patient-1') {
  vi.mocked(doctorApi.getPatientPlans).mockResolvedValue(mockPlans);
  vi.mocked(doctorApi.getTherapyConfig).mockResolvedValue(mockConfig);
  vi.mocked(doctorApi.getPatientSessions).mockResolvedValue(mockSessions);
  vi.mocked(doctorApi.getSessionDetail).mockResolvedValue(mockSessionDetail);

  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <MemoryRouter initialEntries={[`/patients/${patientId}`]}>
        <Routes>
          <Route path="/patients/:patientId" element={<PatientDetailPage />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  );
}

describe('PatientDetailPage', () => {
  it('renders tab bar with Therapy Plan and Sessions tabs', () => {
    wrap();
    expect(screen.getByText('Therapy Plan')).toBeInTheDocument();
    expect(screen.getByText('Sessions')).toBeInTheDocument();
  });

  it('shows plan content by default on Plan tab', async () => {
    wrap();
    expect(await screen.findByText('Active plan: Knee Recovery')).toBeInTheDocument();
  });

  it('switching to Sessions tab shows session rows', async () => {
    wrap();
    const sessionsTab = screen.getByText('Sessions');
    await userEvent.click(sessionsTab);
    expect(await screen.findByText('COMPLETED')).toBeInTheDocument();
    expect(await screen.findByText('STOPPED DUE TO PAIN')).toBeInTheDocument();
  });

  it('shows pain before and pain after on session rows', async () => {
    wrap();
    await userEvent.click(screen.getByText('Sessions'));
    // painBefore=3 and painAfter=2 for first session
    expect(await screen.findByText('3')).toBeInTheDocument();
    expect(await screen.findByText('2')).toBeInTheDocument();
  });

  it('shows empty state when no sessions', async () => {
    vi.mocked(doctorApi.getPatientSessions).mockResolvedValueOnce([]);

    wrap();
    await userEvent.click(screen.getByText('Sessions'));
    expect(await screen.findByText('No sessions yet.')).toBeInTheDocument();
  });

  it('clicking a session shows session detail panel with exercise name', async () => {
    wrap();
    await userEvent.click(screen.getByText('Sessions'));
    // Click the first COMPLETED row
    const completedBadges = await screen.findAllByText('COMPLETED');
    await userEvent.click(completedBadges[0].closest('button')!);
    expect(await screen.findByText('Session detail')).toBeInTheDocument();
    expect(await screen.findByText('Quad Stretch')).toBeInTheDocument();
    expect(screen.getByText('"Felt good"')).toBeInTheDocument();
  });
});
