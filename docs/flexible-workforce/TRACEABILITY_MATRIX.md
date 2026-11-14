# Flexible Workforce & Shift Scheduler — Phase 0 Traceability Matrix

## Audit record

- Audit target: `main` at the repository state inspected on 2026-11-14.
- Documentation branch: `docs/flexible-workforce-scheduler-foundation`.
- Scope: source and test inventory for the initial requirements baseline.
- Method: inspect the tracked-file manifest and fetch representative Dart, PHP, and test files from `main`.
- Execution: source inspection only. No Flutter, PHP, database, browser, or end-to-end test suite was executed in this audit.
- Evidence rule: source presence is not proof of runtime behavior. A test file is not a PASS until the relevant test is executed against the identified commit.
- Status vocabulary: PASS / FAIL / SKIPPED / UNKNOWN. Current verification status for all requirements below is UNKNOWN unless explicitly stated otherwise.

## Repository evidence map

| Concern | Existing source evidence | Existing test evidence | Initial finding |
|---|---|---|---|
| Employee domain | `lib/domain/entities/employee.dart`; `lib/features/employees/application/employee_directory_service.dart` | `test/employee_directory_test.dart`, `test/employee_repository_test.dart` | Employee entity exists. It currently requires a Department and stores position as a string; profession/skill/qualification model not established by these files. |
| Canonical schedule | `lib/domain/entities/schedule.dart`; `lib/domain/entities/schedule_month.dart`; `lib/domain/entities/schedule_day.dart` | `test/canonical_schedule_adapter_test.dart`, `test/schedule_json_codec_test.dart` | Canonical aggregate exists and is month/day based. Revision, approval, publication, and tenant ownership are not fields on the inspected Schedule entity. |
| Shift assignments and templates | `lib/domain/entities/shift_assignment.dart`; `lib/domain/entities/shift_template.dart`; `lib/features/shift_templates/infrastructure/shared_preferences_shift_template_repository.dart` | `test/shift_template_test.dart` | Configurable shifts and location exist. Overnight is derived from time ordering. Explicit timezone, effective-dated template versions, and skill requirements were not found in the inspected entity. |
| Schedule generation | `lib/features/schedule_generation/application/schedule_generator.dart`; `auto_assignment_service.dart`; `conflict_detection_service.dart`; `coverage_checking_service.dart` | `test/schedule_generator_test.dart` | Manual and automatic assignment, coverage, availability/capacity conflict checks exist. Generator currently chooses active employees by department and location lock; qualifications/leave and generalized multi-organization constraints need further audit. |
| Rule validation | `lib/features/rules/application/rule_engine.dart`; `schedule_validation_service.dart`; `lib/features/rule_engine/application/rule_engine.dart` | `test/rule_engine_foundation_test.dart`; `test/rule_engine_consolidation_test.dart`; `test/v2/rule_engine_test.dart` | Rule registration and schedule/employee/assignment validation exist. Hard/soft semantics, unknown handling, stable rule versioning, and approval blockers require deeper inspection. |
| Import | `lib/features/excel_import/application/import_engine.dart`; `lib/features/excel_import/data/excel_reader_service.dart`; `lib/features/excel_import/presentation/controllers/excel_import_controller.dart` | `test/import_engine_test.dart`; `test/excel_import_controller_test.dart`; `test/canonical_import_calendar_vertical_slice_test.dart` | Spreadsheet mapping, row conversion, errors, warnings, and duplicate warnings exist. Full staged import transaction, per-operation decisions, and rollback guarantees need verification. |
| Export | `lib/domain/services/export_service.dart`; `lib/features/reports/infrastructure/monthly_schedule_pdf_service.dart` | `test/monthly_schedule_pdf_service_test.dart`; `test/monthly_schedule_report_mapper_test.dart` | Export abstraction and monthly PDF reporting exist. Three-mode template/page/custom designer workflow is not evidenced by the inspected source. |
| Organization and membership | `backend/app/Http/Controllers/Api/V1/OrganizationController.php`; `backend/database/migrations/2026_11_09_000002_create_organizations_and_memberships.php`; `backend/database/migrations/2026_11_09_000003_create_organization_shift_policies.php` | `backend/tests/Feature/OrganizationApiTest.php`; `backend/tests/Feature/OrganizationJoinRequestApiTest.php` | Backend organization, membership, roles, and organization shift policies exist. Full department hierarchy and end-to-end binding to Flutter canonical schedule/workforce entities need verification. |
| Tenant guard | `lib/features/tenancy/application/tenant_guard.dart`; `lib/features/tenancy/domain/tenant.dart` | `test/tenant_guard_test.dart`; `test/v2/access_control_test.dart` | Tenant access and same-tenant guard abstractions exist. Repository-level enforcement for every workforce/schedule read and write is not established by this evidence. |
| Schedule persistence | `lib/features/schedule/data/shared_preferences_schedule_repository.dart`; `lib/features/schedule/data/schedule_json_codec.dart` | `test/schedule_repository_test.dart`; `test/schedule_json_codec_test.dart` | Canonical schedule persistence uses SharedPreferences with versioned key prefix and alternating slots. Multi-user server persistence, tenant-scoped durable storage, and migration/recovery for new entities remain unverified. |
| History and audit | `lib/features/history/infrastructure/shared_preferences_sync_history_repository.dart`; `lib/models/audit_entry.dart`; `lib/services/roster_revision_service.dart` | `test/audit_entry_test.dart`; `test/roster_revision_service_test.dart`; `test/timeline_history_regression_test.dart` | Calendar sync history, roster revision, and audit-related models exist. Complete immutable audit coverage for import/generation/approval/publication/export is not established. |
| Calendar compatibility | `lib/features/calendar_engine/application/calendar_sync_plan_builder.dart`; `lib/features/calendar_engine/application/resilient_calendar_sync_executor.dart`; `lib/features/calendar_sync/application/calendar_sync_protocol_service.dart` | `test/sce_calendar_sync_executor_test.dart`; `test/sce_resilient_calendar_sync_executor_test.dart`; `test/google_calendar_workflow_integration_test.dart` | Existing sync planning, execution, resilience, history, and regression tests exist. Must preserve existing sync IDs, previews, confirmations, and resume semantics. |

