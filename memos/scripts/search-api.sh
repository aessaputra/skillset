#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

usage() { cat <<'EOF'
Usage: search-api.sh QUERY [--tags a,b] [--from YYYY-MM-DD] [--to YYYY-MM-DD]
       [--visibility VALUE] [--state NORMAL|ARCHIVED] [--limit N] [--page-token TOKEN]
EOF
}
(($#)) || { usage >&2; exit 2; }
[[ "$1" == -h || "$1" == --help || "$1" == help ]] && { usage; exit 0; }
query="$1"; shift
tags="" from="" to="" visibility="" state="NORMAL" limit=50 token=""
while (($#)); do case "$1" in
  --tags) tags="$2"; shift 2;; --from) from="$2"; shift 2;; --to) to="$2"; shift 2;;
  --visibility) visibility="$2"; shift 2;; --state) state="$2"; shift 2;;
  --limit) limit="$2"; shift 2;; --page-token) token="$2"; shift 2;;
  *) printf 'ERROR: unknown option: %s\n' "$1" >&2; exit 2;; esac; done
validate_state "$state"; [[ -n "$visibility" ]] && validate_visibility "$visibility"
cel_string() { jq -Rn --arg v "$1" '$v'; }
filters=()
[[ -n "$query" ]] && filters+=("content.contains($(cel_string "$query"))")
if [[ -n "$tags" ]]; then IFS=',' read -ra list <<< "$tags"; for tag in "${list[@]}"; do tag="${tag#\#}"; filters+=("$(cel_string "$tag") in tags"); done; fi
[[ -n "$from" ]] && filters+=("created_ts >= timestamp($(cel_string "${from}T00:00:00Z"))")
[[ -n "$to" ]] && filters+=("created_ts <= timestamp($(cel_string "${to}T23:59:59Z"))")
[[ -n "$visibility" ]] && filters+=("visibility == $(cel_string "$visibility")")
filter=""; if ((${#filters[@]})); then filter="$(IFS=' && '; echo "${filters[*]}")"; fi
args=(list --limit "$limit" --state "$state")
[[ -n "$filter" ]] && args+=(--filter "$filter")
[[ -n "$token" ]] && args+=(--page-token "$token")
exec "$SCRIPT_DIR/memo-api.sh" "${args[@]}"
