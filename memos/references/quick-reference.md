# Memos Quick Reference

```bash
SKILL="${HERMES_HOME:-$HOME/.hermes}/skills/integrations/memos"
```

## Memos

```bash
bash "$SKILL/scripts/memo-api.sh" create "Note #work" --visibility PRIVATE
bash "$SKILL/scripts/memo-api.sh" list --limit 20 --state NORMAL
bash "$SKILL/scripts/memo-api.sh" list --filter '"work" in tags'
bash "$SKILL/scripts/memo-api.sh" get memos/abc
bash "$SKILL/scripts/memo-api.sh" update abc "Updated content"
bash "$SKILL/scripts/memo-api.sh" update abc --pinned true
bash "$SKILL/scripts/memo-api.sh" archive abc
bash "$SKILL/scripts/memo-api.sh" delete abc
```

## Search and Tags

```bash
bash "$SKILL/scripts/search-api.sh" "kubernetes" --tags devops --from 2026-01-01
bash "$SKILL/scripts/tag-api.sh" list
bash "$SKILL/scripts/tag-api.sh" stats
bash "$SKILL/scripts/tag-api.sh" search devops
bash "$SKILL/scripts/tag-api.sh" rename old-tag new-tag
```

## Attachments

```bash
bash "$SKILL/scripts/attachment-api.sh" upload ./file.pdf --memo-id abc
bash "$SKILL/scripts/attachment-api.sh" list --memo-id abc
bash "$SKILL/scripts/attachment-api.sh" get attachments/xyz
bash "$SKILL/scripts/attachment-api.sh" delete attachments/xyz
bash "$SKILL/scripts/attachment-api.sh" batch-delete attachments/a attachments/b
```

## Users and Tokens

```bash
bash "$SKILL/scripts/user-api.sh" whoami
bash "$SKILL/scripts/user-api.sh" profile
bash "$SKILL/scripts/user-api.sh" profile users/alice
bash "$SKILL/scripts/user-api.sh" update-profile --display-name "Alice"
bash "$SKILL/scripts/user-api.sh" tokens
bash "$SKILL/scripts/user-api.sh" create-token --description "Automation" --expires-in-days 90
bash "$SKILL/scripts/user-api.sh" delete-token users/alice/personalAccessTokens/TOKEN_ID
```

All API output is JSON. Use `jq` for further processing.
