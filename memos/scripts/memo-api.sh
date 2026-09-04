#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

cmd_create() {
  [[ $# -ge 1 ]] || { echo 'ERROR: content required' >&2; return 2; }
  local content="$1"; shift
  local tags="" visibility="PRIVATE" memo_id="" space=""
  while (($#)); do case "$1" in
    --tags) tags="$2"; shift 2;; --visibility) visibility="$2"; shift 2;;
    --memo-id) memo_id="$2"; shift 2;; --space) space="$2"; shift 2;;
    *) printf 'ERROR: unknown option: %s\n' "$1" >&2; return 2;; esac; done
  validate_visibility "$visibility"
  if [[ -n "$tags" ]]; then
    local tag; IFS=',' read -ra tag_list <<< "$tags"
    for tag in "${tag_list[@]}"; do tag="${tag#\#}"; [[ -n "$tag" ]] && content+=" #$tag"; done
  fi
  local payload endpoint="/memos"
  payload="$(jq -n --arg content "$content" --arg visibility "$visibility" --arg space "$space" '{content:$content,visibility:$visibility} + (if $space=="" then {} else {space:$space} end)')"
  [[ -n "$memo_id" ]] && endpoint+="?memoId=$(urlencode "$memo_id")"
  api_call POST "$endpoint" "$payload"
}

cmd_list() {
  local size=50 token="" filter="" state="NORMAL" order="" show_deleted="false"
  while (($#)); do case "$1" in
    --limit|--page-size) size="$2"; shift 2;; --page-token) token="$2"; shift 2;;
    --filter) filter="$2"; shift 2;; --state) state="$2"; shift 2;;
    --order-by) order="$2"; shift 2;; --show-deleted) show_deleted="true"; shift;;
    *) printf 'ERROR: unknown option: %s\n' "$1" >&2; return 2;; esac; done
  validate_state "$state"
  [[ "$size" =~ ^[0-9]+$ ]] && ((size>=1 && size<=1000)) || { echo 'ERROR: page size must be 1..1000' >&2; return 2; }
  local q="pageSize=$size&state=$state"
  [[ -n "$token" ]] && q+="&pageToken=$(urlencode "$token")"
  [[ -n "$filter" ]] && q+="&filter=$(urlencode "$filter")"
  [[ -n "$order" ]] && q+="&orderBy=$(urlencode "$order")"
  [[ "$show_deleted" == true ]] && q+="&showDeleted=true"
  api_call GET "/memos?$q"
}

cmd_get() { [[ $# -eq 1 ]] || { echo 'ERROR: memo ID required' >&2; return 2; }; api_call GET "/memos/$(strip_resource_prefix "$1")"; }

cmd_update() {
  [[ $# -ge 1 ]] || { echo 'ERROR: memo ID required' >&2; return 2; }
  local id; id="$(strip_resource_prefix "$1")"; shift
  local content="" add_tags="" visibility="" state="" pinned="" space="" has_space=false
  if (($#)) && [[ "$1" != --* ]]; then content="$1"; shift; fi
  while (($#)); do case "$1" in
    --add-tags) add_tags="$2"; shift 2;; --visibility) visibility="$2"; shift 2;;
    --state) state="$2"; shift 2;; --pinned) pinned="$2"; shift 2;;
    --space) space="$2"; has_space=true; shift 2;;
    *) printf 'ERROR: unknown option: %s\n' "$1" >&2; return 2;; esac; done
  [[ -n "$visibility" ]] && validate_visibility "$visibility"
  [[ -n "$state" ]] && validate_state "$state"
  if [[ -n "$pinned" && "$pinned" != true && "$pinned" != false ]]; then echo 'ERROR: --pinned must be true or false' >&2; return 2; fi
  if [[ -n "$add_tags" ]]; then
    [[ -n "$content" ]] || content="$(api_call GET "/memos/$id" | jq -er '.content')"
    local tag; IFS=',' read -ra tag_list <<< "$add_tags"
    for tag in "${tag_list[@]}"; do tag="${tag#\#}"; [[ -n "$tag" && "$content" != *"#$tag"* ]] && content+=" #$tag"; done
  fi
  local payload='{}' fields=()
  [[ -n "$content" ]] && { payload="$(jq --arg v "$content" '.+{content:$v}' <<<"$payload")"; fields+=(content); }
  [[ -n "$visibility" ]] && { payload="$(jq --arg v "$visibility" '.+{visibility:$v}' <<<"$payload")"; fields+=(visibility); }
  [[ -n "$state" ]] && { payload="$(jq --arg v "$state" '.+{state:$v}' <<<"$payload")"; fields+=(state); }
  [[ -n "$pinned" ]] && { payload="$(jq --argjson v "$pinned" '.+{pinned:$v}' <<<"$payload")"; fields+=(pinned); }
  $has_space && { payload="$(jq --arg v "$space" '.+{space:(if $v=="" then null else $v end)}' <<<"$payload")"; fields+=(space); }
  ((${#fields[@]})) || { echo 'ERROR: no fields to update' >&2; return 2; }
  local mask; mask="$(IFS=,; echo "${fields[*]}")"
  api_call PATCH "/memos/$id?updateMask=$(urlencode "$mask")" "$payload"
}

cmd_archive() { [[ $# -eq 1 ]] || return 2; cmd_update "$1" --state ARCHIVED; }
cmd_delete() {
  [[ $# -ge 1 ]] || { echo 'ERROR: memo ID required' >&2; return 2; }
  local id; id="$(strip_resource_prefix "$1")"; shift; local force=false
  [[ "${1:-}" == --force ]] && force=true
  api_call DELETE "/memos/$id?force=$force"
}

usage() { cat <<'EOF'
Usage: memo-api.sh COMMAND [ARGS]
  create CONTENT [--tags a,b] [--visibility PRIVATE|PROTECTED|PUBLIC|SPACE] [--memo-id ID] [--space spaces/ID]
  list [--limit N] [--page-token TOKEN] [--state NORMAL|ARCHIVED] [--order-by EXPR] [--filter CEL] [--show-deleted]
  get ID
  update ID [CONTENT] [--add-tags a,b] [--visibility VALUE] [--state VALUE] [--pinned true|false] [--space spaces/ID|""]
  archive ID
  delete ID [--force]
EOF
}
main() { local cmd="${1:-help}"; (($#)) && shift || true; case "$cmd" in create) cmd_create "$@";; list) cmd_list "$@";; get) cmd_get "$@";; update) cmd_update "$@";; archive) cmd_archive "$@";; delete) cmd_delete "$@";; help|-h|--help) usage;; *) usage >&2; return 2;; esac; }
main "$@"
