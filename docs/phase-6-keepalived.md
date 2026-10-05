# Phase 6: Keepalived virtual-IP failover

Keepalived will make `192.168.56.100` a floating address shared by the two web nodes. Only one node owns it at a time. Clients can therefore use one stable address even when the active load-balancer service fails.

## Election design

| Node | Private address | Initial state | Priority |
|---|---|---|---:|
| `web01` | `192.168.56.11` | MASTER | 150 |
| `web02` | `192.168.56.12` | BACKUP | 100 |

The higher-priority healthy node owns the VIP. Keepalived checks HAProxy every two seconds and leaves the election when two consecutive checks fail. Unicast VRRP is used because it is predictable on the VirtualBox host-only network.

Before deployment, confirm Adapter 2 on both VirtualBox VMs is attached to the host-only network, has **Cable Connected** enabled, and uses **Promiscuous Mode: Allow VMs**.

## 1. Check syntax

From PowerShell:

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' keepalived.yml --syntax-check
```

## 2. Deploy only to web01

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' keepalived.yml --limit web01 --diff
```

The final report should say `VIP present=True`. Test the new client address:

```powershell
ping 192.168.56.100
curl.exe -i http://192.168.56.100/health
```

The HTTP response should contain `x-load-balancer: web01`.

## 3. Deploy to web02

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' keepalived.yml --limit web02 --diff
```

Because `web01` has the higher priority, it should keep the VIP. Display the VIP owner:

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-wsl.sh' web -b -m ansible.builtin.shell -a "ip -4 -o address show | grep -F 192.168.56.100 || true"
```

Only `web01` should print an address containing `192.168.56.100`.

## 4. Prove idempotence

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' keepalived.yml --diff
```

Both nodes should report `changed=0` and `failed=0`.

## 5. Test HAProxy-aware VIP failover

Stop HAProxy on the current VIP owner:

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-wsl.sh' web01 -b -m ansible.builtin.systemd_service -a 'name=haproxy state=stopped'
```

Wait six seconds, then test the unchanged client address:

```powershell
Start-Sleep -Seconds 6
curl.exe -i http://192.168.56.100/health
```

The request should still succeed, but its header should now say `x-load-balancer: web02`. Confirm that only `web02` owns the VIP with the ownership command from step 3.

Always restore HAProxy afterward:

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-wsl.sh' web01 -b -m ansible.builtin.systemd_service -a 'name=haproxy state=started'
```

Wait six seconds and query the VIP again. The higher-priority `web01` node should reclaim it, and the response header should return to `x-load-balancer: web01`.

## Troubleshooting

On the affected web node, inspect:

```bash
sudo systemctl status keepalived --no-pager -l
sudo journalctl -u keepalived -n 80 --no-pager
sudo keepalived --config-test --use-file=/etc/keepalived/keepalived.conf
ip -4 -o address show
systemctl is-active haproxy
```

If the VIP moves between servers but Windows temporarily uses an old MAC address, wait several seconds for the gratuitous ARP announcements and test again.

## Completion checklist

- [x] The private interface was detected as `enp0s8` on both nodes.
- [x] Keepalived configuration validation passed on both nodes.
- [x] `web01` became MASTER and initially owned the VIP.
- [x] `web02` joined as BACKUP without duplicating the VIP.
- [x] The Windows host reached HAProxy through `192.168.56.100`.
- [x] A repeated Ansible run reported `changed=0` on both nodes.
- [x] Stopping HAProxy on `web01` moved the VIP to `web02`.
- [x] The unchanged client address continued returning HTTP 200 after failover.
- [x] Restarting HAProxy returned the VIP to higher-priority `web01`.

Detailed evidence is recorded in [Phase 6 verification results](phase-6-results.md).
