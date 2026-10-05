# Phase 4: application deployment

This phase deploys a small Python HTTP service to `web01` and `web02`. Run the deployment one node at a time so a failure can be investigated before the second node is changed.

## 1. Check the playbook syntax

From PowerShell:

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' application.yml --syntax-check
```

This only parses the playbook. It does not change a VM.

## 2. Deploy to web01

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' application.yml --limit web01 --diff
```

Stop here if Ansible reports `failed` or `unreachable`. Read the failed task and investigate it before deploying to `web02`.

## 3. Test web01 from Windows

```powershell
curl.exe http://192.168.56.11:8080/
curl.exe http://192.168.56.11:8080/health
```

The first response should include `"hostname": "web01"`; the health response should include `"status": "ok"`.

## 4. Deploy and test web02

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' application.yml --limit web02 --diff
curl.exe http://192.168.56.12:8080/
curl.exe http://192.168.56.12:8080/health
```

## 5. Prove idempotence

Run the playbook against both web nodes again:

```powershell
wsl.exe -d Debian -- bash '/mnt/c/Users/Usuario/Desktop/1st project/scripts/ansible-playbook-wsl.sh' application.yml --diff
```

The recap should report `changed=0` for both nodes.

## Troubleshooting on a web node

After entering Debian WSL, connect to the affected node with SSH. Replace the address as needed:

```bash
ssh -i ~/.ssh/onprem_ha_lab ansible@192.168.56.11
```

Then inspect the service:

```bash
sudo systemctl status onprem-ha-app --no-pager -l
sudo journalctl -u onprem-ha-app -n 50 --no-pager
sudo ss -lntp | grep 8080
curl http://127.0.0.1:8080/health
```

These commands show whether the service is running, its recent logs, whether port 8080 is listening, and whether it responds locally.

## Completion checklist

- [x] The role deployed successfully to `web01`.
- [x] The role deployed successfully to `web02`.
- [x] `/` returned the correct hostname and version from each node.
- [x] `/health` returned HTTP 200 and `"status": "ok"` from each node.
- [x] A repeated deployment reported `changed=0` on both nodes.

Detailed evidence is recorded in [Phase 4 verification results](phase-4-results.md).
