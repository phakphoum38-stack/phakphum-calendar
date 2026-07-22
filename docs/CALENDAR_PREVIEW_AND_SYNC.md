# Calendar Preview and Synchronization Foundation

## Preview

A simulation plan contains every proposed action before Calendar mutation:

- Add
- Update
- Delete
- Unchanged
- Blocked

The preview screen displays counts and individual items. The confirmation button is disabled
when:

- there are blocked items;
- there are no changes;
- synchronization is already running.

## Managed events

SCE-managed Calendar events contain a private extended property:

```text
sceSyncId=<deterministic Sync ID>
```

This value is used to find, update, and delete only events created or managed by SCE.

## Calendar gateway

The gateway supports:

- listing SCE-managed events in a time range;
- inserting events;
- updating events by Google Calendar event ID;
- deleting events by Google Calendar event ID.

## Safety boundary

The sync executor receives an already-confirmed `CalendarSyncPlan`.
It does not parse Sheets, resolve relationships, or decide which actions are safe.

## Remaining work

- Convert `CalendarDiff` into a `CalendarSyncPlan` using existing Google event IDs.
- Persist synchronization history.
- Add retry and partial-failure reporting.
- Add timezone-aware event creation.
- Connect the preview screen to the file comparison workflow.
