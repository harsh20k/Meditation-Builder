# Community Library — Functional & Non-Functional Requirements

> Scoped to the cloud backend + iOS Community Library feature.
> Must satisfy all constraints in `5411_proj_requirements.md`.
> Last updated: June 19, 2026.

---

## Context

Meditation Builder is a local iOS app (SwiftUI + SwiftData) that lets users build, manage, and play custom meditation routines (blocks with bells, timers, ambient audio). The **Community Library** adds a cloud layer where users can publish, browse, and import routines made by others — with AI-assisted tagging via Bedrock.

---

## 1. Functional Requirements

### 1.1 User Stories (≥4, prioritized)

#### Must-Have

| # | Actor | Story | Acceptance Criteria |
|---|---|---|---|
| US-1 | Meditator | I want to **browse community routines** so I can discover practices I wouldn't have built myself. | Community Library tab shows paginated list of public routines with name, author, duration, tags, and like count. Works without login (read-only). |
| US-2 | Meditator | I want to **import a community routine** into my local library so I can play it as my own. | One-tap import: routine appears in Library tab with all blocks intact. Audio references resolved via CDN URL. |
| US-3 | Creator | I want to **publish one of my routines** to the Community Library so others can benefit from my practice. | Authenticated publish: uploads routine metadata + audio asset references to the cloud. Routine becomes discoverable within 30s. |
| US-4 | Creator | I want the app to **auto-generate tags and a description** for my routine using AI so I don't have to write them manually. | On publish, Bedrock generates ≤5 relevant tags and a 1-2 sentence description. User can review and edit before confirming. |
| US-5 | Meditator | I want to see **personalized routine recommendations** so I discover routines relevant to my practice without having to search. | Authenticated home feed shows ≥5 ranked recommended routines based on: tags of routines I've played/imported, session duration patterns, block types used, and community like/import signals. Recommendations refresh on each app open. |

#### Nice-to-Have

| # | Actor | Story | Acceptance Criteria |
|---|---|---|---|
| US-6 | Meditator | I want to **like a routine** to signal quality to other users. | Authenticated like increments counter. Push notification sent to routine's author asynchronously. |
| US-7 | Meditator | I want to **search and filter** Community Library routines by tag, duration, or popularity. | Free-text search across name, description, and tags with typo tolerance; filter by duration range; sort by likes or recency. Results returned in <200ms p95. |
| US-8 | Creator | I want to **see how many people imported or liked my routine** so I know if it resonates. | Creator profile screen shows per-routine import count and like count. |

---

### 1.2 All Functionalities

**Community Library (cloud-backed):**
- Browse paginated list of public routines (unauthenticated)
- Full-text search across name, description, tags (typo-tolerant) via **Typesense** (self-hosted on EC2 t4g.nano)
- Filter by tag, duration range; sort by likes / newest / relevance
- View routine detail (blocks list, author, description, like count)
- Import a community routine to local library (authenticated)
- Like / unlike a routine (authenticated)
- Publish a local routine to the Community Library (authenticated)
- Unpublish / delete own routine from Community Library (authenticated)
- AI-generated tags and description on publish (Bedrock)
- Async push notification to author on new like (SNS → APNs)
- **Personalized recommendations** — ranked routine feed per authenticated user (GET /recommendations)
  - Signals: played/imported routine tags, session duration history, block types, community like/import counts
  - Computed by a recommendation Lambda (Amazon Personalize or Bedrock embedding similarity)
  - Results cached per user in DynamoDB (TTL: 1hr); refreshed on app open if stale

**Auth:**
- Sign in with Apple ID (via Cognito federated OIDC — `UserPoolIdentityProviderApple`)
- Native `ASAuthorizationAppleIDProvider` on iOS; no custom auth UI needed
- Cognito issues JWT (access + refresh tokens); stored in Keychain, refreshed automatically
- Guest browsing (read-only; import/publish/like require sign-in)

