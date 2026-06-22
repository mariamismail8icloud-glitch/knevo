import axios from 'axios';
import { API_BASE_URL } from '../config/api';

const api = axios.create({ baseURL: API_BASE_URL });

api.interceptors.request.use(config => {
  const token = sessionStorage.getItem('accessToken');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Helper: get userId from sessionStorage (set alongside accessToken)
const getUserId = () => sessionStorage.getItem('userId') ?? '';

export interface Patient {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  enrollmentCode: string | null;
}

export const getMyPatients = (): Promise<Patient[]> =>
  api.get<Patient[]>('/api/doctor/patients', {
    headers: { 'X-User-Id': getUserId() },
  }).then(r => r.data);

export const enrollPatient = (enrollmentCode: string): Promise<Patient> =>
  api.post<Patient>('/api/doctor/enroll-patient',
    { enrollmentCode },
    { headers: { 'X-User-Id': getUserId() } }
  ).then(r => r.data);

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
  api.put<TherapyConfig>(`/api/therapy-config/${configId}`, req).then(r => r.data);

export const getExercises = (params?: { category?: string; mode?: string }): Promise<Exercise[]> =>
  api.get<Exercise[]>('/api/exercises', { params }).then(r => r.data);

export const createPlan = (patientId: string, req: CreatePlanRequest): Promise<PlanSummary> =>
  api.post<PlanSummary>(`/api/doctor/patients/${patientId}/plans`, req, {
    headers: { 'X-User-Id': getUserId() },
  }).then(r => r.data);

export const getPatientPlans = (patientId: string): Promise<PlanSummary[]> =>
  api.get<PlanSummary[]>(`/api/doctor/patients/${patientId}/plans`, {
    headers: { 'X-User-Id': getUserId() },
  }).then(r => r.data);

export const getTherapyConfig = (configId: string): Promise<TherapyConfig> =>
  api.get<TherapyConfig>(`/api/therapy-config/${configId}`).then(r => r.data);

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
  api.get<SessionSummary[]>(`/api/doctor/patients/${patientId}/sessions`, {
    headers: { 'X-User-Id': getUserId() },
  }).then(r => r.data);

export const getSessionDetail = (sessionId: string): Promise<SessionSummary> =>
  api.get<SessionSummary>(`/api/sessions/${sessionId}`).then(r => r.data);

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

export const getMessageThread = (partnerId: string, userId: string): Promise<ChatMessage[]> =>
  api.get<ChatMessage[]>('/api/messages', {
    params: { partnerId },
    headers: { 'X-User-Id': userId },
  }).then(r => r.data);

export const sendMessage = (req: SendMessageRequest, userId: string): Promise<ChatMessage> =>
  api.post<ChatMessage>('/api/messages', req, {
    headers: { 'X-User-Id': userId },
  }).then(r => r.data);

export const markMessageRead = (messageId: string, userId: string): Promise<void> =>
  api.put<void>(`/api/messages/${messageId}/read`, {}, {
    headers: { 'X-User-Id': userId },
  }).then(r => r.data);
