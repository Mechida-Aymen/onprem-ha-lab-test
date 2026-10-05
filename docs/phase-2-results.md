# Phase 2 verification results

Verification date: 2026-09-28

## Installed platform

- Debian GNU/Linux 13.7
- Linux kernel `6.12.107+deb13-amd64`
- VirtualBox 7.0.24
- Minimal installation without a graphical desktop
- OpenSSH enabled
- `ansible` account configured for key-based access and passwordless sudo
- Password authentication for the generated template account locked after key verification

The Debian ISO was verified against the SHA-512 checksum published in Debian's official `SHA512SUMS` file before installation.

## Node verification

| Host | Private address | Machine ID | ED25519 host-key fingerprint |
|---|---|---|---|
| `web01` | `192.168.56.11/24` | `8315e9fb740d454eb9892a091459e72f` | `SHA256:wMRDTsEeS3MdjMaiWrOv/VjWtk/2yN6+vvM/mhxbAbk` |
| `web02` | `192.168.56.12/24` | `0d6f19b010404c208e61057d9a54ae8b` | `SHA256:IscNkaNxoXSqfDUGpQCud6VxNjVLSV7WruqlkPyWPL8` |
| `db01` | `192.168.56.31/24` | `a85a9e277c4543e6b7700ea5e5151dc2` | `SHA256:RtUHqEYPvot6+8UeoV+PeVbEyBvaAObYS/RxhLjNg+c` |
| `db02` | `192.168.56.32/24` | `7fa04f65bf764b83b111899c8c1558fd` | `SHA256:azegpZ7vpCYcWT4eZKC3xqc3yUdA7AKEmJK51JJu2ng` |

All machine IDs, SSH host-key fingerprints, and VirtualBox MAC addresses are unique.

## Acceptance tests

| Test | Result |
|---|---|
| Windows ping to all private addresses | Passed, 0% packet loss |
| Windows SSH key login to all nodes | Passed |
| Passwordless sudo for `ansible` | Passed |
| SSH service active on all nodes | Passed |
| Static host-only addresses | Passed |
| NAT default route and DNS resolution | Passed |
| `web01` to `web02`, `db01`, and `db02` ICMP | Passed |
| Unique machine and SSH identities | Passed |

The four lab VMs are ready for the Ansible foundation in Phase 3.

