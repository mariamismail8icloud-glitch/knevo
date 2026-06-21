# Knevo ESP32 Firmware — Teardown Report

**File:** `knevo_dataset/knevo_FINAL_fixed_wifi_collection_BUS1_10_11.ino`
**Date:** 2026-06-21

---

## 1. CTO Summary

- **Purpose:** ESP32-S3 data acquisition firmware that reads 3× MPU6050 IMUs + 2× FSR sensors at 100 Hz and streams CSV-formatted sensor data over TCP/WiFi to a laptop for gait analysis.
- **Hardware target:** ESP32-S3 microcontroller with 3 MPU6050 6-axis IMUs (foot, shank, thigh) and 2 FSR pressure sensors (heel, midfoot).
- **Communication protocols:** WiFi 802.11 STA mode + TCP client to fixed laptop server; I2C at 400 kHz on 2 separate buses for sensor control.
- **Data produced:** CSV stream — timestamp, sample ID, subject/trial metadata, 3× 6-axis IMU data (accel in g, gyro in rad/s), 2× FSR raw ADC values, and placeholder columns for gait phase/knee angle. Delivered to laptop at 100 rows/second over TCP port 5000.
- **Critical risks:**
  - WiFi credentials and server IP hardcoded in firmware source (lines 46–51) — cannot be provisioned at runtime.
  - No BLE — device cannot communicate with a mobile app.
  - No session or set model — recording triggered by serial commands, not by an app.
  - No motor control logic of any kind.
  - Gait phase and knee angle columns are hardcoded placeholders.
  - No error recovery if WiFi drops mid-recording; data loss is silent.
- **Production readiness:** **Prototype/research-quality.** Suitable for lab data collection and sensor validation. Not suitable for production — no provisioning, no session model, no mobile integration, no therapy control.

---

## 2. Architecture & Product Management View

### Component Breakdown

1. **I2C Bus Management:** Two independent I2C buses (Bus0 GPIO8/9 @ 400 kHz, Bus1 GPIO10/11 @ 400 kHz) to allow 3 MPU6050s without address-conflict multiplexing.
2. **IMU Sensor Stack:** Three MPU6050s configured to ±16g accel, ±2000 deg/s gyro, 100 Hz output (via 200 Hz internal sampling + DLPF).
3. **FSR Analog Input:** Two GPIO pins (GPIO1, GPIO2) reading raw 12-bit ADC (0–4095).
4. **WiFi Stack:** STA mode connecting to hardcoded SSID/password; TCP client to fixed server IP/port.
5. **Serial Command Interface:** 115200 baud serial monitor accepting commands: `STATUS`, `CAL_*`, `TRIAL`.

### Data Flow

```
MPU6050 (×3) ──I2C──┐
                     ├──► sendOneSample() ──► TCP line ──► Laptop Python receiver ──► CSV file
FSR (×2) ──ADC ──────┘
```

Timing: `micros()` poll at 10 ms intervals (100 Hz). Each sample is sent immediately; no buffering.

### Configuration & Parameterisation

| Aspect | Hardcoded? | Value | Line |
|--------|-----------|-------|------|
| WiFi SSID | **Yes — CRITICAL** | `WE_351430` | 46 |
| WiFi password | **Yes — CRITICAL** | `19005152` | 47 |
| Server IP | **Yes — HIGH** | `192.168.1.63` | 50 |
| Server port | **Yes** | `5000` | 51 |
| Sample rate | **Yes** | 100 Hz | 55 |
| I2C speed | **Yes** | 400 kHz | 486–487 |
| Accel range | **Yes** | ±16g | 78 |
| Gyro range | **Yes** | ±2000 dps | 79 |
| MPU DLPF | **Yes** | 0x03 (44 Hz cutoff) | 172 |
| MPU sample rate divisor | **Yes** | 0x04 → 200 Hz internal | 171 |

**Configurable at runtime via serial commands:**
- Recording type (cal_static_standing, cal_right_foot_unloaded, cal_normal_standing_contact, cal_knee_flexion_extension, treadmill_walking_trial)
- Subject ID, trial ID, speed (mph), trial number, duration (seconds)

### Session/Trial Concept

No persistent session model. Each trial is triggered by a serial command (e.g., `TRIAL S01 T001 0.5 1 60`). The TRIAL is the atomic unit — there is no concept of TherapySession, TherapySetConfig, or TherapySetRecord.

