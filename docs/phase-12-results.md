# Phase 12 verification results

Verification date: 2026-10-03

The automated suite passed application-backend failure, HAProxy-aware VIP failover/failback, replica outage/catch-up, and primary outage/recovery tests with `failed=0` on all nodes.

An additional abrupt-failure test powered off `web01` through VirtualBox. Six seconds later, four consecutive requests to the unchanged VIP returned HTTP 200 through HAProxy on `web02`. After `web01` started again, its application, HAProxy, Keepalived, Node Exporter, and database health recovered, and the higher-priority node reclaimed the VIP.

Finally, every VM was rebooted serially. SSH, Chrony, nftables, Node Exporter, all web services, both PostgreSQL instances, and application-to-database connectivity recovered automatically. Replication was tested again after the reboots and passed.

The primary database outage demonstrates the intentional limitation: the basic HTTP service remains available, but `/db-health` returns 503 until `db01` recovers because automatic database promotion is not part of this MVP.
