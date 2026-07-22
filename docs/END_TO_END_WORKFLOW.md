# End-to-End Workflow Foundation

Sprint 6 connects roster comparison output to Calendar preview and synchronization.

```text
Original roster + Current roster
  -> UserShiftChange
  -> UserShiftEventMapper
  -> Calendar event candidates
  -> CalendarDiff
  -> SimulationPlan
  -> User confirmation
  -> CalendarSyncCoordinator
  -> Google Calendar
```

## Mapping rules

- Own unchanged: event remains present.
- Received: event is added or updated.
- Given away: matching managed event is deleted.
- Moved between slots: event remains present with updated source details.
- Unrelated: ignored.
- Unknown shift time: blocks synchronization.

## Safety

The mapper does not invent missing shift times. An unknown category/period produces a
blocked item instead of an incorrect Calendar event.

The Calendar description contains only roster source metadata and relationship status.
Patient information must never be included.
