#!/usr/bin/env bash
# BuildTrack iOS — Build Verification Script
# Validates project structure, dependencies, and compilation readiness
# Usage: ./scripts/verify-build.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; ((ERRORS++)); }
warn() { echo -e "${YELLOW}⚠${NC} $1"; ((WARNINGS++)); }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo "═══════════════════════════════════════════════════════════"
echo "  BuildTrack iOS — Build Verification"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ── 1. Project Structure ──────────────────────────────────
info "Checking project structure..."

required_dirs=(
    "App"
    "Domain/Models"
    "DesignSystem/Components"
    "DesignSystem/Theme"
    "Features/Auth"
    "Features/Dashboard"
    "Features/Map"
    "Features/Notifications"
    "Features/Projects"
    "Features/Reports"
    "Features/Safety"
    "Features/Settings"
    "Features/Tasks"
    "Features/Team"
    "Infrastructure/Supabase"
    "Infrastructure/SwiftData"
    "Infrastructure/ViewModels"
    "Infrastructure/Services"
    "Tests/Unit"
    "Tests/UI"
    "BuildTrack"
    "scripts"
    "fastlane"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        pass "Directory: $dir"
    else
        fail "Missing directory: $dir"
    fi
done

# ── 2. Core Files ─────────────────────────────────────────
info "Checking core files..."

required_files=(
    "Package.swift"
    "BuildTrack/Info.plist"
    "BuildTrack/Config-Production.xcconfig"
    "BuildTrack/Config-Development.xcconfig"
    "App/BuildTrackApp.swift"
    "App/ContentView.swift"
    "Domain/Models/Models.swift"
    "DesignSystem/Components/Components.swift"
    "DesignSystem/Theme/Colors.swift"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        pass "File: $file"
    else
        fail "Missing file: $file"
    fi
done

# ── 3. Swift Source Files ─────────────────────────────────
info "Checking Swift source files..."

swift_count=$(find . -name "*.swift" -not -path "./BuildTrack.xcodeproj/*" -not -path "./BuildTrack.xcworkspace/*" -not -path "./scripts/*" -not -path "./fastlane/*" | wc -l)
if (( swift_count >= 30 )); then
    pass "Found $swift_count Swift files"
else
    fail "Only $swift_count Swift files found (expected ≥30)"
fi

# ── 4. SwiftUI Views ──────────────────────────────────────
info "Checking SwiftUI views..."

view_count=$(grep -r "struct.*: View {" --include="*.swift" . | grep -v "BuildTrack.xcodeproj" | wc -l)
if (( view_count >= 20 )); then
    pass "Found $view_count SwiftUI views"
else
    fail "Only $view_count SwiftUI views found (expected ≥20)"
fi

# ── 5. Xcode Project ──────────────────────────────────────
info "Checking Xcode project..."

if [[ -f "BuildTrack.xcodeproj/project.pbxproj" ]]; then
    pass "BuildTrack.xcodeproj exists"
    build_file_count=$(grep -c "PBXBuildFile" BuildTrack.xcodeproj/project.pbxproj)
    if (( build_file_count >= 30 )); then
        pass "Xcode project has $build_file_count build files"
    else
        warn "Only $build_file_count build files in Xcode project"
    fi
else
    fail "BuildTrack.xcodeproj missing — run: ruby scripts/generate-xcodeproj.rb"
fi

if [[ -f "BuildTrack.xcworkspace/contents.xcworkspacedata" ]]; then
    pass "BuildTrack.xcworkspace exists"
else
    fail "BuildTrack.xcworkspace missing"
fi

# ── 6. Package.swift ──────────────────────────────────────
info "Checking Package.swift..."

if grep -q "supabase-community/supabase-swift" Package.swift; then
    pass "Supabase dependency declared"
else
    fail "Supabase dependency missing from Package.swift"
fi

if grep -q 'path: "."' Package.swift; then
    pass "Package.swift path is correct"
else
    fail "Package.swift path may be incorrect"
fi

# ── 7. Imports ────────────────────────────────────────────
info "Checking imports..."

# Check for files using SwiftUI symbols without importing SwiftUI
swiftui_files=$(grep -rl "struct.*: View {" --include="*.swift" . | grep -v "BuildTrack.xcodeproj" | grep -v "Tests/")
missing_swiftui=0
for f in $swiftui_files; do
    if ! grep -q "import SwiftUI" "$f"; then
        fail "$f defines a View but doesn't import SwiftUI"
        ((missing_swiftui++))
    fi
done
if (( missing_swiftui == 0 )); then
    pass "All View files import SwiftUI"
fi

# Check for files using SwiftData without importing
swifdata_files=$(grep -rl "@Query\|@Model\|ModelContext\|ModelContainer\|FetchDescriptor" --include="*.swift" . | grep -v "BuildTrack.xcodeproj")
missing_swifdata=0
for f in $swifdata_files; do
    if ! grep -q "import SwiftData" "$f"; then
        fail "$f uses SwiftData but doesn't import it"
        ((missing_swifdata++))
    fi
done
if (( missing_swifdata == 0 )); then
    pass "All SwiftData files import SwiftData"
fi

# ── 8. Duplicate Type Definitions ─────────────────────────
info "Checking for duplicate type definitions..."

duplicates=$(grep -rh "struct.*: View {" --include="*.swift" . | grep -v "BuildTrack.xcodeproj" | sed 's/.*struct \([A-Za-z0-9]*\): View.*/\1/' | sort | uniq -d)
if [[ -z "$duplicates" ]]; then
    pass "No duplicate View types found"
else
    for dup in $duplicates; do
        fail "Duplicate View type: $dup"
    done
fi

# ── 9. Undefined References ───────────────────────────────
info "Checking for common undefined references..."

# These should be defined somewhere
common_types=(
    "BuildTrackColors"
    "AuthManager"
    "SupabaseManager"
    "RealtimeService"
    "ProjectRepository"
    "TaskRepository"
    "SwiftDataStack"
    "PushNotificationService"
    "DeepLinkRouter"
    "UserInfo"
)

for type in "${common_types[@]}"; do
    if grep -rq "struct $type\|class $type\|enum $type\|final class $type" --include="*.swift" .; then
        pass "Type defined: $type"
    else
        fail "Type not found: $type"
    fi
done

# ── 10. Asset Catalogs ────────────────────────────────────
info "Checking asset catalogs..."

if [[ -d "Assets.xcassets" ]]; then
    pass "Assets.xcassets exists"
    if [[ -d "Assets.xcassets/AppIcon.appiconset" ]]; then
        pass "AppIcon.appiconset exists"
    else
        warn "AppIcon.appiconset missing"
    fi
    if [[ -d "Assets.xcassets/AccentColor.colorset" ]]; then
        pass "AccentColor.colorset exists"
    else
        warn "AccentColor.colorset missing"
    fi
else
    fail "Assets.xcassets missing"
fi

# ── 11. Info.plist ────────────────────────────────────────
info "Checking Info.plist..."

if grep -q "CFBundleIdentifier" BuildTrack/Info.plist; then
    pass "Info.plist has bundle identifier"
else
    fail "Info.plist missing bundle identifier"
fi

if grep -q "SUPABASE_URL" BuildTrack/Info.plist; then
    pass "Info.plist references SUPABASE_URL"
else
    warn "Info.plist missing SUPABASE_URL reference"
fi

# ── 12. Fastlane ──────────────────────────────────────────
info "Checking fastlane configuration..."

if [[ -f "fastlane/Fastfile" ]]; then
    pass "Fastfile exists"
    if grep -q "BuildTrack.xcworkspace" fastlane/Fastfile; then
        pass "Fastfile references workspace"
    else
        warn "Fastfile doesn't reference BuildTrack.xcworkspace"
    fi
else
    warn "Fastfile missing"
fi

# ── 13. CI/CD ─────────────────────────────────────────────
info "Checking CI/CD configuration..."

if [[ -f ".github/workflows/ios-ci.yml" ]]; then
    pass "GitHub Actions workflow exists"
else
    warn "GitHub Actions workflow missing"
fi

# ── 14. Tests ─────────────────────────────────────────────
info "Checking tests..."

unit_tests=$(find Tests/Unit -name "*.swift" 2>/dev/null | wc -l)
ui_tests=$(find Tests/UI -name "*.swift" 2>/dev/null | wc -l)

if (( unit_tests > 0 )); then
    pass "$unit_tests unit test files found"
else
    warn "No unit test files found"
fi

if (( ui_tests > 0 )); then
    pass "$ui_tests UI test files found"
else
    warn "No UI test files found"
fi

# ── Summary ───────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Verification Complete"
echo "═══════════════════════════════════════════════════════════"

if (( ERRORS == 0 && WARNINGS == 0 )); then
    echo -e "${GREEN}✓ ALL CHECKS PASSED${NC} — Project is build-ready"
    exit 0
elif (( ERRORS == 0 )); then
    echo -e "${YELLOW}✓ PASSED with $WARNINGS warnings${NC} — Review warnings before building"
    exit 0
else
    echo -e "${RED}✗ FAILED with $ERRORS errors and $WARNINGS warnings${NC}"
    echo "Fix errors before attempting to build"
    exit 1
fi
