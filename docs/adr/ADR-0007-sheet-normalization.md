# ADR-0007: Normalize Google Sheets before shift parsing

- Status: Accepted
- Date: 2026-07-22

## Context

Google Sheets API objects include API-specific value types, sparse grid data,
format details, theme colors, and end-exclusive merged ranges. Hospital business
rules should not depend directly on these API classes.

## Decision

Convert API responses into SCE-owned models:

- `SpreadsheetSnapshot`
- `SpreadsheetSheetSnapshot`
- `SheetCell`
- `SheetGridRange`
- `SheetColor`
- `ShiftParserInput`
- `NormalizedCell`

The shift parser consumes only these internal models.

## Consequences

- Parser tests do not require Google APIs.
- API package upgrades affect only the infrastructure adapter.
- Color and merged-cell behavior can be tested independently.
- A normalization step adds a small processing cost.
