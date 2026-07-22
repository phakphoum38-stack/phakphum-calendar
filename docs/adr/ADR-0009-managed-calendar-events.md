# ADR-0009: Identify SCE-managed Calendar events with private extended properties

- Status: Accepted
- Date: 2026-07-22

## Context

SCE must prevent duplicates and must never modify unrelated personal Calendar events.

## Decision

Every event created by SCE stores a deterministic Sync ID in the private extended property
`sceSyncId`.

Calendar reads filter for managed events and time range. Updates and deletes use the Google
Calendar event ID after matching by Sync ID.

## Consequences

- Unrelated events remain untouched.
- Duplicate prevention is deterministic.
- Existing events created before this scheme require migration or manual recreation.
- Sync ID composition must remain stable once production data exists.
