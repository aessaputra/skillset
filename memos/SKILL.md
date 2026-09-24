---
name: memos
description: Manage notes, tags, attachments, and profiles through the current self-hosted Memos API. Use when creating, finding, editing, organizing, archiving, deleting, or attaching files to Memos notes.
metadata:
  hermes:
    tags: [memos, notes, knowledge-management, self-hosted]
---

# Memos

Read-write integration for the current Memos REST API at `/api/v1`.

## Setup

Requirements: a reachable Memos instance, an access token from Settings → Access Tokens, `bash`, `curl`, `jq`, `file`, and `base64`.

Store credentials in `~/.memos/config.json`:

```json
{
  "MEMOS_URL": "https://memos.example.com",
  "MEMOS_API_TOKEN": "<access-token>"
}
```

Set its permission to `600`. Never print or expose the token.

Run commands from this skill directory or use absolute paths:

```bash
SKILL="${HERMES_HOME:-$HOME/.hermes}/skills/integrations/memos"
```

## Core commands

```bash
# Create and retrieve
bash "$SKILL/scripts/memo-api.sh" create "Text" --tags "work,idea" --visibility PRIVATE
bash "$SKILL/scripts/memo-api.sh" list --limit 20 --order-by "pinned desc, create_time desc"
bash "$SKILL/scripts/memo-api.sh" get memos/ID

# Search. Filters use current CEL fields: tags, created_ts, visibility, etc.
bash "$SKILL/scripts/search-api.sh" "roadmap" --tags "work" --from 2026-01-01

# Update, pin, archive, delete
bash "$SKILL/scripts/memo-api.sh" update ID "New content" --visibility PROTECTED
bash "$SKILL/scripts/memo-api.sh" update ID --add-tags urgent --pinned true
bash "$SKILL/scripts/memo-api.sh" archive ID
bash "$SKILL/scripts/memo-api.sh" delete ID

# Tags
bash "$SKILL/scripts/tag-api.sh" list
bash "$SKILL/scripts/tag-api.sh" search work
bash "$SKILL/scripts/tag-api.sh" rename old-tag new-tag

# Attachments: latest API uses /attachments with JSON/base64, not /resources multipart
bash "$SKILL/scripts/attachment-api.sh" upload ./document.pdf --memo-id ID
bash "$SKILL/scripts/attachment-api.sh" list --memo-id ID
bash "$SKILL/scripts/attachment-api.sh" delete attachments/ID

# Authenticated user/profile
bash "$SKILL/scripts/user-api.sh" whoami
bash "$SKILL/scripts/user-api.sh" profile
bash "$SKILL/scripts/user-api.sh" update-profile --display-name "Name"
bash "$SKILL/scripts/user-api.sh" tokens
bash "$SKILL/scripts/user-api.sh" create-token --description "Automation" --expires-in-days 90
```

## Current API rules

- Resource names are `memos/{id}`, `attachments/{id}`, and `users/{username}`. Scripts accept either a full resource name or bare final ID where applicable.
- Create/update bodies are the resource object itself, not `{memo:{...}}` or `{attachment:{...}}` wrappers.
- `updateMask` is required for updates.
- Memo state is `NORMAL` or `ARCHIVED`; use `state`, not obsolete `rowStatus`.
- Visibility values are `PRIVATE`, `PROTECTED`, `PUBLIC`, and `SPACE`.
- Tags are extracted from hashtags in Markdown. List filters use `"work" in tags` or `tags.exists(...)`, not obsolete `tag == "work"`.
- Filter timestamps are `created_ts` and `updated_ts`; sorting uses `create_time` and `update_time`.
- Pagination uses `pageSize`, `pageToken`, and response `nextPageToken`.
- Attachments are JSON resources at `/attachments`; binary `content` is base64-encoded.
- Current-user lookup is `GET /auth/me`. Do not decode the access token as a JWT.
- The Personal Access Token API is available at `/users/{user}/personalAccessTokens` for list, create, and delete operations. A token value is returned only once at creation; never display or log it unless explicitly required.

## Safety workflow

- Create/update/archive: execute directly when explicitly requested, then report the returned resource name.
- Delete, batch delete, or bulk rename: show targets and obtain confirmation unless the user already explicitly authorized the exact destructive operation.
- For bulk operations, paginate until `nextPageToken` is empty and report attempted/succeeded/failed counts.

## References

- `references/api-endpoints.md`: current endpoints and fields.
- `references/quick-reference.md`: command examples.
- `references/troubleshooting.md`: failures and diagnostics.
- Official latest API: https://usememos.com/docs/api/latest
- Canonical latest schema: https://github.com/usememos/memos/tree/main/proto/api/v1
