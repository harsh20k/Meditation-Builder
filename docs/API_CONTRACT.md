# Community Library — API Contract

> REST API over API Gateway + Lambda. Base URL: `https://api.meditationbuilder.app/v1`
> (Served via CloudFront distribution; CloudFront origin is the API Gateway invoke URL.)
> Last updated: 2026-06-22.

---

## Conventions

- **Auth header:** `Authorization: Bearer <Cognito access token>` (JWT, HS256/RS256).
- **Content-Type:** `application/json` for all request and response bodies.
- **Pagination:** Cursor-based via `nextToken` (base64-encoded DynamoDB `LastEvaluatedKey`). Page size default: 20, max: 50.
- **Error shape** (all 4xx/5xx):
  ```json
  { "error": "ROUTINE_NOT_FOUND", "message": "No routine with the given id.", "requestId": "abc-123" }
  ```
- **Rate limiting:** API Gateway usage plan — 100 rps burst, 50 rps steady per API key (unauthenticated endpoints share the plan; authenticated endpoints are per-user via Cognito throttle).
- **Request IDs:** `X-Request-Id` header echoed in all responses for tracing.

---

## Endpoints

---

### 1. GET /routines

Browse public community routines (paginated, newest-first).

**Auth:** None (unauthenticated)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `pageSize` | integer | No | 20 | Number of results (max 50) |
| `nextToken` | string | No | — | Pagination cursor from previous response |
| `tag` | string | No | — | Filter by a single tag (exact match, lowercase) |
| `minDuration` | integer | No | — | Minimum `durationSeconds` (inclusive) |
| `maxDuration` | integer | No | — | Maximum `durationSeconds` (inclusive) |
| `sort` | string | No | `newest` | `newest` \| `popular` |

**Request Body:** None

**Success Response — 200 OK:**

```json
{
  "routines": [
    {
      "routineId": "7f3a1b2c-...",
      "name": "Morning Focus",
      "description": "A gentle 10-minute focus routine.",
      "tags": ["focus", "morning"],
      "durationSeconds": 600,
      "authorName": "Jane D.",
      "likeCount": 42,
      "importCount": 17,
      "publishedAt": "2026-06-20T14:00:00Z"
    }
  ],
  "nextToken": "eyJQSyI6...",
  "count": 20
}
```

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 400 | `INVALID_PARAMETER` | `pageSize` > 50, unknown `sort` value, invalid `nextToken` |
| 429 | `THROTTLED` | Rate limit exceeded |
| 500 | `INTERNAL_ERROR` | Unexpected Lambda or DynamoDB failure |

**Cache:** CloudFront TTL 30s (`Cache-Control: max-age=30, s-maxage=30`). Cache key includes query string. Publish Lambda sends `CreateInvalidation` for `/routines*` on new publish. Unauthenticated; no `Vary: Authorization`.

**Latency targets:** p50 <200ms, p95 <250ms, p99 <300ms.

---

### 2. POST /routines

Publish a local routine to the Community Library.

**Auth:** Required (Cognito Bearer token)

**Request Body:**

```json
{
  "name": "Morning Focus",
  "blocks": [
    {
      "blockId": "b1",
      "type": "timer",
      "durationSeconds": 300,
      "label": "Breathing"
    },
    {
      "blockId": "b2",
      "type": "bell",
      "soundKey": "singing_bowl_c",
      "label": "Opening Bell"
    }
  ],
  "durationSeconds": 600,
  "audioAssetKeys": ["audio/abc123.m4a"],
  "userDescription": "My morning focus practice."
}
```

| Field | Type | Required | Constraints |
|---|---|---|---|
| `name` | string | Yes | 1–100 chars |
| `blocks` | array | Yes | 1–50 blocks |
| `blocks[].blockId` | string | Yes | |
| `blocks[].type` | string | Yes | `timer` \| `bell` \| `ambient` |
| `blocks[].durationSeconds` | integer | No | ≥1 for timer/ambient |
| `blocks[].soundKey` | string | No | Required for bell/ambient |
| `blocks[].label` | string | No | 0–80 chars |
| `durationSeconds` | integer | Yes | ≥1 |
| `audioAssetKeys` | string[] | No | S3 keys; max 10 |
| `userDescription` | string | No | 0–500 chars; Bedrock may supplement/replace |

**Success Response — 201 Created:**

