# Knevo Project Full Context Handoff for Another LLM

## Purpose of This File

This Markdown file contains the full working context for **Knevo**, a senior engineering graduation project. It is written so another LLM, developer, or team member can continue the work without needing the previous conversation.

The project is a **smart active right-leg knee brace platform** for post-stroke rehabilitation and assistance. It includes hardware, firmware/control, patient mobile app, physiotherapist web portal, backend, database, AI gait analysis, safety rules, and dataset planning.

---


# 0. Latest Locked Decisions and Corrections

This section is a **superseding update**. If any older section in this file conflicts with this section, use this section as the source of truth.

## 0.1 Product Version Rule: No Fake Product Features

The user does **not** want fake/simulated product features in any real version.

Allowed:

- Test accounts using fake patient names.
- Test logs and seeded demo records that look like previous sessions.
- Developer-only test fixtures for UI/backend testing.

Not allowed as a product feature:

- A user-facing fake device mode.
- A production “simulated brace” toggle.
- A version that pretends the hardware is connected when it is not.

Important wording:

```text
Use fake patient accounts and fake historical logs only for testing and demo data.
Do not build a fake/simulated device mode as part of the real product experience.
```

## 0.2 Session Types: Mobile-Only Rehab vs Orthosis Device Sessions

There are **two different session categories** and they must not be mixed.

### A. Mobile-only rehab exercise sessions

These sessions use:

- Patient mobile app only.
- Exercise instructions.
- Timers.
- Sets/reps/rest tracking.
- Pain logging.
- Optional help from a family member/caregiver.

These sessions do **not** use:

- Brace device.
- ESP32-S3.
- Motor.
- IMUs.
- BLE live telemetry.
- Device safety limits.

The doctor assigns these exercises from the exercise library. The patient follows the app guidance at home, possibly with a family member.

### B. Orthosis/device sessions

These sessions use:

- Right-leg orthosis prototype.
- ESP32-S3.
- Motor.
- IMUs.
- BLE connection to the app.
- Firmware safety logic.
- Doctor-set device limits.

These sessions are for device-assisted standing/walking/orthosis use, depending on the prescribed activity.

## 0.3 Data Sync and Raw CSV Decision

### V1 locked decision

Use **Option A**:

```text
ESP32-S3 records raw CSV to microSD.
The patient app receives only the session summary through BLE.
The backend stores session summary + metadata only.
Raw IMU CSV is not uploaded through the app in V1.
Raw CSV can be accessed later manually or by a future transfer workflow.
```

V1 backend stores:

- Session ID.
- Patient ID.
- Device ID.
- Session number.
- Date/time.
- Duration.
- Steps if available.
- Completed exercise/session status.
- Pain before/during/after.
- Max/average ROM if available.
- Max/average angular velocity if available.
- Alerts/faults.
- Raw CSV file metadata if known:
  - file name on microSD
  - local device path if available
  - sample rate
  - duration
  - whether raw file exists
  - upload status = `NOT_UPLOADED_V1`

### V2 locked decision

Use **Option C**:

```text
ESP32-S3 connects to Wi-Fi and uploads raw CSV directly to backend/cloud storage.
```

V2 should include:

- Wi-Fi provisioning.
- Device authentication.
- Secure upload endpoint.
- Upload retry.
- CSV checksum/hash.
- Backend raw file storage.
- File metadata in PostgreSQL.

### Unresolved Wi-Fi detail

It is **not yet decided** whether the ESP32-S3 should save Wi-Fi credentials in V1.

Recommended rule:

```text
V1 should not depend on Wi-Fi for active sessions.
V1 live session works through BLE with the phone nearby.
V2 needs Wi-Fi provisioning if the ESP32 will upload CSV directly.
```

## 0.4 BLE, Internet, and Offline Rules

Locked decisions:

- V1 app pairs with **one brace only**.
- The device should work if the phone is nearby but there is **no internet**.
- The motor must stop safely if the app closes, crashes, or heartbeat is lost.
- Internet is needed for cloud sync, doctor portal updates, AI chat, and real-time chat.
- BLE/app connection is required for active motor/device sessions.

Recommended V1 behavior:

```text
Phone has no internet but BLE is connected:
- Device session can continue if the plan/settings were already downloaded.
- Session summary is saved locally and synced later.

App closes/crashes or BLE heartbeat lost:
- Firmware pauses/stops motor assistance safely.
- Session is marked interrupted.

Internet lost but BLE alive:
- Do not stop the motor only because internet is lost.
```

## 0.5 One-Brace Rule

V1 rule:

```text
Each patient account can be paired with only one active brace/device.
```

Device replacement should be controlled through doctor/admin/device management flow, not directly by the patient casually.

Possible replacement flow:

1. Doctor/admin unassigns old device.
2. New device is assigned to patient.
3. Patient pairs the new brace.
4. Old device token is revoked.
5. Audit log is created.

## 0.6 Right-Leg Prototype vs Patient Affected Side

Locked decision:

```text
V1 hardware is a right-leg orthosis prototype.
The app must still include affected side in patient information.
```

Do not write that every patient is necessarily clinically right-side affected unless the team decides that later.

Better wording:

```text
Brace side for V1: right leg only.
Patient clinical affected side: stored in profile as Right / Left / Both / Not specified.
```

## 0.7 Medical Information Editability

Locked decision:

```text
Patient-entered medical information should NOT become locked after doctor approval.
```

Patient can update their medical/profile information, but recommended safety behavior is:

- Store edit history.
- Notify linked doctor of important medical changes.
- Show last updated date/time.
- Do not let the patient edit official doctor-entered clinical scores.

Recommended split:

### Patient-editable medical/profile fields

- Rehab history.
- Walking difficulty.
- Walking aid.
- Height.
- Weight.
- Emergency contact.
- General notes.
- Uploaded reports/tests.

### Doctor-entered clinical fields

- FIM score.
- MMT score.
- MMSE score.
- Home exercise permission.
- Clinical safety notes.
- Device safety limits.
- Exercise prescription.

## 0.8 Assistance Level Definition

The assistance level is now defined.

```text
Assistance level controls motor torque/current contribution, not patient speed directly.
```

Recommended meaning:

| Assistance Level | Patient-facing Label | Meaning |
|---|---|---|
| 0% | No assistance | Motor does not assist movement |
| 1–30% | Low | Small motor support within safety limits |
| 31–70% | Medium | Moderate motor support within safety limits |
| 71–100% | High | Stronger support, still capped by firmware safety limits |

Important:

```text
100% assistance does NOT mean unlimited motor power.
100% means the maximum assistance allowed by the current patient prescription and firmware hard safety caps.
```

Firmware maps assistance percentage to safe motor limits such as:

- Max allowed motor current.
- Max torque contribution.
- Control gain.
- Smooth ramp-up/ramp-down behavior.

The firmware must always enforce:

- Absolute current cap.
- Absolute angular velocity cap.
- Absolute ROM cap.
- Emergency stop.
- Battery/fault limits.

## 0.9 Active Mode vs Assistive Mode Clarification

Because mobile-only rehab sessions do not use the device, use the following terminology:

### Mobile-only exercise session

The patient performs the exercise using app guidance only. A family member/caregiver may help. No motor, IMUs, or brace telemetry are used.

### Device-assisted orthosis session

The brace motor provides assistance according to doctor-prescribed limits.

### Active patient movement inside a device session

If used later, this means the patient moves voluntarily while the brace monitors/safeguards movement. The team must decide later whether the motor provides zero support or low support in this mode.

Do not confuse “active rehab exercise” with “active motor control.”

## 0.10 Doctor Safety Control During Live Session

Locked decisions:

- Doctor can lower safety limits during a live device session.
- Doctor can remotely stop a session in a safe way.
- Doctor cannot increase ROM, speed, or assistance during an active live session.
- Remote stop must be implemented as a safe stop/pause command, not an abrupt unsafe motor action.

Remote stop flow:

1. Doctor presses remote stop.
2. Backend sends command to app/device channel if connected.
3. App shows patient warning.
4. Firmware transitions to safe stop/pause state.
5. Motor assistance stops safely.
6. Session is marked stopped remotely.
7. Patient and doctor see the event.
8. Audit log is created.

## 0.11 Reports Decision

Locked decision:

```text
V1 has reports pages/views only.
V2 adds PDF/CSV export.
```

So update earlier references as follows:

- V1: report screens, charts, summaries.
- V2: export to PDF, export to CSV, print.

## 0.12 Real-Time Chat Decision

Locked decision:

```text
Real-time chat is required in V1.
```

Use WebSocket for patient-doctor messaging.

V1 chat should support:

- Text messages.
- Read status if possible.
- Patient pain quick report.
- Device issue quick report.
- Doctor quick replies.
- Basic attachments can be V2 if needed.

