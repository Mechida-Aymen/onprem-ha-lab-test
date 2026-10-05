# Phase 5 verification results

Verification date: 2026-10-03

## HAProxy configuration

- Load-balancer nodes: `web01` and `web02`
- Client port: TCP `80`
- Backend nodes: `web01:8080` and `web02:8080`
- Balancing algorithm: round robin
- Health endpoint: `/health`
- Check interval: two seconds
- Failure threshold: three failed checks
- Recovery threshold: two successful checks

Each configuration was validated with `haproxy -c` before installation and again after activation. Both services are enabled at boot. An administrative Unix socket is available at `/run/haproxy/admin.sock` for local troubleshooting.

## Load-balancing tests

Six requests sent through HAProxy on `web01` alternated exactly between the `web01` and `web02` application instances. The same test through HAProxy on `web02` also alternated between both backends.

An HTTP response received through `192.168.56.11:80` contained:

```text
x-load-balancer: web01
```

while its JSON body identified `web02`. This proves that HAProxy on `web01` accepted the client connection and forwarded it across the private network to the application on `web02`.

## Idempotence

The repeated HAProxy playbook run produced:

```text
web01 : ok=8 changed=0 unreachable=0 failed=0
web02 : ok=8 changed=0 unreachable=0 failed=0
```

## Controlled backend failure

The `onprem-ha-app` service was intentionally stopped on `web02`. After seven seconds, four requests through HAProxy on `web01` and four requests through HAProxy on `web02` all succeeded and were served by the remaining `web01` application.

The `web02` application was then restarted. After its recovery checks passed, requests through HAProxy alternated between `web01` and `web02` again.

This test proves application-backend health detection and traffic failover. It does not yet prove complete web-node failover because clients still use a specific node address. Phase 6 will introduce the floating virtual IP for that purpose.
