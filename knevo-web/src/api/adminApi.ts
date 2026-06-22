import axios from 'axios';
import { API_BASE_URL } from '../config/api';

const api = axios.create({ baseURL: API_BASE_URL });

// Inject token from sessionStorage (set on login)
api.interceptors.request.use(config => {
  const token = sessionStorage.getItem('accessToken');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export interface PendingDoctor {
  id: string;
  name: string;
  email: string;
  clinicName: string;
  specialization: string;
  doctorStatus: string;
  createdAt: string;
}

export const getPendingDoctors = (): Promise<PendingDoctor[]> =>
  api.get<PendingDoctor[]>('/api/admin/doctors/pending').then(r => r.data);

export const approveDoctor = (id: string): Promise<void> =>
  api.post(`/api/admin/doctors/${id}/approve`).then(() => undefined);

export const rejectDoctor = (id: string, reason?: string): Promise<void> =>
  api.post(`/api/admin/doctors/${id}/reject`, { reason }).then(() => undefined);