## 0.13 Patient AI Chat Decision

Locked decision:

```text
Patient AI chat is included in V1.
```

AI chat can access, with proper authorization and privacy controls:

- Patient profile.
- Medical history/profile fields.
- Uploaded reports.
- Medical test results.
- Session summaries.
- Pain logs.
- Assigned exercise plan.
- Device/session status summaries.

AI chat must not:

- Diagnose independently.
- Replace the doctor.
- Change device settings.
- Change ROM/speed/assistance.
- Prescribe new exercises by itself.
- Tell the patient to ignore high pain or emergency symptoms.

AI chat should escalate/recommend contacting the doctor when:

- Pain is high.
- Symptoms are concerning.
- Device fault occurs.
- Patient asks for clinical decisions.

## 0.14 AI Gait Analysis Location

Locked decision:

```text
AI Gait Analysis = ML model for gait phases running on the ESP32-S3 board.
```

Meaning:

- The gait phase model should run locally/on-device on ESP32-S3 if feasible.
- Backend may store results and display them.
- Doctor portal may show gait phase outputs.
- AI gait analysis must not directly control the motor.

Recommended implementation note:

Use an embedded/TinyML-compatible approach for the ESP32-S3. The model must be small enough for the board and tested for latency, memory, and reliability.

Outputs from on-device gait analysis may include:

- Current gait phase.
- Phase timeline summary.
- Confidence score if available.
- Stance/swing ratio summary.
- Abnormal timing flag for doctor review only.

## 0.15 Raw IMU Upload Decision for V1

Locked answer:

```text
V1 uploads only session summary to backend.
V1 does not upload raw IMU CSV through the app.
```

Raw data is still recorded to microSD by ESP32-S3 for later access.

## 0.16 Remaining Open Decisions

The following are still not fully locked and should be asked/decided before implementation:

1. Should ESP32-S3 save Wi-Fi credentials in V1, or only in V2?
2. Should Google sign-in be included in V1 or postponed?
3. Should doctor license/professional ID be required or optional in V1?
4. Should chat attachments be included in V1 or V2?
5. What exact embedded gait model type will run on ESP32-S3?
6. What exact firmware control law maps assistance level to motor current/torque?
7. What exact raw CSV filename format will firmware use on microSD?
8. How will microSD raw files be retrieved in V1: manual card removal, USB, BLE transfer later, or service tool?
9. Will V1 include push notifications, or only in-app real-time notifications?
10. Should date of birth replace age in the database? Recommended: store date of birth and calculate age.

---

# 1. Project Overview

## Project Name

**Knevo**

## Project Type

Senior engineering graduation project.

## Main Idea

Knevo is a smart active knee brace for **post-stroke patients** who have difficulty walking but still have some leg sensation and voluntary control.

The system supports **standing and walking rehabilitation** using active and assistive modes. It measures knee motion and walking/gait metrics using sensors, assists movement using a motor, and connects the patient to a physiotherapist through a mobile app and web portal.

## Final System Definition

Knevo is a safety-controlled smart active right-leg knee brace system where:

- The brace measures motion using 3 IMUs placed on:
  - Foot
  - Shank
  - Thigh
- The brace uses an MG5010E-i36 motor to provide active/assistive rehabilitation support.
- The mobile app guides the patient through home rehab sessions.
- The physiotherapist web portal assigns exercises, sets safe limits, monitors progress, and communicates with the patient.
- The backend stores users, profiles, sessions, exercises, alerts, messages, reports, and AI results.
- The firmware enforces hard safety limits locally.

---

# 2. Target User and Clinical Scope

## Target Patient

- Post-stroke patients only.
- Patients have difficulty walking.
- Patients still have some sense/control of the leg.
- Right leg only for V1.
- Used for walking and standing rehabilitation.
- Exercises are active and assistive.

## Clinical Control

- Physiotherapist controls rehab stage and exercises.
- Patient cannot edit clinical/safety limits.
- Patient has one physiotherapist.
- One physiotherapist can have many patients.

## Clinical Scores Used

The system should support:

- FIM score
- MMT score
- MMSE score
- Global pain scale 0–10

## Pain Rules

Use pain scale 0–10.

Recommended behavior:

| Pain Level | Behavior |
|---|---|
| 0–3 | Continue |
| 4–6 | Warn patient and offer pause |
| 7–8 | Stop session and notify physiotherapist |
| 9–10 | Stop session, show emergency guidance, offer call to emergency contact/emergency services |

The app should ask pain:

- Before session
- During session if patient presses Pain
- After session
- Anytime in daily life through a pain report shortcut

---

# 3. Hardware Context

## Controller

- ESP32-S3-N16R8

## Motor

Motor: **MG5010E-i36**

Known motor data:

- Rated torque: 4 Nm
- Rated current: 4.4 A
- Max current: 8 A
- Encoder: 18-bit magnetic dual absolute encoder
- Driver: embedded motor driver
- Voltage: 24 V
- Direction of assistance: flexion and extension

## Motor Communication

Motor supports:

- CAN
- UART

Recommended use:

- CAN/TWAI for main motor control and status feedback.
- UART for debugging, configuration, backup communication, and testing.

Important technical note:

- ESP32-S3 has TWAI/CAN-compatible controller, but needs an external CAN transceiver.
- Use a 3.3 V-compatible CAN transceiver.
- Possible transceivers:
  - SN65HVD230
  - TJA1050
  - MCP2551, only if compatible with selected voltage design

## Wireless

Recommended:

- BLE for brace-to-patient mobile app live connection.
- Wi-Fi for backend/cloud sync or firmware update if needed.

Reasoning:

- BLE is better for live app-to-brace connection because it does not require home Wi-Fi.
- Wi-Fi can be used for optional direct cloud sync.
- Home sessions should not depend on Wi-Fi.

## Sensors

IMUs:

- MPU6050
- 6-axis accelerometer + gyroscope
- 3 IMUs:
  - Foot
  - Shank
  - Thigh
- Sampling rate: 100 Hz
- Connection: wired
- Mounted to rigid frame

Future sensor:

- FSR sensors later, especially useful for gait phase labeling.

## IMU I2C Note

MPU6050 address conflict is likely because MPU6050 usually supports two I2C addresses depending on AD0. With 3 MPU6050 sensors, the system may need:

- I2C multiplexer such as TCA9548A
- Separate I2C buses
- Mixed addressing plus multiplexer

## Safety Hardware

Planned:

- Big emergency switch
- Buzzer

Recommended additions:

- Latching emergency stop button
- Buzzer
- Red LED for fault/emergency
- Green LED for ready/safe
- Yellow LED for warning/calibration/offline
- Fuse or breaker
- Battery BMS
- Hardware motor enable cutoff
- Mechanical hard stops
- Quick-release straps
- Cable strain relief
- Proper padding
- Joint-axis alignment guide

## Emergency Stop Requirement

Emergency stop should not only send a software command.

Recommended behavior:

1. Emergency stop is pressed.
2. Motor enable/power is cut immediately through hardware.
3. Firmware detects emergency input.
4. Buzzer activates.
5. App shows emergency message.
6. Session stops.
7. Doctor receives alert.
8. Motor must not restart automatically.
9. Manual reset is required.

---

# 4. Mechanical Safety and ROM

## ROM

User initially mentioned mechanical 180°, but final recommendation:

- Do **not** allow real 180° physical knee motion.
- Software absolute max ROM: 120°
- Physiotherapist chooses patient-specific ROM inside safe range.
- Mechanical hard stop should prevent unsafe movement even if software fails.

Recommended:

- Extension hard stop prevents hyperextension past 0°.
- Adjustable flexion stop options:
  - 30°
  - 45°
  - 60°
  - 90°
  - 120°

Safety protection layers:

1. Doctor-prescribed soft limit
2. Firmware hard limit
3. Motor/current/speed limit
4. Mechanical hard stop

## Angular Velocity

No single universal patient value is known. Recommended V1 defaults:

- Default max angular velocity: 45°/s
- Physiotherapist adjustable range: 20°/s to 90°/s
- Firmware absolute hard cap: 90°/s

Do not allow very high angular velocities in V1.

---

# 5. Firmware and Device Safety Logic

## Firmware State Machine

Recommended states:

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

Fault states:

```text
FAULT_IMU
FAULT_MOTOR_CURRENT
FAULT_MOTOR_COMMUNICATION
FAULT_BLUETOOTH_LOST
FAULT_WIFI_LOST
FAULT_ROM_LIMIT
FAULT_VELOCITY_LIMIT
FAULT_EMERGENCY_STOP
FAULT_BATTERY
FAULT_CALIBRATION
```

Motor can move only in:

```text
ACTIVE_SESSION
```

Motor must not move in:

```text
PAIRING
CALIBRATION
PAUSED
FAULT
EMERGENCY_STOP
```

