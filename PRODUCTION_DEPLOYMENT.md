# BuildTrack iOS — Production Deployment Guide

## Overview

This guide covers the complete production deployment workflow for the BuildTrack iOS app, targeting the production backend at **https://buildtrack.cortexbuildpro.com**.

| Detail | Value |
|--------|-------|
| App Name | BuildTrack |
| Bundle ID | `ro.stancainvest.buildtrack` |
| Min iOS | 17.0 |
| Swift | 5.9 |
| Production Backend | `https://buildtrack.cortexbuildpro.com` |
| Supabase URL | `https://buildtrack.cortexbuildpro.com` |
| Supabase Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (see Config-Production.xcconfig) |
| API Base URL | `https://buildtrack.cortexbuildpro.com/api` |
| CI/CD | GitHub Actions + fastlane |
| Build System | Xcode 15.0+ / xcodebuild |

---

## Quick Start

### 1. Open in Xcode

```bash
cd /root/BuildTrack-iOS

# If you have an .xcworkspace:
open BuildTrack.xcworkspace

# If only an .xcodeproj:
open BuildTrack.xcodeproj
```

Or double-click the project in Finder.

### 2. First-Time Setup (Xcode)

1. **Set Team**: Project navigator → BuildTrack target → Signing & Capabilities → Team → Select your Apple Developer team.

2. **Set Configuration Files**: Project → Info → Configurations:
   - Debug → `Config-Debug.xcconfig` (or None for local dev)
   - Release → `Config-Production.xcconfig`

3. **Verify Bundle ID**: Should read `ro.stancainvest.buildtrack`. Change if needed under Signing & Capabilities.

4. **Add Supabase Package**: File → Add Package Dependencies → `https://github.com/supabase-community/supabase-swift.git` (if not already resolved via SPM).

### 3. Run on Simulator (Development)

```bash
# Using scheme BuildTrack, destination iPhone 15 Pro
xcodebuild \
  -workspace BuildTrack.xcworkspace \
  -scheme BuildTrack \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

---

## Environment Switching

### How It Works

The app uses `#if DEBUG` compile-time directives in `SupabaseManager.swift`:

```swift
enum BuildEnvironment {
    case debug    // → localhost:54321 (development)
    case release  // → buildtrack.cortexbuildpro.com (production)
    
    static var current: BuildEnvironment {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
}
```

| Build Config | Result |
|-------------|--------|
| Debug (⌘R in Xcode) | Points to local Supabase or dev server |
| Release / Archive | Points to `buildtrack.cortexbuildpro.com` |

### Override for Debug Production Testing

To test production backend in the simulator:

1. In Xcode: Product → Scheme → Edit Scheme → Run → Info → Build Configuration → **Release**
2. Build & run. The app connects to production.

### Fallback URLs

If `Info.plist` values are missing, hardcoded fallbacks are used:

| Key | Debug Fallback | Release Fallback |
|-----|---------------|-----------------|
| `SUPABASE_URL` | `http://localhost:54321` | `https://buildtrack.cortexbuildpro.com` |
| `SUPABASE_ANON_KEY` | Supabase demo key | Production anon key |
| `API_BASE_URL` | `http://localhost:54321/api` | `https://buildtrack.cortexbuildpro.com/api` |

---

## Code Signing

### Automatic Signing (Recommended for Individuals)

1. Xcode → BuildTrack target → Signing & Capabilities
2. Check **"Automatically manage signing"**
3. Select your Team
4. Xcode handles provisioning profiles automatically

### Manual Signing via fastlane match (Recommended for Teams)

```bash
# Install fastlane if needed
gem install fastlane

# Set up match (one-time)
fastlane match init

# Create development certs & profiles
fastlane match development

# Create App Store certs & profiles
fastlane match appstore
```

Set environment variables:

```bash
export APP_IDENTIFIER="ro.stancainvest.buildtrack"
export TEAM_ID="YOUR_APPLE_TEAM_ID"
export MATCH_PASSWORD="your-match-encryption-password"
export MATCH_KEYCHAIN_PASSWORD="keychain-password-for-ci"
```

---

## Building for TestFlight

### Option A: Via fastlane (Recommended)

```bash
cd /root/BuildTrack-iOS

# Edit fastlane/Appfile first:
#   team_id("YOUR_TEAM_ID")
#   app_identifier("ro.stancainvest.buildtrack")

# Build and upload to TestFlight
fastlane beta groups:"Internal Testers"
```

What happens:
1. `match` fetches App Store signing assets
2. Build number auto-increments
3. `gym` builds the .ipa in Release configuration
4. `pilot` uploads to TestFlight
5. Distributes to specified tester groups
6. Posts changelog to Slack (if `SLACK_WEBHOOK_URL` is set)

### Option B: Via build script + Transporter

```bash
cd /root/BuildTrack-iOS

# Validate config and build IPA
./scripts/build-production.sh --ipa

# Upload using Transporter app (macOS GUI)
# Or via xcrun:
xcrun altool --upload-app \
  -f build/BuildTrack.ipa \
  -t ios \
  -u "your-apple-id@example.com" \
  -p "@keychain:Application Loader:your-apple-id@example.com"
```

### Option C: Via Xcode Archive

