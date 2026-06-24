# Knevo TCP Data Collection Script — Teardown Report

**File:** `knevo_dataset/knevo_tcp_save_and_check.py`
**Date:** 2026-06-21

---

## 1. CTO Summary

- **Purpose:** TCP server running on a laptop that listens for WiFi data streams from an ESP32 knee exoskeleton, writes raw sensor data to CSV, then performs quick data quality checks (sample rate, FSR saturation).
- **Runtime:** Python 3.6+, cross-platform (Windows/Linux/macOS path handling via `pathlib`), no external dependencies beyond stdlib.
- **Input/Output:** Receives TCP stream from ESP32 on port 5000 (configurable); saves comma-separated sensor rows to a CSV file specified via command-line argument.
- **Verification:** Post-capture checks measure 100 Hz sample rate compliance (95–105 Hz window), detect timing jitter (dt percentiles), and flag FSR saturation (0 counts and max 4095 counts).
- **Production readiness:** **Prototype/research-quality.** No reconnection logic, no sensor validation during capture, hardcoded port, minimal error handling, assumes perfect UTF-8 encoding.

---

## 2. Architecture & Product Management View

**Role in pipeline:**
- Sits **between hardware (ESP32) and analysis.** The ESP32 transmits 100 Hz IMU (3 accelerometers, 3 gyroscopes per segment) + FSR data via WiFi TCP; this script is the "receiver" on the laptop.
- No upstream connection: script is passive server, ESP32 is active TCP client initiating connection from the exoskeleton.

**Communication protocol:**
- **TCP server mode:** binds to `0.0.0.0:5000`, listens for one connection, reads text lines until disconnect or Ctrl+C.
- **Data format:** line-delimited CSV (comma-separated, `\n` terminated).
- ESP32 sends pre-formatted CSV rows; Python script acts as a "dumb" file sink + validator.

**File system output:**
- Output path supplied via `sys.argv[1]` (e.g., `raw/S01/S01_right_0.5mph_trial01_raw.csv`).
- Directories auto-created if missing.
- No timestamp-based naming; experimenter must supply full path including subject ID, leg, speed, trial number as part of the filename.

**CSV schema (from sample data):**
```
timestamp_us, sample_id, subject_id, trial_id, speed_mph, incline_percent, leg,
foot_ax_g, foot_ay_g, foot_az_g, foot_gx_rad_s, foot_gy_rad_s, foot_gz_rad_s,
shank_ax_g, shank_ay_g, shank_az_g, shank_gx_rad_s, shank_gy_rad_s, shank_gz_rad_s,
thigh_ax_g, thigh_ay_g, thigh_az_g, thigh_gx_rad_s, thigh_gy_rad_s, thigh_gz_rad_s,
heel_fsr_raw, midfoot_fsr_raw, heel_contact, midfoot_contact, gait_phase_id, gait_phase_label, knee_angle_est_deg
```

**Verification logic:**
1. **Sample rate check:** Calculates dt intervals from consecutive timestamps; flags deviations > 20 ms (dropped/delayed) or < 5 ms (duplicates/clock errors); accepts 95–105 Hz as nominal.
2. **FSR saturation:** Counts zero values (disconnected sensor) and maxed values (4095 = clipping); reports min/max per FSR channel.

**Configuration & parameterisation:**
- **Hardcoded:** Port 5000 (default), IP bind `0.0.0.0`, FSR column indices 25 and 26, saturation threshold 4095, rate window 95–105 Hz.
- **Parameterised:** Output path (`argv[1]`), port number (`argv[2]`, optional).
- **Missing:** Subject ID, trial metadata, leg designation — embedded in the output filename by the experimenter, not read/validated by the script.

**Error handling:**
- **Connection drop:** Loop terminates silently on stream EOF; no retry.
- **Bad data:** Malformed lines with < 27 CSV columns are skipped; non-integer timestamps/FSR values caught with try/except.
- **Disk full/permission errors:** Not caught; script will crash if file write fails.
- **Graceful shutdown:** Ctrl+C caught; socket closed in finally block.

---

## 3. Detailed Findings

**All imports and their roles:**

| Import | Role |
|--------|------|
| `socket` | TCP server setup |
| `sys` | Command-line argument parsing |
| `pathlib.Path` | Cross-platform file path handling |
| `time` | Wall-clock profiling and timestamp collection |

**All hardcoded values — risk flags:**

| Value | Risk |
|-------|------|
| Port 5000 | Medium — must match ESP32 config |
| `0.0.0.0` bind address | Low — no option to bind to specific interface |
| FSR column indices 25, 26 | **High** — no validation that column count matches; if CSV format changes, script fails silently |
| Saturation threshold 4095 | Medium — assumes 12-bit ADC; breaks if sensor changes |
| Rate window 95–105 Hz | Medium — hardcoded for nominal 100 Hz; inflexible if capture rate changes |
| dt thresholds 20 ms / 5 ms | Medium — heuristic bounds; no documented justification |

