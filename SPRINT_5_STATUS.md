# Sprint 5 Status — Real Roster Parser

Completed:
- Parser profile based on the supplied hospital workbook
- Thai Buddhist period parsing
- Flexible date-header row detection
- Portable/IPD/CT-IPD/CT-ER/ER row parsing
- Stable roster position keys
- Original/current assignment comparison
- Received and given-away classification for user aliases
- Unit tests and ADR-0012

The supplied workbook established that staff text, not cell fill, is the primary assignment signal.

Validation commands:
```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
