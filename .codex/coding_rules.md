# Shift Tools Coding Rules

## Flutter best practices

- Use null-safe Dart and current stable Flutter APIs.
- Keep widgets focused, immutable where possible, and cheap to rebuild.
- Put business decisions in domain/application code, not widget callbacks.
- Dispose controllers, focus nodes, streams, and other owned resources.
- Use `const` constructors where they improve correctness and rebuild cost.
- Preserve behavior and passing tests during refactors.

## Material 3

- Build with `ThemeData(useMaterial3: true)`.
- Use the application `ColorScheme` instead of hard-coded semantic UI colors.
- Prefer Material 3 components such as `NavigationBar`, `SegmentedButton`,
  `FilledButton`, and `Card`.
- Support narrow phones, landscape layouts, desktop widths, keyboard access,
  tooltips, and readable semantics.

## Clean Architecture

- Domain entities and contracts must not import Flutter presentation libraries.
- Application services coordinate use cases and domain behavior.
- Infrastructure implements domain repositories and external-service contracts.
- Presentation depends on controllers and application abstractions.
- Dependencies point inward toward the domain.
- Prefer explicit constructor injection and composition over inheritance.
- Do not introduce global mutable state or an unjustified singleton.

## ChangeNotifier usage

- Use `ChangeNotifier` only for presentation/application state that has listeners.
- Controllers implement the shared `ControllerState` contract.
- Expose `loading`, `error`, `success`, and `message`.
- Keep mutable fields private when introducing a new controller.
- Expose immutable lists, maps, and sets.
- Perform state transitions in named methods and notify once per coherent change.
- Controllers must not perform direct widget navigation or show dialogs.

## Widget naming

- Use descriptive PascalCase nouns: `ScheduleGrid`, `ViolationTile`.
- Pages end in `Page`; reusable panels and controls describe their role.
- Private implementation widgets begin with `_`.
- Avoid names such as `CommonWidget`, `HelperWidget`, or numbered variants.

## File naming

- Use lowercase `snake_case.dart`.
- Prefer one primary public concept per file.
- Match the primary class and filename: `RuleEngine` in `rule_engine.dart`.
- No source file may exceed 500 lines; split by responsibility before that point.

## Folder naming

- Use lowercase `snake_case`.
- Feature folders represent bounded contexts, not UI screens.
- Use `domain/`, `application/`, `data/` or `infrastructure/`, and
  `presentation/` consistently.
- Place cross-feature domain contracts in `lib/domain/`.
- Place genuinely cross-cutting technical utilities in `lib/core/`.

## Testing requirements

- Every feature includes unit tests for models/services/controllers and widget
  tests for meaningful presentation behavior.
- Test success, failure, empty, boundary, and duplicate/conflict cases.
- Use deterministic dates and injected fakes; do not depend on live APIs.
- Preserve all existing tests.
- Before handoff run:

```sh
dart format .
flutter analyze
flutter test
```

- Also run `git diff --check` when files changed.

## Performance rules

- Use builders for potentially large lists and grids.
- Avoid repeated workbook decoding, API calls, and expensive computation in
  `build`.
- Keep payloads bounded and avoid unnecessary object copies in hot paths.
- Use immutable collections at public boundaries.
- Support scrolling and overflow at phone and desktop sizes.
- Profile before adding caches; document ownership and invalidation when caching.

## Error handling

- Return typed `Result<T>` values at repository and external-service boundaries.
- Use `ValidationFailure`, `NetworkFailure`, or `ImportFailure` when applicable.
- Never silently swallow errors.
- Present actionable user messages without leaking tokens, identifiers, or
  sensitive source data.
- Preserve the original cause and stack trace for diagnostics where safe.
- Destructive and external writes require clear user intent and confirmation.

## Null safety

- Do not use forced unwraps unless an invariant is locally proven.
- Prefer required parameters and explicit defaults.
- Model absence with nullable values only when absence is valid domain state.
- Validate external and imported data before creating domain entities.
- Avoid `dynamic`; use typed records, sealed types, or explicit adapters.

## Documentation rules

- Every public class requires DartDoc explaining its responsibility.
- Document non-obvious public methods, invariants, units, and side effects.
- Every feature includes or updates feature documentation.
- Keep `.codex/project.md`, `.codex/domain.md`, and `.codex/roadmap.md` aligned
  with architectural changes.
- Comments explain why, not what the code already states.
- Do not leave TODO placeholders or dead documentation.

## Repository safety

- Do not rename package IDs, bundle IDs, import paths, or Firebase/Google
  configuration without explicit authorization.
- Do not commit unless the user explicitly requests it.
- Preserve unrelated uncommitted work.
