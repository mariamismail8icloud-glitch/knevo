# Knevo — Implementation Detail Specification

> **Read `spec-and-architecture.md` first.** This document adds implementation-level detail only. It does not repeat the architecture, data model, or diagrams. Where this document conflicts with `spec-and-architecture.md`, the spec wins.
>
> **Source:** Distilled from `knevo_context.md`. Items that contradicted the spec have been discarded in favour of the spec.

---

## 1. Clinical Context

**Target patient:** Post-stroke patients who have difficulty walking but retain some voluntary leg control and sensation. Right leg only (V1 hardware constraint).

**Clinical goal:** Standing and walking rehabilitation using active and assistive modes.

**One physiotherapist per patient.** One physiotherapist can have many patients.

**Physiotherapist controls all clinical and safety decisions.** Patients cannot edit clinical scores, ROM limits, angular velocity, assistance levels, or exercise prescriptions.

---

## 2. Session Types

There are two distinct session categories. They must never be mixed or confused.

### Mobile-Only Rehab Session

The patient follows exercise instructions in the app. No device required.

- Uses: exercise guidance, timers, sets/reps tracking, pain logging
- Does **not** use: exoskeleton device, ESP32-S3, motor, IMUs, BLE telemetry, device safety limits
- A family member or caregiver may assist
- Can be done at home as long as `home_exercise_permission = true` in PatientProfile

### Device-Assisted Orthosis Session

The patient wears the exoskeleton. The motor provides active assistance.

- Uses: right-leg orthosis, ESP32-S3, motor, IMUs, BLE connection to app, firmware safety logic
- Doctor-prescribed device limits are enforced by firmware

The `device_assisted` boolean on `TherapySetConfig` determines which type applies to each set within a session. A single therapy session can contain both types of sets.

---

## 3. User Roles & Permissions

### Patient — Can

- Create account, complete profile
- Generate enrollment code to share it with doctor
- Connect and calibrate device
- Start assigned exercises
- View progress, session history
- Chat with doctor in real time (low priority)
- View calendar and appointments (low priority)
- Export own reports (low priority)

### Patient — Cannot

- Change ROM limits, angular velocity, or assistance level
- Edit clinical scores (FIM, MMT, MMSE)
- Change exercise prescription
- Delete session history

### Doctor (Physiotherapist) — Can

- Sign up (pending admin approval before portal access)
- Link patient using patient enrollment code
- Create a patient profile
- Create rehab plans and prescribe exercises from library
- Review rehab sessions data
- Chat with patients in real time (low priority)
- View reports, export PDF/CSV (V2) (low priority)
- View and manage calendar (low priority)

### Doctor — Cannot

- Access portal before admin approval
- Change configuration of an active live session
- Control the device directly from the web portal
- Delete audit logs

### Admin — Can

- Approve, reject, or suspend doctor accounts
- Manage all doctors and patients
- Manage the official exercise library
- Manage devices
- View audit logs and system logs

### Admin — Cannot

- Edit patient medical plans unless also a qualified doctor
- Delete Patients or their sessions logs

---

## 4. Authentication & Identity

### Doctor Account Statuses

| Status | Meaning |
|--------|---------|
| `PENDING` | Submitted, awaiting admin approval |
| `APPROVED` | Can access the portal |
| `REJECTED` | Cannot access; rejection reason stored |
| `SUSPENDED` | Previously approved; access revoked |

### Signup Fields

**Patient:**

- Step 1: Username, email, password, confirm password
- Step 2: Full name, birth date, gender, phone, emergency contact name, emergency contact phone
- Step 3: Consent checkbox
- Step 4: Enrollment code display screen with copy button

**Doctor:**

- Full name, email, username, password, phone, clinic/hospital name, specialization, professional ID/license (optional), years of experience (optional)
- Submits for admin approval; cannot log in until approved

---

## 5. Patient Profile — Additional Fields

### Only Doctors edit PatientProfile

Patients cannot edit PatientProfile.

