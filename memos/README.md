# Memos Skill for Hermes

Self-hosted Memos integration using the latest API at `/api/v1`.

## Configuration

Store the following variables in `~/.memos`:

```bash
MEMOS_URL="https://memos.example.com"
MEMOS_API_TOKEN="<access-token>"
```

Set the file permission to `600`. Create the token from Settings → Access Tokens in the Memos UI.

## Usage

```bash
SKILL="${HERMES_HOME:-$HOME/.hermes}/skills/integrations/memos"
bash "$SKILL/scripts/memo-api.sh" --help
bash "$SKILL/scripts/search-api.sh" --help
bash "$SKILL/scripts/tag-api.sh" --help
bash "$SKILL/scripts/attachment-api.sh" --help
bash "$SKILL/scripts/user-api.sh" --help
```

Major changes from the original skill:

- Attachments use `/attachments` with JSON/base64 instead of multipart `/resources`.
- Archiving uses the `state` field instead of `rowStatus`.
- Tag filters use `"tag" in tags`.
- Current-user lookup uses `/auth/me`.
- Primary configuration follows the active Hermes profile.

See `SKILL.md` and `references/` for complete documentation.
