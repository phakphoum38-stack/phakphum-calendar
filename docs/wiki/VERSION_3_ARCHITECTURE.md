# Version 3.0 SaaS Architecture

Version 3.0 evolves Phakphum Calendar into a multi-tenant hospital scheduling platform.

## Trust boundaries

Every organization-owned record must contain `tenantId`. Every application command must receive a `TenantContext`. Repositories, cache keys, audit events, API idempotency keys and background jobs must be scoped by tenant.

## Main modules

- `tenancy`: tenant lifecycle and isolation guard.
- `api`: stable response, pagination and idempotency contracts.
- `plugin_system`: extension manifests and tenant-scoped plugin lifecycle.
- `admin`: operational metrics for the platform administration console.
- Existing v2 modules: organization, access control, audit, shift exchange and rule engine.

## Deployment target

```text
Flutter Mobile / Web Admin
          |
      API Gateway
          |
 Auth + Tenant Resolver
          |
 Application Services
          |
 PostgreSQL / Queue / Object Storage
          |
 Calendar, Sheets, Drive and Notification adapters
```

## Non-negotiable controls

- No unscoped database query.
- No cross-tenant cache key.
- Server-side authorization for every mutation.
- Immutable audit trail for schedule and approval changes.
- Idempotency key for retried external write requests.
- Encryption in transit and at rest.