---

## 6. Pain Management Rules

Pain is recorded on a 0–10 standard clinical scale. Presented in the UI as a labelled list, not a raw number.

### When Pain Is Recorded

| Context | Timing |
|---------|--------|
| Before session | Required; blocks session if ≥7 |
| During session | Patient-initiated via Pain button |
| After set | Per TherapySetRecord (see data model) |
| After session | Required in session summary |

### Pain Response Rules

| Level | Action |
|-------|--------|
| 0–3 | Continue |
| 4–6 | Warn patient; offer pause option |
| 7–8 | Stop session immediately; notify doctor |
| 9–10 | Stop session; show emergency guidance; offer call to emergency contact and local emergency services |

**Pre-session specific:**

| Level | Action |
|-------|--------|
| 0–6 | Allow session start (warn at 4–6) |
| 7–8 | Block session; notify doctor |
| 9–10 | Block session; show emergency help |

Do not automatically call an ambulance. Offer the option.

---

## 8. Hardware Details

### Controller

**ESP32-S3-N16R8** — 16 MB Flash, 8 MB PSRAM

### Motor

## MG5010E-i36

| Parameter | Value |
|-----------|-------|
| Rated torque | 4 Nm |
| Rated current | 4.4 A |
| Max current | 8 A |
| Voltage | 24 V |
| Encoder | 18-bit magnetic dual absolute encoder |
| Direction | Flexion and extension |

Motor communication:

- **Primary:** CAN / TWAI (main control and status feedback)
- **Secondary:** UART (debugging, configuration, backup)

ESP32-S3 requires an **external CAN transceiver**. Recommended: SN65HVD230 or TJA1050 (3.3 V compatible).

### IMUs

**3× MPU6050** — 6-axis accelerometer + gyroscope (no magnetometer)

Placement: foot, shank, thigh (right leg)
Sample rate: 100 Hz
Connection: wired

**I2C address conflict:** MPU6050 supports only two I2C addresses (AD0 pin). Three sensors require either:

- An I2C multiplexer (TCA9548A recommended)
- Separate I2C buses
- Mixed addressing + multiplexer

### Safety Hardware (Recommended)

- Latching emergency stop button (hardware power cut, not software only)
- Buzzer
- Red LED — fault/emergency
- Green LED — ready/safe
- Yellow LED — warning/calibration/offline
- Fuse or breaker
- Battery BMS
- Hardware motor enable cutoff
- Mechanical hard stops
- Quick-release straps
- Cable strain relief

---

## 9. ROM & Velocity Limits

| Parameter | Value |
|-----------|-------|
| Software absolute max ROM | 120° flexion |
| Extension hard stop | 0° (no hyperextension) |
| Default max angular velocity | 45°/s |
| Doctor-adjustable velocity range | 20–90°/s |
| Firmware hard cap (velocity) | 90°/s |

Protection layers (in order):

1. Doctor-prescribed soft limit (stored in TherapyConfig)
2. Firmware software hard limit
3. Motor current and speed limit
4. Mechanical hard stop (hardware)

Adjustable flexion mechanical hard stop options: 30°, 45°, 60°, 90°, 120°.

---

## 10. Motor Current Safety Rules

| Condition | Action |
|-----------|--------|
| 0–4.4 A | Normal operation |
| >4.4 A sustained (several seconds) | Log warning |
| ~6 A | Reduce assistance or pause |
| ~8 A (near max) | Immediate motor stop |
| Sudden spike | Emergency stop logic |

---

## 11. Firmware State Machine

```text
BOOT
  ↓
SELF_CHECK
  ↓
IDLE
  ↓
PAIRING
  ↓
WAIT_FOR_PLAN
  ↓
CALIBRATION
  ↓
READY
  ↓
ACTIVE_SESSION
  ↓
PAUSED
  ↓
SESSION_COMPLETE
```

**Motor may only move in:** `ACTIVE_SESSION`

