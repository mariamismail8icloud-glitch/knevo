import { test, expect } from '@playwright/test';

const MOCK_AUTH = {
  userId: '00000000-0000-0000-0000-000000000001',
  role: 'DOCTOR',
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  enrollmentCode: null,
};

// Sets up an authenticated session via the localStorage refresh-token mechanism.
// After calling this, the next page.goto will trigger startup refresh and authenticate.
async function mockAuthSession(page: import('@playwright/test').Page, role = 'DOCTOR') {
  await page.evaluate((r) => {
    localStorage.setItem('refreshToken', 'test-refresh-token');
    sessionStorage.setItem('userId', '00000000-0000-0000-0000-000000000001');
    sessionStorage.setItem('role', r);
  }, role);

  await page.route('**/api/auth/refresh', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ ...MOCK_AUTH, role }),
    })
  );
}

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
    await page.goto('/login');
    await mockAuthSession(page);
    await page.goto('/patients');
    await expect(page).toHaveURL(/\/patients/, { timeout: 5000 });
    await expect(page).not.toHaveURL(/\/login/);
  });
});

// B4: 401 Interceptor — API 401 clears auth and redirects to login
test.describe('B4: 401 Interceptor', () => {
  test('401 response from protected API clears auth and redirects to /login', async ({ page }) => {
    await page.goto('/login');
    await mockAuthSession(page);

    // Override patients mock to return 401 (refresh also fails on second call)
    let refreshCount = 0;
    await page.route('**/api/auth/refresh', route => {
      if (refreshCount++ === 0) {
        route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_AUTH) });
      } else {
        route.fulfill({ status: 401, contentType: 'application/json', body: '{}' });
      }
    });

    await page.route('**/api/doctor/patients', route =>
      route.fulfill({ status: 401, contentType: 'application/json', body: '{"message":"Unauthorized"}' })
    );

    await page.goto('/patients');
    await expect(page).toHaveURL(/\/login/, { timeout: 8000 });
  });

  test('after failed auth, localStorage refresh token is cleared', async ({ page }) => {
    await page.goto('/login');
    await mockAuthSession(page);

    let refreshCount = 0;
    await page.route('**/api/auth/refresh', route => {
      if (refreshCount++ === 0) {
        route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_AUTH) });
      } else {
        route.fulfill({ status: 401, contentType: 'application/json', body: '{}' });
      }
    });

    await page.route('**/api/doctor/patients', route =>
      route.fulfill({ status: 401, contentType: 'application/json', body: '{}' })
    );

    await page.goto('/patients');
    await expect(page).toHaveURL(/\/login/, { timeout: 8000 });

    const refreshToken = await page.evaluate(() => localStorage.getItem('refreshToken'));
    expect(refreshToken).toBeNull();
  });
});

// B5: Cache cleared on logout — PrivateRoute blocks after session is cleared
test.describe('B5: Session cleared on logout', () => {
  test('clearing localStorage refresh token prevents access to protected routes on next navigation', async ({ page }) => {
    await mockProtectedApis(page);
    await page.goto('/login');
    await mockAuthSession(page);
    await page.goto('/patients');
    await expect(page).toHaveURL(/\/patients/, { timeout: 5000 });

    // Simulate logout: clear the refresh token from localStorage
    await page.evaluate(() => localStorage.clear());

    // Fresh navigation — no refresh token → startup refresh skipped → not authenticated → /login
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

// B2: Token refresh — 401 retried with refreshed token instead of immediate logout
test.describe('B2: Token refresh on 401', () => {
  test('401 on API call is retried after silent token refresh', async ({ page }) => {
    await page.goto('/login');
    await page.evaluate(() => localStorage.setItem('refreshToken', 'initial-refresh'));

    await page.route('**/api/auth/refresh', route =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(MOCK_AUTH),
      })
    );

    // First call to patients returns 401; second (after retry) returns 200
    let patientsCallCount = 0;
    await page.route('**/api/doctor/patients', route => {
      if (patientsCallCount++ === 0) {
        route.fulfill({ status: 401, contentType: 'application/json', body: '{}' });
      } else {
        route.fulfill({ status: 200, contentType: 'application/json', body: '[]' });
      }
    });

    await page.goto('/patients');

    // Startup refresh restores session; patients 401 is retried and succeeds
    await expect(page).toHaveURL(/\/patients/, { timeout: 8000 });
    await expect(page).not.toHaveURL(/\/login/);
  });

  test('failed refresh on 401 logs the user out', async ({ page }) => {
    await page.goto('/login');
    await page.evaluate(() => localStorage.setItem('refreshToken', 'initial-refresh'));

    // Startup refresh succeeds; second refresh (triggered by 401) fails
    let refreshCallCount = 0;
    await page.route('**/api/auth/refresh', route => {
      if (refreshCallCount++ === 0) {
        route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_AUTH) });
      } else {
        route.fulfill({ status: 401, contentType: 'application/json', body: '{}' });
      }
    });

    await page.route('**/api/doctor/patients', route =>
      route.fulfill({ status: 401, contentType: 'application/json', body: '{}' })
    );

    await page.goto('/patients');
    await expect(page).toHaveURL(/\/login/, { timeout: 8000 });
  });
});

// B3: Token storage — access token must not be in sessionStorage
test.describe('B3: Token storage hardening', () => {
  test('access token is not written to sessionStorage after login', async ({ page }) => {
    await page.route('**/api/doctor/**', route =>
      route.fulfill({ status: 200, contentType: 'application/json', body: '[]' })
    );
    await page.route('**/api/auth/login', route =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          userId: 'doctor-1',
          role: 'DOCTOR',
          accessToken: 'secret-access-token',
          refreshToken: 'secret-refresh-token',
          enrollmentCode: null,
        }),
      })
    );

    await page.goto('/login');
    await page.fill('input[type="email"]', 'doctor@test.com');
    await page.fill('input[type="password"]', 'Password123!');
    await page.click('button[type="submit"]');
    await expect(page).not.toHaveURL(/\/login/, { timeout: 5000 });

    // Access token must NOT be in sessionStorage (XSS mitigation)
    const sessionToken = await page.evaluate(() => sessionStorage.getItem('accessToken'));
    expect(sessionToken).toBeNull();

    // Refresh token must be in localStorage (persists across tabs)
    const localRefresh = await page.evaluate(() => localStorage.getItem('refreshToken'));
    expect(localRefresh).toBe('secret-refresh-token');
  });

  test('page reload with stored refresh token restores session without redirect', async ({ page }) => {
    await page.goto('/login');
    await page.evaluate(() => localStorage.setItem('refreshToken', 'stored-refresh'));

    await page.route('**/api/auth/refresh', route =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(MOCK_AUTH),
      })
    );
    await page.route('**/api/doctor/patients', route =>
      route.fulfill({ status: 200, contentType: 'application/json', body: '[]' })
    );

    await page.goto('/patients');
    await expect(page).toHaveURL(/\/patients/, { timeout: 5000 });
    await expect(page).not.toHaveURL(/\/login/);
  });
});
