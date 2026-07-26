# Contributing to Shift Tools

Thank you for improving Shift Tools. Contributions must be focused, testable,
secure, and compatible with the existing Excel and calendar workflows.

## Before starting

Read [ARCHITECTURE.md](ARCHITECTURE.md), [CODE_STYLE.md](CODE_STYLE.md),
[TESTING.md](TESTING.md), and [SECURITY.md](SECURITY.md). Then inspect the branch
and working tree:

```sh
git branch --show-current
git status
flutter --version
```

Preserve unrelated local changes. Do not change package IDs, bundle IDs, import
paths, OAuth/Firebase configuration, or platform identifiers unless explicitly
authorized.

## Development setup

```sh
flutter pub get
flutter analyze
flutter test
```

Use a stable Flutter SDK compatible with `pubspec.yaml`. Native builds require
the relevant platform toolchain.

## Scope and branches

- Use a descriptive branch such as `feature/import-profiles`.
- Keep each change centered on one coherent outcome.
- Separate mechanical refactors from behavioral changes when practical.
- Never add credentials, tokens, personal roster data, or build output.
- Do not commit or push unless the active task explicitly authorizes it.

## Feature requirements

Every feature must include:

- models or typed domain values;
- a service or application use case;
- a controller exposing `loading`, `error`, `success`, and `message`;
- tests; and
- documentation.

Every public class requires DartDoc. No source file may exceed 500 lines.

## Architecture expectations

- Keep canonical entities and contracts in `lib/domain/`.
- Organize bounded contexts under `lib/features/`.
- Keep domain code independent from Flutter UI and provider SDKs.
- Put external systems behind repository or service interfaces.
- Prefer composition and explicit constructor injection.
- Avoid global mutable state, runtime service lookup, and unjustified singletons.
- Migrate legacy code incrementally with regression coverage.

## Workflow

1. Inspect existing callers, contracts, and tests.
2. Define the smallest coherent design.
3. Add tests with the implementation.
4. Update relevant documentation and `CHANGELOG.md`.
5. Run required validation.
6. Review the diff for secrets, accidental platform changes, and unrelated work.

## Required validation

```sh
dart format .
flutter analyze
flutter test
git diff --check
```

Run affected platform builds when changing native plugins, authentication,
permissions, packaging, or release configuration.

## Testing

Use fixed dates and injected fakes. Do not call live Google APIs. Cover success,
failure, empty, boundary, duplicate, conflict, and responsive UI behavior.
Preserve all existing tests. See [TESTING.md](TESTING.md).

## Documentation

Update documentation when behavior, architecture, dependencies, setup, security
boundaries, or roadmap status changes. Keep root documentation and `.codex/`
context consistent.

## Review checklist

- [ ] Scope is focused and behavior is intentional.
- [ ] Dependency direction is preserved.
- [ ] Public APIs have DartDoc.
- [ ] Source files remain below 500 lines.
- [ ] Loading, empty, error, and success states are handled.
- [ ] No secrets or personal roster data are present.
- [ ] Focused and full tests pass.
- [ ] Documentation and changelog are current.
