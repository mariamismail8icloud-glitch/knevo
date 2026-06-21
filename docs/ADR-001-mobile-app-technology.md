# ADR-001: Mobile Application Technology Stack

**Status:** Accepted
**Date:** 2026-06-21

---

## Context

The patient-facing mobile application is a critical component of the knee exoskeleton rehabilitation system. It must:

- **BLE communication** — scan, connect, provision the device's WiFi credentials, deliver therapy configs, and send set-start signals. Must function reliably with iOS background modes (bluetooth-central).
- **Local WiFi data relay** — receive a continuous 100 Hz sensor stream from the exoskeleton device over local WiFi during active therapy sets and forward it to the backend.
- **Real-time config sync** — receive backend push updates immediately when the doctor changes a therapy config, even when the app is in the background.
- **Session reminders** — schedule and deliver local push notifications on therapy days derived from the active TherapyConfig schedule, without requiring the patient to open the app.
- **Target platform** — iOS only. Android is theoretically possible but explicitly out of scope and will not be tested.

---

## Options Considered

### Option 1: React Native (JavaScript / TypeScript)

The most widely used cross-platform mobile framework. Referenced in the original spec, though the existing codebase does not actually use it.

**BLE:** Supported via `react-native-ble-plx`. Functional, but BLE background state restoration on iOS requires bridging into native code and has a history of reliability issues under edge cases (reconnection, background wakeup).

**Local WiFi (100 Hz relay):** Requires a third-party TCP socket library. More importantly, incoming data must pass through the React Native JS bridge before application code can process and forward it — introducing latency and GC pressure at high frequencies.

**Background tasks:** iOS restricts background execution. Achievable but fragile through bridging.

**Cross-platform benefit:** Not applicable — scope is iOS only.

**Verdict:** The JS bridge adds risk to the two most demanding requirements (BLE reliability + high-frequency WiFi relay) with no cross-platform benefit to justify the trade-off.

---

### Option 2: Flutter (Dart)

Google's cross-platform framework that compiles to native ARM code — no JS bridge.

**BLE:** `flutter_blue_plus` is a mature library. Background BLE on iOS still requires careful handling and does not have the same depth as Core Bluetooth.

**Local WiFi:** Better than React Native — Dart runs natively, so the 100 Hz data path has no bridge overhead.

**Background tasks:** Achievable via `flutter_background_service`, but still a layer over iOS primitives.

**Cross-platform benefit:** Not applicable — scope is iOS only.

**Verdict:** A credible fallback if the team has no Swift experience. Better than React Native for this workload, but still adds a layer over the native iOS frameworks that matter most here.

---

### Option 3: Native Swift (SwiftUI)

Apple's own language and declarative UI framework, with direct access to all iOS system capabilities.

**BLE:** Core Bluetooth — Apple's first-party BLE stack. The most reliable and fully-featured BLE implementation on iOS. Background state restoration, reconnection handling, and the `bluetooth-central` background mode all work without bridging.

**Local WiFi (100 Hz relay):** Full access to `Network.framework` and `URLSession`. No bridge — data is processed at native speed.

**Push / reminders:** APNs (Apple Push Notification service) and `UserNotifications` — first-party, no libraries needed.

**Background tasks:** `BGTaskScheduler` + declared background modes (`bluetooth-central`, `remote-notification`) — the iOS-native approach with the best support.

**iOS-only:** Matches the project scope exactly. No cross-platform overhead.

**Development speed:** SwiftUI is modern and declarative. Comparable in productivity to React for developers new to it.

---

## Decision

**Native Swift with SwiftUI.**

### Reasoning

The cross-platform argument — the primary reason to choose React Native or Flutter — does not apply to this project. iOS is the only target, both by design and by testing constraint.

Without the cross-platform benefit, using a bridging framework means paying the cost of an abstraction layer with no return:

1. **BLE reliability is the single most critical capability.** Core Bluetooth provides the most reliable BLE implementation on iOS, including background operation. Any bridge layer adds a failure surface to the most important feature in the app.

2. **The 100 Hz WiFi sensor relay has no tolerance for bridge latency.** At 100 samples per second, each carrying ~30 sensor values, data must be received, buffered, and forwarded efficiently. Native code handles this trivially; the React Native JS bridge introduces measurable overhead.

3. **iOS background restrictions are best navigated natively.** BLE background mode, APNs, and local notifications are all first-class citizens in the iOS SDK. Accessing them through bridging increases fragility and debugging complexity.

4. **Graduation project timeline favours fewer moving parts.** Third-party bridging libraries are common sources of version conflicts, maintenance gaps, and platform-specific bugs. Native Swift has no such dependencies for the features this app requires.

---

## Consequences

- The mobile app is iOS-only and cannot be deployed to Android without a rewrite or a significant porting effort.
- The development team requires Swift and SwiftUI familiarity. If the team has no iOS experience, Flutter should be reconsidered as the fallback.
- The existing patientapp codebase (vanilla JS web app) is not reusable. It should be treated as a UI/UX reference prototype only.
- All BLE and networking code will use Apple's first-party frameworks: Core Bluetooth, Network.framework, URLSession, UserNotifications, APNs.
