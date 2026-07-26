# SCE 3.0 Implementation Map

สถานะนี้ใช้สำหรับวางแผน migration จาก repository ปัจจุบัน โดยต้องตรวจซ้ำ
หลังแต่ละ phase

| Capability | Current status | Existing production boundary | Next action |
|---|---|---|---|
| Canonical roster | Complete foundation | `domain/entities/schedule.dart`, `ScheduleRepository` | Extend metadata without breaking schema |
| Responsive shell | Partial | `app.dart`, `ui/app_shell.dart` | Align six destinations and extract pages |
| Dashboard | Partial | `_DashboardPage` in `app_shell.dart` | Move to feature and add SCE cards |
| Schedule views | Partial | `features/schedule/` | Adopt as roster viewer/editor |
| Employee directory | Domain partial | canonical employee entities | Add repository/controller/UI |
| Shift exchange | Domain/service partial | `features/shift_exchange/` | Add repository, workflow and UI |
| Reports/A4 | Partial production slice | `features/reports/` | Add report families and exports |
| Settings | Partial legacy | `_SettingsPage`, settings services | Split workspace/profile/template settings |
| Rule engine | Strong foundation | `RuleEvaluator`, validation service | Configurable registrations and severities |
| Conflict engine | Partial | schedule generation/conflict services | Canonical conflict result boundary |
| Policy engine | Missing | none | Implement after rule/conflict contract |
| Preview engine | Partial | simulation and calendar preview | Unify bulk-operation preview semantics |
| Excel import | Production foundation | `features/excel_import/` | Extend source metadata and preview |
| Google Sheets | Partial | gateway and import adapter | Range/mapping/checksum/incremental history |
| Google Calendar | Production foundation | workflow/calendar sync modules | User-only selection, offline queue |
| Payroll/OT | Missing | no canonical payroll aggregate | Implement after templates and employees |
| Notifications | Partial | legacy alerts | Add repository and delivery channels |
| Permissions | Domain foundation | access-control module | Wire policies to active routes/actions |
| Audit/history | Partial | audit and sync history modules | Cover roster/exchange/payroll/profile |
| Workspace/profile | Domain foundation | tenancy/organization modules | Add persisted workspace isolation |
| Backup/restore | Missing | none | Versioned profile/roster backup |
| Localization | Partial | generated Thai/English l10n | Remove remaining active hard-coded strings |
| CI/release | Strong foundation | `.github/workflows/` | Keep all platform builds green |

## Immediate order

1. Keep release workflows green, including Android.
2. Extract top-level navigation and Dashboard from legacy `AppShell`.
3. Introduce Employee Directory through canonical abstractions.
4. Complete canonical roster editor and shift-template configuration.
5. Add configurable Conflict/Policy/Preview boundaries.