**All functions:**

| Function | Purpose | Inputs | Outputs | Side Effects |
|----------|---------|--------|---------|--------------|
| (inline setup) | Parse args, create directories, bind TCP server | `sys.argv`, port default 5000 | Server socket, output file path | Creates directories; prints setup messages |
| (main receive loop) | Read CSV lines from ESP32, write to disk, collect metadata | TCP stream | None | Writes CSV; appends to timestamps/FSR lists; counts rows; prints progress every 1000 rows |
| (post-capture analysis) | Calculate sample rate, timing jitter, FSR stats | Timestamps list, heel_vals, mid_vals | Printed summary | Stdout only |

**Exact TCP payload parsing:**

1. `conn.makefile("r", encoding="utf-8", errors="ignore", newline="\n")` — treats connection as text stream, ignores encoding errors silently.
2. Lines split on `,`; blank lines, comment lines (`#`), and header line (`timestamp_us`) are skipped.
3. Field 0 extracted as timestamp (int); fields 25–26 as FSR values (int).
4. Malformed rows with `ValueError` are silently dropped.
5. No message framing: no length prefixes, checksums, or sequence numbers.

**CSV output schema (exact columns in order):**

| Index | Column | Notes |
|-------|--------|-------|
| 0 | `timestamp_us` | ESP32 microseconds, device-local clock |
| 1 | `sample_id` | |
| 2 | `subject_id` | |
| 3 | `trial_id` | |
| 4 | `speed_mph` | |
| 5 | `incline_percent` | |
| 6 | `leg` | right/left |
| 7–9 | `foot_ax/ay/az_g` | Foot accelerometer (g) |
| 10–12 | `foot_gx/gy/gz_rad_s` | Foot gyroscope (rad/s) |
| 13–15 | `shank_ax/ay/az_g` | Shank accelerometer (g) |
| 16–18 | `shank_gx/gy/gz_rad_s` | Shank gyroscope (rad/s) |
| 19–21 | `thigh_ax/ay/az_g` | Thigh accelerometer (g) |
| 22–24 | `thigh_gx/gy/gz_rad_s` | Thigh gyroscope (rad/s) |
| 25 | `heel_fsr_raw` | Raw ADC 0–4095 |
| 26 | `midfoot_fsr_raw` | Raw ADC 0–4095 |
| 27 | `heel_contact` | Placeholder in raw collection |
| 28 | `midfoot_contact` | Placeholder in raw collection |
| 29 | `gait_phase_id` | Placeholder |
| 30 | `gait_phase_label` | Placeholder |
| 31 | `knee_angle_est_deg` | Placeholder |

**Data quality checks performed:**

1. Total lines and data rows (excluding comments/headers), progress indicator every 1000 rows.
2. Duration from first to last timestamp; measured sample rate.
3. Mean/min/max inter-sample interval (dt); count of outliers (> 20 ms, < 5 ms).
4. FSR: min/max values, count of zeros, count of 4095 saturation per channel.
5. Rate verdict: "OK" if 95–105 Hz, else "WARN — not close to 100 Hz".

---

## 4. Observations & Insights

**What this script reveals about the lab setup:**

1. **Tethered, single-trial architecture.** Experimenter manually supplies output filename with subject/trial metadata embedded; no session management, no database, no automatic naming.
2. **Raw capture trust model.** Script trusts ESP32 to send correct CSV format and column order — no schema validation or versioning.
3. **Post-hoc validation only.** Data quality checks happen after capture ends; no real-time alerting to experimenter during collection.
4. **Power balance is inverted.** Laptop is the server; ESP32 is the client. Works for tethered lab testing but not for mobile/field use.
5. **Metadata sprawl.** Subject ID, trial ID, speed, incline, leg, trial number are embedded in the CSV filename string. No programmatic validation that filename matches CSV header content.

**What would need to change for the Knevo product:**

Current lab model:
```
ESP32 → [WiFi TCP] → Laptop (Python receiver) → CSV file → Offline analysis
```

Required product model:
```
ESP32 → [BLE] → iOS app (Swift) → [WiFi HTTPS] → Spring Boot backend
                                                    ↓
                                              Session-aware persistence
                                              (TherapySession → SetConfig → SetRecord)
```

Key changes:
1. **Protocol flip:** BLE instead of WiFi TCP; iOS app initiates, not ESP32.
2. **Real-time relay:** iOS app buffers 100 Hz stream and uploads to backend.
3. **Session binding:** Data tied to TherapySession ID + TherapySetRecord ID, not a free-form filename.
4. **Metadata from backend:** Trial parameters come from TherapySetConfig, not filename parsing.
5. **Offline tolerance:** Mobile app must queue data if backend is unreachable; lab script has none.
6. **Timestamp reconciliation:** Lab uses ESP32 microsecond timestamps; product needs server-side UTC.