**Motor must not move in:** `PAIRING`, `CALIBRATION`, `PAUSED`, any `FAULT_*` state, `EMERGENCY_STOP`

### Fault States

```text
FAULT_IMU
FAULT_MOTOR_CURRENT
FAULT_MOTOR_COMMUNICATION
FAULT_ROM_LIMIT
FAULT_VELOCITY_LIMIT
FAULT_EMERGENCY_STOP
FAULT_BATTERY
FAULT_CALIBRATION
```

---

## 13. Battery Rules

| Battery Level | Behaviour |
|--------------|-----------|
| Above 30% | Allow session |
| 20–30% | Warn patient |
| Below 20% | Block motor-assisted session |
| Below 10% | Device must not start active session |

Message shown below 20%:

```text
Battery is too low for a safe assisted session.
Please charge your brace before starting.
```

---

## 14. Offline Behaviour

| Condition | Behaviour |
|-----------|-----------|
| BLE disconnects during an active device-assisted set | No interruption — device runs the set to completion autonomously; BLE is not required after the set-start signal is sent |
| WiFi disconnects during an active device-assisted set | No interruption — device continues capturing and buffers data locally; uploads when WiFi restores |
| Internet offline, plan already downloaded | Session may continue; session data saved locally and synced later |
| Internet offline, no BLE | Mobile-only sessions can continue if plan is downloaded |
| Re-opening app while offline (previously authenticated) | Allowed |

---

## 15. Calibration Flow

Calibration is required before every device-assisted session.

Performs 4 steps of calibration as per the code in `knevo_dataset`

There should be two buttons for each step of the 4 steps:

- Repeat same calibration
- Next calibration
These are purely based on user judgement

Live calibration status shown:

- Foot IMU: OK / Error
- Shank IMU: OK / Error
- Thigh IMU: OK / Error
- WiFi Status

---

## 16. Emergency Stop Behaviour

Emergency stop must cut motor power through **hardware**, not only software.

1. Emergency stop is pressed (physical button or software button)
2. Motor enable/power cut immediately through hardware
3. Firmware detects emergency input
4. Buzzer activates
5. App shows emergency message
6. The set stops and is marked `INTERRUPTED`
7. Motor must not restart automatically — manual reset required

Software emergency button is additional to, not a replacement for, the physical button.

---

## 18. Exercise Library — Extended Fields

The `Exercise` entity in `spec-and-architecture.md` has minimal fields. The full library entity requires:

| Field | Notes |
|-------|-------|
| `id` | UUID |
| `name` | |
| `category` | See categories below |
| `activity_type` | `STANDING`, `WALKING`, `SEATED` |
| `mode` | `MOBILE_ONLY`, `DEVICE_ASSISTED` |
| `difficulty` | `BEGINNER`, `INTERMEDIATE`, `ADVANCED` |
| `description` | Full description |
| `patient_instructions` | Simplified language for patient app |
| `doctor_instructions` | Clinical notes for prescribing doctor |
| `default_sets` | |
| `default_reps` | |
| `default_rest_seconds` | |
| `default_min_rom_deg` | |
| `default_max_rom_deg` | |
| `default_max_angular_velocity_deg_s` | |
| `default_pain_stop_threshold` | |
| `safety_notes` | Free text |
| `video_url` | Optional |
| `image_url` | Optional |
| `target_joint` | `KNEE`, `ANKLE`, `BOTH` |
| `is_active` | Boolean; never hard-delete |
| `created_by_id` | FK → User (Admin) |
| `created_at` | |
| `updated_at` | |

The video and image will be AI generated and stored in the system to be referenced and viewed later

### Exercise Categories

- Standing exercises
- Walking / gait exercises
- Knee control exercises
- Balance exercises
- Strength exercises
- Range of motion exercises
- Functional exercises
- Warm-up exercises
- Cool-down exercises
- Assessment exercises

### Exercise Library Governance

