# GitHub Actions workflows

The active delivery surface is intentionally reduced to **two targets only**:

- `windows.yml` — Windows x64 release ZIP + SHA-256 checksum.
- `web.yml` — Flutter Web release + GitHub Pages deployment.

Android, iOS, macOS, Linux, Laravel/backend validation, broad repository
validation, coverage gates, integration-test gates, and platform-specific
release pipelines are **not active delivery gates**. Their source directories
may remain in the Flutter repository for now, but they must not be required to
merge or deploy the supported targets.

## Support policy

For the current stabilization phase:

| Target | Status | CI/CD |
| --- | --- | --- |
| Windows x64 | Supported | `windows.yml` |
| Web / GitHub Pages | Supported | `web.yml` |
| Android | Paused | No active workflow |
| iOS | Paused | No active workflow |
| macOS | Paused | No active workflow |
| Linux | Paused | No active workflow |
| Backend/Laravel | Paused | No active workflow |

**Do not add a new platform workflow automatically.** A paused platform can
return only through an explicit decision and a separately verified workflow.

## Repository secrets

- `GOOGLE_WEB_CLIENT_ID` — used by the Web deployment when Google Sign-In is enabled.
- `GOOGLE_SERVER_CLIENT_ID` — optional server OAuth client used by the Windows build and Web build.

Platform-specific OAuth secrets for iOS/macOS are not required by the active
workflows.

## Active delivery gates

### Windows

The Windows workflow installs dependencies, builds the release application,
packages it as a ZIP, and produces a SHA-256 checksum. It runs manually or
when relevant Windows, Flutter, asset, dependency, or workflow files change
on `main`.

### Web

The Web workflow installs dependencies, builds the release site, uploads the
build as a downloadable artifact, and deploys the same build to GitHub Pages
from `main`.

## Failure-containment policy

The supported delivery workflows must remain independent:

1. A paused platform must not block Windows or Web delivery.
2. Missing `integration_test/` must never be treated as a CI failure for the
   supported targets.
3. Coverage artifacts are not required by the Windows/Web release workflows.
4. Formatting, analysis, unit tests, and coverage remain developer-side checks
   unless a dedicated validation workflow is intentionally restored.
5. A workflow must not auto-commit generated formatting changes during a
   release gate. Formatting changes must be committed explicitly by the
   developer or a dedicated maintenance job.

## Simplification policy

Keep Actions focused on **Windows + Web deployment** until the project has a
clear reason to re-enable another platform. The goal is a small, deterministic
release surface rather than a large matrix of intermittently maintained
platform checks.