```json
{
  "routineId": "7f3a1b2c-...",
  "name": "Morning Focus",
  "publishedAt": "2026-06-20T14:00:00Z",
  "taggingStatus": "pending"
}
```

`taggingStatus` = `"pending"` initially; Bedrock tagging completes asynchronously (<15s p99). Client may re-fetch detail after delay.

**Async side effects (not blocking the 201):**
1. SQS message enqueued → AI-tagging Lambda → Bedrock Claude 3 Haiku → DynamoDB UpdateItem (tags + description) → Typesense upsert.
2. CloudFront invalidation for `/routines*`.
3. DynamoDB Streams event → typesense-indexer Lambda.

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 400 | `INVALID_BODY` | Missing required field or validation failure |
| 401 | `UNAUTHORIZED` | Missing or invalid Bearer token |
| 409 | `ALREADY_EXISTS` | User already published a routine with the same name (warning, not blocking — client may rename) |
| 413 | `PAYLOAD_TOO_LARGE` | blocks array > 50 items or total body > 100KB |
| 429 | `THROTTLED` | Rate limit exceeded |
| 500 | `INTERNAL_ERROR` | Lambda or DynamoDB failure |

**Cache:** Not cached (POST is a mutation).

**Latency targets:** p50 <2s, p95 <5s, p99 <10s (includes DynamoDB write; Bedrock is async).

---

### 3. GET /routines/{id}

Retrieve full detail for a single public routine.

**Auth:** Required (Cognito Bearer token)

**Path Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | string | Yes | UUID v4 routineId |

**Request Body:** None

**Success Response — 200 OK:**

```json
{
  "routineId": "7f3a1b2c-...",
  "name": "Morning Focus",
  "description": "A gentle 10-minute focus routine to start your day.",
  "tags": ["focus", "morning"],
  "durationSeconds": 600,
  "blocks": [
    { "blockId": "b1", "type": "timer", "durationSeconds": 300, "label": "Breathing" },
    { "blockId": "b2", "type": "bell", "soundKey": "singing_bowl_c", "label": "Opening Bell" }
  ],
  "authorName": "Jane D.",
  "authorSub": "apple_abc123",
  "likeCount": 42,
  "importCount": 17,
  "audioAssetKeys": ["audio/abc123.m4a"],
  "publishedAt": "2026-06-20T14:00:00Z",
  "updatedAt": "2026-06-21T09:00:00Z",
  "isLikedByMe": true,
  "isImportedByMe": false
}
```

`isLikedByMe` and `isImportedByMe` are resolved by DynamoDB GetItem checks using the caller's `sub`. Requires auth to populate; unauthenticated calls return `null` for these fields.

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 400 | `INVALID_ID` | `id` is not a valid UUID |
| 401 | `UNAUTHORIZED` | Missing or invalid token |
| 404 | `ROUTINE_NOT_FOUND` | No public routine with this ID exists |
| 429 | `THROTTLED` | |
| 500 | `INTERNAL_ERROR` | |

**Cache:** CloudFront TTL 5 min (`s-maxage=300`). Cache key: path only (`/routines/{id}`). `Vary: Authorization` is NOT set — response is the same for all authenticated users (per-user fields `isLikedByMe`/`isImportedByMe` are populated by a separate non-cached call, or omitted for browse previews). Invalidated by: like Lambda, publish Lambda (on update).

**Latency targets:** p50 <100ms, p95 <200ms, p99 <300ms.

---

### 4. DELETE /routines/{id}

Unpublish and delete the caller's own routine.

**Auth:** Required (Cognito Bearer token)

**Path Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | string | Yes | UUID v4 routineId |

**Request Body:** None

**Success Response — 204 No Content**

Deletes: Routine item + all RoutineTagIndex items (TransactWriteItems, up to 6 items). Sends DynamoDB Streams REMOVE event → Typesense delete.

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 401 | `UNAUTHORIZED` | |
| 403 | `FORBIDDEN` | Caller's `sub` ≠ `authorSub` on the routine |
| 404 | `ROUTINE_NOT_FOUND` | |
| 429 | `THROTTLED` | |
| 500 | `INTERNAL_ERROR` | |

**Cache:** Sends CloudFront invalidation for `/routines/{id}` and `/routines*`.

---

### 5. POST /routines/{id}/like

Like a routine.

**Auth:** Required (Cognito Bearer token)

