# Reusable Shift Tools Prompts

Replace bracketed values before using a prompt. Preserve the repository's current
branch and uncommitted work unless the task explicitly says otherwise.

## Review

```text
You are reviewing the Shift Tools Flutter repository.

Scope:
[files, feature, or diff]

Review for correctness, regressions, null safety, domain-boundary violations,
Material 3 behavior, performance, security/privacy, and missing tests.

Project requirements:
- Preserve Excel Import and existing behavior.
- Public classes require DartDoc.
- No file may exceed 500 lines.
- Prefer composition and constructor injection.
- Do not modify files.

Return findings ordered by severity with file and line references. Include test
gaps and residual risks. If no issues are found, state that explicitly.
```

## Refactor

```text
Refactor [scope] in Shift Tools.

Goal:
[desired architecture or maintainability outcome]

Constraints:
- Preserve behavior and all tests.
- Use canonical domain entities and Clean Architecture.
- Prefer composition over inheritance.
- Avoid global service locators and unjustified singletons.
- Add DartDoc to every public class.
- Keep every file under 500 lines.
- Do not commit.

First inspect callers and tests. Make the smallest coherent refactor, then run:
dart format .
flutter analyze
flutter test
git diff --check

Return changed files, architectural impact, validation results, and remaining
migration work.
```

## Testing

```text
Add production-quality tests for [feature or behavior] in Shift Tools.

Cover:
- successful behavior;
- invalid and null/empty input;
- boundary values;
- duplicates and conflicts;
- controller loading/error/success/message states;
- responsive widget behavior where UI is involved; and
- regression behavior for affected existing features.

Use deterministic dates and injected fakes. Do not call live Google APIs or
modify production behavior solely to satisfy tests.

Run dart format ., flutter analyze, and flutter test. Do not commit.
Return tests created, cases covered, and validation results.
```

## Architecture

```text
Inspect the Shift Tools architecture for [area].

Evaluate:
- domain ownership and aggregate boundaries;
- dependency direction;
- repository and service interfaces;
- application use cases;
- ChangeNotifier state consistency;
- dependency injection;
- legacy-to-domain adapters;
- testability; and
- files approaching 500 lines.

Do not modify files unless explicitly requested. Produce a target tree, current
gaps, a staged migration plan, risks, and the smallest safe next step.
```

## Feature implementation

```text
Implement [feature] in Shift Tools.

Required feature components:
- models/domain values;
- service or application use case;
- ChangeNotifier controller exposing loading, error, success, and message;
- Material 3 UI only when requested;
- unit and widget tests as applicable; and
- feature documentation.

Engineering rules:
- Use Clean Architecture and canonical domain entities.
- Prefer composition and constructor injection.
- Add DartDoc to every public class.
- Keep every file under 500 lines.
- Preserve Excel Import and all existing behavior.
- Do not introduce dead code, TODO placeholders, or unjustified dependencies.
- Do not commit.

Validate with:
dart format .
flutter analyze
flutter test
git diff --check

Return the architecture tree, created and modified files, behavior implemented,
validation results, known limitations, and the recommended next step.
```
