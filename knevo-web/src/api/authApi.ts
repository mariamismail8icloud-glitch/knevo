import axios from 'axios';
import { API_BASE_URL } from '../config/api';

// Plain axios instance — no retry interceptors, safe to use for auth calls
const authClient = axios.create({ baseURL: API_BASE_URL });

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  userId: string;
  role: string;
  name: string | null;
  enrollmentCode: string | null;
  accessToken: string;
  refreshToken: string;
}

export interface DoctorSignupRequest {
  username: string;
  email: string;
  password: string;
  name: string;
  phone?: string;
  clinicName: string;
  specialization: string;
  professionalLicense?: string;
  yearsExperience?: number;
}

export const login = (req: LoginRequest): Promise<AuthResponse> =>
  authClient.post<AuthResponse>('/api/auth/login', req).then(r => r.data);

export const signupDoctor = (req: DoctorSignupRequest): Promise<void> =>
  authClient.post('/api/auth/signup/doctor', req).then(() => undefined);

export const refreshTokens = (refreshToken: string): Promise<AuthResponse> =>
  authClient.post<AuthResponse>('/api/auth/refresh', { refreshToken }).then(r => r.data);
