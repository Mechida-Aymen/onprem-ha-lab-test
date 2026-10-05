#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ansible_dir="${project_dir}/ansible"

export ANSIBLE_CONFIG="${ansible_dir}/ansible.cfg"
cd "${ansible_dir}"

exec ansible-playbook "$@"

