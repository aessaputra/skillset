#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

fetch_all() {
  local token="" first=true page
  printf '{"memos":['
  while :; do
    page="$(api_call GET "/memos?pageSize=1000&state=NORMAL${token:+&pageToken=$(urlencode "$token")}")"
    while IFS= read -r memo; do $first || printf ','; first=false; printf '%s' "$memo"; done < <(jq -c '.memos[]?' <<<"$page")
    token="$(jq -r '.nextPageToken // empty' <<<"$page")"; [[ -n "$token" ]] || break
  done
  printf ']}'
}
cmd_list() { fetch_all | jq '{tags:([.memos[]?.tags[]?]|group_by(.)|map({tag:.[0],count:length})|sort_by(-.count))}'; }
cmd_stats() { fetch_all | jq '{total_memos:(.memos|length),total_tags:([.memos[]?.tags[]?]|unique|length),tagged_memos:([.memos[]?|select((.tags|length)>0)]|length),untagged_memos:([.memos[]?|select((.tags|length)==0)]|length),tags:([.memos[]?.tags[]?]|group_by(.)|map({tag:.[0],count:length})|sort_by(-.count)|.[0:10])}'; }
cmd_search() { [[ $# -eq 1 ]] || return 2; local tag="${1#\#}"; exec "$SCRIPT_DIR/memo-api.sh" list --limit 1000 --filter "$(jq -Rn --arg v "$tag" '$v') in tags"; }
cmd_rename() {
  [[ $# -eq 2 ]] || { echo 'ERROR: old and new tags required' >&2; return 2; }
  local old="${1#\#}" new="${2#\#}" page updated=0 name content changed
  page="$(fetch_all)"
  while IFS= read -r row; do
    name="$(jq -r '.name' <<<"$row")"; content="$(jq -r '.content' <<<"$row")"
    changed="$(OLD_TAG="$old" NEW_TAG="$new" perl -pe 's/(^|\s)\#\Q$ENV{OLD_TAG}\E(?=\s|$)/$1#$ENV{NEW_TAG}/g' <<<"$content")"
    if [[ "$changed" != "$content" ]]; then "$SCRIPT_DIR/memo-api.sh" update "$name" "$changed" >/dev/null; ((updated+=1)); fi
  done < <(jq -c --arg tag "$old" '.memos[]|select(.tags|index($tag))' <<<"$page")
  jq -n --arg old "$old" --arg new "$new" --argjson updated "$updated" '{success:true,updated:$updated,old_tag:$old,new_tag:$new}'
}
usage() { echo 'Usage: tag-api.sh list|stats|search TAG|rename OLD NEW'; }
main() { local c="${1:-help}"; (($#)) && shift || true; case "$c" in list) cmd_list;; stats) cmd_stats;; search) cmd_search "$@";; rename) cmd_rename "$@";; help|-h|--help) usage;; *) usage >&2; return 2;; esac; }
main "$@"
