# KnevoPatient

Native Swift + SwiftUI iOS patient app for the Knevo knee exoskeleton rehabilitation system. iOS 18+.

## Prerequisites

- macOS with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- [SwiftLint](https://github.com/realm/SwiftLint): `brew install swiftlint`
- `knevo-backend` running on `http://localhost:8080` (see backend README)

## Generate the Xcode project

The `.xcodeproj` is generated from `project.yml` using XcodeGen. Regenerate it whenever `project.yml` changes:

```bash
cd KnevoPatient
xcodegen generate
```

This creates `KnevoPatient.xcodeproj`.

## Code signing (per-developer)

Signing is set up **per developer** so teammates never overwrite each other's
team or bundle id. Defaults live in the committed `Signing.xcconfig`; each
machine overrides them in a git-ignored `Signing.local.xcconfig`.

Why you may need your own bundle id: an explicit Apple App ID is globally
unique. `com.knevo.patient` is registered to the maintainer's team, so anyone
**not** on that team must use their own bundle id and their own team.

Setup:

1. Copy the template (in the `KnevoPatient/` folder):

   ```bash
   cp Signing.local.xcconfig.template Signing.local.xcconfig
   ```

2. Edit `Signing.local.xcconfig`:

   ```
   DEVELOPMENT_TEAM = YOUR_TEAM_ID
   KNEVO_BUNDLE_ID  = com.<you>.knevo.patient   # only if not on the owning team
   ```

3. Open `KnevoPatient.xcodeproj` and build. No `xcodegen` rerun is needed — the
   `.xcodeproj` already references `Signing.xcconfig`. `Signing.local.xcconfig`
   is git-ignored, so it stays on your machine.

Verify what got resolved:

```bash
xcodebuild -showBuildSettings -scheme KnevoPatient -configuration Debug \
  | grep -E 'PRODUCT_BUNDLE_IDENTIFIER|DEVELOPMENT_TEAM'
```

**Finding your Team ID** (the 10-character code):

- **Xcode** → Settings (`⌘,`) → **Accounts** → select your Apple ID → select
  your team. The Team ID is shown next to the team name. (Add your Apple ID with
  the `+` button first if it isn't listed.)
- **Paid program:** also at [developer.apple.com](https://developer.apple.com/account) → Membership → "Team ID".
- **Terminal** (after a dev certificate exists): read the `OU` field of your
  signing certificate — that is the Team ID:

  ```bash
  security find-certificate -c "Apple Development: <your-apple-id-email>" -p \
    | openssl x509 -noout -subject
  # Team ID = the OU field. (Do NOT use the code in the CN parentheses — that
  # identifies the certificate, not the team.)
  ```

**Free Apple ID:** a free personal team works for development. The simulator
needs no signing at all; on a physical device the build installs but the profile
expires after 7 days (rebuild from Xcode to refresh), and you must trust the
certificate on the device under Settings → General → VPN & Device Management.

## Run for development

1. Open `KnevoPatient.xcodeproj` in Xcode.
2. Select an iOS 17+ simulator or a connected device.
3. Press `⌘ R` to build and run.

The app connects to `http://localhost:8080` by default. To change the API URL, edit the `API_BASE_URL` entry in `Info.plist`, or set it in the scheme's environment variables.

**Note:** iOS simulators can reach `localhost` on the Mac directly — no special networking setup needed for development.

## Run tests

**From Xcode:** `⌘ U` runs all tests.

**From the command line:**

```bash
xcodebuild test \
  -project KnevoPatient.xcodeproj \
  -scheme KnevoPatient \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

21 tests across 7 files covering ViewModels and network config.

## Lint

```bash
swiftlint lint
```

Rules are configured in `.swiftlint.yml`. Disabled: `trailing_whitespace`, `line_length`. Enabled opt-ins: `empty_count`, `explicit_init`, `first_where`.

## Project structure

```text
Sources/KnevoPatient/
├── Config/         NetworkConfig.swift (base URL)
├── Network/        APIClient.swift, AuthModels.swift, KeychainService.swift
├── Models/         TherapyModels, SessionModels, ProgressModels, MessageModels
├── Services/       ConfigSyncService.swift (stub — not yet active)
├── ViewModels/     AuthViewModel, ActivePlanViewModel, SessionViewModel,
│                   ProgressViewModel, MessagesViewModel
├── Views/
│   ├── Auth/       LoginView, SignupFlowView
│   ├── Session/    SessionFlowView, PreSessionPainView, RunningSessionView,
│   │               ActiveSetView, RestTimerView, PostSessionView, SessionSummaryView,
│   │               PainDuringView
│   └── Components/ KnevoTextField
│   ActivePlanView, SetDetailView, PatientProgressView,
│   SessionsView (placeholder), MessagesView, MainTabView
└── KnevoPatientApp.swift

Tests/KnevoPatientTests/
├── AuthViewModelTests
├── SessionViewModelTests
├── ProgressViewModelTests
├── ActivePlanViewModelTests
├── MessagesViewModelTests
├── NetworkConfigTests
└── ConfigSyncServiceTests
```

## Test accounts

Use the patient account created via the signup flow in the app. After signup, the app displays an 8-character enrollment code — share this with a doctor via the web portal to link the accounts.

## Contributing

1. All new views must have a corresponding ViewModel that does not import SwiftUI — keep UI and logic separated.
2. All network calls go through `APIClient.shared` — do not create ad hoc `URLSession` calls.
3. Tokens are stored in Keychain only — never in `UserDefaults`.
4. Run `swiftlint lint` and `xcodebuild test` before committing.
5. Re-run `xcodegen generate` and commit the updated `.xcodeproj` if you add or remove source files.
6. Commit message format: `feat(M<N>): <one-line summary>` matching the milestone.

## Known issues

See `docs/codebase-ios.md` for the full issue list. Critical items:

- No token refresh — the 15-minute access token expires with no recovery path.
- `SessionsView` (session history tab) is a placeholder — not implemented.
- No logout button accessible from the main app UI.
