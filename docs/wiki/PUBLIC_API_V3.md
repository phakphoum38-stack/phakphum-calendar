# Public API v3 Foundation

The API layer uses correlation IDs, structured errors, cursor pagination and tenant-scoped idempotency.

## Planned endpoints

- `POST /v3/tenants/{tenantId}/shifts/import`
- `GET /v3/tenants/{tenantId}/departments/{departmentId}/schedule`
- `POST /v3/tenants/{tenantId}/shift-exchanges`
- `POST /v3/tenants/{tenantId}/shift-exchanges/{id}/approve`
- `GET /v3/tenants/{tenantId}/audit-events`
- `GET /v3/admin/tenants/{tenantId}/metrics`

Write endpoints should accept an `Idempotency-Key` header. Authentication and permission checks must happen server-side before application services are called.
