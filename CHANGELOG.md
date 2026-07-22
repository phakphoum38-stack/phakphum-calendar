# Changelog

## [Unreleased]

### Added
- End-to-end mapping from user shift changes to Calendar candidates.
- Blocking behavior for unknown shift times.
- Workflow preview builder and controller.
- Dashboard foundation for preview and confirmation.
- Tests for received, given-away, blocked, and preview behavior.
- ADR-0013 and workflow documentation.

## [0.7.0] - 2026-07-22

### Added
- Sprint 6 end-to-end workflow foundation.

## [Unreleased]

### Added
- Real hospital roster parser based on the supplied workbook.
- Thai Buddhist calendar period parser.
- Flexible date-header row detection.
- Stable assignment position keys.
- Original/current roster comparison engine.
- User received/given-away shift classifier.
- Real-roster parser tests and documentation.
- ADR-0012 for text-first comparison.

## [0.6.0] - 2026-07-22

### Added
- Sprint 5 real roster parser foundation.

## [Unreleased]

### Added
- Durable sync history using SharedPreferencesAsync.
- Durable failed-operation payload storage.
- Resume synchronization service.
- Calendar sync coordinator.
- JSON serialization tests.
- ADR-0011.

## [Unreleased]

### Added
- CalendarDiff-to-CalendarSyncPlan builder.
- Deterministic SHA-256 based Sync ID factory.
- Per-operation synchronization results.
- Resilient Calendar synchronization executor.
- Independent retry for insert, update, and delete operations.
- Success, partial-success, and failure history statuses.
- Synchronization history repository contract.
- In-memory history repository.
- Synchronization history controller and screen.
- Unit tests for plan mapping, Sync ID stability, retry, and history.
- Synchronization reliability documentation.
- ADR-0010 for retry and history behavior.

### Pending
- Durable history storage.
- Resume failed operations.
- Duplicate-safe insert recovery after ambiguous network failures.
- Wiring the resilient executor into the preview screen.
- Real roster parsing and production OAuth validation.

## [0.4.0] - 2026-07-22

### Added
- Simulation item and simulation plan models.
- Simulation plan builder.
- Simulation controller with confirmation state.
- Preview screen for add, update, delete, unchanged, warning, and blocked counts.
- Calendar synchronization command and managed-event models.
- Calendar synchronization gateway contract.
- Google Calendar insert, update, delete, and managed-event listing adapter.
- Sequential synchronization executor.
- Unit tests for simulation-plan building and sync execution.
- Calendar preview and synchronization documentation.
- ADR-0009 for SCE-managed Calendar events.

## [0.3.1] - 2026-07-22

### Added
- Configurable roster layout profile model.
- Known shift-time catalog for confirmed shift categories and periods.
- Relationship resolution contracts and conservative default resolver.
- Calendar event candidate and diff models.
- Diff engine for add, update, delete, and unchanged classification.
- Simulation summary model.
- Unit tests for shift times, relationships, and diff behavior.
- Comparison foundation documentation.
- ADR-0008 for simulation before synchronization.

## [0.3.0] - 2026-07-22

### Added
- Typed sheet-cell, color, and merged-range models.
- A1 coordinate conversion utility.
- Google Sheets adapter extraction for effective values, formulas, formatting,
  background colors, number formats, and merged ranges.
- Spreadsheet-to-parser normalization layer.
- Configurable shift-color matching model.
- Parser domain contracts.
- Unit tests for coordinates, ranges, colors, and normalization.
- Parser foundation documentation.
- ADR-0007 for Google Sheets normalization.

## [0.2.1] - 2026-07-22

### Added
- Authorized Google API client factory.
- Drive API gateway for listing Google Sheets files.
- Original/current roster selection controller and UI.
- Typed Google Sheets snapshot models and gateway.
- Google Calendar access verification gateway.
- API foundation documentation.
- ADR-0006 for Drive spreadsheet selection.

## [0.2.0] - 2026-07-22

### Added
- Sprint 1 Google authentication domain and infrastructure scaffold.
- Official `google_sign_in` 7.x initialization flow.
- Drive, Sheets, and Calendar OAuth scope definitions.
- Authentication UI and controller.
- Google Drive Picker domain contract.
- Sheets and Calendar gateway contracts.
- Google Cloud setup guide.
- ADR-0005 for Google authentication and authorization.

## [0.1.0] - 2026-07-22

### Added
- Initial Sprint 0 repository foundation.
- Core project documentation.
- Architecture Decision Record templates.
- Initial domain model placeholders.
- GitHub Actions analysis and test workflow template.