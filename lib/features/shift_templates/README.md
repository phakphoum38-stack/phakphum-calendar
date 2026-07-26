# Shift Templates

Shift templates are persistent, configurable definitions for canonical
`ShiftType` values. They own reusable code, display name, start/end time,
print color, working hours, default location/calendar metadata, reminder, rate,
activation state, and display order.

`ShiftTemplateController` creates the standard morning, evening, night, and
on-call defaults only when the repository is empty. These are editable
configuration records, not hard-coded production assignments. Deactivation is
soft so canonical schedule history keeps valid shift identities.

The manual roster editor loads active employees and templates through
`AppDependencies`, converts templates at the composition boundary, mutates the
canonical `Schedule` first, previews destructive/bulk changes, and explicitly
saves through `ScheduleRepository`.

Template duplication/reordering, role and department restrictions, holiday and
OT rules, personal overrides, and import/export are intentionally out of scope
for this phase.
