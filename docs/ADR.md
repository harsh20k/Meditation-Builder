# Architectural Decision Records

Append-only log of architectural trade-offs. See `.cursor/rules/adr.mdc` for format rules.

---

## ADR-001 — Single-region deployment (us-east-1)
**Date:** 2026-06-19
**Decision:** Deploy all AWS resources to us-east-1 only.
**Reason:** Cost and complexity; single-region is sufficient for the academic demo scope.
**Trade-off:** Availability ceiling is ~99.9% (single-region SLA composite); a regional outage would cause full downtime. Architecture supports adding Route 53 latency routing + replica in us-west-2 when needed.
**Status:** Accepted

---

## ADR-002 — DynamoDB on-demand over provisioned capacity
**Date:** 2026-06-19
**Decision:** Use DynamoDB on-demand billing mode.
**Reason:** Traffic is unpredictable at demo scale (1–50 concurrent users); on-demand eliminates capacity planning and throttling risk.
**Trade-off:** Per-request cost is higher than provisioned at sustained high throughput (>~40k RCU/hr); would switch to provisioned + auto-scaling at production scale.
**Status:** Accepted

---

## ADR-003 — AWS Lambda over ECS Fargate for API compute
**Date:** 2026-06-19
**Decision:** Use Lambda (Node.js 22) for all API handlers behind API Gateway.
**Reason:** Serverless removes server management overhead; scales to zero between demo sessions (cost = $0 at rest); no container registry or task definition maintenance.
**Trade-off:** Cold starts add ~200–400ms latency on first invocation; mitigated with provisioned concurrency on the browse endpoint (hot path). Long-running workloads (>15 min) would require Fargate.
**Status:** Accepted

---

## ADR-007 — Terraform over AWS CDK for IaC
**Date:** 2026-06-19
**Decision:** Use Terraform (HCL) instead of AWS CDK (TypeScript) for all infrastructure definition.
**Reason:** Terraform is cloud-agnostic, widely adopted in industry, and produces a portable state file; stronger for demonstrating IaC mastery in an academic context.
**Trade-off:** Terraform requires managing remote state (S3 backend + DynamoDB lock table); CDK would have abstracted this. No native L2 construct shortcuts — every resource is explicitly declared (more verbose, but more transparent).
**Status:** Accepted

---

## ADR-004 — CloudFront in front of API Gateway for GET /routines
**Date:** 2026-06-19
**Decision:** Add a CloudFront distribution with 30s TTL caching in front of the browse endpoint.
**Reason:** Required to meet p99 < 300ms latency target; cache-hits bypass Lambda entirely (<50ms globally).
**Trade-off:** Newly published routines may not appear for up to 30s (eventual consistency). Publish endpoint sends a cache invalidation to mitigate staleness on demand.
**Status:** Accepted

---

## ADR-005 — Cognito User Pool with Sign in with Apple (federated OIDC)
**Date:** 2026-06-19
**Decision:** Use Amazon Cognito User Pool with Apple as a federated OIDC identity provider; no email/password auth.
**Reason:** iOS users already have an Apple ID; native `ASAuthorizationAppleIDProvider` requires no extra SDK and provides the smoothest UX. Cognito `UserPoolIdentityProviderApple` handles token exchange and user record creation.
**Trade-off:** Requires an Apple Developer account (Services ID + private key) configured outside AWS. If Apple revokes the key or changes OIDC metadata, the integration breaks until re-configured. Email/password fallback deliberately omitted to reduce attack surface.
**Status:** Accepted

---

## ADR-006 — Amazon Bedrock (Claude 3 Haiku) for routine tagging
**Date:** 2026-06-19
**Decision:** Use Bedrock Claude 3 Haiku to auto-generate tags and descriptions on routine publish.
**Reason:** Satisfies the AI service requirement (5411 rubric); Haiku is the lowest-latency/cost Bedrock model suitable for short structured outputs.
**Trade-off:** Adds 3–10s latency to the publish flow; mitigated by running Bedrock call asynchronously after initial publish confirmation so the user is not blocked.
**Status:** Accepted

---

## ADR-008 — Provisioned concurrency + CloudFront caching for detail endpoint
**Date:** 2026-06-19
**Decision:** Apply provisioned concurrency to the get-routine Lambda and add CloudFront caching (5-min TTL) in front of GET /routines/{id}.
**Reason:** p99 <300ms target cannot be met with on-demand Lambda cold starts (~200–400ms) alone; CloudFront cache-hits resolve in <50ms globally.
**Trade-off:** Provisioned concurrency has a fixed hourly cost even at zero traffic. CloudFront introduces up to 5-min staleness on like counts; mitigated by targeted path invalidation on mutations.
**Status:** Accepted

---

