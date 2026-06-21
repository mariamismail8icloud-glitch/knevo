# Build Milestones

> Mindset: release early, release often. Each milestone must be demo-able end-to-end — not a layer, not a service, not a screen in isolation. A milestone is done when one working slice of the system can be shown running.
>
> Reference flows (from `spec-and-architecture.md §4.6`) are noted on the milestones that complete them.

---

## Phase 1 — Software (no hardware required)

---

### M0 — Project Scaffold

**Goal:** All three apps start locally with no errors and talk to the same database.

| Component | What's built |
|-----------|-------------|
| Backend | Spring Boot + Gradle Kotlin project; Flyway migration setup; Docker Compose for PostgreSQL; health check endpoint |
| Patient app | Swift/SwiftUI project; tab navigation skeleton; environment config (base URL) |
| Doctor portal | React + TypeScript + Tailwind project; basic routing skeleton; environment config |

---

### M1 — Patient Can Register and Log In

**Goal:** A new patient can sign up, confirm their account, and reach the home screen.

| Component | What's built |
|-----------|-------------|
| Backend | `USER` table; `POST /auth/signup`; `POST /auth/login`; JWT access + refresh tokens; `POST /auth/refresh`; `POST /auth/logout` |
| Patient app | Signup screen; Login screen; empty Home screen; token storage |

---

### M2 — Doctor Can Log In

**Goal:** A doctor signs up, an admin approves their account, and the doctor reaches an empty portal.

| Component | What's built |
|-----------|-------------|
| Backend | Doctor signup flow; admin-only approval endpoint; seeded admin account; `GET /admin/pending-doctors`; `POST /admin/approve/:id` |
| Doctor portal | Signup screen; "Pending approval" state screen; Login screen; empty Dashboard |

---

### M3 — Patient and Doctor Are Linked

**Goal:** Patient generates an enrollment code; doctor enters it; patient appears in doctor's list.

| Component | What's built |
|-----------|-------------|
| Backend | `POST /patients/enrollment-code` (generate); `POST /doctor/enroll` (redeem code, sets `doctor_id`); `GET /doctor/patients` |
| Patient app | "Share enrollment code" screen on first login |
| Doctor portal | "Enroll patient" form; patient list page |

---

### M4 — Doctor Prescribes a Therapy Plan

**Goal:** Doctor creates a therapy plan with sets for a linked patient; patient sees it in the app.

| Component | What's built |
|-----------|-------------|
| Backend | `EXERCISE` table (seeded with reference data); `THERAPY_CONFIG`; `THERAPY_SET_CONFIG`; `POST /therapy-config`; `GET /therapy-config/:id` |
| Doctor portal | Exercise library view; Create therapy plan form (sets, duration, schedule, safety limits) |
| Patient app | Active plan view (read-only); set list with exercise details |

> Completes the first half of **Flow 2 — Doctor Issues Therapy Config**.

---

### M5 — Patient Completes a Mobile-Only Session

**Goal:** Patient runs a full session — pre-session pain check, set timers, in-set pain button, post-session pain — and the session is saved.

| Component | What's built |
|-----------|-------------|
| Backend | `SESSION`; `THERAPY_SET_RECORD`; `POST /sessions`; `POST /sessions/:id/start-set`; `POST /sessions/:id/stop-set`; `PATCH /sessions/:id/complete`; pain fields on Session |
| Patient app | Pre-session pain check screen (blocks session if ≥ 7); active session screen with set timer; in-session pain button (terminates session on tap); post-session pain and feedback form; session summary screen |

> Enables **Flow 1 — Therapy Session** (mobile-only variant, no device).

---

### M6 — Doctor Reviews Session Data

**Goal:** Doctor navigates to a patient's completed sessions and sees pain levels and set records.

| Component | What's built |
|-----------|-------------|
| Backend | `GET /doctor/patients/:id/sessions`; `GET /sessions/:id` with set records |
| Doctor portal | Patient detail page; session list; session detail view (set records, pain before/during/after) |

---

### M7 — Config Update Reaches the App in Real Time

**Goal:** Doctor changes a therapy config; the patient's app reflects the update within seconds without the patient opening the app; session reminders adjust automatically.

| Component | What's built |
|-----------|-------------|
| Backend | `PUT /therapy-config/:id`; push notification to patient's device (WebSocket or APNs silent push); `PATCH /therapy-config/:id/delivered` |
| Patient app | Config sync on app open + push-triggered background sync; local push notifications scheduled from `schedule` field; reminder updates without user action |
| Doctor portal | Edit therapy config form |

> Completes **Flow 2 — Doctor Issues Therapy Config** and **Flow 3 — Real-Time Config Sync**.

---

### M8 — Doctor and Patient Can Message Each Other

**Goal:** Doctor sends a message to a patient; patient sees it in real time and can reply.

| Component | What's built |
|-----------|-------------|
| Backend | `MESSAGE` table; WebSocket chat endpoint; `GET /messages/:thread` |
| Patient app | Messages screen; real-time message delivery |
| Doctor portal | Messages screen; patient message threads |