## Current Safety Rules

Known motor currents:

- Rated current: 4.4 A
- Max current: 8 A

Recommended rules:

| Current Condition | Action |
|---|---|
| 0–4.4 A | Normal |
| >4.4 A for several seconds | Warning |
| Around 6 A | Reduce assistance or pause |
| Near 8 A | Immediate motor stop |
| Sudden current spike | Emergency stop logic |

Log:

- Average current
- Max current
- Current fault count
- Time above rated current

## BLE/App Heartbeat

Recommended:

- App sends heartbeat every 500 ms to 1 second.
- If brace receives no heartbeat for 2 seconds:
  - Pause assistance safely.
- If no heartbeat for 5 seconds:
  - Stop session.
  - Mark session interrupted.

## Offline Rules

Internet offline:

- Allowed if the exercise plan was already downloaded.
- App stores session locally.
- Syncs later.

BLE/app disconnected from brace:

- Not okay for active motor assistance.
- Motor assistance pauses/stops safely.

App crash:

- Firmware detects missing heartbeat.
- Motor assistance stops safely.
- Session is stored locally if possible.
- App syncs after reconnect.

---

# 6. Calibration

## Calibration Method

Before every active/assistive session:

1. Patient wears brace.
2. Patient stands upright or sits with right leg extended.
3. App instructs patient to keep leg still.
4. Patient presses Start Calibration.
5. System collects 3–5 seconds of IMU data.
6. Firmware calculates average thigh and shank orientation.
7. Knee angle offset is stored.
8. Patient performs a small test bend if needed.
9. System checks plausibility.
10. If valid, session can start.
11. If invalid, session is blocked.

## Calibration Message

Success:

```text
Calibration completed successfully.
You can now start your exercise.
```

Failure:

```text
Calibration failed.
Please check that the sensors are fixed correctly and keep your leg still.
Try again.
```

---

# 7. Overall Platform Architecture

```text
Brace Hardware
3 IMUs + motor + embedded driver + emergency stop
        ↓ BLE / Serial protocol
Patient Mobile App
exercise guidance + BLE control + offline session storage
        ↓ HTTPS / WebSocket
Spring Boot Backend
auth + patients + sessions + alerts + messages + AI results
        ↓ PostgreSQL
Knevo Physio Portal
monitoring + exercise prescription + safety limits + reports
```

## Technology Stack

Backend:

- Spring Boot
- Gradle Kotlin
- PostgreSQL
- Spring Security
- JWT auth
- WebSocket for live monitoring/chat
- REST APIs
- Flyway or Liquibase migrations recommended

Doctor portal:

- React
- TypeScript
- Tailwind CSS
- React Router
- TanStack Query / React Query
- Recharts or Chart.js
- Axios

Patient app:

- React Native
- TypeScript
- BLE library, likely react-native-ble-plx
- Offline storage
- Local session cache
- Push/in-app notifications

Patient web portal:

- Not recommended for V1.
- Patient mobile app should be the main patient interface.
- Patient web portal can be built later for reports/messages only.

---

# 8. User Roles

## Patient

Uses the mobile app.

Can:

- Create account
- Complete profile
- View Patient ID
- Accept/reject doctor link request
- Connect brace
- Calibrate brace
- Start assigned exercises
- Report pain anytime
- View progress
- Chat with doctor
- View calendar appointments
- Export own reports

Cannot:

- Change ROM limits
- Change max angular velocity
- Change assistance level
- Change exercise prescription
- Edit clinical scores
- Delete session history
- Change assigned doctor directly

## Doctor / Physiotherapist

Uses **Knevo Physio Portal**.

Can:

- Sign up
- Wait for admin approval
- Link patient using Patient ID
- Create rehab plans
- Choose exercises from library
- Set ROM
- Set angular velocity
- Set assistance level
- Monitor live sessions
- Chat with patients
- View reports
- Export PDF/CSV
- View calendar

Cannot:

- Use account before admin approval
- Access unlinked patients
- Directly move motor from website
- Increase limits during active live session
- Delete audit logs

## Admin

Uses admin dashboard.

Can:

- Approve/reject doctor accounts
- Suspend doctors
- Manage admins
- View all doctors
- View all patients
- Manage official exercise library
- Manage devices
- View audit logs
- View system logs

Admins should not edit patient medical plans unless they are also doctors.

---

# 9. Account and Authentication Rules

## Signup

Signup requires:

- Full name
- Username
- Email
- Password
- Confirm password
- Role: Patient or Physiotherapist

## Login

Login field should be:

```text
Email, Username, or ID
Password
```

Login accepted for:

Patient:

- Email
- Username
- Patient ID

Doctor:

- Email
- Username
- Doctor ID

Admin:

- Email
- Username

Backend logic:

```text
If input starts with KNEVO-P → search patient_id
Else if input starts with KNEVO-DR → search doctor_id
Else if input contains @ → search email
Else → search username
```

Example IDs:

```text
Patient ID: KNEVO-P-000124
Doctor ID: KNEVO-DR-000018
```

## Doctor Approval

Doctors can sign up themselves, but cannot access the portal until admin approval.

Doctor statuses:

- Pending
- Approved
- Rejected
- Suspended

## Admins

There can be multiple admins.

For V1, one `ADMIN` role is enough.

Future possible admin roles:

- Super Admin
- System Admin
- Content Admin
- Support Admin

---

# 10. Patient-Doctor Linking

Final recommended flow:

1. Patient creates account.
2. System generates Patient ID.
3. Patient gives Patient ID to doctor.
4. Doctor searches by Patient ID.
5. Doctor sends link request.
6. Patient receives request in app.
7. Patient accepts or rejects.
8. If accepted, doctor can access patient profile and assign exercises.

Rules:

- One patient has one doctor only.
- One doctor can have many patients.
- If another doctor tries to link an already linked patient, show:

```text
This patient is already linked to another physiotherapist.
```

Patient notification:

```text
Dr. Ahmed Hassan wants to link to your Knevo account.
Accept / Reject / View Doctor Info
```

---

# 11. Patient Mobile App

## General Design Style

- Modern clean
- Medical-tech look
- Very user friendly
- English only
- Light background
- Soft blue/teal accents
- Large buttons
- Simple language
- Avoid crowded screens
- Use clear status cards and big actions

## Main Bottom Navigation

Five tabs:

```text
Home
Exercises
Progress
Messages
Profile
```

Hidden/special screens:

```text
Login
Signup
Consent
Doctor Link Request
Brace Pairing
Device Status
Calibration
Live Session
Pain Report
Emergency Help
Session Summary
Calendar
Offline Sync
```

---

## Patient App: Splash Screen

Displays:

```text
Knevo
Smart Active Knee Brace
Rehabilitation & Assistance
```

Auto-routes:

- Logged in → Home
- Not logged in → Login
- First time → Onboarding

---

## Patient App: Onboarding

Screen 1:

```text
Welcome to Knevo.
Your smart knee brace helps you perform safe post-stroke rehabilitation exercises at home.
```

Screen 2:

```text
Your physiotherapist assigns your exercises and sets your safe movement limits.
```

Screen 3:

```text
Stop immediately if you feel severe pain, dizziness, or discomfort.
Use the emergency stop button if needed.
```

Buttons:

- Create Account
- Login

---

## Patient App: Login

Fields:

- Email, Username, or ID
- Password

Buttons:

- Login
- Create Account
- Forgot Password?

Options:

- Remember me

Errors:

- Incorrect email or password.
- Account not found.
- No internet connection.

Offline rule:

- New login requires internet.
- Offline opening allowed only if patient logged in before.

---

## Patient App: Signup

Use multi-step signup.

### Step 1: Account

Fields:

- Username
- Email
- Password
- Confirm password

### Step 2: Personal Information

Fields:

- Full name
- Age
- Gender
- Height
- Weight
- Phone number
- Emergency contact name
- Emergency contact phone

### Step 3: Medical Information

Fields:

- Condition: Post-stroke only
- Affected side: selectable patient clinical field; V1 brace prototype is right leg
- Walking difficulty:
  - Mild
  - Moderate
  - Severe
- Walking aid:
  - No
  - Cane
  - Walker
  - Other
- Rehabilitation history:
  - No previous rehab
  - Currently in rehab
  - Completed previous rehab
  - Other

### Step 4: Short Consent

Checkboxes:

- I understand that Knevo supports rehabilitation but does not replace medical care.
- I agree that my physiotherapist can view my exercise and progress data.
- I will stop exercising if I feel severe pain, dizziness, or discomfort.
- I agree that my session data can be stored for monitoring and research purposes.

### Step 5: Patient ID Screen

Shows:

```text
Your Patient ID is:

KNEVO-P-000124

Give this ID to your physiotherapist so they can link your account.
```

Buttons:

- Copy Patient ID
- Go to Home

