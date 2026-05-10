# Wiring up the test scheme

The `Tests/Unit/*.swift` files exist on disk but no test target is defined in
`BuildTrack.xcodeproj`, so `xcodebuild test` is a no-op and CI currently
stubs out the test step (`echo "Tests skipped - scheme not configured for
testing"`). This checklist adds a Unit Testing Bundle target, wires the
existing files into it, and updates CI.

You'll need Xcode 26.3 (the version `deploy-testflight.yml` pins to) on a
macOS environment.

## 1. Open the workspace (not the .xcodeproj)

```
open BuildTrack.xcworkspace
```

Opening the workspace ensures SPM-resolved dependencies — `Supabase`,
`xctest-dynamic-overlay`, etc. — are available to the new target.

## 2. Add a Unit Testing Bundle target

`File → New → Target...` (or `⌥⌘N`)

- Tab: **iOS**
- Template (under *Test*): **Unit Testing Bundle**
- Click **Next**

Configure:

| Field | Value | Why |
|---|---|---|
| Product Name | `BuildTrackTests` | Standard convention; matches the `BuildTrackUITests.swift` naming pattern that already exists |
| Team | (same as `BuildTrack` app) | — |
| Organization Identifier | (same as `BuildTrack` app — likely `ro.stancainvest`) | — |
| Bundle Identifier | auto: `ro.stancainvest.BuildTrackTests` | — |
| Language | Swift | — |
| Testing System | **XCTest** | Not Swift Testing — existing files use XCTest |
| Project | BuildTrack | — |
| Embed in Application | BuildTrack | Required for `@testable import BuildTrack` to work |
| Target to be Tested | BuildTrack | — |

Click **Finish**.

## 3. Replace the auto-generated stub with the real test files

Xcode will create `BuildTrackTests/BuildTrackTests.swift` (a stub). Delete it
(Move to Trash).

Then add the existing test files:

- In Project Navigator, right-click the **BuildTrackTests** group →
  **Add Files to "BuildTrack"...**
- Navigate to and select:
  - `Tests/Unit/DeepLinkRouterTests.swift` (the 34 characterization tests
    landed in commit `be87ee1`)
  - `Tests/Unit/ProjectViewModelTests.swift`
  - `Tests/Unit/TaskViewModelTests.swift`
- On the dialog:
  - **Uncheck** "Copy items if needed" (files are already at `Tests/Unit/`)
  - **Added folders**: Create groups (NOT folder references)
  - **Add to targets**: ✓ `BuildTrackTests` only — **do NOT also tick
    `BuildTrack`**

For each added file, verify in the File Inspector (`⌥⌘1`) that:

- Target Membership shows `BuildTrackTests` ✓ checked
- `BuildTrack` is unchecked

## 4. Verify the scheme

`Product → Scheme → Edit Scheme...` (`⌘<`)

- Select **Test** in the left sidebar
- Confirm `BuildTrackTests` appears under "Tests"
- Tick its checkbox if not already enabled
- If `BuildTrackUITests` is listed but the UI target hasn't been created
  yet, untick it for now (separate follow-up).

Close the scheme editor.

## 5. Local sanity check before commit

```
xcodebuild test \
  -workspace BuildTrack.xcworkspace \
  -scheme BuildTrack \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=17.5"
```

All 34 `DeepLinkRouterTests.*` tests + the 2 existing ViewModel tests
should pass.

## 6. Commit the project + scheme changes

The diff will include:

| File | Expected change |
|---|---|
| `BuildTrack.xcodeproj/project.pbxproj` | ~80–120 new lines (test target, file refs, build phases, build configs) |
| `BuildTrack.xcworkspace/xcshareddata/xcschemes/BuildTrack.xcscheme` | A new `<TestAction>` block referencing `BuildTrackTests` |
| `BuildTrackTests/Info.plist` (likely auto-created) | New file |

Suggested commit message:

```
chore(ios): wire up BuildTrackTests target

Add Unit Testing Bundle target referencing the existing Tests/Unit/*.swift
files. Scheme now runs unit tests on `xcodebuild test`. CI workflow update
follows in a separate commit.
```

Push to `main`.

## 7. CI workflow patch (to apply after step 6 lands)

`.github/workflows/ios-ci.yml` — change:

```diff
       - name: Build for testing
-        run: xcodebuild build -workspace BuildTrack.xcworkspace -scheme BuildTrack -destination "platform=iOS Simulator,name=iPhone 15,OS=17.5" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO COMPILER_INDEX_STORE_ENABLE=NO
+        run: xcodebuild build-for-testing -workspace BuildTrack.xcworkspace -scheme BuildTrack -destination "platform=iOS Simulator,name=iPhone 15,OS=17.5" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO COMPILER_INDEX_STORE_ENABLE=NO
       - name: Run unit tests
-        run: echo "Tests skipped - scheme not configured for testing"
-      - name: Run UI tests
-        run: echo "UI tests skipped - scheme not configured for testing"
+        run: xcodebuild test-without-building -workspace BuildTrack.xcworkspace -scheme BuildTrack -destination "platform=iOS Simulator,name=iPhone 15,OS=17.5" -only-testing:BuildTrackTests
```

The UI tests stub is removed; reinstate as a separate step once a UI
Testing Bundle target is added.

## Notes

- **Why `build-for-testing` + `test-without-building` split** instead of a
  single `xcodebuild test`: the split caches the build separately and lets
  test-only re-runs skip recompilation. On the macos-14 runner,
  `build-for-testing` is ~70–90s; `test-without-building` adds ~10–20s. A
  combined `xcodebuild test` would re-do the build on every retry.
- **`-only-testing:BuildTrackTests`** scopes the test invocation to just
  that bundle. When a UI Testing Bundle (`BuildTrackUITests`) is added
  later, name it explicitly in a separate step so UI tests don't block the
  unit-test pipeline.
- **`@testable import BuildTrack` vs plain `import BuildTrack`:** the
  former exposes `internal`-visibility members. Our `DeepLinkRouter` is
  internal, so plain `import` would also compile — but the existing
  `ProjectViewModelTests.swift` uses `@testable`, and consistency matters.
  `@testable` requires the test target to compile against the *test* build
  product of BuildTrack — automatic when you use *Embed in Application:
  BuildTrack* in step 2. If you accidentally choose "no host application,"
  tests will fail at link time.
