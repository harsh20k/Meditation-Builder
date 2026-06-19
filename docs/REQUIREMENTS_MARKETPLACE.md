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

#### Nice-to-Have

| # | Actor | Story | Acceptance Criteria |
|---|---|---|---|
| US-5 | Meditator | I want to **like a routine** to signal quality to other users. | Authenticated like increments counter. Push notification sent to routine's author asynchronously. |
| US-6 | Meditator | I want to **search and filter** Community Library routines by tag, duration, or popularity. | DynamoDB GSI supports filter by tag + sort by likes or recency. |
| US-7 | Creator | I want to **see how many people imported or liked my routine** so I know if it resonates. | Creator profile screen shows per-routine import count and like count. |

---

### 1.2 All Functionalities

**Community Library (cloud-backed):**
- Browse paginated list of public routines (unauthenticated)
- Search/filter by tag, duration range, sort by likes / newest
- View routine detail (blocks list, author, description, like count)
- Import a community routine to local library (authenticated)
- Like / unlike a routine (authenticated)
- Publish a local routine to the Community Library (authenticated)
- Unpublish / delete own routine from Community Library (authenticated)
- AI-generated tags and description on publish (Bedrock)
- Async push notification to author on new like (SNS → APNs)

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
| GET /routines/{id} (detail) | < 150 ms | < 400 ms | < 800 ms |
| Bedrock tag generation | < 5 s | < 10 s | < 15 s |

**Approach:** CloudFront CDN in front of S3 for audio assets (sub-100ms globally). DynamoDB single-digit millisecond reads. Cold Lambda start mitigated with provisioned concurrency on the browse endpoint (hot path).

---

### 2.4 Durability & RPO

| Data | RPO | Strategy |
|---|---|---|
| Community Library routines (DynamoDB) | 24 hrs | DynamoDB Point-in-Time Recovery (PITR) enabled. |
| Audio assets (S3) | 0 (immutable) | S3 versioning + 11-nines durability. No deletion without explicit request. |
| User accounts (Cognito) | Managed by AWS | Cognito user pool is AWS-managed; no custom backup needed. |

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
| Deployment time | `cdk deploy --all` completes in < 5 min from clean state |

---

## 3. Architectural Constraints (from requirements doc)

| Constraint | How we meet it |
|---|---|
| ≥3 cloud services across required categories | Compute (Lambda), Networking (CloudFront, VPC), Messaging (SQS, SNS), AI (Bedrock), Integration (API Gateway), Monitoring (CloudWatch, X-Ray) |
| ≥2 storage solutions | DynamoDB (NoSQL) + S3 (object storage) |
| Real HTTP traffic | iOS app → API Gateway REST |
| AI service | Amazon Bedrock (Claude 3 Haiku) for routine tagging |
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
