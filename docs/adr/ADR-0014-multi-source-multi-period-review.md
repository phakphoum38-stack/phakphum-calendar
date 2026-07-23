# ADR-0014: Multi-source, multi-period roster review

- Status: Accepted
- Date: 2026-07-23

## Decision

The roster review workflow can combine an unlimited set of user-selected
month/year periods. Google Sheets remain read-only and account-owned. Local
`.xlsx`, `.csv`, `.tsv`, and `.txt` files are decoded in memory and passed to
the same roster parser.

Items copied from a photo, camera, website, or another Workspace tool require
explicit user entry and review. The app does not guess medical duty data with
an unspecified OCR service.

Per-item title, time, category, inclusion, and Calendar color overrides live in
the current app session. They never modify the source Sheet or local file.

## Reason

One parser and one guarded Calendar preview keep duplicate detection, OFF
generation, collision checks, and final confirmation consistent across source
types. Keeping local source bytes, names, and review choices out of the audit
log and repository preserves the project's privacy boundary.

## Consequences

- Auto refresh runs only for the selected owned Google Sheet; local files
  require the user to select them again.
- Local files are not uploaded to Drive automatically, even when monthly
  source archiving is enabled.
- Calendar events that collide can be opened or deleted only from an explicit
  conflict item, and deletion requires a user confirmation.