**Path Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | string | Yes | routineId to like |

**Request Body:** None

**Success Response — 200 OK:**

```json
{ "likeCount": 43 }
```

**Side effects:**
1. DynamoDB PutItem: Like entity (idempotent — condition `attribute_not_exists(SK)`; returns 200 even if already liked).
2. Redis INCR `like:<routineId>` (async flush to DynamoDB every 30s by scheduled Lambda).
3. SNS publish → APNs push notification to routine author (fire-and-forget).
4. CloudFront invalidation for `/routines/{id}`.

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 401 | `UNAUTHORIZED` | |
| 404 | `ROUTINE_NOT_FOUND` | |
| 409 | `ALREADY_LIKED` | User has already liked; returns current `likeCount` |
| 429 | `THROTTLED` | |
| 500 | `INTERNAL_ERROR` | |

---

### 6. DELETE /routines/{id}/like

Remove a like from a routine.

**Auth:** Required (Cognito Bearer token)

**Path Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | string | Yes | routineId to unlike |

**Request Body:** None

**Success Response — 200 OK:**

```json
{ "likeCount": 41 }
```

**Side effects:** DynamoDB DeleteItem (Like entity); Redis DECR `like:<routineId>`; CloudFront invalidation for `/routines/{id}`.

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 401 | `UNAUTHORIZED` | |
| 404 | `ROUTINE_NOT_FOUND` \| `LIKE_NOT_FOUND` | Routine doesn't exist or was never liked |
| 429 | `THROTTLED` | |
| 500 | `INTERNAL_ERROR` | |

---

### 7. POST /routines/{id}/import

Import a community routine to the caller's local library.

**Auth:** Required (Cognito Bearer token)

**Path Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | string | Yes | routineId to import |

**Request Body:** None

**Success Response — 200 OK:**

```json
{
  "routineId": "7f3a1b2c-...",
  "routine": {
    "routineId": "7f3a1b2c-...",
    "name": "Morning Focus",
    "blocks": [...],
    "tags": ["focus", "morning"],
    "durationSeconds": 600,
    "audioAssetKeys": ["audio/abc123.m4a"]
  },
  "importedAt": "2026-06-21T12:00:00Z"
}
```

The `routine` payload contains everything needed for the iOS app to reconstruct the SwiftData object locally.

**Side effects:**
1. DynamoDB PutItem: ImportRecord (condition `attribute_not_exists(SK)` — idempotent; returns 200 on re-import with `alreadyImported: true`).
2. DynamoDB UpdateItem: Routine `importCount` atomic increment (`ADD importCount 1`).
3. Routine metadata fetched via DynamoDB GetItem (or Redis cache).

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 401 | `UNAUTHORIZED` | |
| 404 | `ROUTINE_NOT_FOUND` | |
| 429 | `THROTTLED` | |
| 500 | `INTERNAL_ERROR` | |

---

### 8. GET /recommendations

Retrieve personalized routine recommendations for the authenticated user.

**Auth:** Required (Cognito Bearer token)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `limit` | integer | No | 10 | Max recommendations returned (max 20) |

**Request Body:** None

**Success Response — 200 OK:**

```json
{
  "recommendations": [
    {
      "routineId": "7f3a1b2c-...",
      "name": "Evening Wind Down",
      "description": "A calming bedtime routine.",
      "tags": ["sleep", "calm"],
      "durationSeconds": 900,
      "authorName": "Sam K.",
      "likeCount": 88,
      "importCount": 34,
      "score": 0.94
    }
  ],
  "cacheHit": true,
  "cachedAt": "2026-06-21T11:00:00Z",
  "expiresAt": "2026-06-21T12:00:00Z"
}
```

`score` is the cosine similarity score (0–1) from embedding comparison; for informational/debugging purposes.

**Cache:** Redis per-user cache, TTL 1hr. Cache key: `recommendations:<sub>`. Stale cache is served while a background refresh is triggered if `cachedAt` > 55 min (5-min overlap to avoid thundering herd). Not cached by CloudFront (requires auth; `Vary: Authorization`).

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 401 | `UNAUTHORIZED` | |
| 429 | `THROTTLED` | |
| 500 | `INTERNAL_ERROR` | Bedrock or DynamoDB failure; falls back to latest-published list if recommendations unavailable |

**Latency targets:** p50 <50ms (Redis hit), p95 <100ms, p99 <150ms.

