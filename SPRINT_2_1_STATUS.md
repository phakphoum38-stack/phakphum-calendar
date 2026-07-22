# Sprint 2.1 Status — Relationship and Diff Foundation

## Completed

- Roster layout profile model
- Confirmed shift-time catalog
- Relationship resolver contract
- Conservative default relationship resolver
- Calendar event candidate model
- Diff engine
- Simulation summary
- Unit tests
- ADR and documentation

## What can now be tested without Google

The project can test:

- overnight date calculations;
- received and given-away relationship behavior;
- add/update/delete/unchanged Calendar classification;
- deletion when a shift no longer belongs to the user.

## Still blocked by real roster structure

The parser cannot safely produce real ShiftRecord objects until a representative roster
is supplied or its layout is documented.

Required information:

- screenshot or sanitized Sheet;
- header rows;
- date columns;
- name columns;
- shift labels;
- exact color values;
- combined-color behavior;
- CT time mappings.

## Validation status

The Flutter SDK is unavailable in the generation environment. Run:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
