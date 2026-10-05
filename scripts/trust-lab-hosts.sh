#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
touch "${HOME}/.ssh/known_hosts"
chmod 600 "${HOME}/.ssh/known_hosts"

for ip in 192.168.56.11 192.168.56.12 192.168.56.31 192.168.56.32; do
    if ! ssh-keygen -F "${ip}" -f "${HOME}/.ssh/known_hosts" >/dev/null; then
        ssh-keyscan -H -T 5 -t ed25519 "${ip}" 2>/dev/null >> "${HOME}/.ssh/known_hosts"
    fi
done

echo 'Verified lab host keys are present in ~/.ssh/known_hosts.'

