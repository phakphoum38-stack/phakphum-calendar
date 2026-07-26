# Shift Tools Laravel API

Laravel provides operational health and diagnostic endpoints and is the future
server-side boundary for authenticated Shift Tools APIs. The Flutter
application remains usable without this service; adding the backend does not
change schedule persistence or Google Calendar synchronization.

## Requirements

- PHP 8.4.1 or later
- Composer 2
- SQLite for local development, or another Laravel-supported database

## Local setup

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate
php artisan serve
```

The default development URL is `http://127.0.0.1:8000`.

## API

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/api/v1/health` | Process liveness |
| `GET` | `/api/v1/ready` | Database readiness |
| `POST` | `/api/v1/diagnostics/client-errors` | Rate-limited, validated client error report |

Every API response includes `X-Request-ID`. A valid caller-supplied request ID
is preserved; otherwise the API creates a UUID.

The diagnostics endpoint intentionally does not accept credentials, Google
tokens, roster rows, employee details, or schedule payloads. Do not add
scheduling write endpoints until server-side authentication, tenant
authorization, and idempotency are implemented.

## Validation

```bash
composer validate --strict
vendor/bin/pint --test
php artisan test
```

The same checks run in `.github/workflows/laravel.yml`.
