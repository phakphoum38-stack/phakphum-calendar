# Shift Tools Security Policy

## Reporting vulnerabilities

Do not open a public issue for vulnerabilities involving credentials, OAuth,
personal roster data, authorization, tenant isolation, or external writes.
Report privately to the repository owner or configured private security channel.

Include the affected version, platform, reproduction steps, impact, and a
synthetic proof of concept. Never send real access tokens, secrets, employee
data, or production spreadsheet/calendar content.

## Supported versions

Security fixes target the actively developed branch and latest supported
release. Users should update to a current verified artifact.

## Security principles

### Least privilege

- Request only scopes needed for the active operation.
- Keep roster and metadata reads read-only.
- Request write access only after an explicit write action.
- Re-check ownership and authorization at sensitive boundaries.

### Explicit writes

Importing, previewing, comparing, validating, or generating must not write to
Google services. External changes require a clear action, preview, conflict
check, confirmation, and auditable result.

### Data minimization

- Do not embed account details, roster content, URLs, tokens, or credentials.
- Keep local workbooks in memory unless persistence is explicitly designed.
- Store only necessary device-scoped references.
- Keep sensitive data out of logs, analytics, audit messages, and errors.

### Secrets

- Never commit OAuth secrets, service-account keys, tokens, signing keys, or
  environment files.
- Use platform secure storage and CI secret facilities.
- Rotate exposed credentials immediately.

### Authorization and tenancy

- Scope records by stable organization/tenant identity.
- Enforce authorization in application/domain services, not only UI visibility.
- Reject cross-tenant identifiers.
- Audit privileged actions without storing sensitive payloads.

## Input and file safety

- Accept only supported file types and validate content.
- Bound workbook size, worksheet dimensions, and preview payloads.
- Treat formulas, filenames, hyperlinks, and cells as untrusted.
- Never execute workbook macros or shell commands.
- Sanitize values before logs, URLs, or provider requests.

## Provider and network safety

- Use HTTPS endpoints and validate OAuth state/redirect configuration.
- Handle revoked tokens, rate limits, timeouts, and partial failures.
- Use stable idempotency identifiers when retries could duplicate writes.
- Do not retry destructive actions blindly.

## Local storage

Shared preferences are suitable only for non-secret settings and opaque
references. Tokens require platform secure storage. Document retention and
deletion for persisted schedules or roster data.

## Dependencies and releases

- Prefer maintained, narrowly scoped packages.
- Review transitive dependencies and permissions.
- Protect signing credentials and build through controlled CI.
- Publish checksums where supported.
- Run format, analysis, tests, and relevant platform builds before release.

## Incident response

1. Contain access and disable affected credentials.
2. Preserve safe diagnostic evidence.
3. Identify affected versions and data.
4. Patch and test the root cause.
5. Rotate credentials or invalidate sessions.
6. Notify affected users appropriately.
7. Document preventive follow-up after coordinated disclosure.
