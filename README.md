# BuildTrack for iOS

Native iOS app built with **SwiftUI**, **SwiftData**, and **Supabase**.

## Quick Start

```bash
# Clone and setup
cd BuildTrack-iOS
make setup          # Install deps + generate Xcode project
open BuildTrack.xcworkspace
```

In Xcode: **Product → Build (⌘B)** or **⌘R** to run on simulator.

## Architecture

```
BuildTrack-iOS/
├── App/
│   ├── BuildTrackApp.swift          # @main entry point, SwiftData container
│   └── ContentView.swift            # 8-tab TabView shell
├── Domain/
│   └── Models/Models.swift          # 5 SwiftData models + enums
├── DesignSystem/
│   ├── Components/Components.swift  # 10 reusable UI components
│   └── Theme/Colors.swift         # Color palette + status/priority helpers
├── Features/
│   ├── Auth/AuthView.swift         # Login & Register with validation
│   ├── Dashboard/DashboardView.swift  # Stats, quick actions, Reports card
│   ├── Projects/ProjectsListView.swift   # Search, filter, sort, CRUD
│   ├── Projects/ProjectDetailView.swift  # Detail with tasks, incidents
│   ├── Projects/ProjectFormView.swift    # Create/edit with Mode enum
│   ├── Tasks/TasksListView.swift    # Filter chips, grouped tasks
│   ├── Tasks/TaskFormView.swift     # Worker picker, project picker
│   ├── Map/MapView.swift           # MapKit with project markers
│   ├── Safety/SafetyView.swift     # Incidents + inspections tabs
│   ├── Team/TeamView.swift         # Workers, roles, certifications
│   ├── Reports/ReportsView.swift   # Budget health, analytics
│   ├── Notifications/NotificationInboxView.swift    # Grouped, swipe-to-delete
│   ├── Notifications/NotificationSettingsView.swift   # Toggles, quiet hours
│   └── Settings/SettingsView.swift # Profile, security, help, export
├── Infrastructure/
│   ├── Supabase/
│   │   ├── AuthManager.swift       # Auth state, session, UserInfo
│   │   ├── SupabaseManager.swift   # Client singleton, env switching
│   │   ├── RealtimeService.swift   # Debounced sync (Insert/Update/Delete)
│   │   └── Repositories.swift      # ProjectRepository, TaskRepository
│   ├── SwiftData/
│   │   └── SwiftDataStack.swift    # Shared container + preview factory
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift     # Biometrics, validation
│   │   ├── ProjectViewModel.swift  # Loading states, optimistic updates
│   │   ├── TaskViewModel.swift     # Grouping, completion rate
│   │   ├── SafetyViewModel.swift   # Incident/Inspection CRUD
│   │   ├── TeamViewModel.swift     # Worker search, cert expiry
│   │   └── NotificationViewModel.swift # Grouped notifications
│   └── Services/
│       ├── DeepLinkRouter.swift    # buildtrack:// navigation
│       └── PushNotificationService.swift # UNUserNotificationCenter
├── Tests/
│   ├── Unit/ProjectViewModelTests.swift
│   ├── Unit/TaskViewModelTests.swift
│   └── UI/BuildTrackUITests.swift
└── Package.swift                    # SPM manifest (supabase-swift 2.x)
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI (iOS 17.0+) |
| Local Data | SwiftData |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| Maps | MapKit |
| Auth | Supabase Auth + LocalAuthentication (Face ID / Touch ID) |
| Push | UserNotifications |
| CI/CD | GitHub Actions + Fastlane |
| Lint | SwiftLint |

## Commands

```bash
make build         # Build for simulator
make test          # Run tests
make lint          # Run SwiftLint
make archive       # Create release archive
make beta          # Upload to TestFlight
make release       # Submit to App Store
make clean         # Clean build artifacts
make verify        # Run build verification
make help          # Show all commands
```

## Configuration

### Development
`BuildTrack/Config-Development.xcconfig` — localhost Supabase, debug flags

### Production
`BuildTrack/Config-Production.xcconfig` — production backend, release optimization

Set as project-level config in Xcode: **Project → Info → Configurations**

## Backend Setup

The app expects these Supabase tables:
- `projects` — id, name, description, status, budget, progress, dates, location, client
- `tasks` — id, title, description, priority, status, due_date, assigned_to, project_id
- `incidents` — id, title, description, severity, status, reported_by, location, date
- `inspections` — id, title, inspector, result, date, notes, checklist_json
- `workers` — managed locally via SwiftData (optional: sync to Supabase)

Enable RLS policies and Realtime for each table.

## Deployment

```bash
# TestFlight
bundle exec fastlane beta

# App Store
bundle exec fastlane release
```

See [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md) for full details.

## License

© 2026 Stancă Invest. All rights reserved.
