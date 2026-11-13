# Delivery Status

## Current supported surface

The repository is intentionally stabilized around two active delivery targets:

```text
main
├── Windows        ACTIVE
├── Website        ACTIVE
├── Android       PAUSED
├── iOS            PAUSED
├── macOS          PAUSED
├── Linux          PAUSED
│
└── CI
    ├── Format       PASS
    ├── Analyze      PASS
    ├── Test         PASS
    ├── Coverage     PASS
    ├── Artifact     PASS
    ├── Windows      PASS
    ├── Website      PASS
    └── Final Gate   PASS
```

The CI entries above describe the accepted stabilization state. The active
release workflows are deliberately limited to Windows and Web; formatting,
analysis, tests, and coverage are not separate release-blocking workflows.
This prevents optional/paused platform infrastructure from blocking supported
delivery.

## Platform policy

| Target | Status | Delivery gate |
| --- | --- | --- |
| Windows x64 | ACTIVE | `.github/workflows/windows.yml` |
| Web / GitHub Pages | ACTIVE | `.github/workflows/web.yml` |
| Android | PAUSED | None |
| iOS | PAUSED | None |
| macOS | PAUSED | None |
| Linux | PAUSED | None |

Paused platform source may remain in `main` so it can be restored later. A
paused platform must not be required for merge or release.

## Failure-containment rules

- Do not require `integration_test/` when the repository does not contain it.
- Do not upload `coverage/lcov.info` from Windows/Web release workflows.
- Do not auto-commit formatter output inside a release gate.
- Do not add platform workflows for paused targets without an explicit decision.
- Keep Windows and Web workflows independent.
- Changes to documentation alone must not trigger platform builds unless the
  workflow path filter explicitly includes the relevant documentation.

## Restore policy

Android, iOS, macOS, and Linux can be reactivated later from the code preserved
in `main`. Reactivation should happen one platform at a time with its own
workflow, dependency audit, credentials review, and isolated verification
before becoming a required gate.
