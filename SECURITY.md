# Security policy

## Supported version

The latest commit on `main` is the supported version of this educational project.

## Reporting a vulnerability

Do not publish credentials or a working exploit in a public issue. Use GitHub's private vulnerability-reporting feature or contact the repository owner privately. Include the affected file, expected impact, and safe reproduction steps.

## Scope

This repository is an educational lab, not a production-ready platform. Its deliberate limitations include manual PostgreSQL promotion, locally stored unencrypted backups, a private lab certificate model that has not yet been implemented, and services colocated to fit four VMs.

## Secret handling

The active Vault file, Vault password, SSH private keys, database dumps, and local inventory overrides must remain outside Git. If a secret is committed accidentally, remove it from history and rotate it immediately; deleting it in a later commit is not sufficient.