---

## Patient App: Home Page

Header:

```text
Hello, [Name]
Today’s rehabilitation plan
```

Cards:

### Brace Status Card

Shows:

- Brace: Connected / Not Connected
- Battery: %
- Status: Ready / Needs calibration / Fault / Offline

Buttons:

- Connect Brace
- Device Status

### Today’s Exercise Card

Shows:

- Exercise name
- Sets x reps
- ROM range
- Mode
- Activity

Example:

```text
Assisted Knee Flexion-Extension
3 sets × 10 reps
ROM: 0°–60°
```

Button:

- Start Exercise

If no doctor linked:

```text
No physiotherapist linked yet.
Share your Patient ID with your physiotherapist.
```

Button:

- Copy Patient ID

### Pain Shortcut Card

```text
Feeling pain or discomfort?
```

Button:

- Report Pain

### Calendar Card

Shows next appointment:

```text
Next appointment:
Sunday, 16 June - 5:00 PM
```

Button:

- Open Calendar

### Last Session Card

Shows:

- Last session status
- ROM reached
- Pain after
- Reps completed

Button:

- View Summary

---

## Patient App: Exercises Tab

Shows only exercises assigned by doctor.

Exercise card fields:

- Exercise name
- Mode: Active / Assistive
- Activity: Standing / Walking
- Sets
- Reps
- ROM limit
- Pain stop level
- Status:
  - Not started
  - Completed
  - Missed

Buttons:

- View Details
- Start

Patient can only start assigned exercises.

---

## Patient App: Pre-Session Flow

Before session:

```text
Exercise details
↓
Safety checklist
↓
Brace connection
↓
Battery check
↓
Calibration
↓
Pain before session
↓
Start session
```

### Safety Checklist

Checkboxes:

- Brace is firmly attached.
- Straps are comfortable.
- Emergency stop button is reachable.
- Area around me is clear.
- I am standing/sitting safely.
- I do not feel severe pain.

Button:

- Continue

All must be checked.

### Battery Rule

Recommended:

| Battery | Behavior |
|---|---|
| Above 30% | Allow session |
| 20–30% | Warn patient |
| Below 20% | Block motor-assisted session |
| Below 10% | Device should not start active session |

Message below 20%:

```text
Battery is too low for a safe assisted session.
Please charge your brace before starting.
```

### Calibration

Instructions:

```text
Stand straight or sit with your right leg extended.
Keep your leg still.
Press Start Calibration.
```

Live status:

- Foot IMU: OK
- Shank IMU: OK
- Thigh IMU: OK
- Knee angle: 0°
- Calibration: Good

Buttons:

- Start Calibration
- Retry
- Continue

### Pain Before Session

Question:

```text
What is your pain level now?
```

Scale:

```text
0 1 2 3 4 5 6 7 8 9 10
```

Rules:

| Pain | Action |
|---|---|
| 0–3 | Allow start |
| 4–6 | Warning, allow start |
| 7–8 | Block session and notify doctor |
| 9–10 | Block session and show emergency help |

---

## Patient App: Live Session Page

Top status:

- Brace connected
- Battery %
- Session active

Live values:

- Current knee angle
- Target ROM
- Angular velocity
- Set count
- Rep count
- Timer

Example:

```text
Current knee angle: 42°
Target ROM: 0°–60°
Angular velocity: 31°/s
Set: 2/3
Rep: 6/10
```

Visuals:

- Large knee angle gauge
- ROM progress bar
- Rep counter
- Set counter
- Timer

Buttons:

- Pause
- Stop
- Pain
- Emergency

Emergency button:

- Large red software emergency button.
- Does not replace physical emergency switch.

### Live Warnings

Near ROM limit:

```text
Slow down. You are close to your movement limit.
```

Speed too high:

```text
Move slower. Your knee movement is faster than the safe limit.
```

BLE lost:

```text
Connection lost.
Brace assistance has been paused for safety.
Trying to reconnect...
```

High motor current:

```text
Motor load is high.
Brace assistance has been paused for safety.
```

---

## Patient App: Pain During Session

Question:

```text
What is your pain level now?
```

Rules:

| Pain | Action |
|---|---|
| 0–3 | Continue |
| 4–6 | Offer pause |
| 7–8 | Stop session + notify doctor |
| 9–10 | Stop session + emergency help |

Buttons:

- Continue
- Pause Session
- Stop Session
- Notify Doctor
- Emergency Help

---

## Patient App: Pause Page

Text:

```text
Session paused.
Motor assistance is stopped.
```

Buttons:

- Resume
- End Session
- Report Pain

Before resuming, ask:

```text
Are you comfortable continuing?
Yes / No
```

---

## Patient App: Stop Session

If patient taps stop, ask:

```text
Are you sure you want to stop the session?
```

Reason options:

- I feel pain
- I feel tired
- Device issue
- I finished early
- Other

Buttons:

- Stop Session
- Return to Session

---

## Patient App: Session Summary

Shows:

- Session status: Completed / Stopped / Interrupted
- Exercise name
- Duration
- Sets completed
- Reps completed
- Max ROM reached
- Average ROM
- Max angular velocity
- Average angular velocity
- Pain before
- Pain after
- Motor current max
- Alerts during session

Patient inputs:

- Pain after session: 0–10
- Fatigue:
  - Low
  - Medium
  - High
- Notes

Buttons:

- Save Session
- Send to Physiotherapist
- View Progress

If offline:

```text
Session saved offline.
It will sync automatically when internet is available.
```

---

## Patient App: Progress Tab

Show patient-friendly data.

Cards:

- Sessions completed this week
- Current ROM improvement
- Pain trend
- Exercise streak
- Total reps completed

Charts:

- ROM over time
- Pain before/after
- Completed sessions

Friendly messages:

```text
You completed 4 out of 5 sessions this week.
Your knee movement improved by 8°.
```

---

## Patient App: Messages Tab

Real-time chat.

Features:

- Chat with physiotherapist
- Send pain update
- Send device problem
- Receive exercise changes
- Receive appointment reminders

Quick buttons:

- I feel pain
- I need help with calibration
- I had a device problem
- I missed my session
- I completed my exercise

Message types:

- Text
- Pain report
- Device issue
- Exercise assignment
- Appointment
- System alert

---

## Patient App: Calendar Page

Calendar shows:

- Exercise schedule
- Doctor appointments
- Follow-up sessions
- Missed sessions
- Completed sessions

Event colors:

- Blue: Exercise
- Green: Completed session
- Red: Missed session
- Purple: Appointment
- Orange: Alert/follow-up

Patient can:

- View event
- Receive reminder
- Join external meeting link
- Message doctor

Patient cannot:

- Create clinical appointment without doctor approval
- Edit exercise schedule

---

## Patient App: Emergency Help Page

Accessible from everywhere.

Content:

```text
Stop using the brace immediately.
Sit down safely.
Press the physical emergency stop button if the brace is moving.
```

Buttons:

- Call Emergency Contact
- Message Physiotherapist
- Show Emergency Instructions

For severe pain:

```text
If this is a medical emergency, call local emergency services immediately.
```

Do not automatically call an ambulance. Offer the option.

---

## Patient App: Profile Tab

Patient can edit:

- Full name
- Phone number
- Height
- Weight
- Emergency contact
- Password
- Notification settings

Patient can view only:

- Patient ID
- Assigned physiotherapist
- Medical condition
- Affected side
- Current rehab plan
- Safety limits
- Device ID

Buttons:

- Edit Profile
- Change Password
- Copy Patient ID
- Logout

---

## Patient App: Offline Sync Page

Shows:

- Number of sessions waiting to sync
- Last sync time
- Internet status

Example:

```text
2 sessions waiting to sync
Last sync: Today 3:20 PM
```

Buttons:

- Sync Now
- View Saved Sessions

Offline rules:

- Internet offline = allowed if plan is downloaded.
- BLE connected = session can continue.
- BLE disconnected = motor assistance pauses/stops.
- Session data saved locally.
- Sync when internet returns.

---

# 12. Knevo Physio Portal

## Portal Name

**Knevo Physio Portal**

## Design Style

- Modern clean web dashboard
- Medical-tech look
- React + Tailwind
- Light mode preferred
- Sidebar navigation
- Cards and charts
- Easy patient search
- Clear alerts

## Sidebar Navigation

```text
Dashboard
Patients
Exercise Library
Rehab Plans
Live Monitoring
Calendar
Messages
Reports
AI Analysis
Devices
Alerts
Audit Logs
Settings
```

Admin-only sidebar:

```text
Doctor Approvals
Users
System Exercise Library
System Logs
```

---

## Doctor Signup and Approval

### Doctor Signup Page

Fields:

- Full name
- Email
- Username
- Password
- Phone number
- Clinic/hospital name
- Specialization
- Professional ID/license number, optional
- Years of experience, optional

