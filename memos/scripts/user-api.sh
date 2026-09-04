#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

cmd_whoami() { api_call GET '/auth/me'; }
cmd_profile() {
  if [[ -z "${1:-}" ]]; then api_call GET '/auth/me' | jq '.user'; else api_call GET "/users/$(strip_resource_prefix "$1")"; fi
}
cmd_update_profile() {
  local display_name="" email="" description="" fields=() payload='{}'
  while (($#)); do case "$1" in
    --display-name|--nickname) display_name="$2"; fields+=(displayName); shift 2;;
    --email) email="$2"; fields+=(email); shift 2;; --description) description="$2"; fields+=(description); shift 2;;
    *) echo "ERROR: unknown option: $1" >&2; return 2;; esac; done
  ((${#fields[@]})) || { echo 'ERROR: no fields to update' >&2; return 2; }
  [[ " ${fields[*]} " == *' displayName '* ]] && payload="$(jq --arg v "$display_name" '.+{displayName:$v}' <<<"$payload")"
  [[ " ${fields[*]} " == *' email '* ]] && payload="$(jq --arg v "$email" '.+{email:$v}' <<<"$payload")"
  [[ " ${fields[*]} " == *' description '* ]] && payload="$(jq --arg v "$description" '.+{description:$v}' <<<"$payload")"
  local name mask; name="$(api_call GET '/auth/me' | jq -er '.user.name')"; mask="$(IFS=,; echo "${fields[*]}")"
  api_call PATCH "/users/$(strip_resource_prefix "$name")?updateMask=$(urlencode "$mask")" "$payload"
}
current_user_name() { api_call GET '/auth/me' | jq -er '.user.name'; }
cmd_tokens() {
  local size=50 token="" parent
  while (($#)); do case "$1" in
    --limit|--page-size) size="$2"; shift 2;; --page-token) token="$2"; shift 2;;
    *) echo "ERROR: unknown option: $1" >&2; return 2;; esac; done
  [[ "$size" =~ ^[0-9]+$ ]] && ((size>=1 && size<=1000)) || { echo 'ERROR: page size must be 1..1000' >&2; return 2; }
  parent="$(current_user_name)"
  local q="pageSize=$size"; [[ -n "$token" ]] && q+="&pageToken=$(urlencode "$token")"
  api_call GET "/users/$(strip_resource_prefix "$parent")/personalAccessTokens?$q"
}
cmd_create_token() {
  local description="Memos API token" expires=0
  while (($#)); do case "$1" in
    --description) description="$2"; shift 2;; --expires-in-days) expires="$2"; shift 2;;
    *) echo "ERROR: unknown option: $1" >&2; return 2;; esac; done
  [[ "$expires" =~ ^[0-9]+$ ]] || { echo 'ERROR: --expires-in-days must be a non-negative integer' >&2; return 2; }
  local parent payload; parent="$(current_user_name)"
  payload="$(jq -n --arg description "$description" --argjson expires "$expires" '{description:$description,expiresInDays:$expires}')"
  api_call POST "/users/$(strip_resource_prefix "$parent")/personalAccessTokens" "$payload"
}
cmd_delete_token() {
  [[ $# -eq 1 ]] || { echo 'ERROR: token resource name required' >&2; return 2; }
  local name="$1"
  if [[ "$name" == users/*/personalAccessTokens/* ]]; then
    api_call DELETE "/$name"
  else
    local parent; parent="$(current_user_name)"
    api_call DELETE "/users/$(strip_resource_prefix "$parent")/personalAccessTokens/${name#personalAccessTokens/}"
  fi
}
usage() { cat <<'EOF'
Usage: user-api.sh COMMAND
  whoami
  profile [USERNAME]
  update-profile [--display-name NAME] [--email EMAIL] [--description TEXT]
  tokens [--limit N] [--page-token TOKEN]
  create-token [--description TEXT] [--expires-in-days N]
  delete-token TOKEN_RESOURCE_OR_ID
The token value from create-token is returned once. Store it securely and never log it.
EOF
}
main() { local c="${1:-help}"; (($#)) && shift || true; case "$c" in whoami) cmd_whoami;; profile) cmd_profile "$@";; update-profile) cmd_update_profile "$@";; tokens) cmd_tokens "$@";; create-token) cmd_create_token "$@";; delete-token) cmd_delete_token "$@";; help|-h|--help) usage;; *) usage >&2; return 2;; esac; }
main "$@"
