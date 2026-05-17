# CLAUDE.md — BuildTrack-iOS

Native iOS counterpart to the `BuildTrack/` Expo app. Manages construction projects (tasks, safety incidents, inspections, team, drawings, RFIs, budgets, punch items, submittals, permits, invoices, daily reports) with offline-first SwiftData persistence that syncs to Supabase (Auth, Database, Storage). The app ships to TestFlight via a GitHub Actions `Deploy to TestFlight` workflow (manual trigger only) and targets the production backend at `https://buildtrack.cortexbuildpro.com`. Bundle ID is `ro.stancainvest.buildtrack` — tied to the ASC record, do not change it.

## Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17.0+ declared in Package.swift; Config-Production.xcconfig overrides to 18.0 — see Known issues) |
| Local persistence | SwiftData (19-model schema, `SwiftDataStack.shared`) |
| Auth | Supabase Auth via `supabase-swift` 2.26.0; biometrics via LocalAuthentication |
| Backend | Supabase (PostgreSQL, Realtime, Storage) at `buildtrack.cortexbuildpro.com` |
| Networking | `supabase-swift` 2.26.0 (SPM, pinned in `BuildTrack.xcworkspace/xcshareddata/swiftpm/Package.resolved`) |
| Maps | MapKit |
| Push | UserNotifications framework |
| Config | `.xcconfig` per build configuration (Development / Production) |
| Lint | SwiftLint (`.swiftlint.yml`) |
| CI | GitHub Actions (`ios-ci.yml` SwiftLint on push, `deploy-testflight.yml` manual) |
| Release | Fastlane `beta` / `release` lanes; manual signing in GHA; ASC upload via `xcrun altool` |

No Combine usage found in the codebase. Observable state uses `@Observable` (AuthManager) and `ObservableObject` (ViewModels). No Redux/TCA.

## Architecture

```
BuildTrack-iOS/
├── App/
│   ├── BuildTrackApp.swift       # @main; wires AuthManager + SwiftDataStack.shared.container
│   └── ContentView.swift         # Root TabView (8 tabs), app-lock, deep-link dispatch
├── Domain/
│   └── Models/
│       ├── Models.swift          # 19 @Model classes (Project, TaskItem, Incident,
│       │                         #   Inspection, Worker, PunchItem, RFI, Drawing,
│       │                         #   Budget, BudgetCategory, Material, Equipment,
│       │                         #   Meeting, TimesheetEntry, Permit, Defect,
│       │                         #   DailyReport, Invoice, Submittal)
│       ├── AdminModels.swift     # UserRole, AppUser, SubscriptionTier, AdminDashboardStats
│       └── Enums+Labels.swift    # Display-label extensions for all enums
├── DesignSystem/
│   ├── Components/Components.swift   # 10 reusable SwiftUI components
│   └── Theme/
│       ├── Colors.swift              # Colour palette, status/priority helpers
│       └── DesignTokens.swift        # Typography, spacing, radius, shadow tokens
├── Features/                         # One sub-folder per domain, ~40 Swift files
│   ├── Auth/                         # Login + Register, biometric gate
│   ├── Dashboard/                    # Stats cards, quick actions
│   ├── Projects/                     # List, detail, form (create/edit)
│   ├── Tasks/                        # Filtered list, form
│   ├── Safety/                       # Incidents + inspections tabs, detail, form
│   ├── Team/                         # Workers, roles, cert-expiry alerts
│   ├── Map/                          # MapKit project markers
│   ├── Reports/                      # Budget health, analytics
│   ├── Notifications/                # Inbox, settings, detail
│   ├── Settings/                     # Profile, security, export
│   ├── Admin/                        # Admin dashboard, user management, billing
│   ├── Drawings/, RFIs/, PunchItems/
│   ├── Submittals/, Invoices/, Budget/
│   ├── Materials/, Equipment/, Permits/
│   ├── Meetings/, DailyReports/, Timesheets/
│   └── Onboarding/
└── Infrastructure/
    ├── Supabase/
    │   ├── SupabaseManager.swift     # Singleton client; reads SUPABASE_URL +
    │   │                             #   SUPABASE_ANON_KEY from Info.plist injected
    │   │                             #   via .xcconfig; falls back to hardcoded defaults
    │   ├── AuthManager.swift         # @Observable; session restore, sign-in/out, UserInfo
    │   ├── RealtimeService.swift     # Polling stub (5 s timer) — NOT a WebSocket channel
    │   ├── Repositories.swift        # ProjectRepository, TaskRepository (struct + closures)
    │   └── *Repository.swift         # Per-entity repos (Incident, Worker, Notification, …)
    ├── SwiftData/
    │   └── SwiftDataStack.swift      # @MainActor singleton; 19-model schema;
    │                                 #   previewContainer() for Previews
    ├── ViewModels/
    │   └── *ViewModel.swift          # @MainActor ObservableObject; LoadingState<T> enum
    └── Services/
        ├── DeepLinkRouter.swift      # buildtrack:// URL scheme, 15 Screen cases
        ├── PushNotificationService.swift  # UNUserNotificationCenter delegate
        ├── StorageService.swift      # Supabase Storage — explicitly a stub, no progress/cache
        ├── BiometricAuthService.swift
        └── Logger.swift              # OSLog subsystem wrappers
```

