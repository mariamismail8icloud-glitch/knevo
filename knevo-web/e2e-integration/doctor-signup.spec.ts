import { test, expect } from '@playwright/test';
import type { Page } from '@playwright/test';
import { BACKEND } from './constants';

function uniqueDoctor() {
  const id = `${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
  return {
    name: 'Integration Doctor',
    email: `dr-${id}@integration.test`,
    username: `dr${id.replace('-', '')}`,
    password: 'Password123!',
    clinicName: 'Integration Clinic',
    specialization: 'Rehabilitation',
  };
}

// Navigates label → direct parent div → input.
// More precise than filter({ has: label }) which matches all ancestor divs.
function fieldInput(page: Page, labelText: string) {
  return page.locator('label', { hasText: labelText }).locator('xpath=..').locator('input');
}

async function fillSignupForm(page: Page, doc: ReturnType<typeof uniqueDoctor>) {
  await fieldInput(page, 'Full name').fill(doc.name);
  await fieldInput(page, 'Email').fill(doc.email);
  await fieldInput(page, 'Username').fill(doc.username);
  await page.locator('input[type="password"]').first().fill(doc.password);
  await page.locator('input[type="password"]').nth(1).fill(doc.password);
  await fieldInput(page, 'Clinic').fill(doc.clinicName);
  await fieldInput(page, 'Specialization').fill(doc.specialization);
}

test.describe('Doctor signup', () => {
  test('signup form submits to real backend and redirects to pending-approval', async ({ page }) => {
    const doc = uniqueDoctor();
    await page.goto('/doctor-signup');
    await fillSignupForm(page, doc);
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL(/\/pending-approval/, { timeout: 10_000 });
  });

  test('unapproved doctor login returns 403 and redirects to pending-approval', async ({ page, request }) => {
    const doc = uniqueDoctor();

    // Create pending doctor via API — faster than re-filling the UI form
    const signup = await request.post(`${BACKEND}/api/auth/signup/doctor`, { data: doc });
    expect(signup.status()).toBe(202);

    await page.goto('/login');
    await page.fill('input[type="email"]', doc.email);
    await page.fill('input[type="password"]', doc.password);
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL(/\/pending-approval/, { timeout: 10_000 });
  });

  test('login with wrong credentials shows error and stays on /login', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[type="email"]', 'nobody@example.com');
    await page.fill('input[type="password"]', 'WrongPassword99!');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL(/\/login/);
    await expect(page.locator('text=/Invalid|Unauthorized/i')).toBeVisible({ timeout: 5_000 });
  });
});
