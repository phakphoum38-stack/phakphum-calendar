# Google Cloud and OAuth Setup

## Required APIs

Enable these APIs in the Google Cloud project:

1. Google Drive API
2. Google Sheets API
3. Google Calendar API

## OAuth scopes planned by SCE

```text
https://www.googleapis.com/auth/drive.readonly
https://www.googleapis.com/auth/spreadsheets.readonly
https://www.googleapis.com/auth/calendar.events
```

Drive and Sheets are read-only. Calendar access is limited to event management.

## OAuth clients

Create separate OAuth client configurations as required for:

- Web
- Android
- iOS
- macOS

Desktop support for Windows and Linux needs a confirmed OAuth flow and should not be
declared complete until tested on those platforms.

## Security rules

- Never commit client secrets, refresh tokens, private keys, or downloaded secret files.
- Web client IDs are identifiers and may be configured through build-time values.
- Restrict authorized JavaScript origins and redirect URIs to actual development and production URLs.
- Keep the OAuth consent screen in Testing until the approved tester accounts are added.
- Request permissions incrementally when practical.

## Build-time configuration

The current scaffold accepts placeholders through Dart defines:

```bash
flutter run \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_SERVER_CLIENT_ID
```

No real credentials are included in this repository.
