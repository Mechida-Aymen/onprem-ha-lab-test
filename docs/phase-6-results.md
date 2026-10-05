# Phase 6 verification results

Verification date: 2026-10-03

## Election configuration

| Node | Interface | VRRP state | Priority | Normal VIP ownership |
|---|---|---|---:|---|
| `web01` | `enp0s8` | MASTER | 150 | Yes |
| `web02` | `enp0s8` | BACKUP | 100 | No |

- Floating address: `192.168.56.100/24`
- VRRP transport: unicast over the private host-only network
- HAProxy check interval: two seconds
- Failure threshold: two failed checks
- Recovery threshold: two successful checks

The role automatically matched `enp0s8` to each node's inventory address. Both Keepalived configurations passed their built-in validation before and after activation.

## Initial election and client access

After both nodes joined the election, only `web01` displayed `192.168.56.100` on its private interface. The Windows host reached the VIP with zero ping loss and received HTTP 200 through HAProxy on `web01`.

## Idempotence

The repeated Keepalived playbook run produced:

```text
web01 : ok=15 changed=0 unreachable=0 failed=0
web02 : ok=15 changed=0 unreachable=0 failed=0
```

## Controlled failover and failback

HAProxy was intentionally stopped on `web01`. Keepalived's tracked health script detected the failure and removed `web01` from the election. The VIP appeared only on `web02`, and the unchanged URL `http://192.168.56.100/health` continued returning HTTP 200 with this header:

```text
x-load-balancer: web02
```

HAProxy on `web02` successfully forwarded that request to the still-healthy application on `web01`, demonstrating that VIP ownership and backend selection are separate layers.

After HAProxy was restarted on `web01`, the health checks recovered and the higher-priority node reclaimed the VIP. The same URL then returned:

```text
x-load-balancer: web01
```

This proves service-aware VIP failover and automatic failback while clients continue using a single stable address. Complete abrupt-VM and power-loss scenarios will be repeated in the final failure-testing phase.
