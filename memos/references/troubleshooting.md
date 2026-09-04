# Memos Troubleshooting

## Credentials

Credential file: `~/.memos`.

```bash
MEMOS_URL="https://memos.example.com"
MEMOS_API_TOKEN="<token>"
```

Set the file permission to `600`. The scripts use this dedicated file exclusively.

## Basic Checks

```bash
SKILL="${HERMES_HOME:-$HOME/.hermes}/skills/integrations/memos"
bash "$SKILL/scripts/user-api.sh" whoami
bash "$SKILL/scripts/memo-api.sh" list --limit 1
```

- HTTP 401/Unauthenticated: the token is missing, invalid, or expired.
- HTTP 403/Permission denied: the token cannot access the resource.
- HTTP 404: the ID is wrong or the command uses an obsolete endpoint.
- HTTP 400/Invalid argument: check the field mask, visibility, state, or CEL syntax.

## Migration from the Original Skill

- `/resources` is obsolete; use `/attachments`.
- Uploads no longer use multipart `-F file=@...`; use JSON with base64 `content`.
- `rowStatus` became `state`.
- The tag filter `tag == "x"` became `"x" in tags`.
- Time filters use `created_ts` and `updated_ts`, not `create_time`.
- Current-user lookup uses `/auth/me`; do not decode the token as a JWT.
- Profiles use `displayName`, not `nickname`.
- The old `/access-tokens` endpoint became `/personalAccessTokens`; use `tokens`, `create-token`, and `delete-token`.

## Local Validation

```bash
bash -n "$SKILL/load-env.sh" "$SKILL/scripts/"*.sh
for s in memo-api search-api tag-api attachment-api user-api; do
  bash "$SKILL/scripts/$s.sh" --help
done
```

Documentation: https://usememos.com/docs/api/latest
