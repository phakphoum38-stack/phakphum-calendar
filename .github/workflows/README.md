# GitHub Actions workflows

- `validate.yml` — format, analyze, unit/widget tests with line coverage,
  dependency vulnerability scanning, and static repository security checks.
- `android.yml` — release APK and AAB.
- `ios.yml` — unsigned IPA for testing/build verification.
- `web.yml` — Flutter Web artifact and GitHub Pages deployment.
- `desktop.yml` — Windows x64, Linux x64, and macOS application artifacts.

## Optional repository secrets

- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID`
- `GOOGLE_REVERSED_CLIENT_ID`
- `GOOGLE_MACOS_CLIENT_ID`
- `GOOGLE_MACOS_REVERSED_CLIENT_ID`

Builds still run when these secrets are empty, but Google sign-in will need valid OAuth values at runtime.

The iOS workflow creates an **unsigned** IPA. Installation on a physical iPhone still requires valid Apple signing/provisioning outside this workflow.

## Quality gates

The validation workflow generates `coverage/lcov.info`, uploads it as a
short-lived workflow artifact, and fails when line coverage is below the
configured minimum. The default minimum is 60%. Set the repository Actions
variable `MIN_COVERAGE_PERCENT` to raise or lower the threshold without editing
the workflow.

OSV-Scanner checks the resolved Dart packages in `pubspec.lock` and fails for
known vulnerabilities. Trivy scans the checked-out repository for high- or
critical-severity secret and configuration findings. These checks use the
read-only workflow token and do not require committed credentials.
