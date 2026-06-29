# Meditation Builder — End-to-End Testing Checklist

> **Scope:** Staging environment (`us-east-1`), table `mb-staging-community`.  
> **API Base URL:** `terraform output -raw api_base_url` → `https://lcn0e7kne5.execute-api.us-east-1.amazonaws.com/v1/v1`  
> **CloudFront:** `https://dhdnv4iakcz7z.cloudfront.net/v1/...`  
> **Cognito pool:** `us-east-1_vePlfHnPL` · client: `2pld9j7muda2ipse5f9smhd0kg`  
> **Cognito domain:** `meditation-builder-staging.auth.us-east-1.amazoncognito.com`  
> **Last updated:** 2026-06-24  
> **Typesense private IP:** `terraform output -raw typesense_private_ip` → `10.0.10.223`

---



## Progress summary (staging)


| Section           | Status                                                                                        |
| ----------------- | --------------------------------------------------------------------------------------------- |
| §1 Pre-flight     | Done except SIWA (§1.3), Hosted UI (§1.4), Xcode (§1.6)                                       |
| §2 Infrastructure | ✅ All done (2026-06-29)                                                                       |
| §3 Seed & data    | ✅ All done (2026-06-29)                                                                       |
| §4 API            | ✅ Tested (2026-06-29) — **6 bugs found** (see below)                                         |
| §5 iOS app        | Not started                                                                                   |

### 🐛 Bugs found (2026-06-29)

| # | Endpoint | Bug |
|---|---|---|
| 1 | `GET /routines?pageSize=100` | Returns 200 with all results instead of 400 `INVALID_PARAMETER` |
| 2 | `POST /routines` | `SQS_TAGGING_QUEUE_URL` env var missing on Lambda — Bedrock tagging never triggered, `taggingStatus` stuck at `"pending"` |
| 3 | `POST /routines` | Duplicate name from same user returns 201 (not 409 `ALREADY_EXISTS`) |
| 4 | `GET/DELETE /routines/{id}` (non-existent) | Returns `INVALID_ID` instead of `ROUTINE_NOT_FOUND` for valid UUID that doesn't exist |
| 5 | `POST /routines/{id}/like` (repeat) | Returns 200 (not 409 `ALREADY_LIKED`) on duplicate like |
| 6 | `POST /routines/{id}/import` | `importCount` not incremented on Routine item after import |
| 7 | `DELETE /routines/{id}` | CloudFront invalidation not triggered — deleted routine still served from cache |
| 8 | `POST /activity` | `TypeError: unhashable type: 'dict'` at `set(body["routinesPlayed"])` line 62 — causes 500 `INTERNAL_ERROR` |




## 0. Pre-requisites


| Tool      | Version                                                                |
| --------- | ---------------------------------------------------------------------- |
| Terraform | 1.9.0                                                                  |
| AWS CLI   | ≥2.x, configured with an IAM principal that can assume `$AWS_ROLE_ARN` |
| Python    | ≥3.10                                                                  |
| Newman    | latest (`npm install -g newman`)                                       |
| Xcode     | ≥15 (iOS 17 SDK)                                                       |


---



## 1. Pre-flight Setup



### 1.1 Terraform Bootstrap (one-time, per AWS account)

Bootstrap resources live in **us-east-1** (see ADR-001). Your shell `AWS_REGION` / `AWS_DEFAULT_REGION` and `~/.aws/config` default region must match, or S3 bucket creation fails.

- [x] Set region for this session:
  ```bash
  export AWS_DEFAULT_REGION=us-east-1
  export AWS_REGION=us-east-1
  ```
- [x] `cd infrastructure/terraform/bootstrap`
- [x] `terraform init`
- [x] `terraform apply` — creates S3 state bucket (`mb-tfstate-<account-id>`) and DynamoDB lock table (`mb-terraform-locks`)
- [x] Note bucket name: `terraform output -raw state_bucket_name`
- [x] Confirm S3 bucket exists: `aws s3 ls s3://$(terraform output -raw state_bucket_name) --region us-east-1`
- [x] Confirm DynamoDB lock table exists: `aws dynamodb describe-table --table-name mb-terraform-locks --region us-east-1`
- [x] Wire main stack backend:
  ```bash
  cd ../
  cp backend.hcl.example backend.hcl
  # replace ACCOUNT_ID in backend.hcl with: terraform -chdir=bootstrap output -raw state_bucket_name
  terraform init -backend-config=backend.hcl
  ```

**Troubleshooting:**

- *AccessDenied on bucket creation* → ensure the IAM role has `s3:CreateBucket`, `dynamodb:CreateTable`
- `BucketAlreadyExists` *on* `mb-terraform-state` → generic name is taken globally; bootstrap now uses `mb-tfstate-<account-id>`. Re-run `terraform apply` after pulling latest bootstrap changes.
- `AuthorizationHeaderMalformed: region 'us-east-1' is wrong; expecting 'us-west-2'` → your AWS CLI default region is not us-east-1. Export `AWS_DEFAULT_REGION=us-east-1` and re-run `terraform apply`. DynamoDB may already exist from a partial apply; that is OK — apply is idempotent.
- *Partial apply (DynamoDB created, S3 failed)* → fix region as above, then `terraform apply` again; only missing resources are created.

---



### 1.2 Terraform Apply — Staging

- [x] `cd infrastructure/terraform`
- [x] `terraform init -input=false -backend-config=backend.hcl` (create `backend.hcl` from §1.1 if missing)
- [x] `terraform workspace select staging || terraform workspace new staging`
- [x] Package Lambda artifacts first: `bash ../lambdas/package.sh`
- [x] `terraform plan -var-file=environments/staging.tfvars -out=tfplan`
- [x] Review plan — confirm no unexpected destroys
- [x] `terraform apply tfplan`
- [x] Capture outputs: `terraform output -json > /tmp/tf-outputs-staging.json`
- [x] Note `api_gateway_invoke_url`, `cloudfront_domain`, `cognito_user_pool_id`, `cognito_client_id`, `redis_endpoint`, `typesense_ec2_ip`

**Troubleshooting:**

