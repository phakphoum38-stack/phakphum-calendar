# Sprint 2 Status — Shift Parser Foundation

## Completed

- Stable internal spreadsheet models
- A1 coordinate generation
- Effective value extraction
- Formula extraction
- Effective background-color extraction
- Number-format extraction
- Merged-range extraction
- Merged anchor calculation
- Snapshot normalization
- Parser contracts
- Configurable color matching
- Foundation unit tests

## Required before real roster parsing

A representative Google Sheets roster or sanitized exported structure is needed
to confirm:

- where dates are stored;
- whether shifts are organized by row or column;
- where employee names are stored;
- how categories and periods are labeled;
- exact color RGB values;
- how combined color meanings are represented;
- whether conditional formatting affects effective colors;
- how the user's own name is written.

## Validation status

Flutter SDK is not installed in the generation environment. Therefore the source
has not been compiled here. Run GitHub Actions or these commands locally:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