## Requirement traceability

| ID | Requirement area | Source evidence | Test evidence | Verification |
|---|---|---|---|---|
| WF-001 | Blank-by-default workspace and organization creation | Backend organization controller and migrations | Organization API tests | UNKNOWN |
| WF-002 | User-defined organization and nested department hierarchy | Organization backend evidence; department model exists in Flutter | Organization API tests; department-specific coverage not established | UNKNOWN |
| WF-003 | User-defined professions, positions, skills, and qualification validity | Employee entity has required department and string position; no inspected skill entity | No qualification-specific test identified in initial manifest review | UNKNOWN |
| WF-004 | Configurable shift definitions, overnight support, timezone and effective dates | ShiftTemplate entity and repository | Shift template tests | UNKNOWN |
| WF-005 | Configurable row/column schedule designer independent of canonical assignments | Schedule and ScheduleMonth aggregates exist; no layout module identified in initial inventory | No schedule-layout test identified | UNKNOWN |
| WF-006 | Draft generation with availability, capacity, and coverage validation | ScheduleGenerator, AutoAssignmentService, ConflictDetectionService | Schedule generator tests | UNKNOWN |
| WF-007 | Qualification, leave, location, and cross-period constraints | Availability/capacity and location lock evidence; qualification and leave integration not established | Further tests required | UNKNOWN |
| WF-008 | Hard/soft constraints with explicit unknown handling and rule versioning | RuleEngine and RuleResult/RuleViolation types | Rule engine tests | UNKNOWN |
| WF-009 | Import preview, mapping, validation, duplicate review, explicit confirmation | Excel import engine/controller and preview pages | Import engine/controller and vertical-slice tests | UNKNOWN |
| WF-010 | Import rollback/no mutation before confirmation | Import pipeline evidence exists; transaction and rollback semantics not yet inspected end-to-end | Dedicated persistence/rollback evidence not yet identified | UNKNOWN |
| WF-011 | Prebuilt Template export | ExportService abstraction and PDF reporting | PDF service tests | UNKNOWN |
| WF-012 | Generated Page export | No direct implementation evidence identified in initial source inventory | No direct test identified | UNKNOWN |
| WF-013 | Custom Design export | No direct implementation evidence identified in initial source inventory | No direct test identified | UNKNOWN |
| WF-014 | Human approval tied to exact schedule revision | Organization shift policy includes requires_approval; schedule approval lifecycle not identified | Approval lifecycle test not identified | UNKNOWN |
| WF-015 | Explicit publication separated from generation and Calendar sync | Existing Calendar workflow is separate; workforce publication lifecycle not identified | Publication lifecycle test not identified | UNKNOWN |
| WF-016 | Scoped authorization and organization isolation | Backend membership/controller and Flutter TenantGuard | Organization API and tenant guard tests | UNKNOWN |
| WF-017 | Complete audit of import/generation/approval/publication/export | Sync history, roster revision, audit model | Existing audit/history tests | UNKNOWN |
| WF-018 | Preserve personal roster and Calendar sync workflows | Existing canonical schedule adapters and Calendar engine | Calendar sync and regression tests | UNKNOWN |
| WF-019 | Backup, restore, migration, and tenant-scoped durable persistence | SharedPreferences repositories and Laravel migrations | Existing repository/migration tests require execution and broader coverage review | UNKNOWN |
| WF-020 | Windows/Web delivery and privacy-safe operation | Existing CI workflow inventory and repository security docs | Delivery checks and secret/privacy tests not executed in this audit | UNKNOWN |