## ADR-009 — Bedrock embedding similarity over Amazon Personalize for recommendations
**Date:** 2026-06-22
**Decision:** Use Bedrock text embeddings (cosine similarity between user tag profile and routine tag vectors) for personalized recommendations rather than Amazon Personalize.
**Reason:** Amazon Personalize requires a minimum dataset size (~1k interactions) and a training pipeline that is overkill for demo scale; Bedrock embeddings can run on any interaction count and are already in the stack for tagging.
**Trade-off:** Embedding similarity is simpler but less sophisticated than collaborative filtering (Personalize). At production scale (>10k users) Personalize would yield better results. Results cached per user in DynamoDB with 1hr TTL to avoid repeated embedding calls.
**Status:** Accepted

---

## ADR-010 — ElastiCache Redis for Lambda-side hot cache
**Date:** 2026-06-22
**Decision:** Add ElastiCache for Redis (single-node, cluster mode disabled) as a Lambda-side cache for browse results (60s TTL), routine detail objects (5min TTL), recommendation results (1hr TTL), and like counters (async flush every 30s).
**Reason:** Eliminates DynamoDB reads on the hottest paths; brings GET /recommendations p99 from ~800ms to <150ms and browse p99 well under 300ms even on cache-miss Lambda paths. Also satisfies the ≥2 storage solutions requirement with a third distinct storage tier.
**Trade-off:** ElastiCache requires Lambdas to run inside a VPC, adding ~10ms cold-start overhead and requiring Terraform resources for subnets, security groups, and a NAT Gateway (for Lambda → Bedrock/Cognito egress). Single-node has no Multi-AZ failover; a node failure causes a cold-cache period until DynamoDB backfills — acceptable for demo scope.
**Status:** Accepted

---

## ADR-011 — Typesense on EC2 t4g.nano over OpenSearch for full-text search
**Date:** 2026-06-22
**Decision:** Self-host Typesense (v27, open-source) on an EC2 t4g.nano instance for full-text search across routine name, description, and tags.
**Reason:** OpenSearch Serverless has a 4 OCU minimum floor (~$700/month idle cost); OpenSearch provisioned costs ~$50–100/month minimum. Typesense on t4g.nano costs ~$3.50/month, is production-ready (used by Perplexity, GitLab integrations), and delivers sub-50ms search latency with typo tolerance and relevance ranking out of the box.
**Trade-off:** Typesense is self-managed (not an AWS managed service), which works against the WAF Operational Excellence "use managed services" principle — OS patching, backup, and crash recovery are manual responsibilities. At production scale (>100k documents), migrating to OpenSearch Service (managed) would be the recommended path. Backups handled via daily Typesense snapshot to S3.
**Status:** Accepted

---

## ADR-012 — Single-table DynamoDB design for Community Library
**Date:** 2026-06-22
**Decision:** Store all entity types (Routine, RoutineTagIndex, User, Like, ImportRecord, UserActivity) in a single DynamoDB table (`mb-{env}-community`).
**Reason:** All access patterns are key-value or single-partition queries; no cross-entity joins required. Single-table reduces IAM surface, eliminates cross-table transactions, and aligns with DynamoDB best-practice (Rick Houlihan pattern).
**Trade-off:** Schema is opaque in the console without filtering on `EntityType`; migrations require backwards-compatible attribute additions. Mitigated by the `EntityType` attribute on every item and documented access patterns in `DATA_MODEL.md`.
**Status:** Accepted

---

## ADR-013 — DynamoDB Streams → Lambda → Typesense for search indexing
**Date:** 2026-06-22
**Decision:** Typesense search index is kept in sync via DynamoDB Streams events consumed by a dedicated `typesense-indexer` Lambda, not by synchronous calls from the publish Lambda.
**Reason:** Decoupling indexing from the publish path means a Typesense failure or latency spike cannot degrade the publish API response time or SLA. Stream retries (up to 24hrs) ensure eventual consistency.
**Trade-off:** New routines appear in search results with up to ~1s lag (stream polling interval) rather than immediately. Acceptable given the 30s CloudFront browse cache TTL already introduces similar eventual consistency.
**Status:** Accepted

---

## ADR-014 — POST /activity fire-and-forget for user activity sync
**Date:** 2026-06-22
**Decision:** iOS app syncs session activity via a POST /activity endpoint called on session complete (not on app open), with errors swallowed silently on the client side.
**Reason:** Calling on session complete (not app open) avoids blocking the app launch UX. Fire-and-forget means a transient network failure or Lambda error does not degrade the user's meditation experience; the next session sync will cover the gap.
**Trade-off:** A failed activity sync means that session's data is lost (not retried). The recommendation engine operates on best-effort recent activity; missing one session is acceptable given 60-day activity retention and frequent session cadence.
**Status:** Accepted