Recording duration is either type-specific (10 s, 5 s, 30 s) or user-specified. Session metadata is written into the CSV header and repeated in every row.

### Multi-Sensor Coordination

- **Bus0 (GPIO8/9):** Foot @ 0x68 (AD0 → GND) + Shank @ 0x69 (AD0 → 3.3V). Two sensors sharing one bus, differentiated by address pin.
- **Bus1 (GPIO10/11):** Thigh @ 0x68 (AD0 → GND). Single sensor.
- **Reading strategy:** Sequential polling in `sendOneSample()` — foot, then shank, then thigh.
- **No multiplexer.** Two independent physical I2C buses replace it.

### Error Handling & Fault Recovery

| Failure Mode | Detection | Response |
|---|---|---|
| IMU init fails (WHO_AM_I mismatch) | `initMPU()` check | Set `imu.ok = false`; abort recording |
| I2C read returns 0xFF | `readReg()` | Treat as failure; no retry |
| WiFi not connected | `connectWiFi()` | Retry up to 40× (500 ms each); abort after 20 s |
| Server connection fails | `connectServer()` | Print error; abort recording |
| Late sample (> 2× period) | Timing check | Increment `lateEvents`; skip catch-up; rebase timing to now |
| **WiFi dropout during recording** | **None** | **Data loss; no reconnect; silent failure** |

### TCP/CSV Payload Schema

**Header (14 lines):**
```
# Knevo_Treadmill_Gait_Prototype
# recording_type,<type>
# subject_id,<subject>
# trial_id,<trial>
# speed_mph,<speed>
# incline_percent,0
# leg,right
# trial_number,<num>
# duration_s,<duration>
# sample_hz,100
# accel_unit,g
# gyro_unit,rad_s
# fsr_unit,raw_adc_0_4095
# notes,labels and knee angle are placeholders in raw collection
```

**Data row column headers:**
```
timestamp_us, sample_id, subject_id, trial_id, speed_mph, incline_percent, leg,
foot_ax_g, foot_ay_g, foot_az_g, foot_gx_rad_s, foot_gy_rad_s, foot_gz_rad_s,
shank_ax_g, shank_ay_g, shank_az_g, shank_gx_rad_s, shank_gy_rad_s, shank_gz_rad_s,
thigh_ax_g, thigh_ay_g, thigh_az_g, thigh_gx_rad_s, thigh_gy_rad_s, thigh_gz_rad_s,
heel_fsr_raw, midfoot_fsr_raw, heel_contact, midfoot_contact, gait_phase_id, gait_phase_label, knee_angle_est_deg
```

Notable: `incline_percent` is always `0`; `leg` is always `right`; `heel_contact`, `midfoot_contact`, `gait_phase_id`, `gait_phase_label`, `knee_angle_est_deg` are hardcoded placeholders (`-1`, `unlabeled`, empty).

### Calibration vs. Raw Capture

| Aspect | Calibration (CAL_*) | Raw Trial (TRIAL) |
|--------|--------------------|--------------------|
| Recording type values | `cal_static_standing`, `cal_right_foot_unloaded`, `cal_normal_standing_contact`, `cal_knee_flexion_extension` | `treadmill_walking_trial` |
| Speed | 0.0 mph | User-specified |
| Duration | 10 s / 5 s / 30 s (type-specific) | User-specified; default 60 s |
| CSV schema | Identical | Identical |
| Firmware difference | **None** — both are raw sensor streams; post-processing on the laptop distinguishes them | |

---

## 3. Detailed Findings

### Libraries & Dependencies

| Library | Purpose |
|---------|---------|
| `Wire.h` | I2C communication (TwoWire) |
| `WiFi.h` | WiFi STA mode, TCP client |
| `esp_timer.h` | High-resolution timer (`esp_timer_get_time()`) |
| `math.h` | Math functions (e.g., `sqrt()` in STATUS) |
| Arduino Core (implicit) | `Serial`, `analogRead()`, `delay()`, `micros()`, `pinMode()` |

### Hardcoded Values — Risk Flags

