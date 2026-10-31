#!/usr/bin/env bash

# Usage: ansible-env.sh <environment> <command> [args...]
# Example: ansible-env.sh lab ansible-playbook playbooks/site.yml

set -euo pipefail

if [[ $# -lt 2 ]]; then
  printf 'Usage: %s <environment> <command> [args...]\n' "$(basename "$0")" >&2
  exit 2
fi

environment="$1"
shift

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
ansible_dir="$repo_root/iac/ansible"

if [[ ! -d "$ansible_dir" ]]; then
  printf 'error: Ansible directory not found: %s\n' "$ansible_dir" >&2
  exit 1
fi

export ANSIBLE_INVENTORY="$ansible_dir/inventory/$environment"

cd "$ansible_dir"
exec "$repo_root/scripts/with-secrets.sh" "$environment" -- "$@"
