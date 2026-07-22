# ADR-0003: Local storage

- Status: Proposed
- Date: 2026-07-22

## Context

SCE needs synchronization history, cached settings, mappings, and possibly offline previews.

## Proposed decision

Use SQLite through a Flutter-compatible abstraction. Store OAuth secrets only through
platform secure storage, never in SQLite.

## Confirmation required

Select the exact database package after platform compatibility is verified.
