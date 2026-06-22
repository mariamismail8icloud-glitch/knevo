import axios from 'axios';
import { API_BASE_URL } from '../config/api';

const api = axios.create({ baseURL: API_BASE_URL });

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  userId: string;
  role: string;
  enrollmentCode: string | null;
  accessToken: string;
  refreshToken: string;
}

export const login = (req: LoginRequest): Promise<AuthResponse> =>
  api.post<AuthResponse>('/api/auth/login', req).then(r => r.data);

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

export const signupDoctor = (req: DoctorSignupRequest): Promise<void> =>
  api.post('/api/auth/signup/doctor', req).then(() => undefined);
