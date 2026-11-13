# Automatic CI detection

The CI layer now detects the project capabilities before enabling language-specific checks.

## Rules

- `pubspec.yaml` + Dart sources → Dart quality checks are enabled.
- Flutter project → Flutter SDK is used because `package:flutter/*` requires the Flutter SDK; the bundled Dart SDK is then used for formatting and analysis.
- Pure Dart project → Dart SDK is used directly with `dart pub get`, `dart format`, `dart analyze`, and `dart test`.
- No Dart sources → Dart quality checks are skipped.
- `test/` with `*_test.dart` → unit-test/coverage stage is enabled.
- `integration_test/` with Dart files → Flutter integration tests are enabled only for Flutter projects.
- Platform directories are detected independently (`web`, `windows`, `android`, `ios`, `macos`, `linux`) and reported in the workflow summary.

## Failure prevention

The workflow never assumes that `integration_test` exists and never uploads a required coverage file when tests were not detected. This prevents the previous `pathspec` and missing `coverage/lcov.info` failures.

The existing Windows and Web release workflows remain the deployment/build paths. The automatic workflow is the capability/quality gate and can safely skip language-specific work when the repository does not contain the corresponding project type.
