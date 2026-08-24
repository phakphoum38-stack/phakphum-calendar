# GitHub Actions workflows

The CI surface is intentionally reduced to the two supported delivery targets:

- `windows.yml` — Windows x64 ZIP and SHA-256 checksum.
- `web.yml` — Flutter Web build and GitHub Pages deployment.

Android, iOS, macOS, Linux, Laravel/backend validation, and the broad
repository validation workflow are temporarily removed from Actions so they
cannot block delivery while the project is being simplified. Their source
code is not deleted by this CI cleanup.

## Repository secrets

- `GOOGLE_WEB_CLIENT_ID` — used by the Web deployment when Google Sign-In is enabled.
- `GOOGLE_SERVER_CLIENT_ID` — optional server OAuth client used by the Windows build and Web build.

Platform-specific OAuth secrets for iOS/macOS are no longer required by the
active workflows.

## Active delivery gates

### Windows

The Windows workflow builds the release application, packages it as a ZIP,
and produces a SHA-256 checksum. It runs manually or when relevant Windows,
Flutter, asset, or dependency files change on `main`.

### Web

The Web workflow builds the release site, uploads a downloadable artifact,
and deploys the same build to GitHub Pages from `main`.

## Simplification policy

For now, keep Actions focused on **Windows + Web deployment**. Do not add
platform-specific CI back until the corresponding platform is explicitly
re-enabled and has a stable, independently verified workflow.

Local formatting, analysis, tests, and coverage remain developer-side checks
until a dedicated validation workflow is intentionally restored.
