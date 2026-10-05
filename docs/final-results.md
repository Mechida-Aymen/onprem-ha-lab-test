# Final project results

Verification date: 2026-10-03

## Outcome

The four-VM lab meets every MVP criterion. Ansible reproducibly configures the machines, the VIP survives a web failure, HAProxy removes unhealthy applications, PostgreSQL data streams to a read-only replica, rolling deployment produced no failed requests, a backup restored deleted data, and monitoring exposes current health.

## Final evidence

- Full `site.yml` idempotence: `changed=0`, `unreachable=0`, and `failed=0` on all four nodes.
- Rolling deployment: 205 HTTP requests, zero failures.
- VIP failover: abrupt loss of `web01` produced four successful responses through `web02` after six seconds.
- Replication: a new primary row was readable on `db02` after the final reboots.
- Recovery: an intentionally deleted marker was recovered from an isolated backup restore.
- Persistence: all four nodes passed serial reboot and role-specific service checks.
- Final VIP checks: `/`, `/health`, and `/db-health` all returned HTTP 200; application version is `1.2.2`.

## What is highly available

The client entry point, load balancer, and application have automatic failover. One web VM may fail without changing the URL or stopping HTTP service. A replica outage does not stop database writes, and it catches up after recovery.

The database primary does not fail over automatically. During a primary outage, `/health` remains available but `/db-health` correctly returns 503. This is an explicit safety boundary rather than a hidden claim of full database HA.

## Operations

- Configure everything: `ansible/site.yml`
- Roll the application: `ansible/deploy.yml`
- Verify replication and DB access: `ansible/verify-database.yml`
- Create and verify a backup: `ansible/backup.yml`
- Prove restore: `ansible/restore-test.yml`
- Run controlled failures: `ansible/failure-tests.yml`
- Reboot and verify persistence: `ansible/reboot.yml`

Secrets are encrypted with Ansible Vault. Backups are locally permission-protected and checksummed, but should be encrypted and copied off `db01` before treating this as a production design.
