import path from 'path';

export const BACKEND = 'http://localhost:8080';
export const AUTH_DIR = path.resolve('playwright/.auth');
export const DOCTOR_STATE_FILE = path.join(AUTH_DIR, 'doctor-state.json');

// Fixed email — global.setup seeds this doctor once; subsequent runs reuse it.
export const TEST_DOCTOR = {
  email: 'e2e-doctor@integration.test',
  password: 'Password123!',
  username: 'e2edoctor',
  name: 'E2E Test Doctor',
  clinicName: 'Integration Clinic',
  specialization: 'Physiotherapy',
};

// [assumed] admin password is "admin123" — override with ADMIN_PASSWORD env var if different.
// Verify: run `curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/api/auth/login \
//   -H "Content-Type: application/json" -d '{"email":"admin@knevo.com","password":"admin123"}'`
export const ADMIN = {
  email: 'admin@knevo.com',
  password: process.env.ADMIN_PASSWORD ?? 'Admin1234!',
};