| Value | Line | Risk |
|-------|------|------|
| `WE_351430` (SSID) | 46 | **CRITICAL** — Network-specific; credential in source |
| `19005152` (WiFi password) | 47 | **CRITICAL** — Plaintext credential in firmware source |
| `192.168.1.63` (server IP) | 50 | **HIGH** — Laptop IP-specific; blocks device reuse |
| `5000` (port) | 51 | Medium |
| `100` (sample Hz) | 55 | **HIGH** — Therapy protocol may require different rates |
| `0x18` (accel config ±16g) | 78 | Medium — fixed dynamic range |
| `0x18` (gyro config ±2000 dps) | 79 | Medium |
| `0x04` (MPU sample divisor) | 171 | Low — reasonable internal oversampling |
| `0x03` (MPU DLPF 44 Hz) | 172 | Medium — not tunable |
| `0x68`, `0x69` (IMU addresses) | 66–68 | Medium — physical; requires rewiring to change |
| `1`, `2` (FSR GPIO pins) | 63–64 | Medium |
| `8`, `9`, `10`, `11` (I2C GPIO pins) | 58–61 | Medium |
| `"unlabeled"`, `-1` (placeholders) | 314 | Low |

### IMU Struct (`ImuDef`)

```c
struct ImuDef {
  TwoWire*    bus;         // I2C_BUS0 or I2C_BUS1
  const char* busName;     // Human-readable label
  uint8_t     addr;        // 0x68 or 0x69
  const char* name;        // "foot", "shank", "thigh"
  bool        ok;          // Health flag set by initMPU()
  uint8_t     accelCfg;    // Read-back config register value
  uint8_t     gyroCfg;     // Read-back config register value
  float       accelScale;  // LSBs per g
  float       gyroScaleDps;// LSBs per deg/s
};
```

### Function-by-Function Breakdown

| Function | Lines | Purpose | Key Notes |
|----------|-------|---------|-----------|
| `readReg()` | 106–112 | Single I2C register read | Returns 0xFF on error; no retry |
| `writeReg()` | 114–119 | Single I2C register write | Returns bool success |
| `accelScaleFromConfig()` | 121–129 | Maps accel config byte → LSBs/g | ±2/4/8/16g supported |
| `gyroScaleFromConfig()` | 131–139 | Maps gyro config byte → LSBs/dps | ±250/500/1000/2000 dps supported |
| `readMotion6()` | 141–157 | Burst-read accel + gyro from MPU6050 | Reads 14 bytes in one I2C transaction; populates 6 int16_t refs |
| `initMPU()` | 159–200 | Initialise one MPU6050 | Checks WHO_AM_I (0x68 or 0x70); writes + reads back config; sets scale values |
| `scanBus()` | 202–216 | I2C bus discovery | Debug utility; prints all found addresses |
| `connectWiFi()` | 218–241 | Connect to hardcoded SSID | Retries 40× at 500 ms; disables WiFi sleep |
| `connectServer()` | 243–256 | TCP connect to server | Sets TCP_NODELAY; single attempt |
| `allIMUsOK()` | 258–261 | Check all 3 IMUs healthy | Returns false if any `imu.ok == false` |
| `sendCSVHeader()` | 263–280 | Send 14-line metadata header + column row | Writes to TCP client |
| `sendOneSample()` | 282–327 | Acquire and transmit one sensor row | Reads 3 IMUs + 2 FSRs; formats snprintf; sends via TCP |
| `recordToLaptop()` | 329–372 | Main recording orchestrator | Init IMUs → WiFi → server → header → sample loop → close → print stats |
| `splitTokens()` | 374–390 | Space-delimited string tokeniser | Used by `handleCommand()` |
| `runStatus()` | 392–433 | Hardware diagnostic | I2C scan + IMU init + 30-sample accel magnitude + 10-sample FSR + WiFi test |
| `printHelp()` | 435–443 | Print serial command list | Informational only |
| `handleCommand()` | 445–476 | Parse and dispatch serial commands | Handles STATUS, CAL_*, TRIAL |
| `setup()` | 478–493 | Boot initialisation | Serial, ADC, GPIO, I2C buses, run STATUS |
| `loop()` | 495–501 | Main event loop | Polls serial; blocks on read; dispatches commands |

### I2C Bus Topology

