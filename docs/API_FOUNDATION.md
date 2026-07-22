# Google API Foundation

## Implemented contracts

- Authorized Google client factory
- Drive spreadsheet listing
- Sheets spreadsheet snapshot reader
- Calendar access verification

## Data access

Drive query:

```text
mimeType='application/vnd.google-apps.spreadsheet' and trashed=false
```

Sheets are requested with grid data because SCE eventually needs:

- effective cell values;
- formatting;
- background colors;
- merged ranges;
- row and column coordinates.

The current snapshot model stores effective values first. Color and merge extraction are
the next parser-foundation increment.

## Authorization behavior

The client factory first checks whether required scopes were already granted.
Interactive authorization is requested only when necessary.

On web, access tokens expire and API failures must be able to trigger reauthorization.