**Calibration vs. raw capture:**
The script does **not** differentiate between calibration and raw modes. The `recording_type` metadata in the CSV header (`cal_static_standing` vs. `treadmill_walking_trial`) is set by the ESP32, not this script. The script treats all incoming data identically.

---

## 5. Contradictions with Knevo Product Spec

**[CONTRADICTION #1: Communication Protocol]**
- Lab script: TCP server on laptop; ESP32 actively connects as client.
- Product spec: BLE radio to iOS app; iOS app initiates pairing.
- Impact: Entire networking stack must be replaced.

**[CONTRADICTION #2: Session & Set Model]**
- Lab script: No concept of session, set, or set ID. Data is one-off CSV file named by experimenter.
- Product spec: Data must be tagged with TherapySession UUID → TherapySetConfig ID → TherapySetRecord ID.
- Impact: Script has no session lifecycle; product requires explicit start/stop signals from iOS app.

**[CONTRADICTION #3: Data Destination]**
- Lab script: Writes CSV to laptop disk; no backend connectivity.
- Product spec: iOS app buffers stream and relays to Spring Boot backend via HTTPS.
- Impact: Entire persistence and sync layer is absent from lab script.

**[CONTRADICTION #4: Metadata Binding]**
- Lab script: Trial parameters (speed_mph, incline_percent, leg) are ESP32-set CSV headers; script does not validate them.
- Product spec: Parameters come from TherapySetConfig on backend; app downloads, enforces via BLE, and verifies compliance.
- Impact: Lab script has no authority model; product requires app-to-exoskeleton handshake.

**[CONTRADICTION #5: Sample Rate Assumption]**
- Lab script: Hardcoded check for 100 Hz; assumes fixed 10 ms nominal dt.
- Product spec: Sample rate may be configurable per SetConfig.
- Impact: Rate validation logic is not portable.

**[CONTRADICTION #6: Timestamp Reference Frame]**
- Lab script: Uses ESP32 microsecond timestamps (device-local clock); no server-side clock correlation.
- Product spec: Backend requires UTC server timestamps for multi-device sync and analytics.
- Impact: Lab timestamps are device-local; product needs server-side timestamping or NTP sync.

**[CONTRADICTION #7: Error Recovery & Reconnection]**
- Lab script: Single connection, no retry on drop; experimenter must manually restart.
- Product spec: iOS app must handle WiFi interruption, BLE drop-outs, and backend failures gracefully.
- Impact: Lab script is not resilient; product must be.

**[CONTRADICTION #8: Real-Time Feedback]**
- Lab script: Data quality checks are post-hoc; no real-time alerting.
- Product spec: App must provide real-time feedback (sensor disconnected, out of range) for mid-session correction.
- Impact: Lab script has no closed-loop sensing; product requires it.

**[CONTRADICTION #9: Placeholder Data Fields]**
- Lab script: `heel_contact`, `midfoot_contact`, `gait_phase_id`, `gait_phase_label`, `knee_angle_est_deg` are marked as "placeholders in raw collection" — script ignores them.
- Product spec: Gait phase and knee angle must be computed in real-time (TinyML on ESP32-S3).
- Impact: Lab script captures raw IMU + FSR only; product must add on-device ML pipeline.

---

## Summary

| Aspect | Lab Script | Product Spec | Gap |
|--------|-----------|--------------|-----|
| Receiver | Laptop TCP server (Python) | iOS app (Swift) | Complete rewrite |
| Protocol | WiFi TCP | BLE → WiFi HTTPS relay | New BLE stack + backend API |
| Session binding | Filename-based (free-form) | TherapySession + SetRecord UUID | Add session lifecycle |
| Metadata source | CSV header (ESP32-set) | Backend API (TherapySetConfig) | Add app-to-backend config fetch |
| Data persistence | CSV file (laptop disk) | Backend database (Spring Boot) | Add REST/sync layer |
| Validation | Post-hoc (after capture) | Real-time (during capture) | Add sensor health monitoring |
| Timestamps | ESP32 microseconds (device-local) | Server UTC | Add clock sync / NTP |
| Gait processing | Placeholders | Real-time phase + angle (TinyML) | Add on-device ML pipeline |
| Reconnect | No retry | Queue + resume on reconnect | Add offline buffer + sync |

This script is a proof-of-concept reference implementation. The product requires a fundamentally different architecture — BLE instead of TCP, iOS instead of laptop, backend-driven instead of device-driven, session-aware instead of file-based.