```
GPIO8 (SDA) ─┬─► Foot  MPU6050 @ 0x68 (AD0 → GND)
GPIO9 (SCL) ─┘─► Shank MPU6050 @ 0x69 (AD0 → 3.3V)
                 ──── Bus0 ────

GPIO10 (SDA) ──► Thigh MPU6050 @ 0x68 (AD0 → GND)
GPIO11 (SCL) ──  ──── Bus1 ────
```

No multiplexer used. Two independent TwoWire buses replace it.

### How 100 Hz is Achieved

- **MPU6050 internal rate:** 200 Hz (register 0x19 = 0x04; formula: 1000 / (1 + SMPLRT_DIV)).
- **DLPF:** 0x03 (44 Hz low-pass; reduces aliasing).
- **Firmware timing:** Polling loop in `recordToLaptop()` checks `micros() >= next_us`; period = `PERIOD_US = 10000` µs.
- **On-time:** `next_us += PERIOD_US` each successful sample.
- **Late sample guard:** If behind by > 2× period (> 20 ms), rebase `next_us = now` rather than burst-catching up.
- **Spin wait:** `delayMicroseconds(200)` between poll iterations.
- **Actual rate:** ~100 Hz with occasional skips if WiFi stalls the TCP write.

### CSV Field Encoding (Full Detail)

| Column | Format | Value |
|--------|--------|-------|
| `timestamp_us` | `%lld` | `esp_timer_get_time()` — microseconds since ESP32 boot |
| `sample_id` | `%lu` | Global counter, starts at 0 |
| `subject_id`, `trial_id` | `%s` | Strings from serial command |
| `speed_mph` | `%.2f` | Float from serial command |
| `incline_percent` | literal | Always `0` |
| `leg` | literal | Always `right` |
| Accel fields (×9) | `%.5f` | raw_int16 / accelScale (in g) |
| Gyro fields (×9) | `%.6f` | raw_int16 / gyroScaleDps × DEG_TO_RAD_F (in rad/s) |
| `heel_fsr_raw`, `midfoot_fsr_raw` | `%d` | `analogRead()` — 0 to 4095 |
| `heel_contact`, `midfoot_contact` | literal | Always `-1` |
| `gait_phase_id` | literal | Always `-1` |
| `gait_phase_label` | literal | Always `unlabeled` |
| `knee_angle_est_deg` | literal | Always empty |

---

## 4. Observations & Insights

### Visible Design Decisions

1. **Two I2C buses instead of a multiplexer.** Avoids active or passive MUX complexity. Trade-off: 4 extra GPIO pins consumed, and the bus topology is fully hardcoded.
2. **No buffering — immediate TCP send.** Each sample is formatted and sent as a single line the moment it is acquired. Simpler implementation but higher WiFi load and susceptibility to TCP backpressure.
3. **Config read-back after write.** After writing accel/gyro config registers, the firmware reads them back to confirm they were accepted (lines 180–181). Defensive practice for noisy I2C.
4. **Polling-based timing, not interrupt-driven.** Uses `micros()` spin-polling rather than a hardware timer ISR. Simpler but less precise; WiFi or serial I/O can delay a sample.
5. **No catch-up bursting.** If a sample is late, the firmware skips ahead in time rather than sending a burst. Correct for real-time display; means total sample count can be less than expected.
6. **Placeholder gait columns.** The CSV schema pre-allocates `gait_phase_id`, `gait_phase_label`, and `knee_angle_est_deg`, all hardcoded to placeholder values. Intentional forward compatibility for future ML integration.

### What Must Change for Knevo Product Spec

| Capability | Current Firmware | Product Spec | Change Needed |
|---|---|---|---|
| BLE provisioning | None | BLE GATT service for WiFi credentials, server IP, therapy config | Add BLE peripheral stack |
| Session model | Serial command per TRIAL | TherapySession → TherapySetConfig → TherapySetRecord | Add session FSM |
| Capture trigger | Serial command | Mobile app sends set-start via BLE | Replace serial parser with BLE handler |
| Data destination | Hardcoded laptop IP | Mobile app relay over local WiFi | Configurable server address via BLE provisioning |
| Motor control | None | MG5010E-i36 driver integration | Add motor control subsystem |
| Configuration | Hardcoded in firmware | Delivered per TherapySetConfig via BLE | Add NVS config storage + BLE config reception |
| I2C topology | 2 buses (GPIO8/9, GPIO10/11) | May use multiplexer per spec note | Verify vs final PCB; refactor if needed |
| Gait phase computation | Hardcoded placeholder | TinyML on ESP32-S3 at runtime | Add ML inference pipeline |

