# BuildTrack iOS — CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-08

### Added
- Initial release of BuildTrack iOS
- SwiftUI + SwiftData architecture
- Supabase backend integration (Auth, Database, Realtime, Storage)
- Project management with budget tracking, progress, and timeline
- Task management with priorities, assignments, and due dates
- Safety incident reporting with severity levels and photo attachments
- Safety inspections with pass/fail/conditional results and checklists
- Team management with roles, certifications, and certification expiry tracking
- Interactive map with project markers and annotations
- Notification inbox with deep-link navigation
- Reports & Analytics dashboard with budget health, status breakdown, and task analytics
- Settings with profile, security (biometrics), notifications, help, and data export
- Dark mode support
- Offline-first with SwiftData local persistence
- Real-time sync via Supabase Realtime
- Push notification support
- Fastlane deployment pipeline
- GitHub Actions CI/CD (SwiftLint, tests, archive)
- Unit tests for ProjectViewModel and TaskViewModel
- UI tests with XCTest

### Technical
- iOS 17.0+ minimum
- Swift 5.9
- SwiftData for local persistence
- Supabase Swift SDK 2.x
- MapKit for project mapping
- LocalAuthentication for Face ID / Touch ID
- UserNotifications for push notifications
- SPM for dependency management

## [Unreleased]

### Planned
- iPad-optimized layout with sidebar navigation
- Apple Watch companion app
- Siri Shortcuts for quick task creation
- Widgets (home screen, lock screen)
- Background task scheduling for sync
- Document scanning with VisionKit
- AR site walkthroughs with RealityKit
- Multi-project Gantt chart view
- Budget forecasting with ML
- Voice memos for site notes
- Apple Sign-In