Key conventions:
- ViewModels are `@MainActor` `ObservableObject`; use `LoadingState<T>` for async state.
- Repositories are value types (`struct`) with injectable closure fields — not class singletons.
- `SwiftDataStack.shared` is the only model-container entry point; never call `ModelContainer(for:)` at call-site in production code (only in tests/previews).

## Building locally

Requirements: macOS 14+, Xcode 26.3 (iOS 26 SDK — required for TestFlight builds; Xcode 15/16 may work for simulator dev builds but will fail CI). Ruby + Bundler for Fastlane.

```bash
cd /root/BuildTrack-iOS   # always cd first; don't run from /root
make setup                # installs fastlane + xcbeautify, generates .xcodeproj
open BuildTrack.xcworkspace
# Build: Cmd-B / Cmd-R on iPhone 15 simulator
```

Simulator build only:
```bash
make build    # xcodebuild -workspace BuildTrack.xcworkspace -scheme BuildTrack
              #   -destination 'platform=iOS Simulator,name=iPhone 15'
make test     # same + -enableCodeCoverage YES
make lint     # swiftlint lint --strict --config .swiftlint.yml
```

Signing for device/TestFlight builds: run on macOS with a real Apple Developer account. The CI path (manual signing via P12 secrets) is the canonical distribution route — do not attempt device signing from this Linux box.

Development config: `BuildTrack/Config-Development.xcconfig` (localhost Supabase on `:54321`).
Production config: `BuildTrack/Config-Production.xcconfig` (injected into Info.plist at build time).

## Linux-side dev

`Package.swift` declares a `BuildTrack` library target so SPM resolution works on Linux:

```bash
cd /root/BuildTrack-iOS
swift package resolve   # resolves supabase-swift 2.26.0 into .build/checkouts/
swift build             # compiles domain + infrastructure layers (~80% of non-UI code)
swift test              # runs unit tests that have no UIKit/SwiftUI dependency
```

What works: type-checking `Domain/`, `Infrastructure/`, compile-time Swift 6 diagnostics.
What requires macOS: anything importing `SwiftUI`, `SwiftData`, `UIKit`, `MapKit`, `UserNotifications`, `LocalAuthentication`. All `Features/` views are macOS-only.

The `swift-syntax-check-linux` skill (at `~/.claude/skills/`) runs `swift build` on Linux and catches ~80% of pre-push regressions — run it before opening a PR.

## Tests

Scheme: `BuildTrack`; test targets under `Tests/`:

| File | Coverage |
|---|---|
| `Tests/Unit/ProjectViewModelTests.swift` | LoadingState transitions, filter, sort, stats |
| `Tests/Unit/TaskViewModelTests.swift` | Completion rate, grouping, priority sort |
| `Tests/Unit/DeepLinkRouterTests.swift` | URL parsing for all 15 Screen cases |
| `Tests/UI/BuildTrackUITests.swift` | XCTest UI smoke (launch, tab navigation) |

Run:
```bash
make test           # iPhone 15 simulator, coverage enabled
make test-all       # fastlane test lane — iPhone 15 + 15 Pro matrix
```