1. Product → Scheme → Edit Scheme → Archive → Build Configuration → **Release**
2. Product → Archive
3. In Organiser window → Distribute App → App Store Connect → Upload

---

## Building for App Store Submission

### Full Release via fastlane

```bash
cd /root/BuildTrack-iOS

# Build, upload to App Store Connect, submit for review
fastlane release submit_for_review:true automatic_release:false
```

This lane:
1. Fetches signing assets (match)
2. Bumps build number
3. Builds Release archive
4. Uploads to App Store Connect (deliver)
5. Submits for App Store Review
6. Tags the release in git
7. Creates a GitHub Release with changelog

### Manual Submission

```bash
cd /root/BuildTrack-iOS

# Build the IPA
./scripts/build-production.sh --ipa

# Now in Xcode Organiser or Transporter:
# Upload build/BuildTrack.ipa to App Store Connect
# Then in App Store Connect web:
#   → TestFlight → select build → submit for review
```

### Pre-Submission Checklist

- [ ] App icon (1024×1024) added to `Assets.xcassets`
- [ ] Launch screen configured
- [ ] Privacy manifest included (`PrivacyInfo.xcprivacy`)
- [ ] App Store screenshots captured (fastlane screenshots)
- [ ] Metadata filled in App Store Connect (description, keywords, support URL)
- [ ] Export compliance confirmed (no encryption or ERN submitted)
- [ ] All tests passing: `./scripts/build-production.sh --test`
- [ ] Production backend is live and reachable

---

## CI/CD Pipeline

GitHub Actions workflow: `.github/workflows/ios-ci.yml`

The pipeline runs:
1. **On PR**: Build + unit tests + UI tests on iPhone 15 + iPhone 15 Pro
2. **On push to main**: Same tests + upload to TestFlight (if secrets configured)

Required GitHub Secrets:

| Secret | Purpose |
|--------|---------|
| `APPLE_TEAM_ID` | Apple Developer team |
| `APP_STORE_CONNECT_API_KEY` | App Store Connect API key (JSON) |
| `MATCH_PASSWORD` | fastlane match encryption password |
| `MATCH_GIT_URL` | Git repo for match certificates |

---

## Production URLs & Keys Summary

| Key | Value |
|-----|-------|
| **Supabase URL** | `https://buildtrack.cortexbuildpro.com` |
| **Supabase Anon Key** | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1aWxkdHJhY2siLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc0NjcxMzYwMCwiZXhwIjoyMDYyMjg5NjAwfQ.demo-key` |
| **API Base URL** | `https://buildtrack.cortexbuildpro.com/api` |
| **Bundle Identifier** | `ro.stancainvest.buildtrack` |

> ⚠️ **Important**: Update `SUPABASE_ANON_KEY` with the real production anon key from your Supabase project dashboard (Settings → API). The key in the config file is a placeholder. **Never commit real secrets to version control.**

---

## Project Structure (Production-Relevant)

```
BuildTrack-iOS/
├── BuildTrack/
│   ├── Config-Production.xcconfig    # Production build settings
│   └── Info.plist                    # App metadata + backend URLs
├── Infrastructure/
│   └── Supabase/
│       └── SupabaseManager.swift     # Client init + env switching
├── fastlane/
│   ├── Fastfile                      # beta / release / screenshots lanes
│   └── Appfile                       # Team ID + bundle identifier
├── scripts/
│   └── build-production.sh           # CLI build script
├── eas.json                          # EAS Build for Expo alternative
├── Package.swift                     # SPM dependencies
├── .github/workflows/
│   └── ios-ci.yml                    # CI/CD pipeline
└── PRODUCTION_DEPLOYMENT.md          # This file
```

---

## Troubleshooting

### "No such module 'Supabase'"

```bash
# Reset SPM cache
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData

# In Xcode: File → Packages → Reset Package Caches
# Then: File → Packages → Resolve Package Versions
```

### "Signing requires a development team"

1. Xcode → BuildTrack target → Signing & Capabilities
2. Select a team from the dropdown
3. If no team appears, add your Apple ID: Xcode → Settings → Accounts → +

### "Provisioning profile doesn't include the currently selected device"

- Register the device in Apple Developer portal: Certificates, Identifiers & Profiles → Devices
- Or enable "Automatically manage signing" in Xcode

### Archive build hangs

```bash
# Kill and clean
killall Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### "Supabase URL and Anon Key must be configured"

The app fell through to the `fatalError`. This means:
- `Info.plist` doesn't have `SUPABASE_URL` / `SUPABASE_ANON_KEY`
- And the `#if DEBUG` / `#else` fallback didn't apply (misconfigured build settings)

Fix: Ensure `Config-Production.xcconfig` is assigned to the Release configuration in Xcode project settings.

---

## Fastlane Commands Quick Reference

```bash
fastlane test                    # Run full test suite
fastlane beta                    # Build + upload to TestFlight
fastlane release                 # Build + submit to App Store
fastlane screenshots             # Capture App Store screenshots
fastlane refresh_dsyms           # Download dSYMs from Apple
fastlane nuke_profiles           # Reset all provisioning profiles
```

---

*Last updated: 2026-05-08 — BuildTrack iOS Production Deployment*
