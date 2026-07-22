# ADR-0011: Durable cross-platform sync state

- Status: Accepted
- Date: 2026-07-22

Use `SharedPreferencesAsync` behind repository contracts for bounded lightweight sync
history and resumable failed-operation payloads across all Flutter target platforms.
Do not store patient data, OAuth tokens or complete roster contents.
