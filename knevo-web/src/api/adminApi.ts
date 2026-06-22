import client from './client';

export interface Doctor {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  clinicName: string;
  specialization: string;
  professionalLicense: string | null;
  yearsExperience: number | null;
  doctorStatus: string;
  rejectionReason: string | null;
  createdAt: string;
}

/** @deprecated kept for existing tests */
export type PendingDoctor = Doctor;

export const getAllDoctors = (): Promise<Doctor[]> =>
  client.get<Doctor[]>('/api/admin/doctors').then(r => r.data);

export const getPendingDoctors = (): Promise<Doctor[]> =>
  client.get<Doctor[]>('/api/admin/doctors/pending').then(r => r.data);

export const approveDoctor = (id: string): Promise<void> =>
  client.post(`/api/admin/doctors/${id}/approve`).then(() => undefined);

export const rejectDoctor = (id: string, reason?: string): Promise<void> =>
  client.post(`/api/admin/doctors/${id}/reject`, { reason }).then(() => undefined);