## Gaps and design decisions to resolve before implementation

1. **Do not replace the existing Schedule aggregate.** Determine whether workforce-specific metadata should be added through compatible entities/adapters or a versioned extension. Preserve legacy schedule codecs.
2. **Separate workforce identity from user login identity.** Employee, organization membership, and authenticated account are related but must not be conflated.
3. **Department and position are currently constrained.** The inspected Employee entity requires a Department object and stores position as free text. Decide a backward-compatible migration path for configurable hierarchies, professions, positions, and skills.
4. **Timezone is not explicit in the inspected ShiftTemplate.** Define how local shift times, overnight shifts, DST, and effective dates are represented before adding cross-region scheduling.
5. **Generation is not approval.** Keep generated schedules as drafts; add revision-bound validation and approval only after source audit confirms no equivalent workflow exists.
6. **Import staging must be proven.** Trace the controller, repository writes, confirmation callback, and failure paths before changing import persistence.
7. **Export is broader than PDF.** Inspect all export adapters and UI routes before designing three export modes. Do not assume the abstract ExportService is a complete renderer.
8. **Tenant enforcement must be end-to-end.** A TenantGuard abstraction alone does not prove all repositories or backend queries are scoped.
9. **Avoid SharedPreferences as multi-tenant server storage.** Keep current local persistence compatible while deciding the authoritative persistence boundary for organization data.
10. **Keep Calendar sync contracts unchanged.** No generated schedule should create/update/delete Calendar events without the existing plan, preview, confirmation, guarded execution, and history flow.

## Next audit sequence

- [ ] Read complete import controller and persistence call chain; identify exact confirmation boundary.
- [ ] Read all schedule/employee/shift repositories and JSON codecs; document compatibility constraints.
- [ ] Inspect rule definitions and severity handling; map each rule to hard/soft/unknown semantics.
- [ ] Inspect all report/export routes and adapters; confirm supported file types and current PDF behavior.
- [ ] Trace backend organization authorization, migrations, policies, and Flutter API gateway.
- [ ] Inspect approval/publication and audit implementation across the entire repository; do not infer absence from one folder.
- [ ] Execute targeted Flutter and backend test suites on a checked-out exact commit; record command, commit SHA, exit code, and test counts.
- [ ] Update this matrix with exact line references and PASS/FAIL/SKIPPED/UNKNOWN evidence before any schema or runtime implementation.

## Safety constraints

- No deletion or destructive migration.
- No overwriting existing personal schedules, templates, Calendar sync IDs, or history.
- No fabricated employee or organization data in production.
- Synthetic fixtures only in isolated tests.
- No automatic publishing or Calendar synchronization from generation.
- No merge or deployment without explicit authorization.
