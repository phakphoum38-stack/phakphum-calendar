# ADR-0010: Per-operation retry and synchronization history

- Status: Accepted
- Date: 2026-07-22

## Context

Google Calendar synchronization may fail after some operations have already
completed. Treating the entire run as one transaction is not possible.

## Decision

Execute each Calendar operation independently, retry temporary failures, retain
an operation result, and save a synchronization history entry.

## Consequences

- Partial success is visible.
- Failed operations can be identified.
- Future resume support has a clear data source.
- Insert retries require duplicate checks because network outcomes can be ambiguous.
