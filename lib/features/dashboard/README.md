# Dashboard

Dashboard metrics are prepared from the canonical `Schedule` by
`DashboardSummaryService`. Widgets receive a `DashboardSummary` and never
calculate scheduling data. Payroll, exchange-request counts and durable sync
telemetry will be added when their canonical repositories are available.
