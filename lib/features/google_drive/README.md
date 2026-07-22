# Google Drive module

The domain contract for selecting a Google Sheets roster exists.

The concrete Google Drive Picker implementation is intentionally pending because:

- Web uses Google Picker JavaScript integration.
- Android, iOS, macOS, Windows, and Linux require a compatible selection strategy.
- OAuth client IDs and authorized origins must be supplied by the project owner.
- The exact cross-platform UX must be confirmed before implementation.

Do not replace the requested Drive Picker with an unrelated local file picker.
