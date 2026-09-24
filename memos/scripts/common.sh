#!/usr/bin/env bash
# Common helpers for Memos API scripts.

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../load-env.sh
source "$SCRIPT_DIR/../load-env.sh"
load_service_credentials

MEMOS_URL="${MEMOS_URL%/}"
API_BASE="$MEMOS_URL/api/v1"

api_call() {
  local method="$1" endpoint="$2" data="${3:-}" content_type="${4:-application/json}"
  local response_file status
  response_file="$(mktemp)"
  local args=(--silent --show-error --location --request "$method"
    --header "Authorization: Bearer ${MEMOS_API_TOKEN}"
    --header "Accept: application/json")
  if [[ -n "$data" ]]; then
    args+=(--header "Content-Type: $content_type" --data "$data")
  fi
  status="$(curl "${args[@]}" --output "$response_file" --write-out '%{http_code}' "$API_BASE$endpoint")" || {
    local rc=$?
    rm -f "$response_file"
    return "$rc"
  }
  cat "$response_file"
  if [[ ! "$status" =~ ^2 ]]; then
    printf '\nERROR: Memos API returned HTTP %s for %s %s\n' "$status" "$method" "$endpoint" >&2
    rm -f "$response_file"
    return 22
  fi
  rm -f "$response_file"
}

urlencode() { jq -rn --arg value "$1" '$value|@uri'; }
strip_resource_prefix() { printf '%s' "${1#*/}"; }
validate_visibility() {
  case "$1" in PRIVATE|PROTECTED|PUBLIC|SPACE) ;; *)
    printf 'ERROR: visibility must be PRIVATE, PROTECTED, PUBLIC, or SPACE\n' >&2; return 1;; esac
}
validate_state() {
  case "$1" in NORMAL|ARCHIVED) ;; *)
    printf 'ERROR: state must be NORMAL or ARCHIVED\n' >&2; return 1;; esac
}