**Local app (existing, unchanged):**
- Build, edit, delete, play local routines
- Session history and statistics
- Ambient sound mixer
- Daily reminder notifications

---

## 2. Non-Functional Requirements

All targets are measurable. Capacity assumptions are documented.

---

### 2.1 Scalability

| Parameter | Assumption | Target |
|---|---|---|
| Registered users (launch) | 100 (academic demo) | Support up to 1,000 concurrent users without re-architecture |
| Community Library routines at launch | ~200 | DynamoDB scales horizontally; no limit |
| Peak RPS (browse endpoint) | ~50 rps (class + demo day) | API Gateway + Lambda burst limit: 3,000 rps (default quota) |
| Growth projection (1 yr if real) | 10× user base | Lambda auto-scales to zero; DynamoDB on-demand billing |

**Assumption:** Demo load is 1–50 simultaneous users. Academic context, not production scale. Architecture is designed to scale; it will just cost more at higher loads.

---

### 2.2 Availability

| Target | Rationale |
|---|---|
| **99.9% uptime** (~8.7 hrs downtime/yr) | Academic demo. AWS Lambda SLA is 99.95%; API Gateway is 99.95%. Composite SLA ≈ 99.9%. |
| Multi-AZ DynamoDB | Default; no additional config required. |
| S3 durability | 99.999999999% (11 nines). Audio assets stored in S3 with versioning enabled. |

**Trade-off:** Full multi-region active-active (99.99%+) is deferred for cost reasons. Single-region (us-east-1) is the chosen trade-off, with the architecture documented to support multi-region via Route 53 latency routing if needed.

---

### 2.3 Latency

| Endpoint | p50 Target | p95 Target | p99 Target |
|---|---|---|---|
| GET /routines (browse) | < 200 ms | < 250 ms | < 300 ms |
| POST /routines (publish) | < 2 s | < 5 s | < 10 s |
| GET /routines/{id} (detail) | < 100 ms | < 200 ms | < 300 ms |
| Bedrock tag generation | < 5 s | < 10 s | < 15 s |
| GET /recommendations | < 50 ms | < 100 ms | < 150 ms |
| GET /search?q= | < 50 ms | < 100 ms | < 200 ms |

**Approach:**
- **CloudFront** in front of S3 (audio) and API Gateway (browse + detail). Provisioned concurrency on browse and detail Lambdas eliminates cold starts.
- **ElastiCache for Redis** (cluster mode disabled, single node — demo scale) as Lambda-side hot cache:
  - `GET /routines` browse: top-20 results cached with 60s TTL — Redis read <1ms, eliminates DynamoDB scan on hot path.
  - `GET /routines/{id}` detail: routine object cached with 5min TTL; invalidated on like/update.
  - `GET /recommendations`: per-user Bedrock embedding result cached with 1hr TTL — p99 <150ms on cache hit vs 800ms on cold Bedrock call.
  - Like counter: Redis `INCR` absorbs write bursts; async flush to DynamoDB every 30s via scheduled Lambda.
- Lambdas run inside a **VPC** to reach ElastiCache; NAT Gateway provides internet egress for Cognito/Bedrock calls.

---

### 2.4 Durability & RPO

| Data | RPO | Strategy |
|---|---|---|
| Community Library routines (DynamoDB) | 24 hrs | DynamoDB Point-in-Time Recovery (PITR) enabled. |
| Audio assets (S3) | 0 (immutable) | S3 versioning + 11-nines durability. No deletion without explicit request. |
| User accounts (Cognito) | Managed by AWS | Cognito user pool is AWS-managed; no custom backup needed. |

### 2.4a Recovery Time Objectives (RTO)