- Admin controls and manages the official exercise library
- Doctors choose exercises from the library and customize prescription values per patient
- Doctors cannot freely create custom exercises in V1
- Future: doctors may suggest custom exercises for admin review and approval

---

## 19. Additional Data Entities

These are required for the full system but not captured in `spec-and-architecture.md`.

### RehabPlan

A named programme grouping multiple therapy configs prescribed by a doctor for a patient.

| Field | Notes |
|-------|-------|
| `id` | UUID |
| `patient_id` | FK → User |
| `doctor_id` | FK → User |
| `title` | Plan title |
| `goal` | Free text clinical goal |
| `start_date` | |
| `end_date` | |
| `status` | `DRAFT`, `ACTIVE`, `PAUSED`, `COMPLETED`, `CANCELLED` |
| `notes` | |
| `created_at` | |
| `updated_at` | |

### PainLog

Captures pain reports outside of TherapySetRecord (before session, after session, daily life).

| Field | Notes |
|-------|-------|
| `id` | UUID |
| `patient_id` | FK → User |
| `session_id` | FK → Session; nullable (daily life logs have no session) |
| `pain_level` | 0–10 |
| `context` | `BEFORE_SESSION`, `DURING_SESSION`, `AFTER_SESSION`, `DAILY_LIFE` |
| `notes` | Free text |
| `created_at` | |

### Alert

| Field | Notes |
|-------|-------|
| `id` | UUID |
| `patient_id` | FK → User |
| `session_id` | Nullable FK → Session |
| `device_id` | Nullable FK → Device |
| `type` | See alert types below |
| `severity` | `INFO`, `WARNING`, `URGENT`, `CRITICAL` |
| `message` | |
| `status` | `OPEN`, `REVIEWED`, `RESOLVED` |
| `created_at` | |
| `reviewed_at` | |
| `resolved_at` | |
| `resolved_by` | FK → User |

Alert types: HIGH_PAIN, SEVERE_PAIN, MISSED_SESSION, ROM_LIMIT_EXCEEDED, VELOCITY_EXCEEDED, MOTOR_OVERCURRENT, IMU_ERROR, CALIBRATION_FAILED, BLE_DISCONNECTED, LOW_BATTERY, EMERGENCY_STOP, NO_RECENT_SYNC

### Message

Real-time WebSocket chat between patient and doctor.

| Field | Notes |
|-------|-------|
| `id` | UUID |
| `sender_id` | FK → User |
| `receiver_id` | FK → User |
| `message_type` | `TEXT`, `PAIN_REPORT`, `DEVICE_ISSUE`, `EXERCISE_ASSIGNMENT`, `APPOINTMENT`, `SYSTEM_ALERT` |
| `body` | Message text |
| `attachment_url` | Nullable; V2 |
| `created_at` | |
| `read_at` | Nullable |

### CalendarEvent

| Field | Notes |
|-------|-------|
| `id` | UUID |
| `patient_id` | FK → User |
| `doctor_id` | FK → User |
| `title` | |
| `event_type` | `APPOINTMENT`, `EXERCISE`, `FOLLOW_UP`, `REPORT_REVIEW` |
| `start_time` | |
| `end_time` | |
| `location` | Text; clinic address or "Online" |
| `online_link` | Google Meet / Zoom / Teams URL |
| `notes` | |
| `reminder_time` | When to send notification |
| `created_by` | FK → User |
| `created_at` | |

### Notification

| Field | Notes |
|-------|-------|
| `id` | UUID |
| `user_id` | FK → User |
| `type` | See types below |
| `title` | |
| `body` | |
| `channel` | `IN_APP`, `EMAIL` |
| `status` | `PENDING`, `SENT`, `FAILED` |
| `created_at` | |
| `sent_at` | |
| `read_at` | |

### AuditLog

All safety-related changes must be logged. Audit logs must never be deleted.

