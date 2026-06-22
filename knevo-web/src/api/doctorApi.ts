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
