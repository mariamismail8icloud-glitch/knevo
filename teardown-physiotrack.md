# PhysioTrack — As-Is Teardown

**Date:** June 2026
**Scope:** Clinician-facing web application for knee rehabilitation patient management

---

## 1. Executive Summary

PhysioTrack is a web-based patient management dashboard designed for physiotherapists to monitor rehabilitation progress for knee exoskeleton patients. It displays mock patient data with status tracking, exercise prescriptions, messaging, and PDF reporting. **This is a demo/prototype with zero backend integration** — all data is hardcoded in JavaScript; there is no API, database, or authentication mechanism. The app cannot scale beyond the four demo patients embedded in `js/data.js`.

**Critical risk:** The spec mandates a backend (Firebase or Spring Boot), real-time data pipelines from exoskeleton devices, and secure authentication. PhysioTrack has none of these. It is a UI shell only.

**Verdict:** Proof-of-concept UI suitable for design review or initial stakeholder demo. Requires complete backend implementation before clinical use.

---

## 2. Architecture & Product Overview

### 2.1 Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| **Frontend** | HTML5, CSS3, Vanilla JavaScript (ES6 modules) | No framework. Chart.js for graphs. |
| **Data** | In-memory JavaScript objects | `js/data.js` hardcoded with 4 patients, 3 messages, 4 exercises |
| **Offline** | Service Worker (3 versions: `sevice-worker.js`, `service-worker1.js`, `service-worker3.js`) | Basic cache-first PWA strategy. No sync. |
| **PWA Manifest** | 3 JSON files (`manifest.json`, `manifest1.json`, `manifest3.json`) | Near-identical content; versioning unclear |
| **Styling** | Single 478-line CSS file | BEM-like structure; light/dark theme via CSS variables |

### 2.2 Component Structure

**Entry Points (8+ HTML files):**

| File | Purpose |
|------|---------|
| `index.html` | Clinician dashboard v1 (status cards, patient list, alerts table) |
| `index2.html` | Clinician dashboard v2 (near-identical, links to `exercises2.html`) |
| `index3.html` | Patient portal (login, exercises, progress, messages, appointments) |
| `patients.html` | Patient directory with search/filter |
| `patient-details.html` | Individual patient view with charts |
| `exercises.html` | Exercise library and plan builder |
| `messages.html` | Message inbox and chat thread |
| `reports.html` | Weekly summary table with print support |

**JavaScript:**
- `js/app.js` (~417 lines) — Main app logic; mounts dashboard, patient, exercise, message, and report pages
- `js/data.js` (~117 lines) — Static patient list, messages, exercise library, status helpers
- `app.js` (~20 lines) — Patient portal (index3.html) login/logout and section navigation

### 2.3 Key User Flows

1. **Dashboard View** — Load `index.html` → JS counts patients by status → renders 3 status cards + patient grid + alerts table
2. **Patient Search** — Type in searchbar → filter by name/ID/diagnosis → re-render patient cards
3. **Patient Details** — Click patient card → navigate to `patient-details.html?id=PT-001` → fetch patient from data → render stats + alerts + Chart.js graphs
4. **Exercise Planning** — View exercise library table → click "Add" → append to in-memory plan array → render plan cards → click "Save" → shows alert (no persistence)
5. **Messages** — Load `messages.html` → display inbox → click conversation → render thread → type and send → appends to in-memory thread
6. **Reports** — Load `reports.html` → render summary cards and patient table → click "Print / Save as PDF" → invoke `window.print()`

### 2.4 Data Handled

**Patient model** (4 hardcoded records: PT-001 through PT-004):
- `id`, `name`, `status` (`improving` / `stable` / `needs-attention`)
- `nextVisit`, `exercisesDone`, `exercisesTotal`, `progress` (%)
- `diagnosis`, `painAvg`, `compliance` (%), `device` (`online` / `offline`)
- `alerts` (array of strings), `notes` (clinical notes)

**Messages model** (3 conversations): `patientId`, `patientName`, `unread`, `thread` (array of `{from, text, time}`)

**Exercise library** (4 entries): `name`, `category` (ROM / Strength / Activation / Balance), `sets`, `reps`, `notes`

**Data lifetime:** Session-only. All changes are in-memory; a page reload resets all state.

### 2.5 Integration Points