| Field | Notes |
|-------|-------|
| `id` | UUID |
| `user_id` | FK → User (who made the change) |
| `role` | Role at time of action |
| `action` | Description of action |
| `entity_type` | e.g. `THERAPY_CONFIG`, `DEVICE`, `SESSION` |
| `entity_id` | |
| `patient_id` | Nullable FK → User |
| `old_value` | JSON |
| `new_value` | JSON |
| `reason` | Free text; required for safety limit changes |
| `ip_address` | |
| `created_at` | |

Actions that must be logged: ROM change, velocity change, assistance level change, pain threshold change, exercise prescription change, doctor-patient link, report export, device assignment/unassignment, admin approval/rejection.

### SessionMetrics (out of scope for now)

Aggregated summary data per session (complements raw SensorReading rows).

| Field | Notes |
|-------|-------|
| `id` | UUID |
| `session_id` | FK → Session |
| `max_rom_deg` | |
| `avg_rom_deg` | |
| `max_angular_velocity_deg_s` | |
| `avg_angular_velocity_deg_s` | |
| `max_motor_current_a` | |
| `avg_motor_current_a` | |
| `current_fault_count` | |
| `time_above_rated_current_s` | |
| `total_duration_seconds` | |
| `gait_phase_summary` | JSON summary from on-device gait analysis |
| `alerts_count` | |
| `steps_count` | Derived if available |

---

## 20. Session Status Values (out of scope)

The spec has `IN_PROGRESS`, `COMPLETED`, `INTERRUPTED`. For implementation, the following stop-reason statuses are needed:

| Status | Meaning |
|--------|---------|
| `IN_PROGRESS` | Active |
| `COMPLETED` | All sets finished normally |
| `STOPPED_BY_PATIENT` | Patient chose to stop early |
| `STOPPED_DUE_TO_PAIN` | Pain threshold exceeded |
| `STOPPED_DUE_TO_DEVICE_FAULT` | Device/motor fault |

---

## 21. Notifications

### Channels (V1)

- In-app (real-time)
- Email

### Types

| Type | Audience |
|------|----------|
| Exercise reminder | Patient |
| Appointment reminder | Patient |
| New message | Patient + Doctor |
| Plan updated | Patient |
| Session completed | Doctor |
| Missed session | Doctor |
| High pain alert | Doctor |
| Emergency stop alert | Doctor |
| Device fault | Doctor |
| Low battery | Patient |
| Admin approval result | Doctor |

---

## 22. Real-Time Chat (low priority)

WebSocket required for patient-doctor messaging (V1).

WebSocket endpoints:

```text
/ws/chat
/ws/live-session/{sessionId}
```

**Doctor quick replies:**

- Please stop exercising for today.
- Please repeat calibration and try again.
- Your session looks good.
- Please reduce your movement speed.
- Please schedule a follow-up appointment.

**Patient quick messages:**

- I feel pain.
- I need help with calibration.
- I had a device problem.
- I missed my session.
- I completed my exercise.

---

## 23. AI & Gait Analysis

### On-Device (ESP32-S3)

**Task:** 6-phase gait classification running as a TinyML model on the ESP32-S3.

The gait model must run locally on the device — it must not depend on a cloud connection. It must be small enough for ESP32-S3 memory constraints and tested for latency and reliability.

**Six gait phases:**

1. Initial contact / heel strike
2. Loading response
3. Mid stance
4. Terminal stance
5. Pre-swing / toe-off
6. Swing

**On-device outputs:**

- Current gait phase (real-time)
- Confidence score (if available)

**Models under consideration:** Random Forest, SVM, XGBoost, LSTM, CNN-LSTM, BiLSTM

**Training datasets:** Camargo dataset + team's own treadmill dataset

### Backend Analytics Service

Separate from on-device gait analysis. Runs post-session. Schema is pending (OD-3 in spec). See `spec-and-architecture.md`.
May consider the following for the backend analytics service

- Phase timeline summary
- Stance/swing ratio summary
- Abnormal timing flag (for doctor review only)

### AI Restrictions (All AI Components)

