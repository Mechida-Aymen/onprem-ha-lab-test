# Failure tests

The executable test suite is `ansible/failure-tests.yml`. Every destructive test uses an Ansible `always` section so the stopped service is restored even when an assertion fails.

| Failure injected | Expected behavior | Observed result |
|---|---|---|
| Stop the application on `web02` | HAProxy sends every request to `web01` | Six of six requests succeeded on `web01`; service restored |
| Stop HAProxy on `web01` | Keepalived moves the VIP to `web02` | VIP response header changed to `web02`, then returned to `web01` after recovery |
| Stop PostgreSQL on `db02` | Primary remains writable; replica catches up later | Write and app DB check succeeded; row appeared on `db02` after restart |
| Stop PostgreSQL on `db01` | Stateless health stays up; DB health explicitly fails | `/health` returned 200, `/db-health` returned 503, then recovered to 200 |
| Power off the `web01` VM | `web02` takes the VIP | Four of four client requests returned 200 through `web02` after six seconds |

The full suite completed with `failed=0`. The abrupt VM test was performed with VirtualBox rather than Ansible so it also covered sudden power loss. Full measured results are in [Phase 12](../phase-12-results.md).

