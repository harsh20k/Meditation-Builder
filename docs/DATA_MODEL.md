# Community Library — Data Model

> DynamoDB single-table design, Typesense indexing strategy, and user activity sync.
> Last updated: 2026-06-22.

---

## 1. DynamoDB Design

### 1.1 Table Choice: Single-table

Single-table chosen over multi-table because:

- All entities share transactional boundaries (a Routine publish touches both the Routine item and the tag-fanout RoutineTagIndex items).
- Access patterns are complementary — the same key prefixes allow heterogeneous items to be stored together without cross-table joins.
- Reduces IAM surface (one table ARN, one set of policies) and operational overhead.
- Aligns with DynamoDB best-practice guidance (Rick Houlihan single-table pattern).

**Trade-off:** Schema is harder to inspect ad-hoc in the console. Mitigated by using `EntityType` attribute on every item for filtering. See ADR-012.

---

### 1.2 Table Definition


| Property      | Value                               |
| ------------- | ----------------------------------- |
| Table name    | `mb-{env}-community`                |
| Partition key | `PK` (String)                       |
| Sort key      | `SK` (String)                       |
| Billing mode  | On-demand (PAY_PER_REQUEST)         |
| PITR          | Enabled                             |
| TTL attribute | `ttl` (Number — Unix epoch seconds) |
| Encryption    | AWS-managed KMS (aws/dynamodb)      |


---

### 1.3 Entity Types

#### Routine