## ADR-015 — Replace session-wide ambient sound with per-block custom music
**Date:** 2026-06-22
**Decision:** Removed `AmbientSoundEngine` global mixer and Sounds tab; added `BlockMusicManager` + `musicFileName`/`musicDisplayName` per block, played via `AVAudioPlayer` looping during each block's timer.
**Reason:** Per-block music gives users precise control over what audio plays during each meditation phase, which is a higher-value feature than a global ambient mixer unconnected to the session timer.
**Status:** Accepted

---

## ADR-016 — Python 3.12 over Node.js 22 for Lambda handlers
**Date:** 2026-06-23
**Decision:** Use Python 3.12 as the Lambda runtime for all API and utility handlers.
**Reason:** Aligns handler implementation with pytest/moto testing stack, Bedrock boto3 SDK usage, and shared data-processing utilities; Python is the primary language for the Lambda agent workstream.
**Trade-off:** Supersedes the Node.js 22 runtime mention in ADR-003 only; Lambda-over-Fargate decision unchanged. Cold-start profile differs slightly from Node.js (~250–500ms vs ~200–400ms).
**Status:** Accepted (supersedes ADR-003 runtime only)

---

## ADR-017 — Account-scoped Terraform state bucket name
**Date:** 2026-06-23
**Decision:** Bootstrap creates `mb-tfstate-<account-id>` instead of a fixed global bucket name.
**Reason:** S3 bucket names are globally unique; `mb-terraform-state` was already taken by another AWS account.
**Trade-off:** Main stack `terraform init` requires `-backend-config=backend.hcl` (or CI secret `TF_STATE_BUCKET`) instead of a fully hardcoded backend block.
**Status:** Accepted

---

## ADR-018 — Disable Lambda provisioned concurrency on staging
**Date:** 2026-06-23
**Decision:** Gate provisioned concurrency behind `enable_lambda_provisioned_concurrency` (false for staging).
**Reason:** Small AWS accounts cannot reserve warm capacity without dropping unreserved concurrency below the AWS minimum of 10.
**Trade-off:** Staging hot paths accept cold-start latency (~250–500ms); production can opt in via tfvars after a quota review.
**Status:** Accepted

## ADR-019 — Temporary Cognito USER_PASSWORD_AUTH workaround for iOS testing
**Date:** 2026-06-23
**Decision:** Add `ALLOW_USER_PASSWORD_AUTH` to the Cognito app client and a temp email/password sign-in path in `AuthView`/`AuthManager` to bypass the Sign in with Apple PKCE flow.
**Reason:** Apple Developer Program enrollment is pending; the full authenticated app flow cannot be tested without a working SIWA federation.
**Trade-off:** Plaintext password transmitted over HTTPS to Cognito; temp UI and auth flow must be removed before App Store submission.
**Status:** Accepted

---

**Status:** Accepted

---

## ADR-021 — Optional Cognito JWT validation in Lambda for public GET routes
**Date:** 2026-06-23
**Decision:** For `get_routine`, `get_routines`, and `search` (API Gateway `auth = false`), validate `Authorization: Bearer` JWTs inside `shared/auth.py` using Cognito JWKS.
**Reason:** Public routes must stay anonymous-capable while populating per-user fields (`isLikedByMe`) when a valid token is sent; API Gateway Cognito authorizers are all-or-nothing.
**Trade-off:** Lambdas fetch/cache JWKS and verify tokens locally; invalid Bearer on `GET /routines/{id}` returns 401 instead of silent anonymity.
**Status:** Accepted

---

## ADR-022 — Lambda-side JWT auth for all API routes
**Date:** 2026-06-23
**Decision:** Set API Gateway `authorization = NONE` on all routes; protected handlers call `shared/auth.authenticate()` (Cognito JWKS, access or ID token).
**Reason:** API Gateway Cognito authorizers reject Cognito access tokens from `USER_PASSWORD_AUTH` while the iOS client sends access tokens; Lambda validation already accepts both token types.
**Trade-off:** Auth failures invoke Lambda instead of failing at the edge; Cognito authorizer resource remains unused until removed.
**Status:** Accepted

---

## ADR-023 — Typesense EC2 instance profile for bootstrap
**Date:** 2026-06-24
**Decision:** Attach an IAM instance profile to the Typesense EC2 instance granting `ssm:GetParameter` on the API-key parameter and S3 backup access.
**Reason:** User-data installs Typesense at boot and reads the API key from SSM; without an instance profile cloud-init failed with "Unable to locate credentials" and port 8108 never listened.
**Trade-off:** Instance replacement on user-data changes (`user_data_replace_on_change`); Lambdas also load the API key from SSM at runtime.
**Status:** Accepted
