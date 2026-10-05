# Phase 8 verification results

Verification date: 2026-10-03

The Python application now uses the packaged `psycopg2` driver and reads its database connection settings from `/etc/onprem-ha-app.env`. That file is owned by `root:onprem-app`, has mode `0640`, and is rendered with Ansible's `no_log` protection.

The `/db-health` endpoint executes a real query and reports whether it reached the primary. Direct checks on `web01` and `web02`, plus a check through the VIP, all returned HTTP 200 with `status: ok`, `primary: true`, and database host `192.168.56.31`.

The database passwords are encrypted in `ansible/group_vars/vault.yml`. The separate Vault password file remains only in the WSL controller account with mode `0600` and is excluded from the repository.