Coverage report lands in `fastlane/test_output/coverage/` (Cobertura + HTML via Slather). No minimum coverage threshold is enforced in CI.

## CI

### `ios-ci.yml` — on push to `main`/`develop` and PRs to `main`

| Job | Runner | What it does |
|---|---|---|
| `lint` | `macos-14` | `swiftlint lint --strict` — fails on any violation |
| `summary` | `ubuntu-latest` | Posts job-result table to step summary |

Note: there is no build or test job in `ios-ci.yml` — only lint runs automatically. Tests must be triggered manually or via `deploy-testflight.yml`.

### `deploy-testflight.yml` — `workflow_dispatch` only

Runner: `macos-15`. Timeout: 45 minutes.

Steps: checkout → select Xcode 26.3 → restore SPM cache → resolve deps → setup signing → bump build number (git rev-list count) → archive (CODE_SIGNING_ALLOWED=NO) → export signed IPA → upload to TestFlight via `xcrun altool`.

Required GitHub secrets:

| Secret | Purpose |
|---|---|
| `IOS_DISTRIBUTION_CERT` | Distribution certificate (base64-encoded .cer) |
| `IOS_DISTRIBUTION_KEY` | Corresponding private key (base64-encoded .p12) |
| `IOS_PROVISIONING_PROFILE` | App Store provisioning profile (base64) |
| `ASC_KEY_ID` | ASC API key ID (`Y8D8LW92D2`) |
| `ASC_ISSUER_ID` | ASC issuer ID (`S7PSXPJ963`) |
| `ASC_PRIVATE_KEY` | ASC private key content (`.p8` file text) |

Optional:
| Secret | Purpose |
|---|---|
| `SLACK_WEBHOOK_URL` | Fastlane `notify_slack_build` posts to `#builds` (skipped if absent) |

## Signing + release

Signing posture: **manual** in both the GHA workflow and `ExportOptions.plist`.
- Team ID: `4G3G5MX9BH`
- Bundle ID: `ro.stancainvest.buildtrack`
- Profile name expected by the workflow: `"BuildTrack App Store v4"` (set via `$PROFILE_NAME` env or fallback default — `scripts/setup-signing.sh` exports this after importing the provisioning profile)
- The provisioning profile is installed from `IOS_PROVISIONING_PROFILE` secret by `scripts/setup-signing.sh`; the signing identity is discovered dynamically from the temporary keychain

ASC API key (for `xcrun altool` upload):
- Key ID: `Y8D8LW92D2`, Issuer: `S7PSXPJ963`
- Stored in GHA secret `ASC_PRIVATE_KEY`; written to `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` at runtime, `chmod 600`, deleted in the cleanup step

Fastlane `beta` / `release` lanes use `match` (reads from a private certs repo) — the canonical distribution path for TestFlight is now the raw `xcodebuild` + `xcrun altool` path in `deploy-testflight.yml`, not Fastlane, since the GHA workflow bypasses `match`.

Build number is set to `git rev-list --count HEAD` at archive time.

## Known issues / debt

1. **`actions/checkout@v6` and `actions/upload-artifact@v7` do not exist.** The deploy workflow (`deploy-testflight.yml` lines 29, 149) uses non-existent action versions (max published are `@v4`). The workflow will fail at checkout. Fix: pin both to `@v4`.

2. **`xcrun altool` is deprecated.** Apple deprecated `altool` for uploading to App Store Connect in Xcode 14 (removed from Xcode 16+). The upload step at line 141 of `deploy-testflight.yml` will fail on `macos-15` / Xcode 26.3. Replace with `xcrun notarytool` or App Store Connect API directly.

3. **Signing posture mismatch.** `BuildTrack/Config-Production.xcconfig` sets `CODE_SIGN_STYLE = Automatic`, but `deploy-testflight.yml` exports with `signingStyle = manual`. Xcode will use whichever wins at build time; on CI with `CODE_SIGNING_ALLOWED=NO` for the archive step this is harmless, but the xcconfig should be set to `Manual` to avoid confusion.