- AI must never directly control the motor
- AI must never automatically change ROM, speed, or assistance
- AI must never diagnose independently or replace the physiotherapist
- AI-generated insights must be labelled as support tools in the UI

**Required UI disclaimer:**

```text
AI analysis is a support tool only.
Final clinical decisions must be made by the physiotherapist.
```

### Patient AI Chat (V1)

An in-app AI assistant available to the patient. It may access (with proper auth):

- Patient profile and medical history
- Assigned exercise plan
- Session summaries and pain logs
- Device and session status summaries

AI chat must not:

- Diagnose or prescribe independently
- Change device settings, ROM, speed, or assistance
- Tell the patient to ignore high pain or emergency symptoms

AI must escalate (recommend contacting the doctor) when:

- Pain level is high
- Symptoms are clinically concerning
- Device fault occurs
- Patient asks for clinical decisions

---

## 24. Reports

| Version | Scope |
|---------|-------|
| V1 | Report screens, charts, and summary views only |
| V2 | PDF export, CSV export, print |

Report types to build:

- Session report
- Weekly progress report
- Monthly progress report
- Clinical assessment report
- Device fault report
- AI gait analysis report
- Full patient journey report

---

## 25. Tech Stack (Confirmed)

| Component | Technology |
|-----------|-----------|
| Patient mobile app | Native Swift / SwiftUI (iOS only) — see ADR-001 |
| Doctor web portal | React, TypeScript, Tailwind CSS, React Router, TanStack Query, Recharts or Chart.js, Axios |
| Backend API | Spring Boot (Gradle Kotlin), Spring Security, JWT, WebSocket |
| Database | PostgreSQL |
| Migrations | Flyway or Liquibase |
| Auth | JWT access tokens + refresh tokens |
| Real-time | WebSocket (Spring WebSocket) |

---

## 26. API Endpoint Inventory

### Auth

```text
POST /api/auth/signup
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
POST /api/auth/forgot-password
POST /api/auth/reset-password
```

### Admin

```text
GET  /api/admin/doctors/pending
POST /api/admin/doctors/{id}/approve
POST /api/admin/doctors/{id}/reject
POST /api/admin/doctors/{id}/suspend
GET  /api/admin/audit-logs
GET  /api/admin/users
GET  /api/admin/devices
```

### Patient

```text
GET  /api/patient/profile
PUT  /api/patient/profile
GET  /api/patient/home
GET  /api/patient/exercises
GET  /api/patient/progress
GET  /api/patient/calendar
POST /api/patient/pain-logs
GET  /api/patient/link-requests
POST /api/patient/link-requests/{id}/accept
POST /api/patient/link-requests/{id}/reject
```

### Doctor

```text
GET  /api/doctor/dashboard
GET  /api/doctor/patients
GET  /api/doctor/patients/{id}
GET  /api/doctor/calendar
POST /api/doctor/calendar-events
POST /api/doctor/link-patient
GET  /api/doctor/alerts
POST /api/alerts/{id}/review
POST /api/alerts/{id}/resolve
```

### Exercise Library

```text
GET  /api/exercises
GET  /api/exercises/{id}
POST /api/admin/exercises
PUT  /api/admin/exercises/{id}
POST /api/admin/exercises/{id}/deactivate
```

### Rehab Plans

```text
POST /api/doctor/patients/{patientId}/plans
GET  /api/doctor/patients/{patientId}/plans
PUT  /api/doctor/plans/{planId}
POST /api/doctor/plans/{planId}/activate
POST /api/doctor/plans/{planId}/pause
POST /api/doctor/plans/{planId}/complete
```

### Sessions

```text
POST /api/sessions/start
POST /api/sessions/{id}/metrics
POST /api/sessions/{id}/finish
POST /api/sessions/{id}/stop
GET  /api/doctor/patients/{patientId}/sessions
GET  /api/sessions/{id}
```

### Devices

```text
GET  /api/devices
GET  /api/devices/{id}
POST /api/devices/{id}/assign
POST /api/devices/{id}/unassign
POST /api/devices/{id}/status
```