| Component | RTO Target | Recovery Mechanism | How Architecture Achieves It |
|---|---|---|---|
| API (Lambda + API Gateway) | ~0 — seconds | Serverless auto-recovery | Lambda has no persistent state; API Gateway re-routes to healthy instances automatically. An AZ failure within us-east-1 does not require manual intervention. Measured RTO: <60s from AWS event to restored traffic. |
| DynamoDB (PITR restore) | 1–4 hrs | Point-in-time restore to a new table | PITR restores to a new table name; Terraform variable `DYNAMODB_TABLE_NAME` must be updated and re-applied to redirect Lambda. Full restore of a ~1GB table takes ~1–2hrs; DNS/config propagation adds ~30min. Acceptable for the 24hr RPO window. |
| Typesense (EC2 self-managed) | 30 min | AMI snapshot restore + re-index | Daily AMI snapshot stored in AWS. Recovery: launch new t4g.nano from latest AMI (~5min), restore Typesense snapshot from S3 (~2min), run full DynamoDB re-index Lambda (~20min for ~10k documents). Total: ~30min. Typesense unavailability causes `/search` to return 503; browse and recommendations remain functional. |
| ElastiCache Redis (node failure) | 0 (degraded) | Cold-cache fallback to DynamoDB | Lambda catches Redis connection timeout (50ms) and falls back to DynamoDB read. No data loss; cache rebuilds on next request. Multi-AZ replica (deferred for demo) would reduce cold-cache period to <30s automatic failover. |
| S3 (audio assets) | N/A | Immutable; versioning enabled | S3 offers 99.999999999% durability; no restore procedure needed for normal failures. Accidental deletes recovered via S3 version restore (instant). |

**RTO Summary:** The serverless components (Lambda, API Gateway, DynamoDB) auto-recover within seconds. The only components with significant RTO are Typesense (~30min) and DynamoDB full restore (1–4hrs). The 99.9% availability target (8.7hrs downtime/year) is achievable given these RTOs and the low probability of needing a full PITR restore.

---

### 2.5 Security

| Control | Implementation |
|---|---|
| Authentication | AWS Cognito User Pool; JWT access tokens (1hr expiry), refresh tokens (30 days) |
| Authorization | API Gateway Cognito Authorizer; Lambda checks `sub` claim for ownership on mutations |
| Encryption at rest | Customer-managed KMS CMKs for DynamoDB and S3; automatic key rotation enabled |
| Encryption in transit | TLS 1.2+ enforced on API Gateway and CloudFront |
| Input validation | Lambda validates all inputs; API Gateway request validation on body/params |
| Least privilege | Each Lambda has a dedicated IAM role with only the permissions it needs (no wildcards) |
| SCPs & guardrails | AWS Organizations SCPs restrict dangerous actions (e.g. disabling CloudTrail, enabling public S3 buckets) |
| Audit logging | CloudTrail enabled across all regions; logs shipped to a dedicated S3 bucket with Object Lock (WORM) |

---

### 2.6 Maintainability & Deployability

| Dimension | Target |
|---|---|
| IaC coverage | 100% — Terraform (HCL) for all cloud resources; zero manually created resources; state stored in S3 + DynamoDB lock table |
| CI/CD | GitHub Actions: on PR → `terraform plan`; on merge to `main` → `terraform apply` to staging |
| Observability | CloudWatch dashboards (error rate, latency, throttles); X-Ray distributed tracing on all Lambdas; structured JSON logs |
| Test coverage | Unit tests for all Lambda handlers; iOS unit tests (existing); integration tests hit real AWS endpoints in staging |
| Deployment time | `terraform apply` completes in < 5 min from clean state |

### 2.6a Staging vs Production Environments

**Approach:** Same AWS account, two Terraform workspaces. No separate AWS accounts for demo scope (separate accounts would require cross-account IAM roles and add setup time; single-account with workspace separation is sufficient to isolate state and costs).

#### Resource Naming Convention

All resources follow the pattern: `mb-{env}-{resource}`

