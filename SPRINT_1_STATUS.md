# Sprint 1 Status

## Completed in this increment

- Authentication contracts and controller
- Google Sign-In service scaffold
- OAuth scope definitions
- Authorized Google API client factory
- Drive API spreadsheet listing
- Original/current roster selection state and UI
- Typed Sheets spreadsheet snapshot reader
- Calendar access verification gateway
- Google setup and API foundation documentation
- ADRs for authentication and Drive selection

## Current selection workflow

```text
Signed-in Google account
    -> Load Google Sheets files from Drive
    -> Select original roster
    -> Select current roster
    -> Enable Compare when files are different
```

## Not yet complete

- Real OAuth client IDs and platform configuration
- Web GIS-rendered sign-in button
- Official Google Picker integration for every platform
- Extraction of cell colors and merged ranges
- Original/current spreadsheet comparison
- Calendar event synchronization
- Windows/Linux OAuth validation

## Validation status

Flutter is not installed in the current generation environment, so `flutter pub get`,
`flutter analyze`, and `flutter test` have not been executed here. GitHub Actions or a
Flutter-enabled workstation must validate the generated source before merge.
