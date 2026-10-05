# Phase 4 verification results

Verification date: 2026-10-03

## Deployed service

- Service name: `onprem-ha-app.service`
- Runtime: Python 3 standard library
- Service account: `onprem-app`
- Installation directory: `/opt/onprem-ha-app`
- Listening address: `0.0.0.0:8080`
- Application version: `1.0.0`
- Managed nodes: `web01` and `web02`

The service runs without root privileges. Its source and systemd unit are owned by root, and the systemd sandbox prevents privilege escalation and restricts access to the host system.

## Endpoint verification

| Node | Endpoint | Expected result | Result |
|---|---|---|---|
| `web01` | `http://192.168.56.11:8080/` | Hostname `web01`, version `1.0.0` | Passed |
| `web01` | `http://192.168.56.11:8080/health` | Status `ok`, hostname `web01` | Passed |
| `web02` | `http://192.168.56.12:8080/` | Hostname `web02`, version `1.0.0` | Passed |
| `web02` | `http://192.168.56.12:8080/health` | Status `ok`, hostname `web02` | Passed |

The tests were executed externally from the Windows host, proving that each service listens beyond the VM's loopback interface and is reachable through the lab network.

## Ansible results

The first deployment created the application account and group, installed the application and systemd unit, started the service, enabled it at boot, and passed the built-in health assertion on each node.

The final repeated deployment produced:

```text
web01 : ok=11 changed=0 unreachable=0 failed=0
web02 : ok=11 changed=0 unreachable=0 failed=0
```

This proves that the application role is idempotent on both web nodes. Phase 4 is complete, and the application instances are ready to become HAProxy backends in Phase 5.
