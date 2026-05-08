# BuildTrack iOS — App Store Deployment Guide

## Current Status

| Component | Status |
|-----------|--------|
| iOS source code (34 Swift files) | ✅ Complete |
| Expo app source (47 TS/TSX files) | ✅ Complete |
| Supabase backend | ✅ Deployed on VPS |
| FastAPI backend | ✅ Running (port 8000) |
| Nginx reverse proxy | ✅ Configured |
| Redis | ✅ Connected |
| EAS Project | ✅ Created (cd4364ab) |
| Apple credentials | ❌ One-time setup needed |

---

## One-Time Setup (5 minutes)

Run this command in your terminal (needs Apple Developer account):

```bash
cd /root/BuildTrack
npx eas credentials --platform ios
```

Select:
1. **Profile:** `production-ios`
2. **Distribution Certificate:** "Set up a new one" (Expo handles it)
3. **Push Notifications Key:** Required for notifications
4. **Provisioning Profile:** Expo managed

**You'll need:**
- Apple Developer account ($99/year)
- Apple ID and password
- App Store Connect access

---

## After Credentials Are Set

Once credentials are configured, I can run the build with a single command:

```bash
cd /root/BuildTrack && npx eas build --profile production-ios --platform ios --non-interactive
```

This will:
1. Build your iOS app on Expo's macOS workers
2. Produce a signed IPA
3. Upload to App Store Connect

**Build time:** 15-30 minutes

---

## App Store Submission Checklist

- [ ] App icon 1024×1024 ✅ (exists)
- [ ] Splash screen ✅ (exists)
- [ ] Privacy labels configured (camera, location)
- [ ] Export compliance (no encryption)
- [ ] TestFlight internal testing group
- [ ] App review information
- [ ] GDPR/privacy policy URL

---

## Backend URLs (Production)

| Service | URL |
|---------|-----|
| API | `https://buildtrack.cortexbuildpro.com/api` |
| Supabase | `https://buildtrack.cortexbuildpro.com` |
| Health | `http://72.62.132.43/health` |

(SSL pending DNS A record for `buildtrack.cortexbuildpro.com → 72.62.132.43`)

---

## DNS Reminder

Add this record to enable HTTPS:
```
A  buildtrack.cortexbuildpro.com  →  72.62.132.43
```

---

## Quick Commands Reference

```bash
# Check build status
npx eas build:list

# Submit to App Store
npx eas submit --platform ios --profile production

# View credentials
npx eas credentials --platform ios --profile production-ios

# Check expo whoami
npx eas whoami
```