| Example Resource | Staging Name | Production Name |
|---|---|---|
| DynamoDB table | `mb-staging-community` | `mb-production-community` |
| Lambda function (browse) | `mb-staging-browse-routines` | `mb-production-browse-routines` |
| S3 bucket (audio) | `mb-staging-audio-assets` | `mb-production-audio-assets` |
| ElastiCache cluster | `mb-staging-redis` | `mb-production-redis` |
| EC2 instance (Typesense) | `mb-staging-typesense` | `mb-production-typesense` |
| SSM parameter (API key) | `/mb/staging/typesense/api-key` | `/mb/production/typesense/api-key` |

#### CI/CD Pipeline (GitHub Actions)

```
Pull Request opened / updated
    └─► terraform workspace select staging
    └─► terraform plan  (output posted as PR comment)
    └─► Unit tests (Lambda handlers)

Merge to main
    └─► terraform workspace select staging
    └─► terraform apply -auto-approve  (staging deploy)
    └─► Integration tests against staging endpoints

Manual approval (GitHub Environment protection rule: "production")
    └─► terraform workspace select production
    └─► terraform apply -auto-approve  (production deploy)
```

- Staging deploy is automatic on merge to `main`; production deploy requires a manual approval by a repo admin (GitHub Environments `required_reviewers`).
- `terraform plan` output is posted as a PR comment using the `hashicorp/setup-terraform` action with `terraform_wrapper: true`.
- AWS credentials are provided via GitHub OIDC (`aws-actions/configure-aws-credentials`) — no long-lived access keys stored in GitHub Secrets.

#### Environment Variables and Secrets

All environment-specific configuration is managed via **AWS SSM Parameter Store**, namespaced by environment:

| Parameter | Type | Example path |
|---|---|---|
| Typesense API key | SecureString | `/mb/{env}/typesense/api-key` |
| Typesense host | String | `/mb/{env}/typesense/host` |
| Cognito User Pool ID | String | `/mb/{env}/cognito/user-pool-id` |
| Cognito App Client ID | String | `/mb/{env}/cognito/app-client-id` |
| Redis host | String | `/mb/{env}/redis/host` |

Lambda functions receive environment variables at deploy time via Terraform `aws_lambda_function.environment.variables`, which pulls values from SSM using the `aws_ssm_parameter` data source. No secrets in the Lambda source code or Terraform HCL.

#### Staging Teardown

After the demo submission (target: July 3, 2026):

```bash
terraform workspace select staging
terraform destroy -auto-approve
```

This destroys all staging resources and eliminates ongoing cost. The Terraform state file is preserved in S3 for historical reference. Production resources remain running (or are similarly destroyed if the demo period ends).

**Cost implication of teardown:** ~$25–30/month production cost drops to $0 after full teardown. The S3 state bucket (~$0.01/month) is the only residual cost.

---

## 3. Architectural Constraints (from requirements doc)

| Constraint | How we meet it |
|---|---|
| ≥3 cloud services across required categories | Compute (Lambda, EC2 for Typesense), Networking (CloudFront, VPC), Messaging (SQS, SNS), AI (Bedrock), Integration (API Gateway), Monitoring (CloudWatch, X-Ray) |
| ≥2 storage solutions | DynamoDB (NoSQL) + S3 (object storage) + ElastiCache Redis (in-memory cache) — 3 distinct storage tiers |
| Real HTTP traffic | iOS app → API Gateway REST |
| AI service | Amazon Bedrock (Claude 3 Haiku for tagging; embeddings for recommendation similarity) |
| CI/CD | GitHub Actions → `terraform apply` |
| IaC | Terraform (HCL) |
| All 6 WAF pillars | Documented in `5411_proj_requirements.md` §8 |

---

## 4. Out of Scope (explicitly deferred)

- Social features (comments, follows)
- Audio file hosting by the Community Library (v1 links to existing iCloud/CDN URLs; S3 upload is nice-to-have)
- Subscription/monetization
- Android client
- GDPR/HIPAA compliance (academic demo; no real PII beyond email)
