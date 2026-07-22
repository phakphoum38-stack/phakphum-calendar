# ADR-0008: Comparison and simulation before synchronization

- Status: Accepted
- Date: 2026-07-22

## Context

Calendar changes can remove or alter real user events. SCE must avoid direct mutations
from parser output.

## Decision

Introduce an intermediate event-candidate and diff model.

Pipeline:

```text
Shift records
  -> Calendar event candidates
  -> Diff engine
  -> Simulation summary
  -> User confirmation
  -> Calendar mutation
```

## Consequences

- Calendar changes are previewable.
- Given-away shifts can explicitly request deletion.
- Unit tests can verify synchronization behavior without Google API calls.
- Additional conversion code is required between domain shifts and Calendar candidates.
