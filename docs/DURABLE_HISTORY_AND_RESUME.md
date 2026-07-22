# Durable History and Resume

Sprint 4 stores lightweight synchronization history and failed-operation payloads
through `SharedPreferencesAsync`, using separate versioned keys.

History stores timestamps, status and counts. Failed-operation storage contains only
technical Calendar commands needed for retry. Patient data, OAuth tokens and complete
roster contents must never be stored here.

`ResumeSyncService` retries failed operations and updates the original history entry.
`CalendarSyncCoordinator` joins managed-event lookup, plan building and execution.

Production follow-up: duplicate-safe insert reconciliation, progress UI, authorization
refresh and main-screen dependency wiring.
