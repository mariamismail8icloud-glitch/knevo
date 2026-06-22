import { test as setup, expect } from '@playwright/test';
import fs from 'fs';
import { BACKEND, AUTH_DIR, DOCTOR_STATE_FILE, TEST_DOCTOR, ADMIN } from './constants';

setup('seed: create and approve test doctor', async ({ request }) => {
  // 1. Admin login — fails fast with a helpful message if ADMIN_PASSWORD is wrong
  const adminLogin = await request.post(`${BACKEND}/api/auth/login`, {
    data: { email: ADMIN.email, password: ADMIN.password },
  });
  if (!adminLogin.ok()) {
    throw new Error(
      `Admin login failed (HTTP ${adminLogin.status()}). ` +
      `Set ADMIN_PASSWORD env var if "${ADMIN.password}" is wrong. ` +
      `Also confirm the backend is running at ${BACKEND}.`,
    );
  }
  const { accessToken: adminToken } = await adminLogin.json();

  // 2. Create test doctor — 202 = new, 409 = already exists from a prior run, both are fine
  const signup = await request.post(`${BACKEND}/api/auth/signup/doctor`, {
    data: TEST_DOCTOR,
  });
  if (!signup.ok() && signup.status() !== 409) {
    throw new Error(`Doctor signup failed: HTTP ${signup.status()} — ${await signup.text()}`);
  }

  // 3. Approve if still pending (no-op if already approved from a prior run)
  const pendingRes = await request.get(`${BACKEND}/api/admin/doctors/pending`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  expect(pendingRes.ok()).toBeTruthy();
  const pending: Array<{ id: string; email: string }> = await pendingRes.json();
  const found = pending.find(d => d.email === TEST_DOCTOR.email);
  if (found) {
    const approve = await request.post(`${BACKEND}/api/admin/doctors/${found.id}/approve`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    expect(approve.ok()).toBeTruthy();
  }

  // 4. Login as approved doctor — proves approval worked; saves refresh token for test reuse
  const doctorLogin = await request.post(`${BACKEND}/api/auth/login`, {
    data: { email: TEST_DOCTOR.email, password: TEST_DOCTOR.password },
  });
  if (!doctorLogin.ok()) {
    throw new Error(`Approved doctor login failed: HTTP ${doctorLogin.status()}`);
  }
  const { refreshToken } = await doctorLogin.json();

  fs.mkdirSync(AUTH_DIR, { recursive: true });
  fs.writeFileSync(DOCTOR_STATE_FILE, JSON.stringify({ refreshToken }), 'utf8');
});
