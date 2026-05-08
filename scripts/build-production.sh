#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# BuildTrack iOS — Production Build Script
# ═══════════════════════════════════════════════════════════════
# Builds the iOS app in Release configuration targeting the
# production backend at https://buildtrack.stancainvest.ro
#
# Usage:
#   ./scripts/build-production.sh              # Build archive only
#   ./scripts/build-production.sh --archive     # Build .xcarchive
#   ./scripts/build-production.sh --ipa         # Build .ipa for distribution
#   ./scripts/build-production.sh --test        # Run tests only
#   ./scripts/build-production.sh --all         # Full pipeline: test → archive → IPA
#
# Prerequisites:
#   - Xcode 15.0+ installed
#   - Apple Developer account configured
#   - Config-Production.xcconfig in place
#   - fastlane installed (gem install fastlane)
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colour Output ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ── Configuration ────────────────────────────────────────────
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly PROJECT_NAME="BuildTrack"
readonly SCHEME="BuildTrack"
readonly CONFIGURATION="Release"
readonly WORKSPACE="${PROJECT_DIR}/${PROJECT_NAME}.xcworkspace"
readonly XCODEPROJ="${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj"
readonly ARCHIVE_PATH="${PROJECT_DIR}/build/${PROJECT_NAME}-$(date +%Y%m%d-%H%M%S).xcarchive"
readonly IPA_DIR="${PROJECT_DIR}/build"
readonly IPA_NAME="${PROJECT_NAME}.ipa"
readonly DERIVED_DATA="${PROJECT_DIR}/build/DerivedData"
readonly CONFIG_FILE="${PROJECT_DIR}/BuildTrack/Config-Production.xcconfig"

# Production backend URLs (must match Config-Production.xcconfig)
readonly EXPECTED_SUPABASE_URL="https://buildtrack.stancainvest.ro"
readonly EXPECTED_ANON_KEY_PREFIX="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"

# ── Functions ────────────────────────────────────────────────

validate_environment() {
    log_info "Validating build environment..."
    
    # Check Xcode
    if ! command -v xcodebuild &>/dev/null; then
        log_error "xcodebuild not found. Install Xcode 15.0+."
        exit 1
    fi
    
    local xcode_version
    xcode_version=$(xcodebuild -version | head -1 | awk '{print $2}')
    log_ok "Xcode version: ${xcode_version}"
    
    # Check workspace/project
    if [[ -d "$WORKSPACE" ]]; then
        log_ok "Workspace found: ${WORKSPACE}"
    elif [[ -d "$XCODEPROJ" ]]; then
        log_warn "No .xcworkspace found, using .xcodeproj"
    else
        log_error "No .xcworkspace or .xcodeproj found in ${PROJECT_DIR}"
        exit 1
    fi
    
    # Validate config file
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config-Production.xcconfig not found at ${CONFIG_FILE}"
        exit 1
    fi
    
    # Check production URL in config
    if grep -q "${EXPECTED_SUPABASE_URL}" "$CONFIG_FILE"; then
        log_ok "Production Supabase URL confirmed: ${EXPECTED_SUPABASE_URL}"
    else
        log_error "Config-Production.xcconfig does not contain expected production URL!"
        log_error "Expected: ${EXPECTED_SUPABASE_URL}"
        log_error "Check ${CONFIG_FILE}"
        exit 1
    fi
    
    # Check anon key prefix
    if grep -q "${EXPECTED_ANON_KEY_PREFIX}" "$CONFIG_FILE"; then
        log_ok "Production anon key format confirmed"
    else
        log_warn "Anon key format differs from expected. Verify manually."
    fi
    
    # Check Info.plist
    if [[ ! -f "${PROJECT_DIR}/BuildTrack/Info.plist" ]]; then
        log_error "Info.plist not found. Run setup first."
        exit 1
    fi
    log_ok "Info.plist found"
    
    log_ok "Environment validation complete."
}

clean_build() {
    log_info "Cleaning build artefacts..."
    
    rm -rf "${PROJECT_DIR}/build"
    mkdir -p "${PROJECT_DIR}/build"
    
    if [[ -d "$WORKSPACE" ]]; then
        xcodebuild clean \
            -workspace "$WORKSPACE" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -quiet
    else
        xcodebuild clean \
            -project "$XCODEPROJ" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -quiet
    fi
    
    log_ok "Clean complete."
}

run_tests() {
    log_info "Running test suite..."
    
    local test_cmd
    if [[ -d "$WORKSPACE" ]]; then
        test_cmd="xcodebuild test \
            -workspace \"$WORKSPACE\" \
            -scheme \"$SCHEME\" \
            -configuration \"$CONFIGURATION\" \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
            -derivedDataPath \"$DERIVED_DATA\" \
            -resultBundlePath \"${PROJECT_DIR}/build/TestResults.xcresult\" \
            -enableCodeCoverage YES"
    else
        test_cmd="xcodebuild test \
            -project \"$XCODEPROJ\" \
            -scheme \"$SCHEME\" \
            -configuration \"$CONFIGURATION\" \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
            -derivedDataPath \"$DERIVED_DATA\" \
            -resultBundlePath \"${PROJECT_DIR}/build/TestResults.xcresult\" \
            -enableCodeCoverage YES"
    fi
    
    if eval "$test_cmd"; then
        log_ok "All tests passed."
    else
        log_error "Test suite failed. Fix before building for production."
        exit 1
    fi
}

