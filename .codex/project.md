# Shift Tools Project

## Project overview

Shift Tools is a cross-platform Flutter application for importing staff rosters,
reviewing and validating shift schedules, and synchronizing approved work with
calendar systems. It runs on Web, Android, iOS, Windows, macOS, and Linux.

The repository contains the current roster-to-Google-Calendar workflow alongside
newer domain-driven foundations for Excel import, schedule visualization,
schedule generation, and reusable scheduling rules.

## Vision

Provide a safe, explainable workspace where healthcare and shift-based teams can
turn inconsistent roster sources into validated schedules without losing human
control. Automation should assist users, surface conflicts, and require explicit
approval before external calendars or shared data are changed.

## Target users

- Employees reviewing their own duties.
- Department coordinators preparing monthly rosters.
- Managers checking staffing coverage and policy compliance.
- Administrators maintaining departments, employees, and shift definitions.
- Teams importing schedules from Excel or Google Sheets.

## Major features

- Local Excel `.xlsx` selection, worksheet reading, preview, and column mapping.
- Import conversion with row-level errors, warnings, and summaries.
- Month, week, and day schedule views with filters, statistics, and zoom.
- Manual and deterministic automatic schedule assignment foundations.
- Employee availability, department capacity, and coverage checking.
- Reusable rule validation for workload, night shifts, rest, holidays, weekends,
  departments, locations, duplicates, and custom policies.
- Read-only Google Sheets roster retrieval and ownership validation.
- Google Calendar comparison, conflict review, and guarded synchronization.
- Audit, simulation, history, tenancy, access-control, and workflow foundations.

## Architecture

The target architecture follows domain-driven Clean Architecture:

1. `domain/` owns framework-independent entities, repository contracts, and
   external-service interfaces.
2. `core/` owns cross-cutting result types, state contracts, utilities, Google
   scopes, and typed dependency composition.
3. `features/` owns bounded contexts. Each feature separates domain,
   application/data, and presentation responsibilities as needed.
4. Infrastructure implementations depend on domain contracts, never the reverse.
5. Flutter presentation code depends on application controllers and domain
   values, but domain code must not depend on Flutter UI classes.

Some mature workflow code remains in `models/`, `services/`, `controller/`, and
`ui/`. New work should use the target layers and migrate legacy code
incrementally, with tests protecting behavior.

Dependency injection uses explicit constructors and the typed composition root in
`core/di/`. Do not introduce a global service locator.

## Folder structure

```text
.
├── .codex/                 # Project context, rules, roadmap, and prompts
├── android/ ios/ linux/    # Flutter platform runners
├── macos/ web/ windows/
├── docs/                   # Wiki and long-form project documentation
├── lib/
│   ├── core/               # Shared technical building blocks
│   ├── domain/             # Canonical entities and contracts
│   ├── features/           # Feature bounded contexts
│   ├── controller/         # Legacy application controller
│   ├── models/             # Legacy workflow models
│   ├── services/           # Legacy/integration services
│   ├── ui/                 # Existing application shell
│   ├── app.dart            # Material application composition
│   └── main.dart           # Runtime entry point
└── test/                   # Unit, widget, integration-style, and regression tests
```

Every new feature must include models, a controller, a service, tests, and
documentation. Public classes require DartDoc and source files must remain under
500 lines.

## Dependency overview

### Runtime

- Flutter and Material 3: cross-platform UI and application runtime.
- `excel`: decoding and reading `.xlsx` workbooks.
- `file_picker` and `file_selector`: platform file selection.
- `google_sign_in`: Google account authentication.
- `googleapis`, `googleapis_auth`, and the Google Sign-In auth bridge: Drive,
  Sheets, and Calendar APIs.
- `http`: HTTP transport.
- `shared_preferences`: local, device-scoped settings and references.
- `crypto`: deterministic identifiers and hashes.
- `intl`: date and localized display formatting.
- `url_launcher`: safe external links.

### Development

- `flutter_test`: unit and widget testing.
- `flutter_lints`: static-analysis rules.
- `flutter_launcher_icons`: platform icon generation.

Dependencies must be injected where practical, kept behind domain interfaces,
and added only when the standard library or existing packages cannot meet the
requirement safely.
