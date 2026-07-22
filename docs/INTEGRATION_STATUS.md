# Integration Status

## Included

Sprint 6 production architecture has been merged into the existing `phakphum_calendar` Flutter application without replacing its working entry point.

- `lib/core/`
- `lib/features/authentication/`
- `lib/features/google_drive/`
- `lib/features/google_sheets/`
- `lib/features/shift_parser/`
- `lib/features/relationship_engine/`
- `lib/features/diff_engine/`
- `lib/features/simulation/`
- `lib/features/calendar_engine/`
- `lib/features/history/`
- `lib/features/workflow/`
- Sprint 6 unit tests under `test/sce_*`
- Architecture documentation and ADRs
- AI workspace under `.ai/`

## Active application

The current `lib/main.dart`, `lib/app.dart`, `lib/controller/app_controller.dart`, and existing UI remain active. This avoids breaking the Google authentication, roster screen, and Google Sheets picker already present in the application.

## Next integration step

Connect `AppController` to `ShiftCalendarWorkflowController` behind an adapter, then expose the Sprint 6 workflow preview in the existing dashboard. The adapter should translate the current `Shift` model to the production workflow domain model rather than making either model depend directly on the other.
