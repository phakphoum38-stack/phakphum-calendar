# ADR-0013: Block synchronization when shift time is unknown

- Status: Accepted
- Date: 2026-07-22

## Decision

When a parsed shift category and period do not match a confirmed `ShiftDefinition`, do
not create a Calendar event candidate. Add a warning and increment the blocked count.

## Reason

Guessing a hospital shift time can create an unsafe or misleading Calendar schedule.
A user or administrator must confirm the time mapping first.
