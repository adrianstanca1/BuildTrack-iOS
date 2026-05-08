.PHONY: all build test lint archive beta release clean setup regenerate verify help

# Default target
all: verify

# ═══════════════════════════════════════════════════════════
# Setup
# ═══════════════════════════════════════════════════════════

setup:
	@echo "Setting up BuildTrack iOS development environment..."
	@which ruby > /dev/null || (echo "Ruby not found. Install via rbenv or Homebrew." && exit 1)
	@which gem > /dev/null || (echo "RubyGems not found." && exit 1)
	@echo "Installing fastlane..."
	@gem install fastlane bundler --no-document
	@echo "Installing cocoapods (if needed)..."
	@gem install cocoapods --no-document || true
	@echo "Installing xcbeautify..."
	@brew install xcbeautify 2>/dev/null || true
	@echo "Generating Xcode project..."
	@ruby scripts/generate-xcodeproj.rb
	@echo "Setup complete. Open BuildTrack.xcworkspace in Xcode."

regenerate:
	@echo "Regenerating Xcode project..."
	@ruby scripts/generate-xcodeproj.rb
	@echo "Done."

# ═══════════════════════════════════════════════════════════
# Verification
# ═══════════════════════════════════════════════════════════

verify:
	@bash scripts/verify-build.sh

# ═══════════════════════════════════════════════════════════
# Build
# ═══════════════════════════════════════════════════════════

build:
	@echo "Building BuildTrack for iOS Simulator..."
	@xcodebuild -workspace BuildTrack.xcworkspace \
		-scheme BuildTrack \
		-destination 'platform=iOS Simulator,name=iPhone 15' \
		-derivedDataPath fastlane/DerivedData \
		build \
		COMPILER_INDEX_STORE_ENABLE=NO \
		2>&1 | xcbeautify

test:
	@echo "Running tests on iPhone 15 Simulator..."
	@xcodebuild test \
		-workspace BuildTrack.xcworkspace \
		-scheme BuildTrack \
		-destination 'platform=iOS Simulator,name=iPhone 15' \
		-derivedDataPath fastlane/DerivedData \
		-enableCodeCoverage YES \
		COMPILER_INDEX_STORE_ENABLE=NO \
		2>&1 | xcbeautify

test-all:
	@echo "Running tests across all simulators..."
	@bundle exec fastlane test

# ═══════════════════════════════════════════════════════════
# Linting
# ═══════════════════════════════════════════════════════════

lint:
	@echo "Running SwiftLint..."
	@swiftlint lint --config .swiftlint.yml

lint-fix:
	@echo "Auto-fixing SwiftLint issues..."
	@swiftlint lint --fix --config .swiftlint.yml

# ═══════════════════════════════════════════════════════════
# Archive & Distribution
# ═══════════════════════════════════════════════════════════

archive:
	@echo "Archiving for release..."
	@xcodebuild archive \
		-workspace BuildTrack.xcworkspace \
		-scheme BuildTrack \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-archivePath fastlane/build/BuildTrack.xcarchive \
		-derivedDataPath fastlane/DerivedData \
		CODE_SIGNING_ALLOWED=NO \
		COMPILER_INDEX_STORE_ENABLE=NO \
		2>&1 | xcbeautify

beta:
	@echo "Building and uploading beta to TestFlight..."
	@bundle exec fastlane beta

release:
	@echo "Building and submitting to App Store..."
	@bundle exec fastlane release

screenshots:
	@echo "Capturing App Store screenshots..."
	@bundle exec fastlane screenshots

# ═══════════════════════════════════════════════════════════
# Maintenance
# ═══════════════════════════════════════════════════════════

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf fastlane/DerivedData/
	@rm -rf fastlane/build/
	@rm -rf fastlane/test_output/
	@rm -rf .build/
	@rm -rf ~/Library/Developer/Xcode/DerivedData/BuildTrack-*/
	@echo "Cleaned."

clean-all: clean
	@echo "Cleaning everything including Xcode project..."
	@rm -rf BuildTrack.xcodeproj/
	@rm -rf BuildTrack.xcworkspace/
	@ruby scripts/generate-xcodeproj.rb
	@echo "Regenerated Xcode project."

update-deps:
	@echo "Updating SPM dependencies..."
	@xcodebuild -resolvePackageDependencies \
		-workspace BuildTrack.xcworkspace \
		-scheme BuildTrack \
		-derivedDataPath fastlane/DerivedData

# ═══════════════════════════════════════════════════════════
# Documentation
# ═══════════════════════════════════════════════════════════

readme:
	@echo "Opening README..."
	@cat README.md

changelog:
	@echo "Showing recent changes..."
	@cat CHANGELOG.md

# ═══════════════════════════════════════════════════════════
# Help
# ═══════════════════════════════════════════════════════════

help:
	@echo "BuildTrack iOS — Available Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup       Install dependencies and generate Xcode project"
	@echo "  make regenerate  Regenerate Xcode project from sources"
	@echo ""
	@echo "Build & Test:"
	@echo "  make build       Build for iOS Simulator"
	@echo "  make test        Run unit + UI tests"
	@echo "  make test-all    Run tests across all simulators via fastlane"
	@echo ""
	@echo "Quality:"
	@echo "  make lint        Run SwiftLint"
	@echo "  make lint-fix    Auto-fix SwiftLint issues"
	@echo "  make verify      Run build verification script"
	@echo ""
	@echo "Distribution:"
	@echo "  make archive     Create release archive"
	@echo "  make beta        Upload beta to TestFlight"
	@echo "  make release     Submit to App Store"
	@echo "  make screenshots Capture App Store screenshots"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean       Clean build artifacts"
	@echo "  make clean-all   Clean everything + regenerate project"
	@echo "  make update-deps Update SPM packages"
	@echo ""
	@echo "Documentation:"
	@echo "  make readme      Show README"
	@echo "  make changelog   Show CHANGELOG"
