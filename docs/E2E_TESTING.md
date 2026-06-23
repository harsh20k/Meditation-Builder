# Meditation Builder — End-to-End Testing Checklist

> **Scope:** Staging environment (`us-east-1`), table `mb-staging-community`.  
> **Base URL:** `https://api.meditationbuilder.app/v1` (CloudFront → API Gateway).  
> **Cognito domain:** `mb-staging.auth.us-east-1.amazoncognito.com`  
> **Last updated:** 2026-06-23

---

## 0. Pre-requisites

| Tool | Version |
|---|---|
| Terraform | 1.9.0 |
| AWS CLI | ≥2.x, configured with an IAM principal that can assume `$AWS_ROLE_ARN` |
| Python | ≥3.10 |
| Newman | latest (`npm install -g newman`) |
| Xcode | ≥15 (iOS 17 SDK) |

---

## 1. Pre-flight Setup

### 1.1 Terraform Bootstrap (one-time, per AWS account)

- [ ] `cd infrastructure/terraform/bootstrap`
- [ ] `terraform init`
- [ ] `terraform apply` — creates S3 state bucket (`mb-tfstate-<account-id>`) and DynamoDB lock table (`mb-tfstate-locks`)
- [ ] Confirm S3 bucket exists: `aws s3 ls | grep mb-tfstate`
- [ ] Confirm DynamoDB lock table exists: `aws dynamodb describe-table --table-name mb-tfstate-locks`

**Troubleshooting:**
- *AccessDenied on bucket creation* → ensure the IAM role has `s3:CreateBucket`, `dynamodb:CreateTable`
- *Bucket already exists in another account* → rename bucket in `bootstrap/main.tf`

---

### 1.2 Terraform Apply — Staging

- [ ] `cd infrastructure/terraform`
- [ ] `terraform init -input=false`
- [ ] `terraform workspace select staging || terraform workspace new staging`
- [ ] Package Lambda artifacts first: `bash ../lambdas/package.sh`
- [ ] `terraform plan -var-file=environments/staging.tfvars -out=tfplan`
- [ ] Review plan — confirm no unexpected destroys
- [ ] `terraform apply tfplan`
- [ ] Capture outputs: `terraform output -json > /tmp/tf-outputs-staging.json`
- [ ] Note `api_gateway_invoke_url`, `cloudfront_domain`, `cognito_user_pool_id`, `cognito_client_id`, `redis_endpoint`, `typesense_ec2_ip`

**Troubleshooting:**
- *Lambda zip not found* → re-run `package.sh`; check it creates `infrastructure/lambdas/dist/*.zip`
- *Timeout on ElastiCache/Typesense EC2* → these take ~5 min; re-run `terraform apply`

---

### 1.3 Apple Developer — Sign in with Apple Setup

