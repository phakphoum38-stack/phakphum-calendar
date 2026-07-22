# ADR-0001: Feature-first layered project structure

- Status: Accepted
- Date: 2026-07-22

## Context

SCE must support multiple platforms and keep parsing, business rules, and Google APIs independently testable.

## Decision

Use a feature-first Flutter structure with shared domain and core modules.
Within each feature, separate presentation, application, domain, and infrastructure where needed.

## Consequences

- Features can grow independently.
- Tests can focus on domain behavior.
- Initial folder count is larger than a minimal Flutter application.
