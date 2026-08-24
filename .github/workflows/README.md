# GitHub Actions workflows

- `validate.yml` — format, analyze, unit/widget tests with line coverage,
  dependency vulnerability scanning, and static repository security checks.
- `android.yml` — release APK and AAB.
- `ios.yml` — unsigned IPA for testing/build verification.
- `web.yml` — Flutter Web artifact and GitHub Pages deployment.
- `windows.yml` — Windows x64 ZIP and SHA-256 checksum.
- `macos.yml` — macOS application ZIP and SHA-256 checksum.
- `linux.yml` — Linux x64 TAR.GZ and SHA-256 checksum.
- `laravel.yml` — Composer validation, formatting, and backend tests.

Every platform workflow supports manual `workflow_dispatch`. Platform builds
also run automatically when relevant files are pushed to `main`.

## Repository secrets

- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID` (optional; iOS falls back to `GOOGLE_WEB_CLIENT_ID`)
- `GOOGLE_IOS_CLIENT_ID` (required for the iOS workflow)
- `GOOGLE_REVERSED_CLIENT_ID` (optional; derived from `GOOGLE_IOS_CLIENT_ID`)
- `GOOGLE_MACOS_CLIENT_ID`
- `GOOGLE_MACOS_REVERSED_CLIENT_ID`

The iOS workflow fails early when the iOS or Web/server OAuth client ID is
missing or malformed. This prevents publishing an IPA that builds successfully
but crashes at Google Sign-In because `GIDClientID` is absent.

The iOS workflow creates an **unsigned** IPA. Installation on a physical iPhone still requires valid Apple signing/provisioning outside this workflow.

## Quality gates

The validation workflow generates `coverage/lcov.info`, uploads it as a
short-lived workflow artifact, and fails when line coverage is below the
configured minimum. The default minimum is 60%. Set the repository Actions
variable `MIN_COVERAGE_PERCENT` to raise or lower the threshold without editing
the workflow.

The formatter validates `lib/` and `test/`. The `integration_test/` directory
is optional: when it exists it is formatted and validated; when it does not
exist the workflow skips that target instead of failing on a missing path.
This keeps the validation workflow compatible with repository layouts that do
not use Flutter integration tests.

OSV-Scanner checks the resolved Dart packages in `pubspec.lock` and fails for
known vulnerabilities. Trivy scans the checked-out repository for high- or
critical-severity secret and configuration findings. These checks use the
read-only workflow token and do not require committed credentials.

## Local preflight before push or PR

Run the same checks locally before opening or updating a PR:

```bash
flutter pub get
dart format lib test
if [ -d integration_test ]; then dart format integration_test; fi
flutter analyze --fatal-infos
flutter test --coverage --reporter expanded
```

If CI reports `Changed ...` from `dart format --set-exit-if-changed`, the code
is not formatted in the checked-out commit. Run the formatter locally, review
the diff, commit the formatting changes, and push again. Do not make the CI
formatter silently rewrite the PR, because the validation gate should remain a
strict check of what is actually committed.

If CI reports that `coverage/lcov.info` is missing, investigate the test step
first. The artifact upload is intentionally conditional on the coverage file
existing, so a test failure produces one primary failure instead of a second
misleading artifact-upload failure.
