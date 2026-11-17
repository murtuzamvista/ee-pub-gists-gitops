#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

for command in yamllint kubectl kubeconform; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

yamllint --strict --config-file "$repo_root/.yamllint" "$repo_root"

for overlay in qa production; do
  printf 'Rendering and schema-validating %s overlay...\n' "$overlay"
  kubectl kustomize "$repo_root/overlays/$overlay" |
    kubeconform -strict -summary
done
