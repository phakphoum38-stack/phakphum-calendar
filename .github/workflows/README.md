# GitHub Actions workflows

- `validate.yml` — format, analyze, and unit/widget tests on Ubuntu.
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
