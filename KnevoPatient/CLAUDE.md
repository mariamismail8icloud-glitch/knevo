# KnevoPatient iOS App

Swift/SwiftUI patient-facing mobile app. Backend at `http://127.0.0.1:8080`.

* [ ] At some point the address of the backend will need to be domain name for deployment purposes

## Project Overview

This project is generated from `project.yml` using `XcodeGen`.

Whenever `project.yml` is modified, regenerate the project before building:

```sh
xcodegen generate
```

The generated project is:

```sh
KnevoPatient.xcodeproj
```

## MCP Tool Usage

Available MCP servers:

* pepper
* XcodeBuildMCP
* xcode

### UI Automation

Use **Pepper MCP** for:

* Inspecting screens
* Reading accessibility trees
* Navigating the application
* Entering text
* Tapping controls
* Capturing screenshots
* Verifying user workflows

### Build & Test

Use **XcodeBuildMCP** for:

* Discovering schemes
* Building
* Running tests
* Launching applications
* Installing applications
* Managing simulators
* Collecting build diagnostics

### Xcode Integration

Use the Apple **Xcode MCP server** (xcode) when Xcode-native project information or functionality is required.

### Fallback

Use shell commands only when the required MCP functionality is unavailable.

## Development Workflow

When implementing a change:

1. Understand the affected code.
2. Make the smallest correct change.
3. Build the application.
4. Resolve all compiler warnings and errors introduced by the change.
5. Verify the affected workflow using Pepper.
6. Report exactly what was verified.

Do not stop after a successful build when the change affects application behavior.

## Validation Workflow

After completing a feature or bug fix:

1. Build successfully.
2. Launch the application.
3. Navigate to the affected screen.
4. Exercise the modified functionality.
5. Confirm expected behavior.
6. Check for obvious regressions in nearby functionality.
7. Report validation steps and results.

## Code Quality

Before concluding work, run:

```sh
swiftformat .
swiftlint
```

Do not introduce new SwiftLint violations.

Prefer fixing existing violations in touched code.

## Testing

Prefer existing tests when available.

For automated testing:

* Use unit tests for business logic.
* Use XCTest UI tests for repeatable UI regression coverage.
* Use Pepper for exploratory validation and end-to-end verification.

When running tests from the command line:

```sh
xcodebuild test \
  -scheme KnevoPatient \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Simulator Management

* Do not assume simulator identifiers remain stable.

* Discover available simulators through MCP tools or:

```sh
xcrun simctl list devices
```

or for finding a Booted simulator

```sh
xcrun simctl list devices | grep Booted
```

before launching, installing, or testing.

## Source Layout

```text
Sources/KnevoPatient/
  KnevoPatientApp.swift          — entry point, auth routing, unauthorizedHandler
  Config/NetworkConfig.swift     — baseURL (Info.plist API_BASE_URL or 127.0.0.1:8080)
  Network/
    APIClient.swift              — @MainActor singleton; post/get; 401/403 → logout
    KeychainService.swift        — save/loadTokens/clear
    AuthModels.swift             — request/response DTOs for auth
  ViewModels/                    — one @Observable @MainActor class per feature
  Models/                        — Decodable structs matching backend DTOs
  Views/
    MainTabView.swift            — tab bar (Home / Sessions / Progress / Messages / Profile)
    ActivePlanView.swift         — shows plan; opens SessionFlowView as .sheet
    Session/                     — SessionFlowView + phase sub-views
    Auth/                        — LoginView, SignupFlowView
    Components/                  — shared UI (KnevoTextField, …)
  Services/ConfigSyncService.swift
```

## Architecture Patterns

**ViewModels** — always `@Observable @MainActor final class`. Never `ObservableObject`.

```swift
@Observable
@MainActor
final class FooViewModel {
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do { items = try await APIClient.shared.get(path: "/api/...") }
        catch { errorMessage = error.localizedDescription }
    }
}
```

**Views** — `@State private var vm = FooViewModel()` in root views; plain `var vm: FooViewModel` in child views. Use `@Bindable` only when you need a two-way `$binding`.

**Async button actions** — always `Task { await vm.method() }`:

```swift
Button { Task { await vm.save() } } label: { ... }
    .disabled(vm.isLoading)
```

**Auth propagation** — `AuthViewModel` flows via `.environment(authViewModel)`. Read it with `@Environment(AuthViewModel.self) private var authVM`.

## Networking

`APIClient.shared` is the sole HTTP client — `@MainActor`, `var accessToken: String?`.

* Token is **in-memory only**. Writing to Keychain does NOT update `APIClient.shared.accessToken` — that only happens through `AuthViewModel.login()` / `AuthViewModel.init()` (which reads Keychain on startup).
* 401 or 403 → `unauthorizedHandler` → posts `.sessionExpired` notification → `authViewModel.logout()` → app returns to `LoginView`.

Keychain keys: `com.knevo.patient.accessToken`, `com.knevo.patient.refreshToken`, `com.knevo.patient.userId`.

## Auth Flow

```text
KnevoPatientApp
  ├─ isAuthenticated = true  → MainTabView (+ .onReceive .sessionExpired → logout)
  └─ isAuthenticated = false → LoginView
```

`AuthViewModel.init()` checks Keychain; if a token exists it sets `APIClient.shared.accessToken = token` and `isAuthenticated = true`.

## Session Flow

`ActivePlanView` opens `SessionFlowView` as a `.sheet`. `SessionViewModel` drives a phase state machine:

```text
prePainCheck → running → setActive(index) → restTimer(index) → postSession → summary
```

Each phase maps to a dedicated sub-view. `phase` and other properties are `@Observable`-tracked; changing `phase` automatically re-renders `SessionFlowView`.

## Testing with Pepper

Use Pepper MCP to drive the simulator. Build once then interact:

```text
app_build(workspace: "KnevoPatient/KnevoPatient.xcodeproj/project.xcworkspace",
          simulator: "8A2D6216-629D-4CD5-A5AC-41D17571BDD2")
```

**Critical gotchas:**

* `ui_tap text:"Start Session"` can hit the button **behind** an open sheet (the one in `ActivePlanView`) instead of the one inside the sheet. Use `ui_tap point:"x,y"` when a sheet is open and the label is ambiguous.
* The "SYSTEM DIALOG BLOCKING APP" warning is often a **false positive** when the session sheet is open — run `nav_dialog detect_system` and check `in_process.detected` before dismissing.
* The network monitor (`app_network`) may auto-stop after the first request. Restart it with `app_network start` before each action you want to capture.
* To log in programmatically (e.g. after an auto-logout), fill fields via `app_eval` UITextField traversal then tap "Sign In" via `ui_tap` — this goes through `AuthViewModel.login()` which correctly sets `APIClient.shared.accessToken`.

## Code Style

* Swift 6.0, `SWIFT_STRICT_CONCURRENCY: minimal`
* iOS 17+ deployment target
* SwiftLint active; `trailing_whitespace` and `line_length` rules disabled
* 4-space indentation
* No comments unless the WHY is non-obvious
