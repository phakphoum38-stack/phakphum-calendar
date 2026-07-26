# Employee Directory

The directory reads employees from the canonical `Schedule` through
`EmployeeDirectoryService` and merges them with a versioned production
`EmployeeRepository`. Persisted employees override matching schedule identities,
which keeps deactivation and corrected profile details stable without rewriting
historical assignments.

Phase 2 supports search, department and active-state filters, create/edit, and
soft deactivation. The repository uses a dedicated two-slot SharedPreferences
key so a failed staged write cannot replace the last active employee payload.

Availability, leave, permissions, employee-specific rates, profile images, and
bulk import/export remain later SCE 3.0 phases.