4. **Deployment target conflict.** `Package.swift` declares `.iOS(.v17)` (minimum iOS 17.0); `Config-Production.xcconfig` overrides `IPHONEOS_DEPLOYMENT_TARGET = 18.0`; the `CHANGELOG.md` and `build-production.sh` reference "Xcode 15.0+" and "iOS 17.0+". The xcconfig value wins for Xcode builds. Decide on one target and update all three sources.

5. **Swift version conflict.** `Package.swift` is `swift-tools-version: 5.9`. `Config-Production.xcconfig` sets `SWIFT_VERSION = 6.0`. Fastlane `gym` passes `xcargs: "SWIFT_VERSION=5.9"`. The result at build time depends on which wins; Swift 6 strict concurrency is not fully addressed (see item 6).

6. **`@unchecked Sendable` on two classes.** `RealtimeService` (`Infrastructure/Supabase/RealtimeService.swift:5`) and `PushNotificationService` (`Infrastructure/Services/PushNotificationService.swift:8`) both use `@unchecked Sendable` as a suppression rather than a real concurrency guarantee. If Swift 6 mode is enforced these should be audited for data races.

7. **`RealtimeService` is a polling stub, not Supabase Realtime.** `startListening(for:onChange:)` fires a 5-second `Timer` — it does not open a WebSocket channel. The CHANGELOG claims "Real-time sync via Supabase Realtime"; that is aspirational. True Realtime requires migrating to `supabase-swift`'s `RealtimeChannelV2` API.

8. **`StorageService` is an explicit stub.** `Infrastructure/Services/StorageService.swift` notes in its own comment that it has no progress tracking, compression, or caching.

9. **Two open TODO stubs that silently no-op:**
   - `Features/Safety/SafetyDetailView.swift:108` — `deleteIncident()` calls `dismiss()` without removing from the model context. Deleting an incident from the UI does nothing persistently.
   - `Features/Notifications/NotificationDetailView.swift:66` — "Mark as read" toggles local state only; no repository call is made.

10. **`fastlane refresh_dsyms` references `BuildTrack/GoogleService-Info.plist`** (Fastfile line 285) for Crashlytics symbol upload. No Firebase/Crashlytics integration exists in the codebase — the `plist` path is a Fastfile placeholder. The lane will fail if invoked.

11. **`DesignTokens.swift` was recently added to the Xcode target** (session 2026-05-17 fixed a missing-from-target bug). If you regenerate the `.xcodeproj` via `make regenerate` / `ruby scripts/generate-xcodeproj.rb`, verify `DesignTokens.swift` remains in the `BuildTrack` target's Sources build phase — the generator has been known to miss new files under `DesignSystem/`.

## Don't do

- **Do not change the bundle ID** (`ro.stancainvest.buildtrack`). It is tied to the App Store Connect record and the provisioning profile — renaming it orphans the ASC record and requires a new app submission.
- **Do not edit `BuildTrack.xcodeproj/project.pbxproj` by hand.** File references use random GUIDs; manual edits break the project silently. Use Xcode's file navigator or `ruby scripts/generate-xcodeproj.rb`.
- **Do not run `make setup` / `gem install` / `bundle install` from `/root`.** Always `cd /root/BuildTrack-iOS` first.
- **Do not commit `BuildTrack/Config-Production.xcconfig` with real secrets** — the `SUPABASE_ANON_KEY` is a publishable key (not a service-role key) but the comment in the file warns against this pattern. For secrets rotation, update the file and re-run the CI workflow.
- **Do not add SwiftUI/UIKit imports to files under `Domain/` or the non-view parts of `Infrastructure/`.** Those layers compile on Linux via `swift build`; platform imports break Linux CI.
- **Do not call `SwiftDataStack.shared` from a background thread.** It is `@MainActor` — all model-context access must be on the main actor.
- **Do not use `xcrun altool`** going forward — it is deprecated and will be removed; plan the migration to the App Store Connect API before it starts failing on the CI runner image.

## Cross-references

- Expo sibling: `/root/BuildTrack/CLAUDE.md`
- Shared backend: Supabase containers `supabase_*_BuildTrack` (workspace overview: `/root/CLAUDE.md`)
- iOS skill: `~/.claude/skills/ios-ship-testflight/`
- Linux Swift check: `~/.claude/skills/swift-syntax-check-linux/`
