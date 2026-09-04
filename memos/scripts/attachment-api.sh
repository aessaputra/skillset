#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

normalize_attachment() { printf '%s' "${1#attachments/}"; }
cmd_upload() {
  [[ $# -ge 1 && -f "$1" ]] || { echo 'ERROR: existing file path required' >&2; return 2; }
  local path="$1"; shift; local memo="" attachment_id=""
  while (($#)); do case "$1" in --memo-id) memo="memos/$(strip_resource_prefix "$2")"; shift 2;; --attachment-id) attachment_id="$2"; shift 2;; *) echo "ERROR: unknown option: $1" >&2; return 2;; esac; done
  local filename mime content payload endpoint="/attachments"
  filename="$(basename "$path")"; mime="$(file --brief --mime-type "$path" 2>/dev/null || printf application/octet-stream)"; content="$(base64 -w 0 "$path")"
  payload="$(jq -n --arg filename "$filename" --arg type "$mime" --arg content "$content" --arg memo "$memo" '{filename:$filename,type:$type,content:$content} + (if $memo=="" then {} else {memo:$memo} end)')"
  [[ -n "$attachment_id" ]] && endpoint+="?attachmentId=$(urlencode "$attachment_id")"
  api_call POST "$endpoint" "$payload"
}
cmd_list() {
  local memo="" size=50 token="" filter="" order=""
  while (($#)); do case "$1" in --memo-id) memo="$(strip_resource_prefix "$2")"; shift 2;; --limit|--page-size) size="$2"; shift 2;; --page-token) token="$2"; shift 2;; --filter) filter="$2"; shift 2;; --order-by) order="$2"; shift 2;; *) echo "ERROR: unknown option: $1" >&2; return 2;; esac; done
  local endpoint q="pageSize=$size"
  if [[ -n "$memo" ]]; then endpoint="/memos/$memo/attachments"; else endpoint="/attachments"; [[ -n "$filter" ]] && q+="&filter=$(urlencode "$filter")"; [[ -n "$order" ]] && q+="&orderBy=$(urlencode "$order")"; fi
  [[ -n "$token" ]] && q+="&pageToken=$(urlencode "$token")"
  api_call GET "$endpoint?$q"
}
cmd_get() { [[ $# -eq 1 ]] || return 2; api_call GET "/attachments/$(normalize_attachment "$1")"; }
cmd_delete() { [[ $# -eq 1 ]] || return 2; api_call DELETE "/attachments/$(normalize_attachment "$1")"; }
cmd_batch_delete() { (($#)) || return 2; local names=() n; for n in "$@"; do names+=("attachments/$(normalize_attachment "$n")"); done; local payload; payload="$(printf '%s\n' "${names[@]}" | jq -R . | jq -s '{names:.}')"; api_call POST '/attachments:batchDelete' "$payload"; }
usage() { cat <<'EOF'
Usage: attachment-api.sh COMMAND [ARGS]
  upload FILE [--memo-id ID] [--attachment-id ID]
  list [--memo-id ID] [--limit N] [--page-token TOKEN] [--filter EXPR] [--order-by EXPR]
  get ATTACHMENT
  delete ATTACHMENT
  batch-delete ATTACHMENT...
Latest API uses JSON with base64 content at /attachments, not multipart /resources.
EOF
}
main() { local c="${1:-help}"; (($#)) && shift || true; case "$c" in upload) cmd_upload "$@";; list) cmd_list "$@";; get) cmd_get "$@";; delete) cmd_delete "$@";; batch-delete) cmd_batch_delete "$@";; help|-h|--help) usage;; *) usage >&2; return 2;; esac; }
main "$@"
