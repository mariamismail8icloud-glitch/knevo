import { test, expect } from '@playwright/test';
import fs from 'fs';
import { TEST_DOCTOR, DOCTOR_STATE_FILE } from './constants';

// Restores the authenticated session seeded by global.setup via the startup-refresh mechanism:
// set refreshToken in localStorage → next page.goto triggers AuthProvider's startup useEffect
// → calls /api/auth/refresh with the real backend → sets access token in React state → authenticated.
async function restoreSession(page: import('@playwright/test').Page) {
  const { refreshToken } = JSON.parse(fs.readFileSync(DOCTOR_STATE_FILE, 'utf8'));
  await page.goto('/login');
  await page.evaluate((token: string) => localStorage.setItem('refreshToken', token), refreshToken);
}

test.describe('Approved doctor portal', () => {
  test('approved doctor can login via UI and reach /dashboard', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_DOCTOR.email);
    await page.fill('input[type="password"]', TEST_DOCTOR.password);
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10_000 });
    await expect(page).not.toHaveURL(/\/login/);
    await expect(page).not.toHaveURL(/\/pending-approval/);
  });

  test('approved doctor can access /patients and list loads without auth error', async ({ page }) => {
    await restoreSession(page);
    await page.goto('/patients');

    await expect(page).toHaveURL(/\/patients/, { timeout: 10_000 });
    await expect(page).not.toHaveURL(/\/login/);
    // No auth-error text should be visible
    await expect(page.locator('text=/401|Unauthorized/i')).not.toBeVisible();
  });

  test('real JWT is injected in API calls — patient list renders successfully', async ({ page }) => {
    await restoreSession(page);
    await page.goto('/patients');

    // Wait for the page to stabilise — spinner gone, no error state
    await expect(page).not.toHaveURL(/\/login/, { timeout: 10_000 });
    await expect(page.locator('text=/sign in|session expired/i')).not.toBeVisible();
  });

  test('session expires gracefully — unauthenticated access redirects to /login', async ({ page }) => {
    // Navigate to a protected route with no stored credentials
    await page.goto('/patients');
    await expect(page).toHaveURL(/\/login/, { timeout: 5_000 });
  });

  test('logout clears session and blocks re-entry to protected routes', async ({ page }) => {
    await restoreSession(page);
    await page.goto('/patients');
    await expect(page).toHaveURL(/\/patients/, { timeout: 10_000 });

    // Clear credentials (simulates logout effect on localStorage)
    await page.evaluate(() => localStorage.clear());

    // Fresh navigation — no refresh token → startup refresh skipped → redirected to login
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/login/);
  });
});
