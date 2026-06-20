# PatientApp — As-Is Teardown

**Date:** June 2026
**Scope:** Patient-facing web application for knee exoskeleton rehabilitation

---

## 1. Executive Summary

PatientApp is a vanilla JavaScript + Firebase web application serving as the patient-facing portal for the knee exoskeleton rehabilitation system. It provides an exercise-tracking interface, pain logging via emoji scale, messaging with the therapist, and a progress dashboard.

**What it does today:**
- Patient authentication via Firebase Auth
- Exercise session timers with set/rep tracking (client-side only)
- Pain level self-reporting (0–10 emoji scale)
- Static chat messaging UI
- Progress dashboard with hardcoded values

**Critical risks:**
- **Firebase credentials hardcoded and exposed** in client code — a production security vulnerability
- **Zero device communication** (no BLE, no local WiFi) — the spec's core architectural requirement
- **No backend data flows** — no session upload, no config fetch, no sensor data handling
- **All state ephemeral** — every exercise, pain log, and message is lost on page refresh
- **Manifest branding mismatch** — manifest says "PhysioTrack" but the app is branded "Knevo"
- **Not React Native** — spec names React Native; this is a vanilla JS web app

**Verdict:** A non-functional UI prototype suitable for design review only. Zero implementation of the spec's core device communication, session management, or data persistence requirements.

---

## 2. Architecture & Product Overview

### 2.1 Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| **Frontend** | HTML5, CSS3, Vanilla JS (ES6 modules) | No framework — not React Native as spec states |
| **Auth** | Firebase Auth 11.0.0 | Credentials hardcoded in client code |
| **Database** | Firebase Firestore (configured, not used) | Project: `physiotrack-c8d8d` |
| **Styling** | Plain CSS3 | Grid/Flexbox, CSS variables, responsive breakpoints |
| **Package management** | npm | Single dependency: `firebase@^12.12.0` — imported via CDN, not npm |
| **Build** | None | No bundler, no transpiler, no build step |
| **Target** | Web (PWA manifest present) | No service worker registered |

### 2.2 File Structure

```
patientapp/
├── index.html          # Login screen + full app shell (318 lines)
├── js/
│   └── jsapp.js        # All app logic (179 lines)
├── css/
│   └── style.css       # All styling (684 lines)
├── manifest.json       # PWA manifest — branding wrong
├── package.json        # Firebase dependency (unused via npm)
├── package-lock.json
└── logo.PNG            # Knevo brand
```

### 2.3 Component Structure

**Login & Auth** (index.html lines 15–46)
- Email/password form → `login()` → Firebase `signInWithEmailAndPassword()`
- Success: hides login, shows app. No registration, no forgot password.

**Navigation** (index.html lines 39–54)
- Five tabs: Home, Exercises, Progress, Messages, Profile
- `showSection()` toggles visibility

**Dashboard / Home** (index.html lines 59–171)
- Hardcoded stats cards (exercises count, recovery %, pain level)
- Pain check-in: emoji face selector (0–10 scale) — client memory only
- Today's plan: 3 hardcoded exercises (Heel Slides, Straight Leg Raise, Quad Sets)
- Hardcoded appointment and therapist note

**Exercises** (index.html lines 174–236)
- 3 exercise cards with countdown timers
- `startExercise(id, seconds, totalSets)` → `setInterval()` countdown
- `markDone()` disables buttons — no data persisted

**Progress** (index.html lines 239–258)
- 3 static stat cards: Completion 85%, ROM 112°, Walking: Improving
- No dynamic data

**Messages** (index.html lines 261–285)
- Static sample chat; `sendMessage()` appends to DOM — lost on refresh

**Profile** (index.html lines 288–311)
- Fully static: "Sarah Ali", "Dr. Ahmed", "Device Connected"

### 2.4 Key User Flows

**Login:** Email/password → Firebase Auth → show app shell

**Exercise session:** Tap "Start Set 1" → countdown timer → "Start Set 2" → `markDone()` → buttons disabled. All local; nothing sent anywhere.

**Pain log:** Select emoji face → `logPain()` → UI feedback. Not sent to backend.

**Message therapist:** Type → Send → appended to DOM. Lost on refresh.

### 2.5 Integration Points

| Integration | Spec Requires | Implemented |
|-------------|--------------|-------------|
| Firebase Auth | Yes (or equivalent) | Yes — but credentials hardcoded |
| Firebase Firestore (session data) | Yes | No — configured but never called |
| BLE (device provisioning, session control, config delivery) | Yes | No |
| Local WiFi (sensor data relay) | Yes | No |
| Backend config fetch | Yes | No |

### 2.6 Notable Design Decisions

1. **Vanilla JS, no framework** — no build overhead; quick to prototype; does not match spec's React Native requirement
2. **Firebase credentials in client code** — common prototype shortcut; critical risk in production
3. **All state in memory** — simplest approach; means zero data survives a refresh
4. **Emoji pain scale** — accessible, patient-friendly UX; not mapped to a validated clinical scale
5. **Hardcoded patient data** — name, doctor, appointment, exercises all static