| Attribute         | Type | Example Value          | Notes                                          |
| ----------------- | ---- | ---------------------- | ---------------------------------------------- |
| `PK`              | S    | `ROUTINE#<routineId>`  | UUID v4                                        |
| `SK`              | S    | `METADATA`             | Literal string                                 |
| `EntityType`      | S    | `Routine`              |                                                |
| `routineId`       | S    | `7f3a...`              | UUID v4                                        |
| `authorSub`       | S    | `apple_abc123`         | Cognito sub from Apple OIDC                    |
| `authorName`      | S    | `Jane D.`              | Display name (denormalized)                    |
| `name`            | S    | `Morning Focus`        |                                                |
| `description`     | S    | `A gentle 10-min...`   | AI-generated or user-edited                    |
| `tags`            | SS   | `["focus","morning"]`  | StringSet, ≤5 tags                             |
| `durationSeconds` | N    | `600`                  |                                                |
| `blocks`          | S    | `[{...}]`              | JSON string — full block structure             |
| `audioAssetKeys`  | SS   | `["audio/abc.m4a"]`    | S3 keys; may be empty                          |
| `likeCount`       | N    | `42`                   | Flushed from Redis every 30s                   |
| `importCount`     | N    | `17`                   | Incremented on import                          |
| `publishedAt`     | S    | `2026-06-20T14:00:00Z` | ISO-8601; used for GSI sort                    |
| `updatedAt`       | S    | `2026-06-21T09:00:00Z` |                                                |
| `isPublic`        | BOOL | `true`                 | Gate for GSI1 index entry                      |
| `typesenseSynced` | BOOL | `false`                | Set true after Streams → Typesense sync        |
| `GSI1PK`          | S    | `PUBLIC`               | Written only when `isPublic=true`; drives GSI1 |
| `GSI2PK`          | S    | `USER#<authorSub>`     | Drives GSI2 (author's routines)                |


---

#### RoutineTagIndex *(tag fanout)*

One item written per tag per routine at publish time (up to 5 items per routine).


| Attribute         | Type | Example Value                      | Notes                                                       |
| ----------------- | ---- | ---------------------------------- | ----------------------------------------------------------- |
| `PK`              | S    | `TAG#focus`                        | Lowercase tag name                                          |
| `SK`              | S    | `2026-06-20T14:00:00Z#<routineId>` | publishedAt + routineId — ensures uniqueness and sort order |
| `EntityType`      | S    | `RoutineTagIndex`                  |                                                             |
| `routineId`       | S    | `7f3a...`                          |                                                             |
| `name`            | S    | `Morning Focus`                    | Denormalized                                                |
| `authorName`      | S    | `Jane D.`                          | Denormalized                                                |
| `durationSeconds` | N    | `600`                              | Denormalized                                                |
| `likeCount`       | N    | `42`                               | Periodically refreshed by flush Lambda                      |


*Deleted transactionally with the Routine item on unpublish/delete.*

---

#### User


| Attribute      | Type | Example Value          | Notes |
| -------------- | ---- | ---------------------- | ----- |
| `PK`           | S    | `USER#<sub>`           |       |
| `SK`           | S    | `PROFILE`              |       |
| `EntityType`   | S    | `User`                 |       |
| `sub`          | S    | `apple_abc123`         |       |
| `displayName`  | S    | `Jane D.`              |       |
| `publishCount` | N    | `3`                    |       |
| `importCount`  | N    | `11`                   |       |
| `joinedAt`     | S    | `2026-06-01T00:00:00Z` |       |


---

#### Like


| Attribute    | Type | Example Value          | Notes |
| ------------ | ---- | ---------------------- | ----- |
| `PK`         | S    | `USER#<sub>`           |       |
| `SK`         | S    | `LIKE#<routineId>`     |       |
| `EntityType` | S    | `Like`                 |       |
| `routineId`  | S    | `7f3a...`              |       |
| `likedAt`    | S    | `2026-06-20T18:00:00Z` |       |


*Like-check is a O(1) GetItem. Like count is incremented via Redis INCR and flushed to Routine item asynchronously.*

---

#### ImportRecord


| Attribute    | Type | Example Value          | Notes |
| ------------ | ---- | ---------------------- | ----- |
| `PK`         | S    | `USER#<sub>`           |       |
| `SK`         | S    | `IMPORT#<routineId>`   |       |
| `EntityType` | S    | `ImportRecord`         |       |
| `routineId`  | S    | `7f3a...`              |       |
| `importedAt` | S    | `2026-06-20T18:30:00Z` |       |


*Idempotent: PutItem with condition `attribute_not_exists(SK)` prevents double-import. Import count on the Routine is incremented with UpdateItem atomic counter.*

---

#### UserActivity


| Attribute                | Type | Example Value                | Notes                                |
| ------------------------ | ---- | ---------------------------- | ------------------------------------ |
| `PK`                     | S    | `USER#<sub>`                 |                                      |
| `SK`                     | S    | `ACTIVITY#<ISO-timestamp>`   | e.g. `ACTIVITY#2026-06-20T14:55:00Z` |
| `EntityType`             | S    | `UserActivity`               |                                      |
| `sessionDurationSeconds` | N    | `1200`                       |                                      |
| `routinesPlayed`         | SS   | `["7f3a...","9b2c..."]`      | Routine IDs                          |
| `tagsEngaged`            | SS   | `["focus","morning"]`        | Union of tags from played routines   |
| `blockTypes`             | SS   | `["bell","timer","ambient"]` |                                      |
| `createdAt`              | S    | `2026-06-20T14:55:00Z`       |                                      |
| `ttl`                    | N    | `1753027200`                 | 60-day expiry (Unix epoch)           |


*TTL set to `createdAt + 60 days`. Only last 60 days of activity are retained — sufficient for recommendations. No PII stored beyond the Cognito `sub` claim.*

---

### 1.4 GSI Definitions

#### GSI1 — BrowseNewest


| Property   | Value                                                                                             |
| ---------- | ------------------------------------------------------------------------------------------------- |
| Index name | `GSI1-public-by-date`                                                                             |
| PK         | `GSI1PK` (String) — value `"PUBLIC"`                                                              |
| SK         | `publishedAt` (String — ISO-8601, lexicographic sort = chronological sort)                        |
| Projection | INCLUDE: `routineId, name, authorName, durationSeconds, tags, likeCount, importCount`             |
| Written by | Publish Lambda (sets `GSI1PK = "PUBLIC"`)                                                         |
| Deleted by | Unpublish Lambda (removes `GSI1PK` attribute — removes item from GSI)                             |
| Serves     | GET /routines browse — paginated newest-first, optionally filtered by duration on the client side |


**Query:** `GSI1PK = "PUBLIC"`, scan index forward = false (newest first), page size = 20, ExclusiveStartKey for pagination.

---

#### GSI2 — AuthorRoutines


| Property   | Value                                                    |
| ---------- | -------------------------------------------------------- |
| Index name | `GSI2-author-routines`                                   |
| PK         | `GSI2PK` (String) — value `"USER#<sub>"`                 |
| SK         | `publishedAt` (String)                                   |
| Projection | ALL                                                      |
| Serves     | Get user's own published routines (US-8 creator profile) |


**Query:** `GSI2PK = "USER#<sub>"`, scan index forward = false.

---

### 1.5 Access Pattern Summary


| Access Pattern                    | Method        | Key Condition                                   | Index      | Notes                                 |
| --------------------------------- | ------------- | ----------------------------------------------- | ---------- | ------------------------------------- |
| Browse newest public routines     | Query         | `GSI1PK = "PUBLIC"`                             | GSI1       | Newest-first, paginated, 20/page      |
| Browse by tag                     | Query         | `PK = "TAG#<tag>"`                              | Main table | SK sort gives newest-first within tag |
| Get routine by ID                 | GetItem       | `PK = "ROUTINE#<id>", SK = "METADATA"`          | —          | O(1); hits Redis L1 cache first       |
| Get user's published routines     | Query         | `GSI2PK = "USER#<sub>"`                         | GSI2       | Profile view                          |
| Get user's imported routines      | Query         | `PK = "USER#<sub>", SK begins_with "IMPORT#"`   | Main table |                                       |
| Get user's liked routines         | Query         | `PK = "USER#<sub>", SK begins_with "LIKE#"`     | Main table |                                       |
| Like / unlike check               | GetItem       | `PK = "USER#<sub>", SK = "LIKE#<routineId>"`    | —          | O(1) check before write               |
| Import check (idempotency)        | GetItem       | `PK = "USER#<sub>", SK = "IMPORT#<routineId>"`  | —          |                                       |
| User activity for recommendations | Query         | `PK = "USER#<sub>", SK begins_with "ACTIVITY#"` | Main table | Last-N items, bounded by 60-day TTL   |
| Delete routine + tag fanout       | TransactWrite | Batch: Routine + all RoutineTagIndex items      | —          | Up to 6 items per transaction         |


---

## 2. Typesense Indexing Strategy

### 2.1 Collection Schema

Collection name: `routines`


| Field             | Type     | Facet | Sort | Notes                                       |
| ----------------- | -------- | ----- | ---- | ------------------------------------------- |
| `id`              | string   | —     | —    | Equals `routineId`                          |
| `name`            | string   | —     | —    | Full-text indexed                           |
| `description`     | string   | —     | —    | Full-text indexed                           |
| `tags`            | string[] | Yes   | —    | Facet filter by tag                         |
| `durationSeconds` | int32    | —     | Yes  | Range filter (`durationSeconds:[300..900]`) |
| `authorName`      | string   | —     | —    | Full-text indexed                           |
| `likeCount`       | int32    | —     | Yes  | Sort by popularity                          |
| `importCount`     | int32    | —     | Yes  |                                             |
| `publishedAt`     | int64    | —     | Yes  | Unix epoch seconds                          |


Default sorting: `likeCount:desc` (most popular first when no search query).

---

### 2.2 Indexing Pipeline

**Chosen approach: DynamoDB Streams → Lambda → Typesense** (decoupled; no synchronous dependency in the publish path). See ADR-013.

```
iOS Publish
    └─► POST /routines Lambda
            ├─► DynamoDB PutItem (Routine item)
            └─► return 201 to client (immediately)

DynamoDB Stream (NEW_AND_OLD_IMAGES)
    └─► typesense-indexer Lambda (triggered on stream)
            ├─► INSERT event  → Typesense upsert document
            ├─► MODIFY event  → Typesense upsert document (updates name/desc/tags/likeCount)
            └─► REMOVE event  → Typesense delete document
```

- Stream trigger: filter for `EntityType = "Routine"` items only (skip tag-fanout and user items).
- Lambda sets `typesenseSynced = true` on the DynamoDB item after successful Typesense upsert.
- Retry: Lambda reserved concurrency = 2; DynamoDB Streams retries up to 24 hrs on failure.
- Lag: Typically <1s (stream event delivered within one shard polling interval of 1s).

---

### 2.3 Re-indexing on Update / Delete


| Event                                   | Action                                                                        |
| --------------------------------------- | ----------------------------------------------------------------------------- |
| Routine updated (name/description/tags) | MODIFY stream event → Typesense upsert by `id` (overwrites document)          |
| Routine deleted / unpublished           | REMOVE stream event → Typesense `DELETE /collections/routines/documents/<id>` |
| likeCount flush (Redis → DynamoDB)      | MODIFY stream event → Typesense upsert updates `likeCount` field              |


**Full re-index:** A one-off Lambda (or CLI script) scans the DynamoDB table for all `EntityType = "Routine"` items and bulk-imports to Typesense using `/documents/import?action=upsert`. Needed after Typesense instance replacement.

---

### 2.4 Backup

- **Snapshot schedule:** Daily at 03:00 UTC via EventBridge rule → Lambda → Typesense `/operations/snapshot` API → S3 bucket `mb-{env}-typesense-backups`.
- **Retention:** 7 daily snapshots (S3 lifecycle policy expires after 7 days).
- **Restore:** On EC2 replacement, restore from latest snapshot and trigger full DynamoDB re-index to catch any delta.

---

## 3. User Activity Sync Strategy

### 3.1 What Activity Is Collected


| Signal                   | Source                         | Used For                                  |
| ------------------------ | ------------------------------ | ----------------------------------------- |
| `routinesPlayed`         | SwiftData session records      | Tag affinity, duration preference         |
| `tagsEngaged`            | Derived from played routines   | Direct input to recommendation embedding  |
| `sessionDurationSeconds` | SwiftData                      | Duration preference band                  |
| `blockTypes`             | SwiftData (bell/timer/ambient) | Content-type preference                   |
| `importHistory`          | ImportRecord items in DynamoDB | Already recorded server-side; not re-sent |


### 3.2 Sync Trigger: POST /activity

- Called **on session complete** (user exits meditation session), not on app open.
- Fire-and-forget from iOS: errors are swallowed silently; failed syncs are retried on the next session complete.
- Batching: one POST per session, not per routine played.

**Request body:**

```json
{
  "sessionDurationSeconds": 1200,
  "routinesPlayed": ["7f3a...", "9b2c..."],
  "tagsEngaged": ["focus", "morning"],
  "blockTypes": ["bell", "timer"]
}
```

No PII in request body. The `sub` claim is extracted from the Cognito JWT (`Authorization: Bearer <access_token>`) by the API Gateway authorizer; the Lambda uses it as the storage key.

### 3.3 DynamoDB Storage

Item written by the activity Lambda:

```
PK  = "USER#<sub>"
SK  = "ACTIVITY#2026-06-20T14:55:00Z"
EntityType = "UserActivity"
sessionDurationSeconds = 1200
routinesPlayed = {"7f3a...", "9b2c..."}    -- StringSet
tagsEngaged    = {"focus", "morning"}       -- StringSet
blockTypes     = {"bell", "timer"}          -- StringSet
createdAt = "2026-06-20T14:55:00Z"
ttl = 1753027200   -- createdAt + 60 days, Unix epoch
```

- **TTL:** 60 days. Older activity is irrelevant for recommendation freshness and its removal reduces storage cost.
- **Query:** Recommendation Lambda queries `PK = "USER#<sub>", SK begins_with "ACTIVITY#"`, ScanIndexForward = false, Limit = 50 (last 50 sessions ≈ ~90 days of regular use, bounded by TTL).

### 3.4 Recommendation Flow

```
GET /recommendations (authenticated)
    └─► recommendations Lambda
            ├─► Redis GET recommendations:<sub>   → HIT → return (p50 <50ms)
            │                                     → MISS ↓
            ├─► DynamoDB Query UserActivity (last 50)
            ├─► Aggregate tagsEngaged into tag-frequency vector
            ├─► Bedrock InvokeModel: embed tag vector + fetch routine embeddings
            ├─► Cosine similarity → top-10 routineIds
            ├─► DynamoDB BatchGetItem for routine metadata
            ├─► Redis SET recommendations:<sub> TTL=3600
            └─► return ranked routine list
```

### 3.5 Privacy Notes

- Activity stored keyed by `sub` (opaque Cognito identifier derived from Apple's anonymous sub).
- No email, name, or device identifier stored in UserActivity.
- Apple may rotate the `sub` on app reinstall (if user revokes); new activity starts fresh — no data linkage risk.
- 60-day TTL ensures data is not retained indefinitely.