Button:

- Submit for Approval

Message:

```text
Your account has been submitted for admin approval.
You will be able to login after approval.
```

### Admin Approval Page

Admin sees:

- Doctor name
- Email
- Username
- Clinic
- Specialization
- Date requested
- Status

Buttons:

- Approve
- Reject
- View Details
- Suspend, if already approved

---

## Doctor Dashboard

Top cards:

- Total Patients
- Active Today
- Missed Sessions
- High Pain Alerts
- Device Faults
- Unread Messages
- Pending Reports

Priority patients table:

- Patient ID
- Name
- Reason
- Latest pain
- Last session
- Status
- Action

Status examples:

- Stable
- Needs Review
- Urgent
- Device Issue
- No Recent Data

Buttons:

- Open Patient
- Message
- Review Alert

---

## Patients Page

Table columns:

- Patient ID
- Name
- Age
- Affected side
- Walking difficulty
- Assigned device
- Last session
- Compliance %
- Latest ROM
- Latest pain
- Status

Filters:

- All
- Stable
- High pain
- Missed sessions
- Device issue
- Low compliance
- No active plan
- Recently added

Actions:

- Link Patient
- Open Profile
- Send Message
- Create Plan

---

## Link Patient Page

Doctor enters:

- Patient ID

Button:

- Search

If found, show:

- Patient name
- Age
- Condition
- Affected side

Button:

- Send Link Request

Patient accepts from app.

After acceptance:

```text
Patient linked successfully.
```

---

## Patient Profile Page in Portal

Tabs:

```text
Overview
Clinical Assessment
Rehab Plan
Sessions
Progress
Alerts
Messages
Device
Reports
```

### Overview Tab

Shows:

- Patient name
- Patient ID
- Age
- Gender
- Height
- Weight
- Condition
- Affected side
- Walking difficulty
- Emergency contact
- Assigned device
- Current plan
- Latest session
- Latest pain
- Latest ROM

Buttons:

- Create Rehab Plan
- Edit Notes
- Send Message
- Export Summary

### Clinical Assessment Tab

Doctor enters FIM, MMT, MMSE.

FIM fields:

- FIM total score
- Mobility/walking score
- Transfer score
- Date assessed
- Notes

MMT fields, 0–5 scale:

- Hip flexion
- Hip extension
- Knee flexion
- Knee extension
- Ankle dorsiflexion
- Ankle plantarflexion
- Notes

MMSE fields:

- MMSE total score
- Can follow instructions?
- Needs supervision?
- Cognitive safety notes

Home safety decision:

- Home exercise allowed alone
- Home exercise allowed with supervision
- Home exercise not allowed

Button:

- Save Assessment

---

## Rehab Plan Page

Doctor creates plan.

Fields:

- Plan title
- Start date
- End date
- Goal
- Plan status:
  - Draft
  - Active
  - Paused
  - Completed
- Plan notes

Buttons:

- Add Exercise
- Save Draft
- Activate Plan
- Pause Plan
- Complete Plan

Example goal:

```text
Improve right knee control during standing and walking while safely increasing active ROM and gait stability.
```

---

## Exercise Library

User wants a giant exercise library in the database.

Recommended library strategy:

- Admin controls official exercise library.
- Doctors choose from official library.
- Doctors customize prescription values per patient.
- Doctors should not freely create custom exercises in V1.
- Later, doctors may suggest custom exercises for admin approval.

### Exercise Categories

- Standing exercises
- Walking/gait exercises
- Knee control exercises
- Balance exercises
- Strength exercises
- Range of motion exercises
- Functional exercises
- Warm-up exercises
- Cool-down exercises
- Assessment exercises

### Recommended V1 Library Exercises

#### Standing Exercises

- Supported standing
- Standing weight shift
- Forward-backward weight shift
- Side-to-side weight shift
- Mini knee bends
- Standing knee flexion
- Standing knee extension
- Marching in place
- Static knee control hold
- Heel raises with support
- Toe raises with support

#### Walking / Gait Exercises

- Assisted walking
- Treadmill walking
- Slow walking practice
- Step initiation
- Step-through walking
- Heel strike practice
- Toe-off practice
- Stance phase control
- Swing phase control
- Gait rhythm training

#### Knee Control Exercises

- Active knee flexion-extension
- Assisted knee flexion-extension
- Controlled knee extension
- Controlled knee flexion
- Terminal knee extension
- Knee stabilization hold
- Partial ROM knee movement
- Repeated knee bending

#### Strength Exercises

- Seated knee extension
- Seated knee flexion
- Mini squat with support
- Sit-to-stand assisted
- Step-up practice
- Controlled standing hold

#### Balance Exercises

- Supported balance standing
- Weight bearing on affected leg
- Side weight shifting
- Forward weight shifting
- Balance with hand support
- Controlled stance hold

#### Functional Exercises

- Sit-to-stand
- Stand-to-sit
- Chair transfer practice
- Step initiation from standing
- Short walking task
- Turn preparation

#### Warm-Up / Cool-Down

- Gentle knee ROM
- Slow standing weight shift
- Low-speed assisted flexion-extension
- Relaxation pause

### Exercise Library Database Fields

Each exercise should have:

- id
- name
- category
- activity_type
- mode
- difficulty
- description
- patient_instructions
- doctor_instructions
- default_sets
- default_reps
- default_rest_seconds
- default_min_rom
- default_max_rom
- default_max_angular_velocity
- default_assistance_level
- default_pain_stop_threshold
- requires_motor
- requires_walking_support
- requires_supervision
- contraindications
- safety_notes
- video_url
- image_url
- is_active
- created_by_admin_id
- created_at
- updated_at

---

## Exercise Prescription Page

Doctor chooses from exercise library and customizes per patient.

Fields:

- Exercise
- Mode: Active / Assistive
- Activity: Standing / Walking
- Sets
- Reps per set
- Rest between sets
- Sessions per week
- Start date
- End date
- Schedule days

Safety fields:

- Min ROM
- Max ROM
- Max angular velocity
- Pain stop threshold
- Assistance level

Doctor sees assistance:

- 0–100%

Also show labels:

- 0–30% = Low
- 31–70% = Medium
- 71–100% = High

Patient sees:

- Low / Medium / High

Patient does not need exact percentage.

### Prescription Database Fields

When doctor assigns exercise, create separate prescription record:

- prescription_id
- patient_id
- doctor_id
- exercise_id
- plan_id
- sets
- reps
- rest_seconds
- min_rom
- max_rom
- max_angular_velocity
- assistance_level_percentage
- pain_stop_threshold
- sessions_per_week
- schedule_days
- start_date
- end_date
- doctor_notes
- status

---

## Safety Limits Page

Doctor can set patient-specific limits.

Fields:

- Max knee flexion
- Max knee extension
- Max angular velocity
- Pain stop threshold
- Battery minimum for session
- Motor current warning threshold
- Motor current stop threshold
- Allow offline sessions?
- Require calibration every session?
- Require pain check before session?

Recommended defaults:

- Max knee flexion: 60° initially
- Max extension: 0°
- Max angular velocity: 45°/s
- Pain stop threshold: 7/10
- Battery minimum: 20%
- Current warning: above rated current, >4.4 A
- Current stop: near max current, around 8 A
- Calibration: required every session
- Pain check: required every session

When increasing ROM/speed/assistance, require reason:

```text
You are increasing max ROM from 60° to 75°.
Please enter a reason.
```

Button:

- Confirm and Save

This creates audit log.

---

## Live Monitoring Page

Recommendation:

- Doctor sees detailed live data only during active sessions.
- Doctor sees general device status anytime app/brace syncs.

Why:

- Better privacy
- Less battery usage
- Less unnecessary data
- More professional

### Active Sessions List

Shows:

- Patient
- Exercise
- Session time
- Current ROM
- Pain
- Device status
- Alert status

Button:

- Open Live View

### Live View

Shows:

- Current knee angle
- Angular velocity
- Current set
- Current rep
- Pain level
- Motor current
- Battery
- Connection status
- Current gait phase

Charts:

- Knee angle vs time
- Angular velocity vs time
- Motor current vs time
- Gait phase timeline

Doctor actions allowed:

- Send message
- Request pause
- Stop session remotely
- Lower ROM limit
- Lower speed limit

Doctor actions not allowed:

- Increase ROM during active session
- Increase speed during active session
- Increase assistance during active session
- Move motor directly

---

## Calendar Page

Calendar should be included in V1.

Doctor calendar shows:

- Patient appointments
- Exercise schedules
- Follow-up reminders
- Missed sessions
- Report review reminders

Views:

- Month
- Week
- Day
- List

Doctor can create:

- Appointment
- Follow-up reminder
- Exercise schedule
- Online meeting link

Appointment fields:

- Patient
- Title
- Date
- Start time
- End time
- Location / online link
- Notes
- Reminder time

Patient sees appointments in app calendar.

Use external meeting links instead of building video calls:

- Google Meet
- Zoom
- Microsoft Teams
- Clinic visit
- Phone call

---

## Messages Page

Real-time chat via WebSocket.

Features:

- Text messages
- Read receipts
- Typing indicator, optional
- Pain quick report
- Device issue report
- Exercise update notification
- Appointment reminder

Message types:

- Text
- Pain report
- Device issue
- Exercise assignment
- Appointment
- System alert

Doctor quick replies:

- Please stop exercising for today.
- Please repeat calibration and try again.
- Your session looks good.
- Please reduce your movement speed.
- Please schedule a follow-up appointment.

Patient quick replies:

- I feel pain.
- I need help with calibration.
- I had a device problem.
- I missed my session.
- I completed my exercise.

---

## Reports Page

Report export is required in V1.

Report types:

- Session report
- Weekly progress report
- Monthly progress report
- Clinical assessment report
- Device fault report
- AI gait analysis report
- Full patient journey report

V1 report page options:

- View session summaries
- View charts
- View pain/ROM/progress trends

V2 export options:

- PDF
- CSV
- Print

Patient report should show:

- Simple progress
- Completed sessions
- Pain trend
- ROM improvement
- Doctor notes

Doctor report should show:

- Clinical scores
- ROM graphs
- Angular velocity graphs
- Motor current
- Pain logs
- Alerts
- AI gait phase analysis
- Session CSV link
- Doctor notes

---

## AI Analysis Page

AI task:

- 6-phase gait classification

Show:

- Detected gait phases
- Phase timing
- Stance/swing ratio
- Walking speed estimate
- Model confidence
- Abnormal timing flag

Six gait phases:

1. Initial contact / heel strike
2. Loading response
3. Mid stance
4. Terminal stance
5. Pre-swing / toe-off
6. Swing

Charts:

- Gait phase timeline
- Phase percentage chart
- Speed vs phase timing
- Model confidence chart

Important label:

```text
AI analysis is a support tool only. Final clinical decisions must be made by the physiotherapist.
```

AI should not directly control motor.

---

## Devices Page

Shows:

- Device ID
- Assigned patient
- Battery
- Firmware version
- Last connected
- BLE status
- Wi-Fi status
- CAN status
- UART status
- Motor status
- IMU status
- Emergency stop status
- Fault status

Device details:

- Foot IMU: OK
- Shank IMU: OK
- Thigh IMU: OK
- Motor current
- Battery
- Emergency switch
- Buzzer
- Last calibration

Buttons:

- View Logs
- Assign Device
- Unassign Device
- Mark Maintenance

---

## Alerts Page

Alert types:

- High pain
- Severe pain
- Missed session
- ROM limit exceeded
- Angular velocity exceeded
- Motor overcurrent
- IMU error
- Calibration failed
- BLE disconnected
- Wi-Fi sync failed
- Emergency stop pressed
- Low battery
- No recent sync

Severity:

- Info
- Warning
- Urgent
- Critical

Actions:

- Open Patient
- Message Patient
- Mark Reviewed
- Resolve Alert
- Add Note

---

## Audit Logs Page

Log:

- Doctor linked patient
- Doctor changed ROM
- Doctor changed speed
- Doctor changed assistance
- Doctor assigned exercise
- Doctor paused plan
- Doctor exported report
- Session stopped remotely
- Admin approved doctor
- Device assigned

Columns:

- Date/time
- User
- Role
- Patient
- Action
- Old value
- New value
- Reason

Audit logs should not be deleted.

---

## Settings Page

Doctor settings:

- Profile
- Password
- Clinic information
- Notification preferences
- Calendar preferences
- Report preferences

Notification options:

- High pain alert
- Emergency stop alert
- Missed session alert
- Device fault alert
- New message
- Weekly summary

---

# 13. Admin Dashboard

Minimum V1 pages:

```text
Dashboard
Doctor Approvals
Users
Exercise Library
Devices
Audit Logs
System Settings
```

## Admin Dashboard

Cards:

- Pending doctor approvals
- Active doctors
- Active patients
- Device faults
- System alerts

## Doctor Approvals

Fields:

- Doctor name
- Email
- Username
- Clinic
- Specialization
- Submitted date
- Status

Actions:

- Approve
- Reject
- Suspend
- View details

## Exercise Library Management

Admin can:

- Add official exercise
- Edit official exercise
- Disable exercise
- Add demo video/image URL
- Set default safety values
- Approve/reject custom exercise suggestion in future

## Users Page

Admin can view:

- Patients
- Doctors
- Admins

Admin actions:

- Suspend doctor
- Reset user status
- View linked relationships

## Audit Logs

Admin can view system audit logs but should not delete them.

---

# 14. Backend Database Suggested Tables

Core tables:

```text
users
patients
physiotherapists
admins
patient_physio_links
doctor_approval_requests
devices
clinical_assessments
exercise_library
rehab_plans
prescribed_exercises
sessions
session_metrics
imu_csv_files
pain_logs
alerts
messages
calendar_events
notifications
reports
audit_logs
ai_predictions
sync_queue
```

## users

Fields:

- id
- username
- email
- password_hash
- role
- status
- created_at
- updated_at
- last_login_at
- is_active

Roles:

- PATIENT
- PHYSIOTHERAPIST
- ADMIN

Statuses:

- ACTIVE
- PENDING_APPROVAL
- REJECTED
- SUSPENDED
- DEACTIVATED

## patients

Fields:

- id
- user_id
- patient_code
- full_name
- age
- gender
- height_cm
- weight_kg
- phone
- medical_condition
- affected_side
- walking_difficulty
- walking_aid
- rehab_history
- emergency_contact_name
- emergency_contact_phone
- created_at
- updated_at

## physiotherapists

Fields:

- id
- user_id
- doctor_code
- full_name
- phone
- clinic_name
- specialization
- license_number_optional
- years_experience_optional
- approval_status
- approved_by_admin_id
- approved_at

## patient_physio_links

Fields:

- id
- patient_id
- physiotherapist_id
- status
- requested_at
- accepted_at
- rejected_at
- active

Statuses:

- PENDING
- ACCEPTED
- REJECTED
- CANCELLED

Rule:

- Only one active accepted physiotherapist per patient.

## devices

Fields:

- id
- device_code
- model
- firmware_version
- assigned_patient_id
- status
- battery_level
- last_seen_at
- ble_status
- wifi_status
- can_status
- uart_status
- motor_status
- imu_status
- emergency_stop_status
- current_reading
- fault_status

## clinical_assessments

Fields:

- id
- patient_id
- doctor_id
- assessment_date
- fim_total
- fim_mobility
- fim_transfer
- mmt_hip_flexion
- mmt_hip_extension
- mmt_knee_flexion
- mmt_knee_extension
- mmt_ankle_dorsiflexion
- mmt_ankle_plantarflexion
- mmse_total
- can_follow_instructions
- needs_supervision
- home_exercise_permission
- notes

## exercise_library

Fields:

- id
- name
- category
- activity_type
- mode
- difficulty
- description
- patient_instructions
- doctor_instructions
- default_sets
- default_reps
- default_rest_seconds
- default_min_rom
- default_max_rom
- default_max_angular_velocity
- default_assistance_level
- default_pain_stop_threshold
- requires_motor
- requires_walking_support
- requires_supervision
- contraindications
- safety_notes
- video_url
- image_url
- is_active
- created_by_admin_id
- created_at
- updated_at

## rehab_plans

Fields:

- id
- patient_id
- doctor_id
- title
- goal
- start_date
- end_date
- status
- notes
- created_at
- updated_at

Statuses:

- DRAFT
- ACTIVE
- PAUSED
- COMPLETED
- CANCELLED

## prescribed_exercises

Fields:

- id
- plan_id
- patient_id
- doctor_id
- exercise_id
- sets
- reps
- rest_seconds
- min_rom
- max_rom
- max_angular_velocity
- assistance_level_percentage
- pain_stop_threshold
- sessions_per_week
- schedule_days
- start_date
- end_date
- doctor_notes
- status

## sessions

Fields:

- id
- patient_id
- device_id
- prescribed_exercise_id
- started_at
- ended_at
- status
- completed_sets
- completed_reps
- pain_before
- pain_after
- fatigue_level
- patient_notes
- sync_status
- created_at

Statuses:

- COMPLETED
- STOPPED_BY_PATIENT
- STOPPED_DUE_TO_PAIN
- STOPPED_DUE_TO_DEVICE_FAULT
- INTERRUPTED_CONNECTION
- CALIBRATION_FAILED

## session_metrics

Fields:

- id
- session_id
- max_rom
- avg_rom
- max_angular_velocity
- avg_angular_velocity
- max_motor_current
- avg_motor_current
- current_fault_count
- total_duration_seconds
- gait_phase_summary
- alerts_count

## imu_csv_files

Fields:

- id
- session_id
- file_path
- file_name
- uploaded_at
- sample_rate_hz
- duration_seconds
- data_source
- valid_file

## pain_logs

Fields:

- id
- patient_id
- session_id nullable
- pain_level
- context
- notes
- created_at

Contexts:

- BEFORE_SESSION
- DURING_SESSION
- AFTER_SESSION
- DAILY_LIFE

## alerts

Fields:

- id
- patient_id
- session_id nullable
- device_id nullable
- type
- severity
- message
- status
- created_at
- reviewed_at
- resolved_at
- resolved_by

## messages

Fields:

- id
- sender_id
- receiver_id
- patient_id
- message_type
- body
- attachment_url
- created_at
- read_at

## calendar_events

Fields:

- id
- patient_id
- doctor_id
- title
- event_type
- start_time
- end_time
- location
- online_link
- notes
- reminder_time
- created_by
- created_at

Event types:

- APPOINTMENT
- EXERCISE
- FOLLOW_UP
- REPORT_REVIEW

## notifications

Fields:

- id
- user_id
- type
- title
- body
- channel
- status
- created_at
- sent_at
- read_at

Channels:

- IN_APP
- EMAIL

## audit_logs

Fields:

- id
- user_id
- role
- action
- entity_type
- entity_id
- patient_id nullable
- old_value
- new_value
- reason
- ip_address
- created_at

## ai_predictions

Fields:

- id
- session_id
- model_name
- model_version
- prediction_type
- gait_phase_timeline_path
- summary_json
- confidence
- created_at

---

# 15. Backend API Suggested Endpoints

## Auth

```text
POST /api/auth/signup
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
POST /api/auth/forgot-password
POST /api/auth/reset-password
```

## Admin

```text
GET /api/admin/doctors/pending
POST /api/admin/doctors/{id}/approve
POST /api/admin/doctors/{id}/reject
POST /api/admin/doctors/{id}/suspend
GET /api/admin/audit-logs
```

## Patient

```text
GET /api/patient/profile
PUT /api/patient/profile
GET /api/patient/home
GET /api/patient/exercises
GET /api/patient/progress
GET /api/patient/calendar
POST /api/patient/pain-logs
```

## Doctor

```text
GET /api/doctor/dashboard
GET /api/doctor/patients
GET /api/doctor/patients/{id}
POST /api/doctor/link-requests
GET /api/doctor/calendar
POST /api/doctor/calendar-events
```

## Patient-Doctor Link

```text
POST /api/doctor/link-patient
GET /api/patient/link-requests
POST /api/patient/link-requests/{id}/accept
POST /api/patient/link-requests/{id}/reject
```

## Exercise Library

```text
GET /api/exercises
GET /api/exercises/{id}
POST /api/admin/exercises
PUT /api/admin/exercises/{id}
DELETE /api/admin/exercises/{id}
```

## Rehab Plans

```text
POST /api/doctor/patients/{patientId}/plans
GET /api/doctor/patients/{patientId}/plans
PUT /api/doctor/plans/{planId}
POST /api/doctor/plans/{planId}/activate
POST /api/doctor/plans/{planId}/pause
POST /api/doctor/plans/{planId}/complete
```

## Prescribed Exercises

```text
POST /api/doctor/plans/{planId}/exercises
PUT /api/doctor/prescribed-exercises/{id}
DELETE /api/doctor/prescribed-exercises/{id}
```

## Sessions

```text
POST /api/sessions/start
POST /api/sessions/{id}/metrics
POST /api/sessions/{id}/csv
POST /api/sessions/{id}/finish
POST /api/sessions/{id}/stop
GET /api/doctor/patients/{patientId}/sessions
GET /api/sessions/{id}
```

## Alerts

```text
GET /api/doctor/alerts
POST /api/alerts/{id}/review
POST /api/alerts/{id}/resolve
```

## Messages

```text
GET /api/messages
POST /api/messages
PUT /api/messages/{id}/read
```

WebSocket:

```text
/ws/chat
/ws/live-session/{sessionId}
```

## Reports

```text
GET /api/reports/session/{sessionId}/pdf
GET /api/reports/patient/{patientId}/weekly
GET /api/reports/patient/{patientId}/monthly
GET /api/reports/patient/{patientId}/csv
```

## Devices

```text
GET /api/devices
GET /api/devices/{id}
POST /api/devices/{id}/assign
POST /api/devices/{id}/unassign
POST /api/devices/{id}/status
```

## AI

```text
POST /api/ai/sessions/{sessionId}/predict-gait
GET /api/ai/sessions/{sessionId}/results
```

---

# 16. Notifications

## Notification Channels

V1:

- In-app
- Email

Future optional:

- SMS

## Notification Types

- Exercise reminder
- Appointment reminder
- New message
- Doctor link request
- Plan updated
- Session completed
- Missed session
- High pain alert
- Emergency stop alert
- Device issue
- Low battery
- Calibration failed
- Sync failed
- Report ready

## Reminder Examples

Patient:

```text
Reminder: You have a physiotherapy appointment today at 5:00 PM.
```

Email example:

```text
Subject: Knevo Appointment Reminder

Hello Mariam,
You have an appointment with your physiotherapist today at 5:00 PM.
Please open the Knevo app for details.
```

---

# 17. Testing, Demo Data, and Seed Logs

## Important Rule

The real product must not include a fake/simulated device mode.

Allowed for development and graduation demonstration:

- Fake patient accounts.
- Seeded session logs.
- Seeded pain logs.
- Seeded alerts.
- Seeded chat messages.
- Seeded reports page data.
- Developer test fixtures.

Not allowed as a production feature:

- A patient-facing fake brace connection.
- A doctor-facing fake live monitoring mode labeled as real.
- A production toggle that pretends hardware is connected.

## Recommended Test Data Strategy

Use fake test accounts to create realistic logs, for example:

```text
Patient: Test Patient 001
Doctor: Test Physiotherapist 001
Device: TEST-DEVICE-001
Sessions: 10 previous mobile-only rehab sessions + 5 previous orthosis sessions
Pain logs: mixed 0–6 normal/warning values, one high-pain alert
Alerts: low battery, calibration failed, high pain
Messages: patient-doctor support conversation
```

## Test Scenarios

Create seeded records for:

1. Normal completed mobile-only rehab session.
2. Missed mobile-only rehab session.
3. Completed orthosis/device session summary.
4. High pain session stopped safely.
5. BLE disconnection / app heartbeat lost.
6. Low battery blocks device session.
7. Calibration failed.
8. Doctor lowers ROM during live session.
9. Doctor remotely stops session safely.
10. Emergency stop pressed.

## V1 Demo Principle

If real hardware is not connected during a demo, clearly label the environment as using **test data** or **seeded logs**, not as a simulated real-time device.

For V1 implementation, build real flows:

- Real signup/login.
- Real patient-doctor linking.
- Real plan assignment.
- Real mobile-only exercise timer.
- Real pain logging.
- Real real-time chat.
- Real reports page.
- Real backend persistence.
- Real BLE/device connection path when hardware is ready.


# 18. AI and Dataset Context

## AI Purpose

Final AI task:

- 6-phase gait classification

Models user plans to use:

- Random Forest
- SVM
- XGBoost
- LSTM / deep learning
- Possibly CNN-LSTM or BiLSTM later

Datasets:

- Camargo dataset
- Team’s own treadmill dataset

AI must not directly control motor.

AI can support:

- Gait phase classification
- Walking speed estimation
- Abnormal gait flag
- Session quality score
- Progress trend
- Assistive recommendation for doctor review only

AI must not:

- Diagnose independently
- Automatically change ROM/speed/assistance
- Directly control the motor
- Replace physiotherapist decision-making

## Six Gait Phases

1. Initial contact / heel strike
2. Loading response
3. Mid stance
4. Terminal stance
5. Pre-swing / toe-off
6. Swing

## Dataset Collection

User’s dataset plan:

- Treadmill walking only
- Max speed: 4 mph
- Healthy subjects for now
- Right leg brace
- Sensors:
  - Foot IMU
  - Shank IMU
  - Thigh IMU
- Sampling rate: 100 Hz
- CSV format
- FSR later

Recommended treadmill speeds:

```text
0.5 mph
1.0 mph
1.5 mph
2.0 mph
2.5 mph
3.0 mph
3.5 mph
4.0 mph
```

Recommended recording:

- 1 minute warm-up/adaptation
- 1 minute recording per speed
- 3 trials per speed
- If time is limited, 30 seconds per trial is acceptable

## CSV Dataset Format

One CSV per trial.

Example filename:

```text
SUBJ001_SPEED_1_5MPH_TRIAL_01.csv
```

Columns:

```text
timestamp_ms
subject_id
trial_id
speed_mph
speed_mps
activity
gait_phase_label

foot_acc_x
foot_acc_y
foot_acc_z
foot_gyro_x
foot_gyro_y
foot_gyro_z

shank_acc_x
shank_acc_y
shank_acc_z
shank_gyro_x
shank_gyro_y
shank_gyro_z

thigh_acc_x
thigh_acc_y
thigh_acc_z
thigh_gyro_x
thigh_gyro_y
thigh_gyro_z

knee_angle_deg
knee_angular_velocity_deg_s

motor_current_a
motor_position_deg
motor_velocity_deg_s

fsr_heel
fsr_toe
```

If FSR is not added yet:

- Keep columns empty or remove until V2.

Metadata files:

```text
subjects.csv
trials.csv
sessions.csv
```

Example `trials.csv` fields:

```text
trial_id
subject_id
speed_mph
duration_sec
date
brace_side
notes
valid_trial
```

## Data Storage

Use CSV files for raw data.

Do not store huge raw IMU data directly in PostgreSQL forever.

Recommended:

PostgreSQL stores:

- Session metadata
- Patient ID or subject ID
- Trial ID
- Summary metrics
- File path

File storage stores:

- Raw CSV files

For demo:

```text
backend/uploads/session_csv/
```

Future:

- AWS S3
- Google Cloud Storage
- Firebase Storage

---

# 19. Safety-Critical Messages

## Emergency Stop

```text
Emergency stop activated.
Motor assistance has been stopped.
Please sit down safely.
Contact your physiotherapist if you feel pain or discomfort.
```

## High Pain

```text
High pain level reported.
Your session has been stopped for safety.
Do not continue exercising now.
Your physiotherapist has been notified.
```

## Severe Pain 9–10

```text
Severe pain reported.
Stop using the brace now.
If this is a medical emergency, call emergency services immediately.
You can also contact your emergency contact or physiotherapist.
```

## Sensor Error

```text
Sensor problem detected.
Brace assistance has been disabled.
Please check the brace placement and try calibration again.
```

## Bluetooth Disconnect

```text
Connection lost.
Brace assistance has been paused for safety.
Trying to reconnect...
```

## Calibration Failure

```text
Calibration failed.
Keep your leg still and make sure all brace parts are fixed correctly.
Try again.
```

## Low Battery

```text
Battery is too low for a safe assisted session.
Please charge your brace before starting.
```

---

# 20. Security and Privacy

## Security Requirements

Use:

- JWT authentication
- Refresh tokens
- BCrypt or Argon2 password hashing
- Role-based access control
- HTTPS only
- Input validation
- Audit logs
- Secure BLE pairing
- No default passwords
- Device authentication
- Ability to revoke a device
- Rate limiting
- Backend validation of all commands
- Firmware validation of all safety commands

## Privacy Rules

Because medical/personal data is stored:

- Include consent screen.
- Store only needed data.
- Limit access to assigned doctor.
- No public patient report links.
- Patient can export own reports.
- Patient can correct profile.
- Patient data saved for full patient journey.
- Medical data should not be exposed through unsecured channels.

## Audit Logs

All safety-related changes must be logged:

- Who changed it
- What changed
- Old value
- New value
- Patient ID
- Date/time
- Device ID if applicable
- Reason/notes

Log changes to:

- ROM
- Angular velocity
- Assistance level
- Pain threshold
- Exercise prescription
- Doctor-patient link
- Remote session stop
- Report export
- Device assignment

---

# 21. Build Order

## Phase 1: Core Software With Real Flows and Test Seed Data

Build first:

Patient app:

- Signup/login
- Profile
- Patient ID
- Doctor link request
- Home
- Exercise list
- Mobile-only exercise session timer and seeded/test session history for development
- Pain logging
- Session summary
- Messages
- Calendar
- Progress

Doctor portal:

- Doctor signup
- Admin approval
- Login
- Dashboard
- Link patient
- Patient profile
- Exercise library
- Create plan
- Set ROM/speed/assistance
- View real stored sessions and seeded/test sessions in development
- Messages
- Calendar
- Reports

Backend:

- Auth
- Roles
- Patients
- Doctors
- Admin approval
- Patient-doctor link
- Exercise library
- Plans
- Sessions
- Pain logs
- Messages
- Calendar events
- Reports

## Phase 2: Hardware Connection

Add real hardware integration:

- BLE connection
- ESP32 telemetry
- Real knee angle
- Real angular velocity
- Motor current
- Battery
- Emergency stop
- CSV upload

## Phase 3: AI

Add:

- CSV dataset upload
- 6-phase gait classification
- AI timeline
- Doctor AI analysis page
- PDF report with AI results

---

# 22. Fastest Full Integration Demo

Recommended demo flow:

```text
Doctor signs up
↓
Admin approves doctor
↓
Patient signs up
↓
Patient receives Patient ID
↓
Doctor sends link request using Patient ID
↓
Patient accepts
↓
Doctor creates rehab plan
↓
Doctor chooses exercise from library
↓
Doctor sets ROM/speed/assistance/pain threshold
↓
Patient app downloads plan
↓
Patient connects real brace when hardware is available, or test environment uses seeded session logs clearly labeled as test data
↓
Patient completes checklist
↓
Patient calibrates
↓
Patient starts session
↓
Live knee angle/speed/current/gait phase shown
↓
Pain/fault scenario optionally occurs
↓
Session summary saved
↓
Data syncs to backend
↓
Doctor sees session report, alerts, charts, and CSV
↓
Doctor exports report
```

This shows:

- Patient app
- Doctor portal
- Admin approval
- Backend
- Database
- Safety logic
- Real hardware path plus clearly labeled seeded test logs for development/demo
- Report export
- AI direction

---

# 23. Final Locked Decisions Summary

## Project

- Post-stroke only
- Right leg
- Standing and walking rehab
- Active and assistive modes
- Patient has one doctor
- Doctor can have many patients
- Physiotherapist controls stage and exercises

## Hardware

- ESP32-S3-N16R8
- MG5010E-i36 motor
- 24 V system
- CAN + UART motor communication
- BLE for app live link
- Wi-Fi optional for sync
- 3 MPU6050 IMUs
- 100 Hz sampling
- FSR later
- Emergency switch + buzzer + LEDs recommended
- Mechanical hard stops recommended

## Safety

- Max software ROM: 120°
- Default angular velocity: 45°/s
- Adjustable angular velocity: 20–90°/s
- Firmware hard cap: 90°/s
- Battery below 20% blocks assisted session
- Pain ≥7 stops session/alerts doctor
- Pain ≥9 shows emergency guidance
- BLE loss pauses/stops assistance
- AI cannot control motor
- Audit logs required

## App and Portal

- Patient app: React Native
- Doctor portal: React + Tailwind
- Backend: Spring Boot Gradle Kotlin
- Database: PostgreSQL
- Portal name: Knevo Physio Portal
- Patient app English only
- Style: modern, clean, user-friendly

## Accounts

- Signup with username + email
- Login with email, username, or ID
- Doctors sign up but need admin approval
- Multiple admins allowed
- Doctor-patient link by Patient ID + patient acceptance

## Exercise Library

- Giant official library in database
- Admin controls library
- Doctors choose exercise and customize prescription
- No free custom doctor exercises in V1
- Future: doctors suggest custom exercise, admin approves

## Notifications

- In-app + email
- Appointments should show in calendar
- Real-time chat required

## Reports

- V1: reports pages/views with charts and summaries
- V2: PDF export, CSV export, and print

## Testing / Demo Data

- Do not include fake/simulated product features
- Use fake patient accounts and seeded historical logs only for testing/demo
- V1 stores session summaries; device raw CSV remains on microSD
- V2 adds ESP32 Wi-Fi raw CSV upload

---

# 24. Notes for Another LLM Continuing the Work

When continuing this project, do not ask the user to repeat the high-level concept. The key decisions are already locked. Continue from this context.

Recommended next outputs the user may ask for:

1. Full database ERD
2. Spring Boot project structure
3. React Native app folder structure
4. React doctor portal folder structure
5. UI wireframes/page-by-page layout
6. API DTOs and entities
7. Backend code
8. Frontend code
9. BLE packet protocol
10. Seed/test data generator
11. Exercise library seed data
12. Report PDF template
13. Figma prompt/design system
14. Full graduation report section
15. Architecture diagram
16. User flow diagram
17. Safety risk table
18. Test plan
19. Dataset protocol
20. AI training pipeline

Important implementation principle:

```text
The doctor portal prescribes safe limits and exercises.
The patient app guides the session.
The brace firmware enforces hard safety locally.
The motor must never depend only on cloud/backend decisions.
```

