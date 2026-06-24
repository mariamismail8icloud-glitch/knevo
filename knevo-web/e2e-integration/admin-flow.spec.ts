import { test, expect } from '@playwright/test';
import { BACKEND, ADMIN } from './constants';

async function loginAsAdmin(page: import('@playwright/test').Page) {
  await page.goto('/login');
  await page.fill('input[type="email"]', ADMIN.email);
  await page.fill('input[type="password"]', ADMIN.password);
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL(/\/admin/, { timeout: 10_000 });
}

function uniquePendingDoctor() {
  const id = `${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
  return {
    name: 'Pending Test Doctor',
    email: `dr-pending-${id}@integration.test`,
    username: `drpending${id.replace('-', '')}`,
    password: 'Password123!',
    clinicName: 'Pending Clinic',
    specialization: 'Orthopaedics',
  };
}

test.describe('Admin flow', () => {
  test('admin can login with real credentials and reach /admin dashboard', async ({ page }) => {
    await loginAsAdmin(page);
    await expect(page.getByText('Doctor Accounts')).toBeVisible();
  });

  test('admin dashboard loads pending doctors list from backend', async ({ page, request }) => {
    // Seed a fresh pending doctor so we know at least one exists
    const doc = uniquePendingDoctor();
    const signup = await request.post(`${BACKEND}/api/auth/signup/doctor`, { data: doc });
    expect(signup.status()).toBe(202);

    await loginAsAdmin(page);

    // The Pending tab is selected by default; the seeded doctor must appear
    await expect(page.getByText(doc.email)).toBeVisible({ timeout: 8_000 });
  });

  test('admin can approve a pending doctor from the UI', async ({ page, request }) => {
    const doc = uniquePendingDoctor();
    const signup = await request.post(`${BACKEND}/api/auth/signup/doctor`, { data: doc });
    expect(signup.status()).toBe(202);

    await loginAsAdmin(page);
    await expect(page.getByText(doc.email)).toBeVisible({ timeout: 8_000 });

    // DoctorCard root: div.bg-white.rounded-2xl — filter to the one with this doctor's email
    const card = page.locator('div.bg-white.rounded-2xl').filter({ has: page.locator('p', { hasText: doc.email }) });
    await card.getByRole('button', { name: 'Approve' }).click();

    // After invalidateQueries refetches, the doctor leaves the Pending tab
    await expect(page.getByText(doc.email)).not.toBeVisible({ timeout: 8_000 });
  });

  test('admin can reject a pending doctor from the UI', async ({ page, request }) => {
    const doc = uniquePendingDoctor();
    const signup = await request.post(`${BACKEND}/api/auth/signup/doctor`, { data: doc });
    expect(signup.status()).toBe(202);

    await loginAsAdmin(page);
    await expect(page.getByText(doc.email)).toBeVisible({ timeout: 8_000 });

    const card = page.locator('div.bg-white.rounded-2xl').filter({ has: page.locator('p', { hasText: doc.email }) });
    await card.getByRole('button', { name: 'Reject' }).click();
    await card.getByRole('button', { name: 'Confirm rejection' }).click();

    await expect(page.getByText(doc.email)).not.toBeVisible({ timeout: 8_000 });
  });
});
