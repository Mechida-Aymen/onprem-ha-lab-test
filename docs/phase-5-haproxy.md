# Phase 5: HAProxy load balancing

HAProxy will listen on port `80` on each web node and balance requests across both application instances on port `8080`. Deploy one load balancer at a time and investigate any failure before continuing.

## Request path

```text
Windows client
    |
    | HTTP port 80
    v
HAProxy on web01
    |
    +----> web01 application, port 8080
    |
    `----> web02 application, port 8080
```

HAProxy checks `/health` every two seconds. A backend is marked down after three consecutive failures and restored after two successful checks.

## 1. Check syntax

From PowerShell:

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' haproxy.yml --syntax-check
```

This parses the playbook without changing a VM.

## 2. Deploy only to web01

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' haproxy.yml --limit web01 --diff
```

Stop and investigate if the recap reports a failed or unreachable host.

## 3. Test load balancing through web01

Run several requests against HAProxy on port 80:

```powershell
1..6 | ForEach-Object { curl.exe -s http://192.168.56.11/; Write-Output "" }
```

The JSON responses should alternate between `"hostname": "web01"` and `"hostname": "web02"`.

To display the load-balancer response header as well:

```powershell
curl.exe -i http://192.168.56.11/health
```

The response should contain `X-Load-Balancer: web01`.

## 4. Deploy and test web02

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' haproxy.yml --limit web02 --diff
1..6 | ForEach-Object { curl.exe -s http://192.168.56.12/; Write-Output "" }
```

The second command should again return responses from both application nodes.

## 5. Prove idempotence

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' haproxy.yml --diff
```

Both nodes should report `changed=0` and `failed=0`.

## Troubleshooting

Connect to the affected web node through Debian WSL, then run:

```bash
sudo systemctl status haproxy --no-pager -l
sudo journalctl -u haproxy -n 50 --no-pager
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo ss -lntp | grep ':80 '
echo 'show stat' | sudo socat stdio /run/haproxy/admin.sock
curl http://192.168.56.11:8080/health
curl http://192.168.56.12:8080/health
```

The last two commands distinguish an HAProxy problem from an application-backend problem.

## Backend failure test

Perform this only after HAProxy works normally. Stop the application on `web02` from PowerShell:

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-wsl.sh' web02 -b -m ansible.builtin.systemd_service -a 'name=onprem-ha-app state=stopped'
```

Wait about seven seconds, then send several requests to HAProxy on `web01`. Every successful response should come from `web01` because HAProxy has removed the unhealthy backend:

```powershell
1..6 | ForEach-Object { curl.exe -s http://192.168.56.11/; Write-Output "" }
```

Always restore the stopped application afterward:

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-wsl.sh' web02 -b -m ansible.builtin.systemd_service -a 'name=onprem-ha-app state=started'
```

After about five seconds, responses through HAProxy should include both nodes again.

## Completion checklist

- [x] HAProxy deployed successfully to both web nodes.
- [x] Both HAProxy configurations passed validation.
- [x] Requests through each load balancer alternated between both backends.
- [x] The response header identified the receiving load-balancer node.
- [x] A repeated Ansible run reported `changed=0` on both nodes.
- [x] Both load balancers removed the stopped `web02` application.
- [x] Both load balancers continued serving through `web01` during the failure.
- [x] Round-robin service returned after the `web02` application was restored.

Detailed evidence is recorded in [Phase 5 verification results](phase-5-results.md).