- [ ] In [developer.apple.com](https://developer.apple.com) → Certificates, IDs & Profiles → Identifiers, create a **Services ID** (e.g. `com.AnimeAI.Meditation-Builder.siwa`)
- [ ] Enable *Sign In with Apple* on the Services ID
- [ ] Add **Return URL**: `https://mb-staging.auth.us-east-1.amazoncognito.com/oauth2/idpresponse`
- [ ] Create a **Sign in with Apple** private key; download the `.p8` file; note Key ID and Team ID
- [ ] Store in SSM:

```bash
aws ssm put-parameter \
  --name /mb/staging/apple/team-id \
  --value "<TEAM_ID>" --type SecureString --overwrite

aws ssm put-parameter \
  --name /mb/staging/apple/key-id \
  --value "<KEY_ID>" --type SecureString --overwrite

aws ssm put-parameter \
  --name /mb/staging/apple/private-key \
  --value "$(cat AuthKey_<KEY_ID>.p8)" --type SecureString --overwrite

aws ssm put-parameter \
  --name /mb/staging/apple/services-id \
  --value "com.AnimeAI.Meditation-Builder.siwa" --type SecureString --overwrite
```

**Troubleshooting:**
- *Cognito "invalid_client" on SIWA federation* → verify Services ID matches SSM parameter exactly
- *"redirect_uri_mismatch"* → confirm the Return URL on the Services ID matches `cognito_domain/oauth2/idpresponse`

---

### 1.4 Cognito Hosted UI — Callback URL Registration

- [ ] In the AWS Console → Cognito → User Pools → `mb-staging-user-pool` → App client → Hosted UI
- [ ] Add **Allowed callback URL**: `com.AnimeAI.Meditation-Builder://oauth2/callback`
- [ ] Add **Allowed sign-out URL**: `com.AnimeAI.Meditation-Builder://oauth2/logout`
- [ ] Confirm identity provider **SignInWithApple** is enabled on the app client

**Troubleshooting:**
- *ASWebAuthenticationSession fails with "redirect_uri_mismatch"* → the custom URL scheme above must match `AuthConfig.redirectURI` exactly

---

### 1.5 Populate `AuthConfig.swift`

After `terraform output` supplies values, update the two placeholders in `Meditation Builder/Models/AuthConfig.swift`:

- [ ] `userPoolID` ← `terraform output -raw cognito_user_pool_id`  
  e.g. `us-east-1_AbcDeFghi`
- [ ] `appClientID` ← `terraform output -raw cognito_app_client_id`  
  e.g. `3abc1234xyz`
- [ ] Verify `domain` is still `mb-staging.auth.us-east-1.amazoncognito.com` (matches Terraform variable `cognito_domain`)
- [ ] Verify `redirectURI` = `com.AnimeAI.Meditation-Builder://oauth2/callback` (matches step 1.4)

**Troubleshooting:**
- *Build warning "PLACEHOLDER"* → grep for `PLACEHOLDER` in `AuthConfig.swift`; both must be replaced before testing

---

### 1.6 Xcode Provisioning

- [ ] Open `Meditation Builder.xcodeproj` in Xcode
- [ ] Target → Signing & Capabilities → confirm **Sign in with Apple** entitlement exists (from `Meditation Builder.entitlements`)
- [ ] Select a real device or Simulator with iOS 17+
- [ ] Set provisioning profile to an explicit profile that includes the App ID `com.AnimeAI.Meditation-Builder`
- [ ] Build succeeds with zero errors: `Product → Build`

**Troubleshooting:**
- *"Provisioning profile doesn't include Sign in with Apple"* → regenerate profile in developer portal with SIWA capability

---

### 1.7 Seed Script

- [ ] Export required env vars:

```bash
export DYNAMODB_TABLE_NAME=mb-staging-community
export COGNITO_USER_POOL_ID=$(terraform -chdir=infrastructure/terraform output -raw cognito_user_pool_id)
export TYPESENSE_HOST=$(terraform -chdir=infrastructure/terraform output -raw typesense_ec2_public_ip)
export TYPESENSE_PORT=8108
export TYPESENSE_PROTOCOL=http
export TYPESENSE_API_KEY=$(aws ssm get-parameter --name /mb/staging/typesense/api-key --with-decryption --query Parameter.Value --output text)
```

- [ ] `cd infrastructure/scripts && pip install -r requirements.txt`
- [ ] `python3 seed.py --env staging --count 20`
- [ ] Confirm JSON output contains `seededRoutineIds` (20 entries) and `users` (2 entries)
- [ ] Note the two test user credentials stored in SSM at `/mb/staging/test/user1-password` and `/mb/staging/test/user2-password`

**Troubleshooting:**
- *`COGNITO_USER_POOL_ID` not set* → seed falls back to fake `sub` values (`seed-user-1`/`seed-user-2`); Cognito test users won't be created
- *Typesense upsert fails silently* → `TYPESENSE_API_KEY` empty; verify SSM parameter

---

## 2. Infrastructure Validation

Run all checks from the AWS CLI after `terraform apply` completes.

### 2.1 DynamoDB

- [ ] Table exists: `aws dynamodb describe-table --table-name mb-staging-community`
- [ ] Table status is `ACTIVE`
- [ ] GSI `GSI1-public-by-date` status is `ACTIVE`
- [ ] GSI `GSI2-author-routines` status is `ACTIVE`
- [ ] PITR enabled: `aws dynamodb describe-continuous-backups --table-name mb-staging-community` → `PointInTimeRecoveryStatus: ENABLED`
- [ ] TTL enabled on attribute `ttl`: check `TimeToLiveDescription.AttributeName = ttl`

**Troubleshooting:**
- *GSI status `CREATING`* → wait 2–5 min; DynamoDB provisions GSI capacity asynchronously
- *PITR not enabled* → check `aws_dynamodb_table` resource in `infrastructure/terraform/modules/storage/main.tf`

---

### 2.2 S3

- [ ] Bucket exists: `aws s3 ls | grep mb-staging`
- [ ] CORS configuration present:
  ```bash
  aws s3api get-bucket-cors --bucket mb-staging-assets
  ```
  Confirm `AllowedOrigins` includes the app domain or `*`, `AllowedMethods` includes `GET`

**Troubleshooting:**
- *NoSuchCORSConfiguration* → Terraform CORS resource failed; re-run `terraform apply`

---

### 2.3 Redis (ElastiCache)

- [ ] Cluster endpoint from Terraform output: `terraform output -raw redis_endpoint`
- [ ] From a Lambda test invocation (or EC2 in the same VPC), `redis-cli -h <endpoint> -p 6379 PING` → `PONG`
- [ ] Alternatively, invoke GET /routines/{id} twice and check CloudWatch logs for the Lambda — second call should log `cache hit`

**Troubleshooting:**
- *Connection refused / timeout* → Lambda VPC security group must allow outbound TCP 6379 to the ElastiCache SG; check `infrastructure/terraform/modules/cache`
- *NOAUTH error* → Redis AUTH token mismatch; verify `REDIS_AUTH_TOKEN` Lambda env var matches SSM

---

### 2.4 Typesense EC2

- [ ] Instance running: `aws ec2 describe-instances --filters "Name=tag:Name,Values=mb-staging-typesense" --query "Reservations[].Instances[].State.Name"`
- [ ] Health check (from internet if security group allows, otherwise from a Lambda):
  ```bash
  curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
       http://<typesense_ec2_ip>:8108/health
  ```
  Expected: `{"ok":true}`
- [ ] Collection exists:
  ```bash
  curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
       http://<typesense_ec2_ip>:8108/collections/routines
  ```
  Expected: schema with fields `name`, `description`, `tags`, `durationSeconds`, `likeCount`

**Troubleshooting:**
- *curl: Connection refused* → SSH to EC2; `systemctl status typesense` — restart with `systemctl restart typesense`; check `/var/log/typesense/typesense.log`
- *`collection not found`* → collection not yet created; run the re-index script or trigger a Typesense schema migration

---

### 2.5 API Gateway

- [ ] Stage URL accessible: `curl -i $(terraform output -raw api_gateway_invoke_url)/routines` → HTTP 200
- [ ] Stage is `staging`, not `default`
- [ ] `X-Request-Id` header present in response

**Troubleshooting:**
- *403 Forbidden on invoke URL* → API Gateway resource policy or usage plan key missing; check Lambda authorizer and `aws_api_gateway_usage_plan`

---

### 2.6 CloudFront

- [ ] Distribution status `Deployed`: `aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='mb-staging'].Status"`
- [ ] Domain accessible: `curl -I https://$(terraform output -raw cloudfront_domain)/routines` → `HTTP/2 200`
- [ ] Cache header present: `x-cache: Hit from cloudfront` on second request (wait 1s after first)

**Troubleshooting:**
- *Distribution status `InProgress`* → wait 10–15 min for CloudFront propagation
- *522/523 from CloudFront* → origin (API Gateway) unreachable; check API GW stage URL directly

---

### 2.7 SQS

- [ ] Queue exists: `aws sqs list-queues --queue-name-prefix mb-staging` — confirm `mb-staging-tagging` queue URL
- [ ] DLQ exists: confirm `mb-staging-tagging-dlq` queue URL
- [ ] DLQ depth zero: `aws sqs get-queue-attributes --queue-url <DLQ_URL> --attribute-names ApproximateNumberOfMessages`

**Troubleshooting:**
- *DLQ messages accumulating* → see §6.5

---

### 2.8 SNS

- [ ] Topic exists: `aws sns list-topics | grep mb-staging`
- [ ] Topic ARN matches Lambda env var `SNS_TOPIC_ARN`

---

### 2.9 CloudWatch Log Groups

- [ ] Log groups exist for each Lambda:
  ```bash
  aws logs describe-log-groups --log-group-name-prefix /aws/lambda/mb-staging
  ```
  Expected groups: `get_routines`, `post_routine`, `get_routine`, `delete_routine`, `like_routine`, `unlike_routine`, `import_routine`, `recommendations`, `search`, `post_activity`, `bedrock_tagger`, `typesense_indexer`, `like_flush`

**Troubleshooting:**
- *Missing log group* → Lambda was never invoked; invoke it once manually or via the Postman collection

---

### 2.10 Lambda Functions

- [ ] All 13 functions exist: `aws lambda list-functions --query "Functions[?starts_with(FunctionName,'mb-staging')].FunctionName"`
- [ ] Each has correct env vars set (sample check on `mb-staging-post-routine`):
  ```bash
  aws lambda get-function-configuration --function-name mb-staging-post-routine \
    --query "Environment.Variables"
  ```
  Verify: `DYNAMODB_TABLE_NAME`, `SQS_TAGGING_QUEUE_URL`, `CLOUDFRONT_DISTRIBUTION_ID`, `REDIS_ENDPOINT`, `TYPESENSE_HOST`, `TYPESENSE_API_KEY`

**Troubleshooting:**
- *Missing env var* → update `infrastructure/terraform/lambdas.tf` and re-apply

---

## 3. Seed & Data Layer Validation

### 3.1 Seed Run

- [ ] `python3 infrastructure/scripts/seed.py --env staging --count 20` exits 0
- [ ] Output JSON contains exactly 20 `seededRoutineIds`
- [ ] Output JSON contains 2 user entries

---

### 3.2 DynamoDB Verification

- [ ] Scan for Routine items:
  ```bash
  aws dynamodb scan \
    --table-name mb-staging-community \
    --filter-expression "EntityType = :r" \
    --expression-attribute-values '{":r":{"S":"Routine"}}' \
    --select COUNT \
    --query Count
  ```
  Expected: ≥20

- [ ] Scan for RoutineTagIndex items:
  ```bash
  aws dynamodb scan \
    --table-name mb-staging-community \
    --filter-expression "EntityType = :t" \
    --expression-attribute-values '{":t":{"S":"RoutineTagIndex"}}' \
    --select COUNT \
    --query Count
  ```
  Expected: ≥20 (each seeded routine has 2 tags → ~40 tag-index items)

- [ ] Spot-check a Routine item has `GSI1PK = "PUBLIC"` and `GSI2PK = "USER#seed-user-1"` (or actual sub)

---

### 3.3 Typesense Verification

- [ ] Collection document count:
  ```bash
  curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
       "http://<typesense_ip>:8108/collections/routines" | python3 -m json.tool | grep num_documents
  ```
  Expected: ≥20

- [ ] Simple search returns results:
  ```bash
  curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" \
       "http://<typesense_ip>:8108/collections/routines/documents/search?q=Seed&query_by=name"
  ```
  Expected: `found` ≥ 1

**Troubleshooting:**
- *`num_documents: 0`* → seed ran without `TYPESENSE_API_KEY`; re-run seed with the key exported; or trigger full re-index via DynamoDB scan + bulk import

---

### 3.4 Cognito Test Users

- [ ] Users exist in pool:
  ```bash
  aws cognito-idp list-users \
    --user-pool-id $COGNITO_USER_POOL_ID \
    --filter "email = \"testuser1@mb.test\""
  ```
- [ ] Obtain a token for `testuser1@mb.test` (for Postman environment):
  ```bash
  aws cognito-idp admin-initiate-auth \
    --user-pool-id $COGNITO_USER_POOL_ID \
    --client-id $COGNITO_CLIENT_ID \
    --auth-flow ADMIN_USER_PASSWORD_AUTH \
    --auth-parameters \
      USERNAME=testuser1@mb.test,\
      PASSWORD=$(aws ssm get-parameter --name /mb/staging/test/user1-password \
                   --with-decryption --query Parameter.Value --output text)
  ```
- [ ] Copy `AuthenticationResult.AccessToken` into Postman environment variable `access_token`
- [ ] Copy a seeded `routineId` from seed output into Postman `routine_id`

**Troubleshooting:**
- *`NotAuthorizedException: Incorrect username or password`* → password in SSM was rotated; re-run `seed.py` to reset
- *`UserNotFoundException`* → `COGNITO_USER_POOL_ID` not set during seed; re-run seed with pool ID exported

---

## 4. API Endpoint Testing (Postman / Newman)

### Running the Full Collection

```bash
newman run infrastructure/postman/MeditationBuilder.postman_collection.json \
  -e infrastructure/postman/staging.postman_environment.json \
  --reporters cli,json \
  --reporter-json-export /tmp/newman-results.json
```

Review failures in `/tmp/newman-results.json`.

---

### 4.1 GET /routines — Browse

**Postman request:** `GET {{base_url}}/routines?pageSize=20&sort=newest`

- [ ] Status 200
- [ ] `routines` array length = 20
- [ ] Each item has `routineId`, `name`, `durationSeconds`, `authorName`, `likeCount`, `publishedAt`
- [ ] `nextToken` present (pagination cursor)
- [ ] Paginate: `GET /routines?pageSize=20&sort=newest&nextToken=<token>` → second page, no overlap
- [ ] Tag filter: `GET /routines?tag=focus` → all returned routines have `"focus"` in `tags`
- [ ] Duration filter: `GET /routines?minDuration=600&maxDuration=900` → all `durationSeconds` in [600,900]
- [ ] Popular sort: `GET /routines?sort=popular` → results sorted by `likeCount` descending
- [ ] **CloudFront cache miss** on first call: check response header `x-cache: Miss from cloudfront`
- [ ] **CloudFront cache hit** on second call (within 30s): `x-cache: Hit from cloudfront`
- [ ] Invalid pageSize: `GET /routines?pageSize=100` → 400 `INVALID_PARAMETER`

**Troubleshooting:**
- *Empty `routines` array despite seeded data* → GSI1 not populated; check that seeded items have `GSI1PK = "PUBLIC"`; verify Lambda queries `GSI1-public-by-date`
- *CloudFront always Miss* → TTL may not be propagating; check `Cache-Control: max-age=30, s-maxage=30` in Lambda response headers

---

### 4.2 POST /routines — Publish

**Postman request:** `POST {{base_url}}/routines` with valid body and `Authorization: Bearer {{access_token}}`

- [ ] Status 201
- [ ] Response contains `routineId` (UUID v4), `name`, `publishedAt`, `taggingStatus: "pending"`
- [ ] Save `routineId` for subsequent tests
- [ ] DynamoDB item exists: `aws dynamodb get-item --table-name mb-staging-community --key '{"PK":{"S":"ROUTINE#<id>"},"SK":{"S":"METADATA"}}'`
- [ ] SQS message sent: check `aws sqs get-queue-attributes --queue-url <tagging_queue> --attribute-names ApproximateNumberOfMessages` → count briefly > 0 before Bedrock tagger consumes it
- [ ] **Async tagging**: wait ~30s, then `GET /routines/<id>` → `tags` is populated (not empty), `taggingStatus` = `"complete"`
- [ ] Typesense indexed: search `GET /search?q=<routine name>` → routine appears in results
- [ ] CloudFront `/routines*` invalidated: `GET /routines` returns the new routine (not stale cached)
- [ ] No auth (missing header) → 401 `UNAUTHORIZED`
- [ ] Missing `name` field → 400 `INVALID_BODY`
- [ ] Body >100KB → 413 `PAYLOAD_TOO_LARGE`
- [ ] Duplicate name from same user → 409 `ALREADY_EXISTS`

**Troubleshooting:**
- *`taggingStatus` still `"pending"` after 60s* → check SQS DLQ; check `mb-staging-bedrock-tagger` Lambda CloudWatch logs for IAM or Bedrock model access errors
- *Typesense not indexed* → check `mb-staging-typesense-indexer` Lambda logs; DynamoDB Stream may not be triggering if mapping is disabled

---

### 4.3 GET /routines/{id} — Detail

**Postman request:** `GET {{base_url}}/routines/{{routine_id}}` with auth

- [ ] Status 200
- [ ] Response contains full `blocks` array, `tags`, `isLikedByMe`, `isImportedByMe`
- [ ] `isLikedByMe: false` on first fetch (before liking)
- [ ] **Redis cache miss** on first call: CloudWatch log for `mb-staging-get-routine` logs `cache miss`
- [ ] **Redis cache hit** on second call (within 5 min): CloudWatch log shows `cache hit`; response time < 100ms
- [ ] Invalid UUID → 400 `INVALID_ID`
- [ ] Non-existent ID → 404 `ROUTINE_NOT_FOUND`
- [ ] Missing auth → 401 `UNAUTHORIZED`

**Troubleshooting:**
- *Always cache miss* → Redis endpoint env var `REDIS_ENDPOINT` missing or wrong; Lambda VPC/SG issue (see §2.3)
- *CloudFront returns stale 404 after publish* → issue `aws cloudfront create-invalidation --distribution-id <id> --paths "/routines/*"`

---

### 4.4 DELETE /routines/{id} — Unpublish

- [ ] Publish a routine as `testuser1`; note its `routineId`
- [ ] `DELETE /routines/<id>` with `testuser1` token → 204 No Content
- [ ] `GET /routines/<id>` → 404 `ROUTINE_NOT_FOUND`
- [ ] DynamoDB item gone (GetItem returns empty)
- [ ] RoutineTagIndex items deleted (scan by `PK = "TAG#<tag>"` — seeded SK no longer present)
- [ ] Typesense document deleted: `curl .../collections/routines/documents/<id>` → 404
- [ ] **Ownership check**: attempt `DELETE /routines/<id>` with `testuser2` token on `testuser1`'s routine → 403 `FORBIDDEN`
- [ ] Non-existent ID → 404

**Troubleshooting:**
- *403 when deleting own routine* → `authorSub` in DynamoDB doesn't match Cognito `sub` in JWT; verify seed wrote correct `sub` values

---

### 4.5 POST /routines/{id}/like + DELETE /routines/{id}/like — Like/Unlike

- [ ] `POST /routines/{{routine_id}}/like` with auth → 200, response `{"likeCount": N}`
- [ ] Redis key `like:<routineId>` incremented: verify via CloudWatch metric or Lambda log
- [ ] Idempotency: repeat same POST → 409 `ALREADY_LIKED` with current `likeCount`
- [ ] `GET /routines/{{routine_id}}` → `isLikedByMe: true`
- [ ] `DELETE /routines/{{routine_id}}/like` → 200, `likeCount` decremented by 1
- [ ] `GET /routines/{{routine_id}}` → `isLikedByMe: false`
- [ ] Unlike when not liked → 404 `LIKE_NOT_FOUND`
- [ ] Like flush: wait up to 60s; verify `likeCount` on DynamoDB Routine item matches Redis count

**Troubleshooting:**
- *likeCount not flushing to DynamoDB* → check `mb-staging-like-flush` scheduled Lambda is enabled; check CloudWatch Events / EventBridge rule `mb-staging-like-flush-schedule`

---

### 4.6 POST /routines/{id}/import — Import

- [ ] `POST /routines/{{routine_id}}/import` with auth → 200
- [ ] Response contains `routine` object with full `blocks` payload and `importedAt`
- [ ] `GET /routines/{{routine_id}}` → `isImportedByMe: true`
- [ ] `importCount` incremented on Routine item in DynamoDB
- [ ] Idempotency: repeat import → 200 with `alreadyImported: true` (no second DynamoDB write; `importCount` not double-incremented)
- [ ] Unauthenticated → 401

**Troubleshooting:**
- *`importCount` double-incrementing* → condition expression `attribute_not_exists(SK)` may be missing in Lambda; check `import_routine.py`

---

### 4.7 GET /recommendations — Personalized Recommendations

- [ ] First call (cold / Redis miss): `GET /recommendations?limit=10` with auth
  - Status 200
  - `cacheHit: false`
  - `recommendations` array ≥1 item, each with `score` 0–1
  - CloudWatch log for `mb-staging-recommendations` shows Bedrock invocation
- [ ] Second call (within 1hr): `cacheHit: true`, `cachedAt` matches first call
- [ ] `limit=20` → up to 20 results
- [ ] `limit=25` → 400 or clamped to 20 (per spec max 20)
- [ ] Cache invalidation: `POST /activity` then immediate `GET /recommendations` → `cacheHit: false` (Redis DEL was triggered)

**Troubleshooting:**
- *`cacheHit` always false* → Redis not reachable; or Lambda not writing Redis key; check `REDIS_ENDPOINT` env var
- *Bedrock throttling (500/429)* → fallback to latest-published list should apply; verify Lambda fallback path

---

### 4.8 GET /search — Full-Text Search

- [ ] Basic: `GET /search?q=morning` → 200, `found` ≥1, `results[0]` has `highlights`
- [ ] Typo tolerance: `GET /search?q=mornnig` → still returns morning routines (Typesense fuzzy match)
- [ ] Tag filter: `GET /search?q=routine&tag=focus` → all results have `"focus"` in `tags`
- [ ] Duration range: `GET /search?q=Seed&minDuration=600&maxDuration=900` → all `durationSeconds` in range
- [ ] Sort by popularity: `GET /search?q=Seed&sort=likeCount:desc` → ordered by `likeCount` desc
- [ ] Sort by date: `GET /search?q=Seed&sort=publishedAt:desc`
- [ ] Missing `q` → 400 `MISSING_QUERY`
- [ ] Pagination: page 1 and page 2 of same query return different, non-overlapping results

**Troubleshooting:**
- *503 `SEARCH_UNAVAILABLE`* → Typesense EC2 is down; SSH in and `systemctl restart typesense`
- *Empty results despite seeded data* → Typesense collection was not populated; re-run seed with `TYPESENSE_API_KEY` set, or bulk re-index via DynamoDB scan

---

### 4.9 POST /activity — Session Activity

- [ ] `POST /activity` with valid body and auth → 202, `{"accepted": true}`
- [ ] DynamoDB item written: scan `PK = "USER#<sub>", SK begins_with "ACTIVITY#"` → item exists
- [ ] TTL set correctly: `ttl` value ≈ `now + 60 days` (Unix epoch)
- [ ] Redis recommendations cache invalidated: `GET /recommendations` immediately after → `cacheHit: false`
- [ ] Missing `sessionDurationSeconds` → 400 `INVALID_BODY`
- [ ] Empty `routinesPlayed` array → 400 `INVALID_BODY`
- [ ] Unauthenticated → 401

**Troubleshooting:**
- *TTL attribute wrong type* → must be `Number` (Unix epoch); if stored as String, DynamoDB TTL won't fire

---

## 5. iOS App End-to-End Testing

Run on a physical device or Xcode Simulator (iOS 17+) with the app pointing to the staging API (`AuthConfig.swift` populated as per §1.5).

### 5.1 First Launch

- [ ] Cold launch (no prior app data) → `AuthView` is shown (not the main tab bar)
- [ ] "Continue as Guest" button visible alongside "Sign in with Apple"
- [ ] No crash on launch; console shows no uncaught errors

---

### 5.2 Guest Browse

- [ ] Tap "Continue as Guest" → navigates to main tab bar
- [ ] Community tab loads `RoutineBrowseView` and displays routines fetched from staging API
- [ ] Routines show name, duration, author, like count
- [ ] Scroll to bottom → next page loads (infinite scroll / pagination)
- [ ] Tap a routine → `CommunityRoutineDetailView` opens, full details visible
- [ ] "Like" and "Import" buttons are visible but tap triggers sign-in prompt (requires auth)
- [ ] Search tab → `RoutineSearchView`; typing `morning` returns results from staging

---

### 5.3 Sign in with Apple → Cognito PKCE

- [ ] Tap "Sign in with Apple" from `AuthView` → `ASWebAuthenticationSession` opens Cognito hosted UI
- [ ] Select Apple ID → redirects back to app via `com.AnimeAI.Meditation-Builder://oauth2/callback`
- [ ] App performs PKCE token exchange (code + code verifier → access/refresh/ID tokens)
- [ ] Tokens stored in Keychain under `com.AnimeAI.Meditation-Builder.auth` service:
  - `mb.cognito.accessToken`
  - `mb.cognito.refreshToken`
  - `mb.cognito.idToken`
- [ ] `AuthManager.isAuthenticated = true`, `currentUserSub` is non-nil

**Troubleshooting:**
- *"Sign in with Apple" sheet never dismisses* → check `ASWebAuthenticationSession.prefersEphemeralWebBrowserSession = true` is set; Safari cookies may conflict
- *`tokenExchangeFailed: invalid_grant`* → PKCE verifier mismatch; verify `code_challenge_method=S256` and that `codeVerifier` is the same string passed to SHA-256 (see `PKCE` enum in `AuthManager.swift`)
- *`missingAuthorizationCode`* → callback URL scheme mismatch; verify `com.AnimeAI.Meditation-Builder` scheme is registered in `Info.plist` URL types

---

### 5.4 Token Refresh

- [ ] In Xcode debugger or via Charles Proxy, manually expire the access token (edit Keychain `mb.cognito.accessToken` to a past-expired JWT, or wait for 1-hour natural expiry)
- [ ] Trigger any authenticated API call (e.g. open a routine detail)
- [ ] `AuthManager.refreshTokenIfNeeded()` fires automatically; new access token stored in Keychain
- [ ] API call succeeds (no visible error to user)
- [ ] If refresh token is also expired/missing → `clearSession()` called, app navigates back to `AuthView`

**Troubleshooting:**
- *Refresh token rejected by Cognito (`invalid_grant`)* → refresh tokens expire after Cognito user pool's `refreshTokenValidity` setting (default 30 days); re-authenticate

---

### 5.5 Import Routine

- [ ] Browse Community tab; tap a routine → `CommunityRoutineDetailView`
- [ ] Tap "Import" → `POST /routines/{id}/import` fires; success toast shown
- [ ] Navigate to Library tab → imported routine appears in the local list
- [ ] Open the imported routine in the player → all blocks present, durations correct
- [ ] Re-import same routine → no duplicate in Library; `alreadyImported: true` handled gracefully

**Troubleshooting:**
- *Routine not appearing in Library* → SwiftData save may have failed; check Xcode console for `SwiftData` errors

---

### 5.6 Like / Unlike

- [ ] Open a routine → tap Like ♡ → count increments by 1 in the UI
- [ ] Navigate away and return → like state persists (`isLikedByMe: true`)
- [ ] Tap Like again → unlike; count decrements
- [ ] Like count on `GET /routines` browse reflects update after CloudFront TTL expires (≤30s)

---

### 5.7 Publish Routine

- [ ] Create a routine in the builder (≥1 block)
- [ ] Open `PublishRoutineView` — Step 1: name + user description entry
- [ ] Submit Step 1 → `POST /routines` fires → 201 received; UI advances to Step 2
- [ ] Step 2: tag review — `taggingStatus: "pending"` initially; app polls or refreshes; after ~30s tags appear
- [ ] Step 3: confirm screen shows final name, tags, duration
- [ ] Tap Confirm → routine visible in Community tab
- [ ] In Community tab, routine shows correct `authorName` matching current user

**Troubleshooting:**
- *Publish returns 401* → `bearerToken()` returned nil; ensure user is authenticated (not guest)
- *Tags never appear in Step 2* → Bedrock tagger async path failed; see §6.5

---

### 5.8 Creator Profile

- [ ] Navigate to creator profile (`CreatorProfileView`) for the authenticated user
- [ ] Published routines list populated (GSI2 query by `authorSub`)
- [ ] Each card shows like count and import count
- [ ] Tap a routine → detail view with delete option visible (own routine)

---

### 5.9 Per-Block Music

- [ ] Add a `music` block to a routine; attach a local audio file (`.m4a`)
- [ ] Save the routine
- [ ] Start a meditation session containing the music block
- [ ] Music plays during the block's duration; loops back to start when the block repeats
- [ ] Transition to the next block stops music playback from previous block
- [ ] Verify `AuditoriumManager` logs in console confirm track switch at block boundary

---

### 5.10 Sign Out

- [ ] Tap Sign Out in settings
- [ ] `AuthManager.signOut()` called: `isAuthenticated = false`, `isGuestBrowsing = false`
- [ ] Keychain verified cleared: `mb.cognito.accessToken` / `refreshToken` / `idToken` no longer readable
- [ ] App navigates back to `AuthView`
- [ ] Cold re-launch → `AuthView` shown (no auto-restore since Keychain is empty)

---

## 6. Common Cross-Cutting Problems

### 6.1 "Invalid token" / 401 Unauthorized

**Symptoms:** API returns `{"error":"UNAUTHORIZED"}` on authenticated endpoints.

**Causes & Fixes:**
- [ ] Token expired → `AuthManager.refreshTokenIfNeeded()` should have caught it; check if `JWTDecoder.isExpired()` is being called before every request via `bearerToken()`
- [ ] Token from wrong Cognito pool (production vs staging) → verify `AuthConfig.userPoolID` and `appClientID` match staging outputs
- [ ] Token not passed in header → inspect request with Charles Proxy; confirm `Authorization: Bearer <token>` header present
- [ ] Cognito app client doesn't allow `ALLOW_USER_PASSWORD_AUTH` → check Cognito app client auth flows in Console; enable if missing
- [ ] For Postman: copy a fresh token via step 3.4 and update `access_token` environment variable

---

### 6.2 Lambda Cold Start Timeout

**Symptoms:** First request after idle period returns 504 Gateway Timeout or takes >10s.

**Causes & Fixes:**
- [ ] Check `aws lambda get-function-concurrency --function-name mb-staging-<fn>` → if `ReservedConcurrentExecutions` is 0, cold starts are unlimited
- [ ] Enable provisioned concurrency for high-traffic Lambdas (at minimum `get_routines`, `get_routine`, `recommendations`):
  ```bash
  aws lambda put-provisioned-concurrency-config \
    --function-name mb-staging-get-routines \
    --qualifier <alias> \
    --provisioned-concurrent-executions 2
  ```
- [ ] Alternatively, add a CloudWatch EventBridge ping rule every 5 min to keep Lambdas warm

---

### 6.3 Redis Connection Refused from Lambda

**Symptoms:** Lambda logs show `ConnectionRefusedError` or `TimeoutError` on Redis calls; falls back to DynamoDB but latency spikes.

**Causes & Fixes:**
- [ ] Lambda VPC config: ensure Lambda is in the same VPC as ElastiCache; check `vpc_config` in Lambda Terraform resource
- [ ] Security group: ElastiCache SG must allow inbound TCP 6379 from the Lambda SG; add inbound rule:
  ```bash
  aws ec2 authorize-security-group-ingress \
    --group-id <elasticache_sg_id> \
    --protocol tcp --port 6379 \
    --source-group <lambda_sg_id>
  ```
- [ ] `REDIS_ENDPOINT` env var: verify it matches the ElastiCache cluster endpoint (not a node endpoint)
- [ ] If TLS enabled on Redis: ensure `REDIS_TLS=true` env var is set and the Lambda client uses `ssl=True`

---

### 6.4 Typesense 503 on Search

**Symptoms:** `GET /search` returns `{"error":"SEARCH_UNAVAILABLE"}`.

**Causes & Fixes:**
- [ ] Check EC2 instance state: `aws ec2 describe-instances --filters "Name=tag:Name,Values=mb-staging-typesense"`
- [ ] SSH to EC2: `ssh ec2-user@<typesense_ip>` → `systemctl status typesense`
- [ ] If crashed: `sudo systemctl restart typesense`; check `/var/log/typesense/typesense.log` for OOM or disk full
- [ ] After restart, verify `GET /health` returns `{"ok":true}` and collection still has documents (`num_documents`)
- [ ] If disk full: clear old snapshots in `~/typesense-data/snapshots/` and restart

---

### 6.5 SQS DLQ Messages Accumulating

**Symptoms:** `mb-staging-tagging-dlq` ApproximateNumberOfMessages > 0; routines have `taggingStatus: "pending"` indefinitely.

**Causes & Fixes:**
- [ ] Check `mb-staging-bedrock-tagger` Lambda CloudWatch logs for errors:
  ```bash
  aws logs tail /aws/lambda/mb-staging-bedrock-tagger --since 1h
  ```
- [ ] **Bedrock access denied** → add `bedrock:InvokeModel` permission to Lambda execution role for model `anthropic.claude-3-haiku-20240307-v1:0`
- [ ] **Bedrock model not enabled** → in AWS Console → Bedrock → Model access → enable Claude 3 Haiku in `us-east-1`
- [ ] **IAM permission on DynamoDB** → tagger Lambda needs `dynamodb:UpdateItem` on `mb-staging-community` table
- [ ] Once fixed, move DLQ messages back to source queue for reprocessing:
  ```bash
  aws sqs start-message-move-task \
    --source-arn <dlq_arn> \
    --destination-arn <source_queue_arn>
  ```

---

### 6.6 DynamoDB Throughput Exceeded

**Symptoms:** Lambda returns 500; CloudWatch logs show `ProvisionedThroughputExceededException`.

**Causes & Fixes:**
- [ ] Table uses `PAY_PER_REQUEST` (on-demand) — this exception should not occur under normal load
- [ ] If it does: check CloudWatch metric `ConsumedWriteCapacityUnits` — may indicate a runaway loop
- [ ] For GSI: on-demand billing applies per-GSI as well; check `ConsumedReadCapacityUnits` on `GSI1-public-by-date`
- [ ] If sustained: Terraform `billing_mode = "PROVISIONED"` with `auto_scaling` as a last resort

---

### 6.7 CloudFront Serving Stale 404

**Symptoms:** A newly published routine returns 404 on `GET /routines/{id}` via CloudFront even though it exists in DynamoDB.

**Causes & Fixes:**
- [ ] CloudFront cached the 404 response (default TTL for error responses)
- [ ] Manual invalidation:
  ```bash
  aws cloudfront create-invalidation \
    --distribution-id $(terraform output -raw cloudfront_distribution_id) \
    --paths "/routines/<routineId>"
  ```
- [ ] Prevent future occurrences: ensure publish Lambda calls `create_invalidation` for the new ID (check `post_routine.py`)
- [ ] Set a short error caching TTL (e.g., 5s) in CloudFront distribution settings for 4xx responses

---

### 6.8 Sign in with Apple Fails

**Symptoms:** `ASWebAuthenticationSession` returns an error or the Cognito hosted UI shows "Sign in failed".

**Causes & Fixes:**
- [ ] **Services ID mismatch** → Cognito OIDC provider `client_id` must equal the Services ID (`com.AnimeAI.Meditation-Builder.siwa`); check SSM `/mb/staging/apple/services-id`
- [ ] **Redirect URI mismatch** → Apple Services ID's Return URL must be exactly `https://mb-staging.auth.us-east-1.amazoncognito.com/oauth2/idpresponse`; no trailing slash
- [ ] **Key expired** → Apple private keys for SIWA have no expiry but must be regenerated if revoked; check Cognito identity provider configuration
- [ ] **Team ID wrong** → SSM `/mb/staging/apple/team-id` must be the 10-character Apple Developer Team ID

---

### 6.9 Cognito "invalid_grant" (PKCE Token Exchange)

**Symptoms:** `AuthManager.tokenExchangeFailed("invalid_grant")` logged; user is not authenticated.

**Causes & Fixes:**
- [ ] **PKCE verifier mismatch** → the `code_verifier` used in the token exchange must be the same string used to generate `code_challenge`; verify `PKCE.challenge(from: verifier)` is called with the same `verifier` instance (no regeneration between authorize and token steps)
- [ ] **Authorization code expired** → the code is single-use and expires in ~10 min; if the user left the auth sheet open too long, restart sign-in
- [ ] **Redirect URI mismatch in token request** → `redirect_uri` in the POST body must match `redirect_uri` in the authorization request (`AuthConfig.redirectURI`); verify they are identical
- [ ] **Code already used** → each authorization code can only be exchanged once; if the app retried the exchange, a new sign-in is required

---

## 7. Teardown

Run after testing is complete to avoid ongoing costs.

### 7.1 Seed Teardown

- [ ] Remove all seeded DynamoDB items and Typesense documents:
  ```bash
  python3 infrastructure/scripts/seed.py --env staging --teardown
  ```
- [ ] Confirm output: `{"deleted": N}` where N ≥ expected seeded item count (~80+)

---

### 7.2 Optional: Terraform Destroy

> **Warning:** This destroys all staging infrastructure. Only run if you are done with staging entirely.

- [ ] `cd infrastructure/terraform`
- [ ] `terraform workspace select staging`
- [ ] `terraform destroy -var-file=environments/staging.tfvars`
- [ ] Confirm all resources are destroyed; check AWS Console for any orphaned resources (ElastiCache clusters can persist)
- [ ] S3 bucket for Terraform state is **not** destroyed by this command (bootstrap bucket is separate)

---

*End of checklist. All sections use `- [ ]` checkboxes to support direct use in GitHub Issues, Notion, or any Markdown task tracker.*
