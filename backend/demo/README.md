# Backend demo (PHP + MySQL)

This folder contains a minimal Docker Compose setup to run a small PHP demo API
and a MySQL server for local development and testing.

Services:
- `api` (PHP + Apache) served on http://localhost:8080
- `db` (MySQL 8) on port 3306

Quick start:

```bash
cd backend/demo
docker compose up --build -d

# Check API
curl http://localhost:8080/
curl http://localhost:8080/health

# Create a swap request (example)
curl -X POST http://localhost:8080/swap \
  -H "Content-Type: application/json" \
  -d '{"origin":"Ton","swap":"A","receiver":"B"}'

# List recent swap requests
curl http://localhost:8080/swap

# Stop
docker compose down
```

Notes:
- The demo uses a simple PHP file and a MySQL init script which creates the
  `phakphum` database and `swap_requests` table. It is intended for local demo
  purposes only and not for production use.
- You can change the MySQL root password in `docker-compose.yml` if desired.
