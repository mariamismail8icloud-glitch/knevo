# knevo-web

React 19 + TypeScript + Tailwind CSS doctor portal for the Knevo rehabilitation system.

## Prerequisites

- Node.js 20+
- npm 10+
- `knevo-backend` running on `http://localhost:8080` (see backend README)

## Run for development

```bash
npm install
npm run dev
```

The dev server starts at `http://localhost:5173`.

The API base URL is read from `.env`:

```
VITE_API_BASE_URL=http://localhost:8080
```

This file is already committed with the correct default for local development.

## Run tests

```bash
npm install   # required first time
npm test
```

Runs Vitest in single-run mode. 24 tests across 12 files.

To run in watch mode during development:

```bash
npx vitest
```

## Lint

```bash
npm run lint
```

Runs ESLint with `--max-warnings 0`. Zero warnings allowed.

## Build for production

```bash
npm run build
```

Output goes to `dist/`. Set `VITE_API_BASE_URL` to your production API URL before building:

```bash
VITE_API_BASE_URL=https://api.yourhost.com npm run build
```

## Project structure

```
src/
├── api/            authApi.ts, doctorApi.ts, adminApi.ts
├── config/         api.ts (base URL)
├── context/        AuthContext.tsx (JWT storage + auth state)
├── pages/
│   ├── doctor/     PatientListPage, PatientDetailPage, PatientProgressTab,
│   │               ExerciseLibraryPage, CreatePlanPage, MessagesPage, EditConfigModal
│   └── admin/      AdminDashboardPage
│   LoginPage, DoctorSignupPage, PendingApprovalPage, DashboardPage
└── test/           Vitest + React Testing Library tests
```

## Accounts for local testing

After running the backend:

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@knevo.com` | `Admin1234!` |
| Doctor | sign up via `/doctor-signup`, approve via admin dashboard |

## Contributing

1. Wrap all protected routes in a `ProtectedRoute` component (not yet implemented — see known issues).
2. Use `useMutation` + `queryClient.invalidateQueries` for writes; avoid direct `setState` for server data.
3. Add a test for every new page component. Minimum: a render test and one interaction test.
4. Run `npm run lint` and `npm test` before committing.
5. All Tailwind tokens are defined in `tailwind.config.js` — use `text-primary`, `bg-base`, `shadow-knevo` etc. Do not hardcode `#E8007D`.

## Known issues

See `docs/codebase-web.md` for the full issue list. Critical items:
- No route guards — all pages are publicly accessible without login.
- No token refresh — the 15-minute access token expires silently.
- Tokens are in `sessionStorage` — they are lost on browser close/refresh.
