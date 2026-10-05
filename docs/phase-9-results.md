# Phase 9 verification results

Verification date: 2026-10-03

`ansible/deploy.yml` deploys with `serial: 1`. Before updating a node it disables that backend through both HAProxy administrative sockets, waits for requests to drain, deploys and verifies the service, and then re-enables the backend in an `always` block. The VIP is checked after each node.

A Windows client continuously queried the VIP while version `1.2.2` was deployed. It recorded 205 HTTP probes and zero failures. Both application nodes finished on version `1.2.2`.

The Windows test is authoritative for client availability because it exercises the real host-to-VIP path. The reusable harness is `scripts/test-rolling-deployment.ps1`.