| Integration | Spec Requires | Implemented |
|-------------|--------------|-------------|
| Backend API | Yes | No |
| Authentication | Yes | No |
| Sensor data pipeline | Yes | No |
| Device status | Yes | Mock field only |
| Chart.js | — | Yes (CDN) |
| Service Worker / PWA | — | Yes (offline cache) |
| `window.print()` | — | Yes |
| `localStorage` | — | Yes (theme preference) |

### 2.6 Notable Design Decisions

1. **No backend** — All state lives in JavaScript objects. Appropriate for a frontend-only prototype; a liability for production.
2. **Multiple near-identical entry points** — `index.html` vs `index2.html`, `exercises.html` vs `exercises2.html`. Likely evolution artifacts, not intentional variants.
3. **Three service workers and three manifests** — No clear versioning or migration path between them.
4. **Responsive design** — `deviceHint()` returns "Mobile" (≤820px), "Tablet" (≤1100px), "Laptop" (>1100px).
5. **Theme toggle** — Light/dark mode via CSS variables; persisted in `localStorage`.

---

## 3. Detailed Findings

### 3.1 File-by-File Breakdown

| File | Lines (approx.) | Status |
|------|----------------|--------|
| `index.html` | 155 | Complete UI; no backend |
| `index2.html` | 152 | Near-identical to `index.html`; duplicate |
| `index3.html` | 392 | Separate patient portal app embedded in clinician repo |
| `patients.html` | 94 | Search/filter UI; all data from `js/data.js` |
| `patient-details.html` | 128 | Stats, alerts, Chart.js graphs |
| `exercises.html` | 104 | Plan builder; save is a mock alert |
| `messages.html` | 94 | Thread view; in-memory send |
| `reports.html` | 104 | Print-friendly summary |
| `js/app.js` | ~417 | All page mounting logic; no component separation |
| `js/data.js` | ~117 | Static data store |
| `app.js` (root) | ~20 | Patient portal login/section nav |
| `css/style.css` | 478 | Shared styles |
| `patient3.css` | — | Styles for `index3.html` patient portal |
| `sevice-worker.js` | — | Typo in filename; cache-first SW v1 |
| `service-worker1.js` | — | SW v2 |
| `service-worker3.js` | — | SW v3 |
| `excercises2.txt` | — | Plain text; content unclear |

### 3.2 Technologies & Libraries

| Technology | Version | Usage |
|-----------|---------|-------|
| HTML5, CSS3, Vanilla JS (ES6) | — | All UI and logic |
| Chart.js | v3 (CDN) | Progress, pain trend, compliance graphs in `patient-details.html` |
| Service Worker API | — | Offline caching |
| Web Manifest API | — | PWA installability |
| `localStorage` | — | Theme preference (`pt_theme`) |

### 3.3 Functionalities Implemented

**Clinician dashboard:**
- Patient status summary cards (improving / stable / needs-attention)
- Patient grid with status, next visit, exercises, progress bar
- Search/filter by name, ID, diagnosis, status
- Alerts table for patients needing attention

**Patient details:**
- Stats: diagnosis, device status, next visit, pain avg, compliance
- Alert list
- Quick-action buttons (Call, Message, Adjust Plan — all mock)
- Three Chart.js graphs: Rehab Progress (line), Pain Trend (line), Compliance (bar)

**Exercise planning:**
- Exercise library table
- Add-to-plan (in-memory)
- Save Plan button (mock alert, no persistence)

**Messages:**
- Inbox list with unread count and message preview
- Thread view with sender identification
- In-memory send (lost on reload)

**Reports:**
- Summary cards: total patients, devices offline, avg compliance
- Patient summary table
- `window.print()` for PDF export

**Patient portal (index3.html — embedded inside clinician repo):**
- Login screen (no validation)
- Dashboard with stats and emoji pain check-in
- Exercise list with timers and "Mark Done" buttons
- Progress, Messages, Appointments, Profile sections (all mock)

### 3.4 Code Quality

**Strengths:**
- Clean, readable vanilla JS
- Semantic HTML with proper heading hierarchy
- CSS variables for consistent theming
- `escapeHTML()` utility present (js/app.js ~line 395–398) — XSS surface mitigated
- Responsive flexbox/grid layout

