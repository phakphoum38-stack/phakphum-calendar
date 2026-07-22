# ADR-0004: Diff-based Calendar synchronization

- Status: Accepted
- Date: 2026-07-22

## Decision

Synchronization will compare desired events against previously managed events and produce:

- add;
- update;
- delete;
- unchanged;
- blocked.

Managed events will contain a deterministic Sync ID in Google Calendar extended properties.

## Consequences

The system avoids duplicate events and does not rebuild the entire Calendar on every run.
