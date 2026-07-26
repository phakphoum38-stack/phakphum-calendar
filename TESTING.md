# Shift Tools Testing Guide

Testing protects roster accuracy, scheduling policy, privacy, and external-write
safety.

## Required commands

```sh
dart format .
flutter analyze
flutter test
git diff --check
```

Use `flutter test --coverage` when coverage output is required. A percentage is
not a substitute for meaningful assertions.

## Test layers

### Domain models

Test construction invariants, normalization, equality, serialization, immutable
updates, overnight time boundaries, and nullable/invalid states.

### Services and engines

Inject fakes for repositories, files, clocks, and provider gateways. Cover:

- success and failure;
- empty and boundary input;
- duplicates and conflicts;
- availability, capacity, and coverage;
- deterministic ordering;
- retries, partial failures, and idempotency.

### Controllers

Verify initial state and transitions for `loading`, `error`, `success`, and
`message`. Cover repeated actions, reset/cancellation, immutable output, and
listener notifications.

### Widgets

Test user-visible loading, empty, error, and success states; validation; enabled
actions; navigation; scrolling; text overflow; narrow and desktop layouts; and
confirmation before destructive/external actions.

Avoid assertions tied to incidental widget-tree structure.

### Integrations

Use integration tests or platform builds for file pickers, OAuth redirects,
plugins, persistence, provider adapters, and native configuration. Automated
tests must not call production Google accounts.

## Determinism and privacy

- Use fixed dates and injected clocks.
- Use synthetic employees, schedules, spreadsheet IDs, and events.
- Use in-memory fakes and minimal fixtures.
- Never add real names, emails, tokens, secrets, or roster files.
- Do not depend on test order or live network state.

## Regression requirements

Import changes preserve `.xlsx` validation, worksheet selection, sparse/merged
cells, preview limits, column mapping, date conversion, duplicates, issues, and
summary UI.

Schedule changes preserve month creation/navigation, assignment/deletion,
automatic generation, availability, capacity, coverage, conflict/rule behavior,
and month/week/day rendering.

Google changes verify minimum scopes, ownership, read-only defaults, stable IDs,
preview-before-write, retries, partial failures, and confirmation gates using
fakes.

## Diagnosing failures

Run one test with expanded reporting:

```sh
flutter test test/path_to_test.dart --reporter expanded
```

Fix the root cause rather than weakening assertions. Re-run focused tests, then
the full suite. Flaky tests are defects; remove nondeterminism instead of adding
arbitrary delays.
