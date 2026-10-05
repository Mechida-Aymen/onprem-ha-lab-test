#!/usr/bin/env bash
set -euo pipefail

for ip in 192.168.56.11 192.168.56.12 192.168.56.31 192.168.56.32; do
    echo "--- ${ip} ---"
    key="$(ssh-keyscan -T 5 -t ed25519 "${ip}" 2>/dev/null)"
    if [[ -z "${key}" ]]; then
        echo "No ED25519 host key received from ${ip}" >&2
        exit 1
    fi
    printf '%s\n' "${key}" | ssh-keygen -lf -
done

