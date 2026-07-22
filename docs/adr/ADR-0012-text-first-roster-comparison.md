# ADR-0012: Use worker text before cell color for roster comparison

- Status: Accepted
- Date: 2026-07-22

## Context

The supplied hospital workbook uses many fills and font styles. Inspection shows
that the same person's name is often displayed with a consistent visual style.
Consequently, cell color is primarily a staff-identity aid rather than a transfer
relationship signal.

## Decision

Parse worker names from cell text and compare original/current assignments at a
stable position key composed of date, category, period, and slot.

Preserve background color as metadata only.

## Consequences

- Exchanges can be detected without guessing color semantics.
- The parser is resilient to style changes.
- Name normalization and aliases become important.
- Combined or special color rules may still be added later as secondary evidence.