### Reusability Assessment

**Reusable as-is:**
- `initMPU()`, `readReg()`, `writeReg()`, `readMotion6()`, `accelScaleFromConfig()`, `gyroScaleFromConfig()` — all IMU init and read routines.
- FSR analog read (`analogRead()` with 12-bit resolution).
- CSV field schema and column ordering — compatible with the `knevo_context.md` data model.
- `runStatus()` / `scanBus()` — useful debug utilities.

**Must be rebuilt:**
- WiFi provisioning (hardcoded → BLE-provisioned).
- Serial command parser → BLE GATT command handler.
- TCP client to laptop → configurable WiFi relay to mobile app.
- Recording trigger → therapy session FSM.
- No motor control exists; must be written from scratch.
- Timer/interrupt-driven sampling (replace polling loop for higher timing precision).

---

## 5. Contradictions with Knevo Product Spec

**[CONTRADICTION #1: No BLE — Critical]**
- Firmware: WiFi only; no BLE stack.
- Spec: BLE for provisioning, config delivery, set-start signals, heartbeat, emergency stop.
- Impact: Entire control plane is missing. Device cannot pair with or receive commands from the iOS app.

**[CONTRADICTION #2: Wrong Data Destination — Critical]**
- Firmware: TCP client connects to hardcoded laptop IP (`192.168.1.63:5000`).
- Spec: Mobile iOS app receives 100 Hz WiFi stream and relays to backend. Device has no direct backend connection.
- Impact: Data goes to laptop, not mobile app. Entire relay architecture is absent.

**[CONTRADICTION #3: No Session or Set Model — Critical]**
- Firmware: Flat TRIAL triggered by serial command; no concept of sets or sessions.
- Spec: TherapySession → TherapySetConfig → TherapySetRecord; capture is bounded by set start/stop signals from mobile app.
- Impact: No session lifecycle; data cannot be associated with the correct TherapySetRecord.

**[CONTRADICTION #4: No Motor Control — Critical]**
- Firmware: IMU and FSR data acquisition only; zero motor control logic.
- Spec: MG5010E-i36 motor integration; firmware must generate resistance/assist torque based on gait phase.
- Impact: The core therapeutic function of the device is entirely absent.

**[CONTRADICTION #5: Hardcoded Credentials — Security]**
- Firmware: WiFi SSID and password in plaintext source (lines 46–47).
- Spec: BLE provisioning delivers credentials at runtime; no credentials in firmware binary.
- Impact: Security risk; deployment blocker for any device outside the original lab network.

**[CONTRADICTION #6: I2C Topology — Medium]**
- Firmware: Two separate TwoWire buses (GPIO8/9 and GPIO10/11).
- Spec (knevo_context.md): Mentions I2C multiplexer for multi-sensor topology.
- Impact: Functional difference; must be reconciled with final PCB hardware design. The firmware approach works but may not match the physical board.

**[CONTRADICTION #7: Gait Phase & Knee Angle — Medium]**
- Firmware: Placeholder values (`-1`, `unlabeled`, empty) — computed nowhere.
- Spec: On-device TinyML on ESP32-S3 for real-time 6-phase gait classification and knee angle estimation.
- Impact: ML pipeline must be added. Raw IMU data is captured correctly; inference on top of it is absent.

**[CONTRADICTION #8: Configuration Immutability — High]**
- Firmware: All parameters (sample rate, accel range, gyro range, server IP, port) hardcoded at compile time.
- Spec: TherapySetConfig delivered via BLE at session start; parameters must be configurable per patient and per set.
- Impact: Device cannot adapt to different patients or therapy protocols without reflashing.

---

## Summary

**This firmware is a lab gait data collector.** It successfully acquires 100 Hz multi-segment IMU and FSR data and streams it to a laptop for offline analysis. The sensor read stack is solid and reusable.

**It is not a therapy device.** For the Knevo product, the following must be built from scratch: BLE stack, therapy session FSM, motor control driver, configurable provisioning, and on-device ML inference. The sensor acquisition core (IMU init, burst read, FSR ADC, CSV schema) can carry forward.