build_archive() {
    log_info "Building archive..."
    
    local archive_cmd
    if [[ -d "$WORKSPACE" ]]; then
        archive_cmd="xcodebuild archive \
            -workspace \"$WORKSPACE\" \
            -scheme \"$SCHEME\" \
            -configuration \"$CONFIGURATION\" \
            -archivePath \"$ARCHIVE_PATH\" \
            -derivedDataPath \"$DERIVED_DATA\" \
            -xcconfig \"$CONFIG_FILE\" \
            SWIFT_VERSION=5.9 \
            IPHONEOS_DEPLOYMENT_TARGET=17.0 \
            ENABLE_BITCODE=NO \
            DEBUG_INFORMATION_FORMAT=dwarf-with-dsym"
    else
        archive_cmd="xcodebuild archive \
            -project \"$XCODEPROJ\" \
            -scheme \"$SCHEME\" \
            -configuration \"$CONFIGURATION\" \
            -archivePath \"$ARCHIVE_PATH\" \
            -derivedDataPath \"$DERIVED_DATA\" \
            -xcconfig \"$CONFIG_FILE\" \
            SWIFT_VERSION=5.9 \
            IPHONEOS_DEPLOYMENT_TARGET=17.0 \
            ENABLE_BITCODE=NO \
            DEBUG_INFORMATION_FORMAT=dwarf-with-dsym"
    fi
    
    if eval "$archive_cmd"; then
        log_ok "Archive built successfully."
        log_info "Archive path: ${ARCHIVE_PATH}"
    else
        log_error "Archive build failed."
        exit 1
    fi
}

export_ipa() {
    log_info "Exporting IPA..."
    
    if [[ ! -d "$ARCHIVE_PATH" ]]; then
        log_warn "No archive found. Building archive first..."
        build_archive
    fi
    
    local export_plist="${PROJECT_DIR}/build/ExportOptions.plist"
    
    # Create export options plist for App Store
    cat > "$export_plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>thinning</key>
    <string>&lt;thin-for-all-variants&gt;</string>
</dict>
</plist>
PLIST
    
    log_warn "ExportOptions.plist created with placeholder team ID."
    log_warn "Edit ${export_plist} and set your real teamID before exporting."
    
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$IPA_DIR" \
        -exportOptionsPlist "$export_plist" \
        -allowProvisioningUpdates
    
    local ipa_path="${IPA_DIR}/${IPA_NAME}"
    
    if [[ -f "$ipa_path" ]]; then
        local ipa_size
        ipa_size=$(du -h "$ipa_path" | cut -f1)
        log_ok "IPA exported: ${ipa_path} (${ipa_size})"
    else
        log_error "IPA export failed."
        exit 1
    fi
    
    echo ""
    log_ok "╔══════════════════════════════════════════════╗"
    log_ok "║  BuildTrack Production Build Complete        ║"
    log_ok "╠══════════════════════════════════════════════╣"
    log_ok "║  Archive: ${ARCHIVE_PATH}"
    log_ok "║  IPA:     ${ipa_path}"
    log_ok "║  Backend: ${EXPECTED_SUPABASE_URL}"
    log_ok "╚══════════════════════════════════════════════╝"
    echo ""
}

show_usage() {
    cat << 'USAGE'
BuildTrack iOS — Production Build Script
═══════════════════════════════════════════

Usage:
  ./scripts/build-production.sh [OPTIONS]

Options:
  --validate   Validate environment and config only (no build)
  --test       Run test suite only
  --archive    Build .xcarchive for production
  --ipa        Build .xcarchive and export .ipa for App Store
  --all        Full pipeline: validate → test → archive → IPA
  --help       Show this help

Examples:
  ./scripts/build-production.sh --validate
  ./scripts/build-production.sh --test
  ./scripts/build-production.sh --all

Environment:
  SUPABASE_URL     = https://buildtrack.stancainvest.ro
  Config file      = BuildTrack/Config-Production.xcconfig
  Min iOS          = 17.0
  Swift            = 5.9
USAGE
}

# ── Main ────────────────────────────────────────────────────

main() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  BuildTrack iOS — Production Build           ║"
    echo "║  $(date '+%Y-%m-%d %H:%M:%S')                            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
    
    local mode="${1:---help}"
    
    case "$mode" in
        --validate)
            validate_environment
            ;;
        --test)
            validate_environment
            clean_build
            run_tests
            ;;
        --archive)
            validate_environment
            clean_build
            build_archive
            ;;
        --ipa)
            validate_environment
            clean_build
            build_archive
            export_ipa
            ;;
        --all)
            validate_environment
            clean_build
            run_tests
            build_archive
            export_ipa
            ;;
        --help|-h|help)
            show_usage
            ;;
        *)
            log_error "Unknown option: $mode"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