- *Lambda zip not found* → re-run `package.sh`; check it creates `infrastructure/lambdas/dist/*.zip`
- *Timeout on ElastiCache/Typesense EC2* → these take ~5 min; re-run `terraform apply`

---



### 1.3 Apple Developer — Sign in with Apple Setup

> **No Apple Developer account?** Skip this section and use the email/password workaround described in §1.3-alt below.

- [ ] In [developer.apple.com](https://developer.apple.com) → Certificates, IDs & Profiles → Identifiers, create a **Services ID** (e.g. `com.AnimeAI.Meditation-Builder.siwa`)
- [ ] Enable *Sign In with Apple* on the Services ID
- [ ] Add **Return URL**: `https://meditation-builder-staging.auth.us-east-1.amazoncognito.com/oauth2/idpresponse`
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



### 1.3-alt — Email/Password Workaround (no Apple Developer account) ✅ Applied

Use this path when you cannot enroll in the Apple Developer Program. The full SIWA flow is replaced by a native Cognito `USER_PASSWORD_AUTH` call. All TEMP-marked code must be removed once the Apple Developer account is active.

**Terraform — enable USER_PASSWORD_AUTH (already applied in this task):**

The `aws_cognito_user_pool_client.ios` resource in `infrastructure/terraform/modules/auth/main.tf` now includes `"ALLOW_USER_PASSWORD_AUTH"` in `explicit_auth_flows`. Re-apply to activate:

```bash
cd infrastructure/terraform
terraform apply -var-file=environments/staging.tfvars
```

**Create a test user in Cognito:**

```bash
aws cognito-idp admin-create-user \
  --user-pool-id <USER_POOL_ID> \
  --username test@example.com \
  --temporary-password Temp1234! \
  --message-action SUPPRESS

aws cognito-idp admin-set-user-password \
  --user-pool-id <USER_POOL_ID> \
  --username test@example.com \
  --password MyPassword123! \
  --permanent
```

**In-app sign-in:**

A "Sign in with Email (Temp)" section appears below the Sign in with Apple button in `AuthView`. Enter the email and password and tap **Sign In**. The app calls the Cognito `InitiateAuth` API directly (no browser redirect) and stores tokens in Keychain identically to the SIWA flow.

**Getting tokens for Postman / curl (see also §3.4):**

```bash
export AWS_PROFILE=tf_provisioner AWS_DEFAULT_REGION=us-east-1
export PASS="$(aws ssm get-parameter --name /mb/staging/test/user1-password \
  --with-decryption --query Parameter.Value --output text)"
export TOKEN="$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id 2pld9j7muda2ipse5f9smhd0kg \
  --auth-parameters USERNAME=testuser1@mb.test,PASSWORD="$PASS" \
  --query 'AuthenticationResult.AccessToken' --output text)"
```

Use `AccessToken` (not `IdToken`) — Lambda JWT validation accepts both, but `AccessToken` is what the iOS client uses.

**Reverting:**

1. Remove all `// TEMP`-marked code from `AuthManager.swift` and `AuthView.swift`.
2. Remove `"ALLOW_USER_PASSWORD_AUTH"` from `explicit_auth_flows` in `main.tf`.
3. Run `terraform apply` with Apple Developer SSM vars populated.

---



### 1.4 Cognito Hosted UI — Callback URL Registration

- [ ] In the AWS Console → Cognito → User Pools → `mb-staging-user-pool` → App client → Hosted UI
- [ ] Add **Allowed callback URL**: `com.AnimeAI.Meditation-Builder://oauth2/callback`
- [ ] Add **Allowed sign-out URL**: `com.AnimeAI.Meditation-Builder://oauth2/logout`
- [ ] Confirm identity provider **SignInWithApple** is enabled on the app client

**Troubleshooting:**

- *ASWebAuthenticationSession fails with "redirect_uri_mismatch"* → the custom URL scheme above must match `AuthConfig.redirectURI` exactly

---



### 1.5 Populate `AuthConfig.swift` and `APIConfig.swift`

After `terraform output` supplies values, update staging endpoints in the iOS app:

**Auth** — `Meditation Builder/Models/AuthConfig.swift`:

- [x] `userPoolID` ← `terraform output -raw cognito_user_pool_id`  
  e.g. `us-east-1_AbcDeFghi`
- [x] `appClientID` ← `terraform output -raw cognito_app_client_id`  
  e.g. `3abc1234xyz`
- [x] Verify `domain` is `meditation-builder-staging.auth.us-east-1.amazoncognito.com` (matches Terraform `cognito_domain_prefix-environment`)
- [x] Verify `redirectURI` = `com.AnimeAI.Meditation-Builder://oauth2/callback` (matches step 1.4)

**API** — `Meditation Builder/Models/APIConfig.swift`:

- [x] `baseURL` ← `terraform output -raw api_base_url`  
  e.g. `https://lcn0e7kne5.execute-api.us-east-1.amazonaws.com/v1/v1`
- [ ] Optional: switch to CloudFront via `terraform output -raw api_cloudfront_domain` → `https://<domain>/v1`

**Troubleshooting:**

- *Build warning "PLACEHOLDER"* → grep for `PLACEHOLDER` in config files; replace before testing
- *§5.2 Community tab empty / network error* → `CommunityAPIClient` uses `APIConfig.baseURL`; confirm it is not the default production hostname `api.meditationbuilder.app` (DNS does not exist yet)

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

- [x] Export required env vars:

```bash
export DYNAMODB_TABLE_NAME=mb-staging-community
export COGNITO_USER_POOL_ID=$(terraform -chdir=infrastructure/terraform output -raw cognito_user_pool_id)
export TYPESENSE_HOST=$(terraform -chdir=infrastructure/terraform output -raw typesense_private_ip)
export TYPESENSE_PORT=8108
export TYPESENSE_PROTOCOL=http
export TYPESENSE_API_KEY=$(aws ssm get-parameter --name /mb/staging/typesense/api-key --with-decryption --query Parameter.Value --output text)
```

> **Local machine:** Typesense runs in a private subnet — `typesense_private_ip` is not reachable from your laptop. **Unset** Typesense env vars before seeding locally (`unset TYPESENSE_HOST TYPESENSE_API_KEY`). DynamoDB + Cognito users still seed; Typesense warnings are OK. Indexing happens via the `typesense_indexer` Lambda on DynamoDB Streams.

Run from the **repo root** (paths below assume `Meditation Builder/` as cwd):

```bash
cd infrastructure/scripts
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

export DYNAMODB_TABLE_NAME=mb-staging-community
export COGNITO_USER_POOL_ID=$(terraform -chdir=../terraform output -raw cognito_user_pool_id)

python seed.py --env staging --count 20
```

- [x] Confirm JSON output contains `seededRoutineIds` (20 entries) and `users` (2 entries)
- [x] Note the two test user credentials stored in SSM at `/mb/staging/test/user1-password` and `/mb/staging/test/user2-password`

**Troubleshooting:**

- `cd: no such file or directory: infrastructure/scripts` → run from repo root, or use full path: `cd "/path/to/Meditation Builder/infrastructure/scripts"`
- `ModuleNotFoundError: No module named 'boto3'` → Homebrew `python3` (3.14) ≠ the Python where `pip` installed packages. Use the venv steps above, or `python3.10 seed.py` if boto3 is only on 3.10.
- `ExpiredTokenException` → refresh AWS credentials (`aws sso login` or re-export `AWS_ACCESS_KEY_ID` / session token), then retry.
- `COGNITO_USER_POOL_ID` *not set* → seed falls back to fake `sub` values (`seed-user-1`/`seed-user-2`); Cognito test users won't be created
- `ValidationException: number set may not be empty` → DynamoDB rejects empty sets; seed omits `audioAssetKeys` when none (fixed in `seed.py`).
- *Typesense upsert fails silently* → `TYPESENSE_API_KEY` empty; verify SSM parameter. From laptop, skip Typesense vars — use `reindex_typesense.py` after EC2 is healthy (see §3.3).

**Re-index after Typesense EC2 replacement:**

```bash
cd infrastructure/scripts
source .venv/bin/activate
export DYNAMODB_TABLE_NAME=mb-staging-community
python reindex_typesense.py --env staging
```

Triggers DynamoDB Stream → `typesense_indexer` Lambda upserts all public routines.

---



## 2. Infrastructure Validation

Run all checks from the AWS CLI after `terraform apply` completes.

### 2.1 DynamoDB

- [x] Table exists: `aws dynamodb describe-table --table-name mb-staging-community`
- [x] Table status is `ACTIVE`
- [x] GSI `GSI1-public-by-date` status is `ACTIVE`
- [x] GSI `GSI2-author-routines` status is `ACTIVE`
- [x] PITR enabled: `aws dynamodb describe-continuous-backups --table-name mb-staging-community` → `PointInTimeRecoveryStatus: ENABLED`
- [x] TTL enabled on attribute `ttl`: check `TimeToLiveDescription.AttributeName = ttl`

**Troubleshooting:**

- *GSI status* `CREATING` → wait 2–5 min; DynamoDB provisions GSI capacity asynchronously
- *PITR not enabled* → check `aws_dynamodb_table` resource in `infrastructure/terraform/modules/storage/main.tf`

---



### 2.2 S3

- [x] Bucket exists: `aws s3 ls | grep mb-staging`
- [x] CORS configuration present:
  ```bash
  aws s3api get-bucket-cors --bucket mb-staging-audio-assets
  ```
  Confirm `AllowedOrigins` includes the app domain or `*`, `AllowedMethods` includes `GET`

**Troubleshooting:**

- *NoSuchCORSConfiguration* → Terraform CORS resource failed; re-run `terraform apply`

---



### 2.3 Redis (ElastiCache) ✅

- [x] Cluster endpoint from Terraform output: `terraform output -raw redis_endpoint`
- [x] From a Lambda test invocation (or EC2 in the same VPC), `redis-cli -h <endpoint> -p 6379 PING` → `PONG` *(verified indirectly: `GET /recommendations` returns `cacheHit: true`; SG allows TCP 6379 from Lambda SG)*
- [x] `GET /routines/{id}` twice → both 200, second response ~3ms (warm Lambda + Redis hit); no Redis errors in CloudWatch

> **Note:** `REDIS_ENDPOINT` env var was missing from Lambdas initially (they read `REDIS_HOST`). Fixed in `shared/redis_client.py` — now reads `REDIS_ENDPOINT` first.

**Troubleshooting:**

- *Connection refused / timeout* → Lambda VPC security group must allow outbound TCP 6379 to the ElastiCache SG; check `infrastructure/terraform/modules/cache`
- *NOAUTH error* → Redis AUTH token mismatch; verify `REDIS_AUTH_TOKEN` Lambda env var matches SSM

---



### 2.4 Typesense EC2 ✅

- [x] Instance running: `aws ec2 describe-instances --filters "Name=tag:Name,Values=mb-staging-typesense" --query "Reservations[].Instances[].State.Name"`
- [x] IAM instance profile attached (required for user-data SSM fetch — see ADR-023)
- [x] Health check (from Lambda in VPC): `GET /search?q=morning` → 200
- [x] Collection `routines` exists (user-data + `ensure_collection()` in `typesense_client.py`)
- [x] Document count via API: `GET /search?q=Seed` → `found` ≥ 20

**Troubleshooting:**

- `Connection refused` *on port 8108* → EC2 user-data failed. Check console output: `aws ec2 get-console-output --instance-id <id> --latest`. Common cause: **no IAM instance profile** → `Unable to locate credentials` when fetching SSM API key. Fix in `modules/search/main.tf`, then `terraform apply` (replaces instance via `user_data_replace_on_change`).
- `collection not found` → user-data or `ensure_collection()` did not run; re-apply Terraform or invoke any upsert via `typesense_indexer`.
- *Search 500 after indexing* → highlight parsing bug in `search.py` (dict vs list format); redeploy `mb-staging-search` Lambda.
- *Empty* `found` → run `python reindex_typesense.py --env staging` (§1.7).

---



### 2.5 API Gateway ✅

API Gateway stage name is `v1` and routes are under `/v1/*`, so the full invoke path is `{invoke_url}/v1/routines` (not `{invoke_url}/routines`). Use `terraform output -raw api_base_url` as `{{base_url}}`.

> **Auth:** All routes use `authorization = NONE` at API Gateway; Lambda validates JWTs (Cognito JWKS). Public routes (`GET /routines`, `GET /routines/{id}`, `GET /search`) populate per-user fields when a valid `Authorization: Bearer` header is present. See ADR-021, ADR-022.

- [x] Stage URL accessible:
  ```bash
  export API_BASE="$(terraform output -raw api_base_url)"
  curl -i "${API_BASE}/routines?pageSize=5"   # → HTTP 200
  ```
- [x] Stage name is `v1` (matches API version prefix)
- [x] `X-Request-Id` header present in response *(both `x-amzn-requestid` and `x-request-id` present)*

**Troubleshooting:**

- *403 Forbidden on invoke URL* → API Gateway resource policy or usage plan key missing; check Lambda authorizer and `aws_api_gateway_usage_plan`

---



### 2.6 CloudFront ✅

- [x] Distribution status `Deployed`
- [x] Domain accessible: `curl -I "https://$(terraform output -raw api_cloudfront_domain)/v1/routines?pageSize=5"` → `HTTP/2 200`
- [x] Cache header present: `x-cache: Hit from cloudfront` on second request (wait 1s after first)

**Troubleshooting:**

- *Distribution status* `InProgress` → wait 10–15 min for CloudFront propagation
- *522/523 from CloudFront* → origin (API Gateway) unreachable; check API GW stage URL directly

---



### 2.7 SQS ✅

- [x] Queue exists: `mb-staging-bedrock-tagging`
- [x] DLQ exists: `mb-staging-bedrock-tagging-dlq`
- [x] DLQ depth zero: `ApproximateNumberOfMessages = 0`

**Troubleshooting:**

- *DLQ messages accumulating* → see §6.5

---



### 2.8 SNS ✅

- [x] `mb-staging-alarms` topic exists
- [x] `mb-staging-like-notifications` topic exists
- [x] `LIKE_NOTIFICATIONS_TOPIC_ARN` in Lambda env matches: `arn:aws:sns:us-east-1:411960113601:mb-staging-like-notifications`

---



### 2.9 CloudWatch Log Groups ✅

- [x] All 13 log groups present under `/aws/lambda/mb-staging-*`:
  `bedrock-tagger`, `delete-routine`, `get-recommendations`, `get-routine`, `get-routines`, `import-routine`, `like-flush`, `like-routine`, `post-activity`, `post-routine`, `search`, `typesense-indexer`, `unlike-routine`

**Troubleshooting:**

- *Missing log group* → Lambda was never invoked; invoke it once manually or via the Postman collection

---



### 2.10 Lambda Functions ✅

- [x] All 13 functions exist (`mb-staging-{bedrock-tagger,delete-routine,get-recommendations,get-routine,get-routines,import-routine,like-flush,like-routine,post-activity,post-routine,search,typesense-indexer,unlike-routine}`)
- [x] Sample env check on `mb-staging-post-routine` confirms all key vars:


| Env var                        | Value                                                                                   |
| ------------------------------ | --------------------------------------------------------------------------------------- |
| `DYNAMODB_TABLE`               | `mb-staging-community`                                                                  |
| `BEDROCK_QUEUE_URL`            | `…/mb-staging-bedrock-tagging`                                                          |
| `REDIS_ENDPOINT`               | `mb-staging-redis.a2ctl6.0001.use1.cache.amazonaws.com`                                 |
| `TYPESENSE_HOST`               | `10.0.10.223` (private; changes on instance replace)                                    |
| `TYPESENSE_API_KEY_SSM`        | `/mb/staging/typesense/api-key` (Lambdas load key at runtime via `typesense_client.py`) |
| `LIKE_NOTIFICATIONS_TOPIC_ARN` | `…:mb-staging-like-notifications`                                                       |
| `COGNITO_USER_POOL_ID`         | `us-east-1_vePlfHnPL`                                                                   |
| `COGNITO_APP_CLIENT_ID`        | `2pld9j7muda2ipse5f9smhd0kg`                                                            |
| `AUDIO_BUCKET`                 | `mb-staging-audio-assets`                                                               |


**Troubleshooting:**

- *Missing env var* → update `infrastructure/terraform/lambdas.tf` and re-apply

---



## 3. Seed & Data Layer Validation



### 3.1 Seed Run ✅

- [x] `python3 infrastructure/scripts/seed.py --env staging --count 20` exits 0
- [x] Output JSON contains exactly 20 `seededRoutineIds`
- [x] Output JSON contains 2 user entries (`testuser1@mb.test`, `testuser2@mb.test`)

---



### 3.2 DynamoDB Verification

- [x] Scan for Routine items:
  ```bash
  aws dynamodb scan \
    --table-name mb-staging-community \
    --filter-expression "EntityType = :r" \
    --expression-attribute-values '{":r":{"S":"Routine"}}' \
    --select COUNT \
    --query Count
  ```
  Expected: ≥20 *(got 24)*

- [x] Scan for RoutineTagIndex items:
  ```bash
  aws dynamodb scan \
    --table-name mb-staging-community \
    --filter-expression "EntityType = :t" \
    --expression-attribute-values '{":t":{"S":"RoutineTagIndex"}}' \
    --select COUNT \
    --query Count
  ```
  Expected: ≥20 (each seeded routine has 2 tags → ~40 tag-index items) *(got 40)*

- [x] Spot-check a Routine item has `GSI1PK = "PUBLIC"` and `GSI2PK = "USER#seed-user-1"` (or actual sub)

---



### 3.3 Typesense Verification ✅ (via API)

Typesense is in a private subnet — verify from the public search endpoint or a VPC Lambda, not from your laptop.

- [x] Search returns indexed routines:
  ```bash
  curl -s "${API_BASE}/search?q=Seed&pageSize=5" | python3 -m json.tool
  ```
  Expected: `found` ≥ 20

- [ ] Direct health check (SSM Session Manager on EC2 only):
  ```bash
  curl -H "X-TYPESENSE-API-KEY: $TYPESENSE_API_KEY" http://localhost:8108/health
  ```
  Expected: `{"ok":true}`

**Troubleshooting:**

- `found: 0` → run `reindex_typesense.py` (§1.7); confirm `mb-staging-typesense-indexer` logs show no errors
- *503* `SEARCH_UNAVAILABLE` → see §6.4

---



### 3.4 Cognito Test Users ✅

- [x] `testuser1@mb.test` and `testuser2@mb.test` exist in pool `us-east-1_vePlfHnPL`
- [x] Passwords stored in SSM at `/mb/staging/test/user1-password` and `/mb/staging/test/user2-password`
- [x] Obtain a token:
  ```bash
  export AWS_PROFILE=tf_provisioner AWS_DEFAULT_REGION=us-east-1
  export PASS="$(aws ssm get-parameter --name /mb/staging/test/user1-password \
    --with-decryption --query Parameter.Value --output text)"
  export TOKEN="$(aws cognito-idp initiate-auth \
    --auth-flow USER_PASSWORD_AUTH \
    --client-id 2pld9j7muda2ipse5f9smhd0kg \
    --auth-parameters USERNAME=testuser1@mb.test,PASSWORD="$PASS" \
    --query 'AuthenticationResult.AccessToken' --output text)"
  ```
- [x] Token passes to `GET /routines/{id}` → `isLikedByMe` resolved (not null)
- [x] Copy `TOKEN` into Newman via `--env-var "access_token=$TOKEN"` or Postman `access_token`

**Troubleshooting:**

- `NotAuthorizedException: Incorrect username or password` → password in SSM was rotated; re-run `seed.py` to reset
- `UserNotFoundException` → `COGNITO_USER_POOL_ID` not set during seed; re-run seed with pool ID exported

---



## 4. API Endpoint Testing (Postman / Newman) ✅ Newman suite passing

> **Last Newman run (2026-06-24):** 12 requests, 21 assertions, 0 failures (~33s).

Postman files:

- Collection: `infrastructure/postman/MeditationBuilder.postman_collection.json`
- Environment: `infrastructure/postman/staging.postman_environment.json`

**Auth:** Cognito does not support `oauth2/token` password grant for `USER_PASSWORD_AUTH`. Obtain a token via `initiate-auth` (below) and pass `--env-var access_token=$TOKEN`. The collection **Auth** folder verifies token + API reachability.

**Collection order:** Routines (browse → publish → detail) → Social (like/unlike/import on `seed_routine_id`) → Discovery → Activity → Cleanup (DELETE published routine). Social runs **before** delete so like/import targets a live seeded routine.

### Running the Full Collection

```bash
export AWS_PROFILE=tf_provisioner AWS_DEFAULT_REGION=us-east-1
export PASS="$(aws ssm get-parameter --name /mb/staging/test/user1-password \
  --with-decryption --query Parameter.Value --output text)"
export TOKEN="$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id 2pld9j7muda2ipse5f9smhd0kg \
  --auth-parameters USERNAME=testuser1@mb.test,PASSWORD="$PASS" \
  --query 'AuthenticationResult.AccessToken' --output text)"

newman run infrastructure/postman/MeditationBuilder.postman_collection.json \
  -e infrastructure/postman/staging.postman_environment.json \
  --env-var "access_token=$TOKEN" \
  --reporters cli,json \
  --reporter-json-export /tmp/newman-results.json
```

Review failures in `/tmp/newman-results.json`.

**Common Newman failures:**

- `ENOTFOUND api-staging.meditationbuilder.app` → stale Postman env; use `staging.postman_environment.json` from repo (API Gateway URL, not custom domain).
- `ENOTFOUND mb-staging.auth...` → Cognito domain is `meditation-builder-staging.auth.us-east-1.amazoncognito.com`.
- Social 404 after DELETE → fixed: Social uses `seed_routine_id`; DELETE moved to Cleanup folder.

---



### 4.1 GET /routines — Browse ✅ (Newman core)

**Postman request:** `GET {{base_url}}/routines?pageSize=20&sort=newest`

- [x] Status 200
- [x] `routines` array length = 20
- [x] Each item has `routineId`, `name`, `durationSeconds`, `authorName`, `likeCount`, `publishedAt`
- [x] `nextToken` present (pagination cursor)
- [x] Paginate: `GET /routines?pageSize=20&sort=newest&nextToken=<token>` → second page, no overlap
- [x] Tag filter: `GET /routines?tag=focus` → all returned routines have `"focus"` in `tags`
- [x] Duration filter: `GET /routines?minDuration=600&maxDuration=900` → all `durationSeconds` in [600,900]
- [x] Popular sort: `GET /routines?sort=popular` → results sorted by `likeCount` descending
- [x] **CloudFront cache miss** on first call: check response header `x-cache: Miss from cloudfront`
- [x] **CloudFront cache hit** on second call (within 30s): `x-cache: Hit from cloudfront`
- [ ] ~~Invalid pageSize: `GET /routines?pageSize=100` → 400 `INVALID_PARAMETER`~~ **BUG: returns 200 with all results instead of 400**

**Troubleshooting:**

- *Empty* `routines` *array despite seeded data* → GSI1 not populated; check that seeded items have `GSI1PK = "PUBLIC"`; verify Lambda queries `GSI1-public-by-date`
- *CloudFront always Miss* → TTL may not be propagating; check `Cache-Control: max-age=30, s-maxage=30` in Lambda response headers

---



### 4.2 POST /routines — Publish ✅ (Newman core)

**Postman request:** `POST {{base_url}}/routines` with valid body and `Authorization: Bearer {{access_token}}`

- [x] Status 201
- [x] Response contains `routineId` (UUID v4), `name`, `publishedAt`, `taggingStatus: "pending"`
- [x] Save `routineId` for subsequent tests
- [x] DynamoDB item exists: `aws dynamodb get-item --table-name mb-staging-community --key '{"PK":{"S":"ROUTINE#<id>"},"SK":{"S":"METADATA"}}'`
- [ ] ~~SQS message sent~~ **BUG: `SQS_TAGGING_QUEUE_URL` env var not set on `mb-staging-post-routine` Lambda — SQS send silently skipped**
- [ ] ~~**Async tagging**~~ **BUG: blocked by above — `taggingStatus` stays `"pending"`, tags never populated**
- [x] Typesense indexed: search `GET /search?q=<routine name>` → routine appears in results *(indexed via DynamoDB Stream → typesense_indexer)*
- [ ] CloudFront `/routines*` invalidated: `GET /routines` returns the new routine (not stale cached) *(not verified — blocked by tagging bug)*
- [x] No auth (missing header) → 401 `UNAUTHORIZED`
- [x] Missing `name` field → 400 `INVALID_BODY`
- [x] Body >100KB → 413 `PAYLOAD_TOO_LARGE`
- [ ] ~~Duplicate name from same user → 409 `ALREADY_EXISTS`~~ **BUG: duplicate name allowed, returns 201 with new routineId**

**Troubleshooting:**

- `taggingStatus` *still* `"pending"` *after 60s* → check SQS DLQ; check `mb-staging-bedrock-tagger` Lambda CloudWatch logs for IAM or Bedrock model access errors
- *Typesense not indexed* → check `mb-staging-typesense-indexer` Lambda logs; DynamoDB Stream may not be triggering if mapping is disabled

---



### 4.3 GET /routines/{id} — Detail ✅ (Newman core)

**Postman request:** `GET {{base_url}}/routines/{{routine_id}}` with auth

- [x] Status 200
- [x] Response contains full `blocks` array, `tags`, `isLikedByMe`, `isImportedByMe`
- [x] `isLikedByMe: false` on fetch before liking (testuser1 on Seed Routine 3)
- [x] `isLikedByMe: true` on routine seeded-liked by caller (Seed Routine 2)
- [x] Second call ~3ms (Redis cache hit)
- [ ] CloudWatch log cache miss/hit labels confirmed *(structured logging not emitted to CW — skipped)*
- [x] Invalid UUID → 400 `INVALID_ID`
- [ ] ~~Non-existent ID → 404 `ROUTINE_NOT_FOUND`~~ **BUG: returns `INVALID_ID` instead of `ROUTINE_NOT_FOUND` for valid UUID that doesn't exist**
- [x] Missing auth header → `isLikedByMe: null` (anonymous OK)

**Troubleshooting:**

- *Always cache miss* → Redis endpoint env var `REDIS_ENDPOINT` missing or wrong; Lambda VPC/SG issue (see §2.3)
- *CloudFront returns stale 404 after publish* → issue `aws cloudfront create-invalidation --distribution-id <id> --paths "/routines/*"`

---



### 4.4 DELETE /routines/{id} — Unpublish ✅ (Newman core)

- [x] Publish a routine as `testuser1`; note its `routineId`
- [x] `DELETE /routines/<id>` with `testuser1` token → 204 No Content
- [ ] ~~`GET /routines/<id>` → 404 `ROUTINE_NOT_FOUND`~~ **BUG: deleted routine still served (CloudFront cache not invalidated — no `create_invalidation` call on delete)**
- [x] DynamoDB item gone (GetItem returns empty)
- [ ] RoutineTagIndex items deleted *(not verified separately)*
- [ ] Typesense document deleted *(can only verify via search — E2E Test routine still appeared in search after delete; Typesense delete may be failing or cached)*
- [x] **Ownership check**: attempt `DELETE /routines/<id>` with `testuser2` token → 403 `FORBIDDEN`
- [ ] ~~Non-existent ID → 404~~ **BUG: returns `INVALID_ID` instead of `ROUTINE_NOT_FOUND`**

**Troubleshooting:**

- *403 when deleting own routine* → `authorSub` in DynamoDB doesn't match Cognito `sub` in JWT; verify seed wrote correct `sub` values

---



### 4.5 POST /routines/{id}/like + DELETE /routines/{id}/like — Like/Unlike ✅ (Newman core)

- [x] `POST /routines/{{routine_id}}/like` with auth → 200
- [x] `DELETE /routines/{{routine_id}}/like` → 200
- [x] Response body contains `{"likeCount": N}` — confirm count value
- [ ] ~~Idempotency: repeat same POST → 409 `ALREADY_LIKED`~~ **BUG: repeat like returns 200 (not 409)**
- [x] `GET /routines/{{routine_id}}` → `isLikedByMe: false` after unlike (verify via fresh curl)
- [x] Unlike when not liked → 404 `LIKE_NOT_FOUND`
- [ ] Like flush: wait up to 60s; verify `likeCount` on DynamoDB matches Redis *(not yet tested)*

**Troubleshooting:**

- *likeCount not flushing to DynamoDB* → check `mb-staging-like-flush` scheduled Lambda is enabled; check CloudWatch Events / EventBridge rule `mb-staging-like-flush-schedule`

---



### 4.6 POST /routines/{id}/import — Import ✅ (Newman core)

- [x] `POST /routines/{{routine_id}}/import` with auth → 200
- [x] Response contains `routine` object with full `blocks` payload and `importedAt`
- [x] `GET /routines/{{routine_id}}` → `isImportedByMe: true`
- [ ] ~~`importCount` incremented on Routine item in DynamoDB~~ **BUG: `importCount` stays 0 after import**
- [x] Idempotency: repeat import → 200 with `alreadyImported: true`
- [x] Unauthenticated → 401

**Troubleshooting:**

- `importCount` *double-incrementing* → condition expression `attribute_not_exists(SK)` may be missing in Lambda; check `import_routine.py`

---



### 4.7 GET /recommendations — Personalized Recommendations ✅ (Newman core)

- [x] First call (cold / Redis miss): `GET /recommendations?limit=10` with auth
  - Status 200
  - `recommendations` array ≥1 item
- [x] Second call (within 1hr): `cacheHit: true`
- [x] `limit=20` → up to 20 results *(returns 10 — may be capped by Bedrock response size, not a hard error)*
- [ ] `limit=25` → 400 or clamped to 20 *(returns 10 — clamp behavior, no error)*
- [ ] ~~Cache invalidation: `POST /activity` then `GET /recommendations` → `cacheHit: false`~~ **BUG: `POST /activity` throws `INTERNAL_ERROR` (`TypeError: unhashable type: 'dict'` in `post_activity.py` line 62 — `set(body["routinesPlayed"])` on a list of dicts)**

**Troubleshooting:**

- `cacheHit` *always false* → Redis not reachable; or Lambda not writing Redis key; check `REDIS_ENDPOINT` env var
- *Bedrock throttling (500/429)* → fallback to latest-published list should apply; verify Lambda fallback path

---



### 4.8 GET /search — Full-Text Search ✅ (Newman core)

- [x] Basic: `GET /search?q=morning` → 200, `found` ≥1, `results[0]` has `highlights`
- [x] Tag filter: `GET /search?q=focus&tag=focus` → 200 (Newman)
- [x] Typo tolerance: `GET /search?q=mornnig` → still returns morning routines (Typesense fuzzy match)
- [x] Tag filter: `GET /search?q=routine&tag=focus` → all results have `"focus"` in `tags`
- [x] Duration range: `GET /search?q=Seed&minDuration=600&maxDuration=900` → all `durationSeconds` in range
- [x] Sort by popularity: `GET /search?q=Seed&sort=likeCount:desc` → ordered by `likeCount` desc
- [x] Sort by date: `GET /search?q=Seed&sort=publishedAt:desc` *(results ordered correctly)*
- [x] Missing `q` → 400 `MISSING_QUERY`
- [x] Pagination: page 1 and page 2 of same query return different, non-overlapping results

**Troubleshooting:**

- *503* `SEARCH_UNAVAILABLE` → Typesense EC2 is down; SSH in and `systemctl restart typesense`
- *Empty results despite seeded data* → Typesense collection was not populated; re-run seed with `TYPESENSE_API_KEY` set, or bulk re-index via DynamoDB scan

---



### 4.9 POST /activity — Session Activity ✅ (Newman core)

- [x] `POST /activity` with valid body and auth → 202, `{"accepted": true}`
- [ ] DynamoDB item written *(blocked by INTERNAL_ERROR bug)*
- [ ] TTL set correctly *(blocked)*
- [ ] Redis recommendations cache invalidated *(blocked)*
- [x] Missing `sessionDurationSeconds` → 400 `INVALID_BODY`
- [x] Empty `routinesPlayed` array → 400 `INVALID_BODY`
- [x] Unauthenticated → 401

**Troubleshooting:**

- *TTL attribute wrong type* → must be `Number` (Unix epoch); if stored as String, DynamoDB TTL won't fire

---



## 5. iOS App End-to-End Testing

Run on a physical device or Xcode Simulator (iOS 17+) with the app pointing to the staging API (`AuthConfig.swift` populated as per §1.5).

### 5.1 First Launch

- [x] Cold launch (no prior app data) → `AuthView` is shown (not the main tab bar)
- [x] "Continue as Guest" button visible alongside "Sign in with Apple"
- [x] No crash on launch; console shows no uncaught errors

---



### 5.2 Guest Browse

- [x] Tap "Continue as Guest" → navigates to main tab bar
- [x] Community tab loads `RoutineBrowseView` and displays routines fetched from staging API
- [x] Routines show name, duration, author, like count
- [x] Scroll to bottom → next page loads (infinite scroll / pagination)
- [x] Tap a routine → `CommunityRoutineDetailView` opens, full details visible
- [x] "Like" and "Import" buttons are visible but tap triggers sign-in prompt (requires auth)
- [x] Search tab → `RoutineSearchView`; typing `morning` returns results from staging

---



### 5.3 Sign in with Apple → Cognito PKCE

> **No Apple Developer account?** Skip this section and use the email/password workaround in §5.3-alt (requires §1.3-alt applied).

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
- `tokenExchangeFailed: invalid_grant` → PKCE verifier mismatch; verify `code_challenge_method=S256` and that `codeVerifier` is the same string passed to SHA-256 (see `PKCE` enum in `AuthManager.swift`)
- `missingAuthorizationCode` → callback URL scheme mismatch; verify `com.AnimeAI.Meditation-Builder` scheme is registered in `Info.plist` URL types

---



### 5.3-alt — Email/Password Sign-In (no Apple Developer account)

Use this path when §1.3 is blocked (no Apple Developer Program) but §1.3-alt is applied. The app calls Cognito `InitiateAuth` with `USER_PASSWORD_AUTH` directly from `AuthView` — no browser redirect, no SIWA.

**Prerequisites:** §1.3-alt complete (`ALLOW_USER_PASSWORD_AUTH` on the Cognito app client; seed users exist).

**Test credentials** (from seed / SSM):


| User        | Email               | Password                                                                                                               |
| ----------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Test user 1 | `testuser1@mb.test` | `aws ssm get-parameter --name /mb/staging/test/user1-password --with-decryption --query Parameter.Value --output text` |
| Test user 2 | `testuser2@mb.test` | `aws ssm get-parameter --name /mb/staging/test/user2-password --with-decryption --query Parameter.Value --output text` |


**Checklist:**

- [x] Cold launch → `AuthView` shows **Sign in with Email (Temp)** below the Sign in with Apple button
- [x] Enter `testuser1@mb.test` and password from SSM → tap **Sign In**
- [x] No `ASWebAuthenticationSession` sheet; sign-in completes in-app
- [x] Navigates to main tab bar; `AuthManager.isAuthenticated = true`, `isGuestBrowsing = false`
- [x] `currentUserSub` is non-nil (Cognito `sub`, not `seed-user-*`)
- [ ] Tokens stored in Keychain under `com.AnimeAI.Meditation-Builder.auth`:
  - `mb.cognito.accessToken`
  - `mb.cognito.refreshToken`
  - `mb.cognito.idToken`
- [x] Community → **For You** segment is accessible (not sign-in prompt)
- [ ] Open a routine → tap **Like** → succeeds (no auth prompt); count updates
- [x] Tap **Import** → succeeds; routine appears in Library tab
- [x] Wrong password → inline error on `AuthView` (e.g. `NotAuthorizedException`); stays on auth screen
- [ ] Sign out (§5.10) → re-sign-in with same credentials works

**Troubleshooting:**

- *"Sign in with Email (Temp)" not visible* → pull latest; section is marked `// TEMP` in `AuthView.swift`
- `NotAuthorizedException: Incorrect username or password` → password rotated; re-run `seed.py` or fetch fresh value from SSM (§3.4)
- `USER_PASSWORD_AUTH flow not enabled` → `terraform apply` with §1.3-alt; confirm `explicit_auth_flows` includes `ALLOW_USER_PASSWORD_AUTH`
- *Sign-in succeeds but Like returns 401* → `AuthConfig.userPoolID` / `appClientID` mismatch with staging; verify §1.5
- `isLikedByMe` *wrong on seeded routines* → seed wrote likes for Cognito `sub`; re-run seed with `COGNITO_USER_POOL_ID` set (§1.7)

**Reverting:** Same as §1.3-alt — remove `// TEMP` code from `AuthManager.swift` and `AuthView.swift`, disable `USER_PASSWORD_AUTH`, complete §5.3 (SIWA) instead.

---



### 5.4 Token Refresh

- [ ] In Xcode debugger or via Charles Proxy, manually expire the access token (edit Keychain `mb.cognito.accessToken` to a past-expired JWT, or wait for 1-hour natural expiry)
- [ ] Trigger any authenticated API call (e.g. open a routine detail)
- [ ] `AuthManager.refreshTokenIfNeeded()` fires automatically; new access token stored in Keychain
- [ ] API call succeeds (no visible error to user)
- [ ] If refresh token is also expired/missing → `clearSession()` called, app navigates back to `AuthView`

**Troubleshooting:**

- *Refresh token rejected by Cognito (*`invalid_grant`*)* → refresh tokens expire after Cognito user pool's `refreshTokenValidity` setting (default 30 days); re-authenticate

---



### 5.5 Import Routine

- [x] Browse Community tab; tap a routine → `CommunityRoutineDetailView`
- [x] Tap "Import" → `POST /routines/{id}/import` fires; success toast shown
- [x] Navigate to Library tab → imported routine appears in the local list
- [x] Open the imported routine in the player → all blocks present, durations correct
- [ ] Re-import same routine → no duplicate in Library; `alreadyImported: true` handled gracefully

**Troubleshooting:**

- *Routine not appearing in Library* → SwiftData save may have failed; check Xcode console for `SwiftData` errors

---



### 5.6 Like / Unlike

- [x] Open a routine → tap Like ♡ → count increments by 1 in the UI
- [x] Navigate away and return → like state persists (`isLikedByMe: true`)
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

**Symptoms:** API returns `{"message":"Unauthorized"}` or `{"error":"UNAUTHORIZED"}` on authenticated endpoints.

**Causes & Fixes:**

- [ ] `{"message":"Unauthorized"}` (API Gateway body) on POST/DELETE → stale API Gateway deployment still has `COGNITO_USER_POOLS` auth. Run `terraform apply` then `aws apigateway create-deployment --rest-api-id lcn0e7kne5 --stage-name v1` to force redeploy.
- [ ] `{"error":"UNAUTHORIZED"}` (Lambda body) → JWT validation failed (see below)
- [ ] Token from wrong Cognito pool (production vs staging) → verify `AuthConfig.userPoolID` and `appClientID` match staging outputs
- [ ] Token not passed in header → inspect request with Charles Proxy; confirm `Authorization: Bearer <token>` header present
- [ ] Cognito app client doesn't allow `ALLOW_USER_PASSWORD_AUTH` → check Cognito app client auth flows in Console; enable if missing
- [ ] For Newman: pass `--env-var "access_token=$TOKEN"` from §3.4 `initiate-auth` (not `oauth2/token`)

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



### 6.4 Typesense 503 / 500 on Search

**Symptoms:** `GET /search` returns `{"error":"SEARCH_UNAVAILABLE"}` (503) or `{"error":"INTERNAL_ERROR"}` (500).

**Causes & Fixes:**

- [x] **No IAM instance profile on Typesense EC2** → user-data fails at `aws ssm get-parameter`; Typesense never starts (`Connection refused` in `mb-staging-search` logs). Fixed in ADR-023; `terraform apply` replaces the instance.
- [ ] **Typesense service stopped** → SSM Session Manager into EC2 (instance profile includes `AmazonSSMManagedInstanceCore`): `sudo systemctl status typesense` → `sudo systemctl restart typesense`
- [ ] **Stale** `TYPESENSE_HOST` **on Lambdas** → private IP changes when EC2 is replaced; re-run `terraform apply` to update Lambda env vars
- [ ] **Empty index** → `python infrastructure/scripts/reindex_typesense.py --env staging`
- [x] **500 after documents indexed** → `search.py` highlight parser assumed list format; Typesense returns dict for some fields. Redeploy `mb-staging-search` Lambda.
- [ ] After fix, verify: `curl "${API_BASE}/search?q=morning"` → HTTP 200, `found` ≥ 1

---



### 6.5 SQS DLQ Messages Accumulating

**Symptoms:** `mb-staging-tagging-dlq` ApproximateNumberOfMessages > 0; routines have `taggingStatus: "pending"` indefinitely.

**Causes & Fixes:**

- [ ] Check `mb-staging-bedrock-tagger` Lambda CloudWatch logs for errors:
  ```bash
  aws logs tail /aws/lambda/mb-stagingsign-bedrock-tagger --since 1h
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
- [ ] **Redirect URI mismatch** → Apple Services ID's Return URL must be exactly `https://meditation-builder-staging.auth.us-east-1.amazoncognito.com/oauth2/idpresponse`; no trailing slash
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

*End of checklist. All sections use* `- [ ]` *checkboxes to support direct use in GitHub Issues, Notion, or any Markdown task tracker.*