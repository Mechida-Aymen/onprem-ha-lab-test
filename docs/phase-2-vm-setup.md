# Phase 2: Debian VM setup

This guide prepares the four Debian VMs required by the lab. It is written for VirtualBox on Windows and reuses the existing host-only network `192.168.56.0/24`.

## Result we want

| VM | Private address | RAM | CPU | Disk |
|---|---:|---:|---:|---:|
| `web01` | `192.168.56.11/24` | 768 MB-1 GB | 1 | 10-12 GB |
| `web02` | `192.168.56.12/24` | 768 MB-1 GB | 1 | 10-12 GB |
| `db01` | `192.168.56.31/24` | 1 GB | 1 | 10-12 GB |
| `db02` | `192.168.56.32/24` | 1 GB | 1 | 10-12 GB |

Each VM has two network adapters:

- Adapter 1: NAT, used for Debian package downloads
- Adapter 2: `VirtualBox Host-Only Ethernet Adapter`, used by the lab

The host-only adapter is already configured on Windows as `192.168.56.1/24`, with DHCP disabled. Do not add a gateway to the VM's host-only interface. The NAT interface supplies the default route.

## 1. Download Debian

Download the current stable **64-bit PC netinst ISO** from Debian's official page:

<https://www.debian.org/distrib/netinst>

Keep the ISO after installing the template until all four VMs boot correctly.

## 2. Create a template VM

In VirtualBox, select **New** and use these settings:

- Name: `debian-ha-template`
- Type/version: Debian, 64-bit
- ISO: the Debian netinst ISO
- Skip unattended installation
- Memory: 1024 MB
- Processors: 1
- Virtual disk: 12 GB, dynamically allocated

Before starting it, open **Settings > Network**:

### Adapter 1

- Enable Network Adapter
- Attached to: `NAT`
- Cable Connected: enabled

### Adapter 2

- Enable Network Adapter
- Attached to: `Host-only Adapter`
- Name: `VirtualBox Host-Only Ethernet Adapter`
- Promiscuous Mode: `Allow VMs`
- Cable Connected: enabled

`Allow VMs` helps the later VRRP/VIP lab traffic. This host-only network is isolated from the physical LAN.

## 3. Install minimal Debian

Start the template VM and use the graphical or text installer.

Recommended choices:

- Hostname: `debian-ha-template`
- Domain name: leave blank
- Root password: leave blank so the normal user receives sudo access
- Username: `ansible`
- Partitioning: Guided, use entire disk, all files in one partition
- Package mirror: a nearby official mirror
- Popularity contest: either choice is acceptable

At **Software selection**, enable only:

- SSH server
- standard system utilities

Disable every desktop environment. Finish the installation, remove/eject the ISO, and reboot.

## 4. Prepare the template

Log in through the VirtualBox console and run:

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y openssh-server sudo curl ca-certificates vim
sudo systemctl enable --now ssh
ip -br link
ip route
```

Confirm that two Ethernet interfaces exist. They will commonly be named `enp0s3` for NAT and `enp0s8` for host-only, but record the actual names shown on this VM.

Before cloning, remove identifiers that must be unique on every server:

```bash
sudo rm -f /etc/ssh/ssh_host_*
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo poweroff
```

The template must remain powered off after this step.

## 5. Clone the four VMs

For each target, right-click `debian-ha-template` and select **Clone**:

- Create a **Full Clone**
- Select **Generate new MAC addresses for all network adapters**
- Create `web01`, `web02`, `db01`, and `db02`

Keep the template powered off and do not assign it a lab IP.

## 6. Configure each clone

Start one clone at a time and log in through the VirtualBox console. Substitute the correct hostname and address from the result table.

Set the hostname:

```bash
sudo hostnamectl set-hostname web01
sudo nano /etc/hosts
```

Ensure `/etc/hosts` contains the local hostname on the `127.0.1.1` line:

```text
127.0.0.1 localhost
127.0.1.1 web01
```

Check the real interface names again:

```bash
ip -br link
```

Edit the network configuration:

```bash
sudo nano /etc/network/interfaces
```

Use the following pattern. Replace `enp0s3` and `enp0s8` if the detected names differ, and change the address for each VM:

```text
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

allow-hotplug enp0s3
iface enp0s3 inet dhcp

auto enp0s8
iface enp0s8 inet static
    address 192.168.56.11/24
```

Do not configure `gateway` or DNS under `enp0s8`.

Regenerate the cloned SSH server identity and reboot:

```bash
sudo ssh-keygen -A
sudo reboot
```

Repeat for all VMs using these pairs:

```text
web01  192.168.56.11/24
web02  192.168.56.12/24
db01   192.168.56.31/24
db02   192.168.56.32/24
```

## 7. Verify networking from Windows

With all four VMs running, open PowerShell:

```powershell
ping 192.168.56.11
ping 192.168.56.12
ping 192.168.56.31
ping 192.168.56.32
```

Test SSH with the temporary password:

```powershell
ssh ansible@192.168.56.11
```

Inside every VM, verify private-network and Internet connectivity:

```bash
ping -c 2 192.168.56.1
ping -c 2 192.168.56.11
ping -c 2 192.168.56.12
ping -c 2 192.168.56.31
ping -c 2 192.168.56.32
getent hosts deb.debian.org
```

A VM does not need to ping its own address as part of the cross-node test, but doing so is harmless.

## 8. Configure an SSH key

Windows OpenSSH is already installed. In PowerShell, create a project-specific key if it does not exist:

```powershell
ssh-keygen -t ed25519 -a 100 -f "$env:USERPROFILE\.ssh\onprem_ha_lab"
```

Do not place a private key inside this Git repository.

For each VM, copy the public key using PowerShell:

```powershell
Get-Content "$env:USERPROFILE\.ssh\onprem_ha_lab.pub" | ssh ansible@192.168.56.11 "umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys"
```

Repeat with `.12`, `.31`, and `.32`, then test:

```powershell
ssh -i "$env:USERPROFILE\.ssh\onprem_ha_lab" ansible@192.168.56.11
```

Keep password authentication enabled until key access succeeds on every VM. SSH hardening belongs in the Ansible `common` role in Phase 3.

## 9. Phase completion checklist

Phase 2 is complete only when:

- [x] All four VMs boot without the installer ISO.
- [x] Each VM has a unique hostname and MAC address.
- [x] Each VM has a unique machine ID and SSH host key.
- [x] The NAT interface provides Internet/package access.
- [x] The host-only interface has the planned static address.
- [x] All four VMs can reach one another on `192.168.56.0/24`.
- [x] Windows can ping and SSH to every VM.
- [x] The `ansible` user can run `sudo`.
- [x] SSH key login works on every VM.

The checklist passed on 2026-09-28. Detailed evidence is recorded in [Phase 2 verification results](phase-2-results.md).