---

## 3. Detailed Findings

### 3.1 File-by-File Breakdown

#### index.html (318 lines)

- Lines 1–12: Head; meta, manifest, stylesheet
- Lines 14–36: Login form (hardcodes no defaults; no validation)
- Lines 38–312: Main app (hidden until login)
- Hard-coded strings: "Sarah Ali" (lines 25, 63, 296), "Dr. Ahmed" (lines 270, 304), appointment "Thursday, 16 April • 11:00 AM" (line 162)
- Inline `onclick` handlers mixed with JS-attached listeners

#### js/jsapp.js (179 lines)

**Firebase init (lines 1–14) — credentials fully exposed:**
```
apiKey: "AIzaSyDUyO5dnWqeQkb2bMsOVFRxwDTunhPwi5Q"
projectId: "physiotrack-c8d8d"
```

**Global state (lines 16–17):**
```js
let selectedPainLevel = null;
let selectedPainLabel = null;
```

**Function inventory:**

| Function | Lines | Behaviour | Issues |
|----------|-------|-----------|--------|
| `setGreeting()` | 19–26 | Time-based greeting | Hardcodes "Sarah" |
| `login()` | 28–39 | Firebase sign-in | No input validation; error shown only as alert |
| `logout()` | 41–45 | Firebase sign-out | Doesn't clear local exercise/pain state |
| `showSection()` | 47–52 | Tab switching | Assumes all sections exist |
| `selectFace()` | 54–60 | Records pain level | Clears feedback on re-select (good UX) |
| `logPain()` | 62–94 | Validates + updates UI | No backend call |
| `startExercise()` | 99–140 | `setInterval` countdown | No device signal; no session record |
| `markDone()` | 142–155 | Disables buttons | No persistence |
| `sendMessage()` | 157–170 | Appends to DOM | Lost on refresh; no backend |
| Window exports | 172–179 | Global function exposure | Anti-pattern; pollutes global scope |

#### css/style.css (684 lines)

- CSS custom properties for theming (lines 1–20)
- Brand colour: `#E8007D` (Knevo magenta)
- Responsive breakpoints: 992px, 768px, 600px
- No dark mode
- Pain emoji selector with hover effects (lines 593–644)
- Chat bubble styling (lines 445–519)

#### manifest.json

```json
{
  "name": "PhysioTrack Patient Portal",   ← wrong brand
  "theme_color": "#4f46e5",              ← conflicts with app's #E8007D
  "icons": [ "icons/icon-192.png" ]      ← icons/ directory does not exist
}
```

#### package.json

- Single dependency: `firebase@^12.12.0`
- Firebase is imported from CDN in jsapp.js — npm dep is unused
- No build scripts, no test runner, no linter

### 3.2 Technologies & Libraries

| Library | Version | Usage |
|---------|---------|-------|
| Firebase Auth | 11.0.0 (CDN) | Login / logout |
| Firebase Firestore | 11.0.0 (CDN) | Imported but never called |
| CSS3 (native) | — | All styling |
| ES6 Modules (native) | — | `import`/`export` |
| `setInterval` (native) | — | Exercise countdown timers |

### 3.3 Functionalities Implemented

**Implemented:**
- Email/password login via Firebase Auth
- Tab-based navigation (5 sections)
- Emoji pain selector with contextual feedback
- Exercise countdown timers with set tracking
- Mark exercise done
- In-memory chat send
- Responsive layout

**NOT implemented (spec requires):**
- BLE device provisioning
- BLE session start/stop signals
- BLE config delivery
- Local WiFi sensor data relay
- Session data upload to backend
- Config fetch from backend
- Sensor graphs (knee angle, FSR)
- Patient registration
- Enrollment code generation/display
- Patient-doctor linking
- Persistent pain logs
- Persistent session records
- Progress trends from real data

### 3.4 Code Quality

**Strengths:** Clean HTML/CSS, accessible emoji UX, CSS variables, responsive design

**Weaknesses:**
- Firebase credentials hardcoded and visible — critical
- No input validation on login form
- No error handling beyond login catch
- No tests
- Inline `onclick` handlers instead of event listeners
- Hardcoded user data throughout
- No service worker (manifest present but SW not registered)
- `icons/` directory referenced in manifest does not exist
- Global mutable state without guards
- 417-line monolithic JS file with no component separation

---

## 4. Contradictions with PhysioTrack

