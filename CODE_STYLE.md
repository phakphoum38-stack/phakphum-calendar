# Shift Tools Code Style

`dart format` and `flutter_lints` are authoritative. Resolve all analyzer
findings before handoff.

## Dart

- Use null-safe Dart and stable Flutter APIs.
- Prefer `final` and immutable values; use `const` when meaningful.
- Avoid `dynamic`, forced unwraps, and unchecked casts.
- Model valid absence explicitly and validate external input at boundaries.
- Use typed `Result<T>` failures at repository and integration boundaries.
- Never silently catch exceptions.

## Naming

| Element | Convention | Example |
| --- | --- | --- |
| Classes and enums | `PascalCase` | `ScheduleController` |
| Variables and methods | `lowerCamelCase` | `validateSchedule` |
| Files and folders | `snake_case` | `rule_validation_page.dart` |
| Private declarations | Leading underscore | `_loadMonth` |

Pages end in `Page`; controllers, repositories, and services use their respective
suffixes. Avoid vague names such as `Manager`, `Helper`, `Utils`, or
`CommonWidget`.

## Files and imports

- Keep every source file below 500 lines.
- Prefer one primary public responsibility per file.
- Group Dart, package, then project imports.
- Remove unused imports, exports, dead code, and TODO placeholders.
- Avoid barrel files that obscure ownership or create dependency cycles.

## DartDoc

Every public class requires DartDoc describing its responsibility. Document
non-obvious methods, invariants, units, side effects, ownership, and failure
behavior. Comments should explain why, not narrate the code.

## Architecture

- Domain code must not import Flutter presentation libraries.
- Application services coordinate use cases.
- Infrastructure implements domain contracts.
- Widgets depend on controllers/application abstractions.
- Prefer composition and explicit constructor injection.
- Do not introduce global service locators or unjustified singletons.

## ChangeNotifier

Controllers expose `loading`, `error`, `success`, and `message`. Keep new mutable
state private and expose unmodifiable collections. Notify listeners once per
coherent transition. Controllers must not navigate or show dialogs.

## Material 3

- Use `ThemeData(useMaterial3: true)` and the shared `ColorScheme`.
- Keep business logic outside widgets.
- Use focused reusable widgets.
- Support phones, landscape, desktop widths, text scaling, keyboard access,
  semantics, scrolling, and overflow.
- Dispose resources owned by stateful widgets.

## Async and errors

- Prefer `async`/`await`.
- Prevent duplicate work while loading.
- Check `mounted` before using widget context after an async gap.
- Preserve failure causes and stack traces where safe.
- Keep user messages actionable and free of tokens or sensitive identifiers.
- Require confirmation before destructive or external writes.

## Performance

- Use builders for potentially large lists and grids.
- Do not decode files, call APIs, or aggregate large data in `build`.
- Avoid unbounded payloads and repeated hot-path scans.
- Add caches only after measurement and document invalidation.

## Repository safety

Do not rename platform/package identifiers or modify Google/Firebase
configuration without authorization. Preserve unrelated work and do not commit
unless explicitly requested.
