import client from './client';

export interface Patient {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  enrollmentCode: string | null;
}

export const getMyPatients = (): Promise<Patient[]> =>
  client.get<Patient[]>('/api/doctor/patients').then(r => r.data);

export const getPatient = (patientId: string): Promise<Patient> =>
  client.get<Patient>(`/api/doctor/patients/${patientId}`).then(r => r.data);

export const enrollPatient = (enrollmentCode: string): Promise<Patient> =>
  client.post<Patient>('/api/doctor/enroll-patient', { enrollmentCode }).then(r => r.data);

export interface Exercise {
  id: string;
  name: string;
  category: string;
  activityType: string;
  mode: string;
  difficulty: string;
  description: string;
  patientInstructions: string;
  doctorInstructions: string;
  defaultSets: number | null;
  defaultReps: number | null;
  defaultRestSeconds: number | null;
  defaultMinRomDeg: number | null;
  defaultMaxRomDeg: number | null;
  defaultMaxAngularVelocityDegS: number | null;
  defaultPainStopThreshold: number | null;
  safetyNotes: string | null;
  targetJoint: string;
  videoUrl: string | null;
  imageUrl: string | null;
}

export interface SetConfigRequest {
  exerciseId: string;
  deviceAssisted: boolean;
  durationMin: number;
  restDurationMin: number;
  setOrder: number;
}

export interface CreatePlanRequest {
  title: string;
  goal?: string;
  startDate?: string;
  endDate?: string;
  notes?: string;
  maxSpeed?: number;
  maxExtensionAngleDeg?: number;
  maxFlexionAngleDeg?: number;
  sessionsPerWeek?: number;
  schedule?: string;
  totalSessionsNum?: number;
  comment?: string;
  sets: SetConfigRequest[];
}

export interface PlanSummary {
  planId: string;
  title: string;
  status: string;
  therapyConfigId: string;
  createdAt: string;
  startDate: string | null;
  endDate: string | null;
}

export interface TherapySetConfigDto {
  id: string;
  exercise: Exercise;
  deviceAssisted: boolean;
  durationMin: number | null;
  restDurationMin: number | null;
  setOrder: number;
}

export interface TherapyConfig {
  id: string;
  patientId: string;
  sessionsPerWeek: number | null;
  schedule: string | null;
  totalSessionsNum: number | null;
  maxFlexionAngleDeg: number | null;
  maxExtensionAngleDeg: number | null;
  maxSpeed: number | null;
  status: string;
  sets: TherapySetConfigDto[];
  issuedById: string;
  rehabPlanId: string | null;
  comment: string | null;
  createdAt: string;
  deliveredAt: string | null;
}

export interface UpdateConfigRequest {
  maxSpeed?: number;
  maxExtensionAngleDeg?: number;
  maxFlexionAngleDeg?: number;
  sessionsPerWeek?: number;
  schedule?: string;
  totalSessionsNum?: number;
  comment?: string;
}

export const updateTherapyConfig = (configId: string, req: UpdateConfigRequest): Promise<TherapyConfig> =>
  client.put<TherapyConfig>(`/api/therapy-config/${configId}`, req).then(r => r.data);

export const getExercises = (params?: { category?: string; mode?: string }): Promise<Exercise[]> =>
  client.get<Exercise[]>('/api/exercises', { params }).then(r => r.data);

export const createPlan = (patientId: string, req: CreatePlanRequest): Promise<PlanSummary> =>
  client.post<PlanSummary>(`/api/doctor/patients/${patientId}/plans`, req).then(r => r.data);

export const getPatientPlans = (patientId: string): Promise<PlanSummary[]> =>
  client.get<PlanSummary[]>(`/api/doctor/patients/${patientId}/plans`).then(r => r.data);

export const getTherapyConfig = (configId: string): Promise<TherapyConfig> =>
  client.get<TherapyConfig>(`/api/therapy-config/${configId}`).then(r => r.data);

export interface SetRecord {
  id: string;
  therapySetConfigId: string;
  exerciseName: string | null;
  startDatetime: string | null;
  stopDatetime: string | null;
  painLevel: number | null;
  feedback: string | null;
  status: string;
}

export interface SessionSummary {
  id: string;
  status: string;
  startedAt: string | null;
  endedAt: string | null;
  painBefore: number | null;
  painDuring: number | null;
  painAfter: number | null;
  setRecords: SetRecord[] | null;
}

export const getPatientSessions = (patientId: string): Promise<SessionSummary[]> =>
  client.get<SessionSummary[]>(`/api/doctor/patients/${patientId}/sessions`).then(r => r.data);

export const getSessionDetail = (sessionId: string): Promise<SessionSummary> =>
  client.get<SessionSummary>(`/api/sessions/${sessionId}`).then(r => r.data);

export interface ChatMessage {
  id: string;
  senderId: string;
  receiverId: string;
  senderName: string;
  body: string;
  messageType: string;
  sentAt: string;
  readAt: string | null;
}

export interface SendMessageRequest {
  body: string;
  receiverId: string;
  messageType?: string;
}

export const getMessageThread = (partnerId: string): Promise<ChatMessage[]> =>
  client.get<ChatMessage[]>('/api/messages', { params: { partnerId } }).then(r => r.data);

export const sendMessage = (req: SendMessageRequest): Promise<ChatMessage> =>
  client.post<ChatMessage>('/api/messages', req).then(r => r.data);

export const markMessageRead = (messageId: string): Promise<void> =>
  client.put<void>(`/api/messages/${messageId}/read`, {}).then(r => r.data);

export interface WeeklyCount {
  weekLabel: string;
  count: number;
}

export interface PainPoint {
  sessionDate: string;
  avgPainBefore: number;
}

export interface PatientProgress {
  sessionsPerWeek: WeeklyCount[];
  painTrend: PainPoint[];
  adherenceRate: number;
  missedSessionsCount: number;
  totalSessionsCompleted: number;
  totalSessionsPrescribed: number;
}

export const getPatientProgress = (patientId: string): Promise<PatientProgress> =>
  client.get<PatientProgress>(`/api/patients/${patientId}/progress`).then(r => r.data);

export interface SensorReading {
  timestampUs: number | null;
  sampleId: number | null;
  heelFsrRaw: number | null;
  midfootFsrRaw: number | null;
  // null until Phase 3 analytics (M14)
  kneeAngleEstDeg: number | null;
  footAxG?: number | null;
  footAyG?: number | null;
  footAzG?: number | null;
  shankAxG?: number | null;
  shankAyG?: number | null;
  shankAzG?: number | null;
  thighAxG?: number | null;
  thighAyG?: number | null;
  thighAzG?: number | null;
}

export interface SensorReadingsOptions {
  setRecordId?: string;
  maxPoints?: number;
}

export const getSessionSensorReadings = (
  sessionId: string,
  opts?: SensorReadingsOptions
): Promise<SensorReading[]> =>
  client
    .get<SensorReading[]>(`/api/sessions/${sessionId}/sensor-readings`, {
      params: { setRecordId: opts?.setRecordId, maxPoints: opts?.maxPoints },
    })
    .then(r => r.data);
