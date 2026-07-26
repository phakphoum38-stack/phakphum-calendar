# Shift Tools Domain

## Employee

An employee is a person who can receive shift assignments.

Core attributes include an internal ID, employee code, first and last name,
nickname, department, position, and active state. Identity comparisons use the
internal ID. Search may match names, nickname, employee code, and position.

## Department

A department groups employees and schedule requirements within an organizational
unit. It has an ID, stable code, and display name.

Department capacity limits the number of assignments a department may carry on
a date. Coverage requirements specify how many employees from a department are
needed for a shift.

## Shift

The canonical domain type is `ShiftType`. It describes reusable shift metadata:
ID, code, name, ARGB color value, start time, end time, and working hours.

Times are durations from midnight. An end time at or before the start time means
the shift ends the following day. A `ShiftAssignment` connects one Employee to
one ShiftType on a ScheduleDay and may include a remark and location.

Legacy workflow code also contains a calendar-oriented `Shift` model. New domain
work must use `ShiftType` and adapt legacy values at boundaries.

## Schedule

A Schedule is the aggregate root for named scheduling data. It owns immutable
ScheduleMonth values. Each ScheduleMonth owns normalized ScheduleDay values, and
each ScheduleDay owns its assignments.

Schedule updates replace immutable months or days. Services must not expose
mutable internal collections.

Manual assignment validates availability, overlap, duplicate, and capacity
constraints before producing an updated schedule. Automatic assignment is
currently deterministic and coverage-driven; it is not yet an optimization
solver.

## Import Profile

An ImportProfile stores a named mapping from source columns to domain fields,
with an ID and creation/update timestamps.

Profiles are domain values. Workbook decoding, file selection, and profile
persistence belong behind import services and repositories. Imported data must
be validated before becoming schedule entities.

## Rule

A Rule is a reusable policy with a stable ID, name, category, severity, and an
evaluation operation. Categories currently cover workload, night shifts, rest,
weekends, holidays, departments, locations, and custom policies.

A RuleViolation identifies the rule, employee when applicable, date when
applicable, message, severity, and category.

## Rule Engine

The RuleEngine registers and removes rules and evaluates a full Schedule, a
proposed ShiftAssignment, or one Employee's schedule.

RuleResult separates warnings and errors, reports all violations, lists passed
rules, and considers validation passed when no error-severity violations exist.
Rules must remain deterministic, side-effect free, and explainable so the same
engine can support manual editing, automated generation, and future AI tooling.

## Calendar

Calendar is the time-based presentation and synchronization boundary for a
validated schedule. Month, week, and day views derive from canonical Schedule
data.

Calendar synchronization must compare desired and existing events, detect
conflicts, preview changes, and require approval before writing. External event
identifiers and provider-specific color IDs must remain infrastructure details.

## Google Sheets

Google Sheets is an external roster source. Access is read-only by default and
uses ownership and permission checks before data is accepted.

Sheet rows should enter the same mapping, import, validation, and schedule
creation pipeline as local Excel data. Spreadsheet IDs, worksheet names, API
errors, and quota state belong in infrastructure/application layers, not domain
entities.

## Google Calendar

Google Calendar is an external destination for approved schedule events.

The integration must:

- request the minimum required scopes;
- compare before writing;
- avoid duplicate events through stable identifiers;
- surface overlap and OFF-period conflicts;
- support retries and partial failures;
- record auditable outcomes; and
- never write without explicit user confirmation.

The domain-facing boundary is `CalendarSyncService`; Google API clients and
provider payloads remain infrastructure concerns.
