# Architecture decisions

## Four-VM topology

The lab uses four Debian VMs because the available host cannot comfortably run six. HAProxy, Keepalived, and the application are colocated on each web node. PostgreSQL remains on two dedicated nodes so streaming replication can be demonstrated realistically.

## Availability boundary

- Failure of one application instance should not interrupt HTTP service.
- Failure of one web VM should move the VIP to the surviving web VM.
- Failure of the PostgreSQL replica should not stop writes to the primary.
- Failure of the PostgreSQL primary will require documented manual recovery in the MVP.

## Networking

The private network is `192.168.56.0/24`, with `192.168.56.100` used as the floating VIP. Each VM also has a NAT interface for package downloads, while application and replication traffic remains on the private network.

## Automation boundary

Initial Debian installation, private-network creation, and initial SSH access are bootstrap steps. After bootstrap, server configuration must be performed through Ansible and remain idempotent.

## Request and data paths

Client requests go to the VIP. Keepalived places that address on one healthy web node, and the local HAProxy selects a healthy application instance. Both application instances currently connect to the PostgreSQL primary. PostgreSQL streams write-ahead-log records to the read-only replica.

```text
client -> VIP -> active HAProxy -> web01 or web02 application -> db01 primary
                                                               |
                                                               +-> db02 replica
```

This removes a single point of failure from the web path. The PostgreSQL primary is still a documented availability boundary because automated promotion, fencing, and client redirection are outside this four-VM MVP.

