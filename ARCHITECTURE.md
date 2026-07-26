# Shift Tools Architecture

## Overview

Shift Tools is a cross-platform Flutter application for importing, validating,
reviewing, generating, and synchronizing staff schedules. The target design uses
domain-driven Clean Architecture while mature roster/calendar workflows migrate
incrementally.

## Goals

- Keep scheduling policy independent from Flutter and provider SDKs.
- Reuse canonical entities across Excel, Sheets, UI, rules, generation, and
  calendars.
- Make external writes explicit, previewable, and auditable.
- Keep features independently testable through constructor injection.

## Layers

### Domain

`lib/domain/` owns canonical entities, repository contracts, and external-service
interfaces. It must not depend on Flutter UI or Google provider payloads.

Canonical entities include Employee, Department, ShiftType, ShiftAssignment,
Schedule, ScheduleDay, ScheduleMonth, and ImportProfile.

### Core

`lib/core/` contains cross-cutting primitives: typed results/failures, controller
state contracts, dependency composition, Google authorization helpers, and
bounded utilities. Feature-specific behavior does not belong in core.

### Features

Bounded contexts live under `lib/features/` and may contain:

```text
feature/
├── domain/
├── application/
├── data/ or infrastructure/
└── presentation/
```

Each completed feature includes models, a service, a controller, tests, and
documentation.

### Presentation

Flutter presentation uses Material 3. ChangeNotifier controllers expose
`loading`, `error`, `success`, and `message`. Widgets format and display state;
they do not own parsing, persistence, scheduling policy, or provider decisions.

### Infrastructure

Infrastructure owns file pickers, workbook bytes, local persistence, HTTP,
Google clients, OAuth payloads, and platform adapters. It implements domain
contracts and converts provider failures into typed failures.

## Dependency direction

```text
Presentation → Application → Domain
Infrastructure ────────────→ Domain contracts
Core primitives ───────────→ all layers
```

The domain never depends on presentation or infrastructure.

## Dependency injection

Dependencies are created at composition boundaries and passed through
constructors. `AppDependencies` is a typed composition container, not a global
service locator. Avoid runtime `get<T>()`, global mutable registries, and
unjustified singletons.

## Main flows

### Import

```text
Select source → Read workbook/sheet → Preview → Map columns
→ Convert rows → Report issues → Create canonical schedule data
```

Excel behavior must remain compatible. Import-profile persistence and the final
canonical schedule adapter remain migration work.

### Validation

```text
Schedule / Assignment / Employee → RuleEngine
→ errors + warnings + passed rules → user review
```

Rules are deterministic, side-effect free, and identified by stable IDs.

### Generation

```text
Employees + ShiftTypes + Availability + Coverage + Capacity
→ manual/automatic assignment → conflicts → GenerationResult
```

Automatic assignment is deterministic and constraint-aware, not yet an
optimization solver.

### Calendar synchronization

```text
Validated schedule → desired events → compare existing events
→ preview diff/conflicts → explicit confirmation → guarded write → history
```

Importing or previewing must never trigger an external write.

## Legacy migration

Established code remains in `lib/models/`, `lib/services/`, `lib/controller/`,
and `lib/ui/`. Do not rewrite it wholesale. Add adapters at boundaries, move
ownership toward canonical entities, and preserve regression tests.

## Security and data

Roster data may contain personal information. Minimize persistence, request the
least Google scope, avoid sensitive logs, and require explicit confirmation for
external changes. See [SECURITY.md](SECURITY.md).

## Constraints

- Public classes require DartDoc.
- Source files remain below 500 lines.
- Prefer composition over inheritance.
- Avoid unjustified singletons.
- Every change passes format, analysis, and the complete test suite.
