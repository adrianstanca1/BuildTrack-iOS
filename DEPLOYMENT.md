# BuildTrack-iOS Deployment Guide

## Deployment Workflow

The GitHub Actions workflow at `.github/workflows/deploy-testflight.yml` handles the full pipeline:
- Build unsigned archive
- Export signed IPA with manual provisioning
- Upload to TestFlight via altool

## Pipeline Steps

### 1. Select Xcode 26.3
```bash
sudo xcode-select -s "/Applications/Xcode_26.3.app/Contents/Developer"
```
- Apple now requires iOS 26 SDK for new uploads
- Xcode 26.3 is available on `macos-15` GitHub Actions runner

### 2. Setup Signing
Script: `scripts/setup-signing.sh`

Actions:
1. Create temporary keychain
2. Write distribution certificate + private key from GitHub secrets
3. Extract profile UUID and name from provisioning profile
4. Convert DER cert to PEM, combine into P12
5. Import P12 into keychain
6. Install provisioning profile in `~/Library/MobileDevice/Provisioning Profiles/`
   - Uses UUID-based filename (Xcode preferred)
   - Also installs with profile name as filename
   - Uses `$HOME` with quoted paths (spaces in path)

**Critical:** Profile must be installed with UUID filename AND correct profile name.

### 3. Build Unsigned Archive
```bash
xcodebuild archive \
  -workspace BuildTrack.xcworkspace \
  -scheme BuildTrack \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "build/BuildTrack.xcarchive" \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO
```

**Why unsigned:** SPM packages (like swift-crypto) don't support provisioning profiles. Building unsigned avoids code signing conflicts.

### 4. Export Signed IPA

ExportOptions.plist:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>teamID</key>
  <string>4G3G5MX9BH</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>provisioningProfiles</key>
  <dict>
    <key>ro.stancainvest.buildtrack</key>
    <string>BuildTrack App Store v3</string>
  </dict>
  <key>signingCertificate</key>
  <string>iPhone Distribution: Adrian Stanca (4G3G5MX9BH)</string>
</dict>
</plist>
```

**Critical settings:**
- `method=app-store` (NOT `app-store-connect`)
- `signingStyle=manual`
- Profile NAME (not UUID) in `provisioningProfiles` dictionary

### 5. Upload to TestFlight
```bash
xcrun altool --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"
```

**Prerequisites:**
- AuthKey file at `~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8`
- File must have `chmod 600`
- ASC key must have App Manager role (not just Developer)

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `ASC_KEY_ID` | App Store Connect API Key ID (10 chars) |
| `ASC_ISSUER_ID` | ASC Issuer ID (UUID) |
| `ASC_PRIVATE_KEY` | Full `.p8` private key content |
| `IOS_DISTRIBUTION_CERT` | Base64-encoded `.cer` file |
| `IOS_DISTRIBUTION_KEY` | Base64-encoded `.key` file |
| `IOS_PROVISIONING_PROFILE` | Base64-encoded `.mobileprovision` file |

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `No iOS App Store profiles matching...` | Wrong profile name in ExportOptions.plist | Use exact profile name from ASC |
| `cp: ~/Library/... is not a directory` | Tilde not expanding in script | Use `$HOME` with quotes |
| `cp: Profiles/... is not a directory` | Space in path not quoted | Quote `"$PROV_DIR"` variable |
| `swift-crypto does not support provisioning` | Code signing during archive | Use `CODE_SIGNING_ALLOWED=NO` |
| `SDK version issue. iOS 18.5 SDK` | Old Xcode selected | Use Xcode 26.3 |
| `Invalid large app icon` | Transparent PNG | Remove alpha channel from all icons |
| `The file AuthKey_*.p8 could not be found` | Wrong path format | Create `~/.appstoreconnect/private_keys/` |

## Successful Run Reference
- **Run:** `25616674966`
- **Commit:** `94cff74`
- **Date:** 2026-05-10
- **Duration:** 3m12s
- **Delivery UUID:** `41f5f5d9-c17b-4370-996b-7a38e054767d`
- **IPA Size:** 3,097,887 bytes
- **Xcode:** 26.3 (iOS 26 SDK)
