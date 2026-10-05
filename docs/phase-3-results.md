# Phase 3 verification results

Verification date: 2026-10-03

## Ansible controller

- Debian WSL 2 controller
- Ansible Core 2.19.11
- Project-specific private key stored outside the repository at `~/.ssh/onprem_ha_lab`
- Strict SSH host-key checking enabled
- Verified host fingerprints imported into WSL's `known_hosts`
- Wrapper scripts set `ANSIBLE_CONFIG` explicitly because the repository is mounted from Windows

Use the wrappers from the project directory in WSL:

```bash
./scripts/ansible-wsl.sh all -m ansible.builtin.ping
./scripts/ansible-playbook-wsl.sh site.yml
./scripts/ansible-playbook-wsl.sh reboot.yml
```

The wrappers may also be called from PowerShell through `wsl.exe`.

## Managed baseline

The `common` role now manages:

- Hostnames and `/etc/hosts` entries
- The `Africa/Casablanca` timezone
- APT cache updates and safe package upgrades
- Common administration packages
- Chrony time synchronization
- SSH key-only access, disabled root login, and disabled X11 forwarding
- An nftables firewall with a default-drop input policy
- SSH access and traffic originating from the private `192.168.56.0/24` lab network

## Acceptance tests

| Test | Result |
|---|---|
| Ansible ping to all four nodes | Passed |
| First complete `site.yml` run | Passed, zero failed or unreachable nodes |
| Second complete `site.yml` run | Passed, zero changes on every node |
| SSH and Chrony active | Passed on all nodes |
| nftables rules loaded | Passed on all nodes |
| Firewall input policy is `drop` | Passed on all nodes |
| SSH remains explicitly allowed | Passed on all nodes |
| Serial reboot and reconnection | Passed on all nodes |
| Managed services and firewall recovered after reboot | Passed on all nodes |

After reboot, every node was running kernel `6.12.111+deb13-amd64`. The final Ansible connectivity check returned `pong` from `web01`, `web02`, `db01`, and `db02`.

## Operational note

Debian's `nftables.service` is a `Type=oneshot` unit. It loads the rules and remains `active (exited)` rather than running as a long-lived process. The reboot playbook therefore validates the actual kernel ruleset instead of incorrectly requiring the service-facts state to equal `running`.

Phase 3 is complete. The lab is ready for the Phase 4 application deployment.