**Weaknesses:**
- **No error handling** — functions assume data exists; rare null checks
- **Hardcoded strings** — fictional names, dates (Dec 30 2025; Jan 2 2026), diagnoses
- **No modularity** — 417-line `js/app.js` mounts all pages inline
- **Mixed event binding** — `onclick="login()"` in HTML alongside JS-attached listeners
- **No logging** — only service worker registration console.logs
- **Filename typo** — `sevice-worker.js` (missing 'r')
- **Three duplicate manifests/service workers** — no clear ownership
- **`!important` in print styles** — CSS specificity debt (reports.html line ~20)
- **No input validation** — all form inputs accept any value

---

## 4. Contradictions with patientapp

| Aspect | PhysioTrack (Web) | patientapp (Mobile) |
|--------|-------------------|---------------------|
| Authentication | None (demo data always visible) | Firebase Auth required |
| Data persistence | In-memory JS objects | Firebase Firestore (partially) |
| Exercise interface | Table + plan builder (prescription) | Timer-based execution (patient-facing) |
| Pain tracking | Column in patient list | Emoji face scale 0–10 |
| Device integration | Mock `online/offline` field | BLE provisioning implied |
| Session concept | Not present | Session start/stop flow present |
| Backend | None | Firebase (partially wired) |

**Key conflicts:**

1. **Authentication mismatch** — PhysioTrack has no auth; patientapp uses Firebase. They cannot share a user session or patient record.
2. **Exercise model divergence** — PhysioTrack prescribes exercises as a plan (name, sets, reps); patientapp executes exercises with timers and counters. No protocol defined between the two.
3. **No config delivery path** — PhysioTrack has a plan builder but no mechanism to push the plan to the patient's device or app. The spec requires: web app → backend → mobile app → device via BLE.
4. **Data model mismatch** — PhysioTrack tracks `exercisesDone / exercisesTotal` as integers; patientapp tracks per-set timer state. These cannot be reconciled without a shared session model.
5. **Patient portal in wrong repo** — `index3.html` inside physiotrack is a patient-facing UI. It belongs in patientapp, not the clinician web app.

---

## 5. Contradictions with the Spec

| Spec Requirement | PhysioTrack Status |
|------------------|-------------------|
| Backend API (Firebase or Spring Boot) | Missing entirely |
| Database (Firestore or PostgreSQL) | Missing — in-memory JS |
| Authentication & access control | Missing — demo always visible |
| Doctor-patient enrollment via code | Missing |
| Admin account for doctor enrollment | Missing |
| Therapy config: max speed, max ROM, duration, frequency, schedule | Partial — exercise plan builder exists but captures none of these fields |
| Config delivery: backend → mobile → device via BLE | Missing |
| Session lifecycle (IN_PROGRESS / COMPLETED / INTERRUPTED) | Missing |
| Raw sensor graphs (knee angle, FSR over time) | Partial — Chart.js graphs exist but use synthetic data |
| Progress trends across sessions | Partial — charts exist but not tied to real sessions |
| Sensor data (IMU, FSR, gait events) | Missing |
| Single USER table with role field | Not applicable — no backend |

**Architectural conflict:** The spec defines a mobile-as-relay architecture where the device talks to the mobile app, which talks to the backend. PhysioTrack is a standalone web UI with no connectivity to any of those components.

---

## 6. Gaps vs the Spec

### Feature Gaps

| Feature | Status | Notes |
|---------|--------|-------|
| Therapy config panel (max speed, max ROM, duration, frequency, schedule) | Missing | Exercise plan builder captures only name/sets/reps |
| Enrollment code redemption | Missing | No code input UI |
| Admin doctor management | Missing | No admin interface |
| Real-time sensor data display | Missing | Charts use hardcoded arrays |
| Session history per patient | Missing | No session entity in data model |
| Device pairing status detail | Missing | Only `online`/`offline` string |
| Config delivery confirmation (`delivered_at`) | Missing | No delivery tracking |
| Alert generation logic | Missing | Alerts are hardcoded strings |

### Non-Functional Gaps

| Requirement | Status |
|-------------|--------|
| Authentication | None |
| Authorization (role-based) | None |
| Data persistence | None |
| Scalability beyond 4 patients | None |
| Error handling | Minimal |
| Input validation | None |

---

## 7. Summary

**What works:** Responsive clinician dashboard UI, mock patient data rendering, exercise plan builder (in-memory), message thread viewer (in-memory), patient-side UI with exercise timers, dark/light theme toggle, PWA installability.

**What doesn't work:** Backend connection, user authentication, data persistence, device integration, real sensor data, multi-user isolation, config deployment to device.

**Deployment readiness:** Demo/prototype only. Not suitable for clinical use.
