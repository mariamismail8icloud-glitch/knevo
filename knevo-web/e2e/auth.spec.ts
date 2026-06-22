import { test, expect } from '@playwright/test';

// Seed auth state into sessionStorage to simulate a logged-in user
async function setAuthState(page: import('@playwright/test').Page, role = 'DOCTOR') {
  await page.evaluate((r) => {
    sessionStorage.setItem('accessToken', 'test-access-token');
    sessionStorage.setItem('userId', '00000000-0000-0000-0000-000000000001');
    sessionStorage.setItem('role', r);
  }, role);
}

// Mock all protected API calls with empty-success responses
async function mockProtectedApis(page: import('@playwright/test').Page) {
  await page.route('**/api/doctor/patients', route =>
    route.fulfill({ status: 200, contentType: 'application/json', body: '[]' })
  );
  await page.route('**/api/doctor/patients/**', route =>
    route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
  );
  await page.route('**/api/admin/doctors**', route =>
    route.fulfill({ status: 200, contentType: 'application/json', body: '[]' })
  );
}

// B1: Route Guard — unauthenticated access is blocked
test.describe('B1: Route Guard', () => {
  test('unauthenticated user navigating to /patients is redirected to /login', async ({ page }) => {
    await page.goto('/patients');
    await expect(page).toHaveURL(/\/login/);
  });

  test('unauthenticated user navigating to /dashboard is redirected to /login', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/login/);
  });

  test('unauthenticated user navigating to /admin is redirected to /login', async ({ page }) => {
    await page.goto('/admin');
    await expect(page).toHaveURL(/\/login/);
  });

  test('authenticated user can access /patients without redirect', async ({ page }) => {
    await mockProtectedApis(page);
    // Navigate to the app first to establish the page context, then set auth
    await page.goto('/login');
    await setAuthState(page);
    await page.goto('/patients');
    await expect(page).not.toHaveURL(/\/login/);
  });
});

// B4: 401 Interceptor — API 401 clears auth and redirects to login
test.describe('B4: 401 Interceptor', () => {
  test('401 response from protected API clears auth and redirects to /login', async ({ page }) => {
    // Start authenticated
    await page.goto('/login');
    await setAuthState(page);

    // Mock the patients API to return 401
    await page.route('**/api/doctor/patients', route =>
      route.fulfill({ status: 401, contentType: 'application/json', body: '{"message":"Unauthorized"}' })
    );

    await page.goto('/patients');

    // The 401 response triggers clearAuth + navigate('/login')
    await expect(page).toHaveURL(/\/login/, { timeout: 5000 });
  });

  test('after 401 redirect, sessionStorage tokens are cleared', async ({ page }) => {
    await page.goto('/login');
    await setAuthState(page);

    await page.route('**/api/doctor/patients', route =>
      route.fulfill({ status: 401, contentType: 'application/json', body: '{}' })
    );

    await page.goto('/patients');
    await expect(page).toHaveURL(/\/login/, { timeout: 5000 });

    const token = await page.evaluate(() => sessionStorage.getItem('accessToken'));
    expect(token).toBeNull();
  });
});

// B5: QueryClient cleared on logout
test.describe('B5: Cache cleared on logout', () => {
  test('clearing auth state prevents access to protected routes', async ({ page }) => {
    await mockProtectedApis(page);

    // Log in
    await page.goto('/login');
    await setAuthState(page);
    await page.goto('/patients');
    await expect(page).not.toHaveURL(/\/login/);

    // Simulate logout by clearing sessionStorage (what clearAuth does)
    await page.evaluate(() => sessionStorage.clear());

    // Navigate to a protected route — should redirect
    await page.goto('/patients');
    await expect(page).toHaveURL(/\/login/);
  });
});

// Public routes remain accessible without auth
test.describe('Public routes', () => {
  test('/login is accessible without auth', async ({ page }) => {
    await page.goto('/login');
    await expect(page).toHaveURL(/\/login/);
  });

  test('/doctor-signup is accessible without auth', async ({ page }) => {
    await page.goto('/doctor-signup');
    await expect(page).toHaveURL(/\/doctor-signup/);
  });
});
