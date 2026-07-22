# Project Constitution

## Article 1 — Accuracy

SCE must never silently invent names, times, relationships, colors, or shift rules.

## Article 2 — Human confirmation

No Calendar mutation may happen before a user-visible preview and confirmation.

## Article 3 — Source protection

SCE reads roster spreadsheets but does not modify the original roster file in version 1.0.

## Article 4 — Traceability

Every synchronization action must be explainable and logged.

## Article 5 — Separation of concerns

UI, parsing, business rules, synchronization, and external APIs must remain independently testable.

## Article 6 — Stable identity

Every synchronized Calendar event must contain a stable Sync ID in extended properties.

## Article 7 — Safe failure

Ambiguous or incomplete data must result in a warning or blocked action, not a guessed result.
