# Platform support policy

## Current release scope

The project is intentionally stabilized around two delivery targets:

1. **Windows x64** — packaged release ZIP with SHA-256 checksum.
2. **Web** — Flutter Web release deployed to GitHub Pages.

These are the only platforms that should participate in the active release
pipeline during the current stabilization phase.

| Platform | Product source | Release CI/CD | Status |
| --- | --- | --- | --- |
| Windows x64 | Yes | `.github/workflows/windows.yml` | Supported |
| Web | Yes | `.github/workflows/web.yml` | Supported |
| Android | Preserved for now | None | Paused |
| iOS | Preserved for now | None | Paused |
| macOS | Preserved for now | None | Paused |
| Linux | Preserved for now | None | Paused |
| Backend/Laravel | Preserved if present | None | Paused |

## Why source folders are not deleted yet

The stabilization change removes **delivery responsibility**, not source code.
Deleting Flutter platform directories immediately would be a destructive
migration and could make future re-enablement harder. The first safety step
is therefore to remove their CI/CD gates and keep the repository build surface
small.

A platform should only be physically removed later if there is an explicit
product decision to delete that source permanently.

## Failure containment

The active Windows/Web release path must not depend on:

- `integration_test/` existing;
- coverage files such as `coverage/lcov.info`;
- Android/iOS/macOS/Linux SDKs;
- mobile signing credentials;
- backend/Laravel services;
- broad repository validation jobs.

This prevents the previously observed failures—missing `integration_test/`,
formatter self-modification, and missing coverage artifacts—from blocking the
supported release targets.

## Re-enable procedure

To re-enable a paused platform, add a dedicated workflow only after:

1. the platform has an explicit product requirement;
2. its build/signing prerequisites are documented;
3. its workflow is independently tested;
4. failure in that platform cannot silently block unrelated delivery targets;
5. the support matrix is updated in the same change.