### Messages

```text
GET  /api/messages
POST /api/messages
PUT  /api/messages/{id}/read
```

WebSocket:

```text
/ws/chat
/ws/live-session/{sessionId}
```

### AI

```text
POST /api/ai/sessions/{sessionId}/predict-gait
GET  /api/ai/sessions/{sessionId}/results
```

---

## 27. Security Requirements

- JWT authentication with refresh tokens
- BCrypt or Argon2 password hashing
- Role-based access control (PATIENT, DOCTOR, ADMIN)
- HTTPS only
- Input validation on all endpoints
- Audit logging for all safety-relevant actions
- Secure BLE pairing
- No default passwords
- Device authentication and ability to revoke a device
- Rate limiting on auth endpoints
- Backend validation of all commands (firmware also validates safety commands independently)
- Firmware enforces hard safety limits regardless of backend commands
- OWASP top ten resistant

---

## 28. One-Brace Rule

Each patient account may be paired with only one active device at a time.

Device replacement flow:

1. Doctor or admin unassigns old device
2. New device is assigned to patient
3. Patient pairs the new brace
4. Old device token is revoked
5. Audit log is created

Patients cannot replace their own device without doctor/admin action.

---

## 29. No Fake Device Mode

The production app must not include a simulated or fake device mode.

**Allowed (for development and graduation demo):**

- Fake patient accounts (test accounts)
- Seeded session logs
- Seeded pain logs, alerts, and chat messages
- Developer test fixtures

**Not allowed as a product feature:**

- A user-facing fake brace connection
- A production toggle that pretends hardware is connected
- A doctor-facing fake live monitoring mode labelled as real

For demo purposes: if real hardware is not connected, label the environment clearly as using **test data** or **seeded logs**.

---

## 30. Build Order

### Phase 1 — Core Software (No Hardware)

Build real flows end-to-end with seeded data for development:

**Patient app:**
signup → login → profile → generate enrollment code → home → sessions and exercise list → mobile-only session/set/break timer → pain logging → session summary → messages → calendar → progress

**Doctor portal:**
signup → admin approval → login → dashboard → enroll patient → patient profile → exercise library → create plan → set safety limits → view sessions → messages → calendar → reports

**Backend:**
auth → roles → patients → doctors → admin approval → patient-doctor link → exercise library → plans → sessions → pain logs → messages → calendar events → reports → alerts

### Phase 2 — Hardware Integration

BLE connection, ESP32 telemetry, real knee angle, angular velocity, battery, emergency stop, session data pipeline

### Phase 3 — AI

CSV dataset pipeline, 6-phase gait classification, AI analysis page, doctor AI reports

---

## 31. Safety-Critical UI Messages

### Emergency Stop

```text
Emergency stop activated.
Motor assistance has been stopped.
Please sit down safely.
Contact your physiotherapist if you feel pain or discomfort.
```

### High Pain (7–8)

```text
High pain level reported.
Your session has been stopped for safety.
Do not continue exercising now.
Your physiotherapist has been notified.
```

### Severe Pain (9–10)

```text
Severe pain reported.
Stop using the brace now.
If this is a medical emergency, call emergency services immediately.
You can also contact your emergency contact or physiotherapist.
```

### Sensor Error

```text
Sensor problem detected.
Brace assistance has been disabled.
Please check the brace placement and try calibration again.
```

### BLE Disconnected

```text
Connection lost.
Trying to reconnect...
```

### Calibration Failed

```text
Calibration failed.
Keep your leg still and make sure all brace parts are fixed correctly.
Try again.
```

### Low Battery

```text
Battery is too low for a safe assisted session.
Please charge your brace before starting.
```

### ROM Near Limit

```text
Slow down. You are close to your movement limit.
```

### Speed Too High

```text
Move slower. Your knee movement is faster than the safe limit.
```

### High Motor Current

```text
Motor load is high.
Brace assistance has been paused for safety.
```