---

### 9. GET /search

Full-text search across routine name, description, and tags via Typesense.

**Auth:** None (unauthenticated)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `q` | string | Yes | — | Search query (1–200 chars) |
| `tag` | string | No | — | Filter by tag (exact match) |
| `minDuration` | integer | No | — | Minimum `durationSeconds` |
| `maxDuration` | integer | No | — | Maximum `durationSeconds` |
| `sort` | string | No | `_text_match` | `_text_match` \| `likeCount:desc` \| `publishedAt:desc` |
| `page` | integer | No | 1 | Page number (1-indexed) |
| `pageSize` | integer | No | 20 | Results per page (max 50) |

**Request Body:** None

**Success Response — 200 OK:**

```json
{
  "results": [
    {
      "routineId": "7f3a1b2c-...",
      "name": "Morning Focus",
      "description": "A gentle 10-minute focus routine.",
      "tags": ["focus", "morning"],
      "durationSeconds": 600,
      "authorName": "Jane D.",
      "likeCount": 42,
      "highlights": {
        "name": "<mark>Morning</mark> Focus",
        "description": "A gentle 10-minute <mark>focus</mark> routine."
      }
    }
  ],
  "found": 127,
  "page": 1,
  "pageSize": 20
}
```

`highlights` contains Typesense-generated HTML snippet with `<mark>` tags around matched tokens.

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 400 | `MISSING_QUERY` | `q` parameter absent or empty |
| 400 | `INVALID_PARAMETER` | Invalid filter value |
| 429 | `THROTTLED` | |
| 503 | `SEARCH_UNAVAILABLE` | Typesense EC2 unreachable; Lambda returns 503 with fallback suggestion to use browse |
| 500 | `INTERNAL_ERROR` | |

**Cache:** Not cached by CloudFront (query string varies too widely). Lambda-level: none (Typesense is already sub-50ms).

**Latency targets:** p50 <50ms, p95 <100ms, p99 <200ms.

---

### 10. POST /activity

Sync a completed meditation session's activity for recommendations.

**Auth:** Required (Cognito Bearer token)

**Request Body:**

```json
{
  "sessionDurationSeconds": 1200,
  "routinesPlayed": ["7f3a1b2c-...", "9b2c3d4e-..."],
  "tagsEngaged": ["focus", "morning"],
  "blockTypes": ["bell", "timer"]
}
```

| Field | Type | Required | Constraints |
|---|---|---|---|
| `sessionDurationSeconds` | integer | Yes | ≥1 |
| `routinesPlayed` | string[] | Yes | 1–20 routineIds |
| `tagsEngaged` | string[] | No | ≤20 tags |
| `blockTypes` | string[] | No | Values: `timer`, `bell`, `ambient` |

**Success Response — 202 Accepted:**

```json
{ "accepted": true }
```

202 (not 200) — processing is async; activity written to DynamoDB by Lambda. iOS treats this as fire-and-forget.

**Side effects:**
1. DynamoDB PutItem: UserActivity entity with 60-day TTL.
2. Redis DEL `recommendations:<sub>` (invalidate stale recommendations cache so next GET /recommendations re-computes).

**Error Responses:**

| Code | Error key | Condition |
|---|---|---|
| 400 | `INVALID_BODY` | Missing required field |
| 401 | `UNAUTHORIZED` | |
| 429 | `THROTTLED` | |
| 500 | `INTERNAL_ERROR` | |

**Cache:** None.

---

## Rate Limiting Summary

| Endpoint | RPS limit | Notes |
|---|---|---|
| GET /routines | 200 rps | CloudFront absorbs most traffic; limit on origin |
| POST /routines | 10 rps per user | Prevents publish spam |
| GET /routines/{id} | 200 rps | CloudFront-served on cache hit |
| DELETE /routines/{id} | 5 rps per user | |
| POST /routines/{id}/like | 20 rps per user | Redis INCR handles burst |
| DELETE /routines/{id}/like | 20 rps per user | |
| POST /routines/{id}/import | 20 rps per user | |
| GET /recommendations | 10 rps per user | Redis cache absorbs repeat calls |
| GET /search | 50 rps | Typesense is the real gate |
| POST /activity | 5 rps per user | Session complete is infrequent |

Limits enforced via API Gateway Usage Plans. Per-user throttling enforced in Lambda handler (returns 429 before DynamoDB write).
