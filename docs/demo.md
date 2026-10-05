# Portfolio demonstration runbook

This runbook presents the project in roughly ten minutes. Run commands from PowerShell unless stated otherwise.

## 1. Introduce the design

Show the architecture diagram in the main README and explain the request path:

```text
client -> floating VIP -> active HAProxy -> healthy application -> db01
                                                            db01 -> db02
```

Be explicit that the web tier fails over automatically while database promotion is manual.

## 2. Prove configuration management

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' site.yml
```

A repeated run should finish with `changed=0` and `failed=0` on all nodes. This demonstrates idempotence: Ansible recognizes that the desired state already exists.

## 3. Show the stable service

```powershell
curl.exe --noproxy "*" http://192.168.56.100/
curl.exe --noproxy "*" http://192.168.56.100/health
curl.exe --noproxy "*" http://192.168.56.100/db-health
```

Point out the application hostname, `x-load-balancer` response header, version, and successful database query.

## 4. Show load balancing

```powershell
1..6 | ForEach-Object { curl.exe --noproxy "*" -s http://192.168.56.100/; Write-Output "" }
```

The backend hostname should alternate between `web01` and `web02` while the client continues to use one address.

## 5. Demonstrate failure handling

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' failure-tests.yml
```

Explain that the playbook stops real services, asserts the expected client behavior, and restores every service through `always` blocks.

## 6. Demonstrate recovery

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' restore-test.yml
```

The test writes a marker, backs it up, deletes it, restores the backup into an isolated database, confirms the marker was recovered, and removes the temporary database.

## 7. Show monitoring

```powershell
curl.exe --noproxy "*" -s http://192.168.56.31:9100/metrics | Select-String '^onprem_'
```

Highlight primary readiness and the number of streaming replicas. The same endpoint on web nodes shows application health and which node owns the VIP.

## 8. Close with engineering trade-offs

- Four VMs keep the lab practical on limited hardware.
- Colocation reduces resource use but combines failure domains.
- Replication improves data availability but is not a backup.
- Manual database promotion avoids unsafe split-brain behavior in this MVP.
- Backups still need encryption and off-host storage before production use.
