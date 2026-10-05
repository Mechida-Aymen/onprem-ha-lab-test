#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_log="$(mktemp)"
probe_pid=""

cleanup() {
    if [[ -n "${probe_pid}" ]] && kill -0 "${probe_pid}" 2>/dev/null; then
        kill "${probe_pid}" 2>/dev/null || true
        wait "${probe_pid}" 2>/dev/null || true
    fi
    rm -f "${probe_log}"
}
trap cleanup EXIT

(
    while true; do
        timestamp="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"
        status_code="$(curl --noproxy '*' --connect-timeout 1 --max-time 2 \
            --silent --output /dev/null --write-out '%{http_code}' \
            http://192.168.56.100/health || true)"
        printf '%s %s\n' "${timestamp}" "${status_code:-000}" >> "${probe_log}"
        sleep 0.2
    done
) &
probe_pid="$!"

sleep 1
set +e
bash "${project_dir}/scripts/ansible-playbook-wsl.sh" deploy.yml
playbook_result="$?"
set -e
sleep 2

kill "${probe_pid}" 2>/dev/null || true
wait "${probe_pid}" 2>/dev/null || true
probe_pid=""

total_requests="$(wc -l < "${probe_log}")"
failed_requests="$(awk '$2 != "200" {count++} END {print count+0}' "${probe_log}")"

echo "Rolling deployment HTTP probes: ${total_requests}"
echo "Failed HTTP probes: ${failed_requests}"

if [[ "${playbook_result}" -ne 0 ]]; then
    echo "The rolling deployment playbook failed." >&2
    exit "${playbook_result}"
fi

if [[ "${failed_requests}" -ne 0 ]]; then
    echo "Non-200 responses observed:" >&2
    awk '$2 != "200"' "${probe_log}" >&2
    exit 1
fi

echo "Zero-downtime rolling deployment verified."
