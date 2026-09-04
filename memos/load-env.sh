#!/usr/bin/env bash
# Credential loader for the Hermes Memos skill.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf '%s\n' 'Error: source this file; do not execute it.' >&2
  exit 1
fi

load_service_credentials() {
  local env_file="$HOME/.memos"
  if [[ ! -f "$env_file" ]]; then
    printf 'ERROR: Memos credential file not found: %s\n' "$env_file" >&2
    return 1
  fi

  set -a
  # shellcheck source=/dev/null
  source "$env_file"
  set +a

  local missing=()
  [[ -z "${MEMOS_URL:-}" ]] && missing+=(MEMOS_URL)
  [[ -z "${MEMOS_API_TOKEN:-}" ]] && missing+=(MEMOS_API_TOKEN)
  if ((${#missing[@]})); then
    printf 'ERROR: missing required variables in %s: %s\n' "$env_file" "${missing[*]}" >&2
    return 1
  fi
}
