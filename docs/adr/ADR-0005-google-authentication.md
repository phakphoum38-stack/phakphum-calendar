# ADR-0005: Google authentication and authorization

- Status: Accepted
- Date: 2026-07-22

## Context

SCE needs authentication plus permission to read Drive and Sheets data and manage
Google Calendar events.

## Decision

Use the official Flutter `google_sign_in` package and keep authentication separate
from authorization.

Requested scopes:

- Drive read-only
- Sheets read-only
- Calendar events

OAuth values are supplied through platform configuration or build-time settings.
Secrets must never be committed.

## Consequences

- Consent is explicit.
- Web authorization expiry must be handled.
- Platform-specific OAuth configuration is required.
- Windows and Linux flows remain pending verification.