---

### M9 — Progress and Reports

**Goal:** Doctor sees a patient's session history with trend metrics; patient sees their own progress summary.

| Component | What's built |
|-----------|-------------|
| Backend | Aggregation queries: sessions per week, pain trend, plan adherence; `GET /patients/:id/progress` |
| Doctor portal | Progress chart (sessions over time); pain trend; adherence to schedule |
| Patient app | Progress screen with session count and pain history |

---

## Phase 2 — Hardware Integration

---

### M10 — Device Connects to WiFi via BLE Provisioning

**Goal:** Patient app scans for the exoskeleton device over BLE, provisions WiFi credentials, and the device connects to the local network.

| Component | What's built |
|-----------|-------------|
| Patient app | BLE scan screen; Core Bluetooth connect; GATT write of WiFi credentials; provisioning confirmation |
| Device (ESP32-S3) | BLE peripheral GATT service; accept WiFi SSID + password over BLE; connect to WiFi; confirm status back over BLE |

---

### M11 — Device-Assisted Session Runs End-to-End

**Goal:** Patient starts a device-assisted set; the device captures 100 Hz sensor data; data reaches the backend and is stored against the correct TherapySetRecord.

| Component | What's built |
|-----------|-------------|
| Patient app | BLE config delivery at session start; set-start signal over BLE; 100 Hz WiFi stream reception from device; relay to backend via HTTPS; buffered upload on reconnect |
| Device (ESP32-S3) | BLE config receive + apply; BLE set-start handler; sensor capture loop (IMU × 3, FSR × 2) at 100 Hz over WiFi; local buffer on WiFi loss |
| Backend | `SENSOR_READING` bulk insert; accept relay from app; associate readings with `therapy_set_record_id` |

> Enables **Flow 1 — Therapy Session** (device-assisted variant) and **Flow 4 — WiFi Loss Mid-Session**.

---

### M12 — Doctor Sees Session Sensor Data

**Goal:** After a device-assisted session, the doctor opens the session detail and sees graphs of knee angle and FSR load over time.

| Component | What's built |
|-----------|-------------|
| Backend | `GET /sessions/:id/sensor-readings` (paginated/downsampled for UI) |
| Doctor portal | Knee angle over time graph; FSR load graph; basic per-set breakdown |

---

### M13 — Emergency Stop and Doctor Remote Controls

**Goal:** Doctor can remotely stop a live session from the portal; patient's app and device respond immediately. All safety-critical changes are audit-logged.

| Component | What's built |
|-----------|-------------|
| Backend | `POST /sessions/:id/remote-stop`; doctor can lower limits but not raise them mid-session; `AUDIT_LOG` writes on all safety changes |
| Doctor portal | Live session monitor; remote stop button; limit adjustment controls (lower only) |
| Patient app | Receive remote-stop push; send emergency stop signal to device over BLE; display safety message |
| Device (ESP32-S3) | Emergency stop handler; graceful shutdown; status confirmation back to app |

---

### M14 — BLE Heartbeat and Disconnect Safety

**Goal:** If BLE is lost for more than 5 seconds during a device-assisted set, the session stops and is saved cleanly — no data loss, no stuck state.

| Component | What's built |
|-----------|-------------|
| Patient app | Heartbeat monitor (500 ms interval; 2 s warning; 5 s → auto-stop session); displays disconnect warning |
| Device (ESP32-S3) | Heartbeat sender (500 ms–1 s); triggers local emergency stop if app heartbeat absent |
| Backend | Session saved as `INTERRUPTED` with correct timestamps and any buffered data |

---

## Phase 3 — AI & Analytics

---

### M15 — On-Device Gait Classification

**Goal:** During a device-assisted set, the ESP32-S3 classifies each sample into one of 6 gait phases in real time; phase labels are stored in SENSOR_READING.

| Component | What's built |
|-----------|-------------|
| Device (ESP32-S3) | TinyML model (trained offline on the knevo_dataset); inference in acquisition loop; gait_phase_label populated per sample |
| Backend | gait_phase_label accepted and stored (was `unlabeled` placeholder before) |

---

### M16 — Data Analytics Service Produces Session Insights

**Goal:** After a session completes, the Data Analytics Service processes sensor readings and writes a SessionInsight record with step count, cadence, gait phase distribution, and anomaly flags.

| Component | What's built |
|-----------|-------------|
| Backend | Data Analytics Service triggered post-session; SessionInsight schema (resolves OD-3); `GET /sessions/:id/insight` |

---

### M17 — AI Reports in Doctor Portal

**Goal:** Doctor opens a completed session and sees the AI-derived analysis: gait metrics, anomaly flags, and session-over-session trends.

| Component | What's built |
|-----------|-------------|
| Doctor portal | SessionInsight display panel; gait phase distribution chart; anomaly highlight; trend comparison across sessions |
