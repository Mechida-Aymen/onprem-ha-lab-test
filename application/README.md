# Demonstration application

This is a small Python HTTP service for the high-availability lab. It uses Python's standard HTTP server plus Debian's packaged `psycopg2` PostgreSQL driver. The Ansible `application` role installs it on both web nodes as the hardened `onprem-ha-app.service` systemd unit.

## Endpoints

- `GET /` returns the responding node's hostname and application version.
- `GET /health` returns HTTP 200 and a small health response for Ansible and HAProxy.
- `GET /db-health` verifies a real query against the PostgreSQL primary without exposing credentials.
- Unknown paths return HTTP 404.

The service listens on port `8080` by default. It runs as the unprivileged `onprem-app` account and cannot modify its own root-owned source code.

