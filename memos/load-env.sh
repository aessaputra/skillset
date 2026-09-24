#!/usr/bin/env bash
# Credential loader for the Hermes Memos skill.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf '%s\n' 'Error: source this file; do not execute it.' >&2
  exit 1
fi

load_service_credentials() {
  local config_file="$HOME/.memos/config.json"
  if [[ ! -f "$config_file" ]]; then
    printf 'ERROR: Memos config file not found: %s\n' "$config_file" >&2
    return 1
  fi

  command -v jq >/dev/null 2>&1 || {
    printf 'ERROR: jq is required to read %s\n' "$config_file" >&2
    return 1
  }

  MEMOS_URL="$(jq -er '.MEMOS_URL // .url // empty' "$config_file")" || {
    printf 'ERROR: invalid JSON in %s\n' "$config_file" >&2
    return 1
  }
  MEMOS_API_TOKEN="$(jq -er '.MEMOS_API_TOKEN // .api_token // empty' "$config_file")" || {
    printf 'ERROR: invalid JSON in %s\n' "$config_file" >&2
    return 1
  }
  export MEMOS_URL MEMOS_API_TOKEN

  local missing=()
  [[ -z "${MEMOS_URL:-}" ]] && missing+=(MEMOS_URL)
  [[ -z "${MEMOS_API_TOKEN:-}" ]] && missing+=(MEMOS_API_TOKEN)
  if ((${#missing[@]})); then
    printf 'ERROR: missing required keys in %s: %s\n' "$config_file" "${missing[*]}" >&2
    return 1
  fi
}
