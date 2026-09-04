# Latest Memos API

This reference follows the `latest` documentation and the protobuf schema from the `main` branch.

## General

- Base URL: `${MEMOS_URL}/api/v1`
- Authentication: `Authorization: Bearer <token>`
- JSON fields use lowerCamelCase.
- Pagination uses `pageSize` and `pageToken`; responses return `nextPageToken`.
- Update operations require the `updateMask` query parameter.

## Memos

| Operation | Method and endpoint |
|---|---|
| Create | `POST /memos[?memoId=ID]` |
| List | `GET /memos` |
| Get | `GET /memos/{memo}` |
| Update | `PATCH /memos/{memo}?updateMask=...` |
| Delete | `DELETE /memos/{memo}[?force=true]` |
| Set attachments | `PATCH /memos/{memo}/attachments` |
| List attachments | `GET /memos/{memo}/attachments` |
| Set/list relations | `PATCH/GET /memos/{memo}/relations` |
| Create/list comments | `POST/GET /memos/{memo}/comments` |
| List/upsert reactions | `GET/POST /memos/{memo}/reactions` |
| Shares | `POST/GET /memos/{memo}/shares` |

Minimum create body:

```json
{"content":"Markdown #tag","visibility":"PRIVATE"}
```

An update body contains only the changed fields. Archive example:

```http
PATCH /memos/abc?updateMask=state
{"state":"ARCHIVED"}
```

Visibility values: `PRIVATE`, `PROTECTED`, `PUBLIC`, and `SPACE`. State values: `NORMAL` and `ARCHIVED`.

List queries support `state`, `orderBy`, `filter`, and `showDeleted`. Filters use CEL. Important fields include:

- `content`, `creator`, `created_ts`, `updated_ts`, `pinned`, `visibility`, `space`, and `tags`
- `has_task_list`, `has_link`, `has_code`, `has_incomplete_tasks`, and `has_location`

Examples:

```text
"work" in tags
content.contains("roadmap") && created_ts >= timestamp("2026-01-01T00:00:00Z")
pinned == true && visibility == "PUBLIC"
```

Time fields differ in `orderBy`: use `create_time` and `update_time`.

## Attachments

The latest API replaces multipart `/resources` with JSON-based `/attachments`.

| Operation | Method and endpoint |
|---|---|
| Create | `POST /attachments[?attachmentId=ID]` |
| List | `GET /attachments` |
| Get | `GET /attachments/{attachment}` |
| Update | `PATCH /attachments/{attachment}?updateMask=...` |
| Delete | `DELETE /attachments/{attachment}` |
| Batch delete | `POST /attachments:batchDelete` |

Create body:

```json
{
  "filename": "document.pdf",
  "content": "<base64>",
  "type": "application/pdf",
  "memo": "memos/abc"
}
```

The `memo` field is optional. List operations support `pageSize`, `pageToken`, `filter`, and `orderBy`.

## Authentication and Users

- Current user: `GET /auth/me`; response shape: `{ "user": {...} }`.
- Get user: `GET /users/{username}`.
- Update user: `PATCH /users/{username}?updateMask=...`.
- The current display-name field is `displayName`, not `nickname`.

Personal Access Tokens (PATs):

- List: `GET /users/{user}/personalAccessTokens?pageSize=...`
- Create: `POST /users/{user}/personalAccessTokens` with `{"description":"Automation","expiresInDays":90}`
- Delete: `DELETE /users/{user}/personalAccessTokens/{token}`
- The token value appears only in the create response; list responses contain metadata only.

PATs can also be created through Settings → Access Tokens in the Memos UI.

## Sources

- https://usememos.com/docs/api/latest
- https://raw.githubusercontent.com/usememos/memos/main/proto/api/v1/memo_service.proto
- https://raw.githubusercontent.com/usememos/memos/main/proto/api/v1/attachment_service.proto
- https://raw.githubusercontent.com/usememos/memos/main/proto/api/v1/auth_service.proto
- https://raw.githubusercontent.com/usememos/memos/main/proto/api/v1/user_service.proto