| Aspect | PatientApp | PhysioTrack | Conflict |
|--------|-----------|------------|---------|
| **App name** | "Knevo" in app UI | "PhysioTrack" in manifest and UI | Two brand names for the same system |
| **Primary colour** | `#E8007D` magenta | `#2563eb` blue | Incompatible design systems |
| **Firebase** | Configured + Auth used | No Firebase imports at all | Different backend assumptions |
| **Exercise model** | 3 hardcoded exercises with timers | 4 exercises in library with add-to-plan | Different sets; no shared source |
| **Progress metrics** | "78%" static | `progress: 75`, `compliance: 82` per patient | Different schema and values |
| **Device status** | Hardcoded "Connected" | `device: 'online'/'offline'` string | Different representation |
| **Persistence** | None (memory) | None (memory) | Consistent failure to persist |
| **Module system** | ES6 modules via CDN | CommonJS via npm | Incompatible patterns |

**Deeper conflict — patient portal inside clinician repo:**
`physiotrack/index3.html` is a patient-facing UI embedded inside the clinician web app repo. This is the same concern as PatientApp but implemented separately with a different codebase. The two patient UIs are out of sync and cannot share a backend.

**Neither app implements the config delivery chain.** PhysioTrack has a plan builder but no send mechanism. PatientApp has no config receive UI. The spec's core flow (doctor → backend → mobile → device) is broken at every link.

---

## 5. Contradictions with the Spec

| Spec Requirement | PatientApp Status |
|-----------------|------------------|
| **React Native / iOS** | Web app (vanilla JS). Not React Native. Runs in browser, not natively. |
| **BLE provisioning** | Not implemented — no BLE library |
| **BLE session control** | Not implemented — timers are local |
| **Local WiFi data relay** | Not implemented — no socket or listener |
| **Backend session upload** | Not implemented — Firestore never written to |
| **Config fetch from backend** | Not implemented |
| **Config delivery via BLE** | Not implemented |
| **Patient self-registration** | Not implemented — login only |
| **Enrollment code generation** | Not implemented |
| **Single USER table with role field** | Not implemented — Firebase Auth used but no role stored |
| **Session entity** (IN_PROGRESS / COMPLETED / INTERRUPTED) | Not implemented |
| **SensorReading entity** | Not implemented |
| **TherapyConfig display** | Not implemented |

**Architectural conflict:** The spec defines mobile-as-relay: device → mobile app → backend. PatientApp connects to nothing (no device, no backend writes). It is neither a relay nor a client; it is a standalone UI shell.

### Customer Problem Coverage

| Problem | Spec Solution | PatientApp |
|---------|--------------|-----------|
| P1 — no objective feedback | Sensor data + session analytics | Nothing — no sensors, no graphs |
| P2 — doctors can't track remotely | Session upload + dashboard | Nothing — no upload |
| P3 — static prescriptions | Config system | Nothing — no config |
| P4 — no delivery channel | Config push flow | Nothing — no push |
| P5 — no adherence visibility | Session recording + frequency tracking | Nothing — no recording |

---

## 6. Gaps vs the Spec

### Feature Gaps

| Feature | Status | What's Needed |
|---------|--------|--------------|
| BLE WiFi provisioning | Missing | BLE library, SSID/password UI, provisioning handshake |
| Session start/stop via BLE | Missing | BLE write on "Start Session"; create SESSION in Firestore |
| Local WiFi sensor relay | Missing | TCP socket or HTTP listener to device's local IP |
| Session data upload | Missing | Firestore write on session end: SESSION + SENSOR_READINGs |
| Config fetch on startup | Missing | Firestore read: latest TherapyConfig where `delivered_at = null` |
| Config delivery via BLE | Missing | BLE characteristic write at session start |
| Patient registration | Missing | `createUserWithEmailAndPassword()` + enrollment code generation |
| Enrollment code display | Missing | Generate code after registration; show with copy/share |
| Doctor linking | Missing | Fetch assigned doctor from USER record; display dynamically |
| Sensor graphs | Missing | Chart.js + SESSION/SENSOR_READING data from Firestore |
| Progress trends | Missing | Aggregate SESSION records; plot over time |
| Persistent pain logs | Missing | Firestore write in `logPain()` |
| Therapy config display | Missing | Fetch active TherapyConfig; show in UI |
| Real appointment data | Missing | Fetch from backend; replace hardcoded date |

### Non-Functional Gaps

| Requirement | Status |
|-------------|--------|
| Credentials security | Critical — hardcoded Firebase API key in client |
| Input validation | None on login form |
| Error handling | Only login catch; no network error handling |
| Offline support | Service worker not registered |
| Data persistence | None beyond Firebase Auth session |
| Tests | None |

---

## 7. Summary

**What works:** Firebase login/logout, exercise countdown timers (UI only), emoji pain selector, responsive layout, tab navigation.

**What doesn't work:** Everything the spec requires — device communication, sensor data relay, backend data flows, session recording, config delivery, patient registration, and enrollment.

**Critical security issue:** Firebase credentials exposed in `js/jsapp.js` lines 4–11. Rotate keys before any public deployment.

**Platform mismatch:** Spec calls for React Native iOS. This is a vanilla JS web app. This is not a blocking problem if the team decides to keep it as a web app, but the decision needs to be made explicitly and the spec updated.

**Deployment readiness:** Prototype only. Not suitable for clinical use.
